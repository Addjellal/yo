// ConsoleCommandes.cpp — l'invite dans le texte.
#include "ConsoleCommandes.h"

#include <QAbstractTextDocumentLayout>
#include <QFontDatabase>
#include <QKeyEvent>
#include <QListWidget>
#include <QMouseEvent>
#include <QCoreApplication>
#include <QScrollBar>
#include <QTextBlock>

#include <algorithm>

#include "Theme.h"

namespace {

bool caractereDeNom(QChar c) { return c.isLetterOrNumber() || c == QLatin1Char('_'); }

// Vrai si la position donnee tombe dans une chaine de caracteres, et
// donne alors le rang du premier caractere du texte de la chaine.
//
// L'apostrophe sert aussi de transposition en MATLAB ; on suit donc les
// ouvertures et les fermetures dans l'ordre, le doublement « '' » valant
// une apostrophe dans le texte. C'est assez pour savoir si l'on ecrit un
// nom de fichier — le seul usage qu'on en fait.
bool dansUneChaine(const QString& ligne, int position, int& debutTexte) {
    bool dedans = false;
    QChar delimiteur;
    for (int k = 0; k < position && k < ligne.size(); ++k) {
        QChar c = ligne.at(k);
        if (!dedans) {
            if (c == QLatin1Char('\'') || c == QLatin1Char('"')) {
                dedans = true;
                delimiteur = c;
                debutTexte = k + 1;
            }
        } else if (c == delimiteur) {
            if (k + 1 < position && ligne.at(k + 1) == delimiteur) ++k;   // « '' »
            else dedans = false;
        }
    }
    return dedans;
}

// Le plus long prefixe commun a toutes les propositions : ce que MATLAB
// ecrit d'emblee avant de montrer la liste.
QString prefixeCommun(const QStringList& choix) {
    if (choix.isEmpty()) return QString();
    QString commun = choix.first();
    for (const QString& c : choix) {
        int k = 0;
        while (k < commun.size() && k < c.size() && commun.at(k) == c.at(k)) ++k;
        commun.truncate(k);
    }
    return commun;
}

}  // namespace



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

void ConsoleCommandes::definirCompletions(
    std::function<QStringList(const QString&, bool)> fournisseur) {
    fournisseurCompletions_ = std::move(fournisseur);
}

QStringList ConsoleCommandes::completionsDe(const QString& ligne, int position,
                                           QString* prefixe, bool* fichiers) const {
    int debutTexte = 0;
    bool chaine = dansUneChaine(ligne, position, debutTexte);
    QString mot;
    if (chaine) {
        // Entre guillemets, le prefixe est tout le texte deja ecrit : les
        // chemins portent des barres et des espaces, qu'aucun decoupage en
        // mots ne saurait respecter.
        mot = ligne.mid(debutTexte, position - debutTexte);
    } else {
        int debut = position;
        while (debut > 0 && caractereDeNom(ligne.at(debut - 1))) --debut;
        mot = ligne.mid(debut, position - debut);
    }
    if (prefixe) *prefixe = mot;
    if (fichiers) *fichiers = chaine;
    if (!fournisseurCompletions_) return QStringList();
    QStringList trouves = fournisseurCompletions_(mot, chaine);
    trouves.removeDuplicates();
    return trouves;
}

void ConsoleCommandes::completer() {
    if (!inviteVisible_) return;
    QString ligne = commandeEnCours();
    int position = textCursor().position() - debutSaisie_;
    if (position < 0 || position > ligne.size()) return;
    QString prefixe;
    bool fichiers = false;
    QStringList choix = completionsDe(ligne, position, &prefixe, &fichiers);
    if (choix.isEmpty()) {
        fermerChoix();
        return;
    }
    debutPrefixe_ = debutSaisie_ + position - prefixe.size();
    if (choix.size() == 1) {
        appliquerChoix(choix.first());
        return;
    }
    // Plusieurs : on ecrit ce qu'elles ont en commun, puis on les montre.
    QString commun = prefixeCommun(choix);
    if (commun.size() > prefixe.size()) {
        QTextCursor c = textCursor();
        c.setPosition(debutPrefixe_);
        c.setPosition(debutPrefixe_ + prefixe.size(), QTextCursor::KeepAnchor);
        c.insertText(commun);
        setTextCursor(c);
    }
    montrerChoix(choix);
}

void ConsoleCommandes::appliquerChoix(const QString& choix) {
    QTextCursor c = textCursor();
    int fin = c.position();
    if (debutPrefixe_ < debutSaisie_ || debutPrefixe_ > fin) return;
    c.setPosition(debutPrefixe_);
    c.setPosition(fin, QTextCursor::KeepAnchor);
    c.insertText(choix);
    setTextCursor(c);
    fermerChoix();
}

void ConsoleCommandes::montrerChoix(const QStringList& choix) {
    if (!choix_) {
        choix_ = new QListWidget(this);
        choix_->setWindowFlags(Qt::Popup);
        choix_->setFocusPolicy(Qt::NoFocus);
        choix_->setFont(font());
        choix_->installEventFilter(this);
        connect(choix_, &QListWidget::itemClicked, this,
                [this](QListWidgetItem* item) { appliquerChoix(item->text()); });
    }
    choix_->clear();
    choix_->addItems(choix);
    choix_->setCurrentRow(0);
    // La liste s'ouvre sous le curseur, comme celle de MATLAB, et ne
    // depasse pas une dizaine de lignes.
    int lignes = std::min<int>((int)choix.size(), 10);
    int hauteur = lignes * choix_->sizeHintForRow(0) + 8;
    int largeur = 120;
    for (const QString& c : choix)
        largeur = std::max(largeur, fontMetrics().horizontalAdvance(c) + 40);
    choix_->resize(std::min(largeur, 520), hauteur);
    QRect r = cursorRect();
    choix_->move(mapToGlobal(QPoint(r.left(), r.bottom() + 2)));
    choix_->show();
}

void ConsoleCommandes::fermerChoix() {
    if (choix_) choix_->hide();
}

bool ConsoleCommandes::eventFilter(QObject* objet, QEvent* evenement) {
    if (objet == choix_ && evenement->type() == QEvent::KeyPress) {
        auto* touche = static_cast<QKeyEvent*>(evenement);
        switch (touche->key()) {
            case Qt::Key_Escape:
                fermerChoix();
                return true;
            case Qt::Key_Return:
            case Qt::Key_Enter:
            case Qt::Key_Tab:
                if (choix_->currentItem()) appliquerChoix(choix_->currentItem()->text());
                return true;
            case Qt::Key_Up:
            case Qt::Key_Down:
            case Qt::Key_PageUp:
            case Qt::Key_PageDown:
                return false;   // la liste se deplace elle-meme
            default:
                // Toute autre frappe continue la saisie : la liste se
                // ferme et la touche va a la console, comme dans MATLAB.
                fermerChoix();
                QCoreApplication::sendEvent(this, touche);
                return true;
        }
    }
    return QPlainTextEdit::eventFilter(objet, evenement);
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
    // Le paquet part d'un seul coup : « insertText » traite déjà les fins
    // de ligne comme des séparateurs de bloc. Le faire ligne à ligne
    // demandait une mise en page par ligne, et un affichage de plusieurs
    // millions de lignes figeait la fenêtre.
    c.insertText(texte, format);
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

    // La tabulation complete : un nom de fichier entre guillemets, un nom
    // de fonction ou de variable ailleurs.
    if (touche == Qt::Key_Tab && !controle) {
        completer();
        return;
    }

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
