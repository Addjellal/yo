// FenetreSimulink.cpp — la fenêtre Simulink du bureau.
#include "FenetreSimulink.h"

#include <QHBoxLayout>
#include <QHeaderView>
#include <QLabel>
#include <QListWidget>
#include <QPushButton>
#include <QSplitter>
#include <QTreeWidget>
#include <QVBoxLayout>
#include <QWidget>

#include "Ruban.h"
#include "Theme.h"

namespace {

// La bibliothèque, rangée comme celle de Simulink : par ce que le bloc
// fait, non par ordre alphabétique. Les paramètres donnés sont ceux
// qu'ADD_BLOCK reconnaît, avec une valeur par défaut qui simule.
const BlocBibliotheque blocs[] = {
    {"Sources", "constant", "Une valeur constante", "'Value', 1"},
    {"Sources", "step", "Un échelon à l'instant dit", "'Time', 1, 'After', 1"},
    {"Sources", "ramp", "Une rampe de pente donnée", "'Slope', 1"},
    {"Sources", "sine", "Une sinusoïde", "'Amplitude', 1, 'Frequency', 1"},
    {"Sources", "inport", "L'entrée du modèle, vue par LINMOD", "'Port', 1"},
    {"Sources", "fromworkspace", "Un signal lu dans l'espace de travail",
     "'VariableName', 'signal'"},

    {"Opérations", "gain", "Multiplie par un gain", "'Gain', 1"},
    {"Opérations", "bias", "Ajoute une constante", "'Bias', 0"},
    {"Opérations", "sum", "Somme ses entrées, selon les signes", "'Signs', '+-'"},
    {"Opérations", "product", "Multiplie ses entrées", ""},
    {"Opérations", "abs", "Valeur absolue", ""},
    {"Opérations", "sign", "Le signe : -1, 0 ou 1", ""},
    {"Opérations", "math", "Carré, racine, exponentielle, logarithme, inverse",
     "'Operator', 'square'"},
    {"Opérations", "trigonometry", "Sinus, cosinus, tangente et leurs réciproques",
     "'Operator', 'sin'"},
    {"Opérations", "minmax", "Le plus petit ou le plus grand de ses entrées",
     "'Function', 'max'"},

    {"Logique", "logic", "ET, OU, NON, OU exclusif", "'Operator', 'AND'"},
    {"Logique", "relational", "Compare deux entrées", "'Operator', '<'"},
    {"Logique", "switch", "Aiguille selon un seuil sur la deuxième entrée",
     "'Threshold', 0"},

    {"Non-linéarités", "saturation", "Borne le signal",
     "'UpperLimit', 1, 'LowerLimit', -1"},
    {"Non-linéarités", "deadzone", "Annule une bande autour de zéro",
     "'UpperValue', 0.5, 'LowerValue', -0.5"},
    {"Non-linéarités", "quantizer", "Arrondit à un pas donné",
     "'QuantizationInterval', 0.5"},
    {"Non-linéarités", "lookup", "Interpole dans une table",
     "'BreakpointsData', [0 1 2], 'TableData', [0 1 4]"},
    {"Non-linéarités", "ratelimiter", "Borne la pente du signal",
     "'RisingSlewLimit', 1, 'FallingSlewLimit', -1"},
    {"Non-linéarités", "relay", "Bascule à deux seuils",
     "'OnSwitch', 0.5, 'OffSwitch', -0.5, 'OnOutput', 1, 'OffOutput', 0"},

    {"Continu", "integrator", "Intègre : 1/s", "'InitialCondition', 0"},
    {"Continu", "derivative", "Dérive : du/dt", ""},
    {"Continu", "transferfcn", "Une transmittance en s",
     "'Numerator', 1, 'Denominator', [1 1]"},
    {"Continu", "statespace", "Une représentation d'état",
     "'A', 0, 'B', 1, 'C', 1, 'D', 0"},
    {"Continu", "pidcontroller", "Un PID, dérivée filtrée",
     "'P', 1, 'I', 0, 'D', 0, 'N', 100"},
    {"Continu", "transportdelay", "Retarde le signal d'une durée",
     "'DelayTime', 1, 'InitialOutput', 0"},

    {"Discret", "delay", "Retard d'un pas : 1/z", "'InitialCondition', 0"},
    {"Discret", "memory", "La valeur du pas précédent", "'InitialCondition', 0"},
    {"Discret", "zoh", "Tenue d'ordre zéro", "'SampleTime', 0.1"},
    {"Discret", "discreteintegrator", "Intègre à période fixe",
     "'SampleTime', 0.1, 'IntegratorMethod', 'ForwardEuler'"},
    {"Discret", "discretetransferfcn", "Une transmittance en z",
     "'Numerator', [0 1], 'Denominator', [1 -0.5], 'SampleTime', 0.1"},
    {"Discret", "discretestatespace", "Une représentation d'état échantillonnée",
     "'A', 0.5, 'B', 1, 'C', 1, 'D', 0, 'SampleTime', 0.1"},

    {"Sorties", "outport", "La sortie du modèle, vue par LINMOD", "'Port', 1"},
    {"Sorties", "scope", "Un oscilloscope : le signal est relevé", ""},
    {"Sorties", "toworkspace", "Dépose le signal dans l'espace de travail",
     "'VariableName', 'simout'"},
    {"Sorties", "terminator", "Ferme une sortie qu'on ne lit pas", ""},

    {nullptr, nullptr, nullptr, nullptr},
};

}  // namespace

