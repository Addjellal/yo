// ConsoleCommandes.cpp — l'invite dans le texte.
#include "ConsoleCommandes.h"

#include <QAbstractTextDocumentLayout>
#include <QFontDatabase>
#include <QKeyEvent>
#include <QMouseEvent>
#include <QScrollBar>
#include <QTextBlock>

#include "Theme.h"



ConsoleCommandes::ConsoleCommandes(QWidget* parent) : QPlainTextEdit(parent) {
    QFont police = QFontDatabase::systemFont(QFontDatabase::FixedFont);
    police.setPointSize(11);
    setFont(police);
    setFrameStyle(QFrame::NoFrame);
    setUndoRedoEnabled(false);
    setLineWrapMode(QPlainTextEdit::WidgetWidth);
    setMaximumBlockCount(20000);   // la console ne doit pas grossir sans fin
    document()->setDefaultFont(police);
}

void ConsoleCommandes::allerEnFin() {
    QTextCursor c = textCursor();
    c.movePosition(QTextCursor::End);
    setTextCursor(c);
    verticalScrollBar()->setValue(verticalScrollBar()->maximum());
}

bool ConsoleCommandes::curseurDansZoneModifiable() const {
    return inviteVisible_ && textCursor().position() >= debutSaisie_ &&
           textCursor().selectionStart() >= debutSaisie_;
}

QString ConsoleCommandes::commandeEnCours() const {
    if (!inviteVisible_) return QString();
    QTextCursor c = textCursor();
    c.setPosition(debutSaisie_);
    c.movePosition(QTextCursor::End, QTextCursor::KeepAnchor);
    return c.selectedText().replace(QChar(0x2029), QLatin1Char('\n'));
}

void ConsoleCommandes::remplacerSaisie(const QString& texte) {
    QTextCursor c = textCursor();
    c.setPosition(debutSaisie_);
    c.movePosition(QTextCursor::End, QTextCursor::KeepAnchor);
    c.removeSelectedText();
    c.insertText(texte);
    setTextCursor(c);
}

void ConsoleCommandes::poserInvite(const QString& invite) {
    if (inviteVisible_ && invite == invite_) return;
    if (inviteVisible_) masquerInvite();
    invite_ = invite;
    QTextCursor c = textCursor();
    c.movePosition(QTextCursor::End);
    // L'invite commence toujours en début de ligne.
    if (!c.atBlockStart()) c.insertBlock();
    QTextCharFormat format;
    format.setForeground(theme::invite());
    c.insertText(invite_, format);
    debutSaisie_ = c.position();
    inviteVisible_ = true;
    setTextCursor(c);
    allerEnFin();
}

void ConsoleCommandes::masquerInvite() { inviteVisible_ = false; }

void ConsoleCommandes::effacer() {
    clear();
    inviteVisible_ = false;
    debutSaisie_ = 0;
    poserInvite();
}

void ConsoleCommandes::ecrireSortie(const QString& texte, const QColor& couleur) {
    if (texte.isEmpty()) return;
    // La sortie s'insère avant l'invite : ce que l'utilisateur est en train
    // de taper reste sous ses yeux et sous son curseur.
    QString enCours;
    int decalageCurseur = 0;
    if (inviteVisible_) {
        enCours = commandeEnCours();
        decalageCurseur = textCursor().position() - debutSaisie_;
        QTextCursor c = textCursor();
        c.setPosition(debutSaisie_ - invite_.size());
        c.movePosition(QTextCursor::End, QTextCursor::KeepAnchor);
        c.removeSelectedText();
        // Retire aussi le bloc vide laissé par l'invite.
        if (!c.atBlockStart()) {
            c.deletePreviousChar();
        } else if (c.position() > 0) {
            c.deletePreviousChar();
        }
        inviteVisible_ = false;
    }
    QTextCursor c = textCursor();
    c.movePosition(QTextCursor::End);
    if (!c.atBlockStart()) c.insertBlock();
    QTextCharFormat format;
    format.setForeground(couleur.isValid() ? couleur : theme::texte());
    // Le texte arrive avec ses fins de ligne : on les traduit en blocs pour
    // que la console reste un vrai document et non une seule ligne.
    const QStringList lignes = texte.split(QLatin1Char('\n'));
    for (int k = 0; k < lignes.size(); ++k) {
        if (k) c.insertBlock();
        if (!lignes[k].isEmpty()) c.insertText(lignes[k], format);
    }
    setTextCursor(c);
    if (!enCours.isEmpty() || decalageCurseur > 0) {
        poserInvite();
        QTextCursor r = textCursor();
        r.insertText(enCours);
        r.setPosition(debutSaisie_ + decalageCurseur);
        setTextCursor(r);
    }
    allerEnFin();
}

