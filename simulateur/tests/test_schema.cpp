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
#include <QPointF>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <set>
#include <string>
#include <vector>

#include "app/schematic/ItemComposant.h"
#include "app/schematic/ItemFil.h"
#include "app/panels/FenetreInstrument.h"
#include "app/panels/PanneauAnalyses.h"
#include "app/schematic/SceneSchema.h"
#include "core/Device.h"

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