const BlocBibliotheque* bibliothequeSimulink() { return blocs; }

FenetreSimulink::FenetreSimulink(QWidget* parent) : QMainWindow(parent) {
    setWindowTitle(QStringLiteral("Simulink — bibliothèque et modèles"));
    setWindowIcon(iconeDessinee(QStringLiteral("simulink"), 32));
    resize(880, 560);

    auto* separateur = new QSplitter(Qt::Horizontal);

    // --- à gauche : la bibliothèque -----------------------------------
    auto* gauche = new QWidget;
    auto* colonneGauche = new QVBoxLayout(gauche);
    colonneGauche->setContentsMargins(8, 8, 8, 8);
    auto* titreBibliotheque = new QLabel(QStringLiteral("Bibliothèque de blocs"));
    QFont grasse = titreBibliotheque->font();
    grasse.setBold(true);
    titreBibliotheque->setFont(grasse);
    colonneGauche->addWidget(titreBibliotheque);

    bibliotheque_ = new QTreeWidget;
    bibliotheque_->setHeaderLabels({QStringLiteral("Bloc"), QStringLiteral("Ce qu'il fait")});
    bibliotheque_->header()->setStretchLastSection(true);
    bibliotheque_->setColumnWidth(0, 210);
    colonneGauche->addWidget(bibliotheque_, 1);

    description_ = new QLabel;
    description_->setWordWrap(true);
    description_->setTextInteractionFlags(Qt::TextSelectableByMouse);
    description_->setStyleSheet(
        QStringLiteral("color:%1;").arg(theme::texteEteint().name()));
    colonneGauche->addWidget(description_);

    bInserer_ = new QPushButton(QStringLiteral("Insérer la ligne ADD_BLOCK"));
    bInserer_->setEnabled(false);
    colonneGauche->addWidget(bInserer_);
    separateur->addWidget(gauche);

    // --- à droite : les modèles de l'espace de travail -----------------
    auto* droite = new QWidget;
    auto* colonneDroite = new QVBoxLayout(droite);
    colonneDroite->setContentsMargins(8, 8, 8, 8);
    auto* titreModeles = new QLabel(QStringLiteral("Modèles de l'espace de travail"));
    titreModeles->setFont(grasse);
    colonneDroite->addWidget(titreModeles);

    modeles_ = new QListWidget;
    colonneDroite->addWidget(modeles_, 1);

    etatModeles_ = new QLabel;
    etatModeles_->setWordWrap(true);
    etatModeles_->setStyleSheet(
        QStringLiteral("color:%1;").arg(theme::texteEteint().name()));
    colonneDroite->addWidget(etatModeles_);

    bOuvrir_ = new QPushButton(QStringLiteral("Ouvrir le schéma"));
    bSimuler_ = new QPushButton(QStringLiteral("Simuler et tracer"));
    auto* bNouveau = new QPushButton(QStringLiteral("Nouveau modèle"));
    bOuvrir_->setEnabled(false);
    bSimuler_->setEnabled(false);
    colonneDroite->addWidget(bOuvrir_);
    colonneDroite->addWidget(bSimuler_);
    colonneDroite->addWidget(bNouveau);
    separateur->addWidget(droite);
    separateur->setStretchFactor(0, 3);
    separateur->setStretchFactor(1, 2);
    setCentralWidget(separateur);

    construireBibliotheque();
    definirModeles({});

    connect(bibliotheque_, &QTreeWidget::currentItemChanged, this,
            &FenetreSimulink::montrerBloc);
    connect(bibliotheque_, &QTreeWidget::itemDoubleClicked, this,
            [this](QTreeWidgetItem*, int) { insererBloc(); });
    connect(bInserer_, &QPushButton::clicked, this, &FenetreSimulink::insererBloc);
    connect(modeles_, &QListWidget::currentRowChanged, this,
            [this](int) { ajusterBoutons(); });
    connect(modeles_, &QListWidget::itemDoubleClicked, this,
            [this](QListWidgetItem*) { ouvrirSchema(); });
    connect(bOuvrir_, &QPushButton::clicked, this, &FenetreSimulink::ouvrirSchema);
    connect(bSimuler_, &QPushButton::clicked, this, &FenetreSimulink::simuler);
    connect(bNouveau, &QPushButton::clicked, this, &FenetreSimulink::nouveauModele);
}

