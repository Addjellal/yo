// FenetrePrincipale.cpp — la disposition du bureau et ce qui l'anime.
#include "FenetrePrincipale.h"

#include <functional>

#include <QAction>
#include <QApplication>
#include <QCloseEvent>
#include <QDir>
#include <QDockWidget>
#include <QFileDialog>
#include <QFileInfo>
#include <QFontDatabase>
#include <QHeaderView>
#include <QKeyEvent>
#include <QLabel>
#include <QListWidget>
#include <QMenuBar>
#include <QMessageBox>
#include <QPlainTextEdit>
#include <QScrollBar>
#include <QSet>
#include <QSettings>
#include <QSplitter>
#include <QStatusBar>
#include <QTabWidget>
#include <QTableWidget>
#include <QThread>
#include <QToolBar>
#include <QToolButton>
#include <QVBoxLayout>
#include <algorithm>

#include "ConsoleCommandes.h"
#include "Editeur.h"
#include "FenetreFigure.h"
#include "FenetreAide.h"
#include "FenetreProfileur.h"
#include "Icone.h"
#include "Ruban.h"
#include "Theme.h"
#include "VueFigure.h"
#include "matlibre/Version.h"



FenetrePrincipale::FenetrePrincipale() {
    setWindowTitle(QStringLiteral("MatLibre %1").arg(QLatin1String(MATLIBRE_VERSION)));
    resize(1280, 820);

    // Le moteur vit dans son fil : la fenêtre reste vivante pendant un calcul.
    filMoteur_ = new QThread(this);
    moteur_ = new Moteur();
    moteur_->moveToThread(filMoteur_);
    connect(filMoteur_, &QThread::started, moteur_, &Moteur::demarrer);
    connect(filMoteur_, &QThread::finished, moteur_, &QObject::deleteLater);
    connect(moteur_, &Moteur::sortieProduite, this, &FenetrePrincipale::surSortie);
    connect(moteur_, &Moteur::espaceTravailChange, this,
            &FenetrePrincipale::surEspaceTravail);
    connect(moteur_, &Moteur::figuresChangees, this, &FenetrePrincipale::surFigures);
    connect(moteur_, &Moteur::dossierChange, this, &FenetrePrincipale::surDossier);
    connect(moteur_, &Moteur::commandeFinie, this, &FenetrePrincipale::surCommandeFinie);
    connect(moteur_, &Moteur::effacementDemande, this,
            &FenetrePrincipale::effacerCommandes);
    connect(moteur_, &Moteur::arreteSur, this, &FenetrePrincipale::surArret);
    connect(moteur_, &Moteur::repriseEffectuee, this, &FenetrePrincipale::surReprise);
    connect(moteur_, &Moteur::profilPret, this, &FenetrePrincipale::surProfil);
    connect(moteur_, &Moteur::documentationDemandee, this, &FenetrePrincipale::montrerAide);
    connect(moteur_, &Moteur::aidePrete, this, [this](const FicheAide& fiche) {
        if (fenetreAide_) fenetreAide_->poserFiche(fiche);
    });
    connect(moteur_, &Moteur::indexAidePret, this,
            [this](const QVector<EntreeIndexAide>& entrees) {
                if (fenetreAide_) fenetreAide_->poserIndex(entrees);
            });

    construirePanneaux();
    construireMenus();

    etiquetteDossier_ = new QLabel;
    statusBar()->addWidget(etiquetteDossier_, 1);
    etat_ = new QLabel(QStringLiteral("prêt"));
    statusBar()->addPermanentWidget(etat_);

    // La disposition des panneaux et la taille de la fenêtre se retrouvent
    // d'une session à l'autre : c'est ce qu'on attend d'un bureau.
    QSettings reglages;
    restoreGeometry(reglages.value(QStringLiteral("fenetre/geometrie")).toByteArray());
    restoreState(reglages.value(QStringLiteral("fenetre/etat")).toByteArray());

    filMoteur_->start();
    nouveauFichier();
    console_->poserInvite();
    console_->setFocus();
}

FenetrePrincipale::~FenetrePrincipale() {
    // Un fil arrete dans le crochet de debogage n'entendrait pas
    // « quit() » : on le libere d'abord, sinon Qt abandonne le programme
    // sur « QThread: Destroyed while thread is still running ».
    if (moteur_->arrete()) moteur_->libererPourFermeture();
    filMoteur_->quit();
    filMoteur_->wait(3000);
}

