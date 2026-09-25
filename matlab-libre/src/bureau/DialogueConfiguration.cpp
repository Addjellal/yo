// DialogueConfiguration.cpp — les paramètres de configuration d'un modèle.
#include "DialogueConfiguration.h"

#include <QComboBox>
#include <QDialogButtonBox>
#include <QFormLayout>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QStackedWidget>
#include <QVBoxLayout>

namespace {

// Les diagnostics prennent l'une de ces trois valeurs, comme dans Simulink.
const QStringList kNiveaux = {QStringLiteral("none"), QStringLiteral("warning"),
                              QStringLiteral("error")};

}  // namespace

DialogueConfiguration::DialogueConfiguration(const QString& modele,
                                             const QMap<QString, QString>& valeurs,
                                             const QStringList& fixes,
                                             const QStringList& variables, QWidget* parent)
    : QDialog(parent), fixes_(fixes), variables_(variables) {
    setWindowTitle(QStringLiteral("Paramètres de configuration — %1").arg(modele));
    setObjectName(QStringLiteral("dialogueConfiguration"));
    resize(720, 460);

    auto* colonne = new QVBoxLayout(this);
    auto* corps = new QHBoxLayout;
    volets_ = new QListWidget;
    volets_->addItems({QStringLiteral("Solveur"), QStringLiteral("Diagnostics")});
    volets_->setMaximumWidth(170);
    pages_ = new QStackedWidget;
    corps->addWidget(volets_);
    corps->addWidget(pages_, 1);
    colonne->addLayout(corps, 1);
    connect(volets_, &QListWidget::currentRowChanged, pages_,
            &QStackedWidget::setCurrentIndex);

    auto nouveauChamp = [&](const QString& nom, QFormLayout* formulaire,
                            const QString& libelle, const QString& aide) {
        auto* champ = new QLineEdit(valeurs.value(nom));
        champ->setObjectName(QStringLiteral("champ_") + nom);
        champ->setToolTip(aide);
        formulaire->addRow(libelle, champ);
        champs_.insert(nom, champ);
        ordre_ << nom;
        return champ;
    };
    auto nouvelleListe = [&](const QString& nom, QFormLayout* formulaire,
                             const QString& libelle, const QStringList& choix,
                             const QString& aide) {
        auto* liste = new QComboBox;
        liste->addItems(choix);
        const int rang = liste->findText(valeurs.value(nom), Qt::MatchFixedString);
        if (rang >= 0) liste->setCurrentIndex(rang);
        liste->setObjectName(QStringLiteral("liste_") + nom);
        liste->setToolTip(aide);
        formulaire->addRow(libelle, liste);
        listes_.insert(nom, liste);
        ordre_ << nom;
        return liste;
    };

    // --- Solveur ---------------------------------------------------------
    auto* pageSolveur = new QWidget;
    auto* colonneSolveur = new QVBoxLayout(pageSolveur);
    auto* groupeTemps = new QGroupBox(QStringLiteral("Temps de simulation"));
    auto* formulaireTemps = new QFormLayout(groupeTemps);
    nouveauChamp(QStringLiteral("StartTime"), formulaireTemps,
                 QStringLiteral("Temps de début"),
                 QStringLiteral("L'instant où la simulation commence"));
    nouveauChamp(QStringLiteral("StopTime"), formulaireTemps, QStringLiteral("Temps d'arrêt"),
                 QStringLiteral("L'instant où elle s'arrête ; Inf avec un bloc Stop Simulation"));
    colonneSolveur->addWidget(groupeTemps);

    auto* groupeSolveur = new QGroupBox(QStringLiteral("Choix du solveur"));
    auto* formulaireSolveur = new QFormLayout(groupeSolveur);
    type_ = nouvelleListe(QStringLiteral("SolverType"), formulaireSolveur,
                          QStringLiteral("Type"),
                          {QStringLiteral("Fixed-step"), QStringLiteral("Variable-step")},
                          QStringLiteral("À pas fixe, le pas est donné ; à pas variable, "
                                         "il suit les tolérances"));
    solveur_ = nouvelleListe(QStringLiteral("Solver"), formulaireSolveur,
                             QStringLiteral("Solveur"), fixes_ + variables_,
                             QStringLiteral("À pas fixe — ode1 : Euler ; ode2 à ode5 gagnent "
                                            "un ordre chacun ; FixedStepDiscrete : sans état "
                                            "continu. À pas variable — ode45 : Dormand-Prince ; "
                                            "ode23 : Bogacki-Shampine ; ode23s : pour les "
                                            "systèmes raides."));
    colonneSolveur->addWidget(groupeSolveur);

    auto* groupeOptions = new QGroupBox(QStringLiteral("Options du solveur"));
    auto* formulaireOptions = new QFormLayout(groupeOptions);
    nouveauChamp(QStringLiteral("FixedStep"), formulaireOptions, QStringLiteral("Pas fixe"),
                 QStringLiteral("Le pas d'intégration ; « auto » en prend le cinquantième "
                                "de la durée"));
    nouveauChamp(QStringLiteral("MaxStep"), formulaireOptions, QStringLiteral("Pas maximal"),
                 QStringLiteral("À pas variable : le plus grand pas permis"));
    nouveauChamp(QStringLiteral("MinStep"), formulaireOptions, QStringLiteral("Pas minimal"),
                 QStringLiteral("À pas variable : le plus petit pas permis"));
    nouveauChamp(QStringLiteral("InitialStep"), formulaireOptions,
                 QStringLiteral("Pas initial"),
                 QStringLiteral("À pas variable : le premier pas essayé"));
    nouveauChamp(QStringLiteral("RelTol"), formulaireOptions,
                 QStringLiteral("Tolérance relative"),
                 QStringLiteral("À pas variable : l'erreur relative admise par pas"));
    nouveauChamp(QStringLiteral("AbsTol"), formulaireOptions,
                 QStringLiteral("Tolérance absolue"),
                 QStringLiteral("À pas variable : l'erreur absolue admise par pas"));
    nouvelleListe(QStringLiteral("ZeroCrossControl"), formulaireOptions,
                  QStringLiteral("Passages par zéro"),
                  {QStringLiteral("UseLocalSettings"), QStringLiteral("EnableAll"),
                   QStringLiteral("DisableAll")},
                  QStringLiteral("La détection des instants où un signal change de signe"));
    colonneSolveur->addWidget(groupeOptions);
    colonneSolveur->addStretch(1);
    pages_->addWidget(pageSolveur);

    // --- Diagnostics -----------------------------------------------------
    auto* pageDiagnostics = new QWidget;
    auto* colonneDiagnostics = new QVBoxLayout(pageDiagnostics);
    auto* groupeDiagnostics = new QGroupBox(QStringLiteral("Que faire quand…"));
    auto* formulaireDiagnostics = new QFormLayout(groupeDiagnostics);
    nouvelleListe(QStringLiteral("AlgebraicLoopMsg"), formulaireDiagnostics,
                  QStringLiteral("une boucle est algébrique"), kNiveaux,
                  QStringLiteral("Elle est résolue par la méthode de Newton ; faut-il le "
                                 "dire, ou la refuser ?"));
    nouvelleListe(QStringLiteral("UnconnectedInputMsg"), formulaireDiagnostics,
                  QStringLiteral("une entrée n'est pas reliée"), kNiveaux,
                  QStringLiteral("Elle vaut zéro ; faut-il le dire, ou la refuser ?"));
    nouvelleListe(QStringLiteral("UnconnectedOutputMsg"), formulaireDiagnostics,
                  QStringLiteral("une sortie n'est reliée à rien"), kNiveaux,
                  QStringLiteral("Son signal n'est lu par personne"));
    colonneDiagnostics->addWidget(groupeDiagnostics);
    colonneDiagnostics->addStretch(1);
    pages_->addWidget(pageDiagnostics);

    volets_->setCurrentRow(0);
    connect(type_, &QComboBox::currentIndexChanged, this, [this](int) { typeChange(); });
    typeChange();
    // Ce que la boîte montre en s'ouvrant est la référence des changements :
    // un réglage absent du modèle s'affiche à sa première valeur, et ne doit
    // pas ressortir pour autant si personne n'y touche.
    for (const QString& nom : ordre_) affiches_.insert(nom, valeurDe(nom));

    auto* note = new QLabel(QStringLiteral(
        "Une valeur numérique peut être une expression : « Tfin » vaut ce que vaut Tfin "
        "dans l'espace de travail au moment de la simulation."));
    note->setWordWrap(true);
    colonne->addWidget(note);
    auto* boutons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
    connect(boutons, &QDialogButtonBox::accepted, this, &QDialog::accept);
    connect(boutons, &QDialogButtonBox::rejected, this, &QDialog::reject);
    colonne->addWidget(boutons);
}