void FenetreSimulink::construireBibliotheque() {
    bibliotheque_->clear();
    QTreeWidgetItem* famille = nullptr;
    QString familleCourante;
    for (const BlocBibliotheque* b = blocs; b->famille; ++b) {
        // Le fichier est en UTF-8 : lire « Opérations » comme du Latin-1
        // donnait « OpÃ©rations » dans l'arbre.
        if (familleCourante != QString::fromUtf8(b->famille)) {
            familleCourante = QString::fromUtf8(b->famille);
            famille = new QTreeWidgetItem(bibliotheque_);
            famille->setText(0, familleCourante);
            QFont grasse = famille->font(0);
            grasse.setBold(true);
            famille->setFont(0, grasse);
            famille->setExpanded(true);
        }
        auto* entree = new QTreeWidgetItem(famille);
        entree->setText(0, QLatin1String(b->type));
        entree->setText(1, QString::fromUtf8(b->resume));
        entree->setData(0, Qt::UserRole, QLatin1String(b->type));
        entree->setData(1, Qt::UserRole, QString::fromUtf8(b->parametres));
    }
}

void FenetreSimulink::definirModeles(const QStringList& noms) {
    const QString choisi = modeleChoisi();
    modeles_->clear();
    for (const QString& nom : noms) modeles_->addItem(nom);
    if (!choisi.isEmpty()) {
        // Garder la sélection quand le modèle est toujours là : sans cela,
        // chaque commande tapée dans la console la ferait sauter.
        for (int k = 0; k < modeles_->count(); ++k)
            if (modeles_->item(k)->text() == choisi) modeles_->setCurrentRow(k);
    }
    if (modeles_->currentRow() < 0 && modeles_->count() > 0) modeles_->setCurrentRow(0);
    if (noms.isEmpty()) {
        etatModeles_->setText(QStringLiteral(
            "Aucun modèle dans l'espace de travail. « Nouveau modèle » en écrit "
            "un ; il apparaîtra ici dès qu'il aura été exécuté."));
    } else {
        etatModeles_->setText(QStringLiteral("%1 modèle(s). Les variables sont "
                                             "partagées : un paramètre écrit « K » "
                                             "vaut ce que vaut K ici.")
                                  .arg(noms.size()));
    }
    ajusterBoutons();
}