void FenetrePrincipale::construirePanneaux() {
    // --- centre : l'éditeur au-dessus, la fenêtre de commandes en dessous.
    // Les proportions sont celles de MATLAB : l'éditeur occupe les deux
    // tiers, la console le reste.
    onglets_ = new QTabWidget;
    onglets_->setTabsClosable(true);
    onglets_->setDocumentMode(true);
    onglets_->setMovable(true);
    connect(onglets_, &QTabWidget::tabCloseRequested, this, [this](int index) {
        QWidget* w = onglets_->widget(index);
        onglets_->removeTab(index);
        delete w;
        if (onglets_->count() == 0) nouveauFichier();
    });

    console_ = new ConsoleCommandes;
    // Ctrl-C dans la console coupe le calcul, comme sous MATLAB.
    connect(console_, &ConsoleCommandes::interruptionDemandee, this,
            &FenetrePrincipale::interrompre);
    connect(console_, &ConsoleCommandes::commandeValidee, this,
            [this](const QString& commande) {
                historique_->addItem(commande);
                historique_->scrollToBottom();
                if (enPause_) {
                    // Arrêté sur un point d'arrêt : la commande s'évalue
                    // dans l'espace de travail de l'arrêt, sans reprendre.
                    // C'est le « K>> » de MATLAB.
                    // Appel direct, et non en file : le fil de calcul
                    // dort dans le crochet d'arret, sa boucle d'evenements
                    // ne tourne plus — une connexion en file n'arriverait
                    // jamais. « evaluerALArret » ne touche que l'etat
                    // garde par le verrou du moteur.
                    moteur_->evaluerALArret(commande);
                    return;
                }
                poserOccupe(true);
                QMetaObject::invokeMethod(moteur_, "executer", Qt::QueuedConnection,
                                          Q_ARG(QString, commande));
            });

    // Les figures ne sont pas des onglets du bureau : chacune a sa fenêtre,
    // comme sous MATLAB. Le centre ne porte donc que l'éditeur.
    auto* centreHaut = new QTabWidget;
    centreHaut->setDocumentMode(true);
    centreHaut->addTab(onglets_, iconeDessinee("script", 16),
                       QStringLiteral("Éditeur"));

    // La console porte son titre, comme un panneau de MATLAB.
    auto* boiteConsole = new QWidget;
    auto* dispositionConsole = new QVBoxLayout(boiteConsole);
    dispositionConsole->setContentsMargins(0, 0, 0, 0);
    dispositionConsole->setSpacing(0);
    auto* titreConsole = new QLabel(QStringLiteral("  Fenêtre de commandes"));
    titreConsole->setStyleSheet(
        QStringLiteral("background:%1; padding:5px 4px; border-bottom:1px solid %2;")
            .arg(theme::titrePanneau().name(), theme::bordure().name()));
    dispositionConsole->addWidget(titreConsole);
    dispositionConsole->addWidget(console_, 1);

    auto* separateur = new QSplitter(Qt::Vertical);
    separateur->addWidget(centreHaut);
    separateur->addWidget(boiteConsole);
    separateur->setStretchFactor(0, 2);
    separateur->setStretchFactor(1, 1);
    separateur->setSizes({520, 260});
    setCentralWidget(separateur);

    // --- panneaux, disposés comme le bureau de MATLAB ---------------------
    listeFichiers_ = new QListWidget;
    listeFichiers_->setAlternatingRowColors(true);
    connect(listeFichiers_, &QListWidget::itemDoubleClicked, this,
            &FenetrePrincipale::ouvrirDepuisListe);
    auto* dockFichiers = new QDockWidget(QStringLiteral("Dossier courant"), this);
    dockFichiers->setWidget(listeFichiers_);
    dockFichiers->setObjectName(QStringLiteral("dockFichiers"));
    addDockWidget(Qt::LeftDockWidgetArea, dockFichiers);

    tableVariables_ = new QTableWidget(0, 4);
    tableVariables_->setHorizontalHeaderLabels(
        {QStringLiteral("Nom"), QStringLiteral("Valeur"), QStringLiteral("Taille"),
         QStringLiteral("Classe")});
    tableVariables_->horizontalHeader()->setStretchLastSection(true);
    tableVariables_->verticalHeader()->setVisible(false);
    tableVariables_->setEditTriggers(QAbstractItemView::NoEditTriggers);
    tableVariables_->setSelectionBehavior(QAbstractItemView::SelectRows);
    tableVariables_->setAlternatingRowColors(true);
    tableVariables_->setShowGrid(false);
    // Double-clic sur une variable : elle s'affiche dans la console, comme
    // le fait MATLAB quand on ouvre une variable.
    connect(tableVariables_, &QTableWidget::itemDoubleClicked, this,
            [this](QTableWidgetItem* item) {
                QTableWidgetItem* nom = tableVariables_->item(item->row(), 0);
                if (nom) envoyer(nom->text());
            });
    auto* dockVariables = new QDockWidget(QStringLiteral("Espace de travail"), this);
    dockVariables->setWidget(tableVariables_);
    dockVariables->setObjectName(QStringLiteral("dockVariables"));
    addDockWidget(Qt::RightDockWidgetArea, dockVariables);

    historique_ = new QListWidget;
    historique_->setAlternatingRowColors(true);
    connect(historique_, &QListWidget::itemDoubleClicked, this,
            [this](QListWidgetItem* item) { envoyer(item->text()); });
    listePointsArret_ = new QListWidget;
    listePointsArret_->setAlternatingRowColors(true);
    connect(listePointsArret_, &QListWidget::itemDoubleClicked, this,
            [this](QListWidgetItem* item) {
                // « fichier.m : 12 » — on ouvre le fichier a cette ligne.
                QStringList morceaux = item->text().split(QStringLiteral(" : "));
                if (morceaux.size() != 2) return;
                QString chemin = QDir(dossierCourant_).filePath(morceaux[0]);
                if (!QFileInfo::exists(chemin)) return;
                ouvrirFichier(chemin);
                if (Editeur* e = editeurCourant()) {
                    QTextCursor c(e->document()->findBlockByNumber(morceaux[1].toInt() - 1));
                    e->setTextCursor(c);
                    e->centerCursor();
                }
            });
    auto* dockPointsArret = new QDockWidget(QStringLiteral("Points d'arrêt"), this);
    dockPointsArret->setWidget(listePointsArret_);
    dockPointsArret->setObjectName(QStringLiteral("dockPointsArret"));
    addDockWidget(Qt::RightDockWidgetArea, dockPointsArret);

    auto* dockHistorique = new QDockWidget(QStringLiteral("Historique des commandes"), this);
    dockHistorique->setWidget(historique_);
    dockHistorique->setObjectName(QStringLiteral("dockHistorique"));
    addDockWidget(Qt::RightDockWidgetArea, dockHistorique);
    // L'espace de travail occupe le haut, l'historique le bas — MATLAB.
    // Les largeurs comptent autant que les hauteurs : sans elles, Qt donne
    // aux panneaux de droite la largeur de leur contenu minimal, et leur
    // titre lui-meme se retrouve reduit a « ... ».
    listeFichiers_->setMinimumWidth(180);
    tableVariables_->setMinimumWidth(260);
    historique_->setMinimumWidth(260);
    resizeDocks({dockVariables, dockHistorique}, {520, 260}, Qt::Vertical);
    resizeDocks({dockFichiers, dockVariables, dockHistorique}, {240, 330, 330},
                Qt::Horizontal);
    // Les colonnes de l'espace de travail : « Valeur » prend la place qui
    // reste, les trois autres celle qu'il leur faut.
    tableVariables_->horizontalHeader()->setSectionResizeMode(
        0, QHeaderView::ResizeToContents);
    tableVariables_->horizontalHeader()->setSectionResizeMode(1, QHeaderView::Stretch);
    tableVariables_->horizontalHeader()->setSectionResizeMode(
        2, QHeaderView::ResizeToContents);
    tableVariables_->horizontalHeader()->setSectionResizeMode(
        3, QHeaderView::ResizeToContents);
}

