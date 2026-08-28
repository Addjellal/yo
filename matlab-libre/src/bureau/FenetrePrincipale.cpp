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
#include <QLineEdit>
#include <QListWidget>
#include <QMenuBar>
#include <QMessageBox>
#include <QPlainTextEdit>
#include <QScrollBar>
#include <QSplitter>
#include <QStatusBar>
#include <QTabWidget>
#include <QTableWidget>
#include <QThread>
#include <QToolBar>
#include <QVBoxLayout>

#include "Editeur.h"
#include "VueFigure.h"
#include "matlibre/Version.h"

namespace {

// La ligne de commande : flèches haut et bas rappellent l'historique,
// comme à l'invite de MATLAB.
class LigneCommande : public QLineEdit {
public:
    LigneCommande(QVector<QString>* historique, int* index, QWidget* parent)
        : QLineEdit(parent), historique_(historique), index_(index) {}

protected:
    void keyPressEvent(QKeyEvent* evenement) override {
        if (evenement->key() == Qt::Key_Up || evenement->key() == Qt::Key_Down) {
            if (historique_->isEmpty()) return;
            if (evenement->key() == Qt::Key_Up) {
                if (*index_ < 0) *index_ = historique_->size() - 1;
                else if (*index_ > 0) --(*index_);
            } else {
                if (*index_ >= 0 && *index_ < historique_->size() - 1) ++(*index_);
                else { *index_ = -1; clear(); return; }
            }
            setText(historique_->at(*index_));
            return;
        }
        *index_ = -1;
        QLineEdit::keyPressEvent(evenement);
    }

private:
    QVector<QString>* historique_;
    int* index_;
};

}  // namespace

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

    etat_ = new QLabel(QStringLiteral("prêt"));
    statusBar()->addPermanentWidget(etat_);

    filMoteur_->start();
    nouveauFichier();
    saisie_->setFocus();
}

FenetrePrincipale::~FenetrePrincipale() {
    filMoteur_->quit();
    filMoteur_->wait(3000);
}

