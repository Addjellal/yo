// Tests de la saisie de schéma, sans ouvrir de fenêtre.
//
// Ce que vérifie ce fichier est précisément ce qui casse quand on pose
// plusieurs exemplaires du même composant : l'attribution des références, le
// nommage des nœuds, et le fait que deux exemplaires restent bien deux
// composants distincts jusque dans la netlist.
//
//   QT_QPA_PLATFORM=offscreen ./tests_schema


// La console Windows lit dans une page de code héritée ; ce banc écrit de
// l'UTF-8. Sans cette bascule on y lisait « TESTS DU C┼ÆUR », « r├®sistance »
// et « ╬® » au lieu de « Ω » — un compte rendu qu'on ne peut pas juger d'un
// coup d'œil, alors que c'est tout ce qu'on lui demande.
//
// Sans effet ailleurs : la fonction n'existe que sous Windows.
#ifdef _WIN32
#  define WIN32_LEAN_AND_MEAN
#  define NOMINMAX
#  include <windows.h>
#endif
static void console_en_utf8() {
#ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
#endif
}

#include <QApplication>
#include <QDockWidget>
#include <QMenuBar>
#include <QGraphicsSceneContextMenuEvent>
#include <QGraphicsSceneMouseEvent>
#include <QImage>
#include <QJsonObject>
#include <QMenuBar>
#include <QToolBar>
#include "app/Oscilloscope.h"
#include <QMenu>
#include <functional>
#include <QPainter>
#include <QScrollArea>
#include <QKeyEvent>
#include <QElapsedTimer>
#include <QEventLoop>
#include <QPointF>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <set>
#include <string>
#include <vector>

#include "app/schematic/ItemComposant.h"
#include "app/schematic/ItemFil.h"
#include "app/Oscilloscope.h"
#include "app/panels/FenetreInstrument.h"
#include "app/panels/PanneauAnalyses.h"
#include "app/panels/PanneauPcb.h"
#include "core/engines/NgspiceEngine.h"
#include "app/MoteurSimulation.h"
#include "app/FenetrePrincipale.h"
#include "app/schematic/ItemJonction.h"
#include "app/schematic/Ancre.h"
#include "core/engines/ProgrammesExemples.h"
#include <QDir>
#include <QGraphicsPathItem>
#include <QGraphicsSceneMouseEvent>
#include <QDoubleSpinBox>
#include <QPlainTextEdit>
#include <QTextBlock>
#include <QLineEdit>
#include <QStyleOptionGraphicsItem>
#include <QTransform>
#include "app/schematic/SceneSchema.h"
#include "app/schematic/VueSchema.h"
#include "core/Device.h"
#include "core/pcb/Empreintes.h"

static int g_ok = 0;
static std::vector<std::string> g_echecs;

static void verifier(bool condition, const std::string& titre,
                     const std::string& detail = {}) {
    if (condition) {
        ++g_ok;
        std::printf("  ok    %s\n", titre.c_str());
    } else {
        g_echecs.push_back(titre);
        std::printf("  ECHEC %s   %s\n", titre.c_str(), detail.c_str());
    }
}

static bool presque(double a, double b, double tolerance) {
    return std::fabs(a - b) <= tolerance;
}

static std::string f(double v, int decimales = 3) {
    char tampon[64];
    std::snprintf(tampon, sizeof tampon, "%.*f", decimales, v);
    return tampon;
}

// Indice de la borne portant un nom donné.
static int borne(ItemComposant* composant, const QString& nom) {
    for (int k = 0; k < composant->nb_bornes(); ++k)
        if (composant->nom_borne(k) == nom) return k;
    return -1;
}

// ---------------------------------------------------------------------------
static void test_references() {
    std::printf("\n[1] Références : vingt exemplaires du même composant\n");
    SceneSchema scene;

    std::set<QString> references;
    for (int k = 0; k < 20; ++k) {
        ItemComposant* item =
            scene.ajouter_composant("resistance", QPointF(k * 80, 0));
        if (item) references.insert(item->reference());
    }
    verifier(references.size() == 20, "vingt références toutes distinctes",
             std::to_string(references.size()) + " références");
    verifier(references.count("R1") && references.count("R20"),
             "la numérotation suit le préfixe du modèle (R1…R20)");

    // Suppression au milieu, puis nouvel ajout : la référence libérée ne doit
    // pas être réattribuée à l'aveugle si elle est encore prise ailleurs.
    for (ItemComposant* item : scene.composants())
        if (item->reference() == "R7") item->setSelected(true);
    scene.supprimer_selection();
    ItemComposant* nouveau = scene.ajouter_composant("resistance", QPointF(0, 200));
    int occurrences = 0;
    for (ItemComposant* item : scene.composants())
        if (item->reference() == nouveau->reference()) ++occurrences;
    verifier(occurrences == 1,
             "après suppression, la nouvelle référence reste unique",
             nouveau->reference().toStdString());

    // Mélange de familles : chaque préfixe compte pour lui-même.
    std::set<QString> melange;
    for (int k = 0; k < 5; ++k) {
        melange.insert(scene.ajouter_composant("led", QPointF(k * 80, 300))
                           ->reference());
        melange.insert(scene.ajouter_composant("condensateur", QPointF(k * 80, 400))
                           ->reference());
        melange.insert(scene.ajouter_composant("transistor_npn", QPointF(k * 80, 500))
                           ->reference());
    }
    verifier(melange.size() == 15,
             "quinze composants de trois familles, quinze références",
             std::to_string(melange.size()) + " références");
}

// ---------------------------------------------------------------------------
static void test_dix_led() {
    std::printf("\n[2] Dix LED câblées en parallèle sur la même sortie\n");
    SceneSchema scene;
    ItemComposant* carte = scene.ajouter_composant("arduino_uno", QPointF(-400, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(600, 400));
    const int d13 = borne(carte, "D13");

    for (int k = 0; k < 10; ++k) {
        ItemComposant* led = scene.ajouter_composant("led", QPointF(100, k * 60));
        ItemComposant* r =
            scene.ajouter_composant("resistance", QPointF(280, k * 60));
        r->valeurs["ohms"] = 220;
        scene.addItem(new ItemFil(carte, d13, led, 0));
        scene.addItem(new ItemFil(led, 1, r, 0));
        scene.addItem(new ItemFil(r, 1, masse, 0));
    }

    std::vector<LiaisonBroche> broches;
    coeur::Netlist netlist = scene.construire_netlist(&broches);

    verifier(netlist.instances().size() == 20,
             "vingt instances dans la netlist (dix LED, dix résistances)",
             std::to_string(netlist.instances().size()) + " instances");

    // Les dix anodes doivent partager le nœud D13 ; les dix cathodes doivent
    // au contraire avoir chacune son nœud.
    std::set<std::string> noeuds_cathodes;
    int anodes_sur_d13 = 0;
    for (const coeur::Instance& instance : netlist.instances()) {
        if (instance.type != "led") continue;
        if (instance.borne("A") && instance.borne("A")->noeud == "D13")
            ++anodes_sur_d13;
        if (instance.borne("K")) noeuds_cathodes.insert(instance.borne("K")->noeud);
    }
    verifier(anodes_sur_d13 == 10,
             "les dix anodes partagent bien le nœud D13",
             std::to_string(anodes_sur_d13) + " anodes");
    verifier(noeuds_cathodes.size() == 10,
             "les dix cathodes ont chacune leur propre nœud",
             std::to_string(noeuds_cathodes.size()) + " nœuds distincts");
    verifier(broches.size() == 1,
             "une seule broche de carte est déclarée, malgré dix fils dessus",
             std::to_string(broches.size()) + " broche(s)");
}

// ---------------------------------------------------------------------------
static void test_masses_multiples() {
    std::printf("\n[3] Plusieurs symboles de masse et d'alimentation\n");
    SceneSchema scene;

    // Cinq masses éparpillées : elles doivent toutes désigner le même nœud,
    // c'est tout l'intérêt du symbole.
    std::vector<ItemComposant*> masses, alims, resistances;
    for (int k = 0; k < 5; ++k) {
        masses.push_back(scene.ajouter_composant("masse", QPointF(k * 200, 300)));
        alims.push_back(scene.ajouter_composant("alim5v", QPointF(k * 200, -300)));
        ItemComposant* r =
            scene.ajouter_composant("resistance", QPointF(k * 200, 0));
        r->valeurs["ohms"] = 1000;
        resistances.push_back(r);
        scene.addItem(new ItemFil(alims[k], 0, r, 0));
        scene.addItem(new ItemFil(r, 1, masses[k], 0));
    }

    coeur::Netlist netlist = scene.construire_netlist(nullptr);
    verifier(netlist.instances().size() == 5,
             "les symboles d'alimentation ne deviennent pas des composants",
             std::to_string(netlist.instances().size()) + " instances");

    int vers_masse = 0, vers_alim = 0;
    for (const coeur::Instance& instance : netlist.instances()) {
        if (instance.borne("2") && instance.borne("2")->noeud == coeur::Netlist::kMasse)
            ++vers_masse;
        if (instance.borne("1") && instance.borne("1")->noeud == coeur::Netlist::kAlim)
            ++vers_alim;
    }
    verifier(vers_masse == 5, "les cinq masses désignent le même nœud GND",
             std::to_string(vers_masse) + " sur 5");
    verifier(vers_alim == 5, "les cinq symboles +5 V désignent le même nœud",
             std::to_string(vers_alim) + " sur 5");
}

// ---------------------------------------------------------------------------
static void test_deux_cartes() {
    std::printf("\n[4] Deux cartes programmables sur le même schéma\n");
    SceneSchema scene;
    ItemComposant* carte_a = scene.ajouter_composant("arduino_uno", QPointF(-600, 0));
    ItemComposant* carte_b = scene.ajouter_composant("arduino_uno", QPointF(600, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(0, 500));

    // Chaque carte pilote sa propre LED, sur sa propre broche D13.
    ItemComposant* led_a = scene.ajouter_composant("led", QPointF(-300, -100));
    ItemComposant* r_a = scene.ajouter_composant("resistance", QPointF(-150, -100));
    ItemComposant* led_b = scene.ajouter_composant("led", QPointF(300, -100));
    ItemComposant* r_b = scene.ajouter_composant("resistance", QPointF(150, -100));
    r_a->valeurs["ohms"] = 220;
    r_b->valeurs["ohms"] = 220;

    scene.addItem(new ItemFil(carte_a, borne(carte_a, "D13"), led_a, 0));
    scene.addItem(new ItemFil(led_a, 1, r_a, 0));
    scene.addItem(new ItemFil(r_a, 1, masse, 0));
    scene.addItem(new ItemFil(carte_b, borne(carte_b, "D13"), led_b, 0));
    scene.addItem(new ItemFil(led_b, 1, r_b, 0));
    scene.addItem(new ItemFil(r_b, 1, masse, 0));

    std::vector<LiaisonBroche> broches;
    coeur::Netlist netlist = scene.construire_netlist(&broches);

    verifier(carte_a->reference() != carte_b->reference(),
             "les deux cartes ont des références distinctes",
             (carte_a->reference() + " et " + carte_b->reference()).toStdString());

    // Le point décisif : les deux broches D13 ne doivent PAS finir sur le même
    // nœud. Elles appartiennent à deux cartes différentes, elles sont
    // électriquement indépendantes.
    std::string noeud_a, noeud_b;
    for (const coeur::Instance& instance : netlist.instances()) {
        if (instance.type != "led") continue;
        const coeur::Borne* anode = instance.borne("A");
        if (!anode) continue;
        if (noeud_a.empty()) noeud_a = anode->noeud;
        else noeud_b = anode->noeud;
    }
    verifier(!noeud_a.empty() && !noeud_b.empty() && noeud_a != noeud_b,
             "les broches D13 des deux cartes restent deux nœuds séparés",
             "« " + noeud_a + " » et « " + noeud_b + " »");

    verifier(broches.size() == 2,
             "les deux broches sont déclarées séparément",
             std::to_string(broches.size()) + " broche(s)");

    // Et elles doivent porter des noms de nœud différents, sinon la netlist
    // SPICE émettrait deux fois la même source de tension.
    std::set<std::string> noeuds_broches;
    for (const LiaisonBroche& liaison : broches) noeuds_broches.insert(liaison.noeud);
    verifier(noeuds_broches.size() == broches.size(),
             "aucune source de tension ne serait émise deux fois",
             std::to_string(noeuds_broches.size()) + " nœuds pour " +
                 std::to_string(broches.size()) + " broches");

    // Chaque broche doit savoir de quelle carte elle vient, sinon le pilote
    // ne saurait pas quel cœur AVR interroger.
    std::set<std::string> proprietaires;
    for (const LiaisonBroche& liaison : broches)
        proprietaires.insert(liaison.carte);
    verifier(proprietaires.size() == 2,
             "chaque broche porte l'identité de sa carte",
             std::to_string(proprietaires.size()) + " cartes distinctes");

    // --- liaison directe entre les deux cartes, sans composant au milieu
    //
    // C'est le cas qui échappe au filtre « broche en l'air » : il n'y a aucun
    // composant sur ce nœud, seulement deux broches face à face.
    scene.addItem(new ItemFil(carte_a, borne(carte_a, "D7"), carte_b,
                              borne(carte_b, "D2")));
    broches.clear();
    netlist = scene.construire_netlist(&broches);

    int sur_liaison = 0;
    std::string noeud_liaison;
    for (const LiaisonBroche& liaison : broches) {
        if (liaison.nom != "D7" && liaison.nom != "D2") continue;
        ++sur_liaison;
        if (noeud_liaison.empty()) noeud_liaison = liaison.noeud;
        else if (noeud_liaison != liaison.noeud) noeud_liaison = "(divergent)";
    }
    verifier(sur_liaison == 2,
             "deux cartes reliées directement gardent leurs deux broches",
             std::to_string(sur_liaison) + " broche(s) sur la liaison");
    verifier(sur_liaison == 2 && noeud_liaison != "(divergent)",
             "et les deux broches partagent bien le même nœud",
             "nœud « " + noeud_liaison + " »");

    // La masse, elle, doit rester commune aux deux cartes : deux cartes sans
    // référence partagée ne peuvent rien s'échanger.
    scene.addItem(new ItemFil(carte_a, borne(carte_a, "GND"), masse, 0));
    scene.addItem(new ItemFil(carte_b, borne(carte_b, "GND"), masse, 0));
    netlist = scene.construire_netlist(&broches);
    int cathodes_a_la_masse = 0;
    for (const coeur::Instance& instance : netlist.instances())
        if (instance.type == "resistance" && instance.borne("2") &&
            instance.borne("2")->noeud == coeur::Netlist::kMasse)
            ++cathodes_a_la_masse;
    verifier(cathodes_a_la_masse == 2,
             "la masse reste un nœud unique, partagé par les deux cartes",
             std::to_string(cathodes_a_la_masse) + " retours à la masse");
}

// ---------------------------------------------------------------------------
static void test_cartes_non_cablees() {
    std::printf("\n[5] Cartes posées mais pas encore câblées\n");
    SceneSchema scene;

    // Une carte seule sur un schéma vide n'a aucune broche reliée. Elle doit
    // pourtant être reconnue : sinon elle serait impossible à programmer, et
    // c'est exactement l'état d'un schéma qu'on commence.
    ItemComposant* carte = scene.ajouter_composant("arduino_uno", QPointF(0, 0));
    verifier(carte != nullptr, "la carte est posée");
    verifier(scene.cartes_presentes().size() == 1,
             "une carte non câblée est tout de même recensée",
             std::to_string(scene.cartes_presentes().size()) + " carte(s)");

    std::vector<LiaisonBroche> broches;
    coeur::Netlist netlist = scene.construire_netlist(&broches);
    verifier(broches.empty(),
             "et elle ne déclare aucune broche, puisqu'aucune n'est reliée",
             std::to_string(broches.size()) + " broche(s)");
    verifier(netlist.instances().empty(), "la netlist est vide, sans erreur");

    // Trois cartes, dont deux sans le moindre fil.
    scene.ajouter_composant("arduino_uno", QPointF(400, 0));
    scene.ajouter_composant("arduino_uno", QPointF(800, 0));
    verifier(scene.cartes_presentes().size() == 3,
             "trois cartes posées, trois cartes recensées",
             std::to_string(scene.cartes_presentes().size()) + " cartes");

    // Après suppression, la carte ne doit plus figurer dans le recensement.
    for (ItemComposant* item : scene.composants())
        if (item->reference() == carte->reference()) item->setSelected(true);
    scene.supprimer_selection();
    verifier(scene.cartes_presentes().size() == 2,
             "une carte supprimée disparaît du recensement",
             std::to_string(scene.cartes_presentes().size()) + " cartes");
}

// ---------------------------------------------------------------------------
// [6] Panneau d'analyses : il doit traduire fidèlement un résultat de calcul
// en courbes et en compte rendu. Vérifié sans écran, sur des données dont on
// connaît la réponse.
// ---------------------------------------------------------------------------
static void test_panneau_analyses() {
    std::printf("\n[6] Panneau d'analyses\n");
    PanneauAnalyses panneau;

    // --- diagramme de Bode d'un passe-bas théorique coupant à 1 kHz
    {
        coeur::Balayage bode;
        bode.logarithmique = true;
        bode.grandeur = "Fréquence";
        coeur::Courbe entree, sortie;
        entree.nom = "in";
        sortie.nom = "out";
        for (int k = 0; k <= 50; ++k) {
            const double frequence = std::pow(10.0, 1.0 + k / 10.0);
            const double x = frequence / 1000.0;
            bode.abscisse.push_back(frequence);
            entree.valeurs.push_back(1.0);
            entree.phases.push_back(0.0);
            sortie.valeurs.push_back(1.0 / std::sqrt(1 + x * x));
            sortie.phases.push_back(-std::atan(x) * 180 / 3.14159265358979);
        }
        bode.courbes.push_back(entree);
        bode.courbes.push_back(sortie);
        panneau.afficher_balayage(bode, true, "in");
        const QString resume = panneau.resume();
        verifier(resume.contains("out"), "Bode : la sortie figure au compte rendu",
                 resume.toStdString());
        verifier(resume.contains("coupure"), "Bode : la coupure est annoncée",
                 resume.toStdString());
        // gain et phase : deux courbes par signal, l'entrée servant de
        // référence n'est pas retracée
        verifier(resume.contains("2 courbes"),
                 "Bode : gain et phase, la référence n'est pas retracée",
                 resume.toStdString());
        verifier(panneau.csv().startsWith("Fréquence;"),
                 "Bode : export CSV du balayage",
                 panneau.csv().left(30).toStdString());
    }

    // --- spectre : les raies et la distorsion doivent apparaître en clair
    {
        coeur::Spectre spectre;
        spectre.valide = true;
        spectre.fondamentale = 1000;
        spectre.thd = 42.88;
        spectre.efficace = 2.5;
        spectre.raies = {{1, 1000, 3.183, 100.0}, {3, 3000, 1.061, 33.3}};
        panneau.afficher_spectre(spectre, "N1");
        const QString resume = panneau.resume();
        verifier(resume.contains("42.88"), "spectre : la distorsion est affichée",
                 resume.toStdString());
        verifier(resume.contains("H3"), "spectre : les rangs sont détaillés");
        verifier(panneau.csv().startsWith("rang;frequence"),
                 "spectre : export CSV des raies");
    }

    // --- un résultat vide ne doit pas passer pour un résultat
    {
        panneau.afficher_balayage(coeur::Balayage{}, false);
        verifier(panneau.resume().contains("aucun point"),
                 "balayage vide : le panneau le dit au lieu d'afficher du vide",
                 panneau.resume().toStdString());
    }
}

// ---------------------------------------------------------------------------
// [7] Câblage à la souris : cliquer une borne doit suffire à tirer un fil,
// sans passer par l'outil. Les événements sont envoyés à la scène comme le
// ferait la vue, donc sans ouvrir de fenêtre.
// ---------------------------------------------------------------------------
namespace {

void envoyer(SceneSchema& scene, QEvent::Type type, const QPointF& point,
             Qt::MouseButton bouton = Qt::LeftButton,
             Qt::KeyboardModifiers touches = Qt::NoModifier) {
    QGraphicsSceneMouseEvent evenement(type);
    evenement.setScenePos(point);
    evenement.setPos(point);
    evenement.setButton(bouton);
    evenement.setButtons(type == QEvent::GraphicsSceneMouseRelease
                             ? Qt::NoButton
                             : bouton);
    evenement.setModifiers(touches);
    QApplication::sendEvent(&scene, &evenement);
}

// Une flèche du clavier, envoyée à la scène.
void frapper(SceneSchema& scene, int touche,
             Qt::KeyboardModifiers touches = Qt::NoModifier) {
    QKeyEvent evenement(QEvent::KeyPress, touche, touches);
    QApplication::sendEvent(&scene, &evenement);
}

}  // namespace

static void test_cablage_souris() {
    std::printf("\n[7] Câblage à la souris\n");

    // --- glisser d'une borne à l'autre, outil Sélection
    {
        SceneSchema scene;
        ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(200, 0));
        const QPointF depart = r1->position_borne(1);
        const QPointF arrivee = r2->position_borne(0);

        envoyer(scene, QEvent::GraphicsSceneMousePress, depart);
        envoyer(scene, QEvent::GraphicsSceneMouseMove, arrivee);
        envoyer(scene, QEvent::GraphicsSceneMouseRelease, arrivee);
        verifier(scene.fils().size() == 1,
                 "glisser d'une borne à l'autre crée un fil, outil Sélection",
                 std::to_string(scene.fils().size()) + " fil(s)");
    }

    // --- clic, puis clic : le fil reste accroché entre les deux
    {
        SceneSchema scene;
        ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(200, 0));
        const QPointF depart = r1->position_borne(1);
        const QPointF arrivee = r2->position_borne(0);

        envoyer(scene, QEvent::GraphicsSceneMousePress, depart);
        envoyer(scene, QEvent::GraphicsSceneMouseRelease, depart);
        verifier(scene.fils().empty(),
                 "un simple clic ne crée pas encore de fil");
        envoyer(scene, QEvent::GraphicsSceneMouseMove, arrivee);
        envoyer(scene, QEvent::GraphicsSceneMousePress, arrivee);
        verifier(scene.fils().size() == 1,
                 "le second clic referme le fil",
                 std::to_string(scene.fils().size()) + " fil(s)");
    }

    // --- cliquer dans le vide POSE UN COUDE, et n'abandonne rien
    //
    // C'est le point 3 de DECISION-FILS : « if you want a wire in a particular
    // place, you can simply click at the intermediate corners ». Le code
    // l'annonçait mais ne le faisait pas : `terminer_fil` abandonnait le tracé
    // avant de rendre la main, si bien que le coude était posé à partir d'une
    // cible de départ remise à zéro — c'est-à-dire jamais.
    {
        SceneSchema scene;
        ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(600, 0));
        const QPointF depart = r1->position_borne(1);
        envoyer(scene, QEvent::GraphicsSceneMousePress, depart);
        envoyer(scene, QEvent::GraphicsSceneMouseRelease, depart);
        envoyer(scene, QEvent::GraphicsSceneMousePress, QPointF(300, 300));
        verifier(scene.fils().size() == 1 && scene.jonctions().size() == 1,
                 "un clic dans le vide pose un coude et poursuit le tracé",
                 std::to_string(scene.fils().size()) + " fil(s), "
                     + std::to_string(scene.jonctions().size()) + " point(s)");

        // Le tracé continue vraiment : le clic suivant referme sur une borne.
        envoyer(scene, QEvent::GraphicsSceneMousePress, r2->position_borne(0));
        verifier(scene.fils().size() == 2,
                 "et le clic suivant referme le chemin en deux segments",
                 std::to_string(scene.fils().size()) + " fil(s)");
    }

    // --- Échap abandonne, et le chemin inachevé ne laisse rien derrière lui
    {
        SceneSchema scene;
        ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
        const QPointF depart = r1->position_borne(0);
        envoyer(scene, QEvent::GraphicsSceneMousePress, depart);
        envoyer(scene, QEvent::GraphicsSceneMouseRelease, depart);
        envoyer(scene, QEvent::GraphicsSceneMousePress, QPointF(600, 600));
        scene.abandonner_fil();
        verifier(scene.fils().empty() && scene.jonctions().empty(),
                 "un chemin abandonné est balayé, coude compris",
                 std::to_string(scene.fils().size()) + " fil(s), "
                     + std::to_string(scene.jonctions().size()) + " point(s)");

        // et l'on peut recommencer aussitôt
        ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(300, 0));
        envoyer(scene, QEvent::GraphicsSceneMousePress, r1->position_borne(1));
        envoyer(scene, QEvent::GraphicsSceneMouseRelease, r2->position_borne(0));
        verifier(scene.fils().size() == 1,
                 "après un abandon, le câblage repart normalement",
                 std::to_string(scene.fils().size()) + " fil(s)");
    }

    // --- une borne sur elle-même ne crée pas de fil
    {
        SceneSchema scene;
        ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
        const QPointF borne = r1->position_borne(0);
        envoyer(scene, QEvent::GraphicsSceneMousePress, borne);
        envoyer(scene, QEvent::GraphicsSceneMouseMove, borne + QPointF(20, 20));
        envoyer(scene, QEvent::GraphicsSceneMouseRelease, borne);
        verifier(scene.fils().empty(),
                 "une borne reliée à elle-même est refusée");
    }

    // --- cliquer le corps d'un composant le sélectionne, sans tirer de fil
    {
        SceneSchema scene;
        ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
        envoyer(scene, QEvent::GraphicsSceneMousePress, r1->pos());
        envoyer(scene, QEvent::GraphicsSceneMouseRelease, r1->pos());
        verifier(scene.fils().empty(),
                 "cliquer le corps ne déclenche pas de câblage");
    }
}

