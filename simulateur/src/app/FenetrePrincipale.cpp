#include "app/FenetrePrincipale.h"

#include <QAction>
#include <QActionGroup>
#include <QApplication>
#include <QComboBox>
#include <QDockWidget>
#include <QDoubleSpinBox>
#include <QDrag>
#include <QFile>
#include <QFileDialog>
#include <QFormLayout>
#include <QHBoxLayout>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLabel>
#include <QLineEdit>
#include <QMenu>
#include <QMenuBar>
#include <QMessageBox>
#include <QMimeData>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QSlider>
#include <QSpinBox>
#include <QStandardPaths>
#include <QStatusBar>
#include <QTabWidget>
#include <QTimer>
#include <QToolBar>
#include <QVBoxLayout>

#include <map>

#include <QImage>
#include <QPageSize>
#include <QPdfWriter>

#include "app/MoteurSimulation.h"
#include "app/Oscilloscope.h"
#include "app/panels/FenetreInstrument.h"
#include "app/panels/PanneauAnalyses.h"
#include "core/analysis/Analyses.h"
#include "core/export/Documents.h"
#include "app/schematic/ItemComposant.h"
#include "app/schematic/ItemFil.h"
#include "app/schematic/SceneSchema.h"
#include "app/schematic/VueSchema.h"
#include "core/Device.h"

namespace {

const char* kSourceExemple = R"(/* Clignotant : la LED sur D13 s'allume une demi-seconde sur deux. */
#include <avr/io.h>
#include <util/delay.h>

int main(void) {
    DDRB |= (1 << PB5);              /* D13 en sortie */
    while (1) {
        PORTB |= (1 << PB5);         /* allumée */
        _delay_ms(500);
        PORTB &= ~(1 << PB5);        /* éteinte */
        _delay_ms(500);
    }
}
)";

}  // namespace

// ---------------------------------------------------------------------------
PaletteComposants::PaletteComposants(QWidget* parent) : QTreeWidget(parent) {
    setHeaderHidden(true);
    setDragEnabled(true);
    setDragDropMode(QAbstractItemView::DragOnly);
    setSelectionMode(QAbstractItemView::SingleSelection);
}

QMimeData* PaletteComposants::mimeData(
    const QList<QTreeWidgetItem*>& items) const {
    if (items.isEmpty()) return nullptr;
    const QString type = items.first()->data(0, Qt::UserRole).toString();
    if (type.isEmpty()) return nullptr;
    auto* donnees = new QMimeData;
    donnees->setData("application/x-composant", type.toUtf8());
    return donnees;
}

// ---------------------------------------------------------------------------
FenetrePrincipale::FenetrePrincipale() {
    setWindowTitle("Simulateur embarqué — schéma et exécution du firmware");
    resize(1500, 940);

    scene_ = new SceneSchema(this);
    vue_ = new VueSchema(this);
    vue_->setScene(scene_);
    setCentralWidget(vue_);

    moteur_ = new MoteurSimulation(this);

    construire_palette();
    construire_docks();
    construire_actions();
    construire_barre_etat();

    connect(scene_, &SceneSchema::selection_composant, this,
            &FenetrePrincipale::afficher_proprietes);
    connect(scene_, &SceneSchema::journal, this, &FenetrePrincipale::ecrire);
    connect(scene_, &SceneSchema::double_clic_composant, this,
            &FenetrePrincipale::ouvrir_fenetre_instrument);
    connect(scene_, &SceneSchema::menu_demande, this,
            [this](ItemComposant* composant, const QPoint& ecran) {
                menu_contextuel(composant, ecran);
            });
    connect(scene_, &SceneSchema::changed, this,
            [this](const QList<QRectF>&) { circuit_modifie(); });
    connect(vue_, &VueSchema::composant_depose, this,
            [this](const QString& type, const QPointF& position) {
                scene_->ajouter_composant(type, position);
                circuit_modifie();
            });

    connect(moteur_, &MoteurSimulation::journal, this,
            &FenetrePrincipale::ecrire);
    connect(moteur_, &MoteurSimulation::etat_change, this,
            [this](MoteurSimulation::Etat) { refleter_etat(); });
    connect(moteur_, &MoteurSimulation::resultats, this,
            [this](const std::map<std::string, double>& courants,
                   const std::map<std::string, double>& tensions) {
                // Les formes d'onde de la dernière trame accompagnent les
                // valeurs instantanées : sans elles, un multimètre ne pourrait
                // afficher ni moyenne ni valeur efficace.
                scene_->appliquer_resultats(
                    courants, tensions,
                    dernieres_formes_.vide() ? nullptr : &dernieres_formes_);
            });
    connect(moteur_, &MoteurSimulation::octet_serie, this,
            [this](char octet, const QString& carte) {
                // Avec plusieurs cartes, on préfixe chaque ligne par son
                // émetteur : sans cela les deux flux seraient indémêlables.
                static QString derniere;
                if (moteur_->cartes().size() > 1 && derniere != carte) {
                    moniteur_serie_->appendPlainText("[" + carte + "] ");
                    derniere = carte;
                }
                moniteur_serie_->moveCursor(QTextCursor::End);
                moniteur_serie_->insertPlainText(QString(QChar(octet)));
                moniteur_serie_->moveCursor(QTextCursor::End);
                if (octet == '\n') derniere.clear();
            });
    connect(moteur_, &MoteurSimulation::etats_composants, this,
            [this](const std::map<std::string, std::map<std::string, double>>&
                       etats) { scene_->appliquer_etats(etats); });
    connect(moteur_, &MoteurSimulation::trame_calculee, this,
            [this](const coeur::Formes& formes, double instant) {
                oscilloscope_->ajouter_trame(formes, instant);
                dernieres_formes_ = formes;
            });
    connect(moteur_, &MoteurSimulation::avancement, this,
            [this](double temps, double vitesse) {
                etiquette_temps_->setText(
                    QString("Temps simulé : %1 s").arg(temps / 1000.0, 0, 'f', 3));
                etiquette_vitesse_->setText(
                    QString("Vitesse : %1 × temps réel").arg(vitesse, 0, 'f', 2));
            });

    charger_exemple_clignotant();
}

FenetrePrincipale::~FenetrePrincipale() = default;

// ---------------------------------------------------------------------------
void FenetrePrincipale::construire_palette() {
    palette_ = new PaletteComposants(this);

    std::map<QString, QTreeWidgetItem*> categories;
    for (const coeur::Modele* modele : coeur::Catalogue::instance().tous()) {
        const QString categorie = QString::fromStdString(modele->categorie);
        auto it = categories.find(categorie);
        if (it == categories.end()) {
            auto* parent = new QTreeWidgetItem(palette_, {categorie});
            QFont police = parent->font(0);
            police.setBold(true);
            parent->setFont(0, police);
            parent->setFlags(Qt::ItemIsEnabled);
            it = categories.emplace(categorie, parent).first;
        }
        auto* feuille = new QTreeWidgetItem(
            it->second, {QString::fromStdString(modele->libelle)});
        feuille->setData(0, Qt::UserRole, QString::fromStdString(modele->type));
        feuille->setToolTip(
            0, QString("%1 — glissez-le sur le schéma, ou double-cliquez")
                   .arg(QString::fromStdString(modele->libelle)));
    }
    palette_->expandAll();

    connect(palette_, &QTreeWidget::itemDoubleClicked, this,
            [this](QTreeWidgetItem* item, int) {
                const QString type = item->data(0, Qt::UserRole).toString();
                if (type.isEmpty()) return;
                scene_->ajouter_composant(
                    type, vue_->mapToScene(vue_->viewport()->rect().center()));
                circuit_modifie();
            });

    // Cinquante-trois composants, c'est trop pour être parcouru à l'œil : un
    // champ de recherche filtre l'arbre à la frappe et ouvre ce qui reste.
    auto* contenu = new QWidget;
    auto* colonne = new QVBoxLayout(contenu);
    colonne->setContentsMargins(4, 4, 4, 4);
    auto* recherche = new QLineEdit;
    recherche->setPlaceholderText("Rechercher un composant…");
    recherche->setClearButtonEnabled(true);
    colonne->addWidget(recherche);
    colonne->addWidget(palette_, 1);
    connect(recherche, &QLineEdit::textChanged, this,
            [this](const QString& filtre) {
                for (int c = 0; c < palette_->topLevelItemCount(); ++c) {
                    QTreeWidgetItem* categorie = palette_->topLevelItem(c);
                    int visibles = 0;
                    for (int k = 0; k < categorie->childCount(); ++k) {
                        QTreeWidgetItem* feuille = categorie->child(k);
                        const bool garde =
                            filtre.isEmpty()
                            || feuille->text(0).contains(filtre, Qt::CaseInsensitive)
                            || categorie->text(0).contains(filtre,
                                                           Qt::CaseInsensitive);
                        feuille->setHidden(!garde);
                        if (garde) ++visibles;
                    }
                    categorie->setHidden(visibles == 0);
                    if (visibles) categorie->setExpanded(true);
                }
            });

    auto* dock = new QDockWidget("Composants", this);
    dock->setWidget(contenu);
    dock->setObjectName("dock_palette");
    addDockWidget(Qt::LeftDockWidgetArea, dock);
}

