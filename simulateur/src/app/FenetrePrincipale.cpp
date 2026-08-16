#include "app/Apparence.h"
#include "app/FenetrePrincipale.h"

#include "core/engines/Chaines.h"
#include "core/engines/Microcontroleur.h"
#include "core/engines/ProgrammesExemples.h"

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
#include <QJsonParseError>
#include <QJsonObject>
#include <QLabel>
#include <QLineEdit>
#include <QTextEdit>
#include <QTextDocument>
#include <QMenu>
#include <QCursor>
#include <algorithm>
#include <functional>
#include <QPlainTextDocumentLayout>
#include <QHeaderView>
#include <QMouseEvent>
#include <QTextBlock>
#include <QRegularExpression>
#include <QPushButton>
#include <QComboBox>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QMenu>
#include <QMenuBar>
#include <QInputDialog>
#include <QTabBar>
#include <QToolButton>
#include <QMessageBox>
#include <QMimeData>
#include <QPlainTextEdit>
#include <QHeaderView>
#include <QMouseEvent>
#include <QTextBlock>
#include <QRegularExpression>
#include <QPushButton>
#include <QSlider>
#include <QSpinBox>
#include <QStackedWidget>
#include <QStandardPaths>
#include <QStatusBar>
#include <QCloseEvent>
#include <QCoreApplication>
#include <QDate>
#include <QFileInfo>
#include <QDateTime>
#include <QElapsedTimer>
#include <QSettings>
#include <QTabWidget>
#include <QTimer>
#include <QToolBar>
#include <QVBoxLayout>

#include <cmath>
#include <limits>
#include <map>

#include <QImage>
#include <QPageSize>
#include <QPdfWriter>

#include "app/MoteurSimulation.h"
#include "app/Oscilloscope.h"
#include "app/panels/FenetreInstrument.h"
#include "app/panels/PanneauAnalyses.h"
#include "app/panels/PanneauPcb.h"
#include "core/analysis/Analyses.h"
#include "core/analysis/Campagne.h"
#include "core/export/Documents.h"
#include "app/schematic/ItemComposant.h"
#include "app/schematic/ItemFil.h"
#include "app/schematic/SceneSchema.h"
#include "app/schematic/VueSchema.h"

namespace {
// Un seul endroit pour ces clés : elles se retrouvent dans le registre de
// l'utilisateur, et une faute de frappe y perdrait sa disposition en silence.
// LA CLÉ PORTE UN NUMÉRO, ET IL COMPTE.
//
// La disposition enregistrée sur la machine de l'utilisateur ÉCRASE celle que
// le code met en place au démarrage. Tant que la clé ne change pas, une
// refonte de la disposition est donc invisible pour quiconque a déjà lancé
// l'application une fois : il continue de voir l'ancienne, et il n'a aucun
// moyen de le deviner.
//
// Le numéro se change à chaque refonte. L'ancienne disposition est alors
// simplement ignorée — c'est le prix, et il est juste : on ne peut pas
// deviner comment reporter des panneaux d'hier sur une fenêtre d'aujourd'hui.
constexpr char kCleGeometrie[] = "disposition2/geometrie";
constexpr char kCleEtat[] = "disposition2/etat";

// La portée d'enregistrement suit l'identité de l'application, au lieu de
// noms écrits en dur ici.
//
// C'est ce qui isole le banc d'essai : `tests_schema` construit de vraies
// `FenetrePrincipale`, et avec une portée fixe il aurait relu la disposition
// enregistrée par l'utilisateur sur sa machine — un banc dont le résultat
// dépend de l'état d'un poste n'est plus un banc. Il lui suffit désormais de
// se donner un autre `applicationName`.
QSettings reglages_disposition() {
    return QSettings(QCoreApplication::organizationName(),
                     QCoreApplication::applicationName());
}

// Un champ de valeur qui parle comme un électronicien.
//
// Il affichait « 10000,000000000 » pour une résistance de 10 kΩ : neuf
// décimales en dur, choisies parce qu'un condensateur de 220 nF vaut
// 0,000000220 F. Une seule précision pour toutes les grandeurs ne peut pas
// convenir aux deux — il y a douze décades entre un picofarad et un
// mégohm.
//
// La sortie réutilise `format_ingenieur`, déjà employé par la nomenclature
// et par l'étiquette sous le symbole : le panneau dit désormais « 10 kΩ »
// comme le schéma, au lieu de le contredire.
//
// L'entrée accepte les préfixes : on tape « 220n », « 4k7 » s'écrit « 4.7k »,
// et l'unité peut être omise. C'est ce que fait tout logiciel de CAO
// électronique, et ce que fait la main d'un électronicien sur un cahier.
class ChampValeur : public QDoubleSpinBox {
public:
    explicit ChampValeur(std::string unite, QWidget* parent = nullptr)
        : QDoubleSpinBox(parent), unite_(std::move(unite)) {
        // La précision INTERNE, pas celle de l'affichage : un picofarad vaut
        // 1e-12, et setValue arrondirait à `decimals` sans cela.
        setDecimals(12);
    }

protected:
    QString textFromValue(double valeur) const override {
        return QString::fromStdString(coeur::format_ingenieur(valeur, unite_));
    }

    double valueFromText(const QString& texte) const override {
        const double lu = lire(texte);
        return std::isnan(lu) ? value() : lu;
    }

    QValidator::State validate(QString& texte, int&) const override {
        if (texte.trimmed().isEmpty()) return QValidator::Intermediate;
        return std::isnan(lire(texte)) ? QValidator::Intermediate
                                       : QValidator::Acceptable;
    }

    // Un pas fixe n'a pas plus de sens qu'une précision fixe : monter de 1 Ω
    // sur un mégohm ne se voit pas, monter de 1 F sur un nanofarad est absurde.
    // Le pas vaut donc un dixième de la décade courante.
    void stepBy(int pas) override {
        const double v = value();
        const double decade =
            v > 0 ? std::pow(10.0, std::floor(std::log10(v))) : 1.0;
        setValue(v + pas * decade / 10.0);
    }

private:
    double lire(const QString& texte) const {
        QString net = texte.trimmed();
        net.replace(',', '.');   // le clavier français écrit la virgule
        int fin = 0;
        while (fin < net.size()
               && (net[fin].isDigit() || net[fin] == '.' || net[fin] == '+'
                   || net[fin] == '-'))
            ++fin;

        // LA NOTATION SCIENTIFIQUE, sans quoi « 1e9 » était TRONQUÉ EN
        // SILENCE : le champ retenait 1, et `validate()` répondait
        // « acceptable ». Écrire 1e9 pour un gigaohm est pourtant la façon
        // la plus naturelle, et se tromper d'un facteur milliard sans le
        // moindre signe est le pire comportement possible pour un réglage.
        //
        // On n'avance que si un exposant suit VRAIMENT : « 220e » garde son
        // « e », qui n'est pas un préfixe d'ingénieur et laissera le facteur
        // à un plutôt que de manger un caractère.
        if (fin < net.size() && (net[fin] == 'e' || net[fin] == 'E')) {
            int k = fin + 1;
            if (k < net.size() && (net[k] == '+' || net[k] == '-')) ++k;
            const int premier_chiffre = k;
            while (k < net.size() && net[k].isDigit()) ++k;
            if (k > premier_chiffre) fin = k;
        }

        bool ok = false;
        const double base = net.left(fin).toDouble(&ok);
        if (!ok) return std::numeric_limits<double>::quiet_NaN();

        // Le premier caractère non blanc qui suit : un préfixe d'ingénieur,
        // ou le début de l'unité. « 220 nF » donne n ; « 0.25 W » donne W,
        // qui n'est pas un préfixe — le facteur reste 1.
        static const QString prefixes = "pnµumkMG";
        static const double facteurs[] = {1e-12, 1e-9, 1e-6, 1e-6,
                                          1e-3,  1e3,  1e6,  1e9};
        for (int k = fin; k < net.size(); ++k) {
            if (net[k].isSpace()) continue;
            const int rang = prefixes.indexOf(net[k]);
            if (rang >= 0) return base * facteurs[rang];
            break;
        }
        return base;
    }

    std::string unite_;
};
}  // namespace

#include "core/Device.h"

namespace {

// Repli : le programme proposé quand le modèle de carte n'en porte pas.
// Les cartes du catalogue portent le leur — voir catalogue/cartes.cpp.

}  // namespace

// ---------------------------------------------------------------------------
PaletteComposants::PaletteComposants(QWidget* parent) : QTreeWidget(parent) {
    setHeaderHidden(true);
    // DE LA PLACE POUR LES NOMS, prise sur ce qui n'en dit aucun.
    //
    // Le retrait par défaut de Qt vaut vingt pixels par niveau, et il n'y a
    // que deux niveaux ici : une catégorie, des composants. Ces pixels-là
    // étaient perdus pour le nom, qui s'affichait « Capteur analogiq… ». Un
    // catalogue dont les entrées sont coupées ne se parcourt pas — on ne
    // choisit pas ce qu'on ne peut pas lire.
    setIndentation(12);
    setIconSize(QSize(16, 16));
    setUniformRowHeights(true);
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

    // Deux pages, comme partout ailleurs : la saisie du schéma d'un côté, le
    // circuit imprimé de l'autre. Chez KiCad ce sont deux applications
    // (Eeschema et Pcbnew), chez Proteus deux fenêtres (ISIS et ARES) ; la
    // frontière est la même, et on ne la franchit qu'en demandant le
    // transfert du schéma vers la carte.
    pcb_ = new PanneauPcb;
    pages_ = new QStackedWidget(this);
    pages_->addWidget(vue_);
    pages_->addWidget(pcb_);
    setCentralWidget(pages_);

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
    // Le nom du nœud survolé, en barre d'état. C'est ce que fait LTspice, et
    // la seule chose qu'il fasse : il n'affiche PAS les noms en permanence —
    // un schéma constellé d'étiquettes internes est moins lisible, pas plus.
    // La surbrillance montre l'étendue du nœud, l'étiquette le nomme.
    connect(scene_, &SceneSchema::survol_noeud, this,
            [this](const QString& nom, const QString& description) {
                if (nom.isEmpty()) {
                    etiquette_noeud_->clear();
                    return;
                }
                etiquette_noeud_->setText(
                    QString("Nœud %1 — %2").arg(nom, description));
            });
    connect(vue_, &VueSchema::composant_depose, this,
            [this](const QString& type, const QPointF& position) {
                scene_->memoriser();
                scene_->ajouter_composant(type, position);
                circuit_modifie();
            });

    connect(moteur_, &MoteurSimulation::journal, this,
            &FenetrePrincipale::ecrire);
    connect(moteur_, &MoteurSimulation::etat_change, this,
            [this](MoteurSimulation::Etat) { refleter_etat(); });
    connect(moteur_, &MoteurSimulation::controle_effectue, this,
            &FenetrePrincipale::refleter_controle);
    // Le contrôle repose TOUS les marqueurs, y compris quand il ne trouve
    // rien : une liste vide efface les triangles précédents. C'est ce qui
    // fait qu'un fil enfin tiré fait disparaître son marqueur, au lieu de
    // laisser l'élève douter de ce qu'il vient de corriger.
    connect(moteur_, &MoteurSimulation::anomalies_relevees, this,
            [this](const std::vector<coeur::Anomalie>& anomalies) {
                scene_->poser_anomalies(anomalies);
                remplir_controle(anomalies);
            });
    connect(moteur_, &MoteurSimulation::composant_grille, this,
            [this](const QString& reference) {
                scene_->marquer_grille(reference);
            });
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
                // Chaque scope posé sur le schéma reçoit la même trame.
                for (auto& paire : scopes_)
                    paire.second->ajouter_trame(formes, instant);
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

    // La disposition de référence, relevée ICI : après que tout est construit,
    // avant toute restauration. C'est la seule façon que « Réinitialiser »
    // reste d'accord avec le constructeur — une disposition écrite en dur
    // se désynchroniserait au premier panneau ajouté.
    disposition_par_defaut_ = saveState();
    restaurer_disposition();

    // LA DATE DE CONSTRUCTION, ANNONCÉE À CHAQUE DÉMARRAGE.
    //
    // Deux heures perdues en une journée sur des exécutables PÉRIMÉS : une
    // fois parce que l'édition de liens avait échoué et que l'ancien binaire
    // était resté en place, une fois parce que le dossier de livraison n'est
    // pas reconstruit par la construction ordinaire. Dans les deux cas on
    // essayait du code vieux de plusieurs jours en croyant tester le neuf, et
    // RIEN à l'écran ne le disait.
    //
    // Une ligne dans le journal règle les deux : si la date n'est pas celle
    // du jour, on regarde le mauvais exécutable, et on le voit en une seconde
    // au lieu d'une heure.
    //
    // C'est la date de l'EXÉCUTABLE, pas `__DATE__`. La macro est figée à la
    // compilation de CE fichier-ci : modifier la scène et relier ne la change
    // pas, et elle annoncerait fièrement une date périmée — exactement le
    // défaut qu'elle prétend supprimer. La date du fichier, elle, est celle
    // de l'édition de liens, donc du binaire qu'on est vraiment en train de
    // lancer.
    const QDateTime construit =
        QFileInfo(QCoreApplication::applicationFilePath()).lastModified();
    ecrire(QString("Simulateur embarqué %1 — exécutable du %2.")
               .arg(QApplication::applicationVersion(),
                    construit.toString("dd/MM/yyyy à HH:mm")));
}

FenetrePrincipale::~FenetrePrincipale() = default;