void FenetrePrincipale::construireMenus() {
    QMenu* fichier = menuBar()->addMenu(QStringLiteral("&Fichier"));
    QAction* aNouveau = fichier->addAction(iconeDessinee("nouveau", 16),
                                           QStringLiteral("&Nouveau script"), this,
                                           &FenetrePrincipale::nouveauFichier);
    aNouveau->setShortcut(QKeySequence::New);
    QAction* aOuvrir = fichier->addAction(iconeDessinee("ouvrir", 16),
                                          QStringLiteral("&Ouvrir…"), this,
                                          &FenetrePrincipale::ouvrirParDialogue);
    aOuvrir->setShortcut(QKeySequence::Open);
    QAction* aEnregistrer = fichier->addAction(iconeDessinee("enregistrer", 16),
                                               QStringLiteral("&Enregistrer"), this,
                                               &FenetrePrincipale::enregistrer);
    aEnregistrer->setShortcut(QKeySequence::Save);
    fichier->addAction(QStringLiteral("Enregistrer &sous…"), this,
                       &FenetrePrincipale::enregistrerSous);
    fichier->addSeparator();
    fichier->addAction(iconeDessinee("dossier", 16), QStringLiteral("Changer de &dossier…"),
                       this, &FenetrePrincipale::changerDossierParDialogue);
    fichier->addSeparator();
    QAction* aQuitter = fichier->addAction(QStringLiteral("&Quitter"), this, &QWidget::close);
    aQuitter->setShortcut(QKeySequence::Quit);

    QMenu* edition = menuBar()->addMenu(QStringLiteral("&Édition"));
    edition->addAction(QStringLiteral("&Annuler"), QKeySequence::Undo, this, [this] {
        if (Editeur* e = editeurCourant()) e->undo();
    });
    edition->addAction(QStringLiteral("&Rétablir"), QKeySequence::Redo, this, [this] {
        if (Editeur* e = editeurCourant()) e->redo();
    });
    edition->addSeparator();
    edition->addAction(QStringLiteral("&Copier"), QKeySequence::Copy, this, [this] {
        if (Editeur* e = editeurCourant()) e->copy();
    });
    edition->addAction(QStringLiteral("Co&ller"), QKeySequence::Paste, this, [this] {
        if (Editeur* e = editeurCourant()) e->paste();
    });
    edition->addSeparator();
    // Ctrl-R et Ctrl-T : les raccourcis de MATLAB pour commenter.
    edition->addAction(QStringLiteral("Co&mmenter"), QKeySequence(QStringLiteral("Ctrl+R")),
                       this, &FenetrePrincipale::commenterSelection);
    edition->addAction(QStringLiteral("Dé&commenter"), QKeySequence(QStringLiteral("Ctrl+T")),
                       this, &FenetrePrincipale::decommenterSelection);
    edition->addSeparator();
    edition->addAction(QStringLiteral("Effacer la fenêtre de commandes"),
                       QKeySequence(QStringLiteral("Ctrl+L")), this,
                       &FenetrePrincipale::effacerCommandes);

    QMenu* executer = menuBar()->addMenu(QStringLiteral("E&xécuter"));
    QAction* aExecuter = executer->addAction(iconeDessinee("executer", 16),
                                             QStringLiteral("Exécuter le script"), this,
                                             &FenetrePrincipale::executerScript);
    aExecuter->setShortcut(Qt::Key_F5);
    QAction* aSelection = executer->addAction(iconeDessinee("selection", 16),
                                              QStringLiteral("Exécuter la sélection"), this,
                                              &FenetrePrincipale::executerSelection);
    aSelection->setShortcut(Qt::Key_F9);
    executer->addSeparator();
    aArreter_ = executer->addAction(iconeDessinee("arret", 16),
                                    QStringLiteral("&Interrompre le calcul"), this,
                                    &FenetrePrincipale::interrompre);
    aArreter_->setEnabled(false);

    // « Exécuter et chronométrer » vit dans le menu Exécuter, comme
    // « Run and Time » vit dans l'onglet Éditeur de MATLAB.
    executer->addSeparator();
    QAction* aChronometrer =
        executer->addAction(iconeDessinee("chronometre", 16),
                            QStringLiteral("Exécuter et chronométrer"), this,
                            &FenetrePrincipale::executerEtChronometrer);
    aChronometrer->setShortcut(QKeySequence(QStringLiteral("Ctrl+F5")));

    QMenu* debogage = menuBar()->addMenu(QStringLiteral("&Déboguer"));
    aContinuer_ = debogage->addAction(iconeDessinee("continuer", 16),
                                      QStringLiteral("&Continuer"), this,
                                      &FenetrePrincipale::continuerExecution);
    aContinuer_->setShortcut(Qt::Key_F5 | Qt::ShiftModifier);
    aPasAPas_ = debogage->addAction(iconeDessinee("pasapas", 16),
                                    QStringLiteral("&Pas à pas"), this,
                                    &FenetrePrincipale::pasAPas);
    aPasAPas_->setShortcut(Qt::Key_F10);
    aEntrer_ = debogage->addAction(iconeDessinee("entrer", 16),
                                   QStringLiteral("&Entrer dedans"), this,
                                   &FenetrePrincipale::entrerDedans);
    aEntrer_->setShortcut(Qt::Key_F11);
    aSortir_ = debogage->addAction(iconeDessinee("sortir", 16),
                                   QStringLiteral("&Sortir de"), this,
                                   &FenetrePrincipale::sortirDe);
    aSortir_->setShortcut(Qt::Key_F11 | Qt::ShiftModifier);
    aQuitterDebug_ = debogage->addAction(iconeDessinee("arret", 16),
                                         QStringLiteral("&Arrêter le débogage"), this,
                                         &FenetrePrincipale::quitterDebogage);
    debogage->addSeparator();
    debogage->addAction(iconeDessinee("pointarret", 16),
                        QStringLiteral("Basculer un point d'arrêt"),
                        QKeySequence(Qt::Key_F12), this, [this] {
                            if (Editeur* e = editeurCourant())
                                e->basculerPointArret(e->textCursor().blockNumber() + 1);
                        });
    debogage->addAction(QStringLiteral("Retirer tous les points d'arrêt"), this,
                        &FenetrePrincipale::retirerTousPointsArret);
    debogage->addSeparator();
    debogage->addAction(iconeDessinee("chronometre", 16),
                        QStringLiteral("Ouvrir le profileur"), this,
                        &FenetrePrincipale::montrerProfileur);
    activerCommandesDebogueur(false);

    QMenu* aide = menuBar()->addMenu(QStringLiteral("&Aide"));
    QAction* aDocumentation =
        aide->addAction(iconeDessinee("aide", 16), QStringLiteral("&Documentation"), this,
                        [this] { montrerAide(QString()); });
    aDocumentation->setShortcut(QKeySequence(QStringLiteral("Ctrl+F1")));
    QAction* aAideMot = aide->addAction(QStringLiteral("Aide sur le &mot courant"), this,
                                        &FenetrePrincipale::aideSurMotCourant);
    aAideMot->setShortcut(Qt::Key_F1);
    aide->addSeparator();
    aide->addAction(QStringLiteral("À propos de MatLibre"), this,
                    &FenetrePrincipale::aPropos);

    QMenu* affichage = menuBar()->addMenu(QStringLiteral("&Affichage"));
    affichage->addAction(QStringLiteral("Afficher le &ruban"), this, [this](bool) {
        if (ruban_) ruban_->setVisible(!ruban_->isVisible());
    })->setCheckable(true);
    affichage->addAction(QStringLiteral("Rétablir la disposition par défaut"), this, [this] {
        for (QDockWidget* d : findChildren<QDockWidget*>()) d->show();
        QSettings().remove(QStringLiteral("fenetre/etat"));
    });

    // Le ruban : des onglets et des groupes nommes, comme MATLAB. Il tient
    // lieu de barre d'outils, et porte les memes actions que les menus.
    ruban_ = new Ruban;
    auto* barre = new QToolBar(QStringLiteral("Ruban"));
    barre->setObjectName(QStringLiteral("barreRuban"));
    barre->setMovable(false);
    barre->setFloatable(false);
    barre->addWidget(ruban_);
    barre->setStyleSheet(QStringLiteral("QToolBar { padding:0; spacing:0; }"));
    addToolBar(Qt::TopToolBarArea, barre);

    auto* fichierGroupe = new GroupeRuban(QStringLiteral("Fichier"));
    connect(fichierGroupe->ajouter(QStringLiteral("Nouveau\nscript"), QStringLiteral("nouveau"),
                          QStringLiteral("Nouveau script (Ctrl+N)")),
            &QToolButton::clicked, aNouveau, &QAction::trigger);
    connect(fichierGroupe->ajouter(QStringLiteral("Ouvrir"), QStringLiteral("ouvrir"),
                          QStringLiteral("Ouvrir un fichier (Ctrl+O)")),
            &QToolButton::clicked, aOuvrir, &QAction::trigger);
    connect(fichierGroupe->ajouter(QStringLiteral("Enregistrer"), QStringLiteral("enregistrer"),
                          QStringLiteral("Enregistrer (Ctrl+S)")),
            &QToolButton::clicked, aEnregistrer, &QAction::trigger);
    ruban_->ajouterGroupe(QStringLiteral("Accueil"), fichierGroupe);

    auto* variablesGroupe = new GroupeRuban(QStringLiteral("Variable"));
    QToolButton* bEspace = variablesGroupe->ajouter(
        QStringLiteral("Espace de\ntravail"), QStringLiteral("variables"),
        QStringLiteral("Afficher l'espace de travail"));
    connect(bEspace, &QToolButton::clicked, this, [this] { envoyer(QStringLiteral("whos")); });
    QToolButton* bVider = variablesGroupe->ajouter(
        QStringLiteral("Effacer les\nvariables"), QStringLiteral("effacer"),
        QStringLiteral("clear"));
    connect(bVider, &QToolButton::clicked, this, [this] { envoyer(QStringLiteral("clear")); });
    ruban_->ajouterGroupe(QStringLiteral("Accueil"), variablesGroupe);

    auto* codeGroupe = new GroupeRuban(QStringLiteral("Code"));
    connect(codeGroupe->ajouter(QStringLiteral("Exécuter"), QStringLiteral("executer"),
                          QStringLiteral("Exécuter le script (F5)")),
            &QToolButton::clicked, aExecuter, &QAction::trigger);
    connect(codeGroupe->ajouter(QStringLiteral("Exécuter la\nsélection"), QStringLiteral("selection"),
                          QStringLiteral("Exécuter la sélection (F9)")),
            &QToolButton::clicked, aSelection, &QAction::trigger);
    connect(codeGroupe->ajouter(QStringLiteral("Exécuter et\nchronométrer"),
                                QStringLiteral("chronometre"),
                                QStringLiteral("Mesurer le script ligne à ligne (Ctrl+F5)")),
            &QToolButton::clicked, this, &FenetrePrincipale::executerEtChronometrer);
    bArreter_ = codeGroupe->ajouter(QStringLiteral("Arrêter"), QStringLiteral("arret"),
                                    QStringLiteral("Interrompre le calcul (Ctrl+C)"));
    bArreter_->setEnabled(false);
    connect(bArreter_, &QToolButton::clicked, this, &FenetrePrincipale::interrompre);
    QToolButton* bEffacer = codeGroupe->ajouter(QStringLiteral("Effacer les\ncommandes"),
                                                QStringLiteral("effacer"),
                                                QStringLiteral("clc"));
    connect(bEffacer, &QToolButton::clicked, this, &FenetrePrincipale::effacerCommandes);
    ruban_->ajouterGroupe(QStringLiteral("Accueil"), codeGroupe);

    auto* environnementGroupe = new GroupeRuban(QStringLiteral("Environnement"));
    QToolButton* bDossier = environnementGroupe->ajouter(
        QStringLiteral("Dossier\ncourant"), QStringLiteral("dossier"),
        QStringLiteral("Changer de dossier courant"));
    connect(bDossier, &QToolButton::clicked, this,
            &FenetrePrincipale::changerDossierParDialogue);
    QToolButton* bProfileur = environnementGroupe->ajouter(
        QStringLiteral("Profileur"), QStringLiteral("chronometre"),
        QStringLiteral("Ouvrir le profileur : où passe le temps"));
    connect(bProfileur, &QToolButton::clicked, this, &FenetrePrincipale::montrerProfileur);
    ruban_->ajouterGroupe(QStringLiteral("Accueil"), environnementGroupe);

    auto* debogageGroupe = new GroupeRuban(QStringLiteral("Déboguer"));
    connect(debogageGroupe->ajouter(QStringLiteral("Continuer"), QStringLiteral("continuer"),
                                    QStringLiteral("Reprendre l'exécution (Maj+F5)")),
            &QToolButton::clicked, aContinuer_, &QAction::trigger);
    connect(debogageGroupe->ajouter(QStringLiteral("Pas à\npas"), QStringLiteral("pasapas"),
                                    QStringLiteral("Exécuter la ligne suivante (F10)")),
            &QToolButton::clicked, aPasAPas_, &QAction::trigger);
    connect(debogageGroupe->ajouter(QStringLiteral("Entrer\ndedans"), QStringLiteral("entrer"),
                                    QStringLiteral("Entrer dans l'appel (F11)")),
            &QToolButton::clicked, aEntrer_, &QAction::trigger);
    connect(debogageGroupe->ajouter(QStringLiteral("Sortir\nde"), QStringLiteral("sortir"),
                                    QStringLiteral("Sortir de la fonction (Maj+F11)")),
            &QToolButton::clicked, aSortir_, &QAction::trigger);
    connect(debogageGroupe->ajouter(QStringLiteral("Arrêter"), QStringLiteral("arret"),
                                    QStringLiteral("Arrêter le débogage")),
            &QToolButton::clicked, aQuitterDebug_, &QAction::trigger);
    ruban_->ajouterGroupe(QStringLiteral("Accueil"), debogageGroupe);

    auto* aideGroupe = new GroupeRuban(QStringLiteral("Ressources"));
    QToolButton* bAide = aideGroupe->ajouter(
        QStringLiteral("Aide"), QStringLiteral("aide"),
        QStringLiteral("Ouvrir la documentation (F1)"));
    connect(bAide, &QToolButton::clicked, this, [this] { montrerAide(QString()); });
    ruban_->ajouterGroupe(QStringLiteral("Accueil"), aideGroupe);

    // Onglet TRACÉS : les tracés courants, appliqués à la variable choisie
    // dans l'espace de travail — c'est ce que fait MATLAB.
    auto* tracesGroupe = new GroupeRuban(QStringLiteral("Tracés"));
    struct Trace { const char* libelle; const char* dessin; const char* fonction; };
    const Trace traces[] = {{"plot", "trace", "plot"},   {"bar", "barres", "bar"},
                            {"stem", "trace", "stem"},   {"stairs", "trace", "stairs"},
                            {"area", "trace", "area"},   {"histogram", "barres", "histogram"},
                            {"semilogy", "trace", "semilogy"}};
    for (const Trace& t : traces) {
        QToolButton* b = tracesGroupe->ajouter(QLatin1String(t.libelle),
                                               QLatin1String(t.dessin),
                                               QStringLiteral("Tracer la variable "
                                                              "sélectionnée"));
        QString fonction = QLatin1String(t.fonction);
        connect(b, &QToolButton::clicked, this, [this, fonction] { tracerSelection(fonction); });
    }
    ruban_->ajouterGroupe(QStringLiteral("Tracés"), tracesGroupe);
}