void FenetrePrincipale::construire_docks() {
    // --- propriétés du composant sélectionné
    panneau_proprietes_ = new QWidget(this);
    formulaire_ = new QFormLayout(panneau_proprietes_);
    formulaire_->addRow(new QLabel("Sélectionnez un composant."));
    auto* dock_proprietes = new QDockWidget("Propriétés", this);
    dock_proprietes->setObjectName("dock_proprietes");
    dock_proprietes->setWidget(panneau_proprietes_);
    addDockWidget(Qt::RightDockWidgetArea, dock_proprietes);

    // --- programme et console, en onglets
    auto* onglets = new QTabWidget(this);
    onglets_ = onglets;

    auto* page_source = new QWidget;
    auto* disposition = new QVBoxLayout(page_source);

    // Sélecteur de carte : chaque carte du schéma a son propre programme.
    auto* barre_carte = new QHBoxLayout;
    barre_carte->addWidget(new QLabel("Programme de la carte"));
    selecteur_carte_ = new QComboBox;
    selecteur_carte_->setMinimumWidth(120);
    connect(selecteur_carte_, &QComboBox::currentTextChanged, this,
            &FenetrePrincipale::changer_carte);
    barre_carte->addWidget(selecteur_carte_);
    barre_carte->addStretch(1);
    disposition->addLayout(barre_carte);

    editeur_source_ = new QPlainTextEdit(kSourceExemple);
    QFont fonte("monospace");
    fonte.setStyleHint(QFont::TypeWriter);
    editeur_source_->setFont(fonte);
    disposition->addWidget(editeur_source_);
    auto* bouton = new QPushButton("Compiler avec avr-gcc et charger");
    connect(bouton, &QPushButton::clicked, this,
            &FenetrePrincipale::compiler_source);
    disposition->addWidget(bouton);
    onglets->addTab(page_source, "Programme (C)");

    console_ = new QPlainTextEdit;
    console_->setReadOnly(true);
    console_->setFont(fonte);
    onglets->addTab(console_, "Journal");

    moniteur_serie_ = new QPlainTextEdit;
    moniteur_serie_->setReadOnly(true);
    moniteur_serie_->setFont(fonte);
    onglets->addTab(moniteur_serie_, "Moniteur série");

    oscilloscope_ = new Oscilloscope;
    onglets->addTab(oscilloscope_, "Oscilloscope");
    connect(oscilloscope_, &Oscilloscope::resolution_souhaitee, this,
            [this](double secondes) { moteur_->definir_resolution(secondes); });

    analyses_ = new PanneauAnalyses;
    onglets->addTab(analyses_, "Analyses");
    connect(analyses_, &PanneauAnalyses::balayage_demande, this,
            [this](const QString& directive, bool bode) {
                circuit_modifie();
                QString erreur;
                if (!moteur_->executer_balayage(directive, &erreur)) {
                    analyses_->signaler(erreur);
                    return;
                }
                // Le gain d'un Bode n'a de sens que rapporté à l'entrée : on
                // désigne d'office le nœud attaqué par le générateur.
                QString reference;
                for (const coeur::Instance& instance :
                     moteur_->netlist().instances()) {
                    const coeur::Modele* modele =
                        coeur::Catalogue::instance().modele(instance.type);
                    if (!modele || !modele->generateur) continue;
                    if (const coeur::Borne* borne = instance.borne("+")) {
                        reference = QString::fromStdString(borne->noeud);
                        break;
                    }
                }
                analyses_->afficher_balayage(moteur_->balayage(), bode,
                                             reference);
            });
    connect(analyses_, &PanneauAnalyses::spectre_demande, this,
            [this](const QString& signal, int harmoniques) {
                const std::vector<double>* courbe = nullptr;
                const std::string nom = signal.toLower().toStdString();
                auto tension = dernieres_formes_.tensions.find(nom);
                if (tension != dernieres_formes_.tensions.end())
                    courbe = &tension->second;
                if (!courbe && signal.startsWith("I(")) {
                    const std::string reference =
                        signal.mid(2, signal.size() - 3).toLower().toStdString();
                    auto courant = dernieres_formes_.courants.find(reference);
                    if (courant != dernieres_formes_.courants.end())
                        courbe = &courant->second;
                }
                if (!courbe || courbe->empty()) {
                    analyses_->signaler(
                        "Aucun relevé pour « " + signal
                        + " » : lancez la simulation, puis relancez l'analyse.");
                    return;
                }
                analyses_->afficher_spectre(
                    coeur::analyser_spectre(dernieres_formes_.temps, *courbe,
                                            harmoniques),
                    signal);
                analyses_->afficher_mesures(
                    coeur::mesurer(dernieres_formes_.temps, *courbe), signal);
            });

    auto* dock_bas = new QDockWidget("Programme et journaux", this);
    dock_bas->setObjectName("dock_bas");
    dock_bas->setWidget(onglets);
    addDockWidget(Qt::BottomDockWidgetArea, dock_bas);
    resizeDocks({dock_bas}, {300}, Qt::Vertical);
}

void FenetrePrincipale::construire_actions() {
    auto* fichier = menuBar()->addMenu("&Fichier");
    fichier->addAction("&Nouveau", QKeySequence::New, this,
                       &FenetrePrincipale::nouveau_projet);
    fichier->addAction("&Ouvrir…", QKeySequence::Open, this,
                       &FenetrePrincipale::ouvrir_projet);
    fichier->addAction("&Enregistrer sous…", QKeySequence::Save, this,
                       &FenetrePrincipale::enregistrer_projet);
    fichier->addSeparator();
    // Les documents que produit un atelier complet : la nomenclature part chez
    // le fournisseur, la netlist KiCad chez le routeur, les courbes dans un
    // tableur, le schéma dans le compte rendu.
    auto* exports = fichier->addMenu("E&xporter");
    exports->addAction("Netlist &SPICE…", this,
                       &FenetrePrincipale::exporter_netlist_spice);
    exports->addAction("Netlist &KiCad (vers le routage)…", this,
                       [this] { exporter_netlist_kicad(); });
    exports->addAction("&Nomenclature (CSV)…", this,
                       [this] { exporter_nomenclature(); });
    exports->addAction("&Relevés de l'analyse (CSV)…", this,
                       [this] { exporter_courbes(); });
    exports->addAction("Schéma en &image ou PDF…", this,
                       [this] { exporter_schema(); });
    exports->addAction("Rapport de &contrôle des règles…", this,
                       [this] { exporter_regles(); });
    fichier->addSeparator();
    fichier->addAction("&Quitter", QKeySequence::Quit, this, &QWidget::close);

    auto* edition = menuBar()->addMenu("&Édition");
    edition->addAction("&Supprimer la sélection", QKeySequence::Delete, this,
                       [this] { scene_->supprimer_selection(); });
    edition->addAction("&Pivoter (R)", QKeySequence(Qt::Key_R), this, [this] {
        for (QGraphicsItem* item : scene_->selectedItems())
            if (item->type() == ItemComposant::Type)
                static_cast<ItemComposant*>(item)->tourner();
        circuit_modifie();
    });

    auto* outils = menuBar()->addMenu("&Outils");
    auto* barre = addToolBar("Principal");
    barre->setObjectName("barre_principale");
    barre->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    barre->setMovable(false);
    // Un peu d'air autour des commandes : une barre d'outils compacte se lit
    // mal, et les deux boutons qui comptent doivent sauter aux yeux.
    barre->setStyleSheet(
        "QToolBar { spacing: 4px; padding: 3px; }"
        "QToolButton { padding: 4px 10px; border-radius: 4px; }"
        "QToolButton:hover { background: #e6eef5; }"
        "QToolButton:checked { background: #d7e6f5; }");

    auto* selection = barre->addAction("Sélection");
    selection->setCheckable(true);
    selection->setChecked(true);
    selection->setToolTip("Déplacer et régler les composants. Cliquer une "
                          "borne tire quand même un fil.");
    auto* fil = barre->addAction("Fil");
    fil->setCheckable(true);
    fil->setToolTip("Ne faire que câbler : les composants ne bougent plus par "
                    "mégarde.");
    auto* gomme = barre->addAction("Supprimer");
    gomme->setCheckable(true);
    gomme->setToolTip("Cliquer un composant ou un fil pour l'effacer.");
    auto* groupe = new QActionGroup(this);
    groupe->addAction(selection);
    groupe->addAction(fil);
    groupe->addAction(gomme);
    connect(selection, &QAction::triggered, this,
            [this] { scene_->definir_outil(SceneSchema::Outil::Selection); });
    connect(fil, &QAction::triggered, this,
            [this] { scene_->definir_outil(SceneSchema::Outil::Fil); });
    connect(gomme, &QAction::triggered, this,
            [this] { scene_->definir_outil(SceneSchema::Outil::Suppression); });
    outils->addAction(selection);
    outils->addAction(fil);
    outils->addAction(gomme);

    barre->addSeparator();
    barre->addAction("Zoom +", this, [this] { vue_->zoomer(1.25); });
    barre->addAction("Zoom −", this, [this] { vue_->zoomer(1 / 1.25); });
    barre->addAction("Ajuster", this, [this] { vue_->ajuster(); });

    auto* simulation = menuBar()->addMenu("&Simulation");
    barre->addSeparator();
    simulation->addAction("Charger un &firmware (.elf)…", this,
                          &FenetrePrincipale::ouvrir_firmware);
    simulation->addAction("Ouvrir un &programme C…", this,
                          &FenetrePrincipale::ouvrir_source_c);
    simulation->addAction("&Compiler et charger", QKeySequence(Qt::Key_F5), this,
                          &FenetrePrincipale::compiler_source);
    simulation->addSeparator();

    // Commande unique, comme dans un atelier de calcul : le même bouton lance,
    // met en pause et reprend. Un second bouton arrête et remet à zéro. Deux
    // boutons au lieu de trois, et leur libellé dit toujours ce qui va se
    // passer si on clique.
    action_marche_ = barre->addAction("▶  Lancer");
    action_marche_->setShortcut(QKeySequence(Qt::Key_F9));
    connect(action_marche_, &QAction::triggered, this, [this] {
        if (moteur_->etat() == MoteurSimulation::Etat::EnMarche)
            suspendre();
        else
            lancer();
    });
    action_arreter_ = barre->addAction("■  Arrêter");
    action_arreter_->setShortcut(QKeySequence(Qt::SHIFT | Qt::Key_F5));
    connect(action_arreter_, &QAction::triggered, this,
            &FenetrePrincipale::arreter);
    simulation->addAction(action_marche_);
    simulation->addAction(action_arreter_);
    simulation->addSeparator();
    simulation->addAction("Analyse au point de &repos", this,
                          &FenetrePrincipale::analyser_point_repos);

    // Menu d'analyses, comme dans les ateliers de simulation : chaque entrée
    // ouvre l'onglet et lance l'analyse correspondante.
    auto* analyse = menuBar()->addMenu("&Analyse");
    analyse->addAction("&Balayage continu (.dc)", this,
                       [this] { lancer_analyse(0); });
    analyse->addAction("&Réponse en fréquence (Bode, .ac)", this,
                       [this] { lancer_analyse(1); });
    analyse->addAction("&Spectre et distorsion (FFT)", this,
                       [this] { lancer_analyse(2); });
    analyse->addSeparator();
    analyse->addAction("&Contrôler les règles électriques (ERC)", this, [this] {
        circuit_modifie();
        const QString rapport =
            QString::fromStdString(coeur::rapport_regles(moteur_->netlist()));
        ecrire(rapport);
        onglets_->setCurrentIndex(1);            // onglet « Journal »
        if (!silencieux_)
            QMessageBox::information(this, "Contrôle des règles", rapport);
    });
    analyse->addAction("&Nomenclature du montage", this, [this] {
        circuit_modifie();
        QString texte = "Nomenclature :\n";
        for (const auto& ligne : coeur::nomenclature(moteur_->netlist())) {
            QStringList references;
            for (const auto& reference : ligne.references)
                references << QString::fromStdString(reference);
            texte += QString("  %1 × %2 %3 [%4]\n")
                         .arg(ligne.quantite())
                         .arg(QString::fromStdString(ligne.designation))
                         .arg(QString::fromStdString(ligne.valeur))
                         .arg(references.join(' '));
        }
        ecrire(texte);
        onglets_->setCurrentIndex(1);
    });

    auto* exemples = menuBar()->addMenu("E&xemples");
    exemples->addAction("Clignotant sur D13", this,
                        [this] { charger_exemple(Exemple::Clignotant); });
    exemples->addAction("Bouton et LED (entrée avec pull-up)", this,
                        [this] { charger_exemple(Exemple::BoutonLed); });
    exemples->addAction("Potentiomètre sur A0 (conversion analogique)", this,
                        [this] { charger_exemple(Exemple::PotentiometreLed); });
    exemples->addAction("Moteur commandé par transistor", this,
                        [this] { charger_exemple(Exemple::Transistor); });
    exemples->addAction("PWM sur D9 (à observer à l'oscilloscope)", this,
                        [this] { charger_exemple(Exemple::Pwm); });
    exemples->addAction("Deux cartes qui communiquent", this,
                        [this] { charger_exemple(Exemple::DeuxCartes); });
    exemples->addAction("Servomoteur balayé", this,
                        [this] { charger_exemple(Exemple::Servo); });
    exemples->addAction("Filtre RC (analyses : Bode, balayage, spectre)", this,
                        [this] { charger_exemple(Exemple::FiltreRC); });
    exemples->addAction("Moteur en PWM avec transistor", this,
                        [this] { charger_exemple(Exemple::MoteurPuissance); });

    // Fenêtres : c'est l'utilisateur qui sort un panneau de mesure, jamais
    // l'application. Le raccourci le remet aussi bien qu'il le sort.
    auto* fenetres = menuBar()->addMenu("Fe&nêtres");
    fenetres->addAction("Oscilloscope dans sa propre fenêtre",
                        QKeySequence(Qt::CTRL | Qt::Key_1), this,
                        [this] { basculer_fenetre(oscilloscope_); });
    fenetres->addAction("Analyses dans leur propre fenêtre",
                        QKeySequence(Qt::CTRL | Qt::Key_2), this,
                        [this] { basculer_fenetre(analyses_); });
    fenetres->addSeparator();
    fenetres->addAction("Fermer toutes les fenêtres de mesure", this, [this] {
        while (!fenetres_instruments_.empty())
            fenetres_instruments_.front()->close();
    });

    auto* aide = menuBar()->addMenu("&Aide");
    aide->addAction("À &propos", this, [this] {
        QMessageBox::about(
            this, "À propos",
            "<h3>Simulateur embarqué</h3>"
            "<p>Saisie de schéma, simulation analogique et exécution du vrai "
            "firmware compilé, dans une seule application.</p>"
            "<p>Moteur analogique : <b>ngspice</b> — celui de KiCad.<br>"
            "Moteur microcontrôleur : <b>simavr</b> — exécution cycle par "
            "cycle d'un ATmega328P.</p>"
            "<p>Raccourcis : <b>R</b> pivote la sélection, <b>Suppr</b> "
            "l'efface, la molette zoome.</p>");
    });
}

