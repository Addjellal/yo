// FenetreSimulink.cpp — l'éditeur Simulink du bureau.
#include "FenetreSimulink.h"

#include <QAction>
#include <QGuiApplication>
#include <QDockWidget>
#include <QFileDialog>
#include <QFrame>
#include <QEvent>
#include <QResizeEvent>
#include <QHBoxLayout>
#include <QAbstractItemView>
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
#include "DialogueBloc.h"
#include "ToileSimulink.h"

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

    // Un sous-système pose un modèle entier dans un bloc. Celui qu'on
    // pose par défaut est le plus court qui serve à quelque chose : une
    // entrée reliée à une sortie, qu'on garnit en l'ouvrant.
    {"Sous-systèmes", "subsystem",
     "Un schéma entier abrégé en un bloc ; un double-clic l'ouvre",
     "'Model', add_line(add_block(add_block(new_system('sousSysteme'), "
     "'inport', 'e', 'Port', 1), 'outport', 's', 'Port', 1), 'e', 's')"},

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
    auto* dansCadre = new QVBoxLayout(cadre);
    dansCadre->setContentsMargins(1, 1, 1, 1);
    toile_ = new ToileSimulink;
    dansCadre->addWidget(toile_);
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
    // On traîne un bloc de la bibliothèque jusqu'à la feuille, comme dans
    // Simulink ; à défaut, « Insérer » écrit sa ligne dans l'éditeur.
    bibliotheque_->setDragEnabled(true);
    bibliotheque_->setDragDropMode(QAbstractItemView::DragOnly);
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

    // Les gestes de la toile deviennent des commandes sur le modele : c'est
    // ce qui fait qu'une modification a la souris se relit au clavier, et
    // que l'espace de travail reste le seul etat.
    connect(toile_, &ToileSimulink::blocsDeplaces, this,
            &FenetreSimulink::surBlocsDeplaces);
    connect(toile_, &ToileSimulink::lienDemande, this,
            &FenetreSimulink::surLienDemande);
    connect(toile_, &ToileSimulink::blocsSupprimes, this,
            &FenetreSimulink::surBlocsSupprimes);
    connect(toile_, &ToileSimulink::annulationDemandee, this,
            &FenetreSimulink::surAnnulation);
    connect(toile_, &ToileSimulink::retablissementDemande, this,
            &FenetreSimulink::surRetablissement);
    connect(toile_, &ToileSimulink::lienSupprime, this,
            &FenetreSimulink::surLienSupprime);
    connect(toile_, &ToileSimulink::blocOuvert, this, &FenetreSimulink::surBlocOuvert);
    connect(toile_, &ToileSimulink::blocDepose, this, &FenetreSimulink::surBlocDepose);
    connect(toile_, &ToileSimulink::etatChange, this, &FenetreSimulink::poserEtat);
}

// Un nombre tel qu'un programme le relira : assez de chiffres pour que la
// place retrouvee soit la place posee.
static QString ecrireNombre(double v) {
    return QString::number(v, 'g', 12);
}

// Toute modification passe par ici : une seule ligne, precedee de la mise
// en reserve de l'etat courant. La console refuse ce qu'on lui envoie
// pendant qu'elle calcule, si bien que deux lignes d'affilee en
// perdraient une ; et sans la mise en reserve, Ctrl+Z n'aurait rien a
// defaire.
void FenetreSimulink::envoyerModification(const QString& corps,
                                          const QString& annonce) {
    const QString modele = modeleChoisi();
    if (modele.isEmpty() || corps.isEmpty()) return;
    if (chemin_.isEmpty()) {
        emit commandeDemandee(
            QStringLiteral("matlibre_sl_pile('poser', %1); %2").arg(modele, corps));
    } else {
        // Dans un sous-systeme, le geste ne porte pas sur le modele mais
        // sur celui qu'il abrite : on le sort, on le modifie, on le
        // repose. Le tout tient en une ligne -- il le faut, la console
        // refusant la seconde -- et Ctrl+Z le defait d'un coup, puisque
        // c'est le modele entier qui est mis en reserve avant.
        emit commandeDemandee(
            QStringLiteral("matlibre_sl_pile('poser', %1); "
                           "matlibre_sl_travail = matlibre_sl_dedans(%1, '%2'); %3 "
                           "%1 = matlibre_sl_remplacer(%1, '%2', matlibre_sl_travail); "
                           "clear matlibre_sl_travail;")
                .arg(modele, chemin_, corps));
    }
    poserEtat(annonce);
}