Editeur* FenetrePrincipale::editeurCourant() const {
    return qobject_cast<Editeur*>(onglets_->currentWidget());
}

void FenetrePrincipale::nouveauFichier() {
    auto* editeur = new Editeur;
    connect(editeur, &Editeur::pointArretBascule, this, &FenetrePrincipale::surPointArret);
    onglets_->addTab(editeur, QStringLiteral("sans-titre.m"));
    onglets_->setCurrentWidget(editeur);
    editeur->setFocus();
}

void FenetrePrincipale::ouvrirFichier(const QString& chemin) {
    for (int k = 0; k < onglets_->count(); ++k) {
        auto* e = qobject_cast<Editeur*>(onglets_->widget(k));
        if (e && e->fichier() == chemin) {
            onglets_->setCurrentIndex(k);
            return;
        }
    }
    auto* editeur = new Editeur;
    connect(editeur, &Editeur::pointArretBascule, this, &FenetrePrincipale::surPointArret);
    if (!editeur->chargerFichier(chemin)) {
        delete editeur;
        QMessageBox::warning(this, QStringLiteral("MatLibre"),
                             QStringLiteral("Impossible d'ouvrir « %1 ».").arg(chemin));
        return;
    }
    onglets_->addTab(editeur, QFileInfo(chemin).fileName());
    onglets_->setCurrentWidget(editeur);
    editeur->setFocus();
}