void FenetrePrincipale::construire_barre_etat() {
    etiquette_moteurs_ = new QLabel;
    etiquette_etat_ = new QLabel;
    etiquette_temps_ = new QLabel("Temps simulé : 0,000 s");
    etiquette_vitesse_ = new QLabel("Vitesse : —");

    const bool spice = coeur::NgspiceEngine::compile_avec_ngspice();
    const bool avr = coeur::AvrEngine::compile_avec_simavr();
    const bool gcc = coeur::AvrEngine::avr_gcc_disponible();
    // Une pastille par moteur : verte s'il est là, grise sinon. Le détail —
    // à quoi il sert, ce qu'il manque — passe en infobulle plutôt que
    // d'encombrer la barre en permanence.
    auto pastille = [](bool present, const QString& nom) {
        return QString("<span style='color:%1'>●</span> %2")
            .arg(present ? "#2e9e44" : "#b0b0b0", nom);
    };
    etiquette_moteurs_->setText(pastille(spice, "ngspice") + "   "
                                + pastille(avr, "simavr") + "   "
                                + pastille(gcc, "avr-gcc"));
    etiquette_moteurs_->setToolTip(
        QString("ngspice : %1 — calcul des tensions et des courants\n"
                "simavr : %2 — exécution du firmware\n"
                "avr-gcc : %3 — compilation depuis l'application")
            .arg(spice ? "présent" : "absent",
                 avr ? "présent" : "absent", gcc ? "présent" : "absent"));

    statusBar()->addWidget(etiquette_etat_);
    statusBar()->addWidget(new QLabel("  "));
    statusBar()->addWidget(etiquette_moteurs_);
    statusBar()->addPermanentWidget(etiquette_temps_);
    statusBar()->addPermanentWidget(etiquette_vitesse_);
    refleter_etat();

    // Une ligne d'état ne suffit pas : sans ngspice, l'application se lance,
    // le schéma se dessine, et rien ne se passe quand on simule. Il faut le
    // dire en clair, et dire quoi installer.
    if (!spice)
        ecrire("ngspice n'est pas là : le schéma se dessine et s'exporte, mais "
               "aucune tension ne sera calculée (ni oscilloscope, ni analyses). "
               "Debian/Ubuntu : « libngspice0-dev ». MSYS2/Windows : "
               "« mingw-w64-ucrt-x86_64-ngspice ». Puis reconfigurer avec "
               "cmake.");
    if (!avr)
        ecrire("simavr n'est pas là : les programmes ne seront pas exécutés. "
               "La partie analogique, elle, fonctionne entièrement.");
    else if (!coeur::AvrEngine::avr_gcc_disponible())
        ecrire("avr-gcc est introuvable dans le PATH : le bouton « Compiler » "
               "ne fonctionnera pas. On peut malgré tout charger un .elf déjà "
               "compilé (Simulation → Charger un firmware).");
}

// Le libellé du bouton dit ce qui va se passer, la pastille dit où on en est.
void FenetrePrincipale::refleter_etat() {
    const MoteurSimulation::Etat etat = moteur_->etat();
    const bool marche = etat == MoteurSimulation::Etat::EnMarche;
    const bool pause = etat == MoteurSimulation::Etat::EnPause;

    if (action_marche_) {
        action_marche_->setText(marche  ? "❚❚  Pause"
                                : pause ? "▶  Reprendre"
                                        : "▶  Lancer");
        action_marche_->setToolTip(
            marche ? "Suspendre la simulation sans rien perdre (F9)"
                   : "Lancer la simulation du circuit et du programme (F9)");
    }
    if (action_arreter_) {
        action_arreter_->setEnabled(marche || pause);
        action_arreter_->setToolTip(
            "Arrêter et remettre les microcontrôleurs à zéro (Maj+F5)");
    }
    if (etiquette_etat_) {
        const QString couleur = marche ? "#2e9e44" : pause ? "#d08a1e" : "#8a8a8a";
        const QString texte = marche ? "en marche" : pause ? "en pause" : "arrêté";
        etiquette_etat_->setText(
            QString("<span style='color:%1'>●</span> <b>%2</b>")
                .arg(couleur, texte));
    }
    if (!marche && etiquette_vitesse_) etiquette_vitesse_->setText("Vitesse : —");
}

// ---------------------------------------------------------------------------
// Fenêtres de mesure
// ---------------------------------------------------------------------------
void FenetrePrincipale::basculer_fenetre(QWidget* panneau) {
    if (!panneau || !onglets_) return;

    auto detache = detaches_.find(panneau);
    if (detache != detaches_.end()) {   // il est dehors : on le rentre
        const PanneauDetache place = detache->second;
        detaches_.erase(detache);
        panneau->removeEventFilter(this);
        panneau->setWindowFlags(Qt::Widget);
        onglets_->insertTab(std::min(place.rang, onglets_->count()), panneau,
                            place.titre);
        onglets_->setCurrentWidget(panneau);
        return;
    }

    const int rang = onglets_->indexOf(panneau);
    if (rang < 0) return;
    const QString titre = onglets_->tabText(rang);
    onglets_->removeTab(rang);
    detaches_[panneau] = {titre, rang};
    panneau->setParent(nullptr);
    panneau->setWindowFlags(Qt::Window);
    panneau->setWindowTitle(titre + " — simulateur");
    panneau->resize(940, 520);
    panneau->installEventFilter(this);
    panneau->show();
    panneau->raise();
}

bool FenetrePrincipale::eventFilter(QObject* objet, QEvent* evenement) {
    // Fermer la fenêtre détachée la remet dans les onglets : le panneau n'est
    // jamais perdu, et rien ne se rouvre tout seul au démarrage.
    if (evenement->type() == QEvent::Close) {
        auto* panneau = qobject_cast<QWidget*>(objet);
        if (panneau && detaches_.count(panneau)) {
            basculer_fenetre(panneau);
            evenement->ignore();
            return true;
        }
    }
    return QMainWindow::eventFilter(objet, evenement);
}

void FenetrePrincipale::ouvrir_fenetre_instrument(ItemComposant* composant) {
    if (!composant || !composant->modele()) return;
    if (!composant->modele()->mesure_instrument) {
        // Pas un instrument : le double-clic sert alors à régler le composant.
        afficher_proprietes(composant);
        return;
    }

    // Une seule fenêtre par appareil : un second double-clic la ramène devant.
    for (FenetreInstrument* fenetre : fenetres_instruments_) {
        if (fenetre->composant() != composant) continue;
        fenetre->show();
        fenetre->raise();
        fenetre->activateWindow();
        return;
    }

    auto* fenetre = new FenetreInstrument(
        composant,
        [this](ItemComposant* cible) {
            for (ItemComposant* pose : scene_->composants())
                if (pose == cible) return true;
            return false;
        },
        [this](ItemComposant* cible) -> QString {
            const coeur::Modele* modele = cible->modele();
            if (modele && modele->type == "amperemetre")
                return QString("I(%1)").arg(cible->reference());
            // Voltmètre ou sonde : c'est le potentiel de sa première borne.
            return scene_->noeud_de(cible, 0);
        },
        this);
    connect(fenetre, &FenetreInstrument::sonde_demandee, this,
            [this](const QString& designation) {
                if (!oscilloscope_) return;
                oscilloscope_->sonder(designation);
                if (!detaches_.count(oscilloscope_))
                    onglets_->setCurrentWidget(oscilloscope_);
                ecrire("Suivi à l'oscilloscope : " + designation);
            });
    connect(fenetre, &QObject::destroyed, this, [this, fenetre] {
        fenetres_instruments_.erase(
            std::remove(fenetres_instruments_.begin(),
                        fenetres_instruments_.end(), fenetre),
            fenetres_instruments_.end());
    });
    fenetre->setAttribute(Qt::WA_DeleteOnClose);
    fenetres_instruments_.push_back(fenetre);
    fenetre->show();
}

