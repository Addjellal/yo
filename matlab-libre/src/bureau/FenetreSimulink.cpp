// FenetreSimulink.cpp — l'éditeur Simulink du bureau.
#include "FenetreSimulink.h"

#include <QAction>
#include <QGuiApplication>
#include <QDockWidget>
#include <QFrame>
#include <QEvent>
#include <QResizeEvent>
#include <QHBoxLayout>
#include <QHeaderView>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QPalette>
#include <QPushButton>
#include <QScreen>
#include <QStatusBar>
#include <QToolBar>
#include <QTreeWidget>
#include <QVBoxLayout>
#include <QWidget>

#include "Ruban.h"
#include "Theme.h"
#include "VueFigure.h"

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
    setWindowTitle(QStringLiteral("Simulink — éditeur de schémas"));
    setWindowIcon(iconeDessinee(QStringLiteral("simulink"), 32));
    // Une fenêtre pleine, pas un panneau : c'est ainsi que MATLAB ouvre
    // Simulink, et le bureau reste utilisable derrière. Elle prend la
    // presque totalité de l'écran — un schéma large ne se lit pas dans
    // une lucarne — sans pour autant se mettre en plein écran, ce qui
    // cacherait le bureau qu'on veut garder sous la main.
    QRect ecran;
    if (QScreen* principal = QGuiApplication::primaryScreen())
        ecran = principal->availableGeometry();
    // En deçà, le compte de pourcentage donnerait une lucarne : on garde
    // alors la taille de référence, quitte à déborder d'un écran étroit.
    if (ecran.width() >= 1340 && ecran.height() >= 900) {
        QSize taille(int(ecran.width() * 0.88), int(ecran.height() * 0.88));
        resize(taille);
        move(ecran.left() + (ecran.width() - taille.width()) / 2,
             ecran.top() + (ecran.height() - taille.height()) / 2);
    } else {
        resize(1180, 780);
    }

    construireBarre();

    // --- au centre : la toile, où le schéma se dessine ------------------
    auto* centre = new QWidget;
    auto* colonne = new QVBoxLayout(centre);
    colonne->setContentsMargins(0, 0, 0, 0);
    colonne->setSpacing(0);

    titreToile_ = new QLabel;
    titreToile_->setContentsMargins(10, 6, 10, 6);
    QFont grasse = titreToile_->font();
    grasse.setBold(true);
    titreToile_->setFont(grasse);
    colonne->addWidget(titreToile_);

    auto* cadre = new QFrame;
    cadre->setFrameShape(QFrame::StyledPanel);
    // La toile est centrée dans son cadre et gardée aux proportions du
    // schéma : les ressorts autour d'elle absorbent ce qui reste.
    auto* dansCadre = new QVBoxLayout(cadre);
    dansCadre->setContentsMargins(2, 2, 2, 2);
    // La zone n'a pas de mise en page : la toile y est posée à la main,
    // aux proportions du schéma. Passer par un ressort et une taille
    // maximale faisait le contraire de ce qu'on voulait — la contrainte
    // rétrécissait la zone, qui rétrécissait la contrainte.
    zoneToile_ = new QWidget;
    zoneToile_->setMinimumSize(200, 150);
    // Le fond de la zone est celui de la toile : un schéma en long ne
    // remplit pas un cadre carré, et une bordure grise autour ferait
    // croire à un défaut plutôt qu'à de la marge.
    zoneToile_->setAutoFillBackground(true);
    QPalette fond = zoneToile_->palette();
    fond.setColor(QPalette::Window, Qt::white);
    zoneToile_->setPalette(fond);
    zoneToile_->installEventFilter(this);
    dansCadre->addWidget(zoneToile_, 1);
    toile_ = new VueFigure(zoneToile_);
    toile_->setGeometry(0, 0, 200, 150);
    colonne->addWidget(cadre, 1);
    setCentralWidget(centre);

    // --- à gauche : la bibliothèque, détachable -------------------------
    dockBibliotheque_ = new QDockWidget(QStringLiteral("Bibliothèque de blocs"), this);
    dockBibliotheque_->setObjectName(QStringLiteral("dockBibliothequeSimulink"));
    auto* gauche = new QWidget;
    auto* colonneGauche = new QVBoxLayout(gauche);
    colonneGauche->setContentsMargins(6, 6, 6, 6);
    bibliotheque_ = new QTreeWidget;
    bibliotheque_->setHeaderLabels({QStringLiteral("Bloc"), QStringLiteral("Ce qu'il fait")});
    bibliotheque_->header()->setStretchLastSection(true);
    bibliotheque_->setColumnWidth(0, 190);
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
    dockBibliotheque_->setWidget(gauche);
    addDockWidget(Qt::LeftDockWidgetArea, dockBibliotheque_);

    // --- à droite : les modèles, et l'inventaire de celui qu'on regarde -
    auto* dockModeles = new QDockWidget(QStringLiteral("Modèles de l'espace de travail"),
                                        this);
    dockModeles->setObjectName(QStringLiteral("dockModelesSimulink"));
    auto* droite = new QWidget;
    auto* colonneDroite = new QVBoxLayout(droite);
    colonneDroite->setContentsMargins(6, 6, 6, 6);
    modeles_ = new QListWidget;
    modeles_->setMaximumHeight(150);
    colonneDroite->addWidget(modeles_);
    etatModeles_ = new QLabel;
    etatModeles_->setWordWrap(true);
    etatModeles_->setStyleSheet(
        QStringLiteral("color:%1;").arg(theme::texteEteint().name()));
    colonneDroite->addWidget(etatModeles_);
    explorateur_ = new QTreeWidget;
    explorateur_->setHeaderLabels({QStringLiteral("Contenu du modèle")});
    explorateur_->header()->setStretchLastSection(true);
    colonneDroite->addWidget(explorateur_, 1);
    dockModeles->setWidget(droite);
    addDockWidget(Qt::RightDockWidgetArea, dockModeles);

    statusBar()->showMessage(QStringLiteral("Prêt."));
    construireBibliotheque();
    definirModeles({});

    connect(bibliotheque_, &QTreeWidget::currentItemChanged, this,
            &FenetreSimulink::montrerBloc);
    connect(bibliotheque_, &QTreeWidget::itemDoubleClicked, this,
            [this](QTreeWidgetItem*, int) { insererBloc(); });
    connect(bInserer_, &QPushButton::clicked, this, &FenetreSimulink::insererBloc);
    connect(modeles_, &QListWidget::currentRowChanged, this,
            [this](int) { surModeleChoisi(); });
    connect(modeles_, &QListWidget::itemDoubleClicked, this,
            [this](QListWidgetItem*) { ouvrirSchema(); });
}