void FenetrePrincipale::ouvrirParDialogue() {
    QString chemin = QFileDialog::getOpenFileName(
        this, QStringLiteral("Ouvrir un script"), dossierCourant_,
        QStringLiteral("Scripts MATLAB (*.m);;Tous les fichiers (*)"));
    if (!chemin.isEmpty()) ouvrirFichier(chemin);
}

void FenetrePrincipale::ouvrirDepuisListe() {
    QListWidgetItem* item = listeFichiers_->currentItem();
    if (!item) return;
    QString chemin = QDir(dossierCourant_).filePath(item->text());
    if (QFileInfo(chemin).isDir()) {
        QMetaObject::invokeMethod(moteur_, "changerDossier", Qt::QueuedConnection,
                                  Q_ARG(QString, QDir(chemin).absolutePath()));
        return;
    }
    ouvrirFichier(chemin);
}

void FenetrePrincipale::enregistrer() {
    Editeur* editeur = editeurCourant();
    if (!editeur) return;
    if (editeur->fichier().isEmpty()) {
        enregistrerSous();
        return;
    }
    if (editeur->enregistrerFichier(editeur->fichier())) {
        etat_->setText(QStringLiteral("enregistré : %1").arg(editeur->fichier()));
        rafraichirListeFichiers();
        QMetaObject::invokeMethod(moteur_, "reindexer", Qt::QueuedConnection);
    }
}

void FenetrePrincipale::enregistrerSous() {
    Editeur* editeur = editeurCourant();
    if (!editeur) return;
    QString chemin = QFileDialog::getSaveFileName(
        this, QStringLiteral("Enregistrer le script"),
        QDir(dossierCourant_).filePath(QStringLiteral("sans-titre.m")),
        QStringLiteral("Scripts MATLAB (*.m)"));
    if (chemin.isEmpty()) return;
    if (editeur->enregistrerFichier(chemin)) {
        onglets_->setTabText(onglets_->currentIndex(), QFileInfo(chemin).fileName());
        etat_->setText(QStringLiteral("enregistré : %1").arg(chemin));
        rafraichirListeFichiers();
        QMetaObject::invokeMethod(moteur_, "reindexer", Qt::QueuedConnection);
    }
}

void FenetrePrincipale::executerScript() {
    Editeur* editeur = editeurCourant();
    if (!editeur) return;
    // Un script s'exécute depuis son fichier : c'est ce qui donne les bons
    // numéros de ligne dans les erreurs. On l'enregistre donc d'abord.
    if (editeur->fichier().isEmpty()) {
        enregistrerSous();
        if (editeur->fichier().isEmpty()) return;
    } else if (editeur->document()->isModified()) {
        editeur->enregistrerFichier(editeur->fichier());
    }
    // On passe par run('chemin') et non par le nom du fichier : un fichier
    // dont le nom n'est pas un identifiant MATLAB — « sans-titre.m », que
    // le bureau propose par defaut — donnerait sinon « Unrecognized
    // function or variable 'sans' ». run accepte n'importe quel chemin, et
    // n'exige pas que le dossier soit sur le chemin de recherche.
    QString chemin = QDir::toNativeSeparators(editeur->fichier());
    chemin.replace(QLatin1Char('\''), QStringLiteral("''"));
    envoyer(QStringLiteral("run('%1')").arg(chemin));
}