// La variable sur laquelle les gestes ecrivent. En surface, c'est le
// modele lui-meme ; dans un sous-systeme, la variable de passage
// qu'ENVOYERMODIFICATION sort et repose autour du geste.
QString FenetreSimulink::cibleModele() const {
    if (chemin_.isEmpty()) return modeleChoisi();
    if (modeleChoisi().isEmpty()) return QString();
    return QStringLiteral("matlibre_sl_travail");
}

// Le modele et le chemin reunis : « asservi » en surface,
// « asservi/correcteur » une fois descendu. C'est ce que le moteur
// attend, et ce que le schema rendu porte en retour.
QString FenetreSimulink::ancreAffichee() const {
    const QString modele = modeleChoisi();
    if (modele.isEmpty() || chemin_.isEmpty()) return modele;
    return modele + QLatin1Char('/') + chemin_;
}

void FenetreSimulink::remonter() {
    if (chemin_.isEmpty()) return;
    const int barre = chemin_.lastIndexOf(QLatin1Char('/'));
    chemin_ = barre < 0 ? QString() : chemin_.left(barre);
    majChemin();
    const QString ancre = ancreAffichee();
    if (!ancre.isEmpty()) emit schemaDemande(ancre);
}

void FenetreSimulink::surRemontee() { remonter(); }

// Le bouton qui remonte n'a de sens qu'une fois descendu.
void FenetreSimulink::majChemin() {
    if (aRemonter_) aRemonter_->setEnabled(!chemin_.isEmpty());
}

void FenetreSimulink::surBlocsDeplaces(const QStringList& noms,
                                       const QVector<QRectF>& places) {
    const QString modele = cibleModele();
    if (modele.isEmpty()) return;
    QStringList morceaux;
    for (int k = 0; k < noms.size() && k < places.size(); ++k)
        morceaux << QStringLiteral("%1 = set_param(%1, '%2', 'Position', "
                                   "[%3 %4 %5 %6]);")
                        .arg(modele, noms[k], ecrireNombre(places[k].left()),
                             ecrireNombre(places[k].top()),
                             ecrireNombre(places[k].right()),
                             ecrireNombre(places[k].bottom()));
    envoyerModification(morceaux.join(QLatin1Char(' ')),
                        noms.size() == 1
                            ? QStringLiteral("« %1 » deplace ; sa place est "
                                             "enregistree dans le modele.")
                                  .arg(noms.first())
                            : QStringLiteral("%1 blocs deplaces.").arg(noms.size()));
}

void FenetreSimulink::surLienDemande(const QString& source, const QString& cible,
                                     int port) {
    const QString modele = cibleModele();
    if (modele.isEmpty()) return;
    envoyerModification(QStringLiteral("%1 = add_line(%1, '%2', '%3', %4);")
                            .arg(modele, source, cible)
                            .arg(port),
                        QStringLiteral("« %1 » alimente l'entree %2 de « %3 ».")
                            .arg(source)
                            .arg(port)
                            .arg(cible));
}

void FenetreSimulink::surBlocsSupprimes(const QStringList& noms) {
    const QString modele = cibleModele();
    if (modele.isEmpty() || noms.isEmpty()) return;
    QStringList morceaux;
    for (const QString& nom : noms)
        morceaux << QStringLiteral("%1 = delete_block(%1, '%2');").arg(modele, nom);
    envoyerModification(morceaux.join(QLatin1Char(' ')),
                        noms.size() == 1
                            ? QStringLiteral("« %1 » retire, avec les liens qui y "
                                             "touchaient.").arg(noms.first())
                            : QStringLiteral("%1 blocs retires, avec leurs liens.")
                                  .arg(noms.size()));
}

