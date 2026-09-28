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
#include <QScrollArea>
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
    volets_->addItems({QStringLiteral("Solveur"), QStringLiteral("Import/Export des données"),
                       QStringLiteral("Diagnostics")});
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
                                            "un ordre chacun, ode8 va à l'ordre huit ; "
                                            "ode14x et ode1be, implicites, pour les systèmes "
                                            "raides ; odeN : la formule que choisit sa méthode "
                                            "d'intégration, sans l'adapter ; "
                                            "FixedStepDiscrete : sans état continu. "
                                            "À pas variable — ode45 : Dormand-Prince ; ode23 : "
                                            "Bogacki-Shampine ; ode113 : Adams, pour les "
                                            "tolérances fines ; ode15s, ode23s, ode23t, "
                                            "ode23tb : pour les systèmes raides ; daessc : les "
                                            "BDF, d'ordre 1 à l'ordre maximal."));
    colonneSolveur->addWidget(groupeSolveur);

    auto* groupeOptions = new QGroupBox(QStringLiteral("Options du solveur"));
    auto* formulaireOptions = new QFormLayout(groupeOptions);
    nouveauChamp(QStringLiteral("FixedStep"), formulaireOptions, QStringLiteral("Pas fixe"),
                 QStringLiteral("Le pas d'intégration ; « auto » : le pas fondamental — le plus "
                                "grand commun diviseur des périodes d'échantillonnage —, ou le "
                                "cinquantième de la durée"));
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
    nouveauChamp(QStringLiteral("MaxOrder"), formulaireOptions,
                 QStringLiteral("Ordre maximal"),
                 QStringLiteral("ode15s et daessc : l'ordre le plus haut de leurs formules, "
                                "de 1 à 5"));
    nouveauChamp(QStringLiteral("ExtrapolationOrder"), formulaireOptions,
                 QStringLiteral("Ordre d'extrapolation"),
                 QStringLiteral("ode14x : l'ordre atteint en extrapolant, de 1 à 4"));
    nouveauChamp(QStringLiteral("NumberNewtonIterations"), formulaireOptions,
                 QStringLiteral("Itérations de Newton"),
                 QStringLiteral("ode14x et ode1be : les itérations de Newton à chaque pas"));
    nouvelleListe(QStringLiteral("ODENIntegrationMethod"), formulaireOptions,
                  QStringLiteral("Méthode d'intégration"),
                  {QStringLiteral("ode1"), QStringLiteral("ode2"), QStringLiteral("ode3"),
                   QStringLiteral("ode4"), QStringLiteral("ode5"), QStringLiteral("ode8")},
                  QStringLiteral("odeN : la formule appliquée à chaque pas, sans l'adapter"));
    nouvelleListe(QStringLiteral("ZeroCrossControl"), formulaireOptions,
                  QStringLiteral("Passages par zéro"),
                  {QStringLiteral("UseLocalSettings"), QStringLiteral("EnableAll"),
                   QStringLiteral("DisableAll")},
                  QStringLiteral("La détection des instants où un signal change de signe"));
    nouveauChamp(QStringLiteral("MaxConsecutiveZCs"), formulaireOptions,
                 QStringLiteral("Passages par zéro de suite"),
                 QStringLiteral("À pas variable : combien de passages par zéro de suite, sans "
                                "que le temps avance, avant le diagnostic"));
    nouveauChamp(QStringLiteral("MaxConsecutiveMinStep"), formulaireOptions,
                 QStringLiteral("Pas minimaux de suite"),
                 QStringLiteral("À pas variable : combien de pas de suite au pas minimal, sans "
                                "tenir la tolérance, avant le diagnostic"));
    colonneSolveur->addWidget(groupeOptions);
    colonneSolveur->addStretch(1);
    pages_->addWidget(pageSolveur);

    // --- Import/Export des données ---------------------------------------
    // Ce que la simulation lit dans l'espace de travail, et ce qu'elle y
    // relève : le volet « Data Import/Export » de Simulink.
    auto* pageDonnees = new QWidget;
    auto* colonneDonnees = new QVBoxLayout(pageDonnees);
    const QStringList ouiNon = {QStringLiteral("off"), QStringLiteral("on")};
    auto* formulaireLire = new QFormLayout;
    auto* groupeLire = new QGroupBox(QStringLiteral("Lire dans l'espace de travail"));
    groupeLire->setLayout(formulaireLire);
    auto* formulaireRelever = new QFormLayout;
    auto* groupeRelever = new QGroupBox(QStringLiteral("Relever dans l'espace de travail"));
    groupeRelever->setLayout(formulaireRelever);
    // Chaque interrupteur ouvre le champ qui le suit : le nom de la
    // variable, l'expression à lire.
    auto couple = [&](QFormLayout* formulaire, const QString& interrupteur,
                      const QString& nom, const QString& libelle, const QString& aide,
                      const QString& libelleNom, const QString& aideNom) {
        nouvelleListe(interrupteur, formulaire, libelle, ouiNon, aide);
        nouveauChamp(nom, formulaire, libelleNom, aideNom);
        couples_.insert(interrupteur, nom);
    };
    couple(formulaireLire, QStringLiteral("LoadExternalInput"), QStringLiteral("ExternalInput"),
           QStringLiteral("Entrées"),
           QStringLiteral("Les blocs Inport du modèle lisent l'expression qui suit"),
           QStringLiteral("    expression"),
           QStringLiteral("« [t, u] » : le temps, puis une colonne par élément des entrées ; "
                          "ou des variables séparées par des virgules, une par entrée"));
    couple(formulaireLire, QStringLiteral("LoadInitialState"), QStringLiteral("InitialState"),
           QStringLiteral("État initial"),
           QStringLiteral("La simulation part de l'état qui suit"),
           QStringLiteral("    expression"),
           QStringLiteral("Les états continus, dans l'ordre des colonnes de xout — l'état "
                          "final d'une simulation précédente s'y reprend tel quel"));
    const QString aideNom = QStringLiteral("Le champ du résultat de SIM qui la porte");
    couple(formulaireRelever, QStringLiteral("SaveTime"), QStringLiteral("TimeSaveName"),
           QStringLiteral("Temps"), QStringLiteral("Les instants relevés"),
           QStringLiteral("    nom"), aideNom);
    couple(formulaireRelever, QStringLiteral("SaveState"), QStringLiteral("StateSaveName"),
           QStringLiteral("États"), QStringLiteral("Les états continus, une colonne par état"),
           QStringLiteral("    nom"), aideNom);
    couple(formulaireRelever, QStringLiteral("SaveOutput"), QStringLiteral("OutputSaveName"),
           QStringLiteral("Sorties"), QStringLiteral("Les signaux des blocs Outport"),
           QStringLiteral("    nom"), aideNom);
    couple(formulaireRelever, QStringLiteral("SaveFinalState"),
           QStringLiteral("FinalStateName"), QStringLiteral("État final"),
           QStringLiteral("L'état au dernier instant, pour reprendre plus tard"),
           QStringLiteral("    nom"), aideNom);
    couple(formulaireRelever, QStringLiteral("SignalLogging"),
           QStringLiteral("SignalLoggingName"), QStringLiteral("Journal des signaux"),
           QStringLiteral("Les signaux dont le port a DataLogging à « on », en Dataset"),
           QStringLiteral("    nom"), aideNom);
    nouvelleListe(QStringLiteral("SaveFormat"), formulaireRelever, QStringLiteral("Format"),
                  {QStringLiteral("Array"), QStringLiteral("Structure"),
                   QStringLiteral("StructureWithTime"), QStringLiteral("Dataset")},
                  QStringLiteral("La forme des sorties : une matrice, une structure par "
                                 "sortie — sans ou avec le temps —, ou un Dataset"));
    auto* formulairePlus = new QFormLayout;
    auto* groupePlus = new QGroupBox(QStringLiteral("Réglages supplémentaires"));
    groupePlus->setLayout(formulairePlus);
    couple(formulairePlus, QStringLiteral("LimitDataPoints"), QStringLiteral("MaxDataPoints"),
           QStringLiteral("Limiter aux derniers instants"),
           QStringLiteral("Ne garder que les derniers instants relevés"),
           QStringLiteral("    combien"), QStringLiteral("Le nombre d'instants gardés"));
    nouveauChamp(QStringLiteral("Decimation"), formulairePlus, QStringLiteral("Décimation"),
                 QStringLiteral("Ne garder qu'un instant relevé sur n"));
    nouvelleListe(QStringLiteral("OutputOption"), formulairePlus,
                  QStringLiteral("Options de sortie"),
                  {QStringLiteral("RefineOutputTimes"), QStringLiteral("AdditionalOutputTimes"),
                   QStringLiteral("SpecifiedOutputTimes")},
                  QStringLiteral("À pas variable : affiner entre les pas du solveur, y ajouter "
                                 "des instants qu'il atteint, ou ne relever que ceux-là"));
    nouveauChamp(QStringLiteral("Refine"), formulairePlus,
                 QStringLiteral("Facteur d'affinage"),
                 QStringLiteral("Refine − 1 instants de plus entre deux pas, calculés sur "
                                "l'état interpolé"));
    nouveauChamp(QStringLiteral("OutputTimes"), formulairePlus,
                 QStringLiteral("Instants de sortie"),
                 QStringLiteral("Un vecteur d'instants, ou l'expression qui le donne"));
    colonneDonnees->addWidget(groupeLire);
    colonneDonnees->addWidget(groupeRelever);
    colonneDonnees->addWidget(groupePlus);
    colonneDonnees->addStretch(1);
    auto* defilement = new QScrollArea;
    defilement->setWidgetResizable(true);
    defilement->setFrameShape(QFrame::NoFrame);
    defilement->setWidget(pageDonnees);
    pages_->addWidget(defilement);

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
    auto* groupeSolveurDiag = new QGroupBox(QStringLiteral("Solveur à pas variable"));
    auto* formulaireSolveurDiag = new QFormLayout(groupeSolveurDiag);
    nouvelleListe(QStringLiteral("MinStepSizeMsg"), formulaireSolveurDiag,
                  QStringLiteral("le pas minimal ne tient pas la tolérance"),
                  {QStringLiteral("warning"), QStringLiteral("error")},
                  QStringLiteral("Plus de « pas minimaux de suite » au pas MinStep : le "
                                 "solveur avance quand même, ou s'arrête"));
    nouvelleListe(QStringLiteral("MaxConsecutiveZCsMsg"), formulaireSolveurDiag,
                  QStringLiteral("les passages par zéro s'enchaînent"), kNiveaux,
                  QStringLiteral("Plus de « passages par zéro de suite » sans que le temps "
                                 "avance : le modèle bascule sans fin (Zénon)"));
    colonneDiagnostics->addWidget(groupeSolveurDiag);
    auto* groupeDonneesDiag = new QGroupBox(QStringLiteral("Validité des données"));
    auto* formulaireDonneesDiag = new QFormLayout(groupeDonneesDiag);
    nouvelleListe(QStringLiteral("SignalInfNanChecking"), formulaireDonneesDiag,
                  QStringLiteral("une sortie vaut Inf ou NaN"), kNiveaux,
                  QStringLiteral("Une sortie de bloc infinie ou indéfinie à un pas majeur"));
    nouvelleListe(QStringLiteral("IntegerOverflowMsg"), formulaireDonneesDiag,
                  QStringLiteral("un entier déborde et se replie"), kNiveaux,
                  QStringLiteral("Un entier ou une virgule fixe sort des bornes de son type, "
                                 "et s'y replie"));
    nouvelleListe(QStringLiteral("IntegerSaturationMsg"), formulaireDonneesDiag,
                  QStringLiteral("un entier déborde et sature"), kNiveaux,
                  QStringLiteral("… et s'y arrête : SaturateOnIntegerOverflow"));
    colonneDiagnostics->addWidget(groupeDonneesDiag);
    colonneDiagnostics->addStretch(1);
    pages_->addWidget(pageDiagnostics);

    volets_->setCurrentRow(0);
    connect(type_, &QComboBox::currentIndexChanged, this, [this](int) { typeChange(); });
    connect(solveur_, &QComboBox::currentIndexChanged, this, [this](int) { solveurChange(); });
    for (const QString& interrupteur : couples_.keys())
        connect(listes_.value(interrupteur), &QComboBox::currentIndexChanged, this,
                [this](int) { donneesChange(); });
    connect(listes_.value(QStringLiteral("OutputOption")), &QComboBox::currentIndexChanged,
            this, [this](int) { donneesChange(); });
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
                               QStringLiteral("AbsTol"), QStringLiteral("MaxConsecutiveZCs"),
                               QStringLiteral("MaxConsecutiveMinStep")})
        champs_.value(nom)->setEnabled(variable);
    for (const QString& nom : {QStringLiteral("MinStepSizeMsg"),
                               QStringLiteral("MaxConsecutiveZCsMsg")})
        listes_.value(nom)->setEnabled(variable);
    solveurChange();
    donneesChange();
}