void ConsoleCommandes::mousePressEvent(QMouseEvent* evenement) {
    QPlainTextEdit::mousePressEvent(evenement);
    // Cliquer plus haut sert à sélectionner du texte : on le permet, mais
    // la frappe repart de l'invite. C'est le comportement de MATLAB.
    setReadOnly(false);
}

void ConsoleCommandes::keyPressEvent(QKeyEvent* evenement) {
    const int touche = evenement->key();
    const bool controle = evenement->modifiers() & Qt::ControlModifier;

    if (controle && touche == Qt::Key_C) {
        if (textCursor().hasSelection()) {
            copy();
        } else {
            emit interruptionDemandee();
        }
        return;
    }
    if (controle && touche == Qt::Key_L) {
        effacer();
        return;
    }
    // Copier, sélectionner : autorisés partout. Tout le reste ramène le
    // curseur dans la zone de saisie avant d'agir.
    if (controle && (touche == Qt::Key_A || touche == Qt::Key_Insert)) {
        QPlainTextEdit::keyPressEvent(evenement);
        return;
    }
    if (touche == Qt::Key_PageUp || touche == Qt::Key_PageDown) {
        QPlainTextEdit::keyPressEvent(evenement);
        return;
    }
    if (!inviteVisible_) return;   // occupé : la frappe est ignorée

    if (touche == Qt::Key_Return || touche == Qt::Key_Enter) {
        QString commande = commandeEnCours();
        QTextCursor c = textCursor();
        c.movePosition(QTextCursor::End);
        setTextCursor(c);
        inviteVisible_ = false;
        indexHistorique_ = -1;
        if (!commande.trimmed().isEmpty()) {
            historique_ << commande;
            emit commandeValidee(commande);
        } else {
            poserInvite();
        }
        return;
    }

    if (touche == Qt::Key_Up || touche == Qt::Key_Down) {
        if (historique_.isEmpty()) return;
        if (indexHistorique_ < 0) saisieAvantHistorique_ = commandeEnCours();
        if (touche == Qt::Key_Up) {
            if (indexHistorique_ < 0) indexHistorique_ = historique_.size() - 1;
            else if (indexHistorique_ > 0) --indexHistorique_;
        } else {
            if (indexHistorique_ >= 0 && indexHistorique_ < historique_.size() - 1) {
                ++indexHistorique_;
            } else {
                indexHistorique_ = -1;
                remplacerSaisie(saisieAvantHistorique_);
                allerEnFin();
                return;
            }
        }
        remplacerSaisie(historique_.at(indexHistorique_));
        allerEnFin();
        return;
    }

    if (touche == Qt::Key_Home) {
        QTextCursor c = textCursor();
        c.setPosition(debutSaisie_, evenement->modifiers() & Qt::ShiftModifier
                                        ? QTextCursor::KeepAnchor
                                        : QTextCursor::MoveAnchor);
        setTextCursor(c);
        return;
    }

    // Effacer ne doit pas manger l'invite.
    if ((touche == Qt::Key_Backspace || touche == Qt::Key_Left) &&
        textCursor().position() <= debutSaisie_ && !textCursor().hasSelection())
        return;

    if (!curseurDansZoneModifiable()) allerEnFin();
    QPlainTextEdit::keyPressEvent(evenement);
}