void FenetreSimulink::surAnnulation() {
    const QString modele = modeleChoisi();
    if (modele.isEmpty()) return;
    emit commandeDemandee(
        QStringLiteral("%1 = matlibre_sl_pile('annuler', %1);").arg(modele));
    poserEtat(QStringLiteral("Annulé."));
}

void FenetreSimulink::surRetablissement() {
    const QString modele = modeleChoisi();
    if (modele.isEmpty()) return;
    emit commandeDemandee(
        QStringLiteral("%1 = matlibre_sl_pile('refaire', %1);").arg(modele));
    poserEtat(QStringLiteral("Rétabli."));
}

void FenetreSimulink::surLienSupprime(const QString& source, const QString& cible,
                                      int port) {
    const QString modele = cibleModele();
    if (modele.isEmpty()) return;
    envoyerModification(QStringLiteral("%1 = delete_line(%1, '%2', '%3', %4);")
                            .arg(modele, source, cible)
                            .arg(port),
                        QStringLiteral("Le lien de « %1 » vers « %2 » est retire.")
                            .arg(source, cible));
}

void FenetreSimulink::surBlocOuvert(const QString& nom) {
    const QString modele = cibleModele();
    if (modele.isEmpty()) return;
    const BlocSchema* bloc = nullptr;
    for (const BlocSchema& b : dernier_.blocs)
        if (b.nom == nom) bloc = &b;
    if (!bloc) return;
    // Un sous-systeme ne se regle pas : il s'ouvre. C'est ce que fait
    // Simulink, et c'est la seule facon de voir le schema qu'il abrege.
    if (bloc->type == QLatin1String("subsystem")) {
        chemin_ = chemin_.isEmpty() ? nom : chemin_ + QLatin1Char('/') + nom;
        majChemin();
        emit schemaDemande(ancreAffichee());
        poserEtat(QStringLiteral("Ouvert « %1 ». « Remonter » ramene au schema "
                                 "du dessus.").arg(ancreAffichee()));
        return;
    }
    DialogueBloc boite(bloc->nom, bloc->type, bloc->reglagesNoms,
                       bloc->reglagesValeurs, this);
    if (boite.exec() != QDialog::Accepted) return;

    // Une seule commande, quoi qu'on ait change : la console refuse ce
    // qu'on lui envoie pendant qu'elle calcule, si bien que deux commandes
    // d'affilee auraient perdu la seconde -- changer un reglage et
    // renommer aurait perdu le renommage. Le renommage vient en dernier
    // dans la ligne : ce qui precede designe encore le bloc par son
    // ancien nom.
    QStringList morceaux;
    for (const auto& couple : boite.changements())
        morceaux << QStringLiteral("%1 = set_param(%1, '%2', '%3', '%4');")
                        .arg(modele, nom, couple.first, couple.second);
    const QString neuf = boite.nomDemande();
    if (!neuf.isEmpty() && neuf != nom)
        morceaux << QStringLiteral("%1 = set_param(%1, '%2', 'Name', '%3');")
                        .arg(modele, nom, neuf);
    if (morceaux.isEmpty()) {
        poserEtat(QStringLiteral("Rien n'a change pour « %1 ».").arg(nom));
        return;
    }
    envoyerModification(morceaux.join(QLatin1Char(' ')),
                        QStringLiteral("Reglages de « %1 » enregistres dans le "
                                       "modele.")
                            .arg(neuf.isEmpty() ? nom : neuf));
}