// ---------------------------------------------------------------------------
// Dessine le symbole d'un modèle dans une petite image.
//
// La même liste de traits que celle qu'`ItemComposant::paint` interprète, à
// une échelle qui tient dans la palette. Mise en cache par type : la palette
// se reconstruit à chaque filtrage de la recherche, et redessiner cinquante
// symboles à chaque frappe serait du travail pur.
QIcon FenetrePrincipale::icone_du_modele(const coeur::Modele* modele) {
    if (!modele) return {};
    const QString cle = QString::fromStdString(modele->type);
    auto connue = icones_.find(cle);
    if (connue != icones_.end()) return connue->second;

    constexpr int kCote = 22;
    QPixmap image(kCote, kCote);
    image.fill(Qt::transparent);
    {
        QPainter peintre(&image);
        peintre.setRenderHint(QPainter::Antialiasing, true);

        // Cadrer sur ce que le symbole occupe vraiment : un symbole étroit
        // doit remplir l'icône autant qu'un symbole large, sinon la palette
        // ressemble à une suite de timbres de tailles différentes.
        QRectF etendue;
        for (const auto& trait : modele->symbole)
            for (const auto& point : trait.points) {
                const QPointF p(point.x, point.y);
                etendue = etendue.isNull() ? QRectF(p, QSizeF(0.1, 0.1))
                                           : etendue.united(QRectF(p, QSizeF(0.1, 0.1)));
            }
        if (etendue.isNull()) etendue = QRectF(-20, -20, 40, 40);
        const double marge = 2.0;
        const double echelle =
            std::min((kCote - 2 * marge) / std::max(etendue.width(), 1.0),
                     (kCote - 2 * marge) / std::max(etendue.height(), 1.0));
        peintre.translate(kCote / 2.0, kCote / 2.0);
        peintre.scale(echelle, echelle);
        peintre.translate(-etendue.center());

        QPen crayon(QColor(30, 30, 40), 1.6 / echelle);
        crayon.setJoinStyle(Qt::RoundJoin);
        crayon.setCapStyle(Qt::RoundCap);
        peintre.setPen(crayon);
        QColor corps(QString::fromStdString(modele->couleur_corps));
        if (!corps.isValid()) corps = QColor(210, 210, 210);
        for (const auto& trait : modele->symbole) {
            peintre.setBrush(trait.rempli ? QBrush(corps) : Qt::NoBrush);
            QPolygonF points;
            for (const auto& point : trait.points)
                points << QPointF(point.x, point.y);
            switch (trait.genre) {
                case coeur::TraitSymbole::Genre::Ligne:
                    if (points.size() >= 2) peintre.drawPolyline(points);
                    break;
                case coeur::TraitSymbole::Genre::Rect:
                    if (points.size() >= 2)
                        peintre.drawRect(QRectF(points[0], points[1]));
                    break;
                case coeur::TraitSymbole::Genre::Cercle:
                    if (points.size() >= 1)
                        peintre.drawEllipse(points[0], trait.mesure, trait.mesure);
                    break;
                case coeur::TraitSymbole::Genre::Polygone:
                    if (points.size() >= 3) peintre.drawPolygon(points);
                    break;
                default:
                    break;   // le texte ne se lit pas à vingt-deux pixels
            }
        }
    }
    const QIcon icone(image);
    icones_[cle] = icone;
    return icone;
}

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
        // Le symbole plutôt qu'un mot. Un élève de première année reconnaît le
        // zigzag d'une résistance bien avant de savoir écrire
        // « potentiomètre », et il cherche un dessin, pas un intitulé.
        // Cinquante-trois lignes de texte deviennent cinquante-trois symboles
        // sans créer un seul fichier graphique : le tracé est déjà là, dans
        // `modele->symbole`.
        feuille->setIcon(0, icone_du_modele(modele));
        feuille->setToolTip(
            0, QString("%1 — glissez-le sur le schéma, ou double-cliquez")
                   .arg(QString::fromStdString(modele->libelle)));
    }
    palette_->expandAll();

    connect(palette_, &QTreeWidget::itemDoubleClicked, this,
            [this](QTreeWidgetItem* item, int) {
                const QString type = item->data(0, Qt::UserRole).toString();
                if (type.isEmpty()) return;
                scene_->memoriser();
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
    recherche_palette_ = recherche;
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

    // Assez large pour lire un nom de composant : en dessous, la palette
    // n'affiche que « Té », « Th », « Ali » — autant dire rien.
    contenu->setMinimumWidth(150);

    auto* dock = new QDockWidget("Composants", this);
    dock->setWidget(contenu);
    dock->setObjectName("dock_palette");
    dock_palette_ = dock;
    addDockWidget(Qt::LeftDockWidgetArea, dock);
    docks_schema_.push_back(dock);
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
    docks_schema_.push_back(dock_proprietes);
    dock_proprietes_ = dock_proprietes;
    // UN PANNEAU VIDE NE GARDE PAS SA PLACE.
    //
    // Il occupait 260 pixels en permanence pour afficher « Sélectionnez un
    // composant » — un quart de la largeur utile, pris à la seule chose que
    // l'utilisateur regarde. Il n'apparaît plus qu'avec une sélection, et
    // s'efface dès qu'il n'a plus rien à montrer.
    dock_proprietes->hide();

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

    // Les fichiers du programme. La barre reste cachée tant qu'il n'y en a
    // qu'un — le cas courant —, et apparaît dès qu'on en ajoute.
    {
        auto* ligne = new QHBoxLayout;
        ligne->setContentsMargins(0, 0, 0, 0);
        onglets_fichiers_ = new QTabBar;
        onglets_fichiers_->setExpanding(false);
        onglets_fichiers_->setDrawBase(false);
        onglets_fichiers_->setVisible(false);
        connect(onglets_fichiers_, &QTabBar::currentChanged, this,
                [this](int rang) { afficher_fichier(rang); });
        ligne->addWidget(onglets_fichiers_);
        auto* ajouter = new QToolButton;
        ajouter->setText("+");
        ajouter->setToolTip(
            "Ajouter un fichier au programme de cette carte.\n"
            "« .h » pour des déclarations, « .cpp » pour du code compilé à "
            "part,\n« .ino » pour un onglet de croquis fondu avec le "
            "principal.");
        connect(ajouter, &QToolButton::clicked, this,
                &FenetrePrincipale::ajouter_fichier);
        ligne->addWidget(ajouter);
        auto* retirer = new QToolButton;
        retirer->setText("−");
        retirer->setToolTip("Retirer le fichier affiché (jamais le principal).");
        connect(retirer, &QToolButton::clicked, this,
                [this] { retirer_fichier(fichier_courant_); });
        ligne->addWidget(retirer);
        ligne->addStretch(1);
        disposition->addLayout(ligne);
    }

    editeur_source_ = new QPlainTextEdit(coeur::kSourceExemple);
    QFont fonte("monospace");
    fonte.setStyleHint(QFont::TypeWriter);
    editeur_source_->setFont(fonte);
    // Quatre lignes de code au minimum : au-delà, c'est la hauteur du panneau
    // du bas qui décide, et c'est l'utilisateur qui décide de celle-là.
    editeur_source_->setMinimumHeight(70);
    disposition->addWidget(editeur_source_);
    auto* bouton = new QPushButton("Compiler et charger");
    // LE bouton de cette page : il porte l'accent, et il est le seul.
    //
    // Il s'appelait « Compiler avec avr-gcc et charger » — le nom de l'outil
    // dans le bouton. L'utilisateur n'a pas à savoir qu'il existe un programme
    // nommé avr-gcc pour appuyer dessus ; et s'il l'apprend, c'est par le
    // journal, quand quelque chose échoue.
    bouton->setProperty("principal", true);
    bouton->setShortcut(QKeySequence(Qt::Key_F5));
    bouton->setToolTip("Compile le programme et le charge dans la carte (F5).");
    connect(bouton, &QPushButton::clicked, this,
            &FenetrePrincipale::compiler_source);
    // À DROITE, ET À SA TAILLE.
    //
    // Il barrait toute la largeur de la fenêtre — mille cinq cents pixels de
    // bleu pour une commande qui n'en demande cent cinquante. Un bouton
    // pleine largeur crie sans rien dire de plus, et il écrase le seul objet
    // qui compte sur cette page : le code.
    auto* pied = new QHBoxLayout;
    pied->addStretch(1);
    pied->addWidget(bouton);
    disposition->addLayout(pied);
    // PAS D'ONGLET : une fenêtre à part.
    //
    // Le programme n'appartient pas au bandeau des journaux. Un journal se
    // lit, un moniteur série se regarde ; un programme s'ÉCRIT, et c'est la
    // moitié du travail dans un projet embarqué. Il partageait deux cents
    // pixels de hauteur avec des sorties qu'on ne fait que consulter, et il
    // fallait choisir entre voir son code et voir ce que le compilateur en
    // dit.
    //
    // Il s'ouvre d'un double-clic sur la carte — le geste de Proteus et de
    // Wokwi — ou par son menu contextuel. Fermer la fenêtre ne perd rien :
    // le texte vit dans l'éditeur, pas dans la fenêtre.
    fenetre_programme_ = page_source;
    page_source->setParent(nullptr);
    page_source->setWindowFlags(Qt::Window);
    page_source->setWindowTitle("Programme — simulateur");
    page_source->resize(760, 620);

    console_ = new QPlainTextEdit;
    console_->setReadOnly(true);
    console_->setFont(fonte);
    console_->setMinimumHeight(70);
    // Double-cliquer une ligne d'erreur ouvre le bon onglet à la bonne ligne.
    // Le filtre est posé sur la ZONE D'AFFICHAGE, pas sur le widget : c'est
    // elle qui reçoit les événements de souris d'une vue défilante.
    console_->viewport()->installEventFilter(this);
    console_->setToolTip(
        "Double-cliquez une ligne d'erreur de compilation pour aller à la "
        "ligne fautive dans le programme.");
    onglets->addTab(console_, "Journal");

    // Le panneau « Contrôle » — à CÔTÉ du journal, jamais modal.
    //
    // L'ERC ouvrait une boîte qui recouvrait le schéma qu'elle décrivait :
    // impossible de lire l'anomalie et de regarder le montage en même temps,
    // alors que c'est le seul geste utile. Ici la liste reste ouverte pendant
    // qu'on corrige, et chaque ligne mène à son coupable.
    panneau_controle_ = new QTreeWidget;
    panneau_controle_->setColumnCount(3);
    panneau_controle_->setHeaderLabels({"", "Où", "Quoi faire"});
    panneau_controle_->setRootIsDecorated(false);
    panneau_controle_->setAlternatingRowColors(true);
    panneau_controle_->setMinimumHeight(70);
    panneau_controle_->setToolTip(
        "Cliquez une ligne pour sélectionner et cadrer ce qu'elle désigne sur "
        "le schéma.");
    panneau_controle_->header()->setStretchLastSection(true);
    connect(panneau_controle_, &QTreeWidget::itemSelectionChanged, this, [this] {
        const QList<QTreeWidgetItem*> choisis =
            panneau_controle_->selectedItems();
        if (choisis.isEmpty()) return;
        atteindre_anomalie(choisis.front()->data(0, Qt::UserRole).toString());
    });
    onglets->addTab(panneau_controle_, "Contrôle");

    // Le moniteur série reçoit ET émet.
    //
    // Il ne savait que recevoir, alors que le moteur sait recevoir depuis
    // toujours (`Microcontroleur::envoyer_octet_serie`). Sans champ de
    // saisie, `Serial.read()`, `Serial.available()` et `parseInt()` sont
    // inenseignables dans ce logiciel — tout un pan du programme de première
    // année tombait, faute d'un QLineEdit.
    auto* bloc_serie = new QWidget;
    auto* pile_serie = new QVBoxLayout(bloc_serie);
    pile_serie->setContentsMargins(0, 0, 0, 0);
    pile_serie->setSpacing(3);

    moniteur_serie_ = new QPlainTextEdit;
    moniteur_serie_->setReadOnly(true);
    moniteur_serie_->setFont(fonte);
    moniteur_serie_->setMinimumHeight(70);
    pile_serie->addWidget(moniteur_serie_, 1);

    auto* ligne_serie = new QWidget;
    auto* rang_serie = new QHBoxLayout(ligne_serie);
    rang_serie->setContentsMargins(0, 0, 0, 0);
    saisie_serie_ = new QLineEdit;
    saisie_serie_->setFont(fonte);
    saisie_serie_->setPlaceholderText(
        "Texte à envoyer à la carte, puis Entrée…");
    fin_ligne_serie_ = new QComboBox;
    // Le choix de la fin de ligne est celui de l'IDE Arduino, et il n'est pas
    // cosmétique : `Serial.readStringUntil('\n')` ne rend jamais la main sans
    // saut de ligne, et l'élève croit son programme planté.
    fin_ligne_serie_->addItem("Nouvelle ligne (\\n)", QString("\n"));
    fin_ligne_serie_->addItem("Retour chariot (\\r)", QString("\r"));
    fin_ligne_serie_->addItem("Les deux (\\r\\n)", QString("\r\n"));
    fin_ligne_serie_->addItem("Aucune", QString());
    auto* bouton_serie = new QPushButton("Envoyer");
    rang_serie->addWidget(saisie_serie_, 1);
    rang_serie->addWidget(fin_ligne_serie_);
    rang_serie->addWidget(bouton_serie);
    pile_serie->addWidget(ligne_serie);

    connect(saisie_serie_, &QLineEdit::returnPressed, this,
            &FenetrePrincipale::envoyer_serie);
    connect(bouton_serie, &QPushButton::clicked, this,
            &FenetrePrincipale::envoyer_serie);
    onglets->addTab(bloc_serie, "Moniteur série");

    // L'OSCILLOSCOPE D'ATELIER EST SUPPRIMÉ.
    //
    // Il y en avait deux : celui-ci, dont on promenait les sondes depuis un
    // onglet, et le BLOC qu'on pose sur le schéma. Deux réponses à la même
    // question — « comment je regarde un signal ? » — dont aucune n'était la
    // bonne à coup sûr. Un débutant qui trouve deux oscilloscopes en cherche
    // un troisième.
    //
    // Le bloc l'emporte : c'est le modèle de MATLAB, ce qui est CÂBLÉ est ce
    // qui s'affiche, et le schéma documente alors lui-même ce qu'on observe.
    // Il a hérité des quatre voies de l'appareil qu'il remplace.

    analyses_ = new PanneauAnalyses;
    onglets->addTab(analyses_, "Analyses");

    // La page « circuit imprimé » n'est pas un onglet du bas : elle occupe
    // toute la fenêtre quand on y va, et se commande depuis sa propre barre.
    connect(pcb_, &PanneauPcb::journal, this, &FenetrePrincipale::ecrire);
    connect(pcb_, &PanneauPcb::mise_a_jour_demandee, this,
            &FenetrePrincipale::ouvrir_pcb);
    connect(pcb_, &PanneauPcb::retour_schema_demande, this,
            [this] { afficher_page(0); });
    connect(analyses_, &PanneauAnalyses::balayage_demande, this,
            [this](const QString& directive, bool bode) {
                circuit_modifie();
                QString erreur;
                if (!moteur_->executer_balayage(directive, &erreur)) {
                    analyses_->signaler(erreur);
                    return;
                }
                analyses_->afficher_balayage(moteur_->balayage(), bode,
                                             noeud_generateur());
            });
    connect(analyses_, &PanneauAnalyses::campagne_demandee, this,
            [this](const QString& reference, const QString& propriete,
                   const QVector<double>& valeurs, const QString& directive,
                   bool bode) {
                circuit_modifie();
                std::vector<double> liste(valeurs.begin(), valeurs.end());
                const coeur::Campagne campagne = coeur::balayer_parametre(
                    moteur_->netlist(), {}, reference.toStdString(),
                    propriete.toStdString(), liste, directive.toStdString());
                analyses_->afficher_campagne(campagne, bode,
                                             noeud_generateur());
            });
    connect(analyses_, &PanneauAnalyses::monte_carlo_demande, this,
            [this](double tolerance, int tirages, const QString& directive,
                   bool bode) {
                circuit_modifie();
                const coeur::Campagne campagne = coeur::monte_carlo(
                    moteur_->netlist(), {}, tolerance, tirages,
                    directive.toStdString());
                analyses_->afficher_campagne(campagne, bode,
                                             noeud_generateur());
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

    // Le bandeau ne contient plus de programme : il ne garde que ce qui se LIT.
    auto* dock_bas = new QDockWidget("Journaux et mesures", this);
    dock_bas->setObjectName("dock_bas");
    dock_bas->setWidget(onglets);
    addDockWidget(Qt::BottomDockWidgetArea, dock_bas);
    docks_schema_.push_back(dock_bas);
    // Le panneau du bas prenait un tiers de la hauteur pour montrer quatre
    // lignes de code. Il s'ouvre à la hauteur d'un vrai extrait, et c'est
    // l'utilisateur qui l'agrandit quand il édite pour de bon.
    resizeDocks({dock_bas}, {210}, Qt::Vertical);

    // Largeurs de départ des panneaux latéraux. Sans cela, Qt les répartit au
    // jugé et la palette s'ouvrait amputée.
    // La palette garde de quoi lire un nom en entier : rétrécie à 230, elle
    // affichait « Capteur analogiq… », « Codeur incrémen… ». La place rendue
    // au schéma doit venir du panneau VIDE, pas de celui qui travaille.
    // La palette SEULE : redimensionner un panneau caché ne fait rien, et
    // Qt renonce alors à la paire entière — la palette restait à la largeur
    // que Qt lui avait donnée au jugé, noms coupés compris.
    resizeDocks({docks_schema_.front()}, {265}, Qt::Horizontal);
    resizeDocks({dock_proprietes}, {260}, Qt::Horizontal);

    // Les poignées de redimensionnement font 4 pixels par défaut, et se
    // retrouvent collées aux barres de défilement du schéma et de la palette :
    // on visait la poignée, on attrapait la barre, et la page glissait au lieu
    // de se redimensionner. Sept pixels, teintés au survol, se visent.
    // Les poignées de redimensionnement, la barre de pages et la barre
    // principale portaient chacune leur propre feuille de style, écrite à la
    // main ici. Elles vivent désormais dans `apparence::feuille()`, avec tout
    // le reste — c'est la seule façon qu'une couleur de survol soit la même
    // partout sans qu'on ait à y penser.
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
    // Le nom qui ira dans le cartouche du schéma imprimé. Demandé une fois,
    // retenu ensuite — et jamais montré à l'écran, où il ne sert à rien.
    fichier->addAction("Nom pour le &cartouche…", this, [this] {
        QSettings reglages = reglages_disposition();
        bool valide = false;
        const QString saisi = QInputDialog::getText(
            this, "Cartouche du schéma imprimé",
            "Nom porté sur les schémas exportés ou imprimés :", QLineEdit::Normal,
            reglages.value("cartouche/auteur").toString(), &valide);
        if (!valide) return;
        reglages.setValue("cartouche/auteur", saisi);
        ecrire(saisi.isEmpty()
                   ? "Cartouche : le champ « Nom » sera laissé à remplir à la "
                     "main."
                   : "Cartouche : les schémas exportés porteront « " + saisi
                         + " ».");
    });
    fichier->addSeparator();
    fichier->addAction("&Quitter", QKeySequence::Quit, this, &QWidget::close);

    auto* edition = menuBar()->addMenu("&Édition");
    action_annuler_ = edition->addAction("&Annuler", QKeySequence::Undo, this,
                                         [this] {
                                             scene_->annuler();
                                             circuit_modifie();
                                         });
    action_retablir_ = edition->addAction("&Rétablir", QKeySequence::Redo, this,
                                          [this] {
                                              scene_->retablir();
                                              circuit_modifie();
                                          });
    edition->addSeparator();
    edition->addAction("&Copier", QKeySequence::Copy, this,
                       [this] { scene_->copier_selection(); });
    edition->addAction("Co&ller", QKeySequence::Paste, this, [this] {
        scene_->coller();
        circuit_modifie();
    });
    // « Ctrl+D » ne doit pas voler la frappe à l'éditeur de programme.
    //
    // Qt protège tout seul les touches nues : QPlainTextEdit accepte
    // l'événement ShortcutOverride pour toute touche imprimable, si bien que
    // « R » tapé dans du code s'écrit au lieu de pivoter un composant. Mais
    // il laisse passer les « Ctrl+lettre » : Ctrl+D frappé dans le code
    // dupliquait un composant du schéma, en silence, sans rien à l'écran qui
    // l'explique. On refuse donc la commande quand le curseur est dans un
    // champ de saisie — c'est le seul cas où l'utilisateur ne pense pas au
    // schéma.
    edition->addAction("&Dupliquer", QKeySequence(Qt::CTRL | Qt::Key_D), this,
                       [this] {
                           if (saisie_en_cours()) return;
                           scene_->dupliquer_selection();
                           circuit_modifie();
                       });
    edition->addSeparator();
    // Ces deux commandes agissent sur la PAGE ACTIVE.
    //
    // Elles ne le faisaient pas : posées en raccourci de fenêtre, elles
    // gagnaient toujours contre les gestionnaires de touches des vues, si
    // bien que « R » sur la page Circuit imprimé pivotait la sélection du
    // schéma — invisible à l'écran — et que `VuePcb::tourner_sous_curseur()`
    // ne s'exécutait jamais. Une commande dont l'effet dépend d'une page
    // qu'on ne voit pas est pire qu'une commande absente.
    edition->addAction("&Supprimer la sélection", QKeySequence::Delete, this,
                       [this] { supprimer_sur_page_active(); });
    edition->addAction("&Pivoter (R)", QKeySequence(Qt::Key_R), this,
                       [this] { pivoter_sur_page_active(); });
    edition->addSeparator();
    // « Tout sélectionner » n'existait pas : avant un déplacement d'ensemble,
    // il fallait un rectangle qui rate toujours un composant en bord de
    // feuille. Entièrement clavier, donc praticable sans souris.
    edition->addAction("Tout &sélectionner", QKeySequence::SelectAll, this,
                       [this] {
                           if (saisie_en_cours()) return;
                           for (QGraphicsItem* item : scene_->items())
                               item->setSelected(true);
                       });
    // « A » et « W » sont ceux de KiCad, et ce sont les deux gestes les plus
    // répétés d'une séance : poser un composant, tirer un fil. Ils n'existaient
    // qu'à la souris. Une touche nue ne menace pas l'éditeur de programme —
    // QPlainTextEdit absorbe les touches imprimables par le ShortcutOverride —
    // mais on garde la garde par prudence, elle ne coûte rien.
    edition->addAction("&Ajouter un composant", QKeySequence(Qt::Key_A), this,
                       [this] {
                           if (saisie_en_cours()) return;
                           afficher_page(0);
                           if (dock_palette_) dock_palette_->show();
                           if (recherche_palette_) {
                               recherche_palette_->setFocus();
                               recherche_palette_->selectAll();
                           }
                       });
    // « W » amorce un fil DEPUIS CE QU'IL Y A SOUS LE CURSEUR — il ne bascule
    // dans aucun mode.
    //
    // Il basculait sur l'outil « Fil », ce qui contredisait la décision prise
    // dans DECISION-FILS.md : « plus d'outil fil à choisir, ce qui est sous le
    // curseur décide ». Simulink ne connaît pas non plus d'outil fil — on tire
    // depuis un port, et c'est tout. Un raccourci qui rétablit un mode que le
    // geste a supprimé est une régression déguisée en fonctionnalité.
    edition->addAction("Tirer un &fil", QKeySequence(Qt::Key_W), this, [this] {
        if (saisie_en_cours() || !vue_) return;
        afficher_page(0);
        const QPointF ou =
            vue_->mapToScene(vue_->mapFromGlobal(QCursor::pos()));
        if (!scene_->amorcer_fil_au(ou))
            ecrire("Rien à câbler sous le curseur : placez-le sur une broche, "
                   "un fil ou un point de dérivation, puis appuyez sur W.");
    });

    auto* outils = menuBar()->addMenu("&Outils");
    // « Début » recadre sur tout le schéma, comme KiCad. La fonction existait
    // déjà (bouton « Ajuster ») ; il ne manquait que la touche, et elle est
    // sans danger dans l'éditeur de code, où Début va en début de ligne.
    {
        auto* recadrer = new QAction("Recadrer sur tout (Début)", this);
        recadrer->setShortcut(QKeySequence(Qt::Key_Home));
        connect(recadrer, &QAction::triggered, this, [this] {
            if (saisie_en_cours()) return;
            if (pages_ && pages_->currentIndex() == 1) {
                if (pcb_ && pcb_->vue()) pcb_->vue()->recadrer();
            } else if (vue_) {
                vue_->ajuster();
            }
        });
        outils->addAction(recadrer);
    }


    // Sélecteur de page, dans sa propre barre : c'est la seule commande qui
    // survit au changement de page, puisque c'est elle qui en change.
    auto* barre_pages = addToolBar("Pages");
    barre_pages->setObjectName("barre_pages");
    barre_pages->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    barre_pages->setMovable(false);

    action_page_schema_ = barre_pages->addAction("Schéma");
    action_page_schema_->setCheckable(true);
    action_page_schema_->setChecked(true);
    action_page_schema_->setShortcut(QKeySequence(Qt::ALT | Qt::Key_1));
    action_page_schema_->setToolTip("Page de saisie du schéma (Alt+1)");
    action_page_pcb_ = barre_pages->addAction("Circuit imprimé");
    action_page_pcb_->setCheckable(true);
    action_page_pcb_->setShortcut(QKeySequence(Qt::ALT | Qt::Key_2));
    action_page_pcb_->setToolTip("Page de routage de la carte (Alt+2)");
    auto* groupe_pages = new QActionGroup(this);
    groupe_pages->addAction(action_page_schema_);
    groupe_pages->addAction(action_page_pcb_);
    connect(action_page_schema_, &QAction::triggered, this,
            [this] { afficher_page(0); });
    connect(action_page_pcb_, &QAction::triggered, this,
            [this] { afficher_page(1); });
    auto* barre = addToolBar("Principal");
    barre->setObjectName("barre_principale");
    barre->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    barre->setMovable(false);

    barre_schema_ = barre;

    auto* selection = barre->addAction("Sélection");
    selection->setCheckable(true);
    selection->setChecked(true);
    selection->setToolTip("Déplacer et régler les composants. Cliquer une "
                          "borne tire quand même un fil.");
    // Plus de bouton « Fil ».
    //
    // Il ne faisait que RESTREINDRE : le câblage fonctionne en mode sélection,
    // et le mode n'ajoutait que d'empêcher la sélection et le déplacement. Sa
    // présence enseignait le contraire de ce que fait le logiciel — un élève
    // qui le voit croit qu'il faut le choisir pour câbler, alors que cliquer
    // une broche suffit et a toujours suffi. Voir DECISION-FILS.md.
    auto* gomme = barre->addAction("Supprimer");
    gomme->setCheckable(true);
    gomme->setToolTip("Cliquer un composant ou un fil pour l'effacer.");
    auto* groupe = new QActionGroup(this);
    groupe->addAction(selection);
    groupe->addAction(gomme);
    // Les trois actions sont retenues : le menu contextuel change d'outil, et
    // la barre doit le montrer. Deux commandes qui font la même chose sans se
    // parler, c'est une case cochée qui ment.
    action_selection_ = selection;
    action_gomme_ = gomme;
    connect(selection, &QAction::triggered, this,
            [this] { choisir_outil(SceneSchema::Outil::Selection); });
    connect(gomme, &QAction::triggered, this,
            [this] { choisir_outil(SceneSchema::Outil::Suppression); });
    outils->addAction(selection);
    outils->addAction(gomme);

    // LE ZOOM DESCEND SUR LA FEUILLE.
    //
    // Il vivait en haut de la fenêtre, à un mètre visuel de l'endroit qu'on
    // regarde en zoomant. Les cartes et les logiciels de dessin l'ont tous
    // descendu SUR le dessin depuis quinze ans, pour la même raison : la main
    // et l'œil y sont déjà. L'îlot flotte en bas à droite de la vue.
    auto* ilot = new QWidget;
    ilot->setObjectName("ilot_vue");
    auto* rang = new QHBoxLayout(ilot);
    rang->setContentsMargins(4, 4, 4, 4);
    rang->setSpacing(2);
    auto bouton_ilot = [&](const QString& texte, const QString& aide,
                           auto action) {
        auto* b = new QPushButton(texte);
        b->setToolTip(aide);
        b->setCursor(Qt::PointingHandCursor);
        b->setProperty("ilot", true);
        connect(b, &QPushButton::clicked, this, action);
        rang->addWidget(b);
        return b;
    };
    bouton_ilot("−", "Reculer (Ctrl+molette)", [this] { vue_->zoomer(1 / 1.25); });
    bouton_ilot("+", "Approcher (Ctrl+molette)", [this] { vue_->zoomer(1.25); });
    bouton_ilot("Ajuster", "Voir tout le schéma (Ctrl+0)",
                [this] { vue_->ajuster(); });
    vue_->poser_ilot(ilot);

    auto* simulation = menuBar()->addMenu("&Simulation");
    // Ce qui LANCE est poussé à droite, loin de ce qui DESSINE. Les deux
    // familles se touchaient au milieu de la barre, et rien ne disait qu'un
    // bouton modifiait le schéma quand le voisin faisait tourner le temps.
    auto* ressort = new QWidget;
    ressort->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
    barre->addWidget(ressort);
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
    // L'oscilloscope, à un clic — SANS quitter le panneau du bas.
    //
    // Le mécanisme existait déjà (`Ctrl+1`, menu Fenêtres) : ce qui manquait
    // n'était pas la fonction mais le bouton qui la montre. Un raccourci que
    // personne ne découvre n'existe pas, et l'oscilloscope est l'instrument
    // du TP — voir une PWM, la charge d'un RC.
    //
    // Il est posé près de Lancer/Arrêter et non de Sélection/Supprimer :
    // ces deux-là forment un groupe exclusif de mode d'édition, Zoom et
    // Ajuster commandent la vue. Une commande d'instrument n'est ni l'un ni
    // l'autre — elle appartient à la simulation.
    //
    // Et l'onglet reste. Multisim met ses instruments dans une barre séparée
    // mais ne retire rien ; sur le portable 1366×768 de la salle, une fenêtre
    // flottante recouvre le schéma qu'elle mesure, et l'on perdrait la
    // comparaison en un clic avec le Journal et le Contrôle, qui sont dans le
    // même panneau exprès.

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
        const std::vector<coeur::Anomalie> anomalies =
            coeur::controler_regles(moteur_->netlist());
        int erreurs = 0, avertissements = 0;
        for (const coeur::Anomalie& a : anomalies) {
            if (a.gravite == coeur::Anomalie::Gravite::Erreur) ++erreurs;
            else if (a.gravite == coeur::Anomalie::Gravite::Avertissement)
                ++avertissements;
        }
        scene_->poser_anomalies(anomalies);
        remplir_controle(anomalies);
        refleter_controle(erreurs, avertissements);
        ecrire(QString::fromStdString(coeur::rapport_regles(moteur_->netlist())));
        // PAS DE BOÎTE MODALE : elle recouvrait le schéma qu'elle décrivait,
        // et il fallait la fermer pour regarder ce dont elle parlait. Le
        // panneau reste ouvert pendant qu'on corrige.
        montrer_onglet("Contrôle");
        for (QDockWidget* dock : docks_schema_)
            if (dockWidgetArea(dock) == Qt::BottomDockWidgetArea
                && !dock->isVisible())
                dock->setVisible(true);
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
        montrer_onglet("Journal");
    });

    // Les exemples se rangent PAR CARTE.
    //
    // La liste était plate, et neuf de ses dix entrées posaient un Arduino Uno
    // en dur. Sur un poste réglé pour un TP ESP32 ou STM32, huit entrées
    // chargeaient donc silencieusement un Uno à la place de la carte du jour.
    // Ce n'est pas un problème de rangement : c'est une erreur d'élève qu'on
    // fabrique, et qu'il n'a aucun moyen de diagnostiquer.
    //
    // L'IDE Arduino range de même — « Examples for <board> » —, à ceci près
    // qu'il ne montre que la carte active. Ici les branches sont toutes
    // visibles : elles disent AUSSI que le simulateur connaît neuf cartes,
    // ce que la liste plate cachait.
    auto* exemples = menuBar()->addMenu("E&xemples");

    // La famille ATmega328P d'abord : c'est celle du cours, et la seule dont
    // les montages soient tous écrits.
    auto* uno = exemples->addMenu("Arduino &Uno");
    uno->addAction("Clignotant sur D13", this,
                   [this] { charger_exemple(Exemple::Clignotant); });
    uno->addAction("Bouton et LED (entrée avec pull-up)", this,
                   [this] { charger_exemple(Exemple::BoutonLed); });
    uno->addAction("Potentiomètre sur A0 (conversion analogique)", this,
                   [this] { charger_exemple(Exemple::PotentiometreLed); });
    uno->addAction("PWM sur D9 (à observer à l'oscilloscope)", this,
                   [this] { charger_exemple(Exemple::Pwm); });
    uno->addSeparator();
    uno->addAction("Moteur commandé par transistor", this,
                   [this] { charger_exemple(Exemple::Transistor); });
    uno->addAction("Moteur en PWM avec transistor", this,
                   [this] { charger_exemple(Exemple::MoteurPuissance); });
    uno->addAction("Servomoteur balayé", this,
                   [this] { charger_exemple(Exemple::Servo); });
    uno->addAction("Chenillard sur registre 74HC595 (moteur numérique)", this,
                   [this] { charger_exemple(Exemple::Registre); });
    uno->addSeparator();
    uno->addAction("Deux cartes qui communiquent", this,
                   [this] { charger_exemple(Exemple::DeuxCartes); });

    // Les autres cartes. Chacune porte déjà son clignotant dans le catalogue,
    // vérifié par le banc d'essai ; ce qui change d'une à l'autre tient au nom
    // de la broche qui porte la LED.
    //
    // Aucune n'a plus d'un exemple, et c'est dit plutôt que caché : le noyau
    // Arduino ne couvre que la famille ATmega328P, et les catalogues officiels
    // de Pico (pico-sdk), STM32 (HAL) et ESP32 (ESP-IDF) ne se compilent pas
    // ici — le simulateur n'accepte que du C nu sur registres. Proposer un
    // exemple qui se bloque coûte plus cher qu'une absence.
    struct Branche {
        const char* menu;
        const char* type;
        const char* broche;
        const char* note;
    };
    static const Branche kBranches[] = {
        {"Arduino &Nano", "arduino_nano", "D13", nullptr},
        {"Arduino &Pro Mini", "arduino_pro_mini", "D13", nullptr},
        {"Arduino &Mega 2560", "arduino_mega", "D13", nullptr},
        {"ATmega328P n&u", "atmega328p", "PB5",
         "Puce nue, en C sur registres : pas de noyau Arduino."},
        {"A&Ttiny85", "attiny85", "PB1",
         "Pas d'UART matériel : aucune sortie série sur cette puce."},
        {"Raspberry Pi Pi&co", "pi_pico", "GP25",
         "C nu sur registres : le pico-sdk ne se compile pas ici."},
        {"&STM32F103 (Blue Pill)", "stm32f103", "PC13",
         "C nu sur registres : ni HAL ni CubeMX."},
        {"&ESP32", "esp32", "GPIO2",
         "Chaîne Xtensa absente : chargez un .elf déjà compilé."},
    };
    for (const Branche& branche : kBranches) {
        auto* sous_menu = exemples->addMenu(branche.menu);
        const QString type = branche.type;
        const QString broche = branche.broche;
        QAction* action = sous_menu->addAction(
            QString("Clignotant sur %1").arg(broche), this,
            [this, type, broche] { charger_clignotant_carte(type, broche); });
        if (branche.note) action->setToolTip(branche.note);
        if (branche.note) {
            // La limite est écrite DANS le menu, pas seulement en info-bulle :
            // un élève qui cherche pourquoi son exemple ESP32 ne compile pas
            // ne pensera pas à survoler une entrée.
            auto* limite = sous_menu->addAction(branche.note);
            limite->setEnabled(false);
        }
    }

    exemples->addSeparator();
    // Sans carte : un filtre, un pont diviseur ou un redresseur n'ont pas
    // besoin de microcontrôleur, et ce sont les séances d'électronique du
    // cours. Elles n'avaient qu'un seul exemple, perdu au milieu des montages
    // Arduino.
    auto* sans_carte = exemples->addMenu("Sans &carte (analogique pur)");
    sans_carte->addAction("Pont diviseur (la base de toute entrée analogique)",
                          this, [this] { charger_exemple_pont_diviseur(); });
    sans_carte->addAction("Filtre RC (analyses : Bode, balayage, spectre)",
                          this, [this] { charger_exemple(Exemple::FiltreRC); });
    sans_carte->addAction("Régulateur à diode Zener", this,
                          [this] { charger_exemple_zener(); });

    // Fenêtres : c'est l'utilisateur qui sort un panneau de mesure, jamais
    // l'application. Le raccourci le remet aussi bien qu'il le sort.
    auto* fenetres = menuBar()->addMenu("Fe&nêtres");
    // LE THÈME, ET SON SOUVENIR.
    //
    // Le choix se garde d'une session à l'autre : imposer le clair à chaque
    // lancement à quelqu'un qui travaille en sombre serait pire que de ne pas
    // offrir le choix du tout.
    auto* theme = fenetres->addMenu("&Thème");
    auto* groupe_theme = new QActionGroup(this);
    auto poser_theme = [this](apparence::Theme choix) {
        apparence::appliquer(choix);
        apparence::enregistrer_theme(choix);
        ecrire(choix == apparence::Theme::Sombre ? "Thème sombre."
                                                 : "Thème clair.");
    };
    auto* clair = theme->addAction("Clair");
    clair->setCheckable(true);
    connect(clair, &QAction::triggered, this,
            [poser_theme] { poser_theme(apparence::Theme::Clair); });
    auto* fonce = theme->addAction("Sombre");
    fonce->setCheckable(true);
    connect(fonce, &QAction::triggered, this,
            [poser_theme] { poser_theme(apparence::Theme::Sombre); });
    groupe_theme->addAction(clair);
    groupe_theme->addAction(fonce);
    (apparence::theme_enregistre() == apparence::Theme::Sombre ? fonce : clair)
        ->setChecked(true);
    fenetres->addSeparator();
    fenetres->addAction("Analyses dans leur propre fenêtre",
                        QKeySequence(Qt::CTRL | Qt::Key_2), this,
                        [this] { basculer_fenetre(analyses_); });
    fenetres->addSeparator();
    fenetres->addAction("Fermer toutes les fenêtres de mesure", this, [this] {
        while (!fenetres_instruments_.empty())
            fenetres_instruments_.front()->close();
    });
    fenetres->addSeparator();
    // F11 : la convention du plein écran partout — navigateurs, lecteurs,
    // visionneuses. Rien à apprendre.
    fenetres->addAction("Mode &présentation (schéma seul, plein écran)",
                        QKeySequence(Qt::Key_F11), this,
                        &FenetrePrincipale::basculer_presentation);
    fenetres->addAction("&Réinitialiser la disposition", this,
                        &FenetrePrincipale::reinitialiser_disposition);

    // Le circuit imprimé consomme la netlist du schéma : même composants,
    // mêmes nets, aucune ressaisie.
    auto* pcb = menuBar()->addMenu("&Carte");
    pcb->addAction("&Transférer le schéma vers la carte",
                   QKeySequence(Qt::Key_F8), this,
                   &FenetrePrincipale::ouvrir_pcb);
    pcb->addSeparator();
    pcb->addAction(action_page_schema_);
    pcb->addAction(action_page_pcb_);
    pcb->addSeparator();
    pcb->addAction("&Contrôler les règles de fabrication", this, [this] {
        if (!pcb_) return;
        afficher_page(1);
        pcb_->controler();
    });

    auto* aide = menuBar()->addMenu("&Aide");
    aide->addAction("&Raccourcis clavier", QKeySequence(Qt::Key_F1), this,
                    &FenetrePrincipale::montrer_raccourcis);
    aide->addSeparator();
    aide->addAction("À &propos", this, [this] {
        QMessageBox::about(
            this, "À propos",
            "<h3>Simulateur embarqué</h3>"
            "<p>Saisie de schéma, simulation analogique et exécution du vrai "
            "firmware compilé, dans une seule application.</p>"
            "<p>Moteur analogique : <b>solveur intégré</b> — analyse nodale "
            "modifiée, Newton, trapèzes ; rien à installer. <b>ngspice</b> "
            "peut le doubler pour comparaison.<br>"
            "Moteur microcontrôleur : <b>cœur ATmega328P intégré</b> — le "
            "vrai firmware compilé, exécuté instruction par instruction. "
            "<b>simavr</b> peut le doubler pour comparaison.</p>"
            "<p>Raccourcis : <b>R</b> pivote la sélection, <b>Suppr</b> "
            "l'efface, la molette zoome.</p>"
            "<p>Sur un fil : <b>clic gauche</b> le désigne, <b>glissé "
            "gauche</b> déplace le segment, <b>glissé au bouton droit</b> en "
            "dérive un nouveau — comme dans Simulink.</p>"
            + QString("<p style='color:#666'>Version %1, exécutable du %2.</p>")
                  .arg(QApplication::applicationVersion(),
                       QFileInfo(QCoreApplication::applicationFilePath())
                           .lastModified()
                           .toString("dd/MM/yyyy à HH:mm")));
    });
}

void FenetrePrincipale::construire_barre_etat() {
    etiquette_moteurs_ = new QLabel;
    etiquette_etat_ = new QLabel;
    // Le compteur d'anomalies : le seul endroit où l'existence du contrôle
    // des règles est visible en permanence. Sans lui, un élève ne sait pas
    // qu'on peut vérifier son montage — et en enseignement, une fonction
    // cachée n'existe pas.
    etiquette_anomalies_ = new QLabel("Contrôle : non passé");
    etiquette_anomalies_->setToolTip(
        "Contrôle des règles électriques. Il passe au lancement de la "
        "simulation ; le détail est dans le journal.");
    // Le nœud survolé. Vide au repos : une étiquette qui dirait « aucun nœud »
    // occuperait la place en permanence pour ne rien apprendre.
    etiquette_noeud_ = new QLabel;
    etiquette_noeud_->setStyleSheet("color:#7a5c00");
    etiquette_temps_ = new QLabel("Temps simulé : 0,000 s");
    etiquette_vitesse_ = new QLabel("Vitesse : —");

    const bool spice = coeur::NgspiceEngine::compile_avec_ngspice();
    const bool avr = coeur::AvrEngine::compile_avec_simavr();
    const bool gcc = coeur::AvrEngine::avr_gcc_disponible();
    // Le moteur analogique est toujours là : ou bien c'est le solveur
    // intégré, ou bien ngspice quand il a été trouvé à la compilation.
    // Une pastille par moteur : verte s'il est là, grise sinon. Le détail —
    // à quoi il sert, ce qu'il manque — passe en infobulle plutôt que
    // d'encombrer la barre en permanence.
    auto pastille = [](bool present, const QString& nom) {
        return QString("<span style='color:%1'>●</span> %2")
            .arg(present ? "#2e9e44" : "#b0b0b0", nom);
    };
    etiquette_moteurs_->setText(
        pastille(true, spice ? "analogique (intégré + ngspice)"
                             : "analogique (intégré)")
        + "   " + pastille(true, avr ? "AVR (intégré + simavr)" : "AVR (intégré)")
        // Les moteurs d'abord — ce qui exécute —, les compilateurs ensuite.
        // Sans ce mot, « AVR » apparaîtrait deux fois et désignerait deux
        // choses différentes.
        + "    compilateurs : " + pastille(gcc, "AVR")
        + " " + pastille(coeur::chaine_disponible_pour("rp2040"), "ARM")
        + " " + pastille(coeur::chaine_disponible_pour("esp32"), "Xtensa"));
    etiquette_moteurs_->setToolTip(
        QString("Moteurs d'exécution — tous intégrés, rien à installer :\n"
                "  analogique, AVR, Cortex-M, Xtensa.\n"
                "ngspice : %1, simavr : %2 — moteurs de référence, utilisés "
                "pour comparer dans les tests.\n\n"
                "Compilateurs — nécessaires seulement pour compiler depuis "
                "l'application ; un .elf déjà compilé se charge sans eux :\n%3"
                "\nLancez outils/chaines pour les emporter dans le paquet.")
            .arg(spice ? "présent" : "absent", avr ? "présent" : "absent",
                 QString::fromStdString(coeur::chaines::etat())));

    statusBar()->addWidget(etiquette_etat_);
    statusBar()->addWidget(new QLabel("  "));
    statusBar()->addWidget(etiquette_moteurs_);
    statusBar()->addWidget(new QLabel("  "));
    statusBar()->addWidget(etiquette_anomalies_);
    statusBar()->addWidget(new QLabel("  "));
    statusBar()->addWidget(etiquette_noeud_, 1);
    statusBar()->addPermanentWidget(etiquette_temps_);
    statusBar()->addPermanentWidget(etiquette_vitesse_);
    refleter_etat();

    // Le moteur analogique est toujours là ; seul le firmware peut manquer.
    // Les compilateurs manquants se disent une fois, au démarrage : c'est
    // là que la question se pose, pas au milieu d'une compilation qui échoue.
    if (!coeur::AvrEngine::avr_gcc_disponible()
        || !coeur::chaine_disponible_pour("rp2040")) {
        ecrire("Compilateurs disponibles :\n"
               + QString::fromStdString(coeur::chaines::etat())
               + "Ce qui manque n'empêche que la compilation depuis "
                 "l'application : un .elf déjà compilé se charge toujours "
                 "(Simulation → Charger un firmware).");
    }
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

void FenetrePrincipale::ouvrir_pcb() {
    if (!pcb_) return;
    circuit_modifie();
    // La netlist de la carte inclut les cartes programmables, que la
    // simulation, elle, confie à l'émulateur.
    const QString rapport = pcb_->construire_depuis(scene_->netlist_pcb());
    const bool premier = !carte_transferee_;
    carte_transferee_ = true;
    afficher_page(1);
    ecrire(rapport);
    if (premier) {
        ecrire("Le câblage se refait ici : le schéma dit QUI doit être relié "
               "à qui — c'est le chevelu —, les pistes disent COMMENT.");
        ecrire("Placez les empreintes à la souris (R les fait tourner), puis "
               "tirez les pistes d'une pastille à l'autre.");
    }
}

// Pivoter et supprimer suivent la page qu'on regarde.
//
// Le schéma et le circuit imprimé sont deux dessins distincts avec chacun sa
// sélection ; une même touche doit agir sur celui qui est sous les yeux.
// Le curseur est-il dans un champ où l'on tape du texte ?
//
// Sert d'écran aux commandes de schéma portées par un « Ctrl+lettre » : ce
// sont les seules que Qt laisse passer par-dessus un éditeur de texte, et
// donc les seules qui puissent agir alors que l'utilisateur croit écrire.
bool FenetrePrincipale::saisie_en_cours() const {
    const QWidget* focus = QApplication::focusWidget();
    while (focus) {
        if (qobject_cast<const QPlainTextEdit*>(focus)
            || qobject_cast<const QTextEdit*>(focus)
            || qobject_cast<const QLineEdit*>(focus))
            return true;
        focus = focus->parentWidget();
    }
    return false;
}

// Envoie le contenu du champ de saisie à la carte, octet par octet.
void FenetrePrincipale::envoyer_serie() {
    if (!saisie_serie_ || !moteur_) return;
    const QString texte = saisie_serie_->text();
    if (texte.isEmpty()) return;
    const QString fin = fin_ligne_serie_
                            ? fin_ligne_serie_->currentData().toString()
                            : QString("\n");
    const QByteArray octets = (texte + fin).toUtf8();
    // La carte qui reçoit est celle dont on regarde le programme : c'est
    // celle à laquelle l'utilisateur pense, et sur un schéma à deux cartes
    // c'est la seule réponse qui ne soit pas un tirage au sort.
    moteur_->envoyer_serie(octets, carte_courante_);
    // On répète ce qu'on vient d'envoyer : sans écho, rien ne distingue un
    // envoi parti d'un envoi perdu.
    if (moniteur_serie_)
        moniteur_serie_->appendPlainText("> " + texte);
    saisie_serie_->clear();
}

// Le pense-bête des raccourcis, ENGENDRÉ depuis les actions.
//
// C'est le point essentiel : une liste écrite à la main se désynchronise du
// code à la première modification, et un pense-bête qui ment est pire que pas
// de pense-bête. En parcourant les QAction de la barre de menus, la liste dit
// toujours ce que l'application fait vraiment.
//
// Et c'est la seule réponse à « comment l'élève apprend-il que W existe ? ».
// En enseignement, une fonction cachée n'existe pas : sans cette fenêtre, les
// autres raccourcis du chantier seraient du travail perdu.
// Reflète le résultat du dernier contrôle dans la barre d'état.
void FenetrePrincipale::refleter_controle(int erreurs, int avertissements) {
    if (!etiquette_anomalies_) return;
    if (erreurs == 0 && avertissements == 0) {
        etiquette_anomalies_->setText("Contrôle : aucune anomalie");
        etiquette_anomalies_->setStyleSheet("color:#2e7d32");
        return;
    }
    QString texte;
    if (erreurs > 0)
        texte += QString("%1 erreur%2").arg(erreurs).arg(erreurs > 1 ? "s" : "");
    if (avertissements > 0) {
        if (!texte.isEmpty()) texte += " · ";
        texte += QString("%1 avertissement%2")
                     .arg(avertissements)
                     .arg(avertissements > 1 ? "s" : "");
    }
    etiquette_anomalies_->setText("Contrôle : " + texte);
    etiquette_anomalies_->setStyleSheet(erreurs > 0 ? "color:#c62828"
                                                    : "color:#e65100");
}

void FenetrePrincipale::montrer_raccourcis() {
    QString texte =
        "<p style='color:#555'>Les raccourcis ci-dessous sont lus dans les "
        "menus de l'application : cette liste ne peut donc pas mentir.</p>";

    for (QAction* menu_action : menuBar()->actions()) {
        QMenu* menu = menu_action->menu();
        if (!menu) continue;
        QString lignes;
        // Les sous-menus comptent aussi : « Exemples » et « Fenêtres » en ont.
        std::function<void(QMenu*)> parcourir = [&](QMenu* courant) {
            for (QAction* action : courant->actions()) {
                if (action->menu()) {
                    parcourir(action->menu());
                    continue;
                }
                if (action->isSeparator() || action->shortcut().isEmpty())
                    continue;
                QString nom = action->text();
                nom.remove('&');
                lignes += QString("<tr><td style='padding-right:18px'>%1</td>"
                                  "<td><b>%2</b></td></tr>")
                              .arg(nom.toHtmlEscaped(),
                                   action->shortcut()
                                       .toString(QKeySequence::NativeText)
                                       .toHtmlEscaped());
            }
        };
        parcourir(menu);
        if (lignes.isEmpty()) continue;
        QString titre = menu_action->text();
        titre.remove('&');
        texte += "<h4>" + titre.toHtmlEscaped() + "</h4><table>" + lignes
                 + "</table>";
    }

    // Ce qui ne passe pas par un menu doit être dit ici aussi, sinon la liste
    // est complète au sens du code et fausse au sens de l'utilisateur.
    texte +=
        "<h4>À la souris</h4><table>"
        "<tr><td style='padding-right:18px'>Câbler</td><td><b>Clic sur une "
        "broche, un point ou un fil</b></td></tr>"
        "<tr><td>Dériver depuis un fil</td><td><b>Clic sur le fil</b></td></tr>"
        "<tr><td>Poser un coude</td><td><b>Clic dans le vide</b> pendant le "
        "tracé</td></tr>"
        "<tr><td>Abandonner le fil en cours</td><td><b>Clic droit</b> ou "
        "<b>Échap</b></td></tr>"
        // Les deux lignes qui manquaient le plus.
        //
        // Le double-clic sur une carte ouvre son programme depuis toujours, et
        // personne ne le savait — pas même celui qui a commandé le logiciel.
        // Ce pense-bête n'engendre que les QAction des menus ; un geste de
        // souris n'en est pas une, et n'apparaissait donc nulle part. C'est la
        // porte d'entrée vers l'éditeur de code, pour le seul TP que le
        // simulateur couvre entièrement : elle ne pouvait pas rester cachée.
        "<tr><td><b>Ouvrir le programme d'une carte</b></td><td><b>Double-clic "
        "sur la carte</b></td></tr>"
        "<tr><td>Régler un composant, ouvrir un instrument</td>"
        "<td><b>Double-clic dessus</b></td></tr>"
        "<tr><td>Aller au code d'une erreur de compilation</td>"
        "<td><b>Double-clic sur la ligne</b> du Journal</td></tr>"
        "<tr><td>Voir tout ce qui est relié à un point</td>"
        "<td><b>Survol</b> — le nœud s'allume, son nom est en barre d'état"
        "</td></tr>"
        "<tr><td>Déplacer la vue</td><td><b>Molette</b>, ou bouton du milieu "
        "maintenu</td></tr>"
        "<tr><td>Zoomer</td><td><b>Ctrl + molette</b></td></tr>"
        "</table>";

    QMessageBox boite(this);
    boite.setWindowTitle("Raccourcis clavier");
    boite.setTextFormat(Qt::RichText);
    boite.setText(texte);
    boite.setStandardButtons(QMessageBox::Close);
    if (!silencieux_) boite.exec();
}

void FenetrePrincipale::pivoter_sur_page_active() {
    if (pages_ && pages_->currentIndex() == 1) {
        if (pcb_ && pcb_->vue()) pcb_->vue()->tourner_sous_curseur();
        return;
    }
    scene_->memoriser();
    for (QGraphicsItem* item : scene_->selectedItems())
        if (item->type() == ItemComposant::Type)
            static_cast<ItemComposant*>(item)->tourner();
    circuit_modifie();
}

void FenetrePrincipale::supprimer_sur_page_active() {
    // Sur le circuit imprimé, rien ne s'efface à la touche Suppr : les
    // empreintes viennent du schéma et s'y suppriment. « Défaire la piste »
    // est le geste équivalent, et il a déjà sa touche.
    if (pages_ && pages_->currentIndex() == 1) return;
    scene_->memoriser();
    scene_->supprimer_selection();
    circuit_modifie();
}

// ---------------------------------------------------------------------------
// Disposition et mode présentation
// ---------------------------------------------------------------------------
void FenetrePrincipale::enregistrer_disposition() const {
    // Ne JAMAIS enregistrer la disposition du mode présentation : elle n'a
    // ni panneau ni barre d'outils, et la relire au démarrage suivant
    // donnerait une fenêtre vide dont rien n'expliquerait l'état.
    if (presentation_) return;
    QSettings reglages = reglages_disposition();
    reglages.setValue(kCleGeometrie, saveGeometry());
    reglages.setValue(kCleEtat, saveState());
}

void FenetrePrincipale::restaurer_disposition() {
    QSettings reglages = reglages_disposition();
    const QByteArray geometrie = reglages.value(kCleGeometrie).toByteArray();
    const QByteArray etat = reglages.value(kCleEtat).toByteArray();
    if (!geometrie.isEmpty()) restoreGeometry(geometrie);
    if (!etat.isEmpty()) restoreState(etat);
}

void FenetrePrincipale::reinitialiser_disposition() {
    if (presentation_) basculer_presentation();
    if (disposition_par_defaut_.isEmpty()) return;
    restoreState(disposition_par_defaut_);
    // Les panneaux du schéma n'appartiennent qu'à la page schéma : les
    // reposer tous visibles alors qu'on est sur la carte contredirait la
    // règle. On repasse donc par `afficher_page`, qui la connaît.
    afficher_page(pages_ ? pages_->currentIndex() : 0);
    ecrire("Disposition réinitialisée.");
}

void FenetrePrincipale::basculer_presentation() {
    if (!presentation_) {
        disposition_avant_presentation_ = saveState();
        for (QDockWidget* dock : findChildren<QDockWidget*>())
            dock->hide();
        for (QToolBar* barre : findChildren<QToolBar*>()) barre->hide();
        if (menuBar()) menuBar()->hide();
        if (statusBar()) statusBar()->hide();
        presentation_ = true;
        showFullScreen();
        return;
    }

    presentation_ = false;
    showNormal();
    if (menuBar()) menuBar()->show();
    if (statusBar()) statusBar()->show();
    // `restoreState` repose la visibilité de chaque panneau telle qu'elle
    // était : c'est ce qui évite de rouvrir des panneaux que l'utilisateur
    // avait lui-même fermés avant d'appuyer sur F11.
    if (!disposition_avant_presentation_.isEmpty())
        restoreState(disposition_avant_presentation_);
    afficher_page(pages_ ? pages_->currentIndex() : 0);
}

void FenetrePrincipale::closeEvent(QCloseEvent* evenement) {
    enregistrer_disposition();

    // FERMER LA FENÊTRE PRINCIPALE FERME CE QU'ELLE A DÉTACHÉ.
    //
    // Les fenêtres du programme et des oscilloscopes n'ont pas de parent Qt —
    // c'est ce qui leur permet d'être de vraies fenêtres, déplaçables sur un
    // second écran. Mais Qt ne quitte que lorsque la DERNIÈRE fenêtre se
    // ferme : l'une d'elles restée ouverte gardait donc l'application en vie
    // après la disparition de sa fenêtre principale, sans plus aucun moyen de
    // la faire revenir. Un processus fantôme, qu'il fallait tuer.
    if (fenetre_programme_) fenetre_programme_->close();
    for (auto& paire : scopes_) paire.second->close();
    for (FenetreInstrument* fenetre : fenetres_instruments_) fenetre->close();

    QMainWindow::closeEvent(evenement);
}

// Sortir du plein écran par DEUX Échap rapprochés, jamais un seul.
//
// Un Échap isolé abandonne le fil en cours de tracé : lui donner aussi la
// sortie du plein écran ferait qu'abandonner un fil quitterait la
// présentation, en pleine démonstration. Deux appuis lèvent l'ambiguïté sans
// rien apprendre à personne — et F11 reste la sortie évidente.
void FenetrePrincipale::keyPressEvent(QKeyEvent* evenement) {
    if (presentation_ && evenement->key() == Qt::Key_Escape) {
        const qint64 maintenant = QDateTime::currentMSecsSinceEpoch();
        constexpr qint64 kFenetreMs = 700;
        if (dernier_echap_ms_ != 0
            && maintenant - dernier_echap_ms_ <= kFenetreMs) {
            dernier_echap_ms_ = 0;
            basculer_presentation();
            evenement->accept();
            return;
        }
        dernier_echap_ms_ = maintenant;
        evenement->accept();
        return;
    }
    QMainWindow::keyPressEvent(evenement);
}

void FenetrePrincipale::afficher_page(int page) {
    if (!pages_) return;
    page = page > 0 ? 1 : 0;
    // Masquer un panneau puis le remontrer lui fait perdre sa taille : la
    // palette revenait amputée, les noms de composants coupés. On note donc
    // les tailles avant de partir, et on les repose au retour.
    if (page == 1 && pages_->currentIndex() == 0) {
        tailles_docks_.clear();
        for (QDockWidget* dock : docks_schema_)
            tailles_docks_.push_back(
                dockWidgetArea(dock) == Qt::BottomDockWidgetArea
                    ? dock->height()
                    : dock->width());
    }
    pages_->setCurrentIndex(page);
    page_courante_ = page;
    // Les outils du schéma n'ont rien à faire sur la carte : la palette de
    // composants, les propriétés et le journal appartiennent à la saisie.
    for (QDockWidget* dock : docks_schema_) dock->setVisible(page == 0);
    // …sauf les propriétés, qui n'apparaissent qu'avec une sélection.
    if (dock_proprietes_ && (page == 1 || !selection_)) dock_proprietes_->hide();
    if (page == 0 && tailles_docks_.size() == docks_schema_.size()) {
        // Après le retour à l'affichage, pas avant : Qt doit avoir refait sa
        // mise en page pour qu'un redimensionnement de panneau prenne effet.
        QTimer::singleShot(0, this, [this] {
            if (tailles_docks_.size() != docks_schema_.size()) return;
            QList<QDockWidget*> horizontaux, verticaux;
            QList<int> largeurs, hauteurs;
            for (size_t k = 0; k < docks_schema_.size(); ++k) {
                if (dockWidgetArea(docks_schema_[k]) == Qt::BottomDockWidgetArea) {
                    verticaux << docks_schema_[k];
                    hauteurs << tailles_docks_[k];
                } else {
                    horizontaux << docks_schema_[k];
                    largeurs << tailles_docks_[k];
                }
            }
            if (!horizontaux.isEmpty())
                resizeDocks(horizontaux, largeurs, Qt::Horizontal);
            if (!verticaux.isEmpty())
                resizeDocks(verticaux, hauteurs, Qt::Vertical);
        });
    }
    if (barre_schema_) barre_schema_->setVisible(page == 0);
    if (action_page_schema_) action_page_schema_->setChecked(page == 0);
    if (action_page_pcb_) action_page_pcb_->setChecked(page == 1);
    setWindowTitle(page == 0
                       ? "Simulateur embarqué — schéma et exécution du firmware"
                       : "Simulateur embarqué — circuit imprimé");
    if (page == 1 && !carte_transferee_)
        ecrire("La carte est vide : lancez « Carte ▸ Transférer le schéma vers "
               "la carte » (F8).");
}

int FenetrePrincipale::page_courante() const {
    return pages_ ? pages_->currentIndex() : 0;
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
    // Double-clic dans le journal : si la ligne est une erreur de
    // compilation, on va s'y poser. C'est la première erreur que rencontre un
    // élève, et jusqu'ici la sortie du compilateur était déversée telle
    // quelle — à lui de recompter les lignes à la main.
    if (evenement->type() == QEvent::MouseButtonDblClick && console_
        && objet == console_->viewport()) {
        auto* souris = static_cast<QMouseEvent*>(evenement);
        const QTextCursor curseur =
            console_->cursorForPosition(souris->position().toPoint());
        const std::vector<ErreurCompilation> trouvees =
            analyser_sortie_compilateur(curseur.block().text());
        if (!trouvees.empty() && aller_a_erreur(trouvees.front())) {
            evenement->accept();
            return true;
        }
    }
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

void FenetrePrincipale::ouvrir_programme(ItemComposant* carte) {
    if (!carte || !editeur_source_) return;
    const QString reference = carte->reference();

    // Le sélecteur ne connaît que les cartes que le moteur a vues : une carte
    // tout juste posée n'y est pas encore. On rafraîchit d'abord.
    if (selecteur_carte_ && selecteur_carte_->findText(reference) < 0)
        synchroniser_cartes(moteur_->cartes());
    if (selecteur_carte_ && selecteur_carte_->findText(reference) >= 0)
        selecteur_carte_->setCurrentText(reference);

    afficher_page(0);
    if (fenetre_programme_) {
        // Le titre dit DE QUELLE CARTE il s'agit : sur un schéma à deux
        // microcontrôleurs, une fenêtre « Programme » tout court laisserait
        // charger le mauvais code sans le moindre signe.
        fenetre_programme_->setWindowTitle("Programme de " + reference
                                           + " — simulateur");
        fenetre_programme_->show();
        fenetre_programme_->raise();
        fenetre_programme_->activateWindow();
    }
    editeur_source_->setFocus();
    // La sélection accompagne le geste : les propriétés de la carte restent
    // visibles à droite pendant qu'on écrit son programme.
    afficher_proprietes(carte);
    ecrire("Programme de " + reference + " : à vous.");
}

// Ouvre — ou ramène devant — la fenêtre du scope désigné.
//
// Les deux voies sont liées aux nœuds de ses bornes, pas choisies dans une
// liste : c'est tout l'intérêt du modèle Simulink. Ce qu'on a câblé est ce
// qu'on voit, et le schéma dit lui-même ce qui est observé.
Oscilloscope* FenetrePrincipale::scope_de(ItemComposant* composant) const {
    auto it = scopes_.find(composant);
    return it == scopes_.end() ? nullptr : it->second;
}

// L'APPAREIL EXISTE DÈS QUE LE BLOC EST POSÉ, fenêtre fermée ou non.
//
// Il n'était créé qu'au premier double-clic. Un bloc posé et câblé mais
// jamais ouvert n'enregistrait donc RIEN : on lançait la simulation, on
// ouvrait le scope à la fin, et l'écran était vide — sans que rien n'explique
// pourquoi. C'est aussi ce qui vidait la vérification automatique, qui lit le
// rapport des scopes : sans fenêtre ouverte, elle ne lisait plus rien et
// restait verte en ne prouvant rien.
Oscilloscope* FenetrePrincipale::scope_pour(ItemComposant* composant) {
    if (!composant) return nullptr;
    auto place = scopes_.find(composant);
    if (place != scopes_.end()) return place->second;
    auto* scope = new Oscilloscope;
    // Une fenêtre à part entière, pas un panneau : on en ouvre plusieurs, et
    // on les pose côte à côte pour comparer deux endroits du montage.
    scope->setWindowFlags(Qt::Window);
    scope->setAttribute(Qt::WA_DeleteOnClose, false);
    scopes_[composant] = scope;
    connect(scope, &Oscilloscope::resolution_souhaitee, this,
            [this](double secondes) { moteur_->definir_resolution(secondes); });
    return scope;
}

void FenetrePrincipale::ouvrir_scope(ItemComposant* composant) {
    Oscilloscope* scope = scope_pour(composant);
    if (!scope) return;
    scope->setWindowTitle(composant->reference() + " — oscilloscope");

    // (Re)lier les voies : le câblage a pu changer depuis la dernière fois.
    scope->proposer_signaux(derniers_signaux_, derniers_libelles_);
    for (int voie = 0; voie < TraceOscilloscope::kVoies; ++voie) {
        const QString noeud = scene_->noeud_de(composant, voie);
        if (!noeud.isEmpty()) scope->sonder(noeud);
    }

    scope->resize(760, 520);
    scope->show();
    scope->raise();
    scope->activateWindow();
}

void FenetrePrincipale::ouvrir_fenetre_instrument(ItemComposant* composant) {
    if (!composant || !composant->modele()) return;
    // Une carte programmable, c'est d'abord un programme : double-cliquer
    // dessus ouvre le sien, comme on ouvre le code d'un microcontrôleur dans
    // Proteus ou dans Wokwi. Régler ses propriétés vient après, dans le
    // panneau de droite.
    if (composant->modele()->carte) {
        ouvrir_programme(composant);
        return;
    }
    if (!composant->modele()->mesure_instrument) {
        // Pas un instrument : le double-clic sert alors à régler le composant.
        afficher_proprietes(composant);
        return;
    }
    // Un scope a sa propre fenêtre, et elle montre CE QUI LUI EST CÂBLÉ.
    if (composant->modele()->type == "scope") {
        ouvrir_scope(composant);
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
                // La sonde va sur le PREMIER bloc oscilloscope ouvert. S'il
                // n'y en a pas, on ne fait pas semblant : on dit où le
                // trouver. Une commande qui ne répond rien laisse croire à
                // une panne.
                if (scopes_.empty()) {
                    ecrire("Aucun oscilloscope sur le schéma : posez un bloc "
                           "« Oscilloscope » (catégorie Instruments), câblez "
                           "une voie, puis double-cliquez dessus.");
                    return;
                }
                Oscilloscope* scope = scopes_.begin()->second;
                scope->sonder(designation);
                scope->show();
                scope->raise();
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

// Change d'outil, d'où que vienne la demande — barre du haut, menu
// contextuel ou raccourci — et met tout le monde d'accord.
void FenetrePrincipale::choisir_outil(SceneSchema::Outil outil) {
    scene_->definir_outil(outil);
    QAction* miroir = outil == SceneSchema::Outil::Suppression
                          ? action_gomme_
                          : action_selection_;
    if (miroir) miroir->setChecked(true);
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
        // Une carte, c'est d'abord un programme.
        if (modele && modele->carte)
            menu.addAction("Ouvrir le programme…", this,
                           [this, composant] { ouvrir_programme(composant); });
        menu.addAction("Propriétés", this,
                       [this, composant] { afficher_proprietes(composant); });
        menu.addAction("Pivoter de 90°", this, [this, composant] {
            scene_->memoriser();
            composant->tourner();
            circuit_modifie();
        });
        menu.addSeparator();
        menu.addAction("Supprimer", this, [this] {
            scene_->memoriser();
            scene_->supprimer_selection();
            circuit_modifie();
        });
    }

    // Ce qui suit est offert QUEL QUE SOIT l'endroit du clic : les outils et
    // la vue. Ils vivaient dans la barre du haut, où ils prenaient de la place
    // sans être souvent employés — et où « Sélection », « Fil » et
    // « Supprimer » se lisaient comme trois boutons de même rang alors que le
    // premier est l'état de repos et les deux autres des gestes.
    if (composant) menu.addSeparator();
    QMenu* outils = menu.addMenu("Outil");
    auto ajouter_outil = [&](const QString& nom, SceneSchema::Outil outil,
                             const QString& raccourci) {
        QAction* action = outils->addAction(
            raccourci.isEmpty() ? nom : nom + "\t" + raccourci);
        action->setCheckable(true);
        action->setChecked(scene_->outil() == outil);
        connect(action, &QAction::triggered, this,
                [this, outil] { choisir_outil(outil); });
    };
    ajouter_outil("Sélection", SceneSchema::Outil::Selection, "Échap");
    ajouter_outil("Suppression", SceneSchema::Outil::Suppression, "Suppr");

    QMenu* vue = menu.addMenu("Vue");
    vue->addAction("Zoom avant\tCtrl+molette", this,
                   [this] { vue_->zoomer(1.25); });
    vue->addAction("Zoom arrière\tCtrl+molette", this,
                   [this] { vue_->zoomer(1.0 / 1.25); });
    vue->addAction("Ajuster à la fenêtre", this, [this] { vue_->ajuster(); });

    menu.addSeparator();
    menu.addAction("Analyse au point de repos", this,
                   &FenetrePrincipale::analyser_point_repos);
    menu.exec(ecran);
}

// ---------------------------------------------------------------------------
void FenetrePrincipale::ecrire(const QString& message) {
    if (!console_) return;
    // Un message répété à l'identique — « le point de repos n'a pas convergé »
    // à chaque pas de temps — remplit le journal de milliers de lignes
    // jumelles et pousse hors de l'écran tout ce qui aurait servi à
    // comprendre. On replie la répétition sur la ligne elle-même.
    if (message == derniere_ligne_ && repetitions_ > 0) {
        ++repetitions_;
        QTextCursor curseur(console_->document());
        curseur.movePosition(QTextCursor::End);
        curseur.select(QTextCursor::BlockUnderCursor);
        curseur.removeSelectedText();
        console_->appendPlainText(
            message + QString("   (× %1)").arg(repetitions_));
        return;
    }
    derniere_ligne_ = message;
    repetitions_ = 1;
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

    // Les scopes posés sur le schéma reçoivent la même liste : c'est elle qui
    // leur permet de nommer les nœuds auxquels ils sont câblés.
    derniers_signaux_ = signaux;
    derniers_libelles_ = libelles;
    // LA CARTE DES APPAREILS SE PURGE AVANT D'ÊTRE LUE.
    //
    // Ses CLÉS sont des composants du schéma. Supprimer un bloc, annuler,
    // ouvrir un autre projet ou en commencer un neuf les détruit — et
    // `depuis_json` les détruit TOUS, même ceux que l'annulation ne
    // concernait pas, puisqu'il reconstruit la scène entière à d'autres
    // adresses. La carte pointait alors dans le vide, et le rapport de
    // mesures lisait un composant mort.
    //
    // C'est la leçon déjà apprise pour les gestes de souris — « ce qui
    // détruit clôt d'abord le geste en cours » — que ce code-ci, écrit
    // après, n'avait pas reçue. `FenetreInstrument` fait de même depuis
    // toujours : elle vérifie que son composant est encore là et se referme
    // sinon.
    const std::vector<ItemComposant*> presents = scene_->composants();
    for (auto it = scopes_.begin(); it != scopes_.end();) {
        const bool vivant =
            std::find(presents.begin(), presents.end(), it->first)
            != presents.end();
        if (vivant) {
            ++it;
            continue;
        }
        it->second->close();
        it->second->deleteLater();
        it = scopes_.erase(it);
    }

    // Tout bloc posé a son appareil, même fenêtre fermée : c'est ce qui lui
    // permet d'enregistrer pendant qu'on ne le regarde pas.
    for (ItemComposant* composant : presents)
        if (composant->modele() && composant->modele()->type == "scope") {
            Oscilloscope* scope = scope_pour(composant);
            if (!scope) continue;
            scope->proposer_signaux(signaux, libelles);
            for (int voie = 0; voie < TraceOscilloscope::kVoies; ++voie) {
                const QString noeud = scene_->noeud_de(composant, voie);
                if (!noeud.isEmpty()) scope->sonder(noeud);
            }
        }

    // Grandeurs balayables : les sources imposent une tension, les résistances
    // une valeur. Ce sont exactement les deux formes de « .dc » de SPICE, et
    // le nom donné ici est celui du composant dans la netlist.
    if (action_annuler_) action_annuler_->setEnabled(scene_->peut_annuler());
    if (action_retablir_) action_retablir_->setEnabled(scene_->peut_retablir());

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
        // La température est balayable comme une source : ngspice la traite
        // de la même façon, et c'est le moyen de voir dériver une CTN ou un
        // transistor.
        analyses_->proposer_sources(generateurs + resistances
                                    + QStringList{"TEMP"});

        // Composants dont une valeur se prête au balayage paramétrique.
        QStringList balayables;
        for (const coeur::Instance& instance : netlist.instances()) {
            std::string propriete;
            if (!coeur::valeur_tolerancee(instance.type, propriete)) continue;
            balayables << QString("%1.%2")
                              .arg(QString::fromStdString(instance.reference),
                                   QString::fromStdString(propriete));
        }
        analyses_->proposer_composants(balayables);
        analyses_->proposer_signaux(signaux, libelles);
    }

    const QStringList cartes = scene_->cartes_presentes();
    // La variante avec les puces : sur ce schéma peuvent cohabiter un Arduino
    // et un ATtiny, et chacun doit être compilé et exécuté pour le sien.
    moteur_->definir_circuit(std::move(netlist), std::move(broches),
                             scene_->cartes_posees());
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

// Le programme proposé à une carte qu'on vient de poser. Il vient du modèle,
// donc du contrôleur : ajouter demain une carte à ATtiny ou un ATmega nu
// n'oblige à toucher ni cette fenêtre ni l'éditeur.
QString FenetrePrincipale::programme_par_defaut(const QString& reference) const {
    for (ItemComposant* composant : scene_->composants()) {
        if (composant->reference() != reference) continue;
        const coeur::Modele* modele = composant->modele();
        if (modele && !modele->programme_exemple.empty())
            return QString::fromStdString(modele->programme_exemple);
        break;
    }
    return QString::fromUtf8(coeur::kSourceExemple);
}

// ---------------------------------------------------------------------------
// Les fichiers d'un programme
//
// Un croquis d'une page tient dans un seul fichier, et c'est le cas courant.
// Dès qu'il grossit, on veut sortir les fonctions communes — et les partager
// entre plusieurs cartes. Les onglets au-dessus de l'éditeur servent à cela.
//
// Les règles sont celles de l'IDE Arduino, rappelées ici parce qu'elles ne
// vont pas de soi : un « .h » est déposé à côté et jamais compilé seul ; un
// « .cpp » est une unité de compilation à part ; un « .ino » est FONDU avec
// le croquis principal, ce qui lui évite d'avoir à déclarer quoi que ce soit.
// ---------------------------------------------------------------------------
coeur::Programme& FenetrePrincipale::programme_de(const QString& carte) {
    auto it = programmes_.find(carte);
    if (it == programmes_.end()) {
        // Nouvelle carte : on lui propose le programme d'exemple plutôt qu'un
        // éditeur vide — et celui de SON contrôleur. Une carte Arduino reçoit
        // un croquis, un microcontrôleur nu reçoit du C sur registres.
        // Le nom du fichier principal suit la puce : « .ino » pour une carte
        // qui reçoit le noyau Arduino, « .c » pour une puce nue.
        std::string mcu = "atmega328p";
        for (ItemComposant* composant : scene_->composants())
            if (composant->reference() == carte && composant->modele()
                && !composant->modele()->mcu.empty()) {
                mcu = composant->modele()->mcu;
                break;
            }
        programmes_[carte] = coeur::Programme{
            {coeur::nom_principal(mcu),
             programme_par_defaut(carte).toStdString()}};
        it = programmes_.find(carte);
    }
    if (it->second.empty())
        it->second.push_back({"principal.ino", std::string()});
    return it->second;
}

void FenetrePrincipale::ranger_editeur() {
    if (carte_courante_.isEmpty() || !editeur_source_) return;
    coeur::Programme& programme = programme_de(carte_courante_);
    const int rang =
        std::min<int>(std::max(fichier_courant_, 0),
                      static_cast<int>(programme.size()) - 1);
    programme[rang].contenu = editeur_source_->toPlainText().toStdString();
}

// Un document par fichier, et non un seul contenu qu'on remplace.
//
// `setPlainText` **efface la pile d'annulation** du document et remet le
// curseur en tête. Passer sur un second onglet puis revenir détruisait donc
// tout l'historique — Ctrl+Z ne rendait plus rien —, et faisait remonter en
// haut du fichier. Même effet à chaque changement de carte, c'est-à-dire en
// permanence dans un TP à deux cartes.
//
// C'est la faute la plus coûteuse qu'un éditeur puisse commettre, parce
// qu'elle est silencieuse : on ne s'en aperçoit qu'au moment où on a besoin
// d'annuler, et il est alors trop tard. Un `QTextDocument` par fichier la
// supprime — et donne au passage le socle propre auquel une coloration
// syntaxique viendra s'attacher, un QSyntaxHighlighter s'accrochant à un
// document.
QTextDocument* FenetrePrincipale::document_de(const QString& carte,
                                              int rang) {
    const QString cle = carte + "/" + QString::number(rang);
    auto it = documents_.find(cle);
    if (it != documents_.end()) return it->second;
    auto* document = new QTextDocument(this);
    document->setDocumentLayout(new QPlainTextDocumentLayout(document));
    documents_[cle] = document;
    return document;
}

void FenetrePrincipale::afficher_fichier(int rang) {
    if (carte_courante_.isEmpty() || !editeur_source_) return;
    coeur::Programme& programme = programme_de(carte_courante_);
    if (rang < 0 || rang >= static_cast<int>(programme.size())) return;
    if (rang != fichier_courant_) ranger_editeur();

    // Où en était le curseur dans le fichier qu'on quitte : le retrouver au
    // retour fait partie de ce qu'on attend d'un éditeur à onglets.
    if (fichier_courant_ >= 0 && !carte_courante_.isEmpty())
        curseurs_[carte_courante_ + "/" + QString::number(fichier_courant_)] =
            editeur_source_->textCursor().position();

    fichier_courant_ = rang;
    const QSignalBlocker silence(editeur_source_);
    QTextDocument* document = document_de(carte_courante_, rang);
    const QString contenu = QString::fromStdString(programme[rang].contenu);
    // On ne réécrit le document que si le texte a changé sous lui — un
    // chargement de projet, un exemple. Le réécrire à chaque bascule
    // reviendrait à effacer l'historique qu'on cherche justement à garder.
    if (document->toPlainText() != contenu) {
        document->setPlainText(contenu);
        document->clearUndoRedoStacks();
    }
    editeur_source_->setDocument(document);

    auto place = curseurs_.find(carte_courante_ + "/" + QString::number(rang));
    if (place != curseurs_.end()) {
        QTextCursor curseur = editeur_source_->textCursor();
        curseur.setPosition(std::min(place->second, document->characterCount() - 1));
        editeur_source_->setTextCursor(curseur);
    }
}

void FenetrePrincipale::rafraichir_onglets_fichiers() {
    if (!onglets_fichiers_) return;
    const QSignalBlocker silence(onglets_fichiers_);
    while (onglets_fichiers_->count() > 0) onglets_fichiers_->removeTab(0);
    if (carte_courante_.isEmpty()) return;
    const coeur::Programme& programme = programme_de(carte_courante_);
    for (size_t rang = 0; rang < programme.size(); ++rang)
        onglets_fichiers_->addTab(
            QString::fromStdString(programme[rang].nom));
    if (fichier_courant_ >= static_cast<int>(programme.size()))
        fichier_courant_ = 0;
    onglets_fichiers_->setCurrentIndex(fichier_courant_);
    // Un programme d'un seul fichier n'a pas besoin d'une barre d'onglets :
    // elle n'apprendrait rien et volerait de la hauteur à l'éditeur.
    onglets_fichiers_->setVisible(programme.size() > 1);
}

void FenetrePrincipale::ajouter_fichier() {
    if (carte_courante_.isEmpty()) return;
    bool valide = false;
    const QString nom =
        QInputDialog::getText(
            this, "Nouveau fichier",
            "Nom du fichier :\n"
            "  « .h »   déclarations, inclus par les autres\n"
            "  « .cpp » code compilé à part\n"
            "  « .ino » onglet de croquis, fondu avec le principal",
            QLineEdit::Normal, "mesure.h", &valide)
            .trimmed();
    if (!valide || nom.isEmpty()) return;
    if (nom.contains('/') || nom.contains('\\')) {
        avertir("Nouveau fichier",
                "Un nom simple est attendu, sans dossier : « mesure.h ».");
        return;
    }
    if (!nom.contains('.')) {
        avertir("Nouveau fichier",
                "Il faut une extension : « .h », « .cpp » ou « .ino ». "
                "C'est elle qui décide comment le fichier est compilé.");
        return;
    }
    ranger_editeur();
    coeur::Programme& programme = programme_de(carte_courante_);
    for (const coeur::Fichier& fichier : programme)
        if (QString::fromStdString(fichier.nom) == nom) {
            avertir("Nouveau fichier", "« " + nom + " » existe déjà.");
            return;
        }
    // Un en-tête neuf reçoit sa garde : l'oublier est l'erreur classique, et
    // elle ne se voit qu'à l'édition de liens.
    const std::string amorce =
        nom.endsWith(".h") || nom.endsWith(".hpp")
            ? "#pragma once\n\n"
            : "";
    programme.push_back({nom.toStdString(), amorce});
    rafraichir_onglets_fichiers();
    afficher_fichier(static_cast<int>(programme.size()) - 1);
    onglets_fichiers_->setCurrentIndex(fichier_courant_);
    ecrire("Fichier ajouté au programme de " + carte_courante_ + " : " + nom);
}

void FenetrePrincipale::retirer_fichier(int rang) {
    if (carte_courante_.isEmpty()) return;
    coeur::Programme& programme = programme_de(carte_courante_);
    if (rang <= 0 || rang >= static_cast<int>(programme.size())) {
        // Le principal ne se retire pas : c'est lui qui porte setup() et
        // loop(), et un programme sans lui n'existe pas.
        avertir("Retirer un fichier",
                "Le fichier principal ne peut pas être retiré.");
        return;
    }
    const QString nom = QString::fromStdString(programme[rang].nom);
    const auto reponse = QMessageBox::question(
        this, "Retirer un fichier",
        "Retirer « " + nom + " » du programme de " + carte_courante_
            + " ?\nSon contenu sera perdu.");
    if (reponse != QMessageBox::Yes) return;
    programme.erase(programme.begin() + rang);
    fichier_courant_ = 0;
    rafraichir_onglets_fichiers();
    afficher_fichier(0);
    ecrire("Fichier retiré : " + nom);
}

void FenetrePrincipale::changer_carte(const QString& reference) {
    if (reference == carte_courante_) return;
    // Le programme affiché appartient à la carte qu'on quitte : on le range
    // avant d'afficher celui de la nouvelle.
    ranger_editeur();
    carte_courante_ = reference;
    fichier_courant_ = 0;
    if (!editeur_source_ || reference.isEmpty()) return;
    rafraichir_onglets_fichiers();
    afficher_fichier(0);
    refleter_langage(reference);
}

// L'onglet annonce dans quel langage on écrit pour la carte affichée. Une
// carte Arduino attend un croquis, un microcontrôleur nu attend du C sur
// registres : le dire évite de chercher pourquoi digitalWrite manque.
void FenetrePrincipale::refleter_langage(const QString& reference) {
    if (!onglets_) return;
    QString langage = "Arduino";
    QString note;
    for (ItemComposant* composant : scene_->composants()) {
        if (composant->reference() != reference) continue;
        const coeur::Modele* modele = composant->modele();
        if (modele && !modele->langage.empty())
            langage = QString::fromStdString(modele->langage);
        if (modele) note = QString::fromStdString(modele->note_langage);
        break;
    }
    // LE LANGAGE VA DANS LE TITRE DE LA FENÊTRE, plus dans un onglet.
    //
    // Cette ligne renommait l'onglet de rang ZÉRO. Le programme parti dans sa
    // propre fenêtre, le rang zéro est devenu le JOURNAL — qui s'est retrouvé
    // intitulé « Programme (Arduino) » tout en affichant des journaux. Le
    // pire des deux mondes : la fonction marchait toujours, et elle mentait.
    if (fenetre_programme_)
        fenetre_programme_->setWindowTitle("Programme de " + reference + " ("
                                           + langage + ") — simulateur");
    // Le titre de l'onglet ne tient que deux mots. Ce qui compte vraiment —
    // quels langages la vraie carte accepte, lequel le simulateur sait
    // compiler, et où les deux divergent — vit dans l'infobulle, et passe une
    // fois par le journal quand on choisit la carte. Une divergence tue
    // (« pourquoi ma temporisation dure deux fois trop ? ») ne doit pas
    // attendre qu'on survole un onglet.
    onglets_->setTabToolTip(0, note);
    if (!note.isEmpty() && note != derniere_note_langage_) {
        derniere_note_langage_ = note;
        ecrire(reference + " — " + langage + " :");
        for (const QString& ligne : note.split('\n'))
            if (!ligne.trimmed().isEmpty()) ecrire("   " + ligne.trimmed());
    }
}

void FenetrePrincipale::afficher_proprietes(ItemComposant* composant) {
    selection_ = composant;
    while (formulaire_->rowCount() > 0) formulaire_->removeRow(0);

    if (!composant || !composant->modele()) {
        formulaire_->addRow(new QLabel("Sélectionnez un composant."));
        // Rien à montrer : le panneau rend sa place au schéma. Il ne se cache
        // que sur la page du schéma — sur celle du circuit imprimé il est
        // déjà masqué par le changement de page, et le rappeler ici ferait
        // clignoter la disposition à chaque désélection.
        if (dock_proprietes_ && page_courante_ == 0) dock_proprietes_->hide();
        return;
    }
    if (dock_proprietes_ && page_courante_ == 0) dock_proprietes_->show();
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
                auto* champ = new ChampValeur(propriete.unite);
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
    scene_->oublier_historique();
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
    // Le schéma sait s'écrire lui-même : la fenêtre n'ajoute que ce qu'elle
    // est seule à connaître, les programmes de chaque carte.
    QJsonObject racine = scene_->vers_json();
    ranger_editeur();
    // Chaque carte a ses fichiers, dans l'ordre — le premier est le principal,
    // et cet ordre doit survivre à l'enregistrement. Un objet JSON ne garantit
    // pas l'ordre de ses clés : c'est donc un tableau.
    QJsonObject programmes;
    for (const auto& paire : programmes_) {
        QJsonArray fichiers;
        for (const coeur::Fichier& fichier : paire.second) {
            QJsonObject entree;
            entree["nom"] = QString::fromStdString(fichier.nom);
            entree["contenu"] = QString::fromStdString(fichier.contenu);
            fichiers.append(entree);
        }
        programmes[paire.first] = fichiers;
    }
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
    // ON REGARDE L'ERREUR D'ANALYSE, et c'est tout ce qui manquait.
    //
    // Sans ce contrôle, un fichier tronqué donnait un objet VIDE, que
    // `depuis_json` relisait consciencieusement : il commence par tout
    // effacer, puis ne trouve rien à reposer. Le schéma en cours — non
    // enregistré, peut-être — disparaissait, et la fonction rendait « vrai »
    // en écrivant « Schéma ouvert » dans le journal.
    //
    // Une perte silencieuse annoncée comme un succès est pire qu'un
    // plantage : le plantage, au moins, on le raconte.
    QJsonParseError erreur;
    const QJsonDocument document =
        QJsonDocument::fromJson(fichier.readAll(), &erreur);
    if (erreur.error != QJsonParseError::NoError || !document.isObject()) {
        avertir("Ouverture",
                "Ce fichier n'est pas un projet lisible : "
                    + erreur.errorString()
                    + ".\nLe schéma en cours n'a pas été touché.");
        return false;
    }
    const QJsonObject racine = document.object();
    scene_->depuis_json(racine);
    scene_->oublier_historique();

    // Les programmes de l'ancien projet ne doivent pas déborder sur le
    // nouveau : on repart d'une table vide.
    programmes_.clear();
    carte_courante_.clear();
    const QJsonObject programmes = racine["programmes"].toObject();
    for (auto it = programmes.begin(); it != programmes.end(); ++it) {
        coeur::Programme programme;
        if (it.value().isArray()) {
            for (const QJsonValue& valeur : it.value().toArray()) {
                const QJsonObject entree = valeur.toObject();
                programme.push_back(
                    {entree["nom"].toString().toStdString(),
                     entree["contenu"].toString().toStdString()});
            }
        } else {
            // Projet d'une version antérieure : le programme était une seule
            // chaîne. On le reprend tel quel, sous un nom de principal.
            programme.push_back({"principal.ino",
                                 it.value().toString().toStdString()});
        }
        if (!programme.empty()) programmes_[it.key()] = std::move(programme);
    }
    if (programmes_.empty() && racine.contains("programme")) {
        // Fichier plus ancien encore : un seul programme, pour la première
        // carte, et pas même de table.
        const QStringList cartes = scene_->cartes_presentes();
        if (!cartes.isEmpty())
            programmes_[cartes.first()] = coeur::Programme{
                {"principal.ino", racine["programme"].toString().toStdString()}};
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
    ranger_editeur();
    ecrire("Programme ouvert : " + chemin);
}

void FenetrePrincipale::compiler_source() { compiler_programme(); }

// Compile le programme de la carte courante et dit si ça a marché.
//
// `silence_si_reussi` sert au lancement : quand on appuie sur « Lancer », la
// compilation est un moyen, pas un but — on ne veut pas d'une ligne de succès
// à chaque essai. L'échec, lui, se dit toujours.
bool FenetrePrincipale::compiler_programme(bool silence_si_reussi) {
    QString compte_rendu;
    ranger_editeur();
    // Le programme est nommé plutôt que construit dans l'appel. Un ternaire
    // entre un temporaire et une référence produit une copie anonyme, et gcc
    // le signale — « dangling pointer to an unnamed temporary ». La durée de
    // vie est en fait correcte, mais une variable nommée l'est aussi et ne
    // demande à personne de le vérifier.
    coeur::Programme a_compiler;
    if (carte_courante_.isEmpty())
        a_compiler.push_back(
            {"principal.ino", editeur_source_->toPlainText().toStdString()});
    else
        a_compiler = programme_de(carte_courante_);
    const bool ok = moteur_->compiler_et_charger(a_compiler, dossier_travail(),
                                                 &compte_rendu, carte_courante_);
    if (!compte_rendu.trimmed().isEmpty()) ecrire(compte_rendu.trimmed());
    if (ok) {
        if (!silence_si_reussi) ecrire("Compilation réussie.");
        return ok;
    }

    // PAS DE BOÎTE MODALE.
    //
    // Elle passait le compte rendu entier d'avr-g++ à une QMessageBox non
    // redimensionnable, qu'il fallait fermer pour regarder le code dont elle
    // parlait. Or c'est exactement le moment où l'on veut avoir les deux sous
    // les yeux. Le compte rendu est déjà dans le journal, à côté de
    // l'éditeur, et il y est maintenant cliquable.
    ecrire("Échec de la compilation.");
    const std::vector<ErreurCompilation> erreurs =
        analyser_sortie_compilateur(compte_rendu);
    int nombre = 0;
    for (const ErreurCompilation& e : erreurs)
        if (e.erreur) ++nombre;
    if (nombre > 0)
        ecrire(QString("%1 erreur%2 — double-cliquez une ligne ci-dessus pour "
                       "aller au code fautif.")
                   .arg(nombre)
                   .arg(nombre > 1 ? "s" : ""));
    montrer_onglet("Journal");
    for (QDockWidget* dock : docks_schema_)
        if (dockWidgetArea(dock) == Qt::BottomDockWidgetArea && !dock->isVisible())
            dock->setVisible(true);
    return ok;
}

// ---------------------------------------------------------------------------
MoteurSimulation::Etat FenetrePrincipale::etat_simulation() const {
    return moteur_->etat();
}

void FenetrePrincipale::definir_programme_affiche(const QString& source) {
    if (editeur_source_) editeur_source_->setPlainText(source);
    ranger_editeur();
}

void FenetrePrincipale::lancer() {
    circuit_modifie();

    // S'il y a une carte, « Lancer » compile d'abord.
    //
    // Appuyer sur Lancer et voir la carte rester inerte parce qu'on a oublié
    // F5 est la perte de temps la plus banale d'une séance : rien à l'écran
    // ne distingue « le programme est faux » de « le programme n'est pas
    // chargé ». Lancer suffit donc désormais.
    //
    // Et si le programme ne compile PAS, on ne lance pas. Démarrer sur un
    // firmware absent ou périmé ferait chercher dans le montage une erreur
    // qui est dans le code — c'est exactement le faux problème qu'on veut
    // épargner. La reprise après une pause est exemptée : le programme
    // tourne déjà, il n'y a rien à recompiler.
    const bool reprise = moteur_->etat() == MoteurSimulation::Etat::EnPause;
    if (!reprise && !moteur_->cartes().isEmpty()) {
        if (!compiler_programme(/*silence_si_reussi=*/true)) {
            ecrire("Simulation non lancée : le programme ne compile pas. "
                   "Corrigez-le, puis relancez.");
            montrer_onglet("Journal");     // là où l'erreur est écrite
            return;
        }
    }

    for (auto& paire : scopes_) paire.second->sonder_par_defaut();
    moteur_->demarrer();
}

void FenetrePrincipale::definir_base_temps(double secondes) {
    for (auto& paire : scopes_) paire.second->definir_base_temps(secondes);
}

double FenetrePrincipale::vitesse() const { return moteur_->vitesse(); }

QString FenetrePrincipale::mesures_oscilloscope() const {
    // Le rapport de TOUS les blocs, chacun précédé de sa référence. Sans le
    // nom, deux scopes rendraient deux blocs de chiffres indiscernables.
    // ON NE LIT JAMAIS UNE CLÉ QUI N'EST PLUS DANS LA SCÈNE.
    //
    // La purge de `circuit_modifie` ne suffit pas : elle est déclenchée par
    // `QGraphicsScene::changed`, que Qt émet en DIFFÉRÉ, à la fin de la boucle
    // d'événements. Entre la suppression d'un bloc et le tour suivant de cette
    // boucle, la carte contient donc encore un composant détruit — et c'est
    // précisément l'instant où l'on peut demander les mesures.
    //
    // Comparer un pointeur ne le déréférence pas : le test est sûr même sur
    // une clé morte. Ce qui ne l'est pas, c'est de lui demander sa référence.
    const std::vector<ItemComposant*> presents = scene_->composants();
    QStringList morceaux;
    for (const auto& paire : scopes_) {
        if (std::find(presents.begin(), presents.end(), paire.first)
            == presents.end())
            continue;
        const QString rapport = paire.second->rapport();
        if (rapport.isEmpty()) continue;
        morceaux << paire.first->reference() + " :\n" + rapport;
    }
    return morceaux.join('\n');
}

void FenetrePrincipale::afficher_onglet(int rang) {
    if (onglets_ && rang >= 0 && rang < onglets_->count())
        onglets_->setCurrentIndex(rang);
}

// UN ONGLET SE DÉSIGNE PAR SON NOM, PAS PAR SON RANG.
//
// Les rangs étaient écrits en dur — « setCurrentIndex(2) // onglet Contrôle ».
// Sortir le programme du bandeau les a tous décalés d'un cran d'un seul coup,
// et un commentaire qui dit « Contrôle » à côté d'un 2 qui désigne le
// moniteur série est pire que pas de commentaire : il se lit comme une
// garantie. Le nom, lui, ne glisse pas.
bool FenetrePrincipale::programme_est_ouvert() const {
    return fenetre_programme_ && fenetre_programme_->isVisible();
}

QString FenetrePrincipale::titre_programme() const {
    return fenetre_programme_ ? fenetre_programme_->windowTitle() : QString();
}

void FenetrePrincipale::montrer_onglet(const QString& titre) {
    if (!onglets_) return;
    for (int rang = 0; rang < onglets_->count(); ++rang)
        if (onglets_->tabText(rang) == titre) {
            onglets_->setCurrentIndex(rang);
            break;
        }
    // Le bandeau peut avoir été replié : l'onglet ne servirait à rien caché.
    for (QDockWidget* dock : docks_schema_)
        if (dockWidgetArea(dock) == Qt::BottomDockWidgetArea
            && !dock->isVisible())
            dock->setVisible(true);
}

int FenetrePrincipale::onglet_courant() const {
    return onglets_ ? onglets_->currentIndex() : -1;
}

QString FenetrePrincipale::titre_onglet_courant() const {
    return onglets_ ? onglets_->tabText(onglets_->currentIndex()) : QString();
}

QString FenetrePrincipale::programme_affiche() const {
    return editeur_source_ ? editeur_source_->toPlainText() : QString();
}

void FenetrePrincipale::suspendre() { moteur_->suspendre(); }

void FenetrePrincipale::arreter() {
    moteur_->arreter();
    scene_->effacer_resultats();
    for (auto& paire : scopes_) paire.second->vider();
    for (auto& paire : scopes_) paire.second->vider();
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

// Le gain d'un Bode n'a de sens que rapporté à l'entrée : c'est le nœud
// attaqué par le générateur, et il sert aussi de référence aux campagnes.
QString FenetrePrincipale::noeud_generateur() const {
    for (const coeur::Instance& instance : moteur_->netlist().instances()) {
        const coeur::Modele* modele =
            coeur::Catalogue::instance().modele(instance.type);
        if (!modele || !modele->generateur) continue;
        if (const coeur::Borne* borne = instance.borne("+"))
            return QString::fromStdString(borne->noeud);
    }
    return {};
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

// ---------------------------------------------------------------------------
// Le panneau « Contrôle »
// ---------------------------------------------------------------------------
void FenetrePrincipale::remplir_controle(
    const std::vector<coeur::Anomalie>& anomalies) {
    if (!panneau_controle_) return;
    const QSignalBlocker silence(panneau_controle_);
    panneau_controle_->clear();

    for (const coeur::Anomalie& anomalie : anomalies) {
        auto* ligne = new QTreeWidgetItem(panneau_controle_);
        const bool erreur =
            anomalie.gravite == coeur::Anomalie::Gravite::Erreur;
        ligne->setText(0, erreur ? "Erreur" : "Avertissement");
        ligne->setForeground(0, erreur ? QColor(198, 40, 40)
                                       : QColor(180, 83, 9));
        // Une anomalie sans référence — « aucune masse » — n'a pas de
        // coupable : le dire plutôt que laisser une case vide, qui ferait
        // croire à un défaut d'affichage.
        QString ou = QString::fromStdString(anomalie.reference);
        if (ou.isEmpty()) {
            ou = "tout le montage";
        } else if (!ou.contains(',')) {
            // « D13 » ressemble à une référence de composant et n'en est pas
            // une : c'est un nom de NŒUD. Sans le dire, on envoie l'élève
            // chercher sur son schéma un composant qui n'existe pas. On ne
            // devine pas la nature du nom — on demande à la scène si un
            // composant le porte.
            bool est_un_composant = false;
            for (ItemComposant* composant : scene_->composants())
                if (composant->reference() == ou) est_un_composant = true;
            if (!est_un_composant) ou = "nœud " + ou;
        }
        ligne->setText(1, ou);
        // Le remède à l'impératif est ce qu'on vient chercher ; le message
        // explique pourquoi, et le survol le donne en entier.
        ligne->setText(2, anomalie.remede.empty()
                              ? QString::fromStdString(anomalie.message)
                              : QString::fromStdString(anomalie.remede));
        ligne->setToolTip(2, QString::fromStdString(anomalie.message));
        ligne->setData(0, Qt::UserRole,
                       QString::fromStdString(anomalie.reference));
    }
    for (int colonne = 0; colonne < 2; ++colonne)
        panneau_controle_->resizeColumnToContents(colonne);
}

bool FenetrePrincipale::atteindre_anomalie(const QString& reference) {
    if (reference.trimmed().isEmpty()) return false;
    afficher_page(0);   // le schéma, pas la carte
    const QRectF cadre = scene_->designer_anomalie(reference);
    if (cadre.isNull()) {
        ecrire("« " + reference
               + " » ne désigne rien de posé sur le schéma : l'anomalie porte "
                 "sur le montage entier.");
        return false;
    }
    // Cadrer sans changer d'échelle : un zoom qui saute à chaque clic ferait
    // perdre le repère qu'on vient de se construire.
    vue_->centerOn(cadre.center());
    vue_->setFocus();
    return true;
}

// ---------------------------------------------------------------------------
// Aller à la ligne fautive
// ---------------------------------------------------------------------------
std::vector<FenetrePrincipale::ErreurCompilation>
FenetrePrincipale::analyser_sortie_compilateur(const QString& sortie) {
    std::vector<ErreurCompilation> erreurs;

    // Le nom de fichier est pris NON GOURMAND et sans deux-points : un chemin
    // Windows commence par « C:\ », et une expression gourmande y couperait à
    // la mauvaise place. Les `#line` ne produisent de toute façon que des
    // noms d'onglet, mais un message venant d'un en-tête du noyau Arduino
    // porte, lui, un vrai chemin.
    //
    // Les deux langues sont acceptées : le compilateur suit la locale, et
    // celle d'une salle de classe française n'est pas celle du conteneur qui
    // fait tourner le banc.
    static const QRegularExpression motif(
        R"(^\s*([^:\n]+(?::[^:\n]*[^:\d\n][^:\n]*)?):(\d+)(?::(\d+))?:\s*)"
        R"((erreur fatale|fatal error|erreur|error|attention|warning|note)\s*:\s*(.*)$)",
        QRegularExpression::CaseInsensitiveOption);

    for (const QString& ligne : sortie.split('\n')) {
        const QRegularExpressionMatch trouve = motif.match(ligne);
        if (!trouve.hasMatch()) continue;
        ErreurCompilation erreur;
        erreur.fichier = trouve.captured(1).trimmed();
        erreur.ligne = trouve.captured(2).toInt();
        erreur.colonne = trouve.captured(3).toInt();   // 0 si absente
        const QString genre = trouve.captured(4).toLower();
        erreur.erreur = genre.contains("err");
        erreur.message = trouve.captured(5).trimmed();
        // Une « note » n'est pas un défaut : c'est le complément de celui qui
        // précède. La retenir doublerait le nombre de lignes cliquables sans
        // ajouter un seul endroit à corriger.
        if (genre == "note") continue;
        if (erreur.ligne <= 0) continue;
        erreurs.push_back(erreur);
    }
    return erreurs;
}

bool FenetrePrincipale::aller_a_erreur(const ErreurCompilation& erreur) {
    if (carte_courante_.isEmpty() || !editeur_source_) return false;
    const coeur::Programme& programme = programme_de(carte_courante_);

    // Le compilateur nomme l'onglet grâce aux `#line` ; un en-tête inclus,
    // lui, porte un chemin complet. On compare donc sur le nom seul.
    const QString cible = QFileInfo(erreur.fichier).fileName();
    int rang = -1;
    for (size_t k = 0; k < programme.size(); ++k)
        if (QString::fromStdString(programme[k].nom) == cible)
            rang = static_cast<int>(k);
    if (rang < 0) return false;

    // L'erreur montre le PROGRAMME : sa fenêtre, désormais.
    if (fenetre_programme_) {
        fenetre_programme_->show();
        fenetre_programme_->raise();
    }
    for (QDockWidget* dock : docks_schema_)
        if (dockWidgetArea(dock) == Qt::BottomDockWidgetArea && !dock->isVisible())
            dock->setVisible(true);
    afficher_fichier(rang);
    if (onglets_fichiers_) {
        const QSignalBlocker silence(onglets_fichiers_);
        onglets_fichiers_->setCurrentIndex(rang);
    }

    // Le numéro de ligne peut être PÉRIMÉ.
    //
    // On compile, on obtient une erreur ligne 500, on corrige, le fichier
    // n'en fait plus que dix — et la ligne d'erreur reste affichée dans le
    // journal, cliquable. `movePosition` rend alors faux mais laisse le
    // curseur sur le DERNIER bloc, sans rien dire : on sélectionnait la fin
    // du fichier en la présentant comme « la ligne fautive ».
    const int lignes = editeur_source_->document()->blockCount();
    if (erreur.ligne > lignes) {
        ecrire(QString("Ligne %1 : ce fichier n'en compte plus que %2. "
                       "Recompilez (F5) — cette erreur date d'avant vos "
                       "dernières corrections.")
                   .arg(erreur.ligne)
                   .arg(lignes));
        return false;
    }

    QTextCursor curseur = editeur_source_->textCursor();
    curseur.movePosition(QTextCursor::Start);
    curseur.movePosition(QTextCursor::Down, QTextCursor::MoveAnchor,
                         erreur.ligne - 1);
    if (erreur.colonne > 1) {
        // avr-g++ compte les colonnes en OCTETS, Qt déplace le curseur en
        // CARACTÈRES. Les deux ne coïncident que sur de l'ASCII pur — et ce
        // projet est écrit en français : un seul « é » avant l'erreur, et le
        // curseur tombe un caractère trop loin. Vérifié sur avr-g++ 7.3.0 :
        // pour `const char* s = "café"; foo_inexistant(x);` il annonce la
        // colonne 28 là où Qt compte 27.
        //
        // On tronque donc la ligne au bon nombre d'OCTETS, puis on redécode :
        // le compte de caractères qui en sort est celui que Qt attend.
        const QByteArray brut = curseur.block().text().toUtf8();
        const int octets = std::min(erreur.colonne - 1,
                                    static_cast<int>(brut.size()));
        const int caracteres = QString::fromUtf8(brut.left(octets)).size();
        if (caracteres > 0)
            curseur.movePosition(QTextCursor::Right, QTextCursor::MoveAnchor,
                                 caracteres);
    }
    // Sélectionner la ligne entière : sur un vidéo-projecteur, un curseur
    // clignotant d'un pixel ne se voit pas du fond de la salle.
    curseur.movePosition(QTextCursor::EndOfLine, QTextCursor::KeepAnchor);
    editeur_source_->setTextCursor(curseur);
    editeur_source_->centerCursor();
    editeur_source_->setFocus();
    return true;
}

// Le cartouche — À L'IMPRESSION SEULEMENT.
//
// Rien de nouveau n'apparaît à l'écran : la place y est trop précieuse, et
// l'information qu'il porte ne sert qu'une fois la feuille détachée du
// logiciel. C'est sur le papier qu'elle manque — trente copies de TP sans
// nom d'auteur ne sont pas corrigeables, et le professeur n'a aucun moyen
// de les rattacher après coup.
//
// Le champ « Nom » reste tracé même vide : une ligne à remplir à la main
// vaut mieux qu'une absence, puisqu'une feuille anonyme est le défaut qu'on
// cherche à supprimer.
void FenetrePrincipale::dessiner_cartouche(QPainter* peintre,
                                           const QRectF& bandeau) const {
    peintre->save();
    peintre->setRenderHint(QPainter::Antialiasing, true);
    const double trait = std::max(1.0, bandeau.height() / 90.0);
    peintre->setPen(QPen(QColor(40, 40, 40), trait));
    peintre->setBrush(Qt::NoBrush);
    peintre->drawRect(bandeau);

    // Trois colonnes, comme sur un cartouche de dessin technique : ce qu'on
    // regarde (le titre), qui l'a fait, et quand.
    const double colonne = bandeau.width() / 3.0;
    for (int k = 1; k < 3; ++k)
        peintre->drawLine(QPointF(bandeau.left() + k * colonne, bandeau.top()),
                          QPointF(bandeau.left() + k * colonne,
                                  bandeau.bottom()));

    QFont police = peintre->font();
    police.setPointSizeF(std::max(5.0, bandeau.height() / 5.5));
    peintre->setFont(police);

    const QString titre = chemin_projet_.isEmpty()
                              ? QString("Schéma sans titre")
                              : QFileInfo(chemin_projet_).completeBaseName();
    const QString auteur =
        reglages_disposition().value("cartouche/auteur").toString();

    const struct { const char* etiquette; QString valeur; } cases[3] = {
        {"Montage", titre},
        {"Nom", auteur},
        {"Date", QDate::currentDate().toString("dd/MM/yyyy")}};

    for (int k = 0; k < 3; ++k) {
        const QRectF boite(bandeau.left() + k * colonne, bandeau.top(), colonne,
                           bandeau.height());
        const QRectF interieur = boite.adjusted(bandeau.height() / 4.0, 0,
                                                -bandeau.height() / 8.0, 0);
        QFont petite = police;
        petite.setPointSizeF(police.pointSizeF() * 0.72);
        peintre->setFont(petite);
        peintre->setPen(QPen(QColor(110, 110, 110), trait));
        peintre->drawText(interieur, Qt::AlignLeft | Qt::AlignTop,
                          QString(cases[k].etiquette));
        peintre->setFont(police);
        peintre->setPen(QPen(QColor(20, 20, 20), trait));
        peintre->drawText(interieur, Qt::AlignLeft | Qt::AlignBottom,
                          cases[k].valeur);
        // Le trait à remplir à la main, quand la case est vide.
        if (cases[k].valeur.isEmpty()) {
            const double y = boite.bottom() - bandeau.height() / 5.0;
            peintre->setPen(QPen(QColor(150, 150, 150), trait,
                                 Qt::DashLine));
            peintre->drawLine(QPointF(interieur.left(), y),
                              QPointF(interieur.right(), y));
        }
    }
    peintre->restore();
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
        // Le schéma se rend au-dessus du bandeau, pas par-dessus : un
        // cartouche qui recouvre le montage qu'il décrit ne vaut rien.
        const QRectF page(0, 0, peintre.device()->width(),
                          peintre.device()->height());
        const double hauteur = std::min(page.height() * 0.08, page.width() / 12.0);
        const QRectF bandeau(page.left(), page.bottom() - hauteur, page.width(),
                             hauteur);
        scene_->render(&peintre,
                       page.adjusted(0, 0, 0, -hauteur - page.height() * 0.01),
                       zone, Qt::KeepAspectRatio);
        dessiner_cartouche(&peintre, bandeau);
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





// Deux programmes distincts : c'est le propre du montage à deux cartes.





}  // namespace

void FenetrePrincipale::charger_exemple(Exemple exemple) {
    // Changer d'exemple pendant que ça tourne laissait la simulation en
    // marche sur un schéma qui n'existe plus : le bouton disait « Pause »,
    // l'horloge avançait, et l'on regardait un montage neuf animé par
    // l'ancien. On arrête d'abord.
    arreter();
    scene_->tout_effacer();
    scene_->oublier_historique();
    chemin_projet_.clear();

    if (exemple == Exemple::DeuxCartes) {
        charger_exemple_deux_cartes();
        return;
    }
    if (exemple == Exemple::FiltreRC) {
        charger_exemple_filtre();
        return;
    }
    if (exemple == Exemple::Registre) {
        charger_exemple_registre();
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
            // L'OSCILLOSCOPE EST POSÉ D'AVANCE, câblé sur la broche qui
            // clignote. C'est le seul oscilloscope du logiciel désormais, et
            // un instrument qu'il faut penser à chercher dans un catalogue
            // n'existe pas pour un débutant. Double-clic dessus pour le voir.
            if (ItemComposant* scope =
                    scene_->ajouter_composant("scope", QPointF(140, 170)))
                scene_->addItem(
                    new ItemFil(carte, borne_nommee("D13"), scope, 0));
            programme = QString::fromUtf8(coeur::kSourceExemple);
            ecrire("Exemple : clignotant sur D13 (LED rouge + 220 Ω), avec un "
                   "oscilloscope câblé — double-cliquez dessus.");
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
            programme = QString::fromUtf8(coeur::kProgrammeBouton);
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
            programme = QString::fromUtf8(coeur::kProgrammePotentiometre);
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
            programme = QString::fromUtf8(coeur::kProgrammePwm);
            ecrire("Exemple : PWM matérielle sur D9, rapport cyclique variable.");
            ecrire("Ouvrez l'onglet Oscilloscope : base de temps 5 ms pour le "
                   "créneau, 2 s pour l'enveloppe.");
            break;
        }
        case Exemple::DeuxCartes:
        case Exemple::FiltreRC:
        case Exemple::Registre:
            return;   // traités à part : ces schémas n'ont pas une seule carte
        case Exemple::Servo: {
            ItemComposant* servo = scene_->ajouter_composant("servomoteur", QPointF(120, 0));
            ItemComposant* alim = scene_->ajouter_composant("alim5v", QPointF(20, -140));
            ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(20, 160));
            if (!servo || !alim || !masse) return;
            scene_->addItem(new ItemFil(carte, borne_nommee("D9"), servo, 2));
            scene_->addItem(new ItemFil(alim, 0, servo, 0));
            scene_->addItem(new ItemFil(servo, 1, masse, 0));
            programme = QString::fromUtf8(coeur::kProgrammeServo);
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
            programme = QString::fromUtf8(coeur::kProgrammeMoteur);
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
            programme = QString::fromUtf8(coeur::kProgrammeTransistor);
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
    programmes_[carte->reference()] =
        coeur::Programme{{"principal.ino", programme.toStdString()}};
    carte_courante_.clear();
    changer_carte(carte->reference());

    vue_->ajuster();
    ecrire("Compilez le programme (F5) puis lancez la simulation.");
}

// Le clignotant de N'IMPORTE QUELLE carte.
//
// Cinq cartes portaient déjà leur programme de démarrage dans le catalogue
// (`Modele::programme_exemple`, écrit ET compilé par le banc d'essai), et
// aucune n'était atteignable depuis le menu : il fallait poser la carte à la
// main, puis deviner qu'un double-clic dessus chargeait son programme. Le
// travail était fait ; il manquait le branchement.
//
// Ce qui change d'une carte à l'autre tient en un nom de broche — la LED est
// sur D13 chez Arduino, PB5 sur un ATmega nu, PB1 sur un ATtiny85, GP25 sur
// un Pico, PC13 sur une Blue Pill, GPIO2 sur un DevKit ESP32. Tout le reste
// est commun, d'où une seule fonction plutôt que huit.
void FenetrePrincipale::charger_clignotant_carte(const QString& type,
                                                 const QString& broche) {
    arreter();
    scene_->tout_effacer();
    scene_->oublier_historique();
    chemin_projet_.clear();
    programmes_.clear();
    carte_courante_.clear();

    ItemComposant* carte = scene_->ajouter_composant(type, QPointF(-320, 0));
    if (!carte) return;

    int rang = -1;
    for (int k = 0; k < carte->nb_bornes(); ++k)
        if (carte->nom_borne(k) == broche) rang = k;
    if (rang < 0) {
        // La carte est posée avec son programme : c'est déjà mieux que rien.
        // Mais on le DIT, plutôt que de livrer un montage muet dont l'élève
        // croirait qu'il est complet.
        ecrire("La broche « " + broche + " » n'existe pas sur cette carte : "
               "la LED n'a pas été câblée. Câblez-la à la main.");
    } else {
        ItemComposant* led = scene_->ajouter_composant("led", QPointF(60, -130));
        ItemComposant* r = scene_->ajouter_composant("resistance", QPointF(190, -130));
        ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(300, -40));
        if (led && r && masse) {
            // 220 Ω sous 5 V, 100 Ω sous 3,3 V : c'est le calcul du cours, et
            // livrer la mauvaise valeur sur une carte 3,3 V enseignerait une
            // erreur au lieu de la corriger.
            r->valeurs["ohms"] =
                carte->modele() && carte->modele()->tension_logique < 4.0 ? 100
                                                                          : 220;
            scene_->addItem(new ItemFil(carte, rang, led, 0));
            scene_->addItem(new ItemFil(led, 1, r, 0));
            scene_->addItem(new ItemFil(r, 1, masse, 0));

            // UN OSCILLOSCOPE POSÉ D'AVANCE, câblé sur la broche qui clignote.
            //
            // Deux raisons, et la seconde vaut la première :
            //
            //   - il se DÉCOUVRE. C'est le seul oscilloscope du logiciel
            //     désormais, et un instrument qu'il faut d'abord penser à
            //     chercher dans un catalogue n'existe pas pour un débutant ;
            //   - il rend la vérification automatique VÉRIFIABLE. Le contrôle
            //     de `--capture` lit le rapport des scopes : sans aucun bloc
            //     sur le schéma, il ne lisait plus rien et restait vert en ne
            //     prouvant rien — exactement le défaut qu'on traque partout
            //     ailleurs dans ce projet.
            ItemComposant* scope =
                scene_->ajouter_composant("scope", QPointF(300, 150));
            if (scope) scene_->addItem(new ItemFil(carte, rang, scope, 0));
        }
    }

    circuit_modifie();
    // Le nom du fichier suit la puce : un croquis Arduino porte « .ino », une
    // puce nue porte « .c ». Ce n'est pas cosmétique — c'est l'extension qui
    // décide si le noyau Arduino est fondu dans la compilation.
    const std::string mcu =
        carte->modele() ? carte->modele()->mcu : std::string("atmega328p");
    programmes_[carte->reference()] = coeur::Programme{
        {coeur::nom_principal(mcu), programme_par_defaut(carte->reference())
                                        .toStdString()}};
    carte_courante_.clear();
    changer_carte(carte->reference());
    vue_->ajuster();
    ecrire("Compilez le programme (F5) puis lancez la simulation.");
}

// Deux cartes : le schéma se construit à part, parce qu'il ne repose pas sur
// la carte unique posée par charger_exemple().
void FenetrePrincipale::charger_exemple_deux_cartes() {
    scene_->tout_effacer();
    scene_->oublier_historique();
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
    programmes_[u1->reference()] =
        coeur::Programme{{"principal.ino", coeur::kProgrammeEmetteur}};
    programmes_[u2->reference()] =
        coeur::Programme{{"principal.ino", coeur::kProgrammeRecepteur}};
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
// Le pont diviseur : la figure que le cours pose AVANT le potentiomètre.
//
// `cours/03-arduino.md` §3.2 l'introduit comme « la base de toute entrée
// analogique » — le convertisseur ne sait lire qu'une tension, et c'est le
// pont qui transforme une résistance variable en tension. Le simulateur
// n'en montrait aucun : le seul « pont » du menu passait par un
// potentiomètre, ce qui est le montage SUIVANT, pas celui-là.
void FenetrePrincipale::charger_exemple_pont_diviseur() {
    arreter();
    scene_->tout_effacer();
    scene_->oublier_historique();
    chemin_projet_.clear();
    programmes_.clear();
    carte_courante_.clear();

    ItemComposant* alim = scene_->ajouter_composant("alim5v", QPointF(-200, -180));
    ItemComposant* r1 = scene_->ajouter_composant("resistance", QPointF(-200, -60));
    ItemComposant* r2 = scene_->ajouter_composant("resistance", QPointF(-200, 100));
    ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(-200, 220));
    ItemComposant* vm = scene_->ajouter_composant("voltmetre", QPointF(60, 20));
    if (!alim || !r1 || !r2 || !masse || !vm) return;

    // 10 kΩ et 10 kΩ : le cas le plus lisible, la moitié de la tension. Un
    // élève qui change une des deux valeurs voit la formule marcher.
    r1->valeurs["ohms"] = 10000;
    r2->valeurs["ohms"] = 10000;
    r1->setRotation(90);
    r2->setRotation(90);

    scene_->addItem(new ItemFil(alim, 0, r1, 0));
    scene_->addItem(new ItemFil(r1, 1, r2, 0));
    scene_->addItem(new ItemFil(r2, 1, masse, 0));
    scene_->addItem(new ItemFil(r1, 1, vm, 0));
    scene_->addItem(new ItemFil(vm, 1, masse, 0));

    circuit_modifie();
    vue_->ajuster();
    ecrire("Exemple : pont diviseur, deux résistances de 10 kΩ sous 5 V.");
    ecrire("Le voltmètre doit lire 2,50 V — soit U × R2/(R1+R2). Changez R2 "
           "pour 20 kΩ et la lecture passe à 3,33 V.");
    ecrire("C'est le montage qui est derrière TOUTE entrée analogique : le "
           "convertisseur ne sait lire qu'une tension.");
}

// Le régulateur Zener : le composant le plus soigneusement corrigé du dépôt,
// et qui n'avait aucune vitrine.
//
// Son modèle a été repris de `diotemp.c` de ngspice après qu'un modèle écrit
// de mémoire eut donné le coude 29 mV trop bas et la mauvaise pente (voir
// ETAT.md, défaut 7). Ce travail ne servait à rien tant qu'aucun exemple ne
// le donnait à voir.
void FenetrePrincipale::charger_exemple_zener() {
    arreter();
    scene_->tout_effacer();
    scene_->oublier_historique();
    chemin_projet_.clear();
    programmes_.clear();
    carte_courante_.clear();

    ItemComposant* pile = scene_->ajouter_composant("pile", QPointF(-260, 20));
    ItemComposant* rs = scene_->ajouter_composant("resistance", QPointF(-80, -120));
    ItemComposant* dz = scene_->ajouter_composant("zener", QPointF(80, 20));
    ItemComposant* charge = scene_->ajouter_composant("resistance", QPointF(240, 20));
    ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(0, 220));
    ItemComposant* vm = scene_->ajouter_composant("voltmetre", QPointF(400, 20));
    if (!pile || !rs || !dz || !charge || !masse || !vm) return;

    pile->valeurs["volts"] = 12;
    rs->valeurs["ohms"] = 470;      // résistance de ballast
    charge->valeurs["ohms"] = 2200;
    // La Zener se monte EN INVERSE : cathode vers le +, anode vers la masse.
    // C'est tout l'objet du montage, et l'inverser est l'erreur classique.
    dz->setRotation(90);
    charge->setRotation(90);

    scene_->addItem(new ItemFil(pile, 0, rs, 0));
    scene_->addItem(new ItemFil(rs, 1, dz, 1));       // ballast -> cathode
    scene_->addItem(new ItemFil(rs, 1, charge, 0));
    scene_->addItem(new ItemFil(dz, 0, masse, 0));    // anode -> masse
    scene_->addItem(new ItemFil(charge, 1, masse, 0));
    scene_->addItem(new ItemFil(pile, 1, masse, 0));
    scene_->addItem(new ItemFil(rs, 1, vm, 0));
    scene_->addItem(new ItemFil(vm, 1, masse, 0));

    circuit_modifie();
    vue_->ajuster();
    ecrire("Exemple : régulateur à diode Zener — 12 V en entrée, ballast de "
           "470 Ω, charge de 2,2 kΩ.");
    ecrire("La sortie doit tenir près de la tension Zener malgré les 12 V "
           "d'entrée. Changez la pile pour 9 V ou 15 V : la sortie bouge à "
           "peine, c'est tout l'intérêt.");
    ecrire("Onglet « Analyses » ▸ balayage continu de la source : la "
           "caractéristique montre le coude, puis le plateau.");
}

void FenetrePrincipale::charger_exemple_filtre() {
    scene_->tout_effacer();
    scene_->oublier_historique();
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

// Chenillard sur registre à décalage : le montage qui montre le troisième
// moteur à l'œuvre. L'horloge tourne à quelques centaines de kilohertz —
// aucune analyse analogique ne la suivrait, et pourtant les huit LED
// s'allument au bon moment.
void FenetrePrincipale::charger_exemple_registre() {
    scene_->tout_effacer();
    scene_->oublier_historique();
    chemin_projet_.clear();
    programmes_.clear();
    carte_courante_.clear();

    ItemComposant* carte = scene_->ajouter_composant("arduino_uno", QPointF(-560, 0));
    ItemComposant* ic = scene_->ajouter_composant("registre_74hc595", QPointF(-150, 0));
    ItemComposant* masse = scene_->ajouter_composant("masse", QPointF(-300, 400));
    if (!carte || !ic || !masse) return;
    auto borne_de = [carte](const QString& nom) {
        for (int k = 0; k < carte->nb_bornes(); ++k)
            if (carte->nom_borne(k) == nom) return k;
        return 0;
    };
    auto borne_ic = [ic](const QString& nom) {
        for (int k = 0; k < ic->nb_bornes(); ++k)
            if (ic->nom_borne(k) == nom) return k;
        return 0;
    };

    scene_->addItem(new ItemFil(carte, borne_de("D11"), ic, borne_ic("SER")));
    scene_->addItem(new ItemFil(carte, borne_de("D13"), ic, borne_ic("SRCLK")));
    scene_->addItem(new ItemFil(carte, borne_de("D10"), ic, borne_ic("RCLK")));
    scene_->addItem(new ItemFil(carte, borne_de("GND"), masse, 0));

    // Les LED sont espacées plus largement que les broches du boîtier : à
    // 26 points, leurs symboles se chevauchaient et l'octet devenait
    // illisible.
    for (int k = 0; k < 8; ++k) {
        const double y = -245 + k * 70.0;
        ItemComposant* led = scene_->ajouter_composant("led", QPointF(90, y));
        ItemComposant* r = scene_->ajouter_composant("resistance", QPointF(260, y));
        if (!led || !r) return;
        r->valeurs["ohms"] = 470;
        scene_->addItem(new ItemFil(ic, borne_ic("Q" + QString::number(k)), led, 0));
        scene_->addItem(new ItemFil(led, 1, r, 0));
        scene_->addItem(new ItemFil(r, 1, masse, 0));
    }

    circuit_modifie();
    programmes_[carte->reference()] =
        coeur::Programme{{"principal.ino", coeur::kProgrammeRegistre}};
    const QString affichee = carte_courante_;
    carte_courante_.clear();
    changer_carte(affichee.isEmpty() ? carte->reference() : affichee);
    vue_->ajuster();
    ecrire("Exemple : chenillard sur un 74HC595 — trois broches, huit LED.");
    ecrire("L'horloge tourne à des centaines de kilohertz : c'est le moteur "
           "numérique événementiel qui la traite, pas l'analogique.");
    ecrire("Le registre affiche son contenu sous son symbole, en binaire.");
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
        for (const coeur::Fichier& fichier : paire.second)
            rapport += QString("  %1 / %2 -> %3\n")
                           .arg(paire.first,
                                QString::fromStdString(fichier.nom),
                                QString::fromStdString(fichier.contenu)
                                    .split('\n')
                                    .value(0));
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
        const coeur::Microcontroleur& mcu = moteur_->mcu(reference);
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