void FenetrePrincipale::menu_contextuel(ItemComposant* composant,
                                        const QPoint& ecran) {
    QMenu menu(this);
    if (composant) {
        const coeur::Modele* modele = composant->modele();
        menu.addAction(composant->reference() + " — "
                       + (modele ? QString::fromStdString(modele->libelle)
                                 : QString()))
            ->setEnabled(false);
        menu.addSeparator();
        if (modele && modele->mesure_instrument)
            menu.addAction("Ouvrir la fenêtre de mesure", this,
                           [this, composant] {
                               ouvrir_fenetre_instrument(composant);
                           });
        menu.addAction("Propriétés", this,
                       [this, composant] { afficher_proprietes(composant); });
        menu.addAction("Pivoter de 90°", this, [this, composant] {
            composant->tourner();
            circuit_modifie();
        });
        menu.addSeparator();
        menu.addAction("Supprimer", this, [this] {
            scene_->supprimer_selection();
            circuit_modifie();
        });
    } else {
        menu.addAction("Ajuster la vue", this, [this] { vue_->ajuster(); });
        menu.addAction("Analyse au point de repos", this,
                       &FenetrePrincipale::analyser_point_repos);
    }
    menu.exec(ecran);
}

// ---------------------------------------------------------------------------
void FenetrePrincipale::ecrire(const QString& message) {
    if (!console_) return;
    console_->appendPlainText(message);
}

void FenetrePrincipale::avertir(const QString& titre, const QString& message) {
    ecrire(titre + " : " + message);
    if (!silencieux_) QMessageBox::warning(this, titre, message);
}

void FenetrePrincipale::showEvent(QShowEvent* evenement) {
    QMainWindow::showEvent(evenement);
    // Le cadrage n'a de sens qu'une fois la vue dimensionnée : appelé depuis
    // le constructeur, il calculerait un zoom à partir d'un widget vide.
    if (premier_affichage_) {
        premier_affichage_ = false;
        QTimer::singleShot(0, this, [this] { vue_->ajuster(); });
    }
}

void FenetrePrincipale::demarrage_automatique() {
    // Toutes les cartes, pas seulement celle affichée : sinon la seconde
    // resterait inerte et la vérification ne prouverait rien.
    const QStringList cartes = moteur_->cartes();
    if (cartes.isEmpty()) {
        // Montage purement analogique : il n'y a rien à compiler, seulement à
        // simuler.
        lancer();
        return;
    }
    if (cartes.size() <= 1) {
        compiler_source();
    } else {
        for (const QString& reference : cartes) {
            if (selecteur_carte_) selecteur_carte_->setCurrentText(reference);
            compiler_source();
        }
    }
    lancer();
}

QString FenetrePrincipale::dossier_travail() const {
    return QStandardPaths::writableLocation(QStandardPaths::TempLocation) +
           "/simulateur-embarque";
}

// ---------------------------------------------------------------------------
void FenetrePrincipale::circuit_modifie() {
    std::vector<LiaisonBroche> broches;
    coeur::Netlist netlist = scene_->construire_netlist(&broches);

    // Signaux observables : la tension de chaque nœud, et le courant de
    // chaque composant. L'oscilloscope suit donc le schéma sans réglage.
    QStringList signaux;
    for (const std::string& noeud : netlist.noeuds())
        if (!noeud.empty()) signaux << QString::fromStdString(noeud);
    for (const coeur::Instance& instance : netlist.instances())
        signaux << QString("I(%1)").arg(
            QString::fromStdString(instance.reference));
    signaux.sort();

    // Un nom de nœud ne dit rien tout seul : on lui joint ce qu'il relie, et
    // un courant dit dans quel composant il circule.
    std::map<QString, QString> libelles = scene_->description_noeuds();
    for (const coeur::Instance& instance : netlist.instances()) {
        const QString reference = QString::fromStdString(instance.reference);
        const coeur::Modele* modele =
            coeur::Catalogue::instance().modele(instance.type);
        libelles[QString("I(%1)").arg(reference)] =
            QString("courant dans %1%2")
                .arg(reference,
                     modele ? " (" + QString::fromStdString(modele->libelle) + ")"
                            : QString());
    }
    libelles["GND"] = "masse, 0 V";
    libelles["5V"] = "alimentation 5 V";
    libelles["3V3"] = "alimentation 3,3 V";

    if (oscilloscope_) oscilloscope_->proposer_signaux(signaux, libelles);

    // Grandeurs balayables : les sources imposent une tension, les résistances
    // une valeur. Ce sont exactement les deux formes de « .dc » de SPICE, et
    // le nom donné ici est celui du composant dans la netlist.
    if (analyses_) {
        // Les sources d'abord : c'est ce qu'on balaie neuf fois sur dix.
        QStringList generateurs, resistances;
        for (const coeur::Instance& instance : netlist.instances()) {
            const coeur::Modele* modele =
                coeur::Catalogue::instance().modele(instance.type);
            if (!modele) continue;
            if (modele->generateur)
                generateurs << QString("V%1").arg(
                    QString::fromStdString(instance.reference));
            else if (instance.type == "resistance")
                resistances << QString("R%1").arg(
                    QString::fromStdString(instance.reference));
        }
        analyses_->proposer_sources(generateurs + resistances);
        analyses_->proposer_signaux(signaux, libelles);
    }

    const QStringList cartes = scene_->cartes_presentes();
    moteur_->definir_circuit(std::move(netlist), std::move(broches), cartes);
    synchroniser_cartes(cartes);
}

// Le sélecteur suit les cartes réellement posées. Cette méthode doit toujours
// laisser `carte_courante_` sur une carte existante : si elle restait vide, le
// programme affiché ne serait rattaché à personne et le prochain changement
// l'écraserait sans l'avoir rangé.
void FenetrePrincipale::synchroniser_cartes(const QStringList& cartes) {
    if (!selecteur_carte_) return;

    QStringList actuelles;
    for (int k = 0; k < selecteur_carte_->count(); ++k)
        actuelles << selecteur_carte_->itemText(k);

    if (actuelles != cartes) {
        const QString choix = selecteur_carte_->currentText();
        const QSignalBlocker silence(selecteur_carte_);
        selecteur_carte_->clear();
        selecteur_carte_->addItems(cartes);
        const int rang = selecteur_carte_->findText(choix);
        selecteur_carte_->setCurrentIndex(rang >= 0 ? rang : 0);
        selecteur_carte_->setEnabled(cartes.size() > 1);
    }

    const QString voulue = selecteur_carte_->currentText();
    if (voulue != carte_courante_) changer_carte(voulue);
}

void FenetrePrincipale::changer_carte(const QString& reference) {
    if (reference == carte_courante_) return;
    // Le programme affiché appartient à la carte qu'on quitte : on le range
    // avant d'afficher celui de la nouvelle.
    if (!carte_courante_.isEmpty() && editeur_source_)
        programmes_[carte_courante_] = editeur_source_->toPlainText();
    carte_courante_ = reference;
    if (!editeur_source_ || reference.isEmpty()) return;

    auto it = programmes_.find(reference);
    if (it == programmes_.end()) {
        // Nouvelle carte : on lui propose le programme d'exemple plutôt
        // qu'un éditeur vide.
        programmes_[reference] = QString::fromUtf8(kSourceExemple);
        it = programmes_.find(reference);
    }
    const QSignalBlocker silence(editeur_source_);
    editeur_source_->setPlainText(it->second);
}

void FenetrePrincipale::afficher_proprietes(ItemComposant* composant) {
    selection_ = composant;
    while (formulaire_->rowCount() > 0) formulaire_->removeRow(0);

    if (!composant || !composant->modele()) {
        formulaire_->addRow(new QLabel("Sélectionnez un composant."));
        return;
    }
    const coeur::Modele* modele = composant->modele();
    formulaire_->addRow("Référence", new QLabel(composant->reference()));
    formulaire_->addRow("Type", new QLabel(QString::fromStdString(modele->libelle)));

    for (const coeur::Propriete& propriete : modele->proprietes) {
        const QString libelle =
            QString::fromStdString(propriete.libelle) +
            (propriete.unite.empty()
                 ? QString()
                 : QString(" (%1)").arg(QString::fromStdString(propriete.unite)));
        const std::string cle = propriete.cle;

        switch (propriete.genre) {
            case coeur::Propriete::Genre::Choix: {
                auto* liste = new QComboBox;
                for (const std::string& choix : propriete.choix)
                    liste->addItem(QString::fromStdString(choix));
                auto it = composant->textes.find(cle);
                if (it != composant->textes.end())
                    liste->setCurrentText(QString::fromStdString(it->second));
                connect(liste, &QComboBox::currentTextChanged, this,
                        [this, composant, cle](const QString& valeur) {
                            composant->textes[cle] = valeur.toStdString();
                            composant->update();
                            circuit_modifie();
                        });
                formulaire_->addRow(libelle, liste);
                break;
            }
            case coeur::Propriete::Genre::Curseur: {
                auto* curseur = new QSlider(Qt::Horizontal);
                curseur->setRange(static_cast<int>(propriete.mini),
                                  static_cast<int>(propriete.maxi));
                curseur->setValue(
                    static_cast<int>(composant->valeurs[cle]));
                auto* valeur_affichee =
                    new QLabel(QString::number(composant->valeurs[cle]));
                connect(curseur, &QSlider::valueChanged, this,
                        [this, composant, cle, valeur_affichee](int valeur) {
                            composant->valeurs[cle] = valeur;
                            valeur_affichee->setText(QString::number(valeur));
                            composant->update();
                            circuit_modifie();
                            if (!moteur_->en_marche()) analyser_point_repos();
                        });
                auto* ligne = new QWidget;
                auto* disposition = new QVBoxLayout(ligne);
                disposition->setContentsMargins(0, 0, 0, 0);
                disposition->addWidget(curseur);
                disposition->addWidget(valeur_affichee);
                formulaire_->addRow(libelle, ligne);
                break;
            }
            case coeur::Propriete::Genre::Nombre: {
                auto* champ = new QDoubleSpinBox;
                champ->setDecimals(9);
                champ->setRange(0, 1e9);
                champ->setValue(composant->valeurs[cle]);
                champ->setKeyboardTracking(false);
                connect(champ, &QDoubleSpinBox::valueChanged, this,
                        [this, composant, cle](double valeur) {
                            composant->valeurs[cle] = valeur;
                            composant->update();
                            circuit_modifie();
                            if (!moteur_->en_marche()) analyser_point_repos();
                        });
                formulaire_->addRow(libelle, champ);
                break;
            }
        }
    }

    auto* pivoter = new QPushButton("Pivoter de 90°");
    connect(pivoter, &QPushButton::clicked, this, [this, composant] {
        composant->tourner();
        for (ItemFil* fil : scene_->fils()) fil->rafraichir();
    });
    formulaire_->addRow(pivoter);
}