// « Exécuter et chronométrer » : le même script, mais mesuré. Le relevé
// ouvre la fenêtre du profileur, comme « Run and Time » sous MATLAB.
void FenetrePrincipale::executerEtChronometrer() {
    Editeur* editeur = editeurCourant();
    if (!editeur) return;
    if (editeur->fichier().isEmpty()) {
        enregistrerSous();
        if (editeur->fichier().isEmpty()) return;
    } else if (editeur->document()->isModified()) {
        editeur->enregistrerFichier(editeur->fichier());
    }
    if (occupe_) {
        if (!refusOccupeDit_) {
            refusOccupeDit_ = true;
            ecrire(QStringLiteral("MatLibre est occupé ; Ctrl+C interrompt le calcul.\n"),
                   theme::avertissement().name());
        }
        return;
    }
    QString chemin = QDir::toNativeSeparators(editeur->fichier());
    chemin.replace(QLatin1Char('\''), QStringLiteral("''"));
    QString commande = QStringLiteral("run('%1')").arg(chemin);
    console_->poserInvite();
    console_->ecrireSortie(commande + QStringLiteral("\n"), theme::texte());
    historique_->addItem(commande);
    historique_->scrollToBottom();
    poserOccupe(true);
    etat_->setText(QStringLiteral("mesure en cours"));
    QMetaObject::invokeMethod(moteur_, "executerEtChronometrer", Qt::QueuedConnection,
                              Q_ARG(QString, commande));
}

// La fenêtre du profileur, construite à la demande : tant qu'on ne mesure
// rien, elle n'existe pas.
// Le navigateur d'aide, construit a la demande. L'index des fonctions est
// demande une seule fois : le fil de calcul le fabrique pendant que la
// fenetre s'ouvre.
FenetreAide* FenetrePrincipale::fenetreAide() {
    if (!fenetreAide_) {
        fenetreAide_ = new FenetreAide(this);
        fenetreAide_->setWindowFlag(Qt::Window);
        connect(fenetreAide_, &FenetreAide::pageDemandee, this, [this](const QString& nom) {
            versMoteur([this, nom] { moteur_->demanderAide(nom); });
        });
        versMoteur([this] { moteur_->demanderIndexAide(); });
    }
    return fenetreAide_;
}

void FenetrePrincipale::montrerAide(const QString& nom) {
    FenetreAide* aide = fenetreAide();
    aide->show();
    aide->raise();
    aide->activateWindow();
    if (!nom.trimmed().isEmpty()) aide->afficher(nom);
}

// F1 dans l'editeur ouvre la documentation du mot sous le curseur, comme
// sous MATLAB.
void FenetrePrincipale::aideSurMotCourant() {
    Editeur* editeur = editeurCourant();
    QString mot;
    if (editeur) {
        QTextCursor curseur = editeur->textCursor();
        if (!curseur.hasSelection()) curseur.select(QTextCursor::WordUnderCursor);
        mot = curseur.selectedText().trimmed();
    }
    montrerAide(mot);
}

FenetreProfileur* FenetrePrincipale::profileur() {
    if (!profileur_) profileur_ = new FenetreProfileur(this);
    return profileur_;
}

void FenetrePrincipale::montrerProfileur() {
    profileur()->show();
    profileur()->raise();
}

void FenetrePrincipale::surProfil(const QVector<LigneProfil>& entrees, double duree) {
    profileur()->definirProfil(entrees, duree);
    profileur()->show();
    profileur()->raise();
}

void FenetrePrincipale::executerSelection() {
    Editeur* editeur = editeurCourant();
    if (!editeur) return;
    QString texte = editeur->textCursor().selectedText();
    if (texte.isEmpty()) texte = editeur->textCursor().block().text();
    texte.replace(QChar(0x2029), QLatin1Char('\n'));  // séparateur de paragraphe Qt
    if (!texte.trimmed().isEmpty()) envoyer(texte);
}

// Envoyer une commande depuis ailleurs que la console — un double-clic
// dans l'historique, F5 sur un script — passe par le même chemin : la
// commande s'écrit à l'invite, puis part.
void FenetrePrincipale::envoyer(const QString& commande) {
    // A l'arret, le bureau est « occupe » — le script tourne encore — mais
    // MATLAB accepte quand meme les commandes a l'invite « K>> ».
    if (occupe_ && !enPause_) {
        // Une fois suffit : repeter la phrase a chaque frappe n'apprend
        // rien et noie la console.
        if (!refusOccupeDit_) {
            refusOccupeDit_ = true;
            ecrire(QStringLiteral("MatLibre est occupé ; Ctrl+C interrompt le calcul.\n"),
                   theme::avertissement().name());
        }
        return;
    }
    console_->poserInvite();
    console_->insertPlainText(commande);
    QKeyEvent entree(QEvent::KeyPress, Qt::Key_Return, Qt::NoModifier);
    QCoreApplication::sendEvent(console_, &entree);
}

void FenetrePrincipale::ecrire(const QString& texte, const QString& couleur) {
    console_->ecrireSortie(texte, couleur.isEmpty() ? theme::texte() : QColor(couleur));
}

void FenetrePrincipale::surSortie(const QString& texte) {
    ++paquetsSortie_;
    const bool estErreur = texte.contains(QStringLiteral("Error:")) ||
                           texte.startsWith(QStringLiteral("Error"));
    console_->ecrireSortie(texte, estErreur ? theme::erreur() : theme::texte());
    // Le calcul attend cet accusé pour envoyer la suite : il ne prend
    // ainsi jamais plus d'avance que la console n'en peut peindre.
    moteur_->accuserSortie();
}

// Ctrl-C, ou le bouton « Arrêter ». Le moteur ne fait que lever un
// drapeau : le calcul s'arrête à son prochain point de contrôle — avant
// une instruction, ou pendant l'affichage d'un grand tableau.
void FenetrePrincipale::interrompre() {
    if (!occupe_) return;
    moteur_->demanderArret();
    etat_->setText(QStringLiteral("interruption demandée…"));
}

// Un seul endroit décide de l'état « occupé » : le bandeau, le bouton
// d'arrêt et le message le suivent.
void FenetrePrincipale::poserOccupe(bool occupe) {
    occupe_ = occupe;
    if (!occupe) refusOccupeDit_ = false;
    etat_->setText(occupe ? QStringLiteral("occupé") : QStringLiteral("prêt"));
    if (bArreter_) bArreter_->setEnabled(occupe);
    if (aArreter_) aArreter_->setEnabled(occupe);
}

void FenetrePrincipale::surCommandeFinie() {
    poserOccupe(false);
    console_->poserInvite();
}

