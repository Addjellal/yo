// DialogueBloc.cpp — les réglages d'un bloc.
#include "DialogueBloc.h"

#include <QDialogButtonBox>
#include <QFormLayout>
#include <QLabel>
#include <QLineEdit>
#include <QVBoxLayout>

DialogueBloc::DialogueBloc(const QString& nomBloc, const QString& type,
                           const QStringList& noms, const QStringList& valeurs,
                           QWidget* parent)
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
        auto* champ = new QLineEdit(k < valeurs.size() ? valeurs[k] : QString());
        champ->setObjectName(QStringLiteral("champ_") + noms[k]);
        formulaire->addRow(noms[k], champ);
        champs_.push_back(champ);
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

QVector<QPair<QString, QString>> DialogueBloc::changements() const {
    // Seuls les champs touchés ressortent : renvoyer les autres écrirait
    // dans le modèle des réglages que personne n'a demandé de changer, et
    // ferait passer une expression pour une valeur qu'on a validée.
    QVector<QPair<QString, QString>> liste;
    for (int k = 0; k < noms_.size() && k < champs_.size(); ++k) {
        const QString avant = k < valeursOrigine_.size() ? valeursOrigine_[k] : QString();
        const QString apres = champs_[k]->text();
        if (apres != avant) liste.push_back({noms_[k], apres});
    }
    return liste;
}