void FenetreSimulink::surBlocDepose(const QPointF& place) {
    const QString modele = cibleModele();
    if (modele.isEmpty()) {
        poserEtat(QStringLiteral("Choisissez d'abord un modele, a droite."));
        return;
    }
    QTreeWidgetItem* item = bibliotheque_->currentItem();
    const QString type = item ? item->data(0, Qt::UserRole).toString() : QString();
    if (type.isEmpty()) {
        poserEtat(QStringLiteral("Choisissez un bloc dans la bibliotheque avant de "
                                 "le poser."));
        return;
    }
    const QString parametres = item->data(1, Qt::UserRole).toString();
    const QString nom = QStringLiteral("%1%2").arg(type).arg(++poses_);
    // Un bloc pose garde la place ou on l'a lache : c'est POSITION qui la
    // retient, et le schema ne se replace donc plus tout seul.
    const double demiL = type == QLatin1String("sum") ? 0.5 : 0.85;
    QString ligne = QStringLiteral("%1 = add_block(%1, '%2', '%3'").arg(modele, type, nom);
    if (!parametres.isEmpty()) ligne += QStringLiteral(", ") + parametres;
    ligne += QStringLiteral(", 'Position', [%1 %2 %3 %4]);")
                 .arg(ecrireNombre(place.x() - demiL), ecrireNombre(place.y() - 0.5),
                      ecrireNombre(place.x() + demiL), ecrireNombre(place.y() + 0.5));
    envoyerModification(ligne, QStringLiteral("« %1 » pose sur la feuille.").arg(nom));
}

void FenetreSimulink::ajusterVue() {
    toile_->ajusterVue();
    toile_->update();
}

void FenetreSimulink::construireBarre() {
    auto* barre = addToolBar(QStringLiteral("Simulink"));
    barre->setObjectName(QStringLiteral("barreSimulink"));
    barre->setMovable(false);
    barre->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);

    QAction* aNouveau = barre->addAction(iconeDessinee(QStringLiteral("modele"), 20),
                                         QStringLiteral("Nouveau modèle"));
    connect(aNouveau, &QAction::triggered, this, &FenetreSimulink::nouveauModele);
    QAction* aOuvrirFichier = barre->addAction(
        iconeDessinee(QStringLiteral("ouvrir"), 20), QStringLiteral("Ouvrir"));
    aOuvrirFichier->setToolTip(QStringLiteral(
        "Relire un modèle écrit en .m, et le poser dans l'espace de travail"));
    connect(aOuvrirFichier, &QAction::triggered, this, &FenetreSimulink::ouvrirModele);
    aEnregistrer_ = barre->addAction(iconeDessinee(QStringLiteral("enregistrer"), 20),
                                     QStringLiteral("Enregistrer"));
    aEnregistrer_->setToolTip(QStringLiteral(
        "Écrire un .m qui rebâtit le modèle : le format .slx n'est pas public"));
    connect(aEnregistrer_, &QAction::triggered, this,
            &FenetreSimulink::enregistrerModele);
    aProgramme_ = barre->addAction(iconeDessinee(QStringLiteral("script"), 20),
                                   QStringLiteral("Générer le .m"));
    aProgramme_->setToolTip(QStringLiteral(
        "Écrire le programme qui fait ce que le schéma fait, sans Simulink"));
    connect(aProgramme_, &QAction::triggered, this, &FenetreSimulink::genererProgramme);
    barre->addSeparator();

    aRemonter_ = barre->addAction(iconeDessinee(QStringLiteral("dossier-parent"), 20),
                                  QStringLiteral("Remonter"));
    aRemonter_->setToolTip(QStringLiteral(
        "Revenir au schéma qui contient le sous-système ouvert"));
    aRemonter_->setEnabled(false);
    connect(aRemonter_, &QAction::triggered, this, &FenetreSimulink::surRemontee);
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

    QAction* aAjuster = barre->addAction(QStringLiteral("Ajuster"));
    aAjuster->setToolTip(QStringLiteral("Ramener tout le schéma dans la vue"));
    connect(aAjuster, &QAction::triggered, this, &FenetreSimulink::ajusterVue);
    QAction* aPlus = barre->addAction(QStringLiteral("+"));
    aPlus->setToolTip(QStringLiteral("Agrandir"));
    connect(aPlus, &QAction::triggered, this, [this] { toile_->zoomer(1.25); });
    QAction* aMoins = barre->addAction(QStringLiteral("−"));
    aMoins->setToolTip(QStringLiteral("Réduire"));
    connect(aMoins, &QAction::triggered, this, [this] { toile_->zoomer(1 / 1.25); });
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
    // Si le modele affiche a change sous nos pieds -- efface de l'espace
    // de travail, par exemple --, le chemin ouvert designait ses blocs :
    // il n'a plus de sens dans celui qui prend sa place.
    if (courant != choisi && !chemin_.isEmpty()) {
        chemin_.clear();
        majChemin();
    }
    // Seulement si la fenêtre est ouverte : retracer un schéma après
    // chaque commande de la console coûterait un dessin à qui ne le
    // regarde pas.
    if (!courant.isEmpty() && isVisible()) emit schemaDemande(ancreAffichee());
    if (courant.isEmpty()) {
        affiche_.clear();
        titreToile_->setText(QStringLiteral("Aucun schéma"));
        explorateur_->clear();
    }
}

