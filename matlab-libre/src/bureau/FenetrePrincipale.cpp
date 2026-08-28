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
#include <QVBoxLayout>

#include "ConsoleCommandes.h"
#include "Editeur.h"
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

    ongletsFigures_ = new QTabWidget;
    ongletsFigures_->setTabsClosable(true);
    ongletsFigures_->setDocumentMode(true);
    connect(ongletsFigures_, &QTabWidget::tabCloseRequested, this, [this](int index) {
        QWidget* w = ongletsFigures_->widget(index);
        ongletsFigures_->removeTab(index);
        delete w;
    });

    auto* centreHaut = new QTabWidget;
    centreHaut->setDocumentMode(true);
    centreHaut->addTab(onglets_, QStringLiteral("Éditeur"));
    centreHaut->addTab(ongletsFigures_, QStringLiteral("Figures"));

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
    QAction* aNouveau = fichier->addAction(QStringLiteral("&Nouveau script"), this,
                                           &FenetrePrincipale::nouveauFichier);
    aNouveau->setShortcut(QKeySequence::New);
    QAction* aOuvrir = fichier->addAction(QStringLiteral("&Ouvrir…"), this,
                                          &FenetrePrincipale::ouvrirParDialogue);
    aOuvrir->setShortcut(QKeySequence::Open);
    QAction* aEnregistrer = fichier->addAction(QStringLiteral("&Enregistrer"), this,
                                               &FenetrePrincipale::enregistrer);
    aEnregistrer->setShortcut(QKeySequence::Save);
    fichier->addAction(QStringLiteral("Enregistrer &sous…"), this,
                       &FenetrePrincipale::enregistrerSous);
    fichier->addSeparator();
    fichier->addAction(QStringLiteral("Changer de &dossier…"), this,
                       &FenetrePrincipale::changerDossierParDialogue);
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
    QAction* aExecuter = executer->addAction(QStringLiteral("Exécuter le script"), this,
                                             &FenetrePrincipale::executerScript);
    aExecuter->setShortcut(Qt::Key_F5);
    QAction* aSelection = executer->addAction(QStringLiteral("Exécuter la sélection"), this,
                                              &FenetrePrincipale::executerSelection);
    aSelection->setShortcut(Qt::Key_F9);

    QMenu* aide = menuBar()->addMenu(QStringLiteral("&Aide"));
    aide->addAction(QStringLiteral("À propos de MatLibre"), this,
                    &FenetrePrincipale::aPropos);

    QMenu* affichage = menuBar()->addMenu(QStringLiteral("&Affichage"));
    affichage->addAction(QStringLiteral("Rétablir la disposition par défaut"), this, [this] {
        for (QDockWidget* d : findChildren<QDockWidget*>()) d->show();
        QSettings().remove(QStringLiteral("fenetre/etat"));
    });

    QToolBar* barre = addToolBar(QStringLiteral("Principale"));
    barre->setObjectName(QStringLiteral("barrePrincipale"));
    barre->setMovable(false);
    barre->setToolButtonStyle(Qt::ToolButtonTextOnly);
    barre->addAction(aNouveau);
    barre->addAction(aOuvrir);
    barre->addAction(aEnregistrer);
    barre->addSeparator();
    barre->addAction(aExecuter);
    barre->addAction(aSelection);
    barre->addSeparator();
    barre->addAction(QStringLiteral("Effacer les variables"), this, [this] {
        envoyer(QStringLiteral("clear"));
    });
    barre->addAction(QStringLiteral("Effacer la console"), this,
                     &FenetrePrincipale::effacerCommandes);
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
    QString nom = QFileInfo(editeur->fichier()).completeBaseName();
    envoyer(nom);
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
        VueFigure* vue = nullptr;
        for (int k = 0; k < ongletsFigures_->count(); ++k) {
            auto* candidat = qobject_cast<VueFigure*>(ongletsFigures_->widget(k));
            if (candidat && candidat->numero() == f.numero) { vue = candidat; break; }
        }
        if (!vue) {
            vue = new VueFigure;
            ongletsFigures_->addTab(vue, QStringLiteral("Figure %1").arg(f.numero));
        }
        vue->definirFigure(f);
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
