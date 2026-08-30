// Recherche.cpp — la fenêtre « Rechercher et remplacer ».
#include "Recherche.h"

#include <QCheckBox>
#include <QGridLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QTextCursor>
#include <QTextDocument>
#include <QVBoxLayout>

DialogueRecherche::DialogueRecherche(QWidget* parent) : QDialog(parent) {
    setWindowTitle(QStringLiteral("Rechercher et remplacer"));
    // Une fenêtre qui ne bloque pas : on tape dans l'éditeur pendant
    // qu'elle est ouverte, comme dans MATLAB.
    setModal(false);

    chercher_ = new QLineEdit(this);
    remplacer_ = new QLineEdit(this);
    casse_ = new QCheckBox(QStringLiteral("Respecter la casse"), this);
    motEntier_ = new QCheckBox(QStringLiteral("Mot entier"), this);
    boucler_ = new QCheckBox(QStringLiteral("Boucler"), this);
    boucler_->setChecked(true);
    etat_ = new QLabel(this);
    etat_->setStyleSheet(QStringLiteral("color:#666"));

    auto* grille = new QGridLayout;
    grille->addWidget(new QLabel(QStringLiteral("Rechercher :"), this), 0, 0);
    grille->addWidget(chercher_, 0, 1);
    grille->addWidget(new QLabel(QStringLiteral("Remplacer par :"), this), 1, 0);
    grille->addWidget(remplacer_, 1, 1);

    auto* options = new QHBoxLayout;
    options->addWidget(casse_);
    options->addWidget(motEntier_);
    options->addWidget(boucler_);
    options->addStretch();

    auto* bSuivant = new QPushButton(QStringLiteral("Suivant"), this);
    auto* bPrecedent = new QPushButton(QStringLiteral("Précédent"), this);
    bRemplacer_ = new QPushButton(QStringLiteral("Remplacer"), this);
    bRemplacerTout_ = new QPushButton(QStringLiteral("Remplacer tout"), this);
    auto* bFermer = new QPushButton(QStringLiteral("Fermer"), this);
    bSuivant->setDefault(true);

    auto* boutons = new QHBoxLayout;
    boutons->addWidget(bSuivant);
    boutons->addWidget(bPrecedent);
    boutons->addWidget(bRemplacer_);
    boutons->addWidget(bRemplacerTout_);
    boutons->addStretch();
    boutons->addWidget(bFermer);

    auto* colonne = new QVBoxLayout(this);
    colonne->addLayout(grille);
    colonne->addLayout(options);
    colonne->addLayout(boutons);
    colonne->addWidget(etat_);

    connect(bSuivant, &QPushButton::clicked, this, [this] { chercherSuivant(true); });
    connect(bPrecedent, &QPushButton::clicked, this, [this] { chercherSuivant(false); });
    connect(bRemplacer_, &QPushButton::clicked, this, [this] { remplacerCourant(); });
    connect(bRemplacerTout_, &QPushButton::clicked, this, [this] { remplacerTout(); });
    connect(bFermer, &QPushButton::clicked, this, &QDialog::close);
    // Entrée dans le champ cherche la suite : c'est ce qu'on attend.
    connect(chercher_, &QLineEdit::returnPressed, this, [this] { chercherSuivant(true); });
    connect(remplacer_, &QLineEdit::returnPressed, this, [this] { remplacerCourant(); });
}

void DialogueRecherche::viser(QPlainTextEdit* cible) {
    cible_ = cible;
    bool modifiable = cible && !cible->isReadOnly();
    remplacer_->setEnabled(modifiable);
    bRemplacer_->setEnabled(modifiable);
    bRemplacerTout_->setEnabled(modifiable);
    poserEtat(QString());
}

void DialogueRecherche::definirRecherche(const QString& texte) { chercher_->setText(texte); }

void DialogueRecherche::definirRemplacement(const QString& texte) {
    remplacer_->setText(texte);
}

void DialogueRecherche::poserEtat(const QString& texte) { etat_->setText(texte); }

bool DialogueRecherche::chercherSuivant(bool versLeBas) {
    if (!cible_ || chercher_->text().isEmpty()) return false;
    QTextDocument::FindFlags drapeaux;
    if (!versLeBas) drapeaux |= QTextDocument::FindBackward;
    if (casse_->isChecked()) drapeaux |= QTextDocument::FindCaseSensitively;
    if (motEntier_->isChecked()) drapeaux |= QTextDocument::FindWholeWords;
    QTextCursor trouve = cible_->document()->find(chercher_->text(), cible_->textCursor(),
                                                  drapeaux);
    if (trouve.isNull() && boucler_->isChecked()) {
        // On repart du bout : c'est le « Boucler » de MATLAB.
        QTextCursor bout(cible_->document());
        if (!versLeBas) bout.movePosition(QTextCursor::End);
        trouve = cible_->document()->find(chercher_->text(), bout, drapeaux);
    }
    if (trouve.isNull()) {
        poserEtat(QStringLiteral("« %1 » introuvable.").arg(chercher_->text()));
        return false;
    }
    cible_->setTextCursor(trouve);
    cible_->ensureCursorVisible();
    poserEtat(QString());
    return true;
}

bool DialogueRecherche::remplacerCourant() {
    if (!cible_ || cible_->isReadOnly() || chercher_->text().isEmpty()) return false;
    QTextCursor c = cible_->textCursor();
    // On ne remplace que ce qui est bien sélectionné : sinon on cherche
    // d'abord, comme MATLAB.
    Qt::CaseSensitivity sensibilite =
        casse_->isChecked() ? Qt::CaseSensitive : Qt::CaseInsensitive;
    if (c.hasSelection() && QString::compare(c.selectedText(), chercher_->text(),
                                             sensibilite) == 0) {
        c.insertText(remplacer_->text());
        cible_->setTextCursor(c);
        chercherSuivant(true);
        return true;
    }
    return chercherSuivant(true);
}

int DialogueRecherche::remplacerTout() {
    if (!cible_ || cible_->isReadOnly() || chercher_->text().isEmpty()) return 0;
    QTextDocument::FindFlags drapeaux;
    if (casse_->isChecked()) drapeaux |= QTextDocument::FindCaseSensitively;
    if (motEntier_->isChecked()) drapeaux |= QTextDocument::FindWholeWords;
    QTextCursor c(cible_->document());
    c.beginEditBlock();
    int faits = 0;
    QTextCursor curseur(cible_->document());
    for (;;) {
        QTextCursor trouve = cible_->document()->find(chercher_->text(), curseur, drapeaux);
        if (trouve.isNull()) break;
        trouve.insertText(remplacer_->text());
        curseur = trouve;
        ++faits;
    }
    c.endEditBlock();
    poserEtat(faits == 0 ? QStringLiteral("Rien à remplacer.")
                         : QStringLiteral("%1 remplacement(s).").arg(faits));
    return faits;
}