// ---------------------------------------------------------------------------
void FenetrePrincipale::nouveau_projet() {
    scene_->tout_effacer();
    chemin_projet_.clear();
    programmes_.clear();
    carte_courante_.clear();
    circuit_modifie();
    ecrire("Nouveau schéma.");
}

void FenetrePrincipale::enregistrer_projet() {
    const QString chemin = QFileDialog::getSaveFileName(
        this, "Enregistrer le schéma", chemin_projet_,
        "Schéma (*.schema.json);;Tous les fichiers (*)");
    if (chemin.isEmpty()) return;
    enregistrer_vers(chemin);
}

bool FenetrePrincipale::enregistrer_vers(const QString& chemin) {

    QJsonArray composants;
    std::map<const ItemComposant*, int> index;
    int k = 0;
    for (ItemComposant* item : scene_->composants()) {
        index[item] = k++;
        QJsonObject objet;
        objet["type"] = QString::fromStdString(item->modele()->type);
        objet["reference"] = item->reference();
        objet["x"] = item->pos().x();
        objet["y"] = item->pos().y();
        objet["rotation"] = item->rotation();
        QJsonObject valeurs;
        for (const auto& paire : item->valeurs)
            valeurs[QString::fromStdString(paire.first)] = paire.second;
        objet["valeurs"] = valeurs;
        QJsonObject textes;
        for (const auto& paire : item->textes)
            textes[QString::fromStdString(paire.first)] =
                QString::fromStdString(paire.second);
        objet["textes"] = textes;
        composants.append(objet);
    }

    QJsonArray fils;
    for (ItemFil* fil : scene_->fils()) {
        if (!index.count(fil->depart()) || !index.count(fil->arrivee())) continue;
        QJsonObject objet;
        objet["a"] = index[fil->depart()];
        objet["borne_a"] = fil->borne_depart();
        objet["b"] = index[fil->arrivee()];
        objet["borne_b"] = fil->borne_arrivee();
        fils.append(objet);
    }

    QJsonObject racine;
    racine["format"] = "simulateur-embarque/schema";
    racine["version"] = 1;
    racine["composants"] = composants;
    racine["fils"] = fils;
    // Un programme par carte : n'en garder qu'un perdrait celui des autres.
    if (!carte_courante_.isEmpty())
        programmes_[carte_courante_] = editeur_source_->toPlainText();
    QJsonObject programmes;
    for (const auto& paire : programmes_)
        programmes[paire.first] = paire.second;
    racine["programmes"] = programmes;
    racine["programme"] = editeur_source_->toPlainText();   // anciens fichiers

    QFile fichier(chemin);
    if (!fichier.open(QIODevice::WriteOnly)) {
        avertir("Enregistrement", "Impossible d'écrire " + chemin);
        return false;
    }
    fichier.write(QJsonDocument(racine).toJson(QJsonDocument::Indented));
    chemin_projet_ = chemin;
    ecrire("Schéma enregistré : " + chemin);
    return true;
}

void FenetrePrincipale::ouvrir_projet() {
    const QString chemin = QFileDialog::getOpenFileName(
        this, "Ouvrir un schéma", QString(),
        "Schéma (*.schema.json *.json);;Tous les fichiers (*)");
    if (chemin.isEmpty()) return;
    ouvrir_depuis(chemin);
}

bool FenetrePrincipale::ouvrir_depuis(const QString& chemin) {
    QFile fichier(chemin);
    if (!fichier.open(QIODevice::ReadOnly)) {
        avertir("Ouverture", "Impossible de lire " + chemin);
        return false;
    }
    const QJsonObject racine =
        QJsonDocument::fromJson(fichier.readAll()).object();

    scene_->tout_effacer();
    std::vector<ItemComposant*> ajoutes;
    for (const QJsonValue& valeur : racine["composants"].toArray()) {
        const QJsonObject objet = valeur.toObject();
        ItemComposant* item = scene_->ajouter_composant(
            objet["type"].toString(),
            QPointF(objet["x"].toDouble(), objet["y"].toDouble()));
        if (!item) {
            ajoutes.push_back(nullptr);
            continue;
        }
        item->definir_reference(objet["reference"].toString());
        item->setRotation(objet["rotation"].toDouble());
        const QJsonObject valeurs = objet["valeurs"].toObject();
        for (auto it = valeurs.begin(); it != valeurs.end(); ++it)
            item->valeurs[it.key().toStdString()] = it.value().toDouble();
        const QJsonObject textes = objet["textes"].toObject();
        for (auto it = textes.begin(); it != textes.end(); ++it)
            item->textes[it.key().toStdString()] =
                it.value().toString().toStdString();
        ajoutes.push_back(item);
    }
    for (const QJsonValue& valeur : racine["fils"].toArray()) {
        const QJsonObject objet = valeur.toObject();
        const int a = objet["a"].toInt(), b = objet["b"].toInt();
        if (a < 0 || b < 0 || a >= static_cast<int>(ajoutes.size()) ||
            b >= static_cast<int>(ajoutes.size()))
            continue;
        if (!ajoutes[a] || !ajoutes[b]) continue;
        scene_->addItem(new ItemFil(ajoutes[a], objet["borne_a"].toInt(),
                                    ajoutes[b], objet["borne_b"].toInt()));
    }
    // Les programmes de l'ancien projet ne doivent pas déborder sur le
    // nouveau : on repart d'une table vide.
    programmes_.clear();
    carte_courante_.clear();
    const QJsonObject programmes = racine["programmes"].toObject();
    for (auto it = programmes.begin(); it != programmes.end(); ++it)
        programmes_[it.key()] = it.value().toString();
    if (programmes_.empty() && racine.contains("programme")) {
        // Fichier d'une version antérieure : un seul programme, pour la
        // première carte.
        const QStringList cartes = scene_->cartes_presentes();
        if (!cartes.isEmpty())
            programmes_[cartes.first()] = racine["programme"].toString();
    }

    chemin_projet_ = chemin;
    circuit_modifie();
    // Après recensement des cartes, on réaffiche le programme de celle qui est
    // sélectionnée : `changer_carte` a pu s'exécuter avant le chargement de
    // `programmes_`.
    const QString affichee = carte_courante_;
    carte_courante_.clear();
    changer_carte(affichee.isEmpty() ? scene_->cartes_presentes().value(0)
                                     : affichee);
    vue_->ajuster();
    ecrire("Schéma ouvert : " + chemin);
    return true;
}

void FenetrePrincipale::exporter_netlist_spice() {
    circuit_modifie();
    moteur_->resoudre_une_fois();
    if (moteur_->source_spice().isEmpty()) {
        avertir("Netlist", "Le schéma ne produit encore aucune netlist.");
        return;
    }
    const QString chemin = QFileDialog::getSaveFileName(
        this, "Exporter la netlist SPICE", "circuit.cir",
        "Netlist SPICE (*.cir *.net);;Tous les fichiers (*)");
    if (chemin.isEmpty()) return;
    QFile fichier(chemin);
    if (!fichier.open(QIODevice::WriteOnly | QIODevice::Text)) {
        avertir("Export", "Impossible d'écrire " + chemin);
        return;
    }
    fichier.write(moteur_->source_spice().toUtf8());
    ecrire("Netlist SPICE exportée : " + chemin);
}

// ---------------------------------------------------------------------------
void FenetrePrincipale::ouvrir_firmware() {
    const QString chemin = QFileDialog::getOpenFileName(
        this, "Charger un firmware", QString(),
        "Firmware AVR (*.elf *.hex);;Tous les fichiers (*)");
    if (chemin.isEmpty()) return;
    QString erreur;
    if (!moteur_->charger_firmware(chemin, &erreur)) avertir("Firmware", erreur);
}

void FenetrePrincipale::ouvrir_source_c() {
    const QString chemin = QFileDialog::getOpenFileName(
        this, "Ouvrir un programme", QString(),
        "Sources C (*.c *.ino *.cpp);;Tous les fichiers (*)");
    if (chemin.isEmpty()) return;
    QFile fichier(chemin);
    if (!fichier.open(QIODevice::ReadOnly | QIODevice::Text)) {
        avertir("Ouverture", "Impossible de lire " + chemin);
        return;
    }
    editeur_source_->setPlainText(QString::fromUtf8(fichier.readAll()));
    ecrire("Programme ouvert : " + chemin);
}

void FenetrePrincipale::compiler_source() {
    QString compte_rendu;
    if (!carte_courante_.isEmpty())
        programmes_[carte_courante_] = editeur_source_->toPlainText();
    const bool ok = moteur_->compiler_et_charger(editeur_source_->toPlainText(),
                                                 dossier_travail(),
                                                 &compte_rendu,
                                                 carte_courante_);
    if (!compte_rendu.trimmed().isEmpty()) ecrire(compte_rendu.trimmed());
    if (ok) {
        ecrire("Compilation réussie.");
    } else {
        ecrire("Échec de la compilation.");
        avertir("Compilation", compte_rendu.isEmpty()
                                   ? QString("La compilation a échoué.")
                                   : compte_rendu);
    }
}

// ---------------------------------------------------------------------------
void FenetrePrincipale::lancer() {
    circuit_modifie();
    if (oscilloscope_) oscilloscope_->sonder_par_defaut();
    moteur_->demarrer();
}

void FenetrePrincipale::definir_base_temps(double secondes) {
    if (oscilloscope_) oscilloscope_->definir_base_temps(secondes);
}

double FenetrePrincipale::vitesse() const { return moteur_->vitesse(); }

QString FenetrePrincipale::mesures_oscilloscope() const {
    return oscilloscope_ ? oscilloscope_->rapport() : QString();
}

void FenetrePrincipale::afficher_onglet(int rang) {
    if (onglets_ && rang >= 0 && rang < onglets_->count())
        onglets_->setCurrentIndex(rang);
}

void FenetrePrincipale::suspendre() { moteur_->suspendre(); }

void FenetrePrincipale::arreter() {
    moteur_->arreter();
    scene_->effacer_resultats();
    if (oscilloscope_) oscilloscope_->vider();
}

void FenetrePrincipale::analyser_point_repos() {
    circuit_modifie();
    moteur_->resoudre_une_fois();
}