// ---------------------------------------------------------------------------
// [8] Nommage des nœuds et instruments de mesure : un nœud doit dire ce qu'il
// relie, et un instrument afficher ce qu'il lit.
// ---------------------------------------------------------------------------
static void test_noeuds_et_instruments() {
    std::printf("\n[8] Nœuds nommés et instruments\n");
    SceneSchema scene;
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(200, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(400, 200));
    scene.addItem(new ItemFil(r1, 1, r2, 0));
    scene.addItem(new ItemFil(r2, 1, masse, 0));

    const auto description = scene.description_noeuds();
    bool nom_parlant = false;
    for (const auto& paire : description)
        if (paire.first.startsWith("R1_") || paire.first.startsWith("R2_"))
            nom_parlant = true;
    verifier(nom_parlant,
             "un nœud sans nom imposé prend celui d'une borne (R1_2), pas N1");
    bool aucun_n = true;
    for (const auto& paire : description)
        if (paire.first == "N1" || paire.first == "N2") aucun_n = false;
    verifier(aucun_n, "plus de nœuds « N1 », « N2 » sans signification");

    bool decrit = false;
    for (const auto& paire : description)
        if (paire.second.contains("R1.2") && paire.second.contains("R2.1"))
            decrit = true;
    verifier(decrit, "chaque nœud dit quelles bornes il relie",
             description.empty() ? "" : description.begin()->second.toStdString());

    // --- voltmètre : il doit afficher la différence de potentiel lue
    {
        SceneSchema mesure;
        ItemComposant* vm = mesure.ajouter_composant("voltmetre", QPointF(0, 0));
        ItemComposant* pile = mesure.ajouter_composant("pile", QPointF(-200, 0));
        ItemComposant* gnd = mesure.ajouter_composant("masse", QPointF(200, 200));
        mesure.addItem(new ItemFil(pile, 0, vm, 0));
        mesure.addItem(new ItemFil(vm, 1, gnd, 0));
        const auto noeuds = mesure.description_noeuds();
        std::string nom_plus;
        for (const auto& paire : noeuds)
            if (paire.second.contains("VM1.+")) nom_plus = paire.first.toLower().toStdString();
        verifier(!nom_plus.empty(), "le nœud du voltmètre est identifiable");
        mesure.appliquer_resultats({}, {{nom_plus, 9.0}, {"gnd", 0.0}});
        verifier(vm->mesure() == "9.00 V",
                 "le voltmètre affiche la tension mesurée",
                 vm->mesure().toStdString());
    }

    // --- ampèremètre : il affiche le courant qui le traverse
    {
        SceneSchema mesure;
        ItemComposant* am = mesure.ajouter_composant("amperemetre", QPointF(0, 0));
        mesure.appliquer_resultats({{"am1", 0.0128}}, {});
        verifier(am->mesure() == "12.80 mA",
                 "l'ampèremètre affiche le courant, avec son préfixe",
                 am->mesure().toStdString());
    }
}

// ---------------------------------------------------------------------------
// [9] Clic droit, double-clic, fenêtre d'instrument.
// ---------------------------------------------------------------------------
static void test_interactions() {
    std::printf("\n[9] Clic droit, double-clic, fenêtre de mesure\n");
    SceneSchema scene;
    ItemComposant* vm = scene.ajouter_composant("voltmetre", QPointF(0, 0));

    int doubles = 0, menus = 0;
    ItemComposant* recu = nullptr;
    QObject::connect(&scene, &SceneSchema::double_clic_composant,
                     [&](ItemComposant* c) { ++doubles; recu = c; });
    QObject::connect(&scene, &SceneSchema::menu_demande,
                     [&](ItemComposant*, const QPoint&) { ++menus; });

    QGraphicsSceneMouseEvent deux(QEvent::GraphicsSceneMouseDoubleClick);
    deux.setScenePos(vm->pos());
    deux.setButton(Qt::LeftButton);
    QApplication::sendEvent(&scene, &deux);
    verifier(doubles == 1 && recu == vm,
             "un double-clic gauche désigne le composant visé",
             std::to_string(doubles));

    QGraphicsSceneContextMenuEvent droit(QEvent::GraphicsSceneContextMenu);
    droit.setScenePos(vm->pos());
    QApplication::sendEvent(&scene, &droit);
    verifier(menus == 1, "le clic droit demande le menu des options",
             std::to_string(menus));
    verifier(scene.fils().empty(),
             "le clic droit ne tire aucun fil, même sur une borne");

    // Un clic droit alors qu'un fil est en attente doit l'abandonner.
    ItemComposant* r = scene.ajouter_composant("resistance", QPointF(200, 0));
    QGraphicsSceneMouseEvent appui(QEvent::GraphicsSceneMousePress);
    appui.setScenePos(r->position_borne(0));
    appui.setButton(Qt::LeftButton);
    appui.setButtons(Qt::LeftButton);
    QApplication::sendEvent(&scene, &appui);
    QGraphicsSceneMouseEvent relache(QEvent::GraphicsSceneMouseRelease);
    relache.setScenePos(r->position_borne(0));
    relache.setButton(Qt::LeftButton);
    QApplication::sendEvent(&scene, &relache);
    QGraphicsSceneContextMenuEvent droit2(QEvent::GraphicsSceneContextMenu);
    droit2.setScenePos(r->position_borne(1));
    QApplication::sendEvent(&scene, &droit2);
    QGraphicsSceneMouseEvent apres(QEvent::GraphicsSceneMousePress);
    apres.setScenePos(vm->position_borne(0));
    apres.setButton(Qt::LeftButton);
    apres.setButtons(Qt::LeftButton);
    QApplication::sendEvent(&scene, &apres);
    verifier(scene.fils().empty(),
             "un clic droit abandonne le fil laissé en attente");

    // --- la fenêtre d'un instrument montre sa mesure, et se ferme si le
    // composant disparaît du schéma.
    {
        vm->definir_mesure("4.72 V");
        bool present = true;
        FenetreInstrument fenetre(
            vm, [&present](ItemComposant*) { return present; },
            [](ItemComposant*) { return QString("VM1_+"); });
        fenetre.show();
        verifier(fenetre.windowTitle().contains("VM1"),
                 "la fenêtre porte la référence de l'appareil",
                 fenetre.windowTitle().toStdString());
        verifier(fenetre.isVisible(), "la fenêtre s'ouvre");
    }
}

// ---------------------------------------------------------------------------
// [10] Oscilloscope : déclenchement et curseurs. Sans écran — le rendu est
// forcé par un « grab » hors écran, ce qui suffit à calculer la fenêtre.
// ---------------------------------------------------------------------------
static void test_declenchement() {
    std::printf("\n[10] Déclenchement et curseurs\n");
    const double pi = 3.14159265358979323846;

    TraceOscilloscope trace;
    trace.resize(800, 300);
    trace.definir_signal(0, "sinus");
    trace.definir_fenetre(0.005);          // 5 ms à l'écran

    // 200 ms de sinusoïde à 1 kHz, livrées par trames comme le fait le moteur.
    for (int trame = 0; trame < 8; ++trame) {
        coeur::Formes formes;
        const double debut = trame * 0.025;
        for (int k = 0; k <= 500; ++k) {
            const double t = k * 0.025 / 500;
            formes.temps.push_back(t);
            formes.tensions["sinus"].push_back(
                2.5 + 2.5 * std::sin(2 * pi * 1000 * (debut + t)));
        }
        trace.ajouter(formes, debut);
    }

    // --- sans déclenchement : la fenêtre colle à l'instant présent
    trace.definir_declenchement(TraceOscilloscope::Declenchement::Aucun);
    trace.grab();
    const double libre = trace.debut_fenetre();
    verifier(!trace.declenche(), "sans déclenchement, aucun front n'est cherché");

    // --- avec déclenchement : le front se retrouve au cinquième de l'écran
    trace.definir_voie_declenchement(0);
    trace.definir_niveau_declenchement(2.5);
    trace.definir_front_montant(true);
    trace.definir_declenchement(TraceOscilloscope::Declenchement::Auto);
    trace.grab();
    verifier(trace.declenche(), "un front est trouvé dans le signal");
    const double declenche = trace.debut_fenetre();
    verifier(std::fabs(declenche - libre) > 1e-9,
             "la fenêtre s'est déplacée pour se caler sur le front");

    const double instant_front = declenche + 0.2 * trace.fenetre();
    const double au_front = trace.valeur_a(0, instant_front);
    verifier(presque(au_front, 2.5, 0.05),
             "au cinquième de l'écran, le signal est au niveau de "
             "déclenchement",
             f(au_front) + " V");
    const double avant = trace.valeur_a(0, instant_front - 0.05e-3);
    const double apres = trace.valeur_a(0, instant_front + 0.05e-3);
    verifier(avant < 2.5 && apres > 2.5,
             "et il s'agit bien d'un front montant",
             f(avant) + " -> " + f(apres));

    // --- front descendant : le signal doit décroître au même endroit
    trace.definir_front_montant(false);
    trace.grab();
    const double repere = trace.debut_fenetre() + 0.2 * trace.fenetre();
    verifier(trace.valeur_a(0, repere - 0.05e-3) > 2.5
                 && trace.valeur_a(0, repere + 0.05e-3) < 2.5,
             "front descendant : le signal décroît au repère");

    // --- niveau hors de portée : plus de front, l'image ne ment pas
    trace.definir_front_montant(true);
    trace.definir_niveau_declenchement(12.0);
    trace.grab();
    verifier(!trace.declenche(),
             "un niveau que le signal n'atteint jamais ne déclenche pas");
}

// ---------------------------------------------------------------------------
// [11] Étiquettes de nœud : deux étiquettes de même nom relient deux points
// sans qu'un fil traverse la feuille.
// ---------------------------------------------------------------------------
static void test_etiquettes() {
    std::printf("\n[11] Étiquettes de nœud\n");
    SceneSchema scene;

    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(600, 0));
    ItemComposant* e1 = scene.ajouter_composant("etiquette", QPointF(120, 0));
    ItemComposant* e2 = scene.ajouter_composant("etiquette", QPointF(480, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(300, 200));
    e1->textes["nom"] = "SIG";
    e2->textes["nom"] = "SIG";
    scene.addItem(new ItemFil(r1, 1, e1, 0));
    scene.addItem(new ItemFil(r2, 0, e2, 0));
    scene.addItem(new ItemFil(r1, 0, masse, 0));

    coeur::Netlist netlist = scene.construire_netlist(nullptr);
    const coeur::Instance* a = netlist.trouver("R1");
    const coeur::Instance* b = netlist.trouver("R2");
    verifier(a && b && a->borne("2") && b->borne("1")
                 && a->borne("2")->noeud == "SIG"
                 && b->borne("1")->noeud == "SIG",
             "deux étiquettes de même nom donnent le même nœud",
             a && a->borne("2") ? a->borne("2")->noeud : "");

    verifier(netlist.trouver("NET1") == nullptr,
             "une étiquette n'est pas un composant de la netlist");

    // Noms différents : les nœuds doivent rester séparés.
    e2->textes["nom"] = "CLK";
    netlist = scene.construire_netlist(nullptr);
    a = netlist.trouver("R1");
    b = netlist.trouver("R2");
    verifier(a && b && a->borne("2")->noeud != b->borne("1")->noeud,
             "deux noms différents restent deux nœuds",
             a->borne("2")->noeud + " / " + b->borne("1")->noeud);
}

// ---------------------------------------------------------------------------
// [12] Annulation, rétablissement, presse-papiers.
// ---------------------------------------------------------------------------
static void test_annulation() {
    std::printf("\n[12] Annulation et presse-papiers\n");
    SceneSchema scene;

    verifier(!scene.peut_annuler(), "rien à annuler sur un schéma neuf");

    scene.memoriser();
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
    r1->valeurs["ohms"] = 470;
    scene.memoriser();
    ItemComposant* led = scene.ajouter_composant("led", QPointF(200, 0));
    scene.addItem(new ItemFil(r1, 1, led, 0));
    verifier(scene.composants().size() == 2 && scene.fils().size() == 1,
             "deux composants et un fil posés");

    verifier(scene.annuler(), "l'annulation aboutit");
    verifier(scene.composants().size() == 1 && scene.fils().empty(),
             "l'annulation retire le composant ET son fil",
             std::to_string(scene.composants().size()) + " composant(s)");
    verifier(scene.composants().front()->valeurs["ohms"] == 470,
             "les valeurs réglées sont restituées telles quelles",
             std::to_string(scene.composants().front()->valeurs["ohms"]));

    verifier(scene.retablir(), "le rétablissement aboutit");
    verifier(scene.composants().size() == 2 && scene.fils().size() == 1,
             "le rétablissement remet tout, fil compris");

    verifier(scene.annuler() && scene.annuler(),
             "on remonte plusieurs coups en arrière");
    verifier(scene.composants().empty(), "retour au schéma vide",
             std::to_string(scene.composants().size()) + " composant(s)");
    verifier(!scene.peut_annuler(), "et la pile est vide au bout");

    // --- copier / coller : références neuves, fils recopiés
    {
        SceneSchema atelier;
        ItemComposant* a = atelier.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* b = atelier.ajouter_composant("led", QPointF(150, 0));
        atelier.addItem(new ItemFil(a, 1, b, 0));
        a->setSelected(true);
        b->setSelected(true);
        atelier.copier_selection();
        verifier(atelier.presse_papiers_rempli(), "la sélection est copiée");
        verifier(atelier.coller(), "le collage aboutit");
        verifier(atelier.composants().size() == 4,
                 "quatre composants après collage",
                 std::to_string(atelier.composants().size()));
        verifier(atelier.fils().size() == 2,
                 "le fil interne à la sélection est recopié",
                 std::to_string(atelier.fils().size()));
        std::set<QString> references;
        for (ItemComposant* item : atelier.composants())
            references.insert(item->reference());
        verifier(references.size() == 4,
                 "les copies ont des références neuves",
                 std::to_string(references.size()));
        bool decale = true;
        for (ItemComposant* item : atelier.composants())
            if (item->reference() == "R2" && item->pos() == a->pos())
                decale = false;
        verifier(decale, "la copie ne se superpose pas à l'original");
        verifier(atelier.annuler() && atelier.composants().size() == 2,
                 "un collage s'annule comme le reste");
    }

    // --- ouvrir un projet efface l'histoire : annuler ne doit pas ramener
    // le schéma précédent, ce que personne n'attend.
    {
        SceneSchema atelier;
        atelier.ajouter_composant("resistance", QPointF(0, 0));
        atelier.memoriser();
        atelier.ajouter_composant("led", QPointF(100, 0));
        const QJsonObject autre_projet = atelier.vers_json();
        atelier.depuis_json(autre_projet);
        atelier.oublier_historique();
        verifier(!atelier.peut_annuler() && !atelier.peut_retablir(),
                 "ouvrir un projet repart d'une histoire vierge");
    }

    // --- un fil qui sort de la sélection n'est pas copié
    {
        SceneSchema atelier;
        ItemComposant* a = atelier.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* b = atelier.ajouter_composant("led", QPointF(150, 0));
        atelier.addItem(new ItemFil(a, 1, b, 0));
        a->setSelected(true);            // b n'est pas sélectionné
        atelier.copier_selection();
        atelier.coller();
        verifier(atelier.fils().size() == 1,
                 "un fil à moitié sélectionné n'est pas recopié",
                 std::to_string(atelier.fils().size()));
    }
}

// ---------------------------------------------------------------------------
// Transfert du schéma vers la carte : ce que promet un « mettre à jour »
// ---------------------------------------------------------------------------
static void test_transfert_pcb() {
    std::printf("\n-- transfert du schéma vers le circuit imprimé --\n");

    SceneSchema atelier;
    ItemComposant* r = atelier.ajouter_composant("resistance", QPointF(0, 0));
    ItemComposant* led = atelier.ajouter_composant("led", QPointF(150, 0));
    ItemComposant* masse = atelier.ajouter_composant("masse", QPointF(300, 0));
    atelier.addItem(new ItemFil(r, 1, led, 0));
    atelier.addItem(new ItemFil(led, 1, masse, 0));

    PanneauPcb panneau;
    const QString premier = panneau.construire_depuis(atelier.construire_netlist(nullptr));
    verifier(premier.contains("ajoutés") && premier.contains("R1")
                 && premier.contains("LED1"),
             "le premier transfert annonce les composants ajoutés");
    verifier(panneau.vue()->carte().composants.size() == 2,
             "la masse n'est pas une pièce de la carte",
             std::to_string(panneau.vue()->carte().composants.size()));

    // Placement à la main, puis une piste : c'est ce travail qui doit
    // survivre au transfert suivant.
    panneau.vue()->carte().deplacer("R1", 40, 30);
    const auto liaisons = panneau.vue()->carte().chevelu();
    verifier(!liaisons.empty(), "le chevelu montre ce qu'il reste à relier");
    panneau.vue()->carte().pistes.push_back({liaisons.front().net,
                                             liaisons.front().x1,
                                             liaisons.front().y1,
                                             liaisons.front().x2,
                                             liaisons.front().y2, 0.4, 0});

    const QString second = panneau.construire_depuis(atelier.construire_netlist(nullptr));
    verifier(second.contains("déjà à jour"),
             "un second transfert sans changement ne touche à rien", 
             second.toStdString());
    const coeur::ComposantPose* pose = nullptr;
    for (const auto& candidat : panneau.vue()->carte().composants)
        if (candidat.reference == "R1") pose = &candidat;
    verifier(pose && std::fabs(pose->x - 40) < 1e-6
                 && std::fabs(pose->y - 30) < 1e-6,
             "le placement fait à la main survit au transfert");
    verifier(panneau.vue()->carte().pistes.size() == 1,
             "la piste déjà tirée survit au transfert",
             std::to_string(panneau.vue()->carte().pistes.size()));

    // On retire la LED du schéma : le transfert doit l'ôter de la carte, et
    // abandonner les pistes dont le net n'existe plus.
    atelier.removeItem(led);
    delete led;
    const QString troisieme = panneau.construire_depuis(atelier.construire_netlist(nullptr));
    verifier(troisieme.contains("retirés") && troisieme.contains("LED1"),
             "retirer un composant du schéma le retire de la carte",
             troisieme.toStdString());
    verifier(panneau.vue()->carte().composants.size() == 1,
             "il ne reste que la résistance",
             std::to_string(panneau.vue()->carte().composants.size()));
    verifier(panneau.vue()->carte().pistes.empty(),
             "et la piste de son net a été abandonnée",
             std::to_string(panneau.vue()->carte().pistes.size()));
}

// ---------------------------------------------------------------------------
// Gestes d'un utilisateur ordinaire : poser, déplacer, tourner, effacer
//
// Ce que fait vraiment quelqu'un devant l'application, dans le désordre, et
// ce qui doit rester vrai après : pas de fil qui pointe dans le vide, pas de
// nœud fantôme, pas d'objet oublié dans la scène, et chaque geste annulable.
// ---------------------------------------------------------------------------
namespace {

// Rien d'autre que des composants et des fils ne doit traîner dans la scène :
// un trait provisoire resté en place serait un artefact visible à l'écran.
bool scene_propre(SceneSchema& scene) {
    // Les points de dérivation sont des objets de plein droit : les exclure
    // faisait déclarer sale toute scène portant un T correct.
    for (QGraphicsItem* item : scene.items())
        if (item->type() != ItemComposant::Type && item->type() != ItemFil::Type
            && item->type() != ItemJonction::Type)
            return false;
    return true;
}

// Tous les fils désignent-ils des composants encore présents, et des bornes
// qui existent ?
bool fils_coherents(SceneSchema& scene) {
    // L'invariant se lit sur les ANCRES. Écrit sur `depart()`, il jugeait
    // incohérent tout fil accroché à un point — l'accesseur y rend nullptr —,
    // c'est-à-dire exactement la fonctionnalité qu'il devrait garder.
    std::set<const ItemComposant*> composants_vivants;
    for (ItemComposant* composant : scene.composants())
        composants_vivants.insert(composant);
    std::set<const ItemJonction*> points_vivants;
    for (ItemJonction* point : scene.jonctions()) points_vivants.insert(point);

    auto ancre_saine = [&](const Ancre& ancre) {
        if (ancre.jonction) return points_vivants.count(ancre.jonction) > 0;
        if (!ancre.composant) return false;
        if (!composants_vivants.count(ancre.composant)) return false;
        return ancre.borne >= 0 && ancre.borne < ancre.composant->nb_bornes();
    };
    for (ItemFil* fil : scene.fils())
        if (!ancre_saine(fil->ancre_depart())
            || !ancre_saine(fil->ancre_arrivee()))
            return false;
    return true;
}

// Une netlist saine, c'est-à-dire : des références uniques, et un circuit que
// le moteur analogique accepte et résout. Une borne en l'air est normale — le
// moteur lui invente un nœud de cent mégohms —, ce qui ne doit pas l'être,
// c'est un circuit qui refuse de se calculer.
bool netlist_saine(SceneSchema& scene) {
    const coeur::Netlist netlist = scene.construire_netlist(nullptr);
    std::set<std::string> references;
    for (const coeur::Instance& instance : netlist.instances()) {
        if (instance.reference.empty()) return false;
        if (!references.insert(instance.reference).second) return false;
    }
    if (netlist.instances().empty()) return true;
    coeur::NgspiceEngine moteur;
    moteur.construire(netlist, {});
    return moteur.resoudre() && moteur.erreurs().empty();
}

// Nœuds réellement nommés : les bornes en l'air en sont exclues.
std::set<std::string> noeuds_de(SceneSchema& scene) {
    // La netlist est gardée dans une variable : parcourir directement
    // « construire_netlist(...).instances() » lirait dans un objet déjà
    // détruit.
    const coeur::Netlist netlist = scene.construire_netlist(nullptr);
    std::set<std::string> noeuds;
    for (const coeur::Instance& instance : netlist.instances())
        for (const coeur::Borne& borne : instance.bornes)
            if (!borne.noeud.empty()) noeuds.insert(borne.noeud);
    return noeuds;
}

}  // namespace

