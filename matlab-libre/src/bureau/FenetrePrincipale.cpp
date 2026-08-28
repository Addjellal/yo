// FenetrePrincipale.cpp — la disposition du bureau et ce qui l'anime.
#include "FenetrePrincipale.h"

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
#include <QSettings>
#include <QSplitter>
#include <QStatusBar>
#include <QTabWidget>
#include <QTableWidget>
#include <QThread>
#include <QToolBar>
#include <QToolButton>
#include <QVBoxLayout>

#include "ConsoleCommandes.h"
#include "Editeur.h"
#include "FenetreFigure.h"
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
    connect(console_, &ConsoleCommandes::commandeValidee, this,
            [this](const QString& commande) {
                historique_->addItem(commande);
                historique_->scrollToBottom();
                occupe_ = true;
                etat_->setText(QStringLiteral("occupé"));
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

    QMenu* aide = menuBar()->addMenu(QStringLiteral("&Aide"));
    aide->addAction(iconeDessinee("aide", 16), QStringLiteral("À propos de MatLibre"), this,
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
    QToolButton* bAtelier = environnementGroupe->ajouter(
        QStringLiteral("Atelier\nweb"), QStringLiteral("bureau"),
        QStringLiteral("Ouvre l'atelier dans le navigateur : profileur, "
                       "concepteur d'applications, schémas-blocs"));
    connect(bAtelier, &QToolButton::clicked, this, [this] { envoyer(QStringLiteral("ide")); });
    ruban_->ajouterGroupe(QStringLiteral("Accueil"), environnementGroupe);

    auto* aideGroupe = new GroupeRuban(QStringLiteral("Ressources"));
    QToolButton* bAide = aideGroupe->ajouter(QStringLiteral("Aide"), QStringLiteral("aide"),
                                             QStringLiteral("help"));
    connect(bAide, &QToolButton::clicked, this, [this] { envoyer(QStringLiteral("help")); });
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
    if (occupe_) {
        ecrire(QStringLiteral("MatLibre est occupé ; attendez la fin du calcul.\n"),
               theme::avertissement().name());
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
    const bool estErreur = texte.contains(QStringLiteral("Error:")) ||
                           texte.startsWith(QStringLiteral("Error"));
    console_->ecrireSortie(texte, estErreur ? theme::erreur() : theme::texte());
}

void FenetrePrincipale::surCommandeFinie() {
    occupe_ = false;
    etat_->setText(QStringLiteral("prêt"));
    console_->poserInvite();
}

void FenetrePrincipale::surEspaceTravail(const QVector<LigneEspaceTravail>& lignes) {
    tableVariables_->setRowCount(lignes.size());
    for (int k = 0; k < lignes.size(); ++k) {
        tableVariables_->setItem(k, 0, new QTableWidgetItem(lignes[k].nom));
        tableVariables_->setItem(k, 1, new QTableWidgetItem(lignes[k].valeur));
        tableVariables_->setItem(k, 2, new QTableWidgetItem(lignes[k].taille));
        tableVariables_->setItem(k, 3, new QTableWidgetItem(lignes[k].classe));
    }
}

void FenetrePrincipale::surFigures(const QVector<FigureCopiee>& figures) {
    for (const FigureCopiee& f : figures) {
        FenetreFigure* fenetre = fenetresFigures_.value(f.numero, nullptr);
        if (!fenetre) {
            fenetre = new FenetreFigure(f.numero, this);
            fenetre->setWindowFlag(Qt::Window);
            // La fenêtre ne se détruit pas à la fermeture : elle se cache.
            // Retracer dans la même figure la rouvre, comme sous MATLAB.
            connect(fenetre, &FenetreFigure::fermee, this,
                    [this](int numero) { (void)numero; });
            fenetresFigures_.insert(f.numero, fenetre);
            // Les figures se décalent l'une de l'autre pour ne pas se
            // recouvrir exactement, comme le fait MATLAB.
            int rang = fenetresFigures_.size() - 1;
            fenetre->move(x() + 90 + rang * 26, y() + 90 + rang * 26);
        }
        fenetre->definirFigure(f);
        if (!fenetre->isVisible()) fenetre->show();
        fenetre->raise();
    }
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