void FenetreSimulink::construireBarre() {
    auto* barre = addToolBar(QStringLiteral("Simulink"));
    barre->setObjectName(QStringLiteral("barreSimulink"));
    barre->setMovable(false);
    barre->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);

    QAction* aNouveau = barre->addAction(iconeDessinee(QStringLiteral("modele"), 20),
                                         QStringLiteral("Nouveau modèle"));
    connect(aNouveau, &QAction::triggered, this, &FenetreSimulink::nouveauModele);
    aEnregistrer_ = barre->addAction(iconeDessinee(QStringLiteral("enregistrer"), 20),
                                     QStringLiteral("Enregistrer"));
    aEnregistrer_->setToolTip(QStringLiteral(
        "Écrire un .m qui rebâtit le modèle : le format .slx n'est pas public"));
    connect(aEnregistrer_, &QAction::triggered, this,
            &FenetreSimulink::enregistrerModele);
    barre->addSeparator();

    aOuvrir_ = barre->addAction(iconeDessinee(QStringLiteral("simulink"), 20),
                                QStringLiteral("Redessiner"));
    aOuvrir_->setToolTip(QStringLiteral("Retracer le schéma du modèle choisi"));
    connect(aOuvrir_, &QAction::triggered, this, &FenetreSimulink::ouvrirSchema);
    barre->addSeparator();

    aSimuler_ = barre->addAction(iconeDessinee(QStringLiteral("executer"), 20),
                                 QStringLiteral("Simuler"));
    connect(aSimuler_, &QAction::triggered, this, &FenetreSimulink::simuler);
    barre->addWidget(new QLabel(QStringLiteral("  durée ")));
    duree_ = new QLineEdit(QStringLiteral("10"));
    duree_->setMaximumWidth(70);
    duree_->setToolTip(QStringLiteral("Instant final de la simulation, en secondes"));
    barre->addWidget(duree_);
    barre->addWidget(new QLabel(QStringLiteral(" s  ")));
    barre->addSeparator();

    QAction* aBibliotheque = barre->addAction(QStringLiteral("Bibliothèque"));
    aBibliotheque->setCheckable(true);
    aBibliotheque->setChecked(true);
    connect(aBibliotheque, &QAction::toggled, this,
            [this](bool montrer) { dockBibliotheque_->setVisible(montrer); });
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
    modeles_->blockSignals(true);
    modeles_->clear();
    for (const QString& nom : noms) modeles_->addItem(nom);
    if (!choisi.isEmpty())
        // Garder la sélection quand le modèle est toujours là : sans cela,
        // chaque commande tapée dans la console la ferait sauter.
        for (int k = 0; k < modeles_->count(); ++k)
            if (modeles_->item(k)->text() == choisi) modeles_->setCurrentRow(k);
    if (modeles_->currentRow() < 0 && modeles_->count() > 0) modeles_->setCurrentRow(0);
    modeles_->blockSignals(false);

    if (noms.isEmpty()) {
        etatModeles_->setText(QStringLiteral(
            "Aucun modèle dans l'espace de travail. « Nouveau modèle » en écrit "
            "un ; il paraîtra ici dès qu'il aura été exécuté."));
    } else {
        etatModeles_->setText(QStringLiteral(
            "%1 modèle(s). Les variables sont partagées : un paramètre écrit "
            "« K » vaut ce que vaut K dans l'espace de travail.").arg(noms.size()));
    }
    ajusterBoutons();
    // Le modèle affiché a pu changer sous nos pieds — une commande de la
    // console peut lui ajouter un bloc. On redemande son schéma, qui est
    // ainsi toujours celui de la valeur d'à présent.
    const QString courant = modeleChoisi();
    // Seulement si la fenêtre est ouverte : retracer un schéma après
    // chaque commande de la console coûterait un dessin à qui ne le
    // regarde pas.
    if (!courant.isEmpty() && isVisible()) emit schemaDemande(courant);
    if (courant.isEmpty()) {
        affiche_.clear();
        titreToile_->setText(QStringLiteral("Aucun schéma"));
        explorateur_->clear();
    }
}