// ---------------------------------------------------------------------------
// Analyses paramétriques et documents
// ---------------------------------------------------------------------------
void FenetrePrincipale::lancer_analyse(int rang) {
    if (!analyses_) return;
    circuit_modifie();
    // L'onglet doit être visible : une analyse dont le résultat reste caché
    // derrière un autre onglet passerait pour une commande sans effet.
    onglets_->setCurrentWidget(analyses_);
    analyses_->choisir_analyse(rang);
    analyses_->lancer();
}

QString FenetrePrincipale::resume_analyse() const {
    return analyses_ ? analyses_->resume() : QString();
}

// Fabrique commune aux exports : demande un chemin si besoin, écrit, journalise.
namespace {
bool ecrire_fichier(const QString& chemin, const QByteArray& contenu) {
    QFile fichier(chemin);
    if (!fichier.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
    fichier.write(contenu);
    return true;
}
}  // namespace

bool FenetrePrincipale::exporter_nomenclature(const QString& chemin_demande) {
    circuit_modifie();
    if (moteur_->netlist().instances().empty()) {
        avertir("Nomenclature", "Le schéma est vide.");
        return false;
    }
    QString chemin = chemin_demande;
    if (chemin.isEmpty())
        chemin = QFileDialog::getSaveFileName(
            this, "Exporter la nomenclature", "nomenclature.csv",
            "Tableur (*.csv);;Tous les fichiers (*)");
    if (chemin.isEmpty()) return false;
    const std::string csv = coeur::nomenclature_csv(moteur_->netlist());
    if (!ecrire_fichier(chemin, QByteArray::fromStdString(csv))) {
        avertir("Export", "Impossible d'écrire " + chemin);
        return false;
    }
    ecrire("Nomenclature exportée : " + chemin);
    return true;
}

bool FenetrePrincipale::exporter_regles(const QString& chemin_demande) {
    circuit_modifie();
    QString chemin = chemin_demande;
    if (chemin.isEmpty())
        chemin = QFileDialog::getSaveFileName(
            this, "Enregistrer le rapport de contrôle", "controle-regles.txt",
            "Texte (*.txt);;Tous les fichiers (*)");
    if (chemin.isEmpty()) return false;
    const std::string rapport = coeur::rapport_regles(moteur_->netlist());
    if (!ecrire_fichier(chemin, QByteArray::fromStdString(rapport))) {
        avertir("Export", "Impossible d'écrire " + chemin);
        return false;
    }
    ecrire("Rapport de contrôle enregistré : " + chemin);
    return true;
}

bool FenetrePrincipale::exporter_netlist_kicad(const QString& chemin_demande) {
    circuit_modifie();
    if (moteur_->netlist().instances().empty()) {
        avertir("Netlist", "Le schéma est vide.");
        return false;
    }
    QString chemin = chemin_demande;
    if (chemin.isEmpty())
        chemin = QFileDialog::getSaveFileName(
            this, "Exporter la netlist KiCad", "circuit.net",
            "Netlist KiCad (*.net);;Tous les fichiers (*)");
    if (chemin.isEmpty()) return false;
    const std::string texte = coeur::netlist_kicad(moteur_->netlist());
    if (!ecrire_fichier(chemin, QByteArray::fromStdString(texte))) {
        avertir("Export", "Impossible d'écrire " + chemin);
        return false;
    }
    ecrire("Netlist KiCad exportée : " + chemin);
    return true;
}

bool FenetrePrincipale::exporter_courbes(const QString& chemin_demande) {
    // Priorité au dernier balayage : c'est lui qu'on vient de regarder. À
    // défaut, les formes d'onde de la dernière trame.
    QString contenu = analyses_ ? analyses_->csv() : QString();
    if (contenu.isEmpty() && !dernieres_formes_.vide())
        contenu = QString::fromStdString(coeur::courbes_csv(dernieres_formes_));
    if (contenu.isEmpty()) {
        avertir("Relevés", "Aucun relevé à exporter : lancez une simulation ou "
                           "une analyse.");
        return false;
    }
    QString chemin = chemin_demande;
    if (chemin.isEmpty())
        chemin = QFileDialog::getSaveFileName(
            this, "Exporter les relevés", "releves.csv",
            "Tableur (*.csv);;Tous les fichiers (*)");
    if (chemin.isEmpty()) return false;
    if (!ecrire_fichier(chemin, contenu.toUtf8())) {
        avertir("Export", "Impossible d'écrire " + chemin);
        return false;
    }
    ecrire("Relevés exportés : " + chemin);
    return true;
}

bool FenetrePrincipale::exporter_schema(const QString& chemin_demande) {
    QString chemin = chemin_demande;
    if (chemin.isEmpty())
        chemin = QFileDialog::getSaveFileName(
            this, "Exporter le schéma", "schema.pdf",
            "Document PDF (*.pdf);;Image PNG (*.png);;Tous les fichiers (*)");
    if (chemin.isEmpty()) return false;

    QRectF zone = scene_->itemsBoundingRect().adjusted(-20, -20, 20, 20);
    if (zone.isEmpty()) {
        avertir("Export", "Le schéma est vide.");
        return false;
    }

    if (chemin.endsWith(".pdf", Qt::CaseInsensitive)) {
        // Le PDF est vectoriel : le schéma reste net à n'importe quel zoom,
        // ce qu'attend un compte rendu ou une planche de TP.
        QPdfWriter ecrivain(chemin);
        ecrivain.setPageSize(QPageSize(QPageSize::A4));
        ecrivain.setPageOrientation(zone.width() > zone.height()
                                        ? QPageLayout::Landscape
                                        : QPageLayout::Portrait);
        ecrivain.setTitle("Schéma — simulateur embarqué");
        QPainter peintre(&ecrivain);
        if (!peintre.isActive()) {
            avertir("Export", "Impossible d'écrire " + chemin);
            return false;
        }
        scene_->render(&peintre, QRectF(), zone, Qt::KeepAspectRatio);
    } else {
        const double echelle =
            std::min(4.0, 2000.0 / std::max(zone.width(), zone.height()));
        QImage image(static_cast<int>(zone.width() * echelle),
                     static_cast<int>(zone.height() * echelle),
                     QImage::Format_ARGB32);
        image.fill(Qt::white);
        QPainter peintre(&image);
        peintre.setRenderHint(QPainter::Antialiasing, true);
        scene_->render(&peintre, QRectF(image.rect()), zone,
                       Qt::KeepAspectRatio);
        peintre.end();
        if (!image.save(chemin)) {
            avertir("Export", "Impossible d'écrire " + chemin);
            return false;
        }
    }
    ecrire("Schéma exporté : " + chemin);
    return true;
}

// ---------------------------------------------------------------------------
// Exemples
// ---------------------------------------------------------------------------
namespace {

const char* kProgrammeBouton = R"(/* Bouton sur D2, LED sur D13.
   Le bouton relie D2 à la masse ; le pull-up interne maintient D2 à 5 V
   quand il est relâché. La logique est donc inversée. */
#include <avr/io.h>

int main(void) {
    DDRD  &= ~(1 << PD2);        /* D2 en entrée   */
    PORTD |=  (1 << PD2);        /* pull-up interne */
    DDRB  |=  (1 << PB5);        /* D13 en sortie  */
    while (1) {
        if (PIND & (1 << PD2)) PORTB &= ~(1 << PB5);   /* relâché -> éteinte */
        else                   PORTB |=  (1 << PB5);   /* appuyé  -> allumée */
    }
}
)";

const char* kProgrammePotentiometre = R"(/* Potentiomètre sur A0, LED sur D13.
   La LED s'allume au-delà de la moitié de la course. Faites glisser le
   curseur du potentiomètre pendant la simulation : la conversion est faite
   par le vrai convertisseur de l'ATmega328P. */
#include <avr/io.h>

static uint16_t lire_adc(uint8_t canal) {
    ADMUX  = (1 << REFS0) | (canal & 0x0F);
    ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
    ADCSRA |= (1 << ADSC);
    while (ADCSRA & (1 << ADSC)) { }
    return ADC;
}

int main(void) {
    DDRB |= (1 << PB5);
    while (1) {
        if (lire_adc(0) > 512) PORTB |=  (1 << PB5);
        else                   PORTB &= ~(1 << PB5);
    }
}
)";

const char* kProgrammeTransistor = R"(/* Commande d'un moteur par transistor, sur D9.
   Une sortie de microcontrôleur ne fournit que quelques dizaines de
   milliampères : le transistor sert d'interrupteur commandé. Observez le
   courant réellement calculé dans le moteur. */
#include <avr/io.h>
#include <util/delay.h>

int main(void) {
    DDRB |= (1 << PB1);          /* D9 en sortie */
    while (1) {
        PORTB |= (1 << PB1);
        _delay_ms(800);
        PORTB &= ~(1 << PB1);
        _delay_ms(800);
    }
}
)";

const char* kProgrammePwm = R"(/* PWM matérielle sur D9, à environ 490 Hz.
   Le rapport cyclique monte puis redescend : la LED respire. Ouvrez
   l'oscilloscope et réglez la base de temps sur 5 ms pour voir le créneau,
   puis sur 2 s pour voir l'enveloppe. */
#include <avr/io.h>
#include <util/delay.h>

int main(void) {
    DDRB |= (1 << PB1);              /* D9 = OC1A, en sortie */
    /* PWM rapide 8 bits, sortie non inversée, horloge divisee par 64 */
    TCCR1A = (1 << COM1A1) | (1 << WGM10);
    TCCR1B = (1 << WGM12) | (1 << CS11) | (1 << CS10);

    while (1) {
        for (int rapport = 0; rapport < 255; rapport += 5) {
            OCR1A = rapport;
            _delay_ms(15);
        }
        for (int rapport = 255; rapport > 0; rapport -= 5) {
            OCR1A = rapport;
            _delay_ms(15);
        }
    }
}
)";

// Deux programmes distincts : c'est le propre du montage à deux cartes.
const char* kProgrammeEmetteur = R"(/* Carte U1 — émettrice.
   Elle fait clignoter sa propre LED sur D13 et recopie le même signal sur
   D7, qui part vers la seconde carte. */
#include <avr/io.h>
#include <util/delay.h>

int main(void) {
    DDRB |= (1 << PB5);          /* D13 : LED locale */
    DDRD |= (1 << PD7);          /* D7  : vers la carte U2 */
    while (1) {
        PORTB |=  (1 << PB5);
        PORTD |=  (1 << PD7);
        _delay_ms(300);
        PORTB &= ~(1 << PB5);
        PORTD &= ~(1 << PD7);
        _delay_ms(300);
    }
}
)";

const char* kProgrammeRecepteur = R"(/* Carte U2 — réceptrice.
   Elle lit sur D2 le signal envoyé par U1 et le recopie sur sa LED. Les deux
   LED doivent clignoter ensemble : c'est la preuve que les deux cartes
   exécutent bien deux programmes différents, dans le même circuit. */