// Le type décide des solveurs offerts et des options qui valent : un pas
// fixe n'a pas de tolérance, un pas variable n'a pas de pas fixe.
void DialogueConfiguration::typeChange() {
    const bool variable = type_->currentText() == QLatin1String("Variable-step");
    const QString avant = solveur_->currentText();
    const QStringList offerts = variable ? variables_ : fixes_;
    solveur_->blockSignals(true);
    solveur_->clear();
    if (offerts.isEmpty()) {
        solveur_->addItem(variable ? QStringLiteral("(aucun solveur à pas variable)")
                                   : QStringLiteral("ode1"));
        solveur_->setEnabled(false);
    } else {
        solveur_->addItems(offerts);
        solveur_->setEnabled(true);
        const int rang = solveur_->findText(avant, Qt::MatchFixedString);
        solveur_->setCurrentIndex(rang >= 0 ? rang : 0);
    }
    solveur_->blockSignals(false);
    champs_.value(QStringLiteral("FixedStep"))->setEnabled(!variable);
    for (const QString& nom : {QStringLiteral("MaxStep"), QStringLiteral("MinStep"),
                               QStringLiteral("InitialStep"), QStringLiteral("RelTol"),
                               QStringLiteral("AbsTol")})
        champs_.value(nom)->setEnabled(variable);
}

QLineEdit* DialogueConfiguration::champ(const QString& nom) const {
    return champs_.value(nom, nullptr);
}

QComboBox* DialogueConfiguration::liste(const QString& nom) const {
    return listes_.value(nom, nullptr);
}

QString DialogueConfiguration::valeurDe(const QString& nom) const {
    if (QLineEdit* champ = champs_.value(nom, nullptr)) return champ->text().trimmed();
    if (QComboBox* liste = listes_.value(nom, nullptr)) return liste->currentText();
    return QString();
}

QVector<QPair<QString, QString>> DialogueConfiguration::changements() const {
    // Seuls les réglages touchés ressortent : réécrire les autres poserait
    // sur le modèle des valeurs par défaut que personne n'a choisies.
    QVector<QPair<QString, QString>> liste;
    for (const QString& nom : ordre_) {
        if (nom == QLatin1String("Solver") && !solveur_->isEnabled()) continue;
        const QString apres = valeurDe(nom);
        if (apres != affiches_.value(nom)) liste.push_back({nom, apres});
    }
    return liste;
}