void FenetrePrincipale::surEspaceTravail(const QVector<LigneEspaceTravail>& lignes) {
    if (enPause_) console_->poserInvite(QStringLiteral("K>> "));
    tableVariables_->setRowCount(lignes.size());
    for (int k = 0; k < lignes.size(); ++k) {
        tableVariables_->setItem(k, 0, new QTableWidgetItem(lignes[k].nom));
        tableVariables_->setItem(k, 1, new QTableWidgetItem(lignes[k].valeur));
        tableVariables_->setItem(k, 2, new QTableWidgetItem(lignes[k].taille));
        tableVariables_->setItem(k, 3, new QTableWidgetItem(lignes[k].classe));
    }
}

// Ce que MATLAB fait des fenêtres de figure, et rien de plus : une figure
// remonte au premier plan quand on trace dedans, pas quand on tape une
// commande sans rapport ; une figure fermée reste fermée ; « close all »
// ferme vraiment.
void FenetrePrincipale::surFigures(const QVector<FigureCopiee>& figures, int courante) {
    QSet<int> recues;
    for (const FigureCopiee& f : figures) recues.insert(f.numero);

    // Les fermetures faites à la main attendent que le moteur en prenne
    // acte : tant qu'il rapporte encore la figure, on l'ignore ; dès
    // qu'il ne la rapporte plus, on oublie — retracer dedans la rouvrira.
    for (auto it = fermeturesEnAttente_.begin(); it != fermeturesEnAttente_.end();)
        it = recues.contains(*it) ? ++it : fermeturesEnAttente_.erase(it);

    // Ce que le moteur ne rapporte plus n'existe plus : « close », « clf »
    // sur la dernière figure, « close all ».
    for (auto it = fenetresFigures_.begin(); it != fenetresFigures_.end();) {
        if (recues.contains(it.key())) {
            ++it;
            continue;
        }
        FenetreFigure* morte = it.value();
        it = fenetresFigures_.erase(it);
        empreintesFigures_.remove(morte->numero());
        morte->deleteLater();
    }

    for (const FigureCopiee& f : figures) {
        if (fermeturesEnAttente_.contains(f.numero)) continue;
        FenetreFigure* fenetre = fenetresFigures_.value(f.numero, nullptr);
        bool neuve = false;
        if (!fenetre) {
            neuve = true;
            fenetre = new FenetreFigure(f.numero, this);
            fenetre->setWindowFlag(Qt::Window);
            connect(fenetre, &FenetreFigure::fermee, this,
                    &FenetrePrincipale::surFermetureFigure);
            fenetresFigures_.insert(f.numero, fenetre);
            // Les figures se décalent l'une de l'autre pour ne pas se
            // recouvrir exactement, comme le fait MATLAB.
            int rang = fenetresFigures_.size() - 1;
            fenetre->move(x() + 90 + rang * 26, y() + 90 + rang * 26);
        }
        // Le moteur n'envoie la copie que lorsque le tracé a bougé.
        bool aChange = neuve || empreintesFigures_.value(f.numero, 0) != f.empreinte;
        if (f.contenu) fenetre->definirFigure(f);
        empreintesFigures_.insert(f.numero, f.empreinte);
        if (!aChange) continue;
        if (!fenetre->isVisible()) fenetre->show();
        fenetre->raise();
    }

    // « figure(2) » ramène la figure 2 devant, sans rien y tracer.
    if (courante != 0 && courante != figureCouranteVue_) {
        if (FenetreFigure* fenetre = fenetresFigures_.value(courante, nullptr)) {
            if (!fenetre->isVisible()) fenetre->show();
            fenetre->raise();
        }
    }
    figureCouranteVue_ = courante;
}

// Fermer la fenêtre ferme la figure : sans cela le moteur la garderait, et
// la commande suivante la ferait revenir sous le nez de l'utilisateur.
void FenetrePrincipale::surFermetureFigure(int numero) {
    fermeturesEnAttente_.insert(numero);
    if (FenetreFigure* fenetre = fenetresFigures_.take(numero)) fenetre->deleteLater();
    empreintesFigures_.remove(numero);
    versMoteur([this, numero] { moteur_->fermerFigure(numero); });
}

void FenetrePrincipale::surDossier(const QString& chemin) {
    dossierCourant_ = chemin;
    // Le titre porte le nom du produit, pas un chemin de trois lignes : le
    // dossier courant a sa place dans la barre d'etat, comme sous MATLAB.
    setWindowTitle(QStringLiteral("MatLibre %1").arg(QLatin1String(MATLIBRE_VERSION)));
    etiquetteDossier_->setText(QStringLiteral("  ") + QDir::toNativeSeparators(chemin));
    rafraichirListeFichiers();
}

void FenetrePrincipale::rafraichirListeFichiers() {
    listeFichiers_->clear();
    QDir dossier(dossierCourant_);
    listeFichiers_->addItem(QStringLiteral(".."));
    for (const QFileInfo& e : dossier.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot,
                                                    QDir::Name))
        listeFichiers_->addItem(e.fileName());
    for (const QFileInfo& e :
         dossier.entryInfoList({QStringLiteral("*.m")}, QDir::Files, QDir::Name))
        listeFichiers_->addItem(e.fileName());
}

void FenetrePrincipale::changerDossierParDialogue() {
    QString chemin = QFileDialog::getExistingDirectory(
        this, QStringLiteral("Choisir le dossier courant"), dossierCourant_);
    if (chemin.isEmpty()) return;
    QMetaObject::invokeMethod(moteur_, "changerDossier", Qt::QueuedConnection,
                              Q_ARG(QString, chemin));
}

void FenetrePrincipale::effacerCommandes() { console_->effacer(); }

// Trace la variable choisie dans l'espace de travail, comme l'onglet
// TRACÉS de MATLAB. Sans sélection, on le dit plutôt que de ne rien faire.
void FenetrePrincipale::tracerSelection(const QString& fonction) {
    int ligne = tableVariables_->currentRow();
    if (ligne < 0 || !tableVariables_->item(ligne, 0)) {
        ecrire(QStringLiteral("Choisissez d'abord une variable dans l'espace de "
                              "travail.\n"),
               theme::avertissement().name());
        return;
    }
    envoyer(fonction + QLatin1Char('(') + tableVariables_->item(ligne, 0)->text() +
            QLatin1Char(')'));
}

// --- débogueur ------------------------------------------------------------