void FenetrePrincipale::construirePanneaux() {
    // --- centre : éditeur au-dessus, fenêtre de commandes en dessous ---
    onglets_ = new QTabWidget;
    onglets_->setTabsClosable(true);
    onglets_->setDocumentMode(true);
    connect(onglets_, &QTabWidget::tabCloseRequested, this, [this](int index) {
        QWidget* w = onglets_->widget(index);
        onglets_->removeTab(index);
        delete w;
        if (onglets_->count() == 0) nouveauFichier();
    });

    console_ = new QPlainTextEdit;
    console_->setReadOnly(true);
    QFont fixe = QFontDatabase::systemFont(QFontDatabase::FixedFont);
    fixe.setPointSize(11);
    console_->setFont(fixe);
    console_->setStyleSheet(QStringLiteral("background:#ffffff;"));

    saisie_ = new LigneCommande(&commandesPassees_, &indexHistorique_, nullptr);
    saisie_->setFont(fixe);
    saisie_->setFrame(false);
    connect(saisie_, &QLineEdit::returnPressed, this, &FenetrePrincipale::validerCommande);

    auto* barreSaisie = new QWidget;
    auto* dispositionSaisie = new QHBoxLayout(barreSaisie);
    dispositionSaisie->setContentsMargins(6, 2, 6, 4);
    auto* invite = new QLabel(QStringLiteral(">>"));
    invite->setFont(fixe);
    dispositionSaisie->addWidget(invite);
    dispositionSaisie->addWidget(saisie_, 1);

    auto* boiteCommandes = new QWidget;
    auto* dispositionCommandes = new QVBoxLayout(boiteCommandes);
    dispositionCommandes->setContentsMargins(0, 0, 0, 0);
    dispositionCommandes->setSpacing(0);
    dispositionCommandes->addWidget(console_, 1);
    dispositionCommandes->addWidget(barreSaisie);

    ongletsFigures_ = new QTabWidget;
    ongletsFigures_->setTabsClosable(true);
    connect(ongletsFigures_, &QTabWidget::tabCloseRequested, this, [this](int index) {
        QWidget* w = ongletsFigures_->widget(index);
        ongletsFigures_->removeTab(index);
        delete w;
    });

    auto* centreHaut = new QTabWidget;
    centreHaut->addTab(onglets_, QStringLiteral("Éditeur"));
    centreHaut->addTab(ongletsFigures_, QStringLiteral("Figures"));

    auto* separateur = new QSplitter(Qt::Vertical);
    separateur->addWidget(centreHaut);
    separateur->addWidget(boiteCommandes);
    separateur->setStretchFactor(0, 3);
    separateur->setStretchFactor(1, 2);
    setCentralWidget(separateur);

    // --- panneaux latéraux ---
    listeFichiers_ = new QListWidget;
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
    auto* dockVariables = new QDockWidget(QStringLiteral("Espace de travail"), this);
    dockVariables->setWidget(tableVariables_);
    dockVariables->setObjectName(QStringLiteral("dockVariables"));
    addDockWidget(Qt::RightDockWidgetArea, dockVariables);

    historique_ = new QListWidget;
    connect(historique_, &QListWidget::itemDoubleClicked, this,
            [this](QListWidgetItem* item) { envoyer(item->text()); });
    auto* dockHistorique = new QDockWidget(QStringLiteral("Historique des commandes"), this);
    dockHistorique->setWidget(historique_);
    dockHistorique->setObjectName(QStringLiteral("dockHistorique"));
    addDockWidget(Qt::RightDockWidgetArea, dockHistorique);
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
    edition->addAction(QStringLiteral("Effacer la fenêtre de commandes"), this,
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

    QToolBar* barre = addToolBar(QStringLiteral("Principale"));
    barre->setObjectName(QStringLiteral("barrePrincipale"));
    barre->setMovable(false);
    barre->addAction(aNouveau);
    barre->addAction(aOuvrir);
    barre->addAction(aEnregistrer);
    barre->addSeparator();
    barre->addAction(aExecuter);
    barre->addAction(aSelection);
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

void FenetrePrincipale::validerCommande() {
    QString commande = saisie_->text();
    if (commande.trimmed().isEmpty()) return;
    saisie_->clear();
    envoyer(commande);
}

void FenetrePrincipale::envoyer(const QString& commande) {
    if (occupe_) {
        ecrire(QStringLiteral("MatLibre est occupé ; attendez la fin du calcul.\n"),
               QStringLiteral("#b06000"));
        return;
    }
    ecrire(QStringLiteral(">> ") + commande + QLatin1Char('\n'), QStringLiteral("#000080"));
    commandesPassees_.push_back(commande);
    indexHistorique_ = -1;
    historique_->addItem(commande);
    historique_->scrollToBottom();
    occupe_ = true;
    etat_->setText(QStringLiteral("occupé"));
    QMetaObject::invokeMethod(moteur_, "executer", Qt::QueuedConnection,
                              Q_ARG(QString, commande));
}

void FenetrePrincipale::ecrire(const QString& texte, const QString& couleur) {
    QTextCharFormat format;
    format.setForeground(couleur.isEmpty() ? QColor("#101010") : QColor(couleur));
    QTextCursor curseur = console_->textCursor();
    curseur.movePosition(QTextCursor::End);
    curseur.insertText(texte, format);
    console_->setTextCursor(curseur);
    console_->verticalScrollBar()->setValue(console_->verticalScrollBar()->maximum());
}

void FenetrePrincipale::surSortie(const QString& texte) {
    ecrire(texte, texte.startsWith(QStringLiteral("Error")) ? QStringLiteral("#c00000")
                                                            : QString());
}

void FenetrePrincipale::surCommandeFinie() {
    occupe_ = false;
    etat_->setText(QStringLiteral("prêt"));
}

void FenetrePrincipale::surEspaceTravail(const QVector<LigneEspaceTravail>& lignes) {
    tableVariables_->setRowCount(lignes.size());
    for (int k = 0; k < lignes.size(); ++k) {
        tableVariables_->setItem(k, 0, new QTableWidgetItem(lignes[k].nom));
        tableVariables_->setItem(k, 1, new QTableWidgetItem(lignes[k].valeur));
        tableVariables_->setItem(k, 2, new QTableWidgetItem(lignes[k].taille));
        tableVariables_->setItem(k, 3, new QTableWidgetItem(lignes[k].classe));
    }
    tableVariables_->resizeColumnsToContents();
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
    setWindowTitle(QStringLiteral("MatLibre %1 — %2")
                       .arg(QLatin1String(MATLIBRE_VERSION), chemin));
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

void FenetrePrincipale::effacerCommandes() { console_->clear(); }

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
