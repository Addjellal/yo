// DialogueBloc.cpp — les réglages d'un bloc.
#include "DialogueBloc.h"

#include <QComboBox>
#include <QDialogButtonBox>
#include <QFormLayout>
#include <QFontDatabase>
#include <QLabel>
#include <QLineEdit>
#include <QPlainTextEdit>
#include <QVBoxLayout>

DialogueBloc::DialogueBloc(const QString& nomBloc, const QString& type,
                           const QStringList& noms, const QStringList& valeurs,
                           const QStringList& choix, QWidget* parent)
    : QDialog(parent), nomOrigine_(nomBloc), noms_(noms), valeursOrigine_(valeurs) {
    setWindowTitle(QStringLiteral("Réglages de « %1 »").arg(nomBloc));
    setObjectName(QStringLiteral("dialogueBloc"));
    auto* colonne = new QVBoxLayout(this);

    auto* entete = new QLabel(QStringLiteral("Bloc de type « %1 »").arg(type));
    QFont grasse = entete->font();
    grasse.setBold(true);
    entete->setFont(grasse);
    colonne->addWidget(entete);

    auto* formulaire = new QFormLayout;
    champNom_ = new QLineEdit(nomBloc);
    champNom_->setObjectName(QStringLiteral("champNom"));
    formulaire->addRow(QStringLiteral("Nom du bloc"), champNom_);
    for (int k = 0; k < noms.size(); ++k) {
        const QString valeur = k < valeurs.size() ? valeurs[k] : QString();
        const QString admises = k < choix.size() ? choix[k] : QString();
        if (!admises.isEmpty()) {
            // Un choix se prend dans une liste : taper « u2>=Threshold » à
            // la main, c'était risquer une valeur que le bloc refuse.
            auto* liste = new QComboBox;
            liste->addItems(admises.split(QLatin1Char('|')));
            const int rang = liste->findText(valeur);
            if (rang >= 0) liste->setCurrentIndex(rang);
            else {
                liste->addItem(valeur);
                liste->setCurrentIndex(liste->count() - 1);
            }
            liste->setObjectName(QStringLiteral("liste_") + noms[k]);
            formulaire->addRow(noms[k], liste);
            champs_.push_back(nullptr);
            listes_.push_back(liste);
            textes_.push_back(nullptr);
            continue;
        }
        if (noms[k] == QLatin1String("Script") || valeur.contains(QLatin1Char('\n'))) {
            // Le code d'un bloc MATLAB Function : des lignes, en chasse
            // fixe, comme dans l'éditeur de Simulink.
            auto* texte = new QPlainTextEdit(valeur);
            texte->setObjectName(QStringLiteral("texte_") + noms[k]);
            texte->setFont(QFontDatabase::systemFont(QFontDatabase::FixedFont));
            texte->setMinimumHeight(160);
            texte->setLineWrapMode(QPlainTextEdit::NoWrap);
            formulaire->addRow(noms[k], texte);
            champs_.push_back(nullptr);
            listes_.push_back(nullptr);
            textes_.push_back(texte);
            continue;
        }
        auto* champ = new QLineEdit(valeur);
        champ->setObjectName(QStringLiteral("champ_") + noms[k]);
        formulaire->addRow(noms[k], champ);
        champs_.push_back(champ);
        listes_.push_back(nullptr);
        textes_.push_back(nullptr);
    }
    if (noms.isEmpty())
        formulaire->addRow(new QLabel(QStringLiteral(
            "Ce bloc n'a pas de réglage : son comportement est fixé par son type.")));
    colonne->addLayout(formulaire);

    auto* note = new QLabel(QStringLiteral(
        "Une valeur peut être une expression : « K » vaut ce que vaut K dans "
        "l'espace de travail au moment de la simulation."));
    note->setWordWrap(true);
    colonne->addWidget(note);

    auto* boutons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
    connect(boutons, &QDialogButtonBox::accepted, this, &QDialog::accept);
    connect(boutons, &QDialogButtonBox::rejected, this, &QDialog::reject);
    colonne->addWidget(boutons);
}

QString DialogueBloc::nomDemande() const { return champNom_->text().trimmed(); }

QLineEdit* DialogueBloc::champReglage(const QString& nom) const {
    for (int k = 0; k < noms_.size() && k < champs_.size(); ++k)
        if (noms_[k] == nom) return champs_[k];
    return nullptr;
}

QComboBox* DialogueBloc::listeReglage(const QString& nom) const {
    for (int k = 0; k < noms_.size() && k < listes_.size(); ++k)
        if (noms_[k] == nom) return listes_[k];
    return nullptr;
}

QPlainTextEdit* DialogueBloc::texteReglage(const QString& nom) const {
    for (int k = 0; k < noms_.size() && k < textes_.size(); ++k)
        if (noms_[k] == nom) return textes_[k];
    return nullptr;
}

QString DialogueBloc::valeurDe(int k) const {
    if (k < champs_.size() && champs_[k]) return champs_[k]->text();
    if (k < listes_.size() && listes_[k]) return listes_[k]->currentText();
    if (k < textes_.size() && textes_[k]) return textes_[k]->toPlainText();
    return QString();
}

QVector<QPair<QString, QString>> DialogueBloc::changements() const {
    // Seuls les champs touchés ressortent : renvoyer les autres écrirait
    // dans le modèle des réglages que personne n'a demandé de changer, et
    // ferait passer une expression pour une valeur qu'on a validée.
    QVector<QPair<QString, QString>> liste;
    for (int k = 0; k < noms_.size() && k < champs_.size(); ++k) {
        const QString avant = k < valeursOrigine_.size() ? valeursOrigine_[k] : QString();
        const QString apres = valeurDe(k);
        if (apres != avant) liste.push_back({noms_[k], apres});
    }
    return liste;
}