static void test_gestes_utilisateur() {
    std::printf("\n-- gestes d'un utilisateur ordinaire --\n");

    // --- effacer deux composants reliés entre eux
    //
    // Le fil appartient aux deux : désigné deux fois, il était détruit deux
    // fois. L'application s'arrêtait net sur un « Ctrl+A puis Suppr ».
    {
        SceneSchema scene;
        ItemComposant* r = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* led = scene.ajouter_composant("led", QPointF(150, 0));
        scene.addItem(new ItemFil(r, 1, led, 0));
        r->setSelected(true);
        led->setSelected(true);
        scene.supprimer_selection();
        verifier(scene.composants().empty() && scene.fils().empty(),
                 "effacer deux composants reliés n'en laisse aucun");
        verifier(scene_propre(scene), "et rien ne traîne dans la scène");
    }

    // --- effacer avec une vue attachée, comme dans l'application
    //
    // Sans vue, Qt n'indexe pas la scène de la même façon : retirer un
    // composant ne fait alors recalculer le cadre d'aucun voisin. Avec une
    // vue, si — et c'est là que l'application s'arrêtait net, en demandant la
    // position d'une borne d'un composant déjà retiré.
    {
        SceneSchema scene;
        VueSchema vue;
        vue.setScene(&scene);
        vue.resize(800, 600);
        vue.show();
        std::vector<ItemComposant*> poses;
        for (int k = 0; k < 5; ++k)
            poses.push_back(scene.ajouter_composant(
                k % 2 ? "resistance" : "led", QPointF(k * 140, 0)));
        for (size_t k = 0; k + 1 < poses.size(); ++k)
            scene.addItem(new ItemFil(poses[k], 1, poses[k + 1], 0));
        QCoreApplication::processEvents();

        poses[2]->setSelected(true);
        scene.supprimer_selection();
        QCoreApplication::processEvents();
        verifier(scene.composants().size() == 4 && scene.fils().size() == 2,
                 "effacer sous une vue ouverte ne fait pas tomber la scène",
                 std::to_string(scene.composants().size()) + " composants, "
                     + std::to_string(scene.fils().size()) + " fils");
        for (QGraphicsItem* item : scene.items()) item->setSelected(true);
        scene.supprimer_selection();
        QCoreApplication::processEvents();
        verifier(scene.items().isEmpty(), "et tout effacer non plus");
    }

    // --- effacer tout un montage d'un coup, comme le fait « Ctrl+A, Suppr »
    {
        SceneSchema scene;
        std::vector<ItemComposant*> poses;
        for (int k = 0; k < 6; ++k)
            poses.push_back(scene.ajouter_composant(
                k % 2 ? "resistance" : "led", QPointF(k * 120, 0)));
        for (size_t k = 0; k + 1 < poses.size(); ++k)
            scene.addItem(new ItemFil(poses[k], 1, poses[k + 1], 0));
        for (QGraphicsItem* item : scene.items()) item->setSelected(true);
        scene.supprimer_selection();
        verifier(scene.items().isEmpty(),
                 "effacer une chaîne entière ne laisse rien",
                 std::to_string(scene.items().size()) + " objets restants");
    }

    // --- effacer un seul composant au milieu d'une chaîne
    {
        SceneSchema scene;
        ItemComposant* a = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* b = scene.ajouter_composant("led", QPointF(150, 0));
        ItemComposant* c = scene.ajouter_composant("resistance", QPointF(300, 0));
        scene.addItem(new ItemFil(a, 1, b, 0));
        scene.addItem(new ItemFil(b, 1, c, 0));
        b->setSelected(true);
        scene.supprimer_selection();
        verifier(scene.composants().size() == 2 && scene.fils().empty(),
                 "effacer le composant du milieu emporte ses deux fils",
                 std::to_string(scene.fils().size()) + " fil(s) restant(s)");
        verifier(fils_coherents(scene) && netlist_saine(scene),
                 "et ce qui reste est cohérent");
    }

    // --- effacer un fil seul : les composants restent
    {
        SceneSchema scene;
        ItemComposant* a = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* b = scene.ajouter_composant("led", QPointF(150, 0));
        ItemFil* fil = new ItemFil(a, 1, b, 0);
        scene.addItem(fil);
        fil->setSelected(true);
        scene.supprimer_selection();
        verifier(scene.composants().size() == 2 && scene.fils().empty(),
                 "effacer un fil laisse les composants en place");
        verifier(noeuds_de(scene).empty(),
                 "et les deux composants ne partagent plus de nœud",
                 std::to_string(noeuds_de(scene).size()) + " nœud(s)");
    }

    // --- la gomme, au clic, et son annulation
    {
        SceneSchema scene;
        ItemComposant* r = scene.ajouter_composant("resistance", QPointF(0, 0));
        scene.ajouter_composant("led", QPointF(200, 0));
        scene.oublier_historique();
        scene.definir_outil(SceneSchema::Outil::Suppression);
        envoyer(scene, QEvent::GraphicsSceneMousePress, r->pos());
        verifier(scene.composants().size() == 1,
                 "la gomme efface le composant visé",
                 std::to_string(scene.composants().size()));
        verifier(scene.peut_annuler() && scene.annuler()
                     && scene.composants().size() == 2,
                 "et le coup de gomme s'annule");
        scene.definir_outil(SceneSchema::Outil::Selection);
    }

    // --- effacer pendant qu'un fil est en cours de tracé
    //
    // Le fil en attente garde un pointeur sur son composant de départ : si
    // celui-ci disparaît, le clic suivant travaillerait sur un objet détruit.
    {
        SceneSchema scene;
        ItemComposant* r = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* led = scene.ajouter_composant("led", QPointF(200, 0));
        const QPointF borne = r->position_borne(1);
        envoyer(scene, QEvent::GraphicsSceneMousePress, borne);
        r->setSelected(true);
        scene.supprimer_selection();
        verifier(scene_propre(scene),
                 "effacer le départ d'un fil en cours ne laisse pas de trait");
        // Le clic suivant ne doit ni planter ni fabriquer un fil.
        envoyer(scene, QEvent::GraphicsSceneMousePress, led->position_borne(0));
        envoyer(scene, QEvent::GraphicsSceneMousePress, led->position_borne(1));
        verifier(fils_coherents(scene),
                 "et le câblage repart proprement ensuite");
    }

    // --- déplacer un composant câblé : les fils suivent
    {
        SceneSchema scene;
        ItemComposant* r = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* led = scene.ajouter_composant("led", QPointF(200, 0));
        scene.addItem(new ItemFil(r, 1, led, 0));
        const coeur::Netlist avant = scene.construire_netlist(nullptr);

        r->setPos(QPointF(0, 300));
        for (ItemFil* fil : scene.fils()) fil->rafraichir();
        // Le fil se redessine entre les deux bornes : son cadre doit donc
        // englober la borne qui vient de bouger.
        const QPointF depart = r->position_borne(1);
        const QRectF cadre =
            scene.fils().front()->boundingRect().adjusted(-2, -2, 2, 2);
        verifier(cadre.contains(depart), "le fil suit le composant déplacé",
                 f(depart.x()) + " ; " + f(depart.y()));

        const coeur::Netlist apres = scene.construire_netlist(nullptr);
        verifier(avant.instances().size() == apres.instances().size(),
                 "et le déplacement ne change pas la netlist");
        verifier(netlist_saine(scene), "la netlist reste saine après déplacement");
    }

    // --- superposer deux composants ne les relie pas
    {
        SceneSchema scene;
        ItemComposant* a = scene.ajouter_composant("resistance", QPointF(0, 0));
        scene.ajouter_composant("resistance", QPointF(400, 0));
        a->setPos(QPointF(400, 0));                 // pile sur l'autre
        verifier(noeuds_de(scene).empty(),
                 "deux composants superposés ne se relient pas tout seuls",
                 std::to_string(noeuds_de(scene).size()) + " nœud(s)");
    }

    // --- tourner un composant câblé
    {
        SceneSchema scene;
        ItemComposant* r = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* led = scene.ajouter_composant("led", QPointF(200, 0));
        scene.addItem(new ItemFil(r, 1, led, 0));
        const QString noeud_avant = scene.noeud_de(r, 1);
        r->setSelected(true);
        scene.oublier_historique();
        QKeyEvent touche(QEvent::KeyPress, Qt::Key_R, Qt::NoModifier);
        QApplication::sendEvent(&scene, &touche);
        verifier(fils_coherents(scene), "un composant tourné garde ses fils");
        verifier(scene.noeud_de(r, 1) == noeud_avant,
                 "et le nœud ne change pas de nom");
        verifier(scene.peut_annuler(), "la rotation au clavier s'annule aussi");
    }

    // --- câbler deux fois la même paire de bornes
    {
        SceneSchema scene;
        ItemComposant* a = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* b = scene.ajouter_composant("led", QPointF(200, 0));
        for (int essai = 0; essai < 2; ++essai) {
            envoyer(scene, QEvent::GraphicsSceneMousePress, a->position_borne(1));
            envoyer(scene, QEvent::GraphicsSceneMouseRelease, a->position_borne(1));
            envoyer(scene, QEvent::GraphicsSceneMouseMove, b->position_borne(0));
            envoyer(scene, QEvent::GraphicsSceneMousePress, b->position_borne(0));
        }
        verifier(netlist_saine(scene) && scene_propre(scene),
                 "câbler deux fois la même paire ne casse rien",
                 std::to_string(scene.fils().size()) + " fil(s)");
    }

    // --- annuler après une suppression rend le montage entier
    {
        SceneSchema scene;
        ItemComposant* r = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* led = scene.ajouter_composant("led", QPointF(200, 0));
        scene.addItem(new ItemFil(r, 1, led, 0));
        scene.oublier_historique();
        scene.memoriser();
        r->setSelected(true);
        led->setSelected(true);
        scene.supprimer_selection();
        verifier(scene.items().isEmpty(), "tout est effacé");
        verifier(scene.annuler(), "l'annulation aboutit");
        verifier(scene.composants().size() == 2 && scene.fils().size() == 1,
                 "le montage revient, fil compris",
                 std::to_string(scene.composants().size()) + " composants, "
                     + std::to_string(scene.fils().size()) + " fils");
        verifier(fils_coherents(scene) && netlist_saine(scene),
                 "et il est cohérent après retour");
    }

    // --- poser, effacer, reposer : les références ne se marchent pas dessus
    {
        SceneSchema scene;
        scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* deux = scene.ajouter_composant("resistance", QPointF(200, 0));
        deux->setSelected(true);
        scene.supprimer_selection();
        ItemComposant* trois = scene.ajouter_composant("resistance", QPointF(400, 0));
        std::set<QString> references;
        for (ItemComposant* composant : scene.composants())
            references.insert(composant->reference());
        verifier(references.size() == scene.composants().size(),
                 "aucune référence en double après suppression puis ajout",
                 trois->reference().toStdString());
    }

    // --- un montage complet malmené : on efface, on annule, on rétablit
    {
        SceneSchema scene;
        ItemComposant* carte = scene.ajouter_composant("arduino_uno", QPointF(0, 0));
        ItemComposant* led = scene.ajouter_composant("led", QPointF(300, 0));
        ItemComposant* r = scene.ajouter_composant("resistance", QPointF(500, 0));
        ItemComposant* masse = scene.ajouter_composant("masse", QPointF(700, 0));
        scene.addItem(new ItemFil(carte, 13, led, 0));
        scene.addItem(new ItemFil(led, 1, r, 0));
        scene.addItem(new ItemFil(r, 1, masse, 0));
        scene.oublier_historique();

        for (int tour = 0; tour < 3; ++tour) {
            scene.memoriser();
            led->setSelected(true);
            scene.supprimer_selection();
            verifier(fils_coherents(scene) && netlist_saine(scene)
                         && scene_propre(scene),
                     "après suppression, tout se tient (tour "
                         + std::to_string(tour + 1) + ")");
            verifier(scene.annuler(), "annulation du tour "
                                          + std::to_string(tour + 1));
            // Les objets ont été recréés : on retrouve la LED par sa référence.
            led = nullptr;
            for (ItemComposant* composant : scene.composants())
                if (composant->reference() == "LED1") led = composant;
            verifier(led != nullptr, "la LED est bien revenue");
            if (!led) break;
        }
        verifier(scene.composants().size() == 4 && scene.fils().size() == 3,
                 "le montage est intact après trois allers-retours",
                 std::to_string(scene.composants().size()) + " composants, "
                     + std::to_string(scene.fils().size()) + " fils");
    }
}

// ---------------------------------------------------------------------------
// Modifier le schéma pendant que ça tourne
//
// C'est le geste qu'on fait sans y penser : la simulation avance, on efface
// un composant, on en déplace un autre, on relance. Rien de tout cela ne doit
// laisser le moteur en travers.
// ---------------------------------------------------------------------------
static void test_modification_en_marche() {
    std::printf("\n-- modifier le schéma pendant la simulation --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r = scene.ajouter_composant("resistance", QPointF(250, 0));
    ItemComposant* led = scene.ajouter_composant("led", QPointF(500, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(750, 0));
    scene.addItem(new ItemFil(pile, 0, r, 0));
    scene.addItem(new ItemFil(r, 1, led, 0));
    scene.addItem(new ItemFil(led, 1, masse, 0));
    scene.addItem(new ItemFil(pile, 1, masse, 0));

    MoteurSimulation moteur;
    auto pousser = [&] {
        std::vector<LiaisonBroche> broches;
        moteur.definir_circuit(scene.construire_netlist(&broches), broches,
                               scene.cartes_presentes());
    };
    // La simulation avance sur un minuteur : pour la laisser tourner sans
    // ouvrir de fenêtre, on fait tourner la boucle d'événements un moment.
    auto tourner = [](int millisecondes) {
        QElapsedTimer chrono;
        chrono.start();
        while (chrono.elapsed() < millisecondes)
            QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
    };
    pousser();
    moteur.demarrer();
    verifier(moteur.etat() == MoteurSimulation::Etat::EnMarche,
             "un montage sans carte démarre");

    tourner(120);
    const double tension_avant = moteur.analogique().tension("LED1_A");
    verifier(std::fabs(tension_avant) > 0.5,
             "le circuit est bien alimenté avant modification",
             f(tension_avant) + " V");

    // --- on efface la LED en pleine simulation
    led->setSelected(true);
    scene.supprimer_selection();
    pousser();
    tourner(80);
    verifier(moteur.etat() == MoteurSimulation::Etat::EnMarche,
             "effacer un composant en marche n'arrête pas la simulation");
    verifier(scene.fils().size() == 2,
             "les fils de la LED sont partis avec elle",
             std::to_string(scene.fils().size()) + " fil(s)");

    // --- on déplace ce qui reste, toujours en marche
    r->setPos(QPointF(250, 400));
    for (ItemFil* fil : scene.fils()) fil->rafraichir();
    pousser();
    tourner(80);
    verifier(moteur.etat() == MoteurSimulation::Etat::EnMarche,
             "déplacer un composant en marche non plus");

    // --- on efface tout : le moteur doit encaisser un circuit vide
    for (QGraphicsItem* item : scene.items()) item->setSelected(true);
    scene.supprimer_selection();
    pousser();
    tourner(80);
    verifier(scene.items().isEmpty(), "le schéma est vide");

    // --- et on rebâtit derrière
    ItemComposant* pile2 = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(250, 0));
    ItemComposant* masse2 = scene.ajouter_composant("masse", QPointF(500, 0));
    scene.addItem(new ItemFil(pile2, 0, r2, 0));
    scene.addItem(new ItemFil(r2, 1, masse2, 0));
    scene.addItem(new ItemFil(pile2, 1, masse2, 0));
    pousser();
    tourner(150);
    // Les références repartent de là où elles s'étaient arrêtées : on cherche
    // donc la tension par le nœud que la netlist annonce, pas par un nom
    // deviné.
    double tension_apres = 0;
    std::string noeud_teste;
    for (const coeur::Instance& instance : moteur.netlist().instances())
        for (const coeur::Borne& borne : instance.bornes)
            if (!borne.noeud.empty()
                && std::fabs(moteur.analogique().tension(borne.noeud))
                       > std::fabs(tension_apres)) {
                tension_apres = moteur.analogique().tension(borne.noeud);
                noeud_teste = borne.noeud;
            }
    verifier(std::fabs(tension_apres) > 0.5,
             "un montage rebâti en marche est calculé aussitôt",
             noeud_teste + " = " + f(tension_apres) + " V");

    moteur.arreter();
    verifier(moteur.etat() == MoteurSimulation::Etat::Arrete,
             "et l'arrêt se passe bien");
}

// ---------------------------------------------------------------------------
// Les commandes suivent la page qu'on regarde
//
// « Pivoter » et « Supprimer » étaient des raccourcis de fenêtre : ils
// gagnaient toujours contre les gestionnaires de touches des vues, si bien
// que sur la page Circuit imprimé ils agissaient sur la sélection du schéma —
// invisible à l'écran. Une commande dont l'effet dépend d'une page qu'on ne
// voit pas est pire qu'une commande absente.
// ---------------------------------------------------------------------------
// Le pense-bête des raccourcis est engendré, donc il ne peut pas mentir.
//
// Une liste écrite à la main se désynchronise du code à la première
// modification, et un pense-bête qui ment est pire que pas de pense-bête. On
// vérifie donc qu'il contient bien les raccourcis réellement branchés — et
// qu'il en trouve un nombre plausible, pour attraper le cas où le parcours
// des menus casserait en silence.
static void test_pense_bete_engendre() {
    std::printf("\n-- le pense-bête des raccourcis --\n");

    FenetrePrincipale fenetre;
    // On relit ce que le parcours produirait, par le même chemin que la
    // fenêtre : les QAction des menus, sous-menus compris.
    int comptes = 0;
    QStringList raccourcis;
    std::function<void(QMenu*)> parcourir = [&](QMenu* menu) {
        for (QAction* action : menu->actions()) {
            if (action->menu()) { parcourir(action->menu()); continue; }
            if (action->isSeparator() || action->shortcut().isEmpty()) continue;
            ++comptes;
            raccourcis << action->shortcut().toString(QKeySequence::PortableText);
        }
    };
    for (QAction* haut : fenetre.menuBar()->actions())
        if (haut->menu()) parcourir(haut->menu());

    verifier(comptes >= 15,
             "la barre de menus porte assez de raccourcis pour valoir un "
             "pense-bête",
             std::to_string(comptes) + " raccourcis");
    // Les cinq du chantier 2 doivent y être : s'ils n'apparaissent pas, c'est
    // qu'ils ne sont pas dans un menu, donc introuvables pour l'utilisateur.
    for (const char* attendu : {"A", "W", "R", "Home", "Ctrl+A"})
        verifier(raccourcis.contains(QString(attendu)),
                 std::string("« ") + attendu + " » est dans un menu, donc "
                 "découvrable");
}

// « W » ne doit basculer dans AUCUN mode.
//
// Il basculait sur l'outil « Fil », ce qui rétablissait le mode que
// DECISION-FILS.md supprime. Simulink ne connaît pas non plus d'outil fil :
// on tire depuis un port, et c'est tout. Un raccourci qui rétablit un mode
// que le geste a supprimé est une régression déguisée en fonctionnalité.
// Un montage sans carte a une horloge, lui aussi.
//
// La barre d'état affichait « Temps simulé : 0,000 s » pendant que
// l'oscilloscope en était à soixante-six secondes : temps_ms() ne savait lire
// l'heure que sur une carte programmée. Or la moitié des exemples livrés sont
// purement analogiques — générateur, filtre, redresseur. Deux temps
// contradictoires sur le même écran.
// « Lancer » compile, et refuse de partir si le code est faux.
//
// Trois gestes constatés à l'usage : appuyer sur Lancer sans avoir compilé et
// voir la carte rester inerte ; ne pas savoir si le programme est faux ou
// simplement pas chargé ; et changer d'exemple pendant que ça tourne, ce qui
// laissait la simulation en marche sur un schéma qui n'existait plus.
// Un scope posé sur le schéma montre CE QU'ON LUI A CÂBLÉ.
//
// C'est le modèle de Simulink, et c'est ce qui le distingue de
// l'oscilloscope global déjà présent : on ne choisit pas les signaux dans une
// liste, on les branche. Le schéma documente alors lui-même ce qu'on observe,
// et deux scopes montrent deux endroits éloignés dans deux fenêtres.
// Viser une broche doit rester possible quel que soit le zoom.
//
// Le rayon de capture était exprimé en unités de scène : à 0,3× ses quatorze
// unités ne faisaient plus que quatre pixels à l'écran. On appuyait alors
// dans le vide, le rectangle de sélection démarrait, et le geste de câblage
// se changeait en sélection — sans que rien n'explique pourquoi ça marchait
// tout à l'heure et plus maintenant.
// Poser un point de passage en cliquant dans le vide.
//
// C'est le geste de Simulink et celui de Proteus — « if you want a wire in a
// particular place, you can simply click at the intermediate corners ». Le
// clic dans le vide abandonnait le tracé au lieu de le coude.
// Deux bornes presque alignées donnent un fil droit.
//
// Sans tolérance, trois pixels d'écart vertical suffisaient à produire une
// équerre en trois segments : un décrochement inutile au milieu du fil, qui
// salit le schéma et qu'aucun électronicien ne dessinerait à la main.
// Pendant qu'un fil se tire, la vue ne sélectionne plus.
//
// Le rectangle de sélection ne vient pas de la scène mais de la VUE :
// QGraphicsView le démarre quand la scène n'a pas accepté l'événement. Les
// branches de câblage faisaient « return » sans accepter, si bien qu'un fil
// se tirait ET qu'un rectangle s'ouvrait par-dessus, en même temps.
// La palette montre les symboles, pas seulement des mots.
//
// Un élève de première année reconnaît le zigzag d'une résistance bien avant
// de savoir écrire « potentiomètre » : il cherche un dessin. Le tracé existe
// déjà dans le modèle — il n'y avait aucun fichier graphique à créer.
static void test_palette_montre_les_symboles() {
    std::printf("\n-- la palette montre les symboles --\n");

    FenetrePrincipale fenetre;
    QTreeWidget* palette = fenetre.findChild<QTreeWidget*>();
    verifier(palette != nullptr, "la palette existe");
    if (!palette) return;

    int feuilles = 0, avec_icone = 0;
    for (int c = 0; c < palette->topLevelItemCount(); ++c) {
        QTreeWidgetItem* categorie = palette->topLevelItem(c);
        for (int k = 0; k < categorie->childCount(); ++k) {
            ++feuilles;
            if (!categorie->child(k)->icon(0).isNull()) ++avec_icone;
        }
    }
    verifier(feuilles > 30, "elle propose bien tout le catalogue",
             std::to_string(feuilles) + " composants");
    verifier(avec_icone == feuilles,
             "et chacun porte son propre symbole",
             std::to_string(avec_icone) + "/" + std::to_string(feuilles));

    // Une icône vide serait pire qu'aucune icône : elle promet un dessin et
    // ne montre rien. On vérifie qu'au moins un pixel est peint.
    QTreeWidgetItem* premier = palette->topLevelItem(0)->child(0);
    const QImage rendu = premier->icon(0).pixmap(22, 22).toImage();
    int peints = 0;
    for (int y = 0; y < rendu.height(); ++y)
        for (int x = 0; x < rendu.width(); ++x)
            if (qAlpha(rendu.pixel(x, y)) > 0) ++peints;
    verifier(peints > 10, "et le symbole est réellement dessiné",
             std::to_string(peints) + " pixels");
}

static void test_pas_de_selection_pendant_un_fil() {
    std::printf("\n-- pas de rectangle de sélection pendant un fil --\n");

    SceneSchema scene;
    VueSchema vue;
    vue.setScene(&scene);
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));

    verifier(vue.dragMode() == QGraphicsView::RubberBandDrag,
             "au repos, le rectangle de sélection est disponible");

    verifier(scene.amorcer_fil_au(pile->position_borne(0)),
             "on amorce un fil");
    verifier(vue.dragMode() == QGraphicsView::NoDrag,
             "pendant le tracé, la vue ne sélectionne plus");

    scene.abandonner_fil();
    verifier(vue.dragMode() == QGraphicsView::RubberBandDrag,
             "et elle reprend son droit dès que le fil est fini");
}

static void test_tolerance_alignement() {
    std::printf("\n-- tolérance avant qu'un fil monte --\n");

    // Un chemin droit n'a qu'un seul segment : deux points dans le tracé.
    const QPainterPath droit =
        ItemFil::chemin(QPointF(0, 0), QPointF(200, 3));
    verifier(droit.elementCount() == 2,
             "trois pixels d'écart : le fil reste droit",
             std::to_string(droit.elementCount()) + " points");

    const QPainterPath coude =
        ItemFil::chemin(QPointF(0, 0), QPointF(200, 60));
    verifier(coude.elementCount() == 4,
             "soixante pixels d'écart : le fil prend son équerre",
             std::to_string(coude.elementCount()) + " points");

    // Le cas vertical obéit à la même règle.
    const QPainterPath vertical =
        ItemFil::chemin(QPointF(0, 0), QPointF(4, 200));
    verifier(vertical.elementCount() == 2,
             "et deux bornes l'une au-dessus de l'autre restent droites");
}