#include <avr/io.h>

int main(void) {
    DDRD &= ~(1 << PD2);         /* D2 en entrée, sans pull-up */
    DDRB |=  (1 << PB5);         /* D13 : LED locale */
    while (1) {
        if (PIND & (1 << PD2)) PORTB |=  (1 << PB5);
        else                   PORTB &= ~(1 << PB5);
    }
}
)";

const char* kProgrammeServo = R"(/* Balayage d'un servomoteur sur D9.
   Le servo attend une impulsion toutes les 20 ms : 1 ms pour 0°, 2 ms pour
   180°. On la fabrique à la main, sans bibliothèque — c'est exactement ce
   que fait Servo.h, et le voir écrit une fois vaut mieux que l'ignorer. */
unsigned long dernier_top = 0, dernier_pas = 0;
int angle = 0, sens = 1;

void setup() {
    pinMode(9, OUTPUT);
    Serial.begin(9600);
}

void loop() {
    const unsigned long maintenant = millis();

    /* la trame de 20 ms */
    if (maintenant - dernier_top >= 20) {
        dernier_top = maintenant;
        digitalWrite(9, HIGH);
        delayMicroseconds(1000 + (unsigned int)(angle * 1000L / 180));
        digitalWrite(9, LOW);
    }

    /* balayage aller-retour */
    if (maintenant - dernier_pas >= 40) {
        dernier_pas = maintenant;
        angle += sens * 5;
        if (angle >= 180) { angle = 180; sens = -1; }
        if (angle <= 0)   { angle = 0;   sens =  1; }
        Serial.print("angle ");
        Serial.println((long)angle);
    }
}
)";

const char* kProgrammeMoteur = R"(/* Moteur commandé en PWM, vitesse réglée par le potentiomètre sur A0.
   Le transistor encaisse le courant, la diode de roue libre encaisse la
   surtension à la coupure — c'est l'inductance de l'induit qui la produit. */
void setup() {
    pinMode(9, OUTPUT);
    Serial.begin(9600);
}

void loop() {
    const int consigne = analogRead(A0) / 4;      /* 0 à 255 */
    analogWrite(9, consigne);
    delay(200);
    Serial.print("consigne ");
    Serial.println((long)consigne);
}
)";

}  // namespace

void FenetrePrincipale::charger_exemple(Exemple exemple) {
    scene_->tout_effacer();
    chemin_projet_.clear();

    if (exemple == Exemple::DeuxCartes) {
        charger_exemple_deux_cartes();
        return;
    }
    if (exemple == Exemple::FiltreRC) {
        charger_exemple_filtre();
        return;
    }
    programmes_.clear();
    carte_courante_.clear();
    ItemComposant* carte = scene_->ajouter_composant("arduino_uno", QPointF(-320, 0));
    if (!carte) return;
    QString programme;
    auto borne_nommee = [carte](const QString& nom) {
        for (int k = 0; k < carte->nb_bornes(); ++k)
            if (carte->nom_borne(k) == nom) return k;
        return 0;
    };

    switch (exemple) {
        case Exemple::Clignotant: {
            ItemComposant* led = scene_->ajouter_composant("led", QPointF(60, -130));
            ItemComposant* r = scene_->ajouter_composant("resistance", QPointF(190, -130));
            ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(300, -40));
            if (!led || !r || !masse) return;
            r->valeurs["ohms"] = 220;
            scene_->addItem(new ItemFil(carte, borne_nommee("D13"), led, 0));
            scene_->addItem(new ItemFil(led, 1, r, 0));
            scene_->addItem(new ItemFil(r, 1, masse, 0));
            programme = QString::fromUtf8(kSourceExemple);
            ecrire("Exemple : clignotant sur D13 (LED rouge + 220 Ω).");
            break;
        }
        case Exemple::BoutonLed: {
            ItemComposant* led = scene_->ajouter_composant("led", QPointF(60, -130));
            ItemComposant* r = scene_->ajouter_composant("resistance", QPointF(190, -130));
            ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(300, -40));
            ItemComposant* bouton = scene_->ajouter_composant("bouton", QPointF(-140, 190));
            ItemComposant* masse2 = scene_->ajouter_composant("masse", QPointF(-40, 250));
            if (!led || !r || !masse || !bouton || !masse2) return;
            r->valeurs["ohms"] = 220;
            scene_->addItem(new ItemFil(carte, borne_nommee("D13"), led, 0));
            scene_->addItem(new ItemFil(led, 1, r, 0));
            scene_->addItem(new ItemFil(r, 1, masse, 0));
            scene_->addItem(new ItemFil(carte, borne_nommee("D2"), bouton, 0));
            scene_->addItem(new ItemFil(bouton, 1, masse2, 0));
            programme = QString::fromUtf8(kProgrammeBouton);
            ecrire("Exemple : bouton sur D2 avec pull-up interne, LED sur D13.");
            ecrire("Sélectionnez BP1 et mettez « Appuyé » à 1 pendant la simulation.");
            break;
        }
        case Exemple::PotentiometreLed: {
            ItemComposant* led = scene_->ajouter_composant("led", QPointF(60, -130));
            ItemComposant* r = scene_->ajouter_composant("resistance", QPointF(190, -130));
            ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(300, -40));
            ItemComposant* pot = scene_->ajouter_composant("potentiometre", QPointF(-150, 160));
            ItemComposant* alim = scene_->ajouter_composant("alim5v", QPointF(-250, 250));
            ItemComposant* masse2 = scene_->ajouter_composant("masse", QPointF(-50, 250));
            if (!led || !r || !masse || !pot || !alim || !masse2) return;
            r->valeurs["ohms"] = 220;
            pot->valeurs["ohms"] = 10000;
            pot->valeurs["position"] = 75;
            scene_->addItem(new ItemFil(carte, borne_nommee("D13"), led, 0));
            scene_->addItem(new ItemFil(led, 1, r, 0));
            scene_->addItem(new ItemFil(r, 1, masse, 0));
            scene_->addItem(new ItemFil(pot, 0, alim, 0));       // A -> +5 V
            scene_->addItem(new ItemFil(pot, 1, carte, borne_nommee("A0")));
            scene_->addItem(new ItemFil(pot, 2, masse2, 0));     // B -> masse
            programme = QString::fromUtf8(kProgrammePotentiometre);
            ecrire("Exemple : potentiomètre sur A0, LED sur D13 au-delà de 50 %.");
            ecrire("Sélectionnez POT1 et déplacez le curseur pendant la simulation.");
            break;
        }
        case Exemple::Pwm: {
            ItemComposant* led = scene_->ajouter_composant("led", QPointF(60, -30));
            ItemComposant* r = scene_->ajouter_composant("resistance", QPointF(190, -30));
            ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(300, 60));
            if (!led || !r || !masse) return;
            r->valeurs["ohms"] = 220;
            scene_->addItem(new ItemFil(carte, borne_nommee("D9"), led, 0));
            scene_->addItem(new ItemFil(led, 1, r, 0));
            scene_->addItem(new ItemFil(r, 1, masse, 0));
            programme = QString::fromUtf8(kProgrammePwm);
            ecrire("Exemple : PWM matérielle sur D9, rapport cyclique variable.");
            ecrire("Ouvrez l'onglet Oscilloscope : base de temps 5 ms pour le "
                   "créneau, 2 s pour l'enveloppe.");
            break;
        }
        case Exemple::DeuxCartes:
        case Exemple::FiltreRC:
            return;   // traités à part : ces schémas n'ont pas une seule carte
        case Exemple::Servo: {
            ItemComposant* servo = scene_->ajouter_composant("servomoteur", QPointF(120, 0));
            ItemComposant* alim = scene_->ajouter_composant("alim5v", QPointF(20, -140));
            ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(20, 160));
            if (!servo || !alim || !masse) return;
            scene_->addItem(new ItemFil(carte, borne_nommee("D9"), servo, 2));
            scene_->addItem(new ItemFil(alim, 0, servo, 0));
            scene_->addItem(new ItemFil(servo, 1, masse, 0));
            programme = QString::fromUtf8(kProgrammeServo);
            ecrire("Exemple : servomoteur balayé de 0° à 180° sur D9.");
            ecrire("L'angle s'affiche sous le composant, décodé de la largeur "
                   "d'impulsion.");
            break;
        }
        case Exemple::MoteurPuissance: {
            ItemComposant* alim = scene_->ajouter_composant("alim5v", QPointF(430, -180));
            ItemComposant* moteur =
                scene_->ajouter_composant("moteur_cc_dynamique", QPointF(430, -60));
            ItemComposant* diode = scene_->ajouter_composant("diode", QPointF(580, -60));
            ItemComposant* rb = scene_->ajouter_composant("resistance", QPointF(250, 60));
            ItemComposant* q = scene_->ajouter_composant("transistor_npn", QPointF(430, 80));
            ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(430, 200));
            ItemComposant* pot = scene_->ajouter_composant("potentiometre", QPointF(-120, 220));
            ItemComposant* alim2 = scene_->ajouter_composant("alim5v", QPointF(-220, 140));
            ItemComposant* masse2 = scene_->ajouter_composant("masse", QPointF(-20, 320));
            if (!alim || !moteur || !diode || !rb || !q || !masse || !pot ||
                !alim2 || !masse2)
                return;
            rb->valeurs["ohms"] = 1000;
            moteur->setRotation(90);
            diode->setRotation(90);
            scene_->addItem(new ItemFil(alim, 0, moteur, 0));
            scene_->addItem(new ItemFil(moteur, 1, q, 1));
            scene_->addItem(new ItemFil(alim, 0, diode, 1));
            scene_->addItem(new ItemFil(diode, 0, q, 1));
            scene_->addItem(new ItemFil(carte, borne_nommee("D9"), rb, 0));
            scene_->addItem(new ItemFil(rb, 1, q, 0));
            scene_->addItem(new ItemFil(q, 2, masse, 0));
            scene_->addItem(new ItemFil(alim2, 0, pot, 0));
            scene_->addItem(new ItemFil(pot, 1, carte, borne_nommee("A0")));
            scene_->addItem(new ItemFil(pot, 2, masse2, 0));
            programme = QString::fromUtf8(kProgrammeMoteur);
            ecrire("Exemple : moteur en PWM, vitesse réglée par le potentiomètre.");
            ecrire("La vitesse atteinte s'affiche sous le moteur. Observez le "
                   "courant à l'oscilloscope : l'inductance d'induit l'empêche "
                   "de s'établir d'un coup.");
            break;
        }
        case Exemple::Transistor: {
            ItemComposant* rb = scene_->ajouter_composant("resistance", QPointF(-140, -50));
            ItemComposant* q = scene_->ajouter_composant("transistor_npn", QPointF(20, -50));
            ItemComposant* moteur = scene_->ajouter_composant("moteur_cc", QPointF(60, -220));
            ItemComposant* alim = scene_->ajouter_composant("alim5v", QPointF(-60, -290));
            ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(120, 60));
            if (!rb || !q || !moteur || !alim || !masse) return;
            rb->valeurs["ohms"] = 1000;
            scene_->addItem(new ItemFil(carte, borne_nommee("D9"), rb, 0));
            scene_->addItem(new ItemFil(rb, 1, q, 0));           // base
            scene_->addItem(new ItemFil(q, 1, moteur, 1));       // collecteur
            scene_->addItem(new ItemFil(moteur, 0, alim, 0));    // moteur -> +5 V
            scene_->addItem(new ItemFil(q, 2, masse, 0));        // émetteur
            programme = QString::fromUtf8(kProgrammeTransistor);
            ecrire("Exemple : moteur commandé par transistor NPN sur D9.");
            break;
        }
    }

    // L'ordre compte. `circuit_modifie` recense la carte et remplit le
    // sélecteur ; le programme doit être rangé dans `programmes_` avant qu'on
    // demande son affichage, sinon c'est le programme par défaut qui
    // s'imposerait — y compris plus tard, quand le signal différé de la scène
    // relancera la synchronisation.
    circuit_modifie();
    programmes_[carte->reference()] = programme;
    carte_courante_.clear();
    changer_carte(carte->reference());

    vue_->ajuster();
    ecrire("Compilez le programme (F5) puis lancez la simulation.");
}