QString FenetreSimulink::modeleChoisi() const {
    QListWidgetItem* item = modeles_->currentItem();
    return item ? item->text() : QString();
}

QString FenetreSimulink::ligneInsertion() const {
    QTreeWidgetItem* item = bibliotheque_->currentItem();
    if (!item || item->data(0, Qt::UserRole).toString().isEmpty()) return QString();
    const QString type = item->data(0, Qt::UserRole).toString();
    const QString parametres = item->data(1, Qt::UserRole).toString();
    // Un nom par défaut tiré du type : il suffit d'un nom, et celui-là se
    // renomme d'un geste dans l'éditeur.
    QString ligne = QStringLiteral("m = add_block(m, '%1', '%1'").arg(type);
    if (!parametres.isEmpty()) ligne += QStringLiteral(", ") + parametres;
    ligne += QStringLiteral(");");
    return ligne;
}

QString FenetreSimulink::squeletteModele() {
    return QStringLiteral(
        "%% Un modele Simulink : des blocs, des liens, une simulation.\n"
        "%  Les variables sont celles de l'espace de travail : un parametre\n"
        "%  ecrit entre apostrophes est une expression, evaluee au moment de\n"
        "%  la simulation. Changer K ci-dessous et relancer suffit.\n"
        "K = 2;\n"
        "\n"
        "m = new_system('monModele');\n"
        "m = add_block(m, 'step', 'consigne', 'Time', 0, 'After', 1);\n"
        "m = add_block(m, 'sum', 'ecart', 'Signs', '+-');\n"
        "m = add_block(m, 'gain', 'correcteur', 'Gain', 'K');\n"
        "m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);\n"
        "m = add_line(m, 'consigne', 'ecart', 1);\n"
        "m = add_line(m, 'sortie', 'ecart', 2);\n"
        "m = add_line(m, 'ecart', 'correcteur');\n"
        "m = add_line(m, 'correcteur', 'sortie');\n"
        "\n"
        "open_system(m);              %% le schema\n"
        "r = sim(m, 5, 0.001);        %% la simulation\n"
        "figure; simplot(r, {'consigne', 'sortie'});\n");
}

void FenetreSimulink::montrerBloc() {
    QTreeWidgetItem* item = bibliotheque_->currentItem();
    const QString type = item ? item->data(0, Qt::UserRole).toString() : QString();
    bInserer_->setEnabled(!type.isEmpty());
    if (type.isEmpty()) {
        description_->setText(QStringLiteral(
            "Choisissez un bloc : sa ligne ADD_BLOCK s'écrira dans l'éditeur."));
        return;
    }
    description_->setText(QStringLiteral("%1 — %2\n%3")
                              .arg(type, item->text(1), ligneInsertion()));
}

void FenetreSimulink::ajusterBoutons() {
    const bool choisi = !modeleChoisi().isEmpty();
    bOuvrir_->setEnabled(choisi);
    bSimuler_->setEnabled(choisi);
}

void FenetreSimulink::insererBloc() {
    const QString ligne = ligneInsertion();
    if (!ligne.isEmpty()) emit insertionDemandee(ligne);
}

void FenetreSimulink::ouvrirSchema() {
    const QString nom = modeleChoisi();
    if (!nom.isEmpty()) emit commandeDemandee(QStringLiteral("open_system(%1)").arg(nom));
}

void FenetreSimulink::simuler() {
    const QString nom = modeleChoisi();
    if (nom.isEmpty()) return;
    // Le résultat reste dans l'espace de travail sous « resultatSimulink » :
    // la simulation n'est pas un cul-de-sac, on la reprend au clavier.
    emit commandeDemandee(
        QStringLiteral("resultatSimulink = sim(%1); figure; simplot(resultatSimulink)")
            .arg(nom));
}

void FenetreSimulink::nouveauModele() {
    emit nouveauModeleDemande(squeletteModele());
}