static void test_points_de_passage() {
    std::printf("\n-- poser un point de passage --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r = scene.ajouter_composant("resistance", QPointF(600, 400));

    // On amorce depuis la borne de la pile, on coude deux fois, puis on
    // referme sur la résistance.
    verifier(scene.amorcer_fil_au(pile->position_borne(0)),
             "le tracé s'amorce sur la broche");
    scene.poser_point_de_passage(QPointF(300, 0));
    scene.poser_point_de_passage(QPointF(300, 400));
    verifier(scene.fils().size() == 2,
             "deux coudes posés font deux segments",
             std::to_string(scene.fils().size()));

    verifier(scene.terminer_fil(r->position_borne(0)),
             "et le chemin se referme sur la borne visée");
    verifier(scene.fils().size() == 3,
             "trois segments au total",
             std::to_string(scene.fils().size()));
    verifier(scene.noeud_de(pile, 0) == scene.noeud_de(r, 0),
             "les deux bornes sont bien sur le même nœud",
             scene.noeud_de(pile, 0).toStdString() + " / "
                 + scene.noeud_de(r, 0).toStdString());
    // Deux coudes : degré 2 chacun, donc aucune pastille — ce sont des
    // changements de direction, pas des dérivations.
    for (ItemJonction* j : scene.jonctions())
        verifier(!j->jonction(),
                 "un coude ne dessine pas de pastille de connexion");

    // Un chemin abandonné en route ne doit rien laisser derrière lui.
    const size_t avant = scene.fils().size();
    scene.amorcer_fil_au(pile->position_borne(1));
    scene.poser_point_de_passage(QPointF(-200, 300));
    scene.poser_point_de_passage(QPointF(-400, 300));
    scene.abandonner_fil();
    verifier(scene.fils().size() == avant,
             "un chemin abandonné ne laisse aucun segment",
             std::to_string(scene.fils().size()) + "/"
                 + std::to_string(avant));
}

static void test_capture_suit_le_zoom() {
    std::printf("\n-- viser une broche à tous les zooms --\n");

    SceneSchema scene;
    VueSchema vue;
    vue.setScene(&scene);
    vue.resize(800, 600);
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    const QPointF borne = pile->position_borne(0);

    // À zoom 1, on vise à dix unités de la borne : c'est dans la tolérance.
    vue.resetTransform();
    const QPointF pres(borne.x() + 10, borne.y());
    verifier(scene.viser(pres).genre == SceneSchema::Cible::Genre::Broche,
             "à zoom 1, viser à dix unités attrape la broche");

    // Dézoomé quatre fois, ces dix unités ne font plus que deux ou trois
    // pixels à l'écran : la tolérance doit s'élargir d'autant.
    vue.resetTransform();
    vue.scale(0.25, 0.25);
    verifier(scene.viser(pres).genre == SceneSchema::Cible::Genre::Broche,
             "dézoomé, la même main attrape toujours la broche");
    const QPointF loin(borne.x() + 45, borne.y());
    verifier(scene.viser(loin).genre == SceneSchema::Cible::Genre::Broche,
             "et même un peu plus loin, puisqu'à l'écran c'est aussi près",
             std::to_string(static_cast<int>(scene.viser(loin).genre)));

    // Zoomé, en revanche, la tolérance se resserre : on doit pouvoir viser
    // deux bornes voisines sans les confondre.
    vue.resetTransform();
    vue.scale(4.0, 4.0);
    const QPointF tres_loin(borne.x() + 30, borne.y());
    verifier(scene.viser(tres_loin).genre != SceneSchema::Cible::Genre::Broche,
             "zoomé, trente unités sont loin et n'attrapent plus rien");
}

static void test_scope_suit_son_cablage() {
    std::printf("\n-- un scope montre ce qu'on lui câble --\n");

    FenetrePrincipale fenetre;
    fenetre.definir_mode_silencieux(true);
    SceneSchema* scene = fenetre.scene();
    scene->tout_effacer();

    ItemComposant* pile = scene->ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene->ajouter_composant("resistance", QPointF(200, 0));
    ItemComposant* r2 = scene->ajouter_composant("resistance", QPointF(400, 0));
    ItemComposant* masse = scene->ajouter_composant("masse", QPointF(600, 0));
    ItemComposant* scope = scene->ajouter_composant("scope", QPointF(300, 250));
    verifier(scope != nullptr, "le bloc « scope » est au catalogue");
    if (!scope) return;

    scene->addItem(new ItemFil(pile, 0, r1, 0));
    scene->addItem(new ItemFil(r1, 1, r2, 0));
    scene->addItem(new ItemFil(r2, 1, masse, 0));
    scene->addItem(new ItemFil(pile, 1, masse, 0));
    // Voie 1 sur le haut du pont, voie 2 sur le milieu.
    scene->addItem(new ItemFil(scope, 0, r1, 0));
    scene->addItem(new ItemFil(scope, 1, r1, 1));

    const QString haut = scene->noeud_de(r1, 0);
    const QString milieu = scene->noeud_de(r1, 1);
    verifier(haut != milieu && !haut.isEmpty(),
             "les deux points observés sont bien deux nœuds distincts",
             haut.toStdString() + " / " + milieu.toStdString());

    fenetre.circuit_modifie_pour_essai();
    fenetre.ouvrir_scope(scope);
    Oscilloscope* vue = fenetre.scope_de(scope);
    verifier(vue != nullptr, "le double-clic ouvre une fenêtre pour CE scope");
    if (!vue) return;

    verifier(vue->signal_de_voie(0) == haut,
             "la voie 1 suit ce qui est câblé sur la borne A",
             vue->signal_de_voie(0).toStdString() + " attendu " + haut.toStdString());
    verifier(vue->signal_de_voie(1) == milieu,
             "la voie 2 suit ce qui est câblé sur la borne B",
             vue->signal_de_voie(1).toStdString() + " attendu " + milieu.toStdString());

    // Deux scopes = deux fenêtres indépendantes : c'est ce que l'oscilloscope
    // global ne sait pas faire.
    ItemComposant* second = scene->ajouter_composant("scope", QPointF(300, 400));
    fenetre.ouvrir_scope(second);
    verifier(fenetre.scope_de(second) != nullptr
                 && fenetre.scope_de(second) != vue,
             "un second scope a sa propre fenêtre");
}

static void test_lancer_compile_et_refuse() {
    std::printf("\n-- « Lancer » compile, et refuse un programme faux --\n");

    FenetrePrincipale fenetre;
    fenetre.definir_mode_silencieux(true);
    fenetre.charger_exemple(FenetrePrincipale::Exemple::Clignotant);

    if (!coeur::chaine_disponible_pour("atmega328p")) {
        std::printf("  (avr-g++ absent — section ignorée)\n");
        return;
    }

    // 1. Un programme faux doit EMPÊCHER le démarrage.
    fenetre.definir_programme_affiche("void setup() { ceci n'est pas du C++ }");
    fenetre.lancer_simulation();
    verifier(fenetre.etat_simulation() == MoteurSimulation::Etat::Arrete,
             "un programme qui ne compile pas empêche le lancement");

    // 2. Le programme d'origine, lui, part sans qu'on ait appuyé sur F5.
    fenetre.charger_exemple(FenetrePrincipale::Exemple::Clignotant);
    fenetre.lancer_simulation();
    verifier(fenetre.etat_simulation() == MoteurSimulation::Etat::EnMarche,
             "et « Lancer » suffit : il compile tout seul");

    // 3. Changer d'exemple pendant que ça tourne doit arrêter.
    fenetre.charger_exemple(FenetrePrincipale::Exemple::FiltreRC);
    verifier(fenetre.etat_simulation() == MoteurSimulation::Etat::Arrete,
             "changer d'exemple arrête la simulation en cours");
    fenetre.arreter_simulation();
}

static void test_horloge_sans_carte() {
    std::printf("\n-- un montage analogique a une horloge --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r = scene.ajouter_composant("resistance", QPointF(300, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(600, 0));
    scene.addItem(new ItemFil(pile, 0, r, 0));
    scene.addItem(new ItemFil(r, 1, masse, 0));
    scene.addItem(new ItemFil(pile, 1, masse, 0));

    MoteurSimulation moteur;
    std::vector<LiaisonBroche> broches;
    moteur.definir_circuit(scene.construire_netlist(&broches), broches,
                           scene.cartes_presentes());
    verifier(moteur.cartes().isEmpty(), "le montage n'a aucune carte");

    moteur.demarrer();
    QElapsedTimer chrono;
    chrono.start();
    while (chrono.elapsed() < 200)
        QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
    const double t = moteur.temps_ms();
    moteur.arreter();

    verifier(t > 0.0,
             "et son horloge avance quand même",
             f(t) + " ms");
}

static void test_amorcer_fil_sans_mode() {
    std::printf("\n-- amorcer un fil au clavier, sans mode --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    scene.ajouter_composant("resistance", QPointF(300, 0));

    verifier(scene.outil() == SceneSchema::Outil::Selection,
             "on part du mode sélection");

    // Sur une broche : le fil s'amorce.
    const QPointF borne = pile->position_borne(0);
    verifier(scene.amorcer_fil_au(borne),
             "sur une broche, le fil s'amorce");
    verifier(scene.outil() == SceneSchema::Outil::Selection,
             "et l'outil n'a PAS changé — c'est tout le sujet");

    // Dans le vide : rien ne s'amorce, et surtout on ne bascule nulle part.
    scene.abandonner_fil();
    verifier(!scene.amorcer_fil_au(QPointF(-900, -700)),
             "dans le vide, rien ne s'amorce");
    verifier(scene.outil() == SceneSchema::Outil::Selection,
             "et l'on n'est toujours dans aucun mode à quitter");

    // L'outil « Fil » ne doit plus s'offrir nulle part. Sa présence
    // enseignait le contraire de ce que fait le logiciel : un élève qui le
    // voit croit qu'il faut le choisir pour câbler, alors que cliquer une
    // broche suffit et a toujours suffi.
    FenetrePrincipale fenetre;
    QStringList libelles;
    std::function<void(QList<QAction*>)> ramasser = [&](QList<QAction*> actions) {
        for (QAction* action : actions) {
            if (action->menu()) { ramasser(action->menu()->actions()); continue; }
            QString nom = action->text();
            nom.remove('&');
            libelles << nom;
        }
    };
    for (QAction* haut : fenetre.menuBar()->actions())
        if (haut->menu()) ramasser(haut->menu()->actions());
    for (QToolBar* barre : fenetre.findChildren<QToolBar*>())
        ramasser(barre->actions());

    bool outil_fil_offert = false;
    for (const QString& nom : libelles)
        if (nom == "Fil") outil_fil_offert = true;
    verifier(!outil_fil_offert,
             "l'outil « Fil » ne s'offre plus ni en barre ni en menu");
    // Mais « Tirer un fil » — le raccourci sans mode — doit rester, lui.
    verifier(libelles.contains("Tirer un fil"),
             "tandis que « Tirer un fil » reste offert, sans mode");
}

static void test_portee_des_commandes() {
    std::printf("\n-- les commandes suivent la page affichée --\n");

    FenetrePrincipale fenetre;
    fenetre.definir_mode_silencieux(true);
    SceneSchema* scene = fenetre.scene();

    ItemComposant* r = scene->ajouter_composant("resistance", QPointF(0, 0));
    scene->clearSelection();
    r->setSelected(true);
    const double angle_depart = r->rotation();

    // Page Schéma : la commande agit.
    fenetre.afficher_page(0);
    fenetre.pivoter_sur_page_active();
    const double apres_schema = r->rotation();
    verifier(std::fabs(apres_schema - angle_depart) > 1.0,
             "sur la page Schéma, « Pivoter » tourne le composant sélectionné",
             f(angle_depart) + "° -> " + f(apres_schema) + "°");

    // Page Circuit imprimé : la même commande ne doit PLUS toucher au schéma.
    fenetre.ouvrir_pcb();
    verifier(fenetre.page_courante() == 1, "on est bien sur la page carte");
    r->setSelected(true);
    const double avant_pcb = r->rotation();
    fenetre.pivoter_sur_page_active();
    verifier(std::fabs(r->rotation() - avant_pcb) < 1e-9,
             "sur la page Circuit imprimé, elle ne pivote plus le schéma "
             "invisible",
             f(avant_pcb) + "° -> " + f(r->rotation()) + "°");

    // Idem pour la suppression : rien ne doit disparaître du schéma.
    const size_t avant = scene->composants().size();
    r->setSelected(true);
    fenetre.supprimer_sur_page_active();
    verifier(scene->composants().size() == avant,
             "et « Supprimer » n'efface rien du schéma non plus",
             std::to_string(scene->composants().size()) + " composants");

    // De retour au schéma, elle refonctionne.
    fenetre.afficher_page(0);
    r->setSelected(true);
    fenetre.supprimer_sur_page_active();
    verifier(scene->composants().size() == avant - 1,
             "de retour sur le schéma, elle efface de nouveau");
}

// ---------------------------------------------------------------------------
// Dérivation en T : un fil qui part d'un fil
//
// C'était impossible, et pas par oubli : `ItemFil` reliait deux broches de
// composant et rien d'autre, si bien qu'un fil partant d'un fil était
// inexprimable. L'ancre le rend dicible, la découpe le rend faisable.
//
// La règle à vérifier est électrique, pas graphique : après découpe, les
// trois fils doivent être sur le MÊME nœud. Un T qui se dessine sans relier
// serait pire que pas de T du tout.
// ---------------------------------------------------------------------------
static void test_derivation_en_t() {
    std::printf("\n-- dérivation en T --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(300, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(300, 200));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(600, 0));

    ItemFil* dorsale = new ItemFil(pile, 0, r1, 0);
    scene.addItem(dorsale);
    scene.addItem(new ItemFil(r1, 1, masse, 0));
    scene.addItem(new ItemFil(pile, 1, masse, 0));

    const size_t fils_avant = scene.fils().size();
    const QString noeud_dorsale = scene.noeud_de(r1, 0);

    // On dérive depuis le fil pile→R1 pour alimenter R2.
    ItemJonction* point = scene.decouper(dorsale, QPointF(150, 0));
    verifier(point != nullptr, "la découpe rend le point créé");
    verifier(scene.fils().size() == fils_avant + 1,
             "un fil coupé en deux en fait un de plus",
             std::to_string(scene.fils().size()) + " fils");
    verifier(scene.jonctions().size() == 1, "et pose exactement un point");

    scene.addItem(new ItemFil(Ancre(point), Ancre(r2, 0)));
    scene.addItem(new ItemFil(r2, 1, masse, 0));

    // Le contrôle qui compte : R2 doit se retrouver sur le nœud de la dorsale.
    verifier(scene.noeud_de(r1, 0) == noeud_dorsale,
             "la découpe ne change pas le nœud de la dorsale",
             scene.noeud_de(r1, 0).toStdString());
    verifier(scene.noeud_de(r2, 0) == noeud_dorsale,
             "la dérivation met R2 sur ce même nœud",
             scene.noeud_de(r2, 0).toStdString() + " attendu "
                 + noeud_dorsale.toStdString());
    verifier(scene.noeud_de(pile, 0) == noeud_dorsale,
             "et la pile y est toujours");

    // Le montage doit rester simulable : c'est le vrai juge.
    {
        std::vector<LiaisonBroche> broches;
        const coeur::Netlist netlist = scene.construire_netlist(&broches);
        MoteurSimulation moteur;
        moteur.definir_circuit(netlist, broches, scene.cartes_presentes());
        moteur.demarrer();
        QElapsedTimer chrono;
        chrono.start();
        while (chrono.elapsed() < 120)
            QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
        const double v = moteur.analogique().tension(
            scene.noeud_de(r2, 0).toStdString());
        verifier(std::fabs(v) > 0.5,
                 "le circuit dérivé est bien alimenté",
                 f(v) + " V");
        moteur.arreter();
    }

    // Effacer la dérivation doit reprendre le point : une pastille de
    // connexion là où plus rien ne se connecte serait un mensonge.
    for (ItemFil* fil : scene.fils()) {
        if (fil->ancre_depart().jonction != point) continue;
        if (fil->ancre_arrivee().composant != r2) continue;
        scene.removeItem(fil);
        delete fil;
        break;
    }
    scene.balayer_jonctions();
    verifier(scene.jonctions().size() == 1 && point->degre == 2,
             "le point retombe à deux fils : ce n'est plus une jonction mais "
             "un coude",
             std::to_string(point->degre) + " fils");
    verifier(!point->jonction(),
             "et il ne dessine plus de pastille — un point de connexion là où "
             "rien ne se connecte serait un mensonge");
    verifier(scene.noeud_de(r1, 0) == noeud_dorsale,
             "la dorsale reste d'un seul tenant à travers le coude");
}

// ---------------------------------------------------------------------------
// Ce que la relecture et l'annulation font d'une dérivation
//
// Quatre défauts prouvés par un agent à l'ASan et à valgrind, tous dans le
// code de câblage que je venais d'écrire, et aucun vu par le banc — parce
// qu'aucun test ne fabriquait de jonction autrement qu'en appelant
// `decouper()` en direct.
// ---------------------------------------------------------------------------
static void test_derivation_survit() {
    std::printf("\n-- la dérivation survit à l'enregistrement et à l'annulation --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(300, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(300, 200));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(600, 0));
    ItemFil* dorsale = new ItemFil(pile, 0, r1, 0);
    scene.addItem(dorsale);
    scene.addItem(new ItemFil(r1, 1, masse, 0));
    scene.addItem(new ItemFil(pile, 1, masse, 0));
    ItemJonction* point = scene.decouper(dorsale, QPointF(150, 0));
    scene.addItem(new ItemFil(Ancre(point), Ancre(r2, 0)));
    scene.addItem(new ItemFil(r2, 1, masse, 0));
    scene.balayer_jonctions();

    const QString noeud = scene.noeud_de(r2, 0);
    const size_t fils_avant = scene.fils().size();

    // 1. Aller-retour par le fichier. Le T était intégralement détruit : les
    //    fils touchant un point étaient jetés, faute d'être sérialisables.
    const QJsonObject sauve = scene.vers_json();
    SceneSchema relue;
    relue.depuis_json(sauve);
    verifier(relue.fils().size() == fils_avant,
             "tous les fils survivent à l'enregistrement",
             std::to_string(relue.fils().size()) + "/"
                 + std::to_string(fils_avant));
    verifier(relue.jonctions().size() == 1,
             "et le point de dérivation aussi",
             std::to_string(relue.jonctions().size()));
    ItemComposant* r2_relu = nullptr;
    for (ItemComposant* c : relue.composants())
        if (c->reference() == r2->reference()) r2_relu = c;
    verifier(r2_relu && relue.noeud_de(r2_relu, 0) == noeud,
             "la dérivation est toujours sur le même nœud après relecture",
             (r2_relu ? relue.noeud_de(r2_relu, 0).toStdString() : "absent")
                 + " attendu " + noeud.toStdString());

    // 2. Une annulation sans rapport ne doit pas emporter la dérivation.
    scene.memoriser();
    scene.ajouter_composant("resistance", QPointF(900, 400));
    scene.annuler();
    verifier(scene.fils().size() == fils_avant,
             "annuler un geste sans rapport laisse la dérivation intacte",
             std::to_string(scene.fils().size()) + "/"
                 + std::to_string(fils_avant));

    // 3. Effacer le point efface ses fils : les laisser pendants faisait lire
    //    une position dans de la mémoire libérée dès le premier redessin.
    scene.clearSelection();
    for (ItemJonction* j : scene.jonctions()) j->setSelected(true);
    scene.supprimer_selection();
    for (ItemFil* fil : scene.fils())
        verifier(fil->ancre_depart().jonction == nullptr
                     && fil->ancre_arrivee().jonction == nullptr,
                 "aucun fil ne pointe vers un point supprimé");
    QImage image(80, 60, QImage::Format_ARGB32);
    QPainter peintre(&image);
    scene.render(&peintre);      // le redessin lisait la mémoire libérée
    peintre.end();
    verifier(true, "et le schéma se redessine sans lire de mémoire libérée");

    // 4. Les deux garde-fous du banc doivent accepter une dérivation. Écrits
    //    sur `depart()`, qui rend nullptr sur un point, ils déclaraient
    //    incohérent un T parfaitement correct : ils étaient aveugles à la
    //    fonctionnalité qu'ils devaient garder.
    verifier(scene_propre(relue),
             "l'invariant « rien ne traîne » accepte un point de dérivation");
    verifier(fils_coherents(relue),
             "et l'invariant des fils accepte un fil accroché à un point");

    // 5. Un fil tendu entre DEUX points doit afficher sa tension : aucune de
    //    ses extrémités n'est une borne, et il restait sans mesure.
    {
        SceneSchema pont;
        ItemComposant* p = pont.ajouter_composant("pile", QPointF(0, 0));
        ItemComposant* rr = pont.ajouter_composant("resistance", QPointF(400, 0));
        ItemComposant* gnd = pont.ajouter_composant("masse", QPointF(800, 0));
        ItemFil* haut = new ItemFil(p, 0, rr, 0);
        pont.addItem(haut);
        pont.addItem(new ItemFil(rr, 1, gnd, 0));
        pont.addItem(new ItemFil(p, 1, gnd, 0));
        ItemJonction* j1 = pont.decouper(haut, QPointF(150, 0));
        ItemFil* moitie = nullptr;
        for (ItemFil* f : pont.fils())
            if (f->ancre_depart().jonction == j1 && f->ancre_arrivee().composant == rr)
                moitie = f;
        ItemJonction* j2 = pont.decouper(moitie, QPointF(300, 0));
        ItemFil* entre_points = new ItemFil(Ancre(j1), Ancre(j2));
        pont.addItem(entre_points);
        pont.balayer_jonctions();

        const QString noeud_haut = pont.noeud_de(rr, 0);
        std::map<std::string, double> tensions;
        tensions[noeud_haut.toLower().toStdString()] = 9.0;
        coeur::Formes vides;
        pont.appliquer_resultats({}, tensions, &vides);
        verifier(entre_points->tension_connue(),
                 "un fil tendu entre deux points affiche sa tension");
    }
}

// ---------------------------------------------------------------------------
// Ce qui aurait grillé
//
// Le solveur ne connaît que des équations. Une LED branchée sans résistance
// sur du 5 V lui donne un résultat parfaitement convergé — et sur la
// paillasse, la LED s'allume une fois. Une résistance d'un quart de watt qui
// en dissipe deux fait de même. Rien ne le disait : le montage avait l'air de
// marcher.
// ---------------------------------------------------------------------------
static void test_composants_grilles() {
    std::printf("\n-- ce qui aurait grillé --\n");

    auto tourner = [](int millisecondes) {
        QElapsedTimer chrono;
        chrono.start();
        while (chrono.elapsed() < millisecondes)
            QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
    };

    // Le montage de référence : 5 V, 220 Ω, une LED. Environ 13 mA, une
    // dizaine de milliwatts dans la résistance — tout est dans les clous, et
    // rien ne doit être signalé. C'est le test qui compte le plus : un
    // détecteur qui crie sur un montage correct ne sert à rien.
    {
        SceneSchema scene;
        ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
        ItemComposant* r = scene.ajouter_composant("resistance", QPointF(250, 0));
        ItemComposant* led = scene.ajouter_composant("led", QPointF(500, 0));
        ItemComposant* masse = scene.ajouter_composant("masse", QPointF(750, 0));
        pile->valeurs["volts"] = 5;
        r->valeurs["ohms"] = 220;
        scene.addItem(new ItemFil(pile, 0, r, 0));
        scene.addItem(new ItemFil(r, 1, led, 0));
        scene.addItem(new ItemFil(led, 1, masse, 0));
        scene.addItem(new ItemFil(pile, 1, masse, 0));

        MoteurSimulation moteur;
        std::vector<LiaisonBroche> broches;
        moteur.definir_circuit(scene.construire_netlist(&broches), broches,
                               scene.cartes_presentes());
        moteur.demarrer();
        tourner(150);
        const QSet<QString> grilles = moteur.composants_grilles();
        verifier(grilles.isEmpty(),
                 "un montage dans les clous ne grille rien",
                 grilles.values().join(", ").toStdString());
        moteur.arreter();
    }

    // La même LED, sans résistance. Le courant n'est plus limité que par la
    // résistance série du modèle : bien au-delà des 30 mA d'une 5 mm.
    {
        SceneSchema scene;
        ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
        ItemComposant* led = scene.ajouter_composant("led", QPointF(400, 0));
        ItemComposant* masse = scene.ajouter_composant("masse", QPointF(750, 0));
        pile->valeurs["volts"] = 5;
        scene.addItem(new ItemFil(pile, 0, led, 0));
        scene.addItem(new ItemFil(led, 1, masse, 0));
        scene.addItem(new ItemFil(pile, 1, masse, 0));

        MoteurSimulation moteur;
        std::vector<LiaisonBroche> broches;
        moteur.definir_circuit(scene.construire_netlist(&broches), broches,
                               scene.cartes_presentes());
        moteur.demarrer();
        tourner(150);
        verifier(moteur.composants_grilles().contains("LED1"),
                 "une LED sans résistance sur 5 V est signalée grillée");
        moteur.arreter();
        verifier(moteur.composants_grilles().isEmpty(),
                 "l'arrêt remet le montage à neuf");
    }

    // Une résistance trop petite pour la tension qu'on lui impose : 12 V sur
    // 100 Ω font 1,44 W, contre le quart de watt qu'elle encaisse.
    {
        SceneSchema scene;
        ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
        ItemComposant* r = scene.ajouter_composant("resistance", QPointF(400, 0));
        ItemComposant* masse = scene.ajouter_composant("masse", QPointF(750, 0));
        pile->valeurs["volts"] = 12;
        r->valeurs["ohms"] = 100;
        scene.addItem(new ItemFil(pile, 0, r, 0));
        scene.addItem(new ItemFil(r, 1, masse, 0));
        scene.addItem(new ItemFil(pile, 1, masse, 0));

        MoteurSimulation moteur;
        std::vector<LiaisonBroche> broches;
        moteur.definir_circuit(scene.construire_netlist(&broches), broches,
                               scene.cartes_presentes());
        moteur.demarrer();
        tourner(150);
        verifier(moteur.composants_grilles().contains("R1"),
                 "1,44 W dans une résistance d'un quart de watt est signalé");
        moteur.arreter();
    }

    // La même, déclarée pour cinq watts : la propriété de l'instance prime sur
    // le défaut du catalogue, et plus rien n'est signalé.
    {
        SceneSchema scene;
        ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
        ItemComposant* r = scene.ajouter_composant("resistance", QPointF(400, 0));
        ItemComposant* masse = scene.ajouter_composant("masse", QPointF(750, 0));
        pile->valeurs["volts"] = 12;
        r->valeurs["ohms"] = 100;
        r->valeurs["watts"] = 5;
        scene.addItem(new ItemFil(pile, 0, r, 0));
        scene.addItem(new ItemFil(r, 1, masse, 0));
        scene.addItem(new ItemFil(pile, 1, masse, 0));

        MoteurSimulation moteur;
        std::vector<LiaisonBroche> broches;
        moteur.definir_circuit(scene.construire_netlist(&broches), broches,
                               scene.cartes_presentes());
        moteur.demarrer();
        tourner(150);
        verifier(!moteur.composants_grilles().contains("R1"),
                 "une résistance déclarée 5 W encaisse les mêmes 1,44 W");
        moteur.arreter();
    }
}

// ---------------------------------------------------------------------------
// Traînées à l'écran : ce qu'on peint doit tenir dans ce qu'on déclare
//
// Qt n'efface qu'à l'intérieur du cadre annoncé par `boundingRect`. Tout ce
// qui est peint dehors reste imprimé sur l'écran quand l'objet bouge — c'est
// la traînée d'étiquettes qu'on voyait en déplaçant un composant.
//
// Le test est photographique : on peint l'objet sur fond blanc, et on regarde
// s'il a sali quoi que ce soit hors de son cadre.
// ---------------------------------------------------------------------------
namespace {

// Pixels peints hors du cadre déclaré, pour un objet seul sur fond blanc.
int debordement(QGraphicsItem* item, double rotation) {
    QGraphicsScene scene;
    scene.setBackgroundBrush(Qt::white);
    item->setRotation(rotation);
    scene.addItem(item);

    constexpr int kMarge = 120;
    const QRectF cadre = item->boundingRect();
    const QRectF zone = cadre.adjusted(-kMarge, -kMarge, kMarge, kMarge);
    QImage image(static_cast<int>(zone.width()), static_cast<int>(zone.height()),
                 QImage::Format_RGB32);
    image.fill(Qt::white);
    {
        QPainter peintre(&image);
        scene.render(&peintre, QRectF(image.rect()), zone);
    }

    // Le cadre, ramené aux coordonnées de l'image, avec un pixel de tolérance
    // pour l'anticrénelage des bords.
    const QRectF interne = cadre.translated(-zone.topLeft()).adjusted(-2, -2, 2, 2);
    int taches = 0;
    for (int y = 0; y < image.height(); ++y)
        for (int x = 0; x < image.width(); ++x) {
            if (interne.contains(x, y)) continue;
            if (image.pixel(x, y) != qRgb(255, 255, 255)) ++taches;
        }
    scene.removeItem(item);
    return taches;
}

}  // namespace

static void test_pas_de_trainee() {
    std::printf("\n-- rien n'est peint hors du cadre déclaré --\n");

    int modeles = 0, fautifs = 0;
    std::string liste;
    for (const coeur::Modele* modele : coeur::Catalogue::instance().tous()) {
        if (!modele) continue;
        const std::string& type = modele->type;
        ++modeles;
        // Le pire cas : une mesure affichée, une étiquette, et le composant
        // tourné d'un quart de tour — les textes sortent alors par le côté.
        for (double rotation : {0.0, 90.0, 180.0, 270.0}) {
            auto* item = new ItemComposant(modele, "REF12");
            item->definir_mesure("1234,5 tr/min");
            const int taches = debordement(item, rotation);
            if (taches > 0 && fautifs < 6) {
                liste += " " + type + "(" + std::to_string(static_cast<int>(rotation))
                         + "°:" + std::to_string(taches) + "px)";
            }
            if (taches > 0) ++fautifs;
            delete item;
        }
    }
    verifier(modeles > 25, "tout le catalogue est passé au crible",
             std::to_string(modeles) + " modèles × 4 orientations");
    verifier(fautifs == 0, "aucun composant ne peint hors de son cadre", liste);

    // --- un fil doit quitter l'ancien emplacement dans l'index de la scène
    //
    // C'est la traînée qu'on voyait en déplaçant un composant : le fil se
    // redessinait au bon endroit, mais Qt continuait de croire qu'il occupait
    // l'ancien — donc n'effaçait jamais ce qu'il y avait peint.
    {
        SceneSchema atelier;
        // Une vue attachée, sinon Qt n'indexe pas la scène et recalcule les
        // cadres à chaque interrogation : le défaut ne se voit plus.
        VueSchema vue;
        vue.setScene(&atelier);
        vue.resize(900, 700);
        vue.show();
        ItemComposant* a = atelier.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* b = atelier.ajouter_composant("led", QPointF(200, 0));
        atelier.addItem(new ItemFil(a, 1, b, 0));
        QCoreApplication::processEvents();

        const QRectF ancienne = atelier.fils().front()->sceneBoundingRect();
        // Les deux extrémités s'en vont : la bande d'origine doit se vider
        // complètement.
        a->setPos(QPointF(0, 900));
        b->setPos(QPointF(200, 900));
        QCoreApplication::processEvents();

        bool encore_la = false;
        for (QGraphicsItem* item : atelier.items(ancienne))
            if (item->type() == ItemFil::Type) encore_la = true;
        verifier(!encore_la,
                 "un fil déplacé ne reste pas inscrit à son ancienne place");
    }

    // --- même chose pour un fil, avec sa tension affichée
    {
        SceneSchema atelier;
        ItemComposant* a = atelier.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* b = atelier.ajouter_composant("led", QPointF(60, 0));
        auto* fil = new ItemFil(a, 1, b, 0);
        atelier.addItem(fil);
        fil->definir_tension(-12.345);
        atelier.removeItem(fil);
        verifier(debordement(fil, 0.0) == 0,
                 "un fil non plus, tension affichée comprise",
                 std::to_string(debordement(fil, 0.0)) + " px");
        atelier.addItem(fil);
    }
}

// Un panneau qui exige une largeur énorme la fait exiger par la fenêtre
// entière : tous les séparateurs se retrouvent alors collés à leur butée, plus
// aucun panneau ne peut être étiré, et la palette s'ouvre amputée. C'est
// exactement ce qui était arrivé — l'oscilloscope réclamait 1738 pixels, la
// fenêtre 1742, et sur un écran de 1920 il ne restait rien à distribuer.
//
// Ce test mesure ce que chaque panneau réclame. Il a des dents : sans les
// barres défilantes, il échoue.
static void test_panneaux_retrecissables() {
    std::printf("\n-- les panneaux acceptent d'être rétrécis --\n");

    // Une fenêtre de 1280 × 800 est un ordinateur portable ordinaire ; il faut
    // qu'il reste de la marge pour les trois panneaux latéraux et du bas.
    constexpr int kLargeurMax = 500;
    constexpr int kHauteurMax = 400;

    Oscilloscope oscilloscope;
    const QSize oscillo = oscilloscope.minimumSizeHint();
    verifier(oscillo.width() <= kLargeurMax && oscillo.height() <= kHauteurMax,
             "l'oscilloscope n'impose pas sa largeur à la fenêtre",
             std::to_string(oscillo.width()) + "x"
                 + std::to_string(oscillo.height()));

    PanneauAnalyses analyses;
    const QSize mesure = analyses.minimumSizeHint();
    verifier(mesure.width() <= kLargeurMax && mesure.height() <= kHauteurMax,
             "le panneau d'analyses n'impose pas sa largeur à la fenêtre",
             std::to_string(mesure.width()) + "x"
                 + std::to_string(mesure.height()));

    PanneauPcb pcb;
    const QSize carte = pcb.minimumSizeHint();
    verifier(carte.width() <= kLargeurMax && carte.height() <= kHauteurMax,
             "la page du circuit imprimé n'impose pas sa largeur au schéma",
             std::to_string(carte.width()) + "x"
                 + std::to_string(carte.height()));

    // Rétrécir ne doit rien rendre inatteignable : ce qui dépasse défile.
    oscilloscope.resize(420, 300);
    oscilloscope.show();
    QApplication::processEvents();
    int defilables = 0;
    for (QScrollArea* zone : oscilloscope.findChildren<QScrollArea*>())
        if (zone->widget()
            && zone->widget()->sizeHint().width() > zone->viewport()->width())
            ++defilables;
    verifier(defilables > 0,
             "les réglages trop larges deviennent défilants, pas coupés",
             std::to_string(defilables) + " zone(s) défilante(s)");
    oscilloscope.hide();
}


// Les cartes de la famille ATmega328P : Nano, Pro Mini, et la puce nue. Elles
// portent le même contrôleur que l'Uno — le cœur qui exécute le firmware ne
// doit voir aucune différence. Ce qui change est le nom des broches, et c'est
// précisément ce que ce test vérifie : PB5 et D13 doivent aboutir à la même
// broche interne, sans quoi un programme écrit pour la puce nue piloterait
// autre chose que ce qu'il croit.
static void test_famille_328p() {
    std::printf("\n-- Nano, Pro Mini et ATmega328P nu --\n");

    struct Cas {
        const char* type;
        const char* broche;      // la borne où l'on branche la LED
        int attendu;             // le numéro interne qu'elle doit recevoir
    };
    const Cas cas[] = {{"arduino_uno", "D13", 13},
                       {"arduino_nano", "D13", 13},
                       {"arduino_pro_mini", "D13", 13},
                       {"arduino_mega", "D13", 13},
                       {"atmega328p", "PB5", 13}};

    for (const Cas& essai : cas) {
        SceneSchema scene;
        ItemComposant* carte = scene.ajouter_composant(essai.type, QPointF(-400, 0));
        ItemComposant* led = scene.ajouter_composant("led", QPointF(0, 0));
        ItemComposant* masse = scene.ajouter_composant("masse", QPointF(300, 200));
        if (!carte) {
            verifier(false, std::string("la carte « ") + essai.type
                                + " » existe au catalogue", "absente");
            continue;
        }
        scene.addItem(new ItemFil(carte, borne(carte, essai.broche), led, 0));
        scene.addItem(new ItemFil(led, 1, masse, 0));

        std::vector<LiaisonBroche> broches;
        const coeur::Netlist netlist = scene.construire_netlist(&broches);

        int trouve = -1;
        for (const LiaisonBroche& liaison : broches)
            if (liaison.nom == essai.broche) trouve = liaison.numero;
        verifier(trouve == essai.attendu,
                 std::string(essai.type) + " : " + essai.broche
                     + " est bien la broche interne "
                     + std::to_string(essai.attendu),
                 "reçu " + std::to_string(trouve));
    }

    // A7 n'existe que sur le Nano et la Pro Mini, et seulement comme entrée
    // de convertisseur : elle doit recevoir un numéro, sinon analogRead(A7)
    // ne lirait rien.
    {
        SceneSchema scene;
        ItemComposant* nano = scene.ajouter_composant("arduino_nano", QPointF(0, 0));
        ItemComposant* pot = scene.ajouter_composant("potentiometre", QPointF(400, 0));
        scene.addItem(new ItemFil(nano, borne(nano, "A7"), pot, 1));
        std::vector<LiaisonBroche> broches;
        const coeur::Netlist netlist = scene.construire_netlist(&broches);
        int numero = -1;
        for (const LiaisonBroche& liaison : broches)
            if (liaison.nom == "A7") numero = liaison.numero;
        verifier(numero == 21, "A7 du Nano est une entrée de convertisseur",
                 "numéro " + std::to_string(numero));
    }

    // Le même nom, deux puces, deux broches. « PB1 » vaut 9 sur un ATmega328P
    // — c'est D9 — et 1 sur un ATtiny85. Confondre les deux ferait piloter la
    // mauvaise broche sans le moindre message d'erreur : c'est le genre de
    // faute qu'on cherche pendant une soirée.
    {
        struct Attendu { const char* type; int numero; };
        const Attendu attendus[] = {{"atmega328p", 9}, {"attiny85", 1}};
        for (const Attendu& attendu : attendus) {
            SceneSchema scene;
            ItemComposant* puce =
                scene.ajouter_composant(attendu.type, QPointF(0, 0));
            ItemComposant* led = scene.ajouter_composant("led", QPointF(400, 0));
            if (!puce) continue;
            scene.addItem(new ItemFil(puce, borne(puce, "PB1"), led, 0));
            std::vector<LiaisonBroche> broches;
            const coeur::Netlist netlist = scene.construire_netlist(&broches);
            int numero = -1;
            for (const LiaisonBroche& liaison : broches)
                if (liaison.nom == "PB1") numero = liaison.numero;
            verifier(numero == attendu.numero,
                     std::string("PB1 de ") + attendu.type + " est la broche "
                         + std::to_string(attendu.numero),
                     "reçu " + std::to_string(numero));
        }
    }

    // A0 n'est pas au même numéro selon la carte : 14 sur un Uno, 54 sur un
    // Mega, qui a cinquante-quatre broches numériques avant lui. Confondre
    // les deux ferait lire la mauvaise entrée du convertisseur.
    {
        struct Attendu { const char* type; const char* borne; int numero; };
        const Attendu attendus[] = {{"arduino_uno", "A0", 14},
                                    {"arduino_mega", "A0", 54},
                                    {"arduino_mega", "A15", 69},
                                    {"arduino_mega", "D42", 42}};
        for (const Attendu& attendu : attendus) {
            SceneSchema scene;
            ItemComposant* carte =
                scene.ajouter_composant(attendu.type, QPointF(0, 0));
            ItemComposant* pot =
                scene.ajouter_composant("potentiometre", QPointF(600, 0));
            if (!carte) continue;
            scene.addItem(new ItemFil(carte, borne(carte, attendu.borne), pot, 1));
            std::vector<LiaisonBroche> broches;
            const coeur::Netlist netlist = scene.construire_netlist(&broches);
            int numero = -1;
            for (const LiaisonBroche& liaison : broches)
                if (liaison.nom == attendu.borne) numero = liaison.numero;
            verifier(numero == attendu.numero,
                     std::string(attendu.borne) + " de " + attendu.type
                         + " est la broche " + std::to_string(attendu.numero),
                     "reçu " + std::to_string(numero));
        }
    }

    // Chaque carte doit dire quelle puce elle porte et à quelle vitesse : la
    // compilation comme l'exécution en dépendent.
    {
        SceneSchema scene;
        scene.ajouter_composant("attiny85", QPointF(0, 0));
        scene.ajouter_composant("arduino_uno", QPointF(600, 0));
        const std::vector<CartePosee> posees = scene.cartes_posees();
        bool tiny = false, uno = false;
        for (const CartePosee& posee : posees) {
            if (posee.mcu == "attiny85" && posee.horloge == 8000000) tiny = true;
            if (posee.mcu == "atmega328p" && posee.horloge == 16000000) uno = true;
        }
        verifier(posees.size() == 2 && tiny && uno,
                 "deux puces différentes cohabitent, chacune avec son horloge",
                 std::to_string(posees.size()) + " carte(s)");
    }

    // La tension logique n'est pas la même partout : cinq volts sur un AVR,
    // trois volts trois sur tout ce qui est moderne. Imposer cinq volts à un
    // Pico ferait passer dans une LED presque le double du courant réel — et
    // rien, à l'écran, ne le dirait.
    {
        struct Attendu { const char* type; double volts; };
        const Attendu attendus[] = {{"arduino_uno", 5.0}, {"attiny85", 5.0},
                                    {"pi_pico", 3.3}, {"stm32f103", 3.3},
                                    {"esp32", 3.3}};
        for (const Attendu& attendu : attendus) {
            const coeur::Modele* modele =
                coeur::Catalogue::instance().modele(attendu.type);
            verifier(modele
                         && std::fabs(modele->tension_logique - attendu.volts)
                                < 0.01,
                     std::string(attendu.type) + " sort "
                         + (attendu.volts > 4 ? "5 V" : "3,3 V"),
                     modele ? std::to_string(modele->tension_logique)
                            : std::string("modèle introuvable"));
        }
    }

    // Et chacune doit avoir une empreinte réelle : une carte sans empreinte
    // ne pourrait pas partir au routage.
    for (const Cas& essai : cas) {
        const coeur::Modele* modele =
            coeur::Catalogue::instance().modele(essai.type);
        if (!modele) continue;
        const coeur::Empreinte empreinte = coeur::empreintes::resoudre(*modele);
        const size_t bornes = modele->bornes.size();
        verifier(empreinte.pastilles.size() >= bornes && empreinte.largeur > 5,
                 std::string(essai.type) + " a une empreinte à ses cotes",
                 std::to_string(empreinte.pastilles.size()) + " pastilles, "
                     + std::to_string(static_cast<int>(empreinte.largeur))
                     + " mm");
    }
}


// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// L'analyseur d'impédance embarqué
//
// C'est le test qui met à l'épreuve tout le couplage d'un bout à l'autre : un
// vrai firmware, compilé par avr-g++, qui excite un RLC, l'échantillonne par
// son convertisseur, en fait une transformée de Fourier et publie le résultat
// sur sa liaison série. On relit ce qu'il a écrit, et l'on vérifie qu'il a
// trouvé la résonance là où la théorie la met.
//
// Ce test n'aurait rien donné avant que le convertisseur sache DATER ses
// mesures : la fenêtre de couplage figeant la tension pendant cinq
// millisecondes, le firmware relisait treize fois la même valeur et son
// spectre était plat.
// ---------------------------------------------------------------------------
static void test_analyseur_impedance() {
    std::printf("\n-- analyseur d'impédance embarqué --\n");

    if (!coeur::AvrEngine::avr_gpp_disponible()) {
        std::printf("  (avr-g++ absent — section ignorée)\n");
        return;
    }

    // Le montage : D8 attaque L en série avec C et le shunt. Deux diviseurs à
    // trois résistances ramènent les points de mesure autour de 5/3 V, ce qui
    // évite d'écrêter les alternances négatives.
    const double kL = 1.0, kC = 220e-9, kShunt = 470.0;
    const double f0 = 1.0 / (2 * 3.14159265358979323846 * std::sqrt(kL * kC));

    coeur::Netlist netlist;
    auto& l = netlist.ajouter("L1", "inductance");
    l.valeurs["henrys"] = kL;
    netlist.relier("L1", "1", "EXC");
    netlist.relier("L1", "2", "M");
    auto& c = netlist.ajouter("C1", "condensateur");
    c.valeurs["farads"] = kC;
    netlist.relier("C1", "1", "M");
    netlist.relier("C1", "2", "SHUNT");
    auto& rs = netlist.ajouter("R1", "resistance");
    rs.valeurs["ohms"] = kShunt;
    netlist.relier("R1", "1", "SHUNT");
    netlist.relier("R1", "2", "GND");
    netlist.ajouter("V5", "alim5v");
    netlist.relier("V5", "1", "VCC");

    // Les deux fronts de mesure, identiques : trois résistances de 22 kΩ.
    auto diviseur = [&netlist](const char* source, const char* sortie,
                               const char* r1, const char* r2, const char* r3) {
        auto& a = netlist.ajouter(r1, "resistance");
        a.valeurs["ohms"] = 22000;
        netlist.relier(r1, "1", source);
        netlist.relier(r1, "2", sortie);
        auto& b = netlist.ajouter(r2, "resistance");
        b.valeurs["ohms"] = 22000;
        netlist.relier(r2, "1", sortie);
        netlist.relier(r2, "2", "VCC");
        auto& d = netlist.ajouter(r3, "resistance");
        d.valeurs["ohms"] = 22000;
        netlist.relier(r3, "1", sortie);
        netlist.relier(r3, "2", "GND");
    };
    diviseur("SHUNT", "MES_I", "R2", "R3", "R4");
    diviseur("EXC", "MES_U", "R5", "R6", "R7");

    std::vector<LiaisonBroche> broches = {
        {8, "D8", "EXC", "U1"},        // excitation
        {14, "A0", "MES_I", "U1"},     // image du courant
        {15, "A1", "MES_U", "U1"}};    // image de l'excitation
    std::vector<CartePosee> cartes = {{"U1", "atmega328p", 16000000, 5.0, 25.0,
                                       35000.0}};

    MoteurSimulation moteur;
    moteur.definir_circuit(netlist, broches, cartes);

    QString journal;
    if (!moteur.compiler_et_charger(coeur::programme_analyseur("atmega328p"),
                                    QDir::tempPath(), &journal, "U1")) {
        verifier(false, "l'analyseur compile et se charge",
                 journal.toStdString());
        return;
    }
    verifier(true, "l'analyseur compile et se charge");

    QString sortie;
    QObject::connect(&moteur, &MoteurSimulation::octet_serie,
                     [&sortie](char octet, const QString&) { sortie += octet; });

    // Un balayage complet dure environ un demi-seconde simulée ; on en laisse
    // passer largement plus, le temps que la première ligne sorte de l'UART.
    moteur.avancer_simule(4.5);

    // Ce que le firmware a écrit : « f  U  I  |Z| » par ligne.
    struct Point { long f = 0, u = 0, i = 0, z = 0; };
    std::vector<Point> points;
    for (const QString& ligne : sortie.split('\n')) {
        const QStringList mots = ligne.simplified().split(' ');
        if (mots.size() != 4) continue;
        bool ok1 = false, ok2 = false, ok3 = false, ok4 = false;
        Point p;
        p.f = mots[0].toLong(&ok1);
        p.u = mots[1].toLong(&ok2);
        p.i = mots[2].toLong(&ok3);
        p.z = mots[3].toLong(&ok4);
        if (ok1 && ok2 && ok3 && ok4 && p.f > 0) points.push_back(p);
    }

    verifier(points.size() >= 9,
             "l'analyseur publie son balayage sur la liaison série",
             std::to_string(points.size()) + " point(s) relevé(s)");
    if (points.size() < 9) {
        std::printf("     sortie brute : %s\n",
                    sortie.left(300).toStdString().c_str());
        return;
    }

    // Le courant doit culminer à la résonance, et l'impédance y être minimale.
    size_t rang_i = 0, rang_z = 0;
    for (size_t k = 1; k < 9; ++k) {
        if (points[k].i > points[rang_i].i) rang_i = k;
        if (points[k].z < points[rang_z].z) rang_z = k;
    }
    verifier(std::fabs(points[rang_z].f - f0) < 0.12 * f0,
             "l'impédance mesurée est minimale à la résonance",
             std::to_string(points[rang_z].f) + " Hz contre " + f(f0, 0)
                 + " Hz attendus");
    // Le minimum d'impédance et le maximum de courant doivent tomber au même
    // point du balayage, ou sur deux points voisins : la mesure a la
    // résolution de son pas, pas davantage.
    const long ecart = std::labs(static_cast<long>(rang_z)
                                 - static_cast<long>(rang_i));
    verifier(ecart <= 1,
             "le courant culmine au même point, ou au point voisin",
             std::to_string(points[rang_z].f) + " Hz contre "
                 + std::to_string(points[rang_i].f) + " Hz");

    // À la résonance il ne reste que les résistances : le shunt, la sortie du
    // microcontrôleur et les diviseurs. L'ordre de grandeur doit être le bon.
    verifier(points[rang_z].z > 200 && points[rang_z].z < 1200,
             "l'impédance à la résonance vaut quelques centaines d'ohms",
             std::to_string(points[rang_z].z) + " Ω");
    // Et loin de la résonance, elle est bien plus grande : c'est le condensateur
    // en dessous, la bobine au-dessus.
    verifier(points[0].z > points[rang_z].z * 3
                 && points[8].z > points[rang_z].z * 3,
             "l'impédance remonte de part et d'autre",
             std::to_string(points[0].z) + " Ω à " + std::to_string(points[0].f)
                 + " Hz, " + std::to_string(points[8].z) + " Ω à "
                 + std::to_string(points[8].f) + " Hz");
    // La tension relevée n'est pas nulle : sans elle l'impédance ne voudrait
    // rien dire, et un convertisseur muet passerait inaperçu.
    verifier(points[rang_i].u > 100,
             "la tension aux bornes du montage est relevée elle aussi",
             std::to_string(points[rang_i].u) + " mV");

    std::printf("     relevé de la carte : ");
    for (size_t k = 0; k < 9; ++k)
        std::printf("%ld Hz:%ld Ω  ", points[k].f, points[k].z);
    std::printf("\n");
}


// ---------------------------------------------------------------------------
// Chaque carte compile SON programme, et seulement le sien
//
// Le piège est discret : deux cartes sur le même schéma, chacune avec ses
// fichiers annexes. Si les deux compilent dans le même dossier, celui de U1
// se retrouve dans le chemin d'inclusion de U2 — et « #include "mesure.h" »
// depuis U2 attrape le fichier de U1 sans que rien ne le signale. Le second
// piège est le fichier qu'on RETIRE d'un programme : s'il reste sur le
// disque, il continue de satisfaire son inclusion, et le programme compile
// encore alors qu'il ne le devrait plus.
// ---------------------------------------------------------------------------
static void test_programmes_par_carte() {
    std::printf("\n-- chaque carte compile son propre programme --\n");

    if (!coeur::AvrEngine::avr_gpp_disponible()) {
        std::printf("  (avr-g++ absent — section ignorée)\n");
        return;
    }

    coeur::Netlist netlist;
    std::vector<LiaisonBroche> broches = {{13, "D13", "L1", "U1"},
                                          {13, "D13", "L2", "U2"}};
    std::vector<CartePosee> cartes = {
        {"U1", "atmega328p", 16000000, 5.0, 25.0, 35000.0},
        {"U2", "atmega328p", 16000000, 5.0, 25.0, 35000.0}};

    MoteurSimulation moteur;
    moteur.definir_circuit(netlist, broches, cartes);
    const QString atelier = QDir::tempPath() + "/essai_deux_cartes";
    QDir(atelier).removeRecursively();

    // U1 déclare « mesure.h » avec une constante à elle.
    const coeur::Programme pour_u1 = {
        {"principal.ino",
         "#include \"mesure.h\"\n"
         "void setup() { pinMode(13, OUTPUT); }\n"
         "void loop() { digitalWrite(13, HIGH); delay(CADENCE);\n"
         "              digitalWrite(13, LOW);  delay(CADENCE); }\n"},
        {"mesure.h", "#pragma once\n#define CADENCE 100\n"}};
    QString journal;
    verifier(moteur.compiler_et_charger(pour_u1, atelier, &journal, "U1"),
             "U1 compile son programme à deux fichiers",
             journal.trimmed().toStdString());

    // U2 n'a PAS de « mesure.h ». Si le dossier était partagé, celui de U1
    // serait encore là et U2 compilerait — ce qui serait le défaut.
    const coeur::Programme pour_u2 = {
        {"principal.ino",
         "#include \"mesure.h\"\n"
         "void setup() { pinMode(13, OUTPUT); }\n"
         "void loop() { digitalWrite(13, HIGH); delay(CADENCE); }\n"}};
    QString journal_u2;
    const bool u2_compile =
        moteur.compiler_et_charger(pour_u2, atelier, &journal_u2, "U2");
    verifier(!u2_compile
                 && journal_u2.contains("mesure.h"),
             "U2 ne voit PAS le fichier de U1 : son inclusion échoue",
             u2_compile ? std::string("elle a compilé — les dossiers sont "
                                      "partagés")
                        : journal_u2.trimmed().left(70).toStdString());

    // U2 avec son propre « mesure.h » : cette fois cela doit passer.
    const coeur::Programme complet_u2 = {
        pour_u2.front(), {"mesure.h", "#pragma once\n#define CADENCE 250\n"}};
    verifier(moteur.compiler_et_charger(complet_u2, atelier, &journal_u2, "U2"),
             "U2 compile avec SON propre fichier",
             journal_u2.trimmed().toStdString());

    // Et le fichier retiré ne doit pas survivre : on recompile U2 sans lui.
    QString journal_apres;
    const bool encore =
        moteur.compiler_et_charger(pour_u2, atelier, &journal_apres, "U2");
    verifier(!encore,
             "un fichier retiré du programme ne traîne pas sur le disque",
             encore ? std::string("il a survécu au vidage")
                    : journal_apres.trimmed().left(60).toStdString());


    // --- une compilation ratée ne laisse pas tourner l'ancien programme ---
    //
    // Le piège : on corrige son code, on compile, le message d'erreur passe
    // inaperçu dans le journal, on lance — et c'est l'ANCIEN firmware qui
    // tourne. On croit alors que ses modifications n'ont aucun effet, ce qui
    // est la pire piste possible.
    {
        const coeur::Programme bon = {
            {"principal.ino",
             "void setup() { pinMode(13, OUTPUT); }\n"
             "void loop() { digitalWrite(13, HIGH); }\n"}};
        QString journal_bon;
        verifier(moteur.compiler_et_charger(bon, atelier, &journal_bon, "U1")
                     && moteur.firmware_charge("U1"),
                 "un programme correct se charge",
                 journal_bon.trimmed().toStdString());

        const coeur::Programme casse = {
            {"principal.ino", "void setup() { cette_ligne_est_fausse; }\n"}};
        QString journal_casse;
        const bool compile =
            moteur.compiler_et_charger(casse, atelier, &journal_casse, "U1");
        verifier(!compile, "un programme fautif ne compile pas");
        verifier(!moteur.firmware_charge("U1"),
                 "et l'ancien firmware a été DÉCHARGÉ : rien ne tourne à sa "
                 "place",
                 moteur.firmware_charge("U1")
                     ? std::string("l'ancien est resté en place")
                     : std::string("plus aucun firmware"));
    }

    // Les deux binaires existent, chacun chez soi. Les deux sont recompilés
    // d'abord : les essais précédents devaient échouer, et un échec ne laisse
    // pas de binaire — c'est justement ce qu'on vient de vérifier.
    moteur.compiler_et_charger(pour_u1, atelier, &journal, "U1");
    moteur.compiler_et_charger(complet_u2, atelier, &journal_u2, "U2");
    verifier(QFile::exists(atelier + "/carte_u1/firmware.elf")
                 && QFile::exists(atelier + "/carte_u2/firmware.elf"),
             "chaque carte a son propre dossier de compilation",
             "carte_u1/ et carte_u2/");
}

// ---------------------------------------------------------------------------
// Le survol allume tout le nœud
//
// La question à laquelle ce dispositif répond est celle de l'élève dont la LED
// ne s'allume pas : « qu'est-ce qui est relié à quoi ? » Un schéma immobile n'y
// répond pas — deux fils qui se croisent à l'écran se ressemblent, qu'ils
// soient reliés ou non. C'est le contrôle décisif de cette section.
// ---------------------------------------------------------------------------
static void test_survol_allume_le_noeud() {
    std::printf("\n-- le survol allume tout le nœud --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(300, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(600, 0));

    ItemFil* haut = new ItemFil(pile, 0, r1, 0);
    ItemFil* droite = new ItemFil(r1, 1, masse, 0);
    ItemFil* retour = new ItemFil(pile, 1, masse, 0);
    for (ItemFil* fil : {haut, droite, retour}) scene.addItem(fil);

    // --- ce que le nœud contient -------------------------------------------
    const SceneSchema::Noeud noeud = scene.noeud_sous(r1->position_borne(0));
    verifier(!noeud.nom.isEmpty(), "survoler une broche câblée nomme son nœud",
             noeud.nom.toStdString());
    verifier(noeud.nom == scene.noeud_de(r1, 0),
             "et c'est le nom que la netlist emploiera — pas un second calcul",
             noeud.nom.toStdString() + " / "
                 + scene.noeud_de(r1, 0).toStdString());
    verifier(noeud.bornes.size() == 2,
             "le nœud pile→R1 tient exactement deux bornes",
             std::to_string(noeud.bornes.size()));
    verifier(noeud.fils.size() == 1 && noeud.fils.front() == haut,
             "et le seul fil qui les relie");

    // --- le contrôle qui compte : le nœud voisin reste éteint --------------
    scene.allumer_noeud(r1->position_borne(0));
    verifier(haut->surbrillance(), "le fil du nœud survolé s'allume");
    verifier(!droite->surbrillance() && !retour->surbrillance(),
             "les fils des AUTRES nœuds restent éteints — sans quoi la "
             "surbrillance ne distinguerait plus deux fils qui se croisent");
    verifier(r1->bornes_allumees() == std::vector<int>{0},
             "sur R1, la borne 0 seule est allumée : un composant RELIE des "
             "nœuds, il n'en est pas un",
             std::to_string(r1->bornes_allumees().size()) + " borne(s)");

    // --- le corps d'un composant n'est pas un nœud -------------------------
    //
    // Viser à dix unités du centre, et non le centre lui-même : l'équerre du
    // fil pile→masse passe exactement par x = 300, et un fil l'emporte sur un
    // corps de composant (priorités 20 contre 70). Le premier jet de ce test
    // visait le centre et allumait GND — le classement de `viser()` faisait
    // son travail, c'est le point de mesure qui était mal choisi.
    scene.allumer_noeud(r1->pos() + QPointF(10, 0));
    verifier(scene.noeud_allume().isEmpty(),
             "survoler le CORPS d'un composant n'allume aucun nœud");
    verifier(!haut->surbrillance() && r1->bornes_allumees().empty(),
             "et éteint ce qui l'était");

    // --- une borne en l'air n'est pas un nœud ------------------------------
    ItemComposant* seule = scene.ajouter_composant("resistance", QPointF(0, 400));
    scene.allumer_noeud(seule->position_borne(0));
    verifier(scene.noeud_allume().isEmpty(),
             "une borne en l'air n'allume rien : elle n'est reliée à rien");

    // --- la surbrillance ne survit pas au schéma qui change ----------------
    //
    // Le piège qu'un raccourci « le nom n'a pas changé, ne rien faire »
    // laisserait passer : on rallume le MÊME nœud après avoir supprimé un de
    // ses fils. Le nom est identique, le contenu non.
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(300, 200));
    ItemFil* derivation = new ItemFil(r1, 0, r2, 0);
    scene.addItem(derivation);
    scene.allumer_noeud(r1->position_borne(0));
    verifier(derivation->surbrillance() && haut->surbrillance(),
             "les deux fils du nœud élargi s'allument");
    const QString avant = scene.noeud_allume();

    scene.removeItem(derivation);
    delete derivation;
    scene.allumer_noeud(r1->position_borne(0));
    verifier(scene.noeud_allume() == avant,
             "le nœud garde son nom après la suppression du fil dérivé",
             scene.noeud_allume().toStdString());
    verifier(r2->bornes_allumees().empty(),
             "mais R2 n'en fait plus partie : la surbrillance suit le schéma, "
             "pas le nom du nœud");
}


#include <QElapsedTimer>

static void experience_cout_survol() {
    std::printf("\n-- experience: cout de allumer_noeud() et emission changed --\n");
    for (int n : {5, 20, 60, 150, 300}) {
        SceneSchema scene;
        int compte_changed = 0;
        QObject::connect(&scene, &QGraphicsScene::changed,
                          [&](const QList<QRectF>&) { compte_changed++; });
        std::vector<ItemComposant*> rs;
        for (int i = 0; i < n; ++i)
            rs.push_back(scene.ajouter_composant(
                "resistance", QPointF(i * 60, 0)));
        for (int i = 0; i + 1 < n; ++i) {
            ItemFil* fil = new ItemFil(rs[i], 1, rs[i + 1], 0);
            scene.addItem(fil);
        }
        QElapsedTimer chrono;
        chrono.start();
        const int essais = 50;
        for (int e = 0; e < essais; ++e)
            scene.allumer_noeud(rs[n / 2]->position_borne(0));
        const qint64 ns = chrono.nsecsElapsed();
        QCoreApplication::processEvents();
        std::printf("  n=%4d composants : %6.1f microsecondes / appel a "
                    "allumer_noeud(), changed emis %d fois pour %d appels\n",
                    n, (double)ns / essais / 1000.0, compte_changed, essais);
    }
}

// ---------------------------------------------------------------------------
// Le marqueur ERC est posé À CÔTÉ, et il vise la borne
//
// Deux choses à ne pas confondre, et c'est tout l'objet de cette section : le
// noirci-barré dit « ce composant a grillé », un fait physique constaté
// pendant la simulation ; le triangle dit « ce schéma est incomplet ». Les
// dessiner pareil enseignerait qu'un fil oublié détruit un composant.
// ---------------------------------------------------------------------------
static void test_marqueur_erc_a_cote() {
    std::printf("\n-- le marqueur ERC est posé à côté, pas sur le composant --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(300, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(600, 0));
    // R1 n'est câblée que d'un côté : sa borne 2 reste en l'air. C'est
    // l'erreur de câblage la plus fréquente en TP.
    scene.addItem(new ItemFil(pile, 0, r1, 0));
    scene.addItem(new ItemFil(pile, 1, masse, 0));

    std::vector<LiaisonBroche> broches;
    const coeur::Netlist netlist = scene.construire_netlist(&broches);
    const std::vector<coeur::Anomalie> anomalies =
        coeur::controler_regles(netlist);

    // --- l'anomalie porte le nom de la borne, en clair -------------------
    bool borne_nommee = false;
    for (const coeur::Anomalie& anomalie : anomalies)
        if (anomalie.reference == "R1" && anomalie.borne == "2")
            borne_nommee = true;
    verifier(borne_nommee,
             "l'anomalie désigne la borne dans un champ, pas seulement dans "
             "sa phrase");

    // --- le marqueur atterrit sur la bonne borne -------------------------
    scene.poser_anomalies(anomalies);
    verifier(r1->anomalies().size() == 1,
             "R1 porte un marqueur, un seul",
             std::to_string(r1->anomalies().size()));
    verifier(!r1->anomalies().empty() && r1->anomalies().front().borne == 1,
             "et il vise la borne 2 (indice 1) — la borne, pas le corps");
    verifier(!r1->anomalies().empty() && r1->anomalies().front().erreur,
             "un composant à deux bornes mal câblé est une erreur, pas un "
             "avertissement");

    // --- le fait physique et le manquement aux règles restent distincts --
    verifier(!r1->grille(),
             "une borne en l'air ne noircit PAS le composant : un fil oublié "
             "ne détruit rien");
    scene.marquer_grille("R1");
    verifier(r1->grille() && r1->anomalies().size() == 1,
             "les deux marques coexistent sans se confondre");

    // --- corriger le câblage retire le marqueur --------------------------
    scene.addItem(new ItemFil(r1, 1, masse, 0));
    std::vector<LiaisonBroche> broches2;
    const coeur::Netlist complete = scene.construire_netlist(&broches2);
    scene.poser_anomalies(coeur::controler_regles(complete));
    verifier(r1->anomalies().empty(),
             "le fil enfin tiré fait disparaître le marqueur");

    // --- une référence qui n'est pas un composant ne marque rien ---------
    //
    // `Anomalie.reference` est tantôt une référence, tantôt un nom de nœud,
    // tantôt une liste jointe par virgules. Les deux dernières formes ne
    // doivent marquer aucun symbole plutôt que de marquer le mauvais.
    coeur::Anomalie noeud;
    noeud.gravite = coeur::Anomalie::Gravite::Erreur;
    noeud.reference = "GND";           // un nœud, pas un composant
    coeur::Anomalie liste;
    liste.gravite = coeur::Anomalie::Gravite::Erreur;
    liste.reference = "R1, V1";        // deux composants d'un coup
    scene.poser_anomalies({noeud, liste});
    verifier(r1->anomalies().size() == 1,
             "la liste jointe par virgules marque bien R1",
             std::to_string(r1->anomalies().size()));
    verifier(pile->anomalies().size() == 1,
             "et V1 aussi, dans la même anomalie",
             std::to_string(pile->anomalies().size()));
    verifier(masse->anomalies().empty(),
             "tandis qu'un nom de nœud ne marque aucun symbole");
}

// ---------------------------------------------------------------------------
// Mode présentation, et mémoire de la disposition
//
// Le mode présentation sert le vidéo-projecteur de la salle ; la
// réinitialisation sert le poste partagé, où un élève qui replie un panneau
// à zéro le lègue au suivant sans que celui-ci sache quoi rappeler.
// ---------------------------------------------------------------------------
static void test_presentation_et_disposition() {
    std::printf("\n-- mode présentation et mémoire de la disposition --\n");

    FenetrePrincipale fenetre;
    fenetre.show();
    QCoreApplication::processEvents();

    const QList<QDockWidget*> docks = fenetre.findChildren<QDockWidget*>();
    verifier(!docks.isEmpty(), "la fenêtre a bien des panneaux",
             std::to_string(docks.size()) + " panneaux");

    // --- F11 : tout disparaît sauf le schéma -----------------------------
    fenetre.basculer_presentation();
    QCoreApplication::processEvents();
    verifier(fenetre.en_presentation(), "F11 entre en mode présentation");
    bool un_dock_visible = false;
    for (QDockWidget* dock : docks)
        if (dock->isVisible()) un_dock_visible = true;
    verifier(!un_dock_visible, "aucun panneau ne reste visible");
    verifier(!fenetre.menuBar()->isVisible(),
             "la barre de menus s'efface aussi : elle mange une ligne sur un "
             "vidéo-projecteur");

    // --- et tout revient -------------------------------------------------
    fenetre.basculer_presentation();
    QCoreApplication::processEvents();
    verifier(!fenetre.en_presentation(), "un second F11 en sort");
    verifier(fenetre.menuBar()->isVisible(), "la barre de menus revient");

    // --- réinitialiser rend un panneau replié -----------------------------
    //
    // Le geste qu'on répare : replier un panneau à zéro. Qt le laisse faire,
    // et rien à l'écran ne dit ensuite comment le rappeler.
    QDockWidget* palette = nullptr;
    for (QDockWidget* dock : docks)
        if (dock->objectName() == "dock_palette") palette = dock;
    verifier(palette != nullptr, "la palette est identifiable par son nom "
                                 "d'objet — sans quoi Qt ne sait pas la "
                                 "réenregistrer");
    if (palette) {
        palette->hide();
        QCoreApplication::processEvents();
        verifier(!palette->isVisible(), "la palette est repliée");
        fenetre.reinitialiser_disposition();
        QCoreApplication::processEvents();
        verifier(palette->isVisible(),
                 "« Réinitialiser la disposition » la fait revenir");
    }
}

// ---------------------------------------------------------------------------
// Le cartouche est sur le papier, et NULLE PART ailleurs
//
// Les deux moitiés comptent autant l'une que l'autre. Sur le papier, sans
// lui, trente copies de TP sont anonymes et le professeur n'a aucun moyen de
// les rattacher. À l'écran, la place est trop précieuse pour une information
// qui ne sert qu'une fois la feuille détachée du logiciel.
// ---------------------------------------------------------------------------
static void test_cartouche_a_l_impression_seulement() {
    std::printf("\n-- le cartouche est à l'impression, pas à l'écran --\n");

    FenetrePrincipale fenetre;
    SceneSchema* scene = fenetre.scene();
    scene->tout_effacer();
    ItemComposant* pile = scene->ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene->ajouter_composant("resistance", QPointF(200, 0));
    scene->addItem(new ItemFil(pile, 0, r1, 0));

    // --- rien de neuf à l'écran -------------------------------------------
    //
    // On rend la scène telle qu'elle s'affiche, puis on compte les pixels
    // non blancs de la bande basse. Un cartouche y laisserait un cadre.
    const QRectF zone = scene->itemsBoundingRect().adjusted(-20, -20, 20, 20);
    QImage ecran(600, 400, QImage::Format_ARGB32);
    ecran.fill(Qt::white);
    {
        QPainter peintre(&ecran);
        scene->render(&peintre, QRectF(ecran.rect()), zone, Qt::KeepAspectRatio);
    }
    int encre_en_bas = 0;
    for (int y = ecran.height() - 40; y < ecran.height(); ++y)
        for (int x = 0; x < ecran.width(); ++x)
            if (ecran.pixelColor(x, y) != QColor(Qt::white)) ++encre_en_bas;
    verifier(encre_en_bas == 0,
             "la scène rendue seule ne porte aucun cartouche",
             std::to_string(encre_en_bas) + " pixels encrés");

    // --- mais il est bien dessiné quand on le demande ----------------------
    QImage papier(600, 400, QImage::Format_ARGB32);
    papier.fill(Qt::white);
    {
        QPainter peintre(&papier);
        fenetre.dessiner_cartouche(&peintre, QRectF(0, 340, 600, 60));
    }
    int encre_cartouche = 0;
    for (int y = 340; y < 400; ++y)
        for (int x = 0; x < 600; ++x)
            if (papier.pixelColor(x, y) != QColor(Qt::white)) ++encre_cartouche;
    verifier(encre_cartouche > 200,
             "dessiné à la demande, le cartouche marque bien le bandeau",
             std::to_string(encre_cartouche) + " pixels encrés");

    // Le haut de la feuille reste au schéma : le cartouche ne déborde pas sur
    // le montage qu'il décrit.
    //
    // La marge de deux pixels n'est pas de la complaisance : le trait du
    // cadre est CENTRÉ sur le bord du rectangle, il mord donc d'un demi-trait
    // au-dessus par construction. Un seuil à zéro échouait sur exactement
    // 600 pixels — la largeur de l'image, soit une seule ligne, celle du
    // bord. Ce qu'il faut interdire, c'est l'empiètement sur le dessin, pas
    // l'épaisseur du trait de cadre.
    int encre_hors_bandeau = 0;
    for (int y = 0; y < 338; ++y)
        for (int x = 0; x < 600; ++x)
            if (papier.pixelColor(x, y) != QColor(Qt::white))
                ++encre_hors_bandeau;
    verifier(encre_hors_bandeau == 0,
             "et il ne déborde pas de son bandeau",
             std::to_string(encre_hors_bandeau) + " pixels débordés");

    // --- l'export PDF passe bien par là ------------------------------------
    const QString pdf = QDir::tempPath() + "/cartouche-essai.pdf";
    QFile::remove(pdf);
    verifier(fenetre.exporter_schema(pdf), "l'export PDF aboutit");
    verifier(QFile::exists(pdf) && QFileInfo(pdf).size() > 0,
             "et produit un fichier non vide");
    QFile::remove(pdf);
}

// ---------------------------------------------------------------------------
// Cliquer une erreur de compilation mène à la ligne fautive
//
// C'est la PREMIÈRE erreur que rencontre un élève, et l'éditeur est dans la
// même fenêtre. Jusqu'ici la sortie d'avr-g++ était déversée telle quelle,
// à charge pour lui de recompter les lignes.
// ---------------------------------------------------------------------------
static void test_erreur_compilation_cliquable() {
    std::printf("\n-- cliquer une erreur mène à la ligne fautive --\n");

    using Erreur = FenetrePrincipale::ErreurCompilation;

    // --- la forme ordinaire, telle qu'avr-g++ 7.3 l'écrit ------------------
    {
        const QString sortie =
            "principal.ino:12:5: error: 'digitalWrit' was not declared in "
            "this scope\n"
            "   digitalWrit(13, HIGH);\n"
            "   ^~~~~~~~~~~\n";
        const std::vector<Erreur> lues =
            FenetrePrincipale::analyser_sortie_compilateur(sortie);
        verifier(lues.size() == 1, "une erreur lue dans un compte rendu ordinaire",
                 std::to_string(lues.size()));
        if (!lues.empty()) {
            verifier(lues[0].fichier == "principal.ino"
                         && lues[0].ligne == 12 && lues[0].colonne == 5,
                     "fichier, ligne et colonne sont extraits",
                     lues[0].fichier.toStdString() + ":"
                         + std::to_string(lues[0].ligne) + ":"
                         + std::to_string(lues[0].colonne));
            verifier(lues[0].erreur, "et c'est bien une erreur");
        }
    }

    // --- la sortie RÉELLE d'avr-g++ 7.3.0, recopiée telle quelle ----------
    //
    // Relevée en compilant pour de bon un croquis fautif. Les deux lignes
    // « In function » n'ont pas de numéro et ne doivent rien déclencher :
    // c'est du contexte, pas un endroit à corriger.
    {
        const QString sortie =
            "principal.ino: In function 'void setup()':\n"
            "principal.ino:1:15: error: 'digitalWrit' was not declared in this "
            "scope\n"
            "principal.ino: In function 'void loop()':\n"
            "principal.ino:2:22: error: expected primary-expression before ';' "
            "token\n";
        const std::vector<Erreur> lues =
            FenetrePrincipale::analyser_sortie_compilateur(sortie);
        verifier(lues.size() == 2,
                 "deux erreurs lues dans la sortie réelle d'avr-g++ 7.3.0, "
                 "sans prendre les lignes « In function » pour des défauts",
                 std::to_string(lues.size()));
        if (lues.size() == 2)
            verifier(lues[0].ligne == 1 && lues[0].colonne == 15
                         && lues[1].ligne == 2 && lues[1].colonne == 22,
                     "aux bonnes lignes et colonnes");
    }

    // --- le compilateur suit la LOCALE ------------------------------------
    //
    // Le conteneur qui fait tourner ce banc est en anglais ; la salle de
    // classe est en français. Un analyseur qui ne lirait que « error: »
    // marcherait ici et nulle part là-bas.
    {
        const std::vector<Erreur> lues =
            FenetrePrincipale::analyser_sortie_compilateur(
                "mesure.ino:4:1: erreur: « capteur » n'a pas été déclaré\n");
        verifier(lues.size() == 1 && lues[0].erreur && lues[0].ligne == 4,
                 "« erreur: » en français est reconnu comme « error: »",
                 std::to_string(lues.size()) + " lue(s)");
    }

    // --- avertissements, colonne absente, notes ----------------------------
    {
        const QString sortie =
            "principal.ino:7: warning: unused variable 'x'\n"
            "principal.ino:9:2: note: in expansion of macro 'F'\n"
            "principal.ino:11:3: error: expected ';' before '}' token\n";
        const std::vector<Erreur> lues =
            FenetrePrincipale::analyser_sortie_compilateur(sortie);
        verifier(lues.size() == 2,
                 "la « note » est écartée : elle complète l'erreur précédente, "
                 "elle n'ajoute aucun endroit à corriger",
                 std::to_string(lues.size()));
        if (lues.size() == 2) {
            verifier(!lues[0].erreur && lues[0].ligne == 7
                         && lues[0].colonne == 0,
                     "un avertissement sans colonne reste exploitable");
            verifier(lues[1].erreur && lues[1].ligne == 11,
                     "et l'erreur qui suit est bien lue");
        }
    }

    // --- une ligne quelconque du journal n'est pas une erreur --------------
    {
        const std::vector<Erreur> lues =
            FenetrePrincipale::analyser_sortie_compilateur(
                "Compilation réussie.\n"
                "Temps simulé : 1.500 s\n"
                "Nœud R1_2 — R1.2 · D1.1\n");
        verifier(lues.empty(),
                 "aucune ligne ordinaire du journal n'est prise pour une "
                 "erreur",
                 std::to_string(lues.size()) + " fausse(s) prise(s)");
    }

    // --- et le saut atterrit sur la bonne ligne ---------------------------
    {
        FenetrePrincipale fenetre;
        Erreur cible;
        cible.fichier = "n-existe-pas.ino";
        cible.ligne = 3;
        verifier(!fenetre.aller_a_erreur(cible),
                 "un fichier étranger au programme ne fait sauter nulle part");
    }
}

// ---------------------------------------------------------------------------
// Le panneau « Contrôle » mène au coupable
//
// Le piège de cette section, et la raison pour laquelle elle existe :
// `Anomalie.reference` est tantôt une référence de composant, tantôt un nom
// de nœud, tantôt une liste jointe par virgules. Un clic qui ne traiterait
// que le premier cas serait mort sur un bon tiers des lignes — et un clic
// mort est pire qu'une ligne non cliquable, puisqu'il se laisse essayer.
// ---------------------------------------------------------------------------
static void test_panneau_controle_mene_au_coupable() {
    std::printf("\n-- le panneau Contrôle mène au coupable --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(300, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(600, 0));
    scene.addItem(new ItemFil(pile, 0, r1, 0));
    scene.addItem(new ItemFil(r1, 1, masse, 0));
    scene.addItem(new ItemFil(pile, 1, masse, 0));

    // --- forme 1 : une référence de composant -----------------------------
    const QRectF sur_r1 = scene.designer_anomalie("R1");
    verifier(!sur_r1.isNull(), "une référence désigne un rectangle à cadrer");
    verifier(r1->isSelected() && !pile->isSelected(),
             "et sélectionne ce composant, lui seul");

    // --- forme 2 : une liste jointe par virgules ---------------------------
    const QRectF sur_deux = scene.designer_anomalie("R1, V1");
    verifier(!sur_deux.isNull() && r1->isSelected() && pile->isSelected(),
             "une liste jointe par virgules les sélectionne tous les deux");
    verifier(sur_deux.width() > sur_r1.width(),
             "et le cadre les englobe — il est plus large que celui de R1 "
             "seule",
             f(sur_deux.width()) + " contre " + f(sur_r1.width()));

    // --- forme 3 : un nom de nœud -----------------------------------------
    //
    // Un nœud n'a pas de symbole. Ce sont ses fils qui le matérialisent, et
    // les sélectionner montre son étendue exacte.
    const QString noeud = scene.noeud_de(r1, 0);
    verifier(!noeud.isEmpty(), "le nœud de R1.1 porte bien un nom",
             noeud.toStdString());
    const QRectF sur_noeud = scene.designer_anomalie(noeud);
    verifier(!sur_noeud.isNull(),
             "un nom de nœud désigne lui aussi un rectangle — pas un clic mort");
    int fils_choisis = 0;
    for (ItemFil* fil : scene.fils())
        if (fil->isSelected()) ++fils_choisis;
    verifier(fils_choisis >= 1,
             "et ce sont les FILS du nœud qui sont sélectionnés",
             std::to_string(fils_choisis) + " fil(s)");

    // --- ce qui ne désigne rien ne prétend pas le contraire ----------------
    verifier(scene.designer_anomalie("R99").isNull(),
             "une référence absente ne rend aucun cadre");
    verifier(scene.designer_anomalie("").isNull(),
             "une référence vide non plus — c'est le cas de « aucune masse », "
             "qui porte sur le montage entier");
}

// ---------------------------------------------------------------------------
// Ce qu'une relecture a trouvé, et que le premier banc laissait passer
//
// Quatre défauts rapportés par `critique-code`, tous avec leur scénario.
// Trois cassaient réellement quelque chose. Ils sont ici AVANT leur
// correction : c'est la seule façon de savoir que ces tests prouvent
// quelque chose.
// ---------------------------------------------------------------------------
static void test_survol_noeuds_noues_par_le_nom() {
    std::printf("\n-- le survol suit les nœuds noués par le NOM --\n");

    // Deux masses, sans le moindre fil entre elles. Elles SONT le même nœud
    // — c'est même la première chose qu'un cours d'électronique enseigne, et
    // la raison d'être du symbole de masse. Un survol qui n'en allume qu'une
    // enseignerait le contraire.
    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(300, 0));
    ItemComposant* m1 = scene.ajouter_composant("masse", QPointF(0, 200));
    ItemComposant* m2 = scene.ajouter_composant("masse", QPointF(600, 200));
    scene.addItem(new ItemFil(pile, 0, r1, 0));
    scene.addItem(new ItemFil(pile, 1, m1, 0));
    scene.addItem(new ItemFil(r1, 1, m2, 0));

    verifier(scene.noeud_de(m1, 0) == scene.noeud_de(m2, 0),
             "les deux masses portent bien le même nom de nœud",
             scene.noeud_de(m1, 0).toStdString() + " / "
                 + scene.noeud_de(m2, 0).toStdString());

    const SceneSchema::Noeud noeud = scene.noeud_sous(m1->position_borne(0));
    bool tient_m2 = false;
    for (const auto& [composant, borne] : noeud.bornes)
        if (composant == m2) tient_m2 = true;
    verifier(tient_m2,
             "survoler une masse allume l'AUTRE masse : sans fil entre elles, "
             "c'est pourtant le même nœud");

    scene.allumer_noeud(m1->position_borne(0));
    verifier(!m2->bornes_allumees().empty(),
             "et la seconde masse s'allume pour de bon");

    // Même chose pour deux étiquettes de nœud de même nom : c'est tout
    // l'intérêt de l'étiquette, et le code de nommage le dit déjà.
    SceneSchema autre;
    ItemComposant* ra = autre.ajouter_composant("resistance", QPointF(0, 0));
    ItemComposant* rb = autre.ajouter_composant("resistance", QPointF(0, 300));
    ItemComposant* ea = autre.ajouter_composant("etiquette", QPointF(200, 0));
    ItemComposant* eb = autre.ajouter_composant("etiquette", QPointF(200, 300));
    if (ea && eb) {
        ea->textes["nom"] = "SIG";
        eb->textes["nom"] = "SIG";
        autre.addItem(new ItemFil(ra, 1, ea, 0));
        autre.addItem(new ItemFil(rb, 1, eb, 0));
        const SceneSchema::Noeud sig = autre.noeud_sous(ra->position_borne(1));
        bool tient_rb = false;
        for (const auto& [composant, borne] : sig.bornes)
            if (composant == rb) tient_rb = true;
        verifier(tient_rb,
                 "deux étiquettes « SIG » relient leurs deux résistances, "
                 "sans fil entre elles");
    }
}

static void test_survol_description_suit_le_contenu() {
    std::printf("\n-- la description du nœud suit son contenu --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(300, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(300, 200));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(600, 0));
    scene.addItem(new ItemFil(pile, 0, r1, 0));
    scene.addItem(new ItemFil(pile, 1, masse, 0));

    QString derniere;
    int emissions = 0;
    QObject::connect(&scene, &SceneSchema::survol_noeud,
                     [&](const QString&, const QString& description) {
                         if (description.isEmpty()) return;
                         derniere = description;
                         ++emissions;
                     });

    scene.allumer_noeud(r1->position_borne(0));
    const QString avant = derniere;
    verifier(!avant.isEmpty(), "le survol décrit ce que relie le nœud",
             avant.toStdString());
    verifier(!avant.contains("R2"), "R2 n'en fait pas encore partie");

    // On élargit le nœud SANS changer son nom, puis on resurvole le même
    // point — SANS repasser ailleurs entre les deux. C'est la condition qui
    // révèle le défaut : sortir du nœud remettrait le nom à zéro et le
    // raccourci ne se déclencherait pas. Mon premier jet le faisait, et
    // masquait donc exactement ce qu'il prétendait vérifier.
    ItemFil* derivation = new ItemFil(r1, 0, r2, 0);
    scene.addItem(derivation);
    scene.allumer_noeud(r1->position_borne(0));
    verifier(derniere.contains("R2"),
             "après l'ajout d'un fil, la description nomme R2 — le NOM du "
             "nœud n'a pas changé, son contenu si",
             derniere.toStdString());
}

static void test_marqueur_erc_tient_dans_son_cadre() {
    std::printf("\n-- le marqueur ERC tient dans le cadre de dessin --\n");

    // L'ATtiny85 porte ses bornes à x = ±90, tout au bord de son boîtier.
    // C'est le cas le plus serré du catalogue, et celui qui débordait.
    SceneSchema scene;
    ItemComposant* puce = scene.ajouter_composant("attiny85", QPointF(0, 0));
    verifier(puce != nullptr, "l'ATtiny85 est au catalogue");
    if (!puce) return;

    std::vector<ItemComposant::MarqueurErc> marqueurs;
    for (int k = 0; k < puce->nb_bornes(); ++k)
        marqueurs.push_back({k, true});
    puce->definir_anomalies(marqueurs);

    // On peint l'item seul dans une image, en repérant où tombe son cadre.
    // Tout pixel encré hors du cadre est un pixel que Qt n'effacera pas quand
    // le composant bougera : une traînée à l'écran.
    for (double angle : {0.0, 90.0, 180.0, 270.0}) {
        puce->setRotation(angle);
        const QRectF cadre = puce->boundingRect();
        QImage image(700, 700, QImage::Format_ARGB32);
        image.fill(Qt::white);
        {
            QPainter peintre(&image);
            peintre.translate(350, 350);
            QStyleOptionGraphicsItem option;
            peintre.rotate(angle);
            puce->paint(&peintre, &option, nullptr);
        }
        int dehors = 0;
        for (int y = 0; y < image.height(); ++y)
            for (int x = 0; x < image.width(); ++x) {
                if (image.pixelColor(x, y) == QColor(Qt::white)) continue;
                // Repère de l'item : le cadre est exprimé dans SON repère,
                // tourné comme lui autour de (350, 350).
                const QPointF local =
                    QTransform().rotate(-angle).map(QPointF(x - 350, y - 350));
                if (!cadre.adjusted(-1, -1, 1, 1).contains(local)) ++dehors;
            }
        verifier(dehors == 0,
                 "à " + std::to_string(static_cast<int>(angle))
                     + "° rien n'est peint hors du cadre",
                 std::to_string(dehors) + " pixels dehors");
    }
    puce->setRotation(0);
}

static void test_surbrillance_ne_survit_pas_a_la_suppression() {
    std::printf("\n-- la surbrillance ne survit pas à ce qu'elle désignait --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(300, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(600, 0));
    ItemFil* haut = new ItemFil(pile, 0, r1, 0);
    scene.addItem(haut);
    scene.addItem(new ItemFil(r1, 1, masse, 0));
    scene.addItem(new ItemFil(pile, 1, masse, 0));

    scene.allumer_noeud(r1->position_borne(0));
    verifier(!r1->bornes_allumees().empty() && !scene.noeud_allume().isEmpty(),
             "le nœud est allumé au départ");

    // On supprime le fil SANS bouger la souris : aucun mouseMoveEvent ne
    // viendra rafraîchir quoi que ce soit. C'est le chemin réel — sélection
    // puis Suppr.
    haut->setSelected(true);
    scene.supprimer_selection();
    verifier(scene.noeud_allume().isEmpty(),
             "supprimer un fil du nœud éteint la surbrillance : la borne de "
             "R1 est maintenant en l'air");
    verifier(r1->bornes_allumees().empty(),
             "et plus aucune borne ne reste allumée");
}

// ---------------------------------------------------------------------------
// Deux défauts vus sur une capture d'écran
//
// Ni le compilateur ni les tests ne les voyaient. Il a fallu regarder
// l'application tourner — c'est la méthode que le projet s'est donnée, et
// elle continue de rapporter plus que la relecture.
// ---------------------------------------------------------------------------
static void test_marqueur_erc_evite_la_reference() {
    std::printf("\n-- le marqueur ERC ne se pose pas sur la référence --\n");

    // Le curseur du potentiomètre est en (0, −25) : en haut, AU CENTRE,
    // c'est-à-dire exactement là où la référence « POT1 » est écrite. Le
    // triangle y atterrissait en plein milieu du texte — on lisait « P⚠T1 ».
    SceneSchema scene;
    ItemComposant* pot = scene.ajouter_composant("potentiometre", QPointF(0, 0));
    verifier(pot != nullptr, "le potentiomètre est au catalogue");
    if (!pot) return;

    int borne_curseur = -1;
    for (int k = 0; k < pot->nb_bornes(); ++k)
        if (pot->nom_borne(k) == "W") borne_curseur = k;
    verifier(borne_curseur >= 0, "sa borne « W » (le curseur) existe");
    if (borne_curseur < 0) return;

    pot->definir_anomalies({{borne_curseur, true}});

    // On peint deux fois : avec et sans le marqueur. La référence doit
    // rester IDENTIQUE — si le triangle mordait dessus, les pixels du texte
    // changeraient.
    auto peindre = [&](bool avec_marqueur) {
        pot->definir_anomalies(
            avec_marqueur
                ? std::vector<ItemComposant::MarqueurErc>{{borne_curseur, true}}
                : std::vector<ItemComposant::MarqueurErc>{});
        QImage image(400, 400, QImage::Format_ARGB32);
        image.fill(Qt::white);
        QPainter peintre(&image);
        peintre.translate(200, 200);
        QStyleOptionGraphicsItem option;
        pot->paint(&peintre, &option, nullptr);
        return image;
    };
    const QImage sans = peindre(false);
    const QImage avec = peindre(true);

    // Le bandeau de la référence, dans le repère de l'image.
    const QRectF cadre = pot->boundingRect();
    const int haut = 200 + static_cast<int>(cadre.top()) - 2;
    int pixels_changes = 0;
    for (int y = std::max(0, haut); y < std::min(400, haut + 16); ++y)
        for (int x = 130; x < 270; ++x)
            if (sans.pixelColor(x, y) != avec.pixelColor(x, y)) ++pixels_changes;
    verifier(pixels_changes == 0,
             "poser le marqueur ne change AUCUN pixel du bandeau de la "
             "référence",
             std::to_string(pixels_changes) + " pixels modifiés");

    // Et il est bien dessiné quelque part — sinon le test ci-dessus passerait
    // pour la mauvaise raison.
    int pixels_marqueur = 0;
    for (int y = 0; y < 400; ++y)
        for (int x = 0; x < 400; ++x)
            if (sans.pixelColor(x, y) != avec.pixelColor(x, y))
                ++pixels_marqueur;
    verifier(pixels_marqueur > 30,
             "mais le marqueur est bien peint, ailleurs",
             std::to_string(pixels_marqueur) + " pixels");
    pot->definir_anomalies({});
}

// ---------------------------------------------------------------------------
// Le fil détruit sous les pieds du geste qui le tenait
//
// Un vrai plantage, signalé en câblant « un peu n'importe quoi ». Partir d'un
// FIL et refermer sur ce même fil : `ancrer` le découpe et le DÉTRUIT pour y
// poser une jonction, puis l'arrivée se retrouve égale au départ et le geste
// échoue. La cible gardée par l'appelant désignait alors un objet mort.
// ---------------------------------------------------------------------------
static void test_depart_sur_fil_detruit() {
    std::printf("\n-- repartir d'un fil que la découpe a détruit --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(400, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(700, 0));
    ItemFil* dorsale = new ItemFil(pile, 0, r1, 0);
    scene.addItem(dorsale);
    scene.addItem(new ItemFil(pile, 1, masse, 0));

    // Un point franchement SUR la dorsale.
    const QPointF a = pile->position_borne(0);
    const QPointF b = r1->position_borne(0);
    const QPointF milieu((a.x() + b.x()) / 2.0, a.y());
    verifier(scene.viser(milieu).genre == SceneSchema::Cible::Genre::Fil,
             "le point visé est bien sur le fil");

    verifier(scene.amorcer_fil_au(milieu), "le tracé s'amorce depuis ce fil");

    // Refermer sur le MÊME point. La découpe n'a plus lieu du tout — c'est
    // elle qui périmait la cible — mais la garde reste indispensable : une
    // dérivation qui aboutit détruit bel et bien le fil d'origine.
    Ancre materialisee;
    const bool abouti = scene.terminer_fil(milieu, &materialisee);
    verifier(!abouti, "le geste échoue — on ne relie pas un point à lui-même");
    verifier(!materialisee.valide(),
             "et il n'a RIEN matérialisé : l'échec ne coupe plus");

    // Une dérivation qui aboutit, elle, détruit le fil d'origine : c'est le
    // pointeur que l'ancien code réutilisait ensuite.
    ItemComposant* cible = scene.ajouter_composant("masse", QPointF(200, 400));
    verifier(scene.terminer_fil(cible->position_borne(0), &materialisee),
             "la dérivation vers la masse, elle, aboutit");
    // On ne compare pas au POINTEUR `dorsale` : il est détruit, et l'allocateur
    // rend volontiers la même adresse à l'un des deux segments qui le
    // remplacent — le test passerait ou non selon l'humeur du tas. C'est la
    // STRUCTURE qui dit la découpe : deux fils là où il y en avait un, plus
    // celui de la dérivation.
    verifier(scene.fils().size() == 4,
             "le fil de départ a été découpé en deux, plus la dérivation",
             std::to_string(scene.fils().size()) + " fil(s)");
    verifier(scene.jonctions().size() == 1,
             "et une seule jonction marque la dérivation",
             std::to_string(scene.jonctions().size()));
    verifier(materialisee.valide() && materialisee.jonction != nullptr,
             "terminer_fil rend la jonction matérialisée, pas le fil mort");
    verifier(scene.ancre_vivante(materialisee),
             "cette jonction est bien dans la scène : on peut repartir de là");

    // Une ancre qui désigne un objet retiré doit être déclarée morte.
    ItemJonction* survivante = materialisee.jonction;
    scene.removeItem(survivante);
    verifier(!scene.ancre_vivante(materialisee),
             "retirée de la scène, la même ancre est déclarée morte");
    delete survivante;

    // Et le fil, de même : c'est ce qui protège un tracé dont le fil de
    // départ disparaît avant le clic de fermeture.
    verifier(!scene.fils().empty() && scene.fil_vivant(scene.fils().front()),
             "un fil présent dans la scène est déclaré vivant");
    auto* etranger = new ItemFil(pile, 0, r1, 0);   // jamais ajouté
    verifier(!scene.fil_vivant(etranger),
             "un fil qui n'est pas dans la scène est déclaré mort");
    verifier(!scene.fil_vivant(nullptr), "et un fil nul aussi");
    delete etranger;
}

// ---------------------------------------------------------------------------
// Ce que le sélecteur annonce doit être ce que l'écran dessine
//
// L'oscilloscope s'ouvrait sur « Base de temps : 500 ms » en affichant une
// fenêtre de 50 ms — dix fois trop étroite. `setCurrentIndex(7)` était appelé
// AVANT le `connect` : le réglage initial n'atteignait jamais la trace, qui
// gardait sa valeur par défaut.
//
// C'est le pire genre de défaut d'interface : rien ne plante, rien n'est
// vide, et le réglage affiché est un mensonge. Sur un clignotant d'une demi-
// seconde, l'élève ne voit qu'un trait plat et conclut que son programme ne
// marche pas.
// ---------------------------------------------------------------------------
static void test_base_de_temps_annoncee_est_celle_dessinee() {
    std::printf("\n-- la base de temps affichée est celle qui est dessinée --\n");

    Oscilloscope scope;
    verifier(std::fabs(scope.fenetre_affichee() - 0.5) < 1e-9,
             "à l'ouverture, l'écran couvre bien les 500 ms annoncées",
             std::to_string(scope.fenetre_affichee()) + " s");

    // Et le réglage suit, dans les deux sens.
    scope.definir_base_temps(0.02);
    verifier(std::fabs(scope.fenetre_affichee() - 0.02) < 1e-9,
             "choisir 20 ms rétrécit la fenêtre pour de bon",
             std::to_string(scope.fenetre_affichee()) + " s");
    scope.definir_base_temps(2.0);
    verifier(std::fabs(scope.fenetre_affichee() - 2.0) < 1e-9,
             "et choisir 2 s l'élargit",
             std::to_string(scope.fenetre_affichee()) + " s");
}

// ---------------------------------------------------------------------------
// Un panneau vide ne garde pas sa place
//
// « Propriétés » occupait 260 pixels en permanence pour afficher
// « Sélectionnez un composant » — un quart de la largeur utile, pris à la
// seule chose que l'utilisateur regarde. Il n'apparaît plus qu'avec une
// sélection.
// ---------------------------------------------------------------------------
static void test_proprietes_rendent_la_place() {
    std::printf("\n-- le panneau des propriétés rend sa place --\n");

    FenetrePrincipale fenetre;
    QDockWidget* proprietes = nullptr;
    for (QDockWidget* dock : fenetre.findChildren<QDockWidget*>())
        if (dock->objectName() == "dock_proprietes") proprietes = dock;
    verifier(proprietes != nullptr, "le panneau des propriétés existe");
    if (!proprietes) return;

    verifier(proprietes->isHidden(),
             "au démarrage, sans sélection, il est effacé");

    // On passe par le VRAI chemin — un clic sur le corps du composant —
    // plutôt que par la méthode qui met à jour le panneau : c'est le chemin
    // que l'utilisateur emprunte, et le seul dont la rupture se verrait.
    SceneSchema* scene = fenetre.scene();
    // UNE CARTE, PAS UNE RÉSISTANCE, et loin du montage d'exemple.
    //
    // Le corps d'une résistance ne fait que soixante unités : son centre est
    // à trente unités de chaque borne, c'est-à-dire DANS le rayon de capture
    // des broches. `viser()` y répond « broche », le clic tire un fil, et
    // rien n'est sélectionné. Le montage d'essai était trop petit — le code,
    // lui, faisait exactement ce qu'on lui demande.
    ItemComposant* r =
        scene->ajouter_composant("arduino_uno", QPointF(-1500, -1500));
    envoyer(*scene, QEvent::GraphicsSceneMousePress, r->pos());
    envoyer(*scene, QEvent::GraphicsSceneMouseRelease, r->pos());
    verifier(!proprietes->isHidden(),
             "il apparaît dès qu'un composant est sélectionné");

    envoyer(*scene, QEvent::GraphicsSceneMousePress, QPointF(-4000, -4000));
    envoyer(*scene, QEvent::GraphicsSceneMouseRelease, QPointF(-4000, -4000));
    verifier(proprietes->isHidden(),
             "et il s'efface dès que la sélection tombe");
}

// ---------------------------------------------------------------------------
// Déplacer un segment de fil, comme dans Simulink
//
// « Le mouvement des fils quand on appuie dessus une fois branché est loin
// d'être comme dans Simulink. » Chez MathWorks, un glissé simple sur un
// segment le déplace et le curseur annonce l'axe permis ; c'est `Ctrl`+glissé
// qui dérive. Ici le CLIC dérive déjà — polarité inverse, arbitrée et écrite.
//
// Le partage retenu ne demande donc aucune touche : c'est le seuil de glissé
// de Qt qui tranche, celui qui sépare partout ailleurs un clic d'un
// déplacement. En deçà on dérive comme avant ; au-delà, et perpendiculairement
// au fil, on déplace le segment.
// ---------------------------------------------------------------------------
static void test_deplacer_un_segment() {
    std::printf("\n-- glisser un fil déplace le segment --\n");

    // Deux composants reliés par un fil bien horizontal.
    SceneSchema scene;
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(400, 0));
    scene.addItem(new ItemFil(r1, 1, r2, 0));
    const QPointF a = r1->position_borne(1);
    const QPointF b = r2->position_borne(0);
    verifier(std::fabs(a.y() - b.y()) < 0.01, "le fil d'essai est d'aplomb");
    const QPointF milieu((a.x() + b.x()) / 2.0, a.y());
    const QPointF composant_avant = r1->pos();
    scene.oublier_historique();

    // Ce que voit l'utilisateur AVANT d'appuyer : le nombre de nœuds, qu'un
    // déplacement ne doit pas changer d'un iota.
    const std::size_t noeuds_avant =
        scene.construire_netlist(nullptr).noeuds().size();

    // Le glissé : bien au-delà du seuil de Qt, et perpendiculaire au fil.
    envoyer(scene, QEvent::GraphicsSceneMousePress, milieu);
    verifier(scene.fils().size() == 1,
             "l'appui seul ne décide rien : toujours un fil",
             std::to_string(scene.fils().size()));
    envoyer(scene, QEvent::GraphicsSceneMouseMove, milieu + QPointF(0, 60));
    envoyer(scene, QEvent::GraphicsSceneMouseRelease, milieu + QPointF(0, 60));

    // LE CONTRÔLE : le segment est descendu, les composants n'ont pas bougé,
    // et rien n'a été débranché.
    verifier(r1->pos() == composant_avant,
             "le composant n'a pas bougé d'un pixel");
    verifier(scene.jonctions().size() == 2,
             "deux poignées tiennent le segment déplacé",
             std::to_string(scene.jonctions().size()));
    verifier(scene.fils().size() == 3,
             "et le fil est devenu trois segments : raccord, segment, raccord",
             std::to_string(scene.fils().size()));
    for (ItemJonction* point : scene.jonctions())
        verifier(std::fabs(point->pos().y() - (a.y() + 60)) < 0.01,
                 "chaque poignée est descendue de 60, aimantée sur la grille",
                 std::to_string(point->pos().y()));
    const std::size_t noeuds_apres =
        scene.construire_netlist(nullptr).noeuds().size();
    verifier(noeuds_apres == noeuds_avant,
             "et le circuit est électriquement le même",
             std::to_string(noeuds_apres) + " contre "
                 + std::to_string(noeuds_avant));

    // LE DÉGAGEMENT DE BROCHE.
    //
    // Les poignées ne doivent PAS être posées sur les bornes : le segment
    // partirait du point d'accroche à angle droit, et l'on ne verrait plus
    // d'où le fil part — coude, borne et étiquette de tension superposés.
    // Un fil quitte sa broche en ligne droite sur une petite longueur, comme
    // sur un schéma tracé à la main.
    for (ItemJonction* point : scene.jonctions()) {
        const double ecart = std::min(std::fabs(point->pos().x() - a.x()),
                                      std::fabs(point->pos().x() - b.x()));
        verifier(ecart >= 10.0 - 0.01,
                 "la poignée dégage la borne d'au moins une maille",
                 std::to_string(ecart));
        // …et le dégagement reste À L'INTÉRIEUR du fil : une poignée qui
        // dépasserait l'autre bout ferait revenir le fil sur ses pas.
        verifier(point->pos().x() > std::min(a.x(), b.x()) - 0.01
                     && point->pos().x() < std::max(a.x(), b.x()) + 0.01,
                 "et elle reste entre les deux bornes",
                 std::to_string(point->pos().x()));
    }

    // Le geste s'annule d'un bloc — poignées comprises.
    verifier(scene.annuler(), "le déplacement s'annule");
    verifier(scene.fils().size() == 1 && scene.jonctions().empty(),
             "et le fil redevient un seul segment, sans poignée",
             std::to_string(scene.fils().size()) + " fil(s), "
                 + std::to_string(scene.jonctions().size()) + " point(s)");
}

static void test_glisser_sans_deplacer_ne_laisse_rien() {
    std::printf("\n-- un glissé qui revient à zéro ne laisse rien --\n");

    SceneSchema scene;
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(400, 0));
    scene.addItem(new ItemFil(r1, 1, r2, 0));
    const QPointF a = r1->position_borne(1);
    const QPointF milieu((a.x() + r2->position_borne(0).x()) / 2.0, a.y());
    scene.oublier_historique();
    const QJsonObject avant = scene.vers_json();

    // On déplace, puis on revient exactement d'où l'on venait.
    envoyer(scene, QEvent::GraphicsSceneMousePress, milieu);
    envoyer(scene, QEvent::GraphicsSceneMouseMove, milieu + QPointF(0, 60));
    envoyer(scene, QEvent::GraphicsSceneMouseMove, milieu);
    envoyer(scene, QEvent::GraphicsSceneMouseRelease, milieu);

    verifier(scene.vers_json() == avant,
             "le schéma est celui d'avant : pas de poignée orpheline");
    verifier(!scene.annuler(),
             "et rien n'est entré dans la pile d'annulation");
}

static void test_clic_gauche_designe_clic_droit_derive() {
    std::printf("\n-- gauche désigne, droit dérive : les deux boutons de "
                "Simulink --\n");

    // Simulink, mot pour mot : « Déplacer des segments : cliquez sur un
    // segment de fil horizontal ou vertical, glissez-le pour ajuster sa
    // position sans déconnecter les blocs » et « Créer une dérivation :
    // cliquez avec le bouton DROIT sur un fil existant, glissez le curseur
    // vers le nouveau bloc ».
    //
    // Le bouton gauche ne s'occupe donc que de ce qui existe déjà, et le
    // bouton droit fait naître. C'est ce partage qui rend un fil TOUCHABLE :
    // avant, le montrer en faisait pousser un autre.
    SceneSchema scene;
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(400, 0));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(200, 400));
    scene.addItem(new ItemFil(r1, 1, r2, 0));
    const QPointF a = r1->position_borne(1);
    const QPointF milieu((a.x() + r2->position_borne(0).x()) / 2.0, a.y());

    // --- Clic GAUCHE, avec le tremblement de main qui va avec : il DÉSIGNE.
    envoyer(scene, QEvent::GraphicsSceneMousePress, milieu);
    envoyer(scene, QEvent::GraphicsSceneMouseMove, milieu + QPointF(1, 2));
    envoyer(scene, QEvent::GraphicsSceneMouseRelease, milieu + QPointF(1, 2));
    verifier(scene.fils().size() == 1 && scene.jonctions().empty(),
             "le clic gauche ne coupe rien et ne dérive rien",
             std::to_string(scene.fils().size()) + " fil(s), "
                 + std::to_string(scene.jonctions().size()) + " point(s)");
    verifier(scene.selectedItems().size() == 1
                 && scene.selectedItems().front()->type() == ItemFil::Type,
             "il DÉSIGNE le fil, et rien d'autre",
             std::to_string(scene.selectedItems().size()) + " objet(s)");

    // --- Clic DROIT maintenu : il tire une dérivation.
    envoyer(scene, QEvent::GraphicsSceneMousePress, milieu, Qt::RightButton);
    envoyer(scene, QEvent::GraphicsSceneMouseMove, milieu + QPointF(0, 80),
            Qt::RightButton);
    verifier(scene.fils().size() == 1,
             "pendant le glissé, rien n'est encore coupé",
             std::to_string(scene.fils().size()) + " fil(s)");
    envoyer(scene, QEvent::GraphicsSceneMouseRelease, milieu + QPointF(0, 80),
            Qt::RightButton);
    // Relâché dans le vide : le fil reste accroché au curseur, et c'est un
    // clic GAUCHE qui le referme — la suite ne dépend plus du bouton par
    // lequel le tracé a commencé.
    envoyer(scene, QEvent::GraphicsSceneMousePress, masse->position_borne(0));
    verifier(scene.fils().size() == 3 && scene.jonctions().size() == 1,
             "le glissé droit a bien dérivé, et le clic gauche a refermé",
             std::to_string(scene.fils().size()) + " fil(s), "
                 + std::to_string(scene.jonctions().size()) + " point(s)");

    // --- Un simple clic droit, sans glissé, ne dérive pas : il laisse le
    // menu contextuel faire son travail.
    SceneSchema autre;
    ItemComposant* r3 = autre.ajouter_composant("resistance", QPointF(0, 0));
    ItemComposant* r4 = autre.ajouter_composant("resistance", QPointF(400, 0));
    autre.addItem(new ItemFil(r3, 1, r4, 0));
    const QPointF b = r3->position_borne(1);
    const QPointF milieu2((b.x() + r4->position_borne(0).x()) / 2.0, b.y());
    envoyer(autre, QEvent::GraphicsSceneMousePress, milieu2, Qt::RightButton);
    envoyer(autre, QEvent::GraphicsSceneMouseRelease, milieu2, Qt::RightButton);
    verifier(autre.fils().size() == 1 && autre.jonctions().empty(),
             "un clic droit sans glissé ne laisse aucune dérivation",
             std::to_string(autre.fils().size()) + " fil(s), "
                 + std::to_string(autre.jonctions().size()) + " point(s)");
}

static void test_fil_en_equerre_ne_se_deplace_pas() {
    std::printf("\n-- un fil en équerre n'a pas d'axe : il se dérive --\n");

    // Bornes décalées en x ET en y : le fil est tracé en équerre, et
    // « déplacer le segment » n'y veut rien dire — quel segment ?
    SceneSchema scene;
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(400, 300));
    scene.addItem(new ItemFil(r1, 1, r2, 0));
    const QPointF a = r1->position_borne(1);
    const QPointF b = r2->position_borne(0);
    verifier(std::fabs(a.x() - b.x()) > 0.01 && std::fabs(a.y() - b.y()) > 0.01,
             "le fil d'essai est bien en équerre");

    // Un point franchement sur le fil : le coin de l'équerre.
    const QPointF coin(b.x(), a.y());
    const QPointF sur_le_fil((a.x() + b.x()) / 2.0, a.y());
    verifier(scene.viser(sur_le_fil).genre == SceneSchema::Cible::Genre::Fil,
             "et le point visé est bien dessus");
    (void)coin;

    envoyer(scene, QEvent::GraphicsSceneMousePress, sur_le_fil);
    envoyer(scene, QEvent::GraphicsSceneMouseMove, sur_le_fil + QPointF(0, 60));
    // Le geste bascule en DÉRIVATION : rien n'a encore été coupé, et un fil
    // provisoire suit le curseur.
    verifier(scene.jonctions().empty(),
             "aucune poignée n'a été posée sur un fil sans axe",
             std::to_string(scene.jonctions().size()));
    scene.abandonner_fil();
    verifier(scene.fils().size() == 1,
             "et le fil est intact après abandon",
             std::to_string(scene.fils().size()));
}

static void test_ctrl_clic_designe_un_fil() {
    std::printf("\n-- Ctrl+clic désigne un fil, les flèches le déplacent --\n");

    SceneSchema scene;
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(400, 0));
    scene.addItem(new ItemFil(r1, 1, r2, 0));
    const QPointF a = r1->position_borne(1);
    const QPointF milieu((a.x() + r2->position_borne(0).x()) / 2.0, a.y());

    envoyer(scene, QEvent::GraphicsSceneMousePress, milieu, Qt::LeftButton,
            Qt::ControlModifier);
    envoyer(scene, QEvent::GraphicsSceneMouseRelease, milieu, Qt::LeftButton,
            Qt::ControlModifier);
    verifier(scene.fils().size() == 1 && scene.jonctions().empty(),
             "le fil n'a été ni coupé ni dérivé",
             std::to_string(scene.fils().size()) + " fil(s), "
                 + std::to_string(scene.jonctions().size()) + " point(s)");
    verifier(scene.selectedItems().size() == 1
                 && scene.selectedItems().front()->type() == ItemFil::Type,
             "il est SÉLECTIONNÉ — ce qu'aucun geste ne permettait avant",
             std::to_string(scene.selectedItems().size()) + " objet(s)");

    // Et les flèches, mécanisme déjà écrit, s'appliquent enfin à un fil : ses
    // deux bouts tiennent à des broches, il n'a donc rien à déplacer, et
    // c'est exactement ce que dit DECISION-FILS. La touche ne casse rien.
    frapper(scene, Qt::Key_Down);
    verifier(scene.fils().size() == 1,
             "une flèche sur un fil tendu entre deux broches ne casse rien",
             std::to_string(scene.fils().size()));

    // Sur un fil qui porte une poignée, en revanche, elle déplace vraiment.
    envoyer(scene, QEvent::GraphicsSceneMousePress, milieu);
    envoyer(scene, QEvent::GraphicsSceneMouseMove, milieu + QPointF(0, 60));
    envoyer(scene, QEvent::GraphicsSceneMouseRelease, milieu + QPointF(0, 60));
    verifier(scene.jonctions().size() == 2, "le segment porte deux poignées",
             std::to_string(scene.jonctions().size()));
    // Un banc qui plante n'accuse plus rien : sans poignée, la suite n'a plus
    // d'objet et doit s'arrêter là, pas déréférencer un vecteur vide.
    if (scene.jonctions().empty()) return;
    const double y_avant = scene.jonctions().front()->pos().y();
    scene.clearSelection();
    for (ItemJonction* point : scene.jonctions()) point->setSelected(true);
    frapper(scene, Qt::Key_Down);
    verifier(std::fabs(scene.jonctions().front()->pos().y() - (y_avant + 10))
                 < 0.01,
             "et la flèche descend le segment d'un pas de grille",
             std::to_string(scene.jonctions().front()->pos().y()));
}

// ---------------------------------------------------------------------------
// Ce qui arrive PENDANT que le bouton est enfoncé
//
// Les cinq tests précédents vérifient le geste du début à la fin, sans
// interruption. C'est le trou : rien n'y fait survenir un événement extérieur
// — Suppr, Ctrl+Z, l'ouverture d'un fichier — alors que le bouton est encore
// tenu et que la scène garde des pointeurs vers ce que ce geste manipule.
//
// Trois use-after-free vivaient là, confirmés à l'ASan. Tous de la même
// famille : un geste de souris désigne des objets d'un événement à l'autre, et
// ce qui les détruit ne sait pas que ce geste existe. Le remède est unique —
// tout ce qui détruit clôt d'abord le geste en cours.
// ---------------------------------------------------------------------------
static void test_geste_interrompu_par_une_destruction() {
    std::printf("\n-- détruire pendant qu'un geste tient des pointeurs --\n");

    auto montage = [](SceneSchema& scene) {
        ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
        ItemComposant* r2 =
            scene.ajouter_composant("resistance", QPointF(400, 0));
        scene.addItem(new ItemFil(r1, 1, r2, 0));
        const QPointF a = r1->position_borne(1);
        return QPointF((a.x() + r2->position_borne(0).x()) / 2.0, a.y());
    };

    // --- Ctrl+Z pendant le glissé d'un segment
    {
        SceneSchema scene;
        const QPointF milieu = montage(scene);
        scene.memoriser();   // il y a quelque chose à annuler

        envoyer(scene, QEvent::GraphicsSceneMousePress, milieu);
        envoyer(scene, QEvent::GraphicsSceneMouseMove, milieu + QPointF(0, 60));
        // Le raccourci d'annulation appartient à la FENÊTRE : il part même si
        // le bouton de la souris est encore enfoncé.
        scene.annuler();
        // La scène a été reconstruite de fond en comble : les poignées que le
        // glissé tenait n'existent plus.
        envoyer(scene, QEvent::GraphicsSceneMouseMove, milieu + QPointF(0, 80));
        envoyer(scene, QEvent::GraphicsSceneMouseRelease,
                milieu + QPointF(0, 80));
        verifier(scene.fils().size() == 1,
                 "annuler pendant un glissé ne laisse pas le geste courir",
                 std::to_string(scene.fils().size()) + " fil(s)");
    }

    // --- Suppr pendant le glissé d'un segment
    {
        SceneSchema scene;
        const QPointF milieu = montage(scene);
        envoyer(scene, QEvent::GraphicsSceneMousePress, milieu);
        envoyer(scene, QEvent::GraphicsSceneMouseMove, milieu + QPointF(0, 60));
        // Tout sélectionner puis effacer : les poignées partent avec.
        for (QGraphicsItem* item : scene.items()) item->setSelected(true);
        frapper(scene, Qt::Key_Delete);
        envoyer(scene, QEvent::GraphicsSceneMouseMove, milieu + QPointF(0, 90));
        envoyer(scene, QEvent::GraphicsSceneMouseRelease,
                milieu + QPointF(0, 90));
        verifier(scene.fils().empty() && scene.jonctions().empty(),
                 "supprimer pendant un glissé n'y laisse aucun survivant",
                 std::to_string(scene.fils().size()) + " fil(s), "
                     + std::to_string(scene.jonctions().size()) + " point(s)");
    }

    // --- Suppr entre l'appui et le verdict, sur le fil même qu'on tient
    //
    // Celui-ci est le plus retors : le fil est sélectionné par Ctrl+clic, puis
    // repris par un clic ordinaire — qui arme l'attente SANS toucher à la
    // sélection. Suppr détruit alors le fil que l'attente désigne, et c'est le
    // franchissement du seuil qui va le relire.
    {
        SceneSchema scene;
        const QPointF milieu = montage(scene);
        envoyer(scene, QEvent::GraphicsSceneMousePress, milieu, Qt::LeftButton,
                Qt::ControlModifier);
        envoyer(scene, QEvent::GraphicsSceneMouseRelease, milieu,
                Qt::LeftButton, Qt::ControlModifier);
        envoyer(scene, QEvent::GraphicsSceneMousePress, milieu);
        frapper(scene, Qt::Key_Delete);
        envoyer(scene, QEvent::GraphicsSceneMouseMove, milieu + QPointF(0, 60));
        envoyer(scene, QEvent::GraphicsSceneMouseRelease,
                milieu + QPointF(0, 60));
        verifier(scene.fils().empty(),
                 "le fil supprimé sous le geste n'est plus relu",
                 std::to_string(scene.fils().size()) + " fil(s)");
    }
}

// ---------------------------------------------------------------------------
// Un clic raté sur un fil ne doit RIEN changer au schéma
//
// Appuyer sur un fil et relâcher sans bouger d'un pixel — le geste le plus
// banal du monde, celui qu'on fait pour désigner un fil avant de le déplacer —
// coupait le fil en deux et y laissait une jonction de degré 2, que le
// balayage ne retire pas puisqu'elle relie bien deux fils. Rien à l'écran ne
// le disait : la pastille ne se dessine qu'au-delà de deux fils. Le schéma
// enregistré, lui, gardait la coupure, et la pile d'annulation une entrée
// pour un geste qui n'avait rien demandé.
//
// C'est une mutation topologique silencieuse au moindre clic, et c'est la
// racine de la plainte « le mouvement des fils est loin de Simulink » : chez
// nous on ne peut même pas TOUCHER un fil sans l'abîmer.
// ---------------------------------------------------------------------------
static void test_clic_immobile_ne_coupe_pas() {
    std::printf("\n-- un clic sans mouvement sur un fil ne coupe rien --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(400, 0));
    ItemFil* dorsale = new ItemFil(pile, 0, r1, 0);
    scene.addItem(dorsale);
    scene.oublier_historique();

    const QPointF a = pile->position_borne(0);
    const QPointF b = r1->position_borne(0);
    const QPointF milieu((a.x() + b.x()) / 2.0, a.y());
    verifier(scene.viser(milieu).genre == SceneSchema::Cible::Genre::Fil,
             "le point visé est bien sur le fil");

    const QJsonObject avant = scene.vers_json();
    verifier(scene.amorcer_fil_au(milieu), "le tracé s'amorce depuis ce fil");
    verifier(!scene.terminer_fil(milieu),
             "refermer au point de départ n'aboutit à aucun fil");
    scene.abandonner_fil();

    // LE CONTRÔLE : le schéma est celui d'avant, au caractère près.
    verifier(scene.fils().size() == 1, "il reste UN fil, pas deux moitiés",
             std::to_string(scene.fils().size()));
    bool dorsale_encore_la = false;
    for (ItemFil* fil : scene.fils())
        if (fil == dorsale) dorsale_encore_la = true;
    verifier(dorsale_encore_la, "et c'est bien le fil d'origine, intact");
    verifier(scene.jonctions().empty(),
             "aucune jonction fantôme n'a été semée",
             std::to_string(scene.jonctions().size()));
    verifier(scene.vers_json() == avant,
             "le schéma enregistré est identique à celui d'avant le clic");
    verifier(!scene.annuler(),
             "et rien n'est entré dans la pile : il n'y a rien à annuler");

    // Ce qui doit encore marcher : dériver POUR DE BON depuis ce même fil.
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(400, 400));
    verifier(scene.amorcer_fil_au(milieu), "le tracé se réamorce sur le fil");
    verifier(scene.terminer_fil(masse->position_borne(0)),
             "et cette fois, la dérivation aboutit");
    verifier(scene.jonctions().size() == 1,
             "une jonction, et une seule, matérialise la dérivation",
             std::to_string(scene.jonctions().size()));
}

// ---------------------------------------------------------------------------
// Ce qu'une seconde relecture a trouvé, après un banc vert et un audit
//
// Deux défauts CASSE dans du code livré, compilé sans avertissement, couvert
// par 342 tests verts et passé sous ASan sans une alerte. Ils rappellent ce
// qu'un banc vert prouve : que les chemins parcourus marchent. Pas les autres.
// ---------------------------------------------------------------------------
static void test_colonne_en_octets_pas_en_caracteres() {
    std::printf("\n-- la colonne d'erreur se compte en octets --\n");

    // avr-g++ 7.3.0 compte les colonnes en OCTETS, Qt déplace le curseur en
    // CARACTÈRES. Sur `const char* s = "café";` les deux divergent dès
    // l'accent — et tout ce projet est écrit en français.
    FenetrePrincipale fenetre;
    QPlainTextEdit essai;
    essai.setPlainText(QString::fromUtf8("const char* s = \"café\"; erreur;"));

    const QString ligne = essai.document()->firstBlock().text();
    const QByteArray brut = ligne.toUtf8();
    verifier(brut.size() > ligne.size(),
             "la ligne compte plus d'octets que de caractères",
             std::to_string(brut.size()) + " octets pour "
                 + std::to_string(ligne.size()) + " caractères");

    // La colonne qu'annonce le compilateur pour « erreur » : son rang en
    // octets, un de plus que son rang en caractères à cause du « é ».
    const int rang_caractere = ligne.indexOf("erreur");
    const int rang_octet = brut.indexOf("erreur");
    verifier(rang_octet == rang_caractere + 1,
             "et l'accent décale le compte d'exactement un",
             std::to_string(rang_octet) + " contre "
                 + std::to_string(rang_caractere));

    // La conversion qu'applique aller_a_erreur : tronquer au bon nombre
    // d'octets, redécoder, compter les caractères.
    const int converti = QString::fromUtf8(brut.left(rang_octet)).size();
    verifier(converti == rang_caractere,
             "tronquer en octets puis redécoder rend le bon rang caractère — "
             "sans quoi le curseur tombe un cran trop loin",
             std::to_string(converti));
}

static void test_notation_scientifique() {
    std::printf("\n-- le champ de valeur lit la notation scientifique --\n");

    // « 1e9 » pour un gigaohm était TRONQUÉ EN SILENCE : le champ retenait 1,
    // et validate() répondait « acceptable ». Se tromper d'un facteur
    // milliard sans le moindre signe est le pire comportement possible pour
    // un réglage de composant.
    FenetrePrincipale fenetre;
    SceneSchema* scene = fenetre.scene();
    scene->tout_effacer();
    ItemComposant* r = scene->ajouter_composant("resistance", QPointF(0, 0));
    verifier(r != nullptr, "une résistance est posée");
    if (!r) return;

    struct Cas { const char* saisi; double attendu; };
    const Cas cas[] = {
        {"1e9", 1e9},      {"2.5e3", 2500.0},  {"1e-9", 1e-9},
        {"4.7k", 4700.0},  {"220n", 220e-9},   {"10k", 10000.0},
        {"4,7k", 4700.0},  {"220", 220.0},
    };
    for (const Cas& c : cas) {
        // On passe par le champ réel : c'est lui qui a le défaut, pas une
        // fonction d'aide qu'on aurait écrite pour l'occasion.
        // Le panneau se remplit par le signal de sélection de la scène —
        // le chemin réel, celui qu'emprunte un clic de l'utilisateur.
        emit scene->selection_composant(r);
        QCoreApplication::processEvents();
        // DANS LE PANNEAU PROPRIÉTÉS, pas n'importe où : `findChild` sur la
        // fenêtre entière rendait le premier QDoubleSpinBox venu — celui de
        // la largeur de piste du circuit imprimé, à 0,40 mm. Le test mesurait
        // alors un champ qui n'a rien à voir.
        QDockWidget* proprietes =
            fenetre.findChild<QDockWidget*>("dock_proprietes");
        QDoubleSpinBox* champ =
            proprietes ? proprietes->findChild<QDoubleSpinBox*>() : nullptr;
        if (!champ) {
            verifier(false, "le champ de valeur existe");
            return;
        }
        QLineEdit* saisie = champ->findChild<QLineEdit*>();
        if (!saisie) {
            verifier(false, "le champ a bien une zone de saisie");
            return;
        }
        saisie->setText(c.saisi);
        champ->interpretText();
        const double lu = champ->value();
        const double ecart = std::fabs(lu - c.attendu);
        verifier(ecart <= std::fabs(c.attendu) * 1e-6,
                 std::string("« ") + c.saisi + " » vaut "
                     + f(c.attendu),
                 "lu " + f(lu));
    }
}

static void test_nom_de_noeud_impose_assaini() {
    std::printf("\n-- un nom de nœud imposé est assaini comme les autres --\n");

    // Une étiquette dont le nom vient d'un fichier de projet, pas de la
    // liste fermée de l'interface : `depuis_json` recopie les textes sans
    // les valider. Une virgule y suffit à tromper le panneau « Contrôle »,
    // qui s'en sert pour distinguer un nœud d'une LISTE de composants.
    SceneSchema scene;
    ItemComposant* r = scene.ajouter_composant("resistance", QPointF(0, 0));
    ItemComposant* etiquette = scene.ajouter_composant("etiquette", QPointF(200, 0));
    verifier(etiquette != nullptr, "l'étiquette de nœud est au catalogue");
    if (!r || !etiquette) return;

    etiquette->textes["nom"] = "A,B";
    scene.addItem(new ItemFil(r, 1, etiquette, 0));

    const QString noeud = scene.noeud_de(r, 1);
    verifier(!noeud.isEmpty(), "le nœud porte bien un nom",
             noeud.toStdString());
    verifier(!noeud.contains(','),
             "et ce nom ne contient AUCUNE virgule — sans quoi le panneau "
             "Contrôle le prendrait pour deux composants",
             noeud.toStdString());
}

// ---------------------------------------------------------------------------
// Les deux exemples sans carte donnent bien ce qu'ils annoncent
//
// Un exemple qui ment vaut moins que pas d'exemple : l'élève croit le
// journal, mesure autre chose, et conclut qu'il n'a rien compris. On vérifie
// donc le CHIFFRE, pas seulement que le montage se charge.
// ---------------------------------------------------------------------------
static void test_exemples_sans_carte() {
    std::printf("\n-- pont diviseur et Zener donnent le bon chiffre --\n");

    FenetrePrincipale fenetre;

    // --- pont diviseur : 5 V, deux fois 10 kΩ -> 2,50 V ---------------------
    fenetre.charger_exemple_pont_diviseur();
    {
        std::vector<LiaisonBroche> broches;
        const coeur::Netlist netlist =
            fenetre.scene()->construire_netlist(&broches);
        coeur::NgspiceEngine moteur;
        moteur.construire(netlist, {});
        verifier(moteur.resoudre() && moteur.erreurs().empty(),
                 "le pont diviseur se résout");

        // Le point milieu : la borne 1 de R1, celle où pend le voltmètre.
        ItemComposant* r1 = nullptr;
        for (ItemComposant* c : fenetre.scene()->composants())
            if (c->reference() == "R1") r1 = c;
        verifier(r1 != nullptr, "R1 est bien là");
        if (r1) {
            const double v = moteur.tension(
                fenetre.scene()->noeud_de(r1, 1).toStdString());
            verifier(std::fabs(v - 2.5) < 0.05,
                     "le point milieu est à 2,50 V — U × R2/(R1+R2)",
                     f(v) + " V");
        }
    }

    // --- Zener : 12 V en entrée, la sortie doit être RÉGULÉE ---------------
    fenetre.charger_exemple_zener();
    {
        std::vector<LiaisonBroche> broches;
        const coeur::Netlist netlist =
            fenetre.scene()->construire_netlist(&broches);
        coeur::NgspiceEngine moteur;
        moteur.construire(netlist, {});
        verifier(moteur.resoudre() && moteur.erreurs().empty(),
                 "le régulateur Zener converge — c'est précisément ce qui ne "
                 "marchait pas avant la reprise du modèle sur diotemp.c");

        ItemComposant* dz = nullptr;
        for (ItemComposant* c : fenetre.scene()->composants())
            if (c->reference().startsWith("DZ") || c->reference().startsWith("D"))
                if (c->modele() && c->modele()->type == "zener") dz = c;
        verifier(dz != nullptr, "la Zener est bien là");
        if (dz) {
            // Borne 1 = cathode, le point régulé.
            const double v = moteur.tension(
                fenetre.scene()->noeud_de(dz, 1).toStdString());
            // Sous 12 V d'entrée avec 470 Ω de ballast, la sortie doit être
            // très en dessous de l'entrée : c'est ça, réguler. Le seuil est
            // large exprès — la tension Zener est un réglage du composant, et
            // le test ne doit pas se casser si le défaut du catalogue change.
            verifier(v > 1.0 && v < 11.0,
                     "la sortie est régulée bien en dessous des 12 V d'entrée",
                     f(v) + " V");
        }
    }
}

// ---------------------------------------------------------------------------
// L'aperçu du fil suit la grille, comme le clic
//
// DECISION-FILS annonçait le piège : « l'aperçu doit être celui du tracé
// final, sinon il ment ». Il mentait — il suivait le curseur au pixel près
// alors que le clic aligne toujours son point sur la grille.
// ---------------------------------------------------------------------------
static void test_apercu_suit_la_grille() {
    std::printf("\n-- l'aperçu du fil suit la grille --\n");

    SceneSchema scene;
    ItemComposant* r = scene.ajouter_composant("resistance", QPointF(0, 0));
    verifier(r != nullptr, "une résistance est posée");
    if (!r) return;

    verifier(scene.amorcer_fil_au(r->position_borne(1)),
             "le tracé s'amorce depuis la borne 2");

    // Un point franchement HORS grille : 247 et 103 ne sont multiples de rien.
    const QPointF hors_grille(247, 103);
    QGraphicsSceneMouseEvent glissement(QEvent::GraphicsSceneMouseMove);
    glissement.setScenePos(hors_grille);
    glissement.setButtons(Qt::NoButton);
    QCoreApplication::sendEvent(&scene, &glissement);

    QGraphicsPathItem* apercu = nullptr;
    for (QGraphicsItem* item : scene.items())
        if (auto* chemin = dynamic_cast<QGraphicsPathItem*>(item)) apercu = chemin;
    verifier(apercu != nullptr, "l'aperçu existe pendant le tracé");
    if (!apercu) return;

    const QPointF bout = apercu->path().pointAtPercent(1.0);
    verifier(std::fmod(std::fabs(bout.x()), 10.0) < 0.01,
             "l'abscisse du bout de l'aperçu est sur la grille (pas de 10)",
             f(bout.x()));
    verifier(std::fmod(std::fabs(bout.y()), 10.0) < 0.01,
             "et son ordonnée aussi — le curseur était pourtant à (247, 103)",
             f(bout.y()));

    // Et ce bout est bien celui que le clic poserait.
    scene.poser_point_de_passage(hors_grille);
    ItemJonction* pose = nullptr;
    for (ItemJonction* j : scene.jonctions()) pose = j;
    verifier(pose != nullptr, "le clic pose bien un point de passage");
    if (pose)
        verifier(std::fabs(pose->pos().x() - bout.x()) < 0.01
                     && std::fabs(pose->pos().y() - bout.y()) < 0.01,
                 "et il tombe EXACTEMENT où l'aperçu l'annonçait",
                 f(pose->pos().x()) + "," + f(pose->pos().y()) + " contre "
                     + f(bout.x()) + "," + f(bout.y()));
    scene.abandonner_fil();
}

// ---------------------------------------------------------------------------
// Tirer un fil s'annule, et plusieurs fils s'annulent un par un
//
// `terminer_fil` n'appelait pas `memoriser()`. L'action la plus fréquente du
// logiciel n'entrait donc pas dans la pile, qui ne gardait que suppressions,
// rotations et collages — d'où l'impression qu'un seul geste tenait en
// mémoire, alors que Ctrl+Z sautait par-dessus tous les fils.
// ---------------------------------------------------------------------------
static void test_annulation_des_fils() {
    std::printf("\n-- tirer un fil s'annule, un par un --\n");

    SceneSchema scene;
    ItemComposant* pile = scene.ajouter_composant("pile", QPointF(0, 0));
    ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(300, 0));
    ItemComposant* r2 = scene.ajouter_composant("resistance", QPointF(300, 200));
    ItemComposant* masse = scene.ajouter_composant("masse", QPointF(600, 0));
    scene.oublier_historique();

    // Trois fils, tirés comme l'utilisateur le fait : amorcer puis refermer.
    struct Lien { ItemComposant* a; int ba; ItemComposant* b; int bb; };
    const Lien liens[] = {{pile, 0, r1, 0}, {r1, 1, masse, 0}, {pile, 1, r2, 0}};
    for (const Lien& l : liens) {
        verifier(scene.amorcer_fil_au(l.a->position_borne(l.ba)),
                 "le tracé s'amorce");
        verifier(scene.terminer_fil(l.b->position_borne(l.bb)),
                 "et le fil se referme");
    }
    verifier(scene.fils().size() == 3, "trois fils tirés",
             std::to_string(scene.fils().size()));

    // LE CONTRÔLE : trois annulations retirent les trois fils, un par un.
    verifier(scene.annuler() && scene.fils().size() == 2,
             "une annulation retire UN fil",
             std::to_string(scene.fils().size()) + " restants");
    verifier(scene.annuler() && scene.fils().size() == 1,
             "la deuxième en retire un autre",
             std::to_string(scene.fils().size()) + " restants");
    verifier(scene.annuler() && scene.fils().empty(),
             "la troisième vide le schéma de ses fils",
             std::to_string(scene.fils().size()) + " restants");

    // Et le rétablissement les repose dans l'ordre.
    verifier(scene.retablir() && scene.fils().size() == 1,
             "rétablir en repose un");
    verifier(scene.retablir() && scene.fils().size() == 2,
             "puis deux");
    verifier(scene.retablir() && scene.fils().size() == 3,
             "puis les trois");

    // Les composants n'ont pas bougé au passage.
    verifier(scene.composants().size() == 4,
             "et les quatre composants sont toujours là",
             std::to_string(scene.composants().size()));
}

int main(int argc, char** argv) {
    console_en_utf8();
    QApplication application(argc, argv);
    // Une identité PROPRE AU BANC : la fenêtre enregistre et relit sa
    // disposition dans QSettings, et sans cette ligne le banc lirait celle
    // que l'utilisateur a laissée sur sa machine. Un essai dont le résultat
    // dépend de l'état d'un poste ne prouve rien.
    application.setApplicationName("Simulateur embarqué — banc d'essai");
    application.setOrganizationName("Formation embarquée");
    std::printf("============================================================\n");
    std::printf("TESTS DE LA SAISIE DE SCHÉMA — exemplaires multiples\n");
    std::printf("============================================================\n");

    test_references();
    test_dix_led();
    test_masses_multiples();
    test_deux_cartes();
    test_cartes_non_cablees();
    test_panneau_analyses();
    test_cablage_souris();
    test_noeuds_et_instruments();
    test_interactions();
    test_declenchement();
    test_etiquettes();
    test_annulation();
    test_transfert_pcb();
    test_gestes_utilisateur();
    test_modification_en_marche();
    test_pense_bete_engendre();
    test_palette_montre_les_symboles();
    test_pas_de_selection_pendant_un_fil();
    test_tolerance_alignement();
    test_points_de_passage();
    test_capture_suit_le_zoom();
    test_scope_suit_son_cablage();
    test_lancer_compile_et_refuse();
    test_horloge_sans_carte();
    test_amorcer_fil_sans_mode();
    test_portee_des_commandes();
    test_derivation_en_t();
    test_derivation_survit();
    test_composants_grilles();
    test_pas_de_trainee();
    test_panneaux_retrecissables();
    test_famille_328p();
    test_analyseur_impedance();
    test_programmes_par_carte();
    experience_cout_survol();
    test_survol_allume_le_noeud();
    test_marqueur_erc_a_cote();
    test_presentation_et_disposition();
    test_cartouche_a_l_impression_seulement();
    test_erreur_compilation_cliquable();
    test_panneau_controle_mene_au_coupable();
    test_survol_noeuds_noues_par_le_nom();
    test_survol_description_suit_le_contenu();
    test_marqueur_erc_tient_dans_son_cadre();
    test_surbrillance_ne_survit_pas_a_la_suppression();
    test_marqueur_erc_evite_la_reference();
    test_colonne_en_octets_pas_en_caracteres();
    test_notation_scientifique();
    test_nom_de_noeud_impose_assaini();
    test_exemples_sans_carte();
    test_apercu_suit_la_grille();
    test_annulation_des_fils();
    test_depart_sur_fil_detruit();
    test_clic_immobile_ne_coupe_pas();
    test_base_de_temps_annoncee_est_celle_dessinee();
    test_proprietes_rendent_la_place();
    test_deplacer_un_segment();
    test_glisser_sans_deplacer_ne_laisse_rien();
    test_clic_gauche_designe_clic_droit_derive();
    test_fil_en_equerre_ne_se_deplace_pas();
    test_ctrl_clic_designe_un_fil();
    test_geste_interrompu_par_une_destruction();

    std::printf("\n============================================================\n");
    if (!g_echecs.empty()) {
        std::printf("%zu test(s) en échec sur %zu :\n", g_echecs.size(),
                    g_echecs.size() + g_ok);
        for (const std::string& titre : g_echecs)
            std::printf("   - %s\n", titre.c_str());
        return 1;
    }
    std::printf("TOUS LES TESTS PASSENT (%d)\n", g_ok);
    return 0;
}