Editeur* FenetrePrincipale::editeurDuFichier(const QString& fichier) {
    // Le débogueur nomme les fichiers par leur nom court ; on retrouve
    // l'onglet qui le porte, ou on l'ouvre.
    QFileInfo cible(fichier);
    for (int k = 0; k < onglets_->count(); ++k) {
        auto* e = qobject_cast<Editeur*>(onglets_->widget(k));
        if (!e || e->fichier().isEmpty()) continue;
        QFileInfo info(e->fichier());
        if (info.completeBaseName() == cible.completeBaseName() ||
            info.absoluteFilePath() == cible.absoluteFilePath())
            return e;
    }
    if (cible.isFile()) {
        ouvrirFichier(cible.absoluteFilePath());
        return qobject_cast<Editeur*>(onglets_->currentWidget());
    }
    // Le fichier n'est pas ouvert : on le cherche dans le dossier courant.
    QString essai = QDir(dossierCourant_).filePath(cible.completeBaseName() + ".m");
    if (QFileInfo::exists(essai)) {
        ouvrirFichier(essai);
        return qobject_cast<Editeur*>(onglets_->currentWidget());
    }
    return nullptr;
}

// Un appel au moteur qui marche dans les deux etats du fil de calcul :
// en file quand il tourne — la modification arrive alors entre deux
// commandes, sans course —, en direct quand il dort dans le crochet
// d'arret, ou plus rien ne depile la file mais ou rien non plus ne lit
// l'interpreteur.
void FenetrePrincipale::versMoteur(std::function<void()> action) {
    if (moteur_->arrete()) {
        action();
        return;
    }
    QMetaObject::invokeMethod(moteur_, std::move(action), Qt::QueuedConnection);
}

void FenetrePrincipale::surArret(const QString& fichier, int ligne) {
    enPause_ = true;
    activerCommandesDebogueur(true);
    etat_->setText(QStringLiteral("arrêté ligne %1").arg(ligne));
    if (Editeur* e = editeurDuFichier(fichier)) {
        onglets_->setCurrentWidget(e);
        e->definirLigneArret(ligne);
    }
    // L'invite passe à « K>> », comme MATLAB : on peut regarder et
    // modifier les variables sans reprendre l'exécution.
    console_->poserInvite(QStringLiteral("K>> "));
    console_->setFocus();
}

void FenetrePrincipale::surReprise() {
    enPause_ = false;
    activerCommandesDebogueur(false);
    poserOccupe(occupe_);
    for (int k = 0; k < onglets_->count(); ++k)
        if (auto* e = qobject_cast<Editeur*>(onglets_->widget(k))) e->definirLigneArret(0);
}

void FenetrePrincipale::surPointArret(int ligne, bool pose) {
    auto* editeur = qobject_cast<Editeur*>(sender());
    if (!editeur) return;
    if (editeur->fichier().isEmpty()) {
        ecrire(QStringLiteral("Enregistrez le fichier avant d'y poser un point "
                              "d'arrêt.\n"),
               theme::avertissement().name());
        editeur->basculerPointArret(ligne);   // annule la pastille
        return;
    }
    QString fichier = editeur->fichier();
    versMoteur([this, pose, fichier, ligne] {
        if (pose) moteur_->poserPointArret(fichier, ligne);
        else moteur_->retirerPointArret(fichier, ligne);
    });
    rafraichirPointsArret();
}

void FenetrePrincipale::rafraichirPointsArret() {
    if (!listePointsArret_) return;
    listePointsArret_->clear();
    for (int k = 0; k < onglets_->count(); ++k) {
        auto* e = qobject_cast<Editeur*>(onglets_->widget(k));
        if (!e || e->fichier().isEmpty()) continue;
        QString nom = QFileInfo(e->fichier()).fileName();
        QList<int> lignes = e->pointsArret().values();
        std::sort(lignes.begin(), lignes.end());
        for (int ligne : lignes)
            listePointsArret_->addItem(QStringLiteral("%1 : %2").arg(nom).arg(ligne));
    }
}

void FenetrePrincipale::activerCommandesDebogueur(bool actif) {
    for (QAction* a : {aContinuer_, aPasAPas_, aEntrer_, aSortir_, aQuitterDebug_})
        if (a) a->setEnabled(actif);
}

// Les cinq commandes. ActionDebogueur : 0 continuer, 1 pas a pas,
// 2 entrer, 3 sortir, 4 quitter. Toutes appellent le moteur DIRECTEMENT :
// le fil de calcul dort dans le crochet, il n'y a plus de boucle
// d'evenements pour delivrer une connexion en file.
void FenetrePrincipale::continuerExecution() { moteur_->reprendre(0); }
void FenetrePrincipale::pasAPas()            { moteur_->reprendre(1); }
void FenetrePrincipale::entrerDedans()       { moteur_->reprendre(2); }
void FenetrePrincipale::sortirDe()           { moteur_->reprendre(3); }
void FenetrePrincipale::quitterDebogage()    { moteur_->reprendre(4); }

void FenetrePrincipale::retirerTousPointsArret() {
    versMoteur([this] { moteur_->retirerTousPointsArret(); });
    for (int k = 0; k < onglets_->count(); ++k) {
        auto* e = qobject_cast<Editeur*>(onglets_->widget(k));
        if (!e) continue;
        for (int ligne : e->pointsArret().values()) e->basculerPointArret(ligne);
    }
    rafraichirPointsArret();
}

void FenetrePrincipale::commenterSelection() {
    if (Editeur* e = editeurCourant()) e->commenter();
}

void FenetrePrincipale::decommenterSelection() {
    if (Editeur* e = editeurCourant()) e->decommenter();
}

void FenetrePrincipale::aPropos() {
    QMessageBox::about(
        this, QStringLiteral("À propos de MatLibre"),
        QStringLiteral("<b>MatLibre %1</b><br><br>"
                       "Clone libre du langage MATLAB, écrit en C++17.<br>"
                       "Aucun code MathWorks n'est repris.<br><br>"
                       "L'interpréteur tourne dans ce processus : l'espace de "
                       "travail que montre le panneau de droite est celui de la "
                       "fenêtre de commandes.")
            .arg(QLatin1String(MATLIBRE_VERSION)));
}

void FenetrePrincipale::closeEvent(QCloseEvent* evenement) {
    QSettings reglages;
    reglages.setValue(QStringLiteral("fenetre/geometrie"), saveGeometry());
    reglages.setValue(QStringLiteral("fenetre/etat"), saveState());
    for (int k = 0; k < onglets_->count(); ++k) {
        auto* e = qobject_cast<Editeur*>(onglets_->widget(k));
        if (!e || !e->document()->isModified()) continue;
        auto reponse = QMessageBox::question(
            this, QStringLiteral("MatLibre"),
            QStringLiteral("« %1 » a été modifié. Enregistrer avant de quitter ?")
                .arg(onglets_->tabText(k)),
            QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel);
        if (reponse == QMessageBox::Cancel) { evenement->ignore(); return; }
        if (reponse == QMessageBox::Save) {
            onglets_->setCurrentIndex(k);
            enregistrer();
        }
    }
    evenement->accept();
}
