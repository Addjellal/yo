// Tests de la saisie de schéma, sans ouvrir de fenêtre.
//
// Ce que vérifie ce fichier est précisément ce qui casse quand on pose
// plusieurs exemplaires du même composant : l'attribution des références, le
// nommage des nœuds, et le fait que deux exemplaires restent bien deux
// composants distincts jusque dans la netlist.
//
//   QT_QPA_PLATFORM=offscreen ./tests_schema

#include <QApplication>
#include <QGraphicsSceneContextMenuEvent>
#include <QGraphicsSceneMouseEvent>
#include <QImage>
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
#include "core/engines/ProgrammesExemples.h"
#include <QDir>
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
             Qt::MouseButton bouton = Qt::LeftButton) {
    QGraphicsSceneMouseEvent evenement(type);
    evenement.setScenePos(point);
    evenement.setPos(point);
    evenement.setButton(bouton);
    evenement.setButtons(type == QEvent::GraphicsSceneMouseRelease
                             ? Qt::NoButton
                             : bouton);
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

    // --- cliquer ailleurs qu'une borne ne fabrique rien, et ne casse rien
    {
        SceneSchema scene;
        ItemComposant* r1 = scene.ajouter_composant("resistance", QPointF(0, 0));
        const QPointF depart = r1->position_borne(0);
        envoyer(scene, QEvent::GraphicsSceneMousePress, depart);
        envoyer(scene, QEvent::GraphicsSceneMouseRelease, depart);
        envoyer(scene, QEvent::GraphicsSceneMousePress, QPointF(600, 600));
        verifier(scene.fils().empty(),
                 "un clic dans le vide abandonne le fil en cours");

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
    for (QGraphicsItem* item : scene.items())
        if (item->type() != ItemComposant::Type && item->type() != ItemFil::Type)
            return false;
    return true;
}

// Tous les fils désignent-ils des composants encore présents, et des bornes
// qui existent ?
bool fils_coherents(SceneSchema& scene) {
    std::set<const ItemComposant*> vivants;
    for (ItemComposant* composant : scene.composants()) vivants.insert(composant);
    for (ItemFil* fil : scene.fils()) {
        if (!vivants.count(fil->depart()) || !vivants.count(fil->arrivee()))
            return false;
        if (fil->borne_depart() < 0
            || fil->borne_depart() >= fil->depart()->nb_bornes())
            return false;
        if (fil->borne_arrivee() < 0
            || fil->borne_arrivee() >= fil->arrivee()->nb_bornes())
            return false;
    }
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

int main(int argc, char** argv) {
    QApplication application(argc, argv);
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
    test_composants_grilles();
    test_pas_de_trainee();
    test_panneaux_retrecissables();
    test_famille_328p();
    test_analyseur_impedance();
    test_programmes_par_carte();

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