void FenetreSimulink::definirSchema(const SchemaSimulink& schema) {
    if (schema.nom != ancreAffichee()) return;   // une réponse en retard
    explorateur_->clear();
    if (!schema.erreur.isEmpty()) {
        titreToile_->setText(QStringLiteral("%1 — %2").arg(schema.nom, schema.erreur));
        toile_->vider();
        poserEtat(schema.erreur);
        return;
    }
    affiche_ = schema.nom;
    dernier_ = schema;
    toile_->definirSchema(schema);
    titreToile_->setText(QStringLiteral("%1 — %2 bloc(s), %3 lien(s)")
                             .arg(schema.nom)
                             .arg(schema.blocs.size())
                             .arg(schema.liens.size()));
    auto* rubriqueBlocs = new QTreeWidgetItem(explorateur_);
    rubriqueBlocs->setText(0, QStringLiteral("Blocs (%1)").arg(schema.blocs.size()));
    QFont grasse = rubriqueBlocs->font(0);
    grasse.setBold(true);
    rubriqueBlocs->setFont(0, grasse);
    for (const BlocSchema& b : schema.blocs)
        (new QTreeWidgetItem(rubriqueBlocs))
            ->setText(0, QStringLiteral("%1 — %2").arg(b.nom, b.type));
    rubriqueBlocs->setExpanded(true);
    auto* rubriqueLiens = new QTreeWidgetItem(explorateur_);
    rubriqueLiens->setText(0, QStringLiteral("Liens (%1)").arg(schema.liens.size()));
    rubriqueLiens->setFont(0, grasse);
    for (const LienSchema& l : schema.liens) {
        const QString source = (l.source >= 1 && l.source <= schema.blocs.size())
                                   ? schema.blocs[l.source - 1].nom
                                   : QStringLiteral("?");
        const QString cible = (l.cible >= 1 && l.cible <= schema.blocs.size())
                                  ? schema.blocs[l.cible - 1].nom
                                  : QStringLiteral("?");
        (new QTreeWidgetItem(rubriqueLiens))
            ->setText(0, QStringLiteral("%1 → %2 (entrée %3)")
                             .arg(source, cible)
                             .arg(l.port));
    }
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
    if (aProgramme_) aProgramme_->setEnabled(choisi);
}