void FenetreSimulink::definirSchema(const SchemaSimulink& schema) {
    if (schema.nom != modeleChoisi()) return;   // une réponse en retard
    explorateur_->clear();
    if (!schema.erreur.isEmpty()) {
        titreToile_->setText(QStringLiteral("%1 — %2").arg(schema.nom, schema.erreur));
        poserEtat(schema.erreur);
        return;
    }
    affiche_ = schema.nom;
    if (schema.figure.figure.hauteur > 0)
        aspect_ = double(schema.figure.figure.largeur) / schema.figure.figure.hauteur;
    toile_->definirFigure(schema.figure);
    ajusterToile();
    titreToile_->setText(QStringLiteral("%1 — %2 bloc(s), %3 lien(s)")
                             .arg(schema.nom)
                             .arg(schema.blocs.size())
                             .arg(schema.liens.size()));
    auto* rubriqueBlocs = new QTreeWidgetItem(explorateur_);
    rubriqueBlocs->setText(0, QStringLiteral("Blocs (%1)").arg(schema.blocs.size()));
    QFont grasse = rubriqueBlocs->font(0);
    grasse.setBold(true);
    rubriqueBlocs->setFont(0, grasse);
    for (const QString& b : schema.blocs)
        (new QTreeWidgetItem(rubriqueBlocs))->setText(0, b);
    rubriqueBlocs->setExpanded(true);
    auto* rubriqueLiens = new QTreeWidgetItem(explorateur_);
    rubriqueLiens->setText(0, QStringLiteral("Liens (%1)").arg(schema.liens.size()));
    rubriqueLiens->setFont(0, grasse);
    for (const QString& l : schema.liens)
        (new QTreeWidgetItem(rubriqueLiens))->setText(0, l);
    rubriqueLiens->setExpanded(true);
    poserEtat(QStringLiteral("Schéma de « %1 » à jour.").arg(schema.nom));
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
        "m = add_line(m, 'correcteur', 'sortie');\n");
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
    if (aOuvrir_) aOuvrir_->setEnabled(choisi);
    if (aSimuler_) aSimuler_->setEnabled(choisi);
    if (aEnregistrer_) aEnregistrer_->setEnabled(choisi);
}