// Deux cartes : le schéma se construit à part, parce qu'il ne repose pas sur
// la carte unique posée par charger_exemple().
void FenetrePrincipale::charger_exemple_deux_cartes() {
    scene_->tout_effacer();
    chemin_projet_.clear();
    programmes_.clear();
    carte_courante_.clear();

    ItemComposant* u1 = scene_->ajouter_composant("arduino_uno", QPointF(-520, 0));
    ItemComposant* u2 = scene_->ajouter_composant("arduino_uno", QPointF(520, 0));
    if (!u1 || !u2) return;
    auto borne_de = [](ItemComposant* carte, const QString& nom) {
        for (int k = 0; k < carte->nb_bornes(); ++k)
            if (carte->nom_borne(k) == nom) return k;
        return 0;
    };

    // Une LED par carte, plus le fil de liaison D7 -> D2.
    struct { ItemComposant* carte; double x; } cotes[] = {{u1, -300}, {u2, 300}};
    for (const auto& cote : cotes) {
        ItemComposant* led = scene_->ajouter_composant("led", QPointF(cote.x, -230));
        ItemComposant* r =
            scene_->ajouter_composant("resistance", QPointF(cote.x, -150));
        ItemComposant* masse =
            scene_->ajouter_composant("masse", QPointF(cote.x, -60));
        if (!led || !r || !masse) return;
        r->valeurs["ohms"] = 220;
        scene_->addItem(new ItemFil(cote.carte, borne_de(cote.carte, "D13"), led, 0));
        scene_->addItem(new ItemFil(led, 1, r, 0));
        scene_->addItem(new ItemFil(r, 1, masse, 0));
    }
    scene_->addItem(new ItemFil(u1, borne_de(u1, "D7"), u2, borne_de(u2, "D2")));
    // Masse commune : sans elle, deux cartes n'ont aucune référence partagée
    // et le signal échangé n'aurait pas de sens.
    ItemComposant* masse_commune =
        scene_->ajouter_composant("masse", QPointF(0, 300));
    if (masse_commune) {
        scene_->addItem(new ItemFil(u1, borne_de(u1, "GND"), masse_commune, 0));
        scene_->addItem(new ItemFil(u2, borne_de(u2, "GND"), masse_commune, 0));
    }

    circuit_modifie();
    programmes_[u1->reference()] = QString::fromUtf8(kProgrammeEmetteur);
    programmes_[u2->reference()] = QString::fromUtf8(kProgrammeRecepteur);
    // Les programmes viennent d'être posés : on réaffiche celui de la carte
    // sélectionnée pour que l'éditeur montre le bon.
    const QString affichee = carte_courante_;
    carte_courante_.clear();
    changer_carte(affichee.isEmpty() ? u1->reference() : affichee);

    vue_->ajuster();
    ecrire("Exemple : deux cartes Arduino, deux programmes différents.");
    ecrire("U1 clignote et envoie son signal sur D7 ; U2 le lit sur D2 et le "
           "recopie sur sa LED.");
    ecrire("Compilez chaque carte séparément (sélecteur au-dessus de "
           "l'éditeur), puis lancez.");
}

// Filtre RC : le montage de référence pour les analyses. Sa coupure vaut
// 1/(2 pi R C), soit 1591 Hz ici — une valeur qu'on peut confronter au
// diagramme de Bode que trace le simulateur.
void FenetrePrincipale::charger_exemple_filtre() {
    scene_->tout_effacer();
    chemin_projet_.clear();
    programmes_.clear();
    carte_courante_.clear();

    ItemComposant* gbf = scene_->ajouter_composant("generateur_signal",
                                                   QPointF(-260, 0));
    ItemComposant* r = scene_->ajouter_composant("resistance", QPointF(-80, -120));
    ItemComposant* c = scene_->ajouter_composant("condensateur", QPointF(60, 0));
    ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(-100, 160));
    if (!gbf || !r || !c || !masse) return;
    r->valeurs["ohms"] = 1000;
    c->valeurs["farads"] = 1e-7;
    gbf->valeurs["amplitude"] = 1;
    gbf->valeurs["frequence"] = 1000;
    gbf->textes["forme"] = "sinus";
    c->setRotation(90);

    // Deux instruments posés dans le circuit, comme sur une paillasse :
    // l'ampèremètre en série, le voltmètre en parallèle sur le condensateur.
    // Ils sont modélisés (0,01 Ω et 10 MΩ), donc ils chargent le montage —
    // très peu, mais réellement.
    ItemComposant* am = scene_->ajouter_composant("amperemetre", QPointF(-150, -120));
    ItemComposant* vm = scene_->ajouter_composant("voltmetre", QPointF(200, 0));
    if (!am || !vm) return;
    // Montage alternatif : les appareils sont mis en position alternatif,
    // sinon ils afficheraient la moyenne d'une sinusoïde — c'est-à-dire zéro.
    am->textes["mode"] = "alternatif";
    vm->textes["mode"] = "alternatif";

    scene_->addItem(new ItemFil(gbf, 0, am, 0));     // + -> ampèremètre
    scene_->addItem(new ItemFil(am, 1, r, 0));       // ampèremètre -> R
    scene_->addItem(new ItemFil(r, 1, c, 0));        // R -> C
    scene_->addItem(new ItemFil(c, 1, masse, 0));    // C -> masse
    scene_->addItem(new ItemFil(gbf, 1, masse, 0));  // - -> masse
    scene_->addItem(new ItemFil(c, 0, vm, 0));       // voltmètre sur C
    scene_->addItem(new ItemFil(vm, 1, masse, 0));

    circuit_modifie();
    vue_->ajuster();
    ecrire("Exemple : filtre passe-bas RC (1 kΩ, 100 nF), attaqué par un "
           "générateur de signaux.");
    ecrire("Onglet « Analyses » : la réponse en fréquence doit couper à "
           "1/(2·pi·R·C) = 1591 Hz, avec −20 dB par décade et −45° à la "
           "coupure.");
    ecrire("Le balayage continu et le spectre s'y lancent de la même façon.");
    ecrire("AM1 et VM1 affichent leur mesure sous leur symbole dès que la "
           "simulation tourne.");
}

// ---------------------------------------------------------------------------
QString FenetrePrincipale::diagnostic() {
    circuit_modifie();
    QString rapport;
    rapport += QString("=== Carte courante : %1 ===\n")
                   .arg(carte_courante_.isEmpty() ? "(aucune)" : carte_courante_);
    rapport += "programme affiché : " +
               editeur_source_->toPlainText().split('\n').value(0) + "\n";
    for (const auto& paire : programmes_)
        rapport += QString("  %1 -> %2\n")
                       .arg(paire.first, paire.second.split('\n').value(0));
    rapport += "=== Composants du schéma ===\n";
    for (ItemComposant* item : scene_->composants()) {
        rapport += QString("  %1 (%2)")
                       .arg(item->reference(),
                            QString::fromStdString(item->modele()->type));
        for (int k = 0; k < item->nb_bornes(); ++k)
            rapport += " " + item->nom_borne(k);
        rapport += "\n";
    }
    rapport += QString("=== Netlist (%1 instances) ===\n")
                   .arg(moteur_->netlist().instances().size());
    for (const coeur::Instance& instance : moteur_->netlist().instances()) {
        rapport += QString("  %1 %2 :")
                       .arg(QString::fromStdString(instance.reference),
                            QString::fromStdString(instance.type));
        for (const coeur::Borne& borne : instance.bornes)
            rapport += QString(" %1=%2")
                           .arg(QString::fromStdString(borne.nom),
                                QString::fromStdString(borne.noeud));
        rapport += "\n";
    }
    rapport += QString("=== Broches de carte (%1 carte(s)) ===\n")
                   .arg(moteur_->cartes().size());
    for (const LiaisonBroche& liaison : moteur_->broches()) {
        // Chaque carte a ses propres registres : interroger la bonne est
        // toute la différence entre un diagnostic utile et un mensonge.
        const QString reference = QString::fromStdString(liaison.carte);
        const coeur::AvrEngine& mcu = moteur_->mcu(reference);
        rapport += QString("  %1.%2 (n°%3) -> nœud %4   sortie=%5 niveau=%6\n")
                       .arg(reference)
                       .arg(QString::fromStdString(liaison.nom))
                       .arg(liaison.numero)
                       .arg(QString::fromStdString(liaison.noeud))
                       .arg(mcu.direction_sortie(liaison.numero))
                       .arg(mcu.niveau_port(liaison.numero));
    }
    rapport += "=== Source SPICE ===\n" + moteur_->source_spice();
    rapport += "\n=== Tensions relevées ===\n";
    for (const auto& mesure : moteur_->analogique().toutes_tensions())
        rapport += QString("  %1 = %2 V\n")
                       .arg(QString::fromStdString(mesure.first))
                       .arg(mesure.second, 0, 'f', 4);
    rapport += "=== Courants relevés ===\n";
    for (const auto& mesure : moteur_->analogique().tous_courants())
        rapport += QString("  %1 = %2 mA\n")
                       .arg(QString::fromStdString(mesure.first))
                       .arg(mesure.second * 1000, 0, 'f', 3);
    return rapport;
}