void FenetreSimulink::surModeleChoisi() {
    // Changer de modele ferme les sous-systemes ouverts : le chemin
    // designait des blocs de l'ancien, et n'a plus de sens dans le neuf.
    chemin_.clear();
    majChemin();
    ajusterBoutons();
    const QString nom = modeleChoisi();
    if (!nom.isEmpty()) emit schemaDemande(nom);
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
    const QString ancre = ancreAffichee();
    if (!ancre.isEmpty()) emit schemaDemande(ancre);
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

// Un chemin peut porter une apostrophe — « /home/…/l'essai/pid.m » —, et
// dans une chaîne MATLAB elle se double. Sans cela la chaîne se
// refermerait au milieu du chemin, et la fin passerait pour du code.
static QString chaineMatlab(const QString& texte) {
    QString echappe = texte;
    echappe.replace(QLatin1Char('\''), QLatin1String("''"));
    return QStringLiteral("'%1'").arg(echappe);
}

void FenetreSimulink::enregistrerModele() {
    const QString nom = modeleChoisi();
    if (nom.isEmpty()) return;
    const QString chemin = QFileDialog::getSaveFileName(
        this, QStringLiteral("Enregistrer le modèle"), nom + QStringLiteral(".m"),
        QStringLiteral("Programmes MatLibre (*.m)"));
    if (!chemin.isEmpty()) enregistrerVers(chemin);
}

// Le .m qui rebatit le modele : NEW_SYSTEM, ADD_BLOCK, ADD_LINE. C'est
// l'aller du schema ; LOAD_SYSTEM en est le retour.
void FenetreSimulink::enregistrerVers(const QString& chemin) {
    const QString nom = modeleChoisi();
    if (nom.isEmpty() || chemin.isEmpty()) return;
    emit commandeDemandee(
        QStringLiteral("save_system(%1, %2);").arg(nom, chaineMatlab(chemin)));
    poserEtat(QStringLiteral("« %1 » écrit dans %2 — un programme qui le rebâtit.")
                  .arg(nom, chemin));
}

void FenetreSimulink::genererProgramme() {
    const QString nom = modeleChoisi();
    if (nom.isEmpty()) return;
    const QString chemin = QFileDialog::getSaveFileName(
        this, QStringLiteral("Générer le programme de simulation"),
        nom + QStringLiteral("_simule.m"), QStringLiteral("Programmes MatLibre (*.m)"));
    if (!chemin.isEmpty()) genererVers(chemin);
}

// Le .m qui *fait ce que le schema fait* : des variables, une boucle, de
// l'arithmetique. Les reglages y sont inscrits tels qu'ils valent ; le
// programme ne depend donc de rien, et rend les memes nombres que SIM.
void FenetreSimulink::genererVers(const QString& chemin) {
    const QString nom = modeleChoisi();
    if (nom.isEmpty() || chemin.isEmpty()) return;
    emit commandeDemandee(
        QStringLiteral("matlibre_sl_ecrire(%1, %2);").arg(nom, chaineMatlab(chemin)));
    poserEtat(QStringLiteral("Le programme qui simule « %1 » est écrit dans %2.")
                  .arg(nom, chemin));
}

void FenetreSimulink::ouvrirModele() {
    const QString chemin = QFileDialog::getOpenFileName(
        this, QStringLiteral("Ouvrir un modèle"), QString(),
        QStringLiteral("Programmes MatLibre (*.m)"));
    if (!chemin.isEmpty()) ouvrirDepuis(chemin);
}

// Le modele relu ne reste pas dans la fenetre : il est pose dans l'espace
// de travail, sous son propre nom, ou la console et l'explorateur de
// variables le voient comme les autres.
void FenetreSimulink::ouvrirDepuis(const QString& chemin) {
    if (chemin.isEmpty()) return;
    emit commandeDemandee(
        QStringLiteral("matlibre_sl_charger(%1);").arg(chaineMatlab(chemin)));
    poserEtat(QStringLiteral("Modèle relu depuis %1 ; il paraît à droite dès qu'il "
                             "est dans l'espace de travail.").arg(chemin));
}

void FenetreSimulink::nouveauModele() {
    emit nouveauModeleDemande(squeletteModele());
    poserEtat(QStringLiteral("Un modèle de départ vous attend dans l'éditeur ; "
                             "exécutez-le et il paraîtra ici."));
}