// Le volet des données : un nom ne se règle que son interrupteur à « on » ;
// les options de sortie ne valent qu'à pas variable, le facteur d'affinage
// pour RefineOutputTimes, les instants de sortie pour les deux autres.
void DialogueConfiguration::donneesChange() {
    for (auto it = couples_.cbegin(); it != couples_.cend(); ++it)
        champs_.value(it.value())
            ->setEnabled(listes_.value(it.key())->currentText() == QLatin1String("on"));
    const bool variable = type_->currentText() == QLatin1String("Variable-step");
    QComboBox* options = listes_.value(QStringLiteral("OutputOption"));
    const bool affine = options->currentText() == QLatin1String("RefineOutputTimes");
    options->setEnabled(variable);
    champs_.value(QStringLiteral("Refine"))->setEnabled(variable && affine);
    champs_.value(QStringLiteral("OutputTimes"))->setEnabled(variable && !affine);
}

// Certaines options n'appartiennent qu'à un solveur : l'ordre maximal à
// ode15s et daessc, l'extrapolation à ode14x, les itérations de Newton à
// ode14x et ode1be, la méthode d'intégration à odeN. Elles ne se règlent
// que lui choisi.
void DialogueConfiguration::solveurChange() {
    const QString choisi = solveur_->currentText().toLower();
    champs_.value(QStringLiteral("MaxOrder"))
        ->setEnabled(choisi == QLatin1String("ode15s") || choisi == QLatin1String("daessc"));
    listes_.value(QStringLiteral("ODENIntegrationMethod"))
        ->setEnabled(choisi == QLatin1String("oden"));
    champs_.value(QStringLiteral("ExtrapolationOrder"))
        ->setEnabled(choisi == QLatin1String("ode14x"));
    champs_.value(QStringLiteral("NumberNewtonIterations"))
        ->setEnabled(choisi == QLatin1String("ode14x") || choisi == QLatin1String("ode1be"));
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