void FenetreSimulink::surModeleChoisi() {
    ajusterBoutons();
    const QString nom = modeleChoisi();
    if (!nom.isEmpty()) emit schemaDemande(nom);
}

bool FenetreSimulink::eventFilter(QObject* objet, QEvent* evenement) {
    if (objet == zoneToile_ && evenement->type() == QEvent::Resize) ajusterToile();
    return QMainWindow::eventFilter(objet, evenement);
}

void FenetreSimulink::ajusterToile() {
    if (!toile_ || !zoneToile_) return;
    const int disponibleL = zoneToile_->width();
    const int disponibleH = zoneToile_->height();
    if (disponibleL < 40 || disponibleH < 40) return;
    if (!(aspect_ > 0)) {
        toile_->setGeometry(0, 0, disponibleL, disponibleH);
        return;
    }
    int largeur = disponibleL;
    int hauteur = int(largeur / aspect_);
    if (hauteur > disponibleH) {
        hauteur = disponibleH;
        largeur = int(hauteur * aspect_);
    }
    toile_->setGeometry((disponibleL - largeur) / 2, (disponibleH - hauteur) / 2,
                        largeur, hauteur);
}

void FenetreSimulink::poserEtat(const QString& texte) {
    statusBar()->showMessage(texte);
}

void FenetreSimulink::insererBloc() {
    const QString ligne = ligneInsertion();
    if (ligne.isEmpty()) return;
    emit insertionDemandee(ligne);
    poserEtat(QStringLiteral("Ligne écrite dans l'éditeur : %1").arg(ligne));
}

void FenetreSimulink::ouvrirSchema() {
    const QString nom = modeleChoisi();
    if (!nom.isEmpty()) emit schemaDemande(nom);
}

void FenetreSimulink::simuler() {
    const QString nom = modeleChoisi();
    if (nom.isEmpty()) return;
    bool nombre = false;
    const double fin = duree_->text().toDouble(&nombre);
    if (!nombre || !(fin > 0)) {
        poserEtat(QStringLiteral("La durée doit être un nombre de secondes positif."));
        return;
    }
    // Le résultat reste dans l'espace de travail sous « resultatSimulink » :
    // la simulation n'est pas un cul-de-sac, on la reprend au clavier.
    emit commandeDemandee(
        QStringLiteral("resultatSimulink = sim(%1, %2); figure; "
                       "simplot(resultatSimulink)")
            .arg(nom, duree_->text()));
    poserEtat(QStringLiteral("Simulation de « %1 » sur %2 s ; le relevé est dans "
                             "resultatSimulink.").arg(nom, duree_->text()));
}

void FenetreSimulink::enregistrerModele() {
    const QString nom = modeleChoisi();
    if (nom.isEmpty()) return;
    emit commandeDemandee(QStringLiteral("save_system(%1)").arg(nom));
    poserEtat(QStringLiteral("« %1 » écrit dans %1.m — un programme qui le rebâtit.")
                  .arg(nom));
}

void FenetreSimulink::nouveauModele() {
    emit nouveauModeleDemande(squeletteModele());
    poserEtat(QStringLiteral("Un modèle de départ vous attend dans l'éditeur ; "
                             "exécutez-le et il paraîtra ici."));
}
