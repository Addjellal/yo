// Tests du cœur : netlist, catalogue, moteur analogique (ngspice) et
// moteur microcontrôleur (simavr), puis leur COUPLAGE — c'est ce couplage
// qui fait un simulateur de type Proteus.
//
// Aucun écran nécessaire : ./tests_coeur


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

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <complex>
#include <cstring>
#include <cstdlib>
#include <functional>
#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "coeur/Device.h"
#include "coeur/Netlist.h"
#include "coeur/analyses/Analyses.h"
#include "coeur/analyses/Campagne.h"
#include <fstream>
#include <set>

#include "coeur/moteurs/microcontroleurs/AvrEngine.h"
#include "coeur/moteurs/microcontroleurs/CortexEngine.h"
#include "coeur/moteurs/microcontroleurs/CoeurXtensa.h"
#include "coeur/moteurs/microcontroleurs/Microcontroleur.h"
#include "coeur/compilation/ProgrammesExemples.h"
#include "coeur/moteurs/analogique/SolveurIntegre.h"
#include "coeur/moteurs/numerique/MoteurNumerique.h"
#include "coeur/moteurs/analogique/NgspiceEngine.h"
#include "coeur/documents/Documents.h"
#include "coeur/pcb/Empreintes.h"
#include "coeur/pcb/Pcb.h"
#include "coeur/pcb/Routeur.h"

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

// ---------------------------------------------------------------------------
static void test_netlist() {
    std::printf("\n[1] Netlist et catalogue\n");
    coeur::Netlist netlist;
    auto& r = netlist.ajouter("R1", "resistance");
    r.valeurs["ohms"] = 220;
    netlist.relier("R1", "1", "D13");
    netlist.relier("R1", "2", "GND");

    verifier(netlist.instances().size() == 1, "ajout d'une instance");
    verifier(netlist.trouver("R1") != nullptr, "recherche par référence");
    verifier(netlist.trouver("R1")->valeur("ohms") == 220, "valeur conservée");
    verifier(netlist.occurrences("D13") == 1, "comptage des bornes d'un nœud");

    const auto* modele = coeur::Catalogue::instance().modele("led");
    verifier(modele != nullptr, "catalogue : modèle LED présent");
    verifier(modele && modele->bornes.size() == 2, "LED : 2 bornes");
    verifier(modele && !modele->empreinte.pastilles.empty(),
             "LED : empreinte PCB déjà décrite (prêt pour le module PCB)");
    verifier(coeur::Catalogue::instance().tous().size() >= 8,
             "catalogue : au moins 8 composants");

    netlist.supprimer("R1");
    verifier(netlist.instances().empty(), "suppression d'une instance");
}

// ---------------------------------------------------------------------------
static void test_ngspice() {
    std::printf("\n[2] Moteur analogique\n");

    // --- LED rouge + résistance 220 Ω pilotée par une sortie à 5 V
    coeur::Netlist netlist;
    auto& led = netlist.ajouter("LED1", "led");
    led.textes["couleur"] = "rouge";
    netlist.relier("LED1", "A", "D13");
    netlist.relier("LED1", "K", "N1");
    auto& r = netlist.ajouter("R1", "resistance");
    r.valeurs["ohms"] = 220;
    netlist.relier("R1", "1", "N1");
    netlist.relier("R1", "2", "GND");

    std::vector<coeur::BrocheElectrique> broches = {
        {"D13", coeur::BrocheElectrique::Mode::Sortie, 5.0, 25.0}};

    coeur::NgspiceEngine moteur;
    moteur.construire(netlist, broches);
    bool resolu = moteur.resoudre();
    verifier(resolu, "résolution du circuit LED + résistance");

    double courant = std::fabs(moteur.courant("LED1"));
    verifier(courant > 0.008 && courant < 0.016,
             "LED + 220 Ω : courant nominal (8-16 mA)",
             f(courant * 1000, 1) + " mA");
    double v_n1 = moteur.tension("N1");
    verifier(v_n1 > 1.5 && v_n1 < 3.5, "chute de tension cohérente sur la LED",
             "V(N1) = " + f(v_n1) + " V");

    // --- extinction : sortie à 0 V
    broches[0].tension = 0.0;
    moteur.construire(netlist, broches);
    moteur.resoudre();
    double eteinte = std::fabs(moteur.courant("LED1"));
    verifier(eteinte < 1e-4, "LED éteinte quand la broche est à 0 V",
             f(eteinte * 1000, 4) + " mA");

    // --- LED SANS résistance : surintensité (l'erreur classique du débutant)
    coeur::Netlist sans_r;
    auto& led2 = sans_r.ajouter("LED1", "led");
    led2.textes["couleur"] = "rouge";
    sans_r.relier("LED1", "A", "D13");
    sans_r.relier("LED1", "K", "GND");
    broches[0].tension = 5.0;
    moteur.construire(sans_r, broches);
    moteur.resoudre();
    double exces = std::fabs(moteur.courant("LED1"));
    verifier(exces > 0.030, "LED sans résistance : surintensité détectée",
             f(exces * 1000, 1) + " mA");

    // --- pont diviseur par potentiomètre : la tension suit la position
    coeur::Netlist pont;
    auto& pot = pont.ajouter("POT1", "potentiometre");
    pot.valeurs["ohms"] = 10000;
    pot.valeurs["position"] = 25;
    pont.relier("POT1", "A", "5V");
    pont.relier("POT1", "W", "A0");
    pont.relier("POT1", "B", "GND");
    std::vector<coeur::BrocheElectrique> entree = {
        {"A0", coeur::BrocheElectrique::Mode::Entree, 0.0, 0.0}};
    moteur.construire(pont, entree);
    moteur.resoudre();
    double v_a0 = moteur.tension("A0");
    verifier(presque(v_a0, 1.25, 0.05), "potentiomètre à 25 % -> 1,25 V",
             f(v_a0) + " V");

    // --- bouton + pull-up interne : logique inversée
    coeur::Netlist bouton_net;
    auto& bp = bouton_net.ajouter("BP1", "bouton");
    bp.valeurs["appuye"] = 0;
    bouton_net.relier("BP1", "1", "D2");
    bouton_net.relier("BP1", "2", "GND");
    std::vector<coeur::BrocheElectrique> pullup = {
        {"D2", coeur::BrocheElectrique::Mode::PullUp, 5.0, 20000.0}};
    moteur.construire(bouton_net, pullup);
    moteur.resoudre();
    verifier(moteur.tension("D2") > 4.5, "bouton relâché + pull-up -> ~5 V",
             f(moteur.tension("D2")) + " V");
    bouton_net.trouver("BP1")->valeurs["appuye"] = 1;
    moteur.construire(bouton_net, pullup);
    moteur.resoudre();
    verifier(moteur.tension("D2") < 0.5, "bouton appuyé -> ~0 V",
             f(moteur.tension("D2")) + " V");

    // --- transistor : un vrai composant non linéaire, hors de portée d'un
    //     solveur maison ; c'est l'apport de ngspice
    coeur::Netlist ampli;
    auto& q = ampli.ajouter("Q1", "transistor_npn");
    (void)q;
    ampli.relier("Q1", "B", "NB");
    ampli.relier("Q1", "C", "NC");
    ampli.relier("Q1", "E", "GND");
    auto& rb = ampli.ajouter("RB", "resistance");
    rb.valeurs["ohms"] = 10000;
    ampli.relier("RB", "1", "D9");
    ampli.relier("RB", "2", "NB");
    auto& rc = ampli.ajouter("RC", "resistance");
    rc.valeurs["ohms"] = 1000;
    ampli.relier("RC", "1", "5V");
    ampli.relier("RC", "2", "NC");
    std::vector<coeur::BrocheElectrique> commande = {
        {"D9", coeur::BrocheElectrique::Mode::Sortie, 5.0, 25.0}};
    moteur.construire(ampli, commande);
    moteur.resoudre();
    double vc_sature = moteur.tension("NC");
    commande[0].tension = 0.0;
    moteur.construire(ampli, commande);
    moteur.resoudre();
    double vc_bloque = moteur.tension("NC");
    verifier(vc_sature < 0.5 && vc_bloque > 4.5,
             "transistor NPN : saturé puis bloqué",
             "Vc = " + f(vc_sature) + " V puis " + f(vc_bloque) + " V");
}

// ---------------------------------------------------------------------------
// [48] AUDIT — cinq défauts trouvés en relisant la carte et les analyses
// ---------------------------------------------------------------------------
static void test_audit_carte_et_analyses() {
    std::printf("\n[48] Audit : carte, documents, analyses\n");

    // --- 1. UNE PASTILLE CMS N'A DE CUIVRE QUE SUR UNE FACE.
    //
    // La boucle qui grave les pastilles ne regardait pas la couche demandée —
    // contrairement à celle des pistes, juste en dessous. Un boîtier monté en
    // surface ressortait donc avec ses pastilles sur LES DEUX FACES : du
    // cuivre qui n'existe pas, payé au fabricant et court-circuitant ce qui
    // passe dessous.
    {
        coeur::Netlist netlist;
        netlist.ajouter("U1", "capteur_courant");   // empreinte SOIC-8, CMS
        netlist.relier("U1", "VCC", "P5V");
        coeur::CartePcb carte = coeur::CartePcb::depuis_netlist(netlist);
        int cms = 0, traversantes = 0;
        for (const auto& pastille : carte.pastilles()) {
            if (pastille.mecanique()) continue;
            (pastille.percage > 0 ? traversantes : cms)++;
        }
        verifier(cms > 0, "le boîtier d'essai est bien monté en surface",
                 std::to_string(cms) + " pastille(s) sans perçage");
        if (cms > 0) {
            auto compter = [](const std::string& gerber) {
                int n = 0;
                for (std::size_t k = gerber.find("D03*"); k != std::string::npos;
                     k = gerber.find("D03*", k + 1))
                    ++n;
                return n;
            };
            const int dessus = compter(carte.gerber(0));
            const int dessous = compter(carte.gerber(1));
            verifier(dessus > 0, "les pastilles sont gravées sur le dessus",
                     std::to_string(dessus));
            verifier(dessous == traversantes,
                     "et le dessous ne reçoit QUE les trous traversants",
                     std::to_string(dessous) + " flash(s) pour "
                         + std::to_string(traversantes) + " traversante(s)");
        }
    }

    // --- 2. LE CUIVRE DÉBORDE, PAS L'AXE.
    //
    // Le contrôle comparait les coordonnées brutes au contour : une piste d'un
    // millimètre tracée pile sur le bord passait pour bonne, alors qu'un
    // demi-millimètre de cuivre sort de la carte et sera coupé à la fraise.
    {
        coeur::Netlist netlist;
        netlist.ajouter("R1", "resistance");
        netlist.relier("R1", "1", "A");
        netlist.relier("R1", "2", "B");
        coeur::CartePcb carte = coeur::CartePcb::depuis_netlist(netlist);
        // Un contour large : la piste ne doit sortir QUE par sa demi-largeur,
        // sinon le test passerait aussi sans le correctif, pour une autre
        // raison — et ne prouverait rien.
        carte.largeur = 40.0;
        carte.hauteur = 40.0;
        carte.pistes.push_back({"A", 0.0, 10.0, 0.0, 30.0, 1.0, 0});
        const auto anomalies = carte.controler();
        bool signalee = false;
        for (const auto& a : anomalies)
            if (a.message.find("hors du contour") != std::string::npos)
                signalee = true;
        verifier(signalee,
                 "une piste dont le CUIVRE sort de la carte est signalée, "
                 "même si son axe est pile sur le bord");
    }

    // --- 3. L'ENCOMBREMENT D'UNE PASTILLE, C'EST SON PLUS GRAND CÔTÉ.
    //
    // Une pastille CMS fait 0,65 mm de large pour 1,55 de haut : le
    // demi-diamètre seul la croyait trois fois plus petite qu'elle n'est, et
    // un foret qui la mord le long de son grand côté ne déclenchait rien. Le
    // contrôle « piste frôle une pastille », quelques lignes plus bas, faisait
    // pourtant déjà le calcul juste — la règle était écrite, pas appliquée.
    {
        coeur::Netlist netlist;
        netlist.ajouter("U1", "capteur_courant");
        netlist.relier("U1", "VCC", "P5V");
        coeur::CartePcb carte = coeur::CartePcb::depuis_netlist(netlist);
        const std::vector<coeur::PastillePosee> pastilles = carte.pastilles();
        const coeur::PastillePosee* haute = nullptr;
        for (const auto& p : pastilles)
            if (!p.mecanique() && p.hauteur > p.diametre * 1.5) haute = &p;
        verifier(haute != nullptr,
                 "le boîtier a bien une pastille plus haute que large");
        if (haute) {
            // Un trou de fixation posé le long du GRAND côté, à une distance
            // qui laisse le demi-diamètre tranquille (0,5 + 0,325 = 0,825 mm)
            // mais entame la hauteur (0,5 + 0,775 = 1,275 mm).
            coeur::PastillePosee trou;
            trou.composant = carte.composants.front().reference;
            trou.numero = 0;              // ni numéro ni borne : c'est un trou,
            trou.borne.clear();           // pas du cuivre — voir mecanique()
            trou.percage = 1.0;
            trou.diametre = 1.0;
            // Les pastilles d'un composant sont relatives à son centre.
            trou.x = haute->x - carte.composants.front().x;
            trou.y = haute->y - carte.composants.front().y + 1.0;
            carte.composants.front().pastilles.push_back(trou);
            bool signale = false;
            for (const auto& a : carte.controler())
                if (a.message.find("trou de fixation dans la pastille")
                    != std::string::npos)
                    signale = true;
            verifier(signale,
                     "un foret qui mord une pastille par son grand côté est "
                     "signalé");
        }
    }

    // --- 4. UN INSTRUMENT VIRTUEL NE S'ACHÈTE NI NE SE ROUTE.
    //
    // Un voltmètre figurait dans le tableau « qu'on envoie au fournisseur »,
    // et dans le fichier qui part vers le routage. Le critère existait
    // pourtant déjà, et servait déjà au placement sur la carte : il n'avait
    // simplement pas été appliqué ici.
    {
        coeur::Netlist netlist;
        auto& r = netlist.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 220;
        netlist.relier("R1", "1", "A");
        netlist.relier("R1", "2", "B");
        netlist.ajouter("VM1", "voltmetre");
        netlist.relier("VM1", "+", "A");
        netlist.relier("VM1", "-", "B");

        bool voltmetre_liste = false, resistance_listee = false;
        for (const auto& ligne : coeur::nomenclature(netlist)) {
            if (ligne.type == "voltmetre") voltmetre_liste = true;
            if (ligne.type == "resistance") resistance_listee = true;
        }
        verifier(resistance_listee, "la résistance figure à la nomenclature");
        verifier(!voltmetre_liste,
                 "le voltmètre, non : c'est une sonde, elle ne s'achète pas");

        const std::string kicad = coeur::netlist_kicad(netlist);
        verifier(kicad.find("\"R1\"") != std::string::npos,
                 "la résistance part vers le routage");
        verifier(kicad.find("\"VM1\"") == std::string::npos,
                 "le voltmètre, non");
    }

    // --- 5. UN PASSE-HAUT A UNE COUPURE, LUI AUSSI.
    //
    // La recherche ne regardait que les fréquences SUPÉRIEURES au sommet — ce
    // qui suppose un passe-bas, dont le gain redescend ensuite. Sur un
    // passe-haut, le sommet est au bout du balayage et la coupure est de
    // l'autre côté : la fonction rendait zéro, et le panneau se contentait
    // alors d'omettre la ligne. Un filtre parfaitement caractérisé n'affichait
    // aucune coupure, sans un mot.
    {
        const double fc = 1000.0;
        coeur::Balayage balayage;
        coeur::Courbe sortie;
        for (int k = 0; k <= 80; ++k) {
            const double f = 10.0 * std::pow(10.0, k / 20.0);   // 10 Hz → 100 kHz
            balayage.abscisse.push_back(f);
            const double x = f / fc;
            sortie.valeurs.push_back(x / std::sqrt(1.0 + x * x));   // passe-haut
        }
        const double trouvee = coeur::frequence_coupure(balayage, sortie, nullptr);
        verifier(std::fabs(trouvee - fc) < fc * 0.15,
                 "la coupure d'un passe-haut est trouvée",
                 f(trouvee) + " Hz au lieu de " + f(fc));

        // Et le passe-bas continue de marcher : on ne remplace pas un trou
        // par un autre.
        coeur::Courbe passe_bas;
        for (double freq : balayage.abscisse) {
            const double x = freq / fc;
            passe_bas.valeurs.push_back(1.0 / std::sqrt(1.0 + x * x));
        }
        const double bas = coeur::frequence_coupure(balayage, passe_bas, nullptr);
        verifier(std::fabs(bas - fc) < fc * 0.15,
                 "et celle d'un passe-bas ne s'est pas perdue en chemin",
                 f(bas) + " Hz");
    }
}

// ---------------------------------------------------------------------------
static const char* kBlink = R"(
#include <avr/io.h>

int main(void) {
    DDRB |= (1 << 5);            /* D13 en sortie */
    while (1) {
        PORTB |= (1 << 5);
        for (volatile long i = 0; i < 2000; i++) { }
        PORTB &= ~(1 << 5);
        for (volatile long i = 0; i < 2000; i++) { }
    }
    return 0;
}
)";

static std::string g_firmware;

static void test_simavr() {
    std::printf("\n[3] Moteur microcontrôleur (cœur intégré + avr-gcc)\n");
    if (!coeur::AvrEngine::avr_gcc_disponible()) {
        std::printf("  (avr-gcc absent — section ignorée)\n");
        return;
    }

    g_firmware = "/tmp/sim_blink.elf";
    std::string journal;
    bool compile = coeur::AvrEngine::compiler_source(kBlink, g_firmware,
                                                     &journal);
    verifier(compile, "compilation du firmware par avr-gcc", journal);
    if (!compile) return;

    coeur::AvrEngine mcu;
    verifier(mcu.charger(g_firmware), "chargement du .elf dans le cœur",
             mcu.erreur());

    int basculements = 0;
    mcu.sur_changement_broche([&](int broche, bool) {
        if (broche == 13) ++basculements;
    });

    mcu.avancer(2000000);          // 2 millions de cycles = 125 ms simulées
    verifier(basculements > 2, "le VRAI firmware fait basculer D13",
             std::to_string(basculements) + " basculements");
    verifier(presque(mcu.temps_ms(), 125.0, 5.0),
             "horloge au cycle près (16 MHz)",
             f(mcu.temps_ms(), 1) + " ms");
    verifier(mcu.cycle() >= 2000000, "compteur de cycles cohérent");
}

// ---------------------------------------------------------------------------
// LE test qui compte : le firmware pilote la broche, ngspice calcule le
// courant réel dans la LED. C'est le principe même de Proteus.
static void test_couplage() {
    std::printf("\n[4] Couplage firmware <-> circuit analogique\n");
    if (!coeur::AvrEngine::avr_gcc_disponible() || g_firmware.empty()) {
        std::printf("  (moteurs indisponibles — section ignorée)\n");
        return;
    }

    coeur::Netlist netlist;
    auto& led = netlist.ajouter("LED1", "led");
    led.textes["couleur"] = "rouge";
    netlist.relier("LED1", "A", "D13");
    netlist.relier("LED1", "K", "N1");
    auto& r = netlist.ajouter("R1", "resistance");
    r.valeurs["ohms"] = 220;
    netlist.relier("R1", "1", "N1");
    netlist.relier("R1", "2", "GND");

    coeur::NgspiceEngine analogique;
    coeur::AvrEngine mcu;
    if (!mcu.charger(g_firmware)) {
        verifier(false, "chargement du firmware pour le couplage", mcu.erreur());
        return;
    }

    double courant_allume = 0.0, courant_eteint = -1.0;
    int recalculs = 0;

    mcu.sur_changement_broche([&](int broche, bool haut) {
        if (broche != 13) return;
        std::vector<coeur::BrocheElectrique> broches = {
            {"D13", coeur::BrocheElectrique::Mode::Sortie, haut ? 5.0 : 0.0,
             25.0}};
        analogique.construire(netlist, broches);
        analogique.resoudre();
        const double i = std::fabs(analogique.courant("LED1"));
        if (haut) courant_allume = i;
        else courant_eteint = i;
        ++recalculs;
    });

    mcu.avancer(3000000);

    verifier(recalculs >= 2, "le circuit est recalculé à chaque front",
             std::to_string(recalculs) + " résolutions");
    verifier(courant_allume > 0.008,
             "firmware -> broche haute -> LED parcourue par ~12 mA",
             f(courant_allume * 1000, 1) + " mA");
    verifier(courant_eteint >= 0.0 && courant_eteint < 1e-4,
             "firmware -> broche basse -> courant nul",
             f(courant_eteint * 1000, 4) + " mA");
    verifier(courant_allume > courant_eteint * 100 + 0.005,
             "le programme commande bien la LED (rapport marche/arrêt)");
}

// ---------------------------------------------------------------------------
// Couplage dans l'autre sens : le circuit impose un niveau, le firmware le
// lit. Sans cela un bouton ou un capteur ne servirait à rien.
static const char* kRecopie = R"(
#include <avr/io.h>
int main(void) {
    DDRD &= ~(1 << 2);           /* D2 en entrée */
    PORTD |= (1 << 2);           /* pull-up interne */
    DDRB |= (1 << 5);            /* D13 en sortie */
    while (1) {
        if (PIND & (1 << 2)) PORTB |=  (1 << 5);   /* relâché -> allumée */
        else                 PORTB &= ~(1 << 5);   /* appuyé  -> éteinte */
    }
}
)";

static void test_couplage_inverse() {
    std::printf("\n[5] Couplage circuit -> firmware (lecture d'une entrée)\n");
    if (!coeur::AvrEngine::avr_gcc_disponible()) {
        std::printf("  (moteurs indisponibles — section ignorée)\n");
        return;
    }
    const std::string firmware = "/tmp/sim_recopie.elf";
    std::string journal;
    if (!coeur::AvrEngine::compiler_source(kRecopie, firmware, &journal)) {
        verifier(false, "compilation du programme de recopie", journal);
        return;
    }
    coeur::AvrEngine mcu;
    if (!mcu.charger(firmware)) {
        verifier(false, "chargement du programme de recopie", mcu.erreur());
        return;
    }

    mcu.avancer(200000);
    verifier(!mcu.direction_sortie(2), "D2 est bien configurée en entrée");
    verifier(mcu.pullup_actif(2), "le pull-up interne de D2 est actif");
    verifier(mcu.direction_sortie(13), "D13 est bien configurée en sortie");

    // Bouton relâché : le circuit laisse la broche à 5 V (pull-up).
    mcu.definir_niveau_externe(2, true);
    mcu.avancer(200000);
    const bool allumee = mcu.niveau_port(13);

    // Bouton appuyé : le circuit tire la broche à la masse.
    mcu.definir_niveau_externe(2, false);
    mcu.avancer(200000);
    const bool eteinte = !mcu.niveau_port(13);

    verifier(allumee, "niveau haut imposé au circuit -> le firmware allume D13");
    verifier(eteinte, "niveau bas imposé au circuit -> le firmware éteint D13");

    // Retour au niveau haut : on vérifie que ce n'est pas un état bloqué.
    mcu.definir_niveau_externe(2, true);
    mcu.avancer(200000);
    verifier(mcu.niveau_port(13), "le firmware suit bien les changements");
}

// ---------------------------------------------------------------------------
// Conversion analogique-numérique : la tension calculée par ngspice remonte
// dans l'ADC et pilote une décision du programme.
static const char* kSeuil = R"(
#include <avr/io.h>
static uint16_t lire_adc(uint8_t canal) {
    ADMUX = (1 << REFS0) | (canal & 0x0F);
    ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
    ADCSRA |= (1 << ADSC);
    while (ADCSRA & (1 << ADSC)) { }
    return ADC;
}
int main(void) {
    DDRB |= (1 << 5);
    while (1) {
        if (lire_adc(0) > 512) PORTB |=  (1 << 5);
        else                   PORTB &= ~(1 << 5);
    }
}
)";

static void test_adc() {
    std::printf("\n[6] Conversion analogique-numérique\n");
    if (!coeur::AvrEngine::avr_gcc_disponible()) {
        std::printf("  (moteurs indisponibles — section ignorée)\n");
        return;
    }
    const std::string firmware = "/tmp/sim_seuil.elf";
    std::string journal;
    if (!coeur::AvrEngine::compiler_source(kSeuil, firmware, &journal)) {
        verifier(false, "compilation du programme à seuil", journal);
        return;
    }
    coeur::AvrEngine mcu;
    if (!mcu.charger(firmware)) {
        verifier(false, "chargement du programme à seuil", mcu.erreur());
        return;
    }

    mcu.definir_tension_adc(0, 4.0);     // au-dessus de 2,5 V
    mcu.avancer(400000);
    const bool haut = mcu.niveau_port(13);

    mcu.definir_tension_adc(0, 1.0);     // en dessous
    mcu.avancer(400000);
    const bool bas = !mcu.niveau_port(13);

    verifier(haut, "4 V sur A0 -> le programme dépasse le seuil");
    verifier(bas, "1 V sur A0 -> le programme repasse sous le seuil");
}

// ---------------------------------------------------------------------------
// Tout le catalogue passe au banc : chaque composant est monté seul dans un
// circuit et doit être accepté par ngspice. Sans ce test, un modèle mal écrit
// ne se manifesterait qu'au moment où l'utilisateur le pose sur son schéma.
static void test_catalogue_complet() {
    std::printf("\n[7] Le catalogue entier passe dans ngspice\n");
    int examines = 0, refuses = 0;
    std::string liste_refuses;

    for (const coeur::Modele* modele : coeur::Catalogue::instance().tous()) {
        if (!modele->vers_spice || modele->bornes.empty()) continue;
        ++examines;

        coeur::Netlist netlist;
        auto& instance = netlist.ajouter("X1", modele->type);
        for (const auto& propriete : modele->proprietes) {
            if (propriete.genre == coeur::Propriete::Genre::Choix)
                instance.textes[propriete.cle] = propriete.defaut_texte;
            else
                instance.valeurs[propriete.cle] = propriete.defaut;
        }
        // Première borne pilotée à 5 V, dernière à la masse, les autres sur
        // des nœuds distincts ramenés à la masse par 1 kΩ : un montage
        // volontairement quelconque, mais jamais dégénéré.
        const int dernier = static_cast<int>(modele->bornes.size()) - 1;
        for (int k = 0; k <= dernier; ++k) {
            const std::string& borne = modele->bornes[k].nom;
            if (k == 0)
                netlist.relier("X1", borne, "D13");
            else if (k == dernier) {
                // Pas de liaison directe à la masse : un composant qui est
                // lui-même une source (l'alimentation triphasée) s'y
                // court-circuiterait, et le banc accuserait le modèle d'un
                // défaut de câblage.
                netlist.relier("X1", borne, "FIN");
                auto& retour = netlist.ajouter("RFIN", "resistance");
                retour.valeurs["ohms"] = 1000;
                netlist.relier("RFIN", "1", "FIN");
                netlist.relier("RFIN", "2", "GND");
            }
            else {
                const std::string noeud = "T" + std::to_string(k);
                netlist.relier("X1", borne, noeud);
                auto& charge = netlist.ajouter("RT" + std::to_string(k),
                                               "resistance");
                charge.valeurs["ohms"] = 1000;
                netlist.relier(charge.reference, "1", noeud);
                netlist.relier(charge.reference, "2", "GND");
            }
        }

        coeur::NgspiceEngine moteur;
        moteur.construire(netlist,
                          {{"D13", coeur::BrocheElectrique::Mode::Sortie, 5.0,
                            25.0}});
        const bool ok = moteur.resoudre() && moteur.erreurs().empty();
        if (!ok) {
            ++refuses;
            liste_refuses += " " + modele->type;
        }
    }
    verifier(examines >= 25,
             "le catalogue compte au moins 25 composants simulables",
             std::to_string(examines) + " examinés");
    verifier(refuses == 0, "tous les modèles sont acceptés par ngspice",
             refuses ? ("refusés :" + liste_refuses) : "");
}

// ---------------------------------------------------------------------------
// Vérification du comportement physique des nouveaux modèles. Compiler n'est
// pas simuler juste : chaque composant doit faire ce que promet sa fiche.
static void test_physique_catalogue() {
    std::printf("\n[8] Comportement physique des modèles\n");
    coeur::NgspiceEngine moteur;

    auto resistance_entre = [&](coeur::Netlist& netlist, const char* type,
                                const char* borne_a, const char* borne_b) {
        netlist.relier("X1", borne_a, "D13");
        netlist.relier("X1", borne_b, "N1");
        auto& r = netlist.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 1000;
        netlist.relier("R1", "1", "N1");
        netlist.relier("R1", "2", "GND");
        moteur.construire(netlist,
                          {{"D13", coeur::BrocheElectrique::Mode::Sortie, 5.0,
                            25.0}});
        moteur.resoudre();
        (void)type;
        return moteur.tension("N1");
    };

    {   // --- diode : environ 0,7 V de chute en direct
        coeur::Netlist netlist;
        netlist.ajouter("X1", "diode").textes["reference"] = "1N4148";
        const double v = resistance_entre(netlist, "diode", "A", "K");
        const double chute = moteur.tension("D13") - v;
        verifier(chute > 0.4 && chute < 0.9,
                 "diode 1N4148 : chute directe voisine de 0,7 V",
                 f(chute) + " V");
    }
    {   // --- thermistance CTN : 10 kΩ à 25 °C, moins quand il fait chaud
        auto resistance_a = [&](double temperature) {
            coeur::Netlist netlist;
            auto& th = netlist.ajouter("X1", "thermistance");
            th.valeurs["temperature"] = temperature;
            th.valeurs["r25"] = 10000;
            th.valeurs["beta"] = 3950;
            netlist.relier("X1", "1", "5V");
            netlist.relier("X1", "2", "N1");
            auto& r = netlist.ajouter("R1", "resistance");
            r.valeurs["ohms"] = 10000;
            netlist.relier("R1", "1", "N1");
            netlist.relier("R1", "2", "GND");
            moteur.construire(netlist, {});
            moteur.resoudre();
            const double v = moteur.tension("N1");
            return v > 0 ? 10000.0 * (5.0 - v) / v : 0.0;
        };
        const double froide = resistance_a(25);
        const double chaude = resistance_a(80);
        verifier(presque(froide, 10000, 300),
                 "thermistance : 10 kΩ à 25 °C", f(froide, 0) + " Ω");
        verifier(chaude < froide / 4,
                 "thermistance : la résistance chute quand la température monte",
                 f(chaude, 0) + " Ω à 80 °C");
    }
    {   // --- photorésistance : sombre = très résistante, éclairée = passante
        auto tension_a = [&](double luminosite) {
            coeur::Netlist netlist;
            netlist.ajouter("X1", "ldr").valeurs["luminosite"] = luminosite;
            netlist.relier("X1", "1", "5V");
            netlist.relier("X1", "2", "N1");
            auto& r = netlist.ajouter("R1", "resistance");
            r.valeurs["ohms"] = 10000;
            netlist.relier("R1", "1", "N1");
            netlist.relier("R1", "2", "GND");
            moteur.construire(netlist, {});
            moteur.resoudre();
            return moteur.tension("N1");
        };
        const double noir = tension_a(0);
        const double plein_jour = tension_a(100);
        verifier(noir < 0.2 && plein_jour > 4.5,
                 "photorésistance : la tension suit l'éclairement",
                 f(noir) + " V dans le noir, " + f(plein_jour) + " V en plein jour");
    }
    {   // --- porte NON-ET : la table de vérité, mesurée en volts
        auto sortie = [&](double a, double b) {
            coeur::Netlist netlist;
            netlist.ajouter("X1", "porte_nand");
            netlist.relier("X1", "A", "D2");
            netlist.relier("X1", "B", "D3");
            netlist.relier("X1", "Y", "N1");
            auto& r = netlist.ajouter("R1", "resistance");
            r.valeurs["ohms"] = 10000;
            netlist.relier("R1", "1", "N1");
            netlist.relier("R1", "2", "GND");
            moteur.construire(
                netlist, {{"D2", coeur::BrocheElectrique::Mode::Sortie, a, 25.0},
                          {"D3", coeur::BrocheElectrique::Mode::Sortie, b, 25.0}});
            moteur.resoudre();
            return moteur.tension("N1");
        };
        const bool table = sortie(0, 0) > 4.5 && sortie(5, 0) > 4.5 &&
                           sortie(0, 5) > 4.5 && sortie(5, 5) < 0.5;
        verifier(table, "porte NON-ET : table de vérité respectée",
                 "0/0=" + f(sortie(0, 0), 1) + " 1/1=" + f(sortie(5, 5), 1));
    }
    {   // --- amplificateur opérationnel monté en suiveur
        coeur::Netlist netlist;
        netlist.ajouter("X1", "ampli_op");
        netlist.relier("X1", "IN+", "N_ENTREE");
        netlist.relier("X1", "IN-", "N_SORTIE");
        netlist.relier("X1", "OUT", "N_SORTIE");
        auto& haut = netlist.ajouter("R1", "resistance");
        haut.valeurs["ohms"] = 10000;
        netlist.relier("R1", "1", "5V");
        netlist.relier("R1", "2", "N_ENTREE");
        auto& bas = netlist.ajouter("R2", "resistance");
        bas.valeurs["ohms"] = 10000;
        netlist.relier("R2", "1", "N_ENTREE");
        netlist.relier("R2", "2", "GND");
        moteur.construire(netlist, {});
        moteur.resoudre();
        const double entree = moteur.tension("N_ENTREE");
        const double sortie = moteur.tension("N_SORTIE");
        verifier(presque(sortie, entree, 0.05) && presque(entree, 2.5, 0.1),
                 "ampli op en suiveur : la sortie recopie l'entrée",
                 "entrée " + f(entree) + " V, sortie " + f(sortie) + " V");
    }
    {   // --- régulateur 7805 : 12 V en entrée donnent 5 V en sortie
        coeur::Netlist netlist;
        netlist.ajouter("X1", "regulateur_5v");
        auto& pile = netlist.ajouter("V1", "pile");
        pile.valeurs["volts"] = 12;
        netlist.relier("V1", "+", "N_ENTREE");
        netlist.relier("V1", "-", "GND");
        netlist.relier("X1", "IN", "N_ENTREE");
        netlist.relier("X1", "GND", "GND");
        netlist.relier("X1", "OUT", "N_SORTIE");
        auto& charge = netlist.ajouter("R1", "resistance");
        charge.valeurs["ohms"] = 100;
        netlist.relier("R1", "1", "N_SORTIE");
        netlist.relier("R1", "2", "GND");
        moteur.construire(netlist, {});
        moteur.resoudre();
        verifier(presque(moteur.tension("N_SORTIE"), 5.0, 0.1),
                 "régulateur 7805 : 12 V -> 5 V",
                 f(moteur.tension("N_SORTIE")) + " V");
    }
    {   // --- relais : le contact travail se ferme quand la bobine est excitée
        auto tension_contact = [&](double commande) {
            coeur::Netlist netlist;
            netlist.ajouter("X1", "relais");
            netlist.relier("X1", "A", "D7");
            netlist.relier("X1", "B", "GND");
            netlist.relier("X1", "COM", "5V");
            netlist.relier("X1", "NO", "N_CHARGE");
            netlist.relier("X1", "NC", "N_REPOS");
            auto& charge = netlist.ajouter("R1", "resistance");
            charge.valeurs["ohms"] = 1000;
            netlist.relier("R1", "1", "N_CHARGE");
            netlist.relier("R1", "2", "GND");
            auto& repos = netlist.ajouter("R2", "resistance");
            repos.valeurs["ohms"] = 1000;
            netlist.relier("R2", "1", "N_REPOS");
            netlist.relier("R2", "2", "GND");
            moteur.construire(
                netlist,
                {{"D7", coeur::BrocheElectrique::Mode::Sortie, commande, 25.0}});
            moteur.resoudre();
            return std::make_pair(moteur.tension("N_CHARGE"),
                                  moteur.tension("N_REPOS"));
        };
        const auto au_repos = tension_contact(0.0);
        const auto excite = tension_contact(5.0);
        verifier(au_repos.second > 4.5 && au_repos.first < 0.5,
                 "relais au repos : le contact NC conduit, le NO est ouvert",
                 "NO=" + f(au_repos.first) + " V, NC=" + f(au_repos.second) + " V");
        verifier(excite.first > 4.5 && excite.second < 0.5,
                 "relais excité : le contact NO conduit, le NC s'ouvre",
                 "NO=" + f(excite.first) + " V, NC=" + f(excite.second) + " V");
    }
}

// ---------------------------------------------------------------------------
// Analyse transitoire : ce qui rend l'oscilloscope possible. On ne vérifie pas
// seulement qu'une courbe sort, mais qu'elle a la bonne forme et les bonnes
// valeurs — comparées à la théorie du circuit RC.
static void test_transitoire() {
    std::printf("\n[9] Analyse transitoire (formes d'onde)\n");

    // Filtre RC : 10 kΩ + 100 nF, constante de temps 1 ms.
    coeur::Netlist netlist;
    auto& r = netlist.ajouter("R1", "resistance");
    r.valeurs["ohms"] = 10000;
    netlist.relier("R1", "1", "D3");
    netlist.relier("R1", "2", "NS");
    auto& c = netlist.ajouter("C1", "condensateur");
    c.valeurs["farads"] = 100e-9;
    netlist.relier("C1", "1", "NS");
    netlist.relier("C1", "2", "GND");

    coeur::NgspiceEngine moteur;
    std::vector<coeur::BrocheElectrique> broches = {
        {"D3", coeur::BrocheElectrique::Mode::Sortie, 0.0, 25.0}};

    // Échelon à t = 0 : le condensateur se charge pendant 5 ms.
    std::vector<coeur::TransitionBroche> transitions = {{0.0, "D3", 5.0}};
    moteur.oublier_etat();
    moteur.definir_etat_initial({{"ns", 0.0}});
    moteur.construire_transitoire(netlist, broches, transitions, 5e-3, 10e-6);
    const bool ok = moteur.resoudre_transitoire();
    verifier(ok, "l'analyse transitoire aboutit",
             moteur.erreurs().empty() ? "" : moteur.erreurs().front());
    if (!ok) return;

    const coeur::Formes& formes = moteur.formes();
    verifier(formes.temps.size() > 100, "la forme d'onde contient assez de points",
             std::to_string(formes.temps.size()) + " points");
    verifier(presque(formes.temps.back(), 5e-3, 1e-4),
             "la fenêtre couvre bien la durée demandée",
             f(formes.temps.back() * 1000, 3) + " ms");

    // Relève la tension à un instant donné, par recherche dans la courbe.
    auto tension_a = [&formes](double instant) {
        auto it = formes.tensions.find("ns");
        if (it == formes.tensions.end()) return -1.0;
        for (size_t k = 0; k < formes.temps.size(); ++k)
            if (formes.temps[k] >= instant) return it->second[k];
        return it->second.back();
    };

    // Charge d'un RC : v(t) = V·(1 − e^(−t/τ)), avec τ = RC = 1 ms.
    const double a_1tau = tension_a(1e-3);      // attendu 5·(1−e⁻¹) = 3,161 V
    const double a_3tau = tension_a(3e-3);      // attendu 5·(1−e⁻³) = 4,751 V
    verifier(presque(a_1tau, 3.16, 0.15),
             "charge du RC à une constante de temps (théorie : 3,16 V)",
             f(a_1tau) + " V");
    verifier(presque(a_3tau, 4.75, 0.15),
             "charge du RC à trois constantes de temps (théorie : 4,75 V)",
             f(a_3tau) + " V");
    verifier(tension_a(0.0) < 0.2, "la courbe part bien de zéro",
             f(tension_a(0.0)) + " V");

    // L'état final doit permettre d'enchaîner la fenêtre suivante sans que le
    // condensateur ne se redécharge tout seul.
    const double final_1 = moteur.etat_final().at("ns");
    moteur.definir_etat_initial(moteur.etat_final());
    moteur.construire_transitoire(netlist, broches, {}, 1e-3, 10e-6);
    moteur.resoudre_transitoire();
    const double debut_2 = moteur.formes().tensions.at("ns").front();
    verifier(presque(debut_2, final_1, 0.05),
             "l'état se transmet d'une fenêtre à la suivante",
             "fin " + f(final_1) + " V -> début " + f(debut_2) + " V");

    // --- PWM : c'est le cas qui piège une moyenne naïve des tensions.
    // Rapport cyclique 25 % à 1 kHz sur une LED : elle doit conduire pendant
    // le quart du temps, pas rester éteinte sous une tension moyenne.
    coeur::Netlist circuit_led;
    auto& led = circuit_led.ajouter("LED1", "led");
    led.textes["couleur"] = "rouge";
    circuit_led.relier("LED1", "A", "D5");
    circuit_led.relier("LED1", "K", "NL");
    auto& rs = circuit_led.ajouter("R1", "resistance");
    rs.valeurs["ohms"] = 220;
    circuit_led.relier("R1", "1", "NL");
    circuit_led.relier("R1", "2", "GND");

    std::vector<coeur::TransitionBroche> pwm;
    for (int periode = 0; periode < 20; ++periode) {       // 20 ms à 1 kHz
        const double t0 = periode * 1e-3;
        pwm.push_back({t0, "D5", 5.0});
        pwm.push_back({t0 + 0.25e-3, "D5", 0.0});          // 25 % de rapport
    }
    coeur::NgspiceEngine moteur_pwm;
    moteur_pwm.oublier_etat();
    moteur_pwm.construire_transitoire(
        circuit_led, {{"D5", coeur::BrocheElectrique::Mode::Sortie, 0.0, 25.0}},
        pwm, 20e-3, 10e-6);
    verifier(moteur_pwm.resoudre_transitoire(), "PWM : analyse transitoire menée");

    const auto& courbe = moteur_pwm.formes();
    auto it = courbe.courants.find("led1");
    verifier(it != courbe.courants.end(), "PWM : le courant de la LED est relevé");
    if (it == courbe.courants.end()) return;

    double maximum = 0, somme = 0;
    int au_dessus = 0;
    for (double valeur : it->second) {
        const double courant = std::fabs(valeur);
        maximum = std::max(maximum, courant);
        somme += courant;
        if (courant > 0.005) ++au_dessus;
    }
    const double moyenne = somme / it->second.size();
    const double proportion =
        static_cast<double>(au_dessus) / it->second.size();

    verifier(maximum > 0.010,
             "PWM : la LED reçoit bien le plein courant pendant l'impulsion",
             f(maximum * 1000, 1) + " mA de crête");
    verifier(presque(proportion, 0.25, 0.08),
             "PWM : elle conduit environ un quart du temps",
             f(proportion * 100, 0) + " % du temps");
    verifier(moyenne > 0.002 && moyenne < 0.006,
             "PWM : le courant moyen vaut environ le quart du courant de crête",
             f(moyenne * 1000, 2) + " mA");
}

// ---------------------------------------------------------------------------
// Exemplaires multiples : que se passe-t-il si on pose cinq fois le même
// composant ? Chaque modèle génère des noms d'éléments et des nœuds internes ;
// s'ils ne dérivent pas de la référence, deux exemplaires se marchent dessus
// et SPICE refuse le circuit — ou pire, l'accepte en les confondant.
static std::vector<std::string> noms_dupliques(const std::string& source) {
    std::vector<std::string> vus, doubles;
    std::istringstream flux(source);
    std::string ligne;
    while (std::getline(flux, ligne)) {
        if (ligne.empty()) continue;
        const char premier = ligne[0];
        // Seules les lignes d'éléments comptent : pas les directives, pas le
        // titre du circuit.
        if (!std::isalpha(static_cast<unsigned char>(premier))) continue;
        std::string nom = ligne.substr(0, ligne.find(' '));
        std::transform(nom.begin(), nom.end(), nom.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        if (std::find(vus.begin(), vus.end(), nom) != vus.end())
            doubles.push_back(nom);
        else
            vus.push_back(nom);
    }
    return doubles;
}

static void test_exemplaires_multiples() {
    std::printf("\n[10] Cinq exemplaires de chaque composant\n");
    constexpr int kExemplaires = 5;
    int examines = 0, refuses = 0, collisions = 0;
    std::string liste_refuses, liste_collisions;

    for (const coeur::Modele* modele : coeur::Catalogue::instance().tous()) {
        if (!modele->vers_spice || modele->bornes.empty()) continue;
        ++examines;

        coeur::Netlist netlist;
        // Chaîne de cinq exemplaires : la sortie de l'un alimente l'entrée du
        // suivant, ce qui les met vraiment en relation au lieu de les poser
        // côte à côte sans interaction. Les générateurs font exception : les
        // mettre en série reviendrait à opposer cinq sources, un montage que
        // SPICE refuse à juste titre et qui ne dit rien du modèle.
        const bool en_chaine = !modele->generateur;
        std::string amont = "D13";
        for (int n = 1; n <= kExemplaires; ++n) {
            const std::string reference = modele->prefixe + std::to_string(n);
            auto& instance = netlist.ajouter(reference, modele->type);
            for (const auto& propriete : modele->proprietes) {
                if (propriete.genre == coeur::Propriete::Genre::Choix)
                    instance.textes[propriete.cle] = propriete.defaut_texte;
                else
                    instance.valeurs[propriete.cle] = propriete.defaut;
            }
            const int dernier = static_cast<int>(modele->bornes.size()) - 1;
            const std::string aval =
                !en_chaine ? ("FIN" + std::to_string(n))
                           : (n == kExemplaires ? std::string("FIN")
                                                : ("M" + std::to_string(n)));
            for (int k = 0; k <= dernier; ++k) {
                const std::string& borne = modele->bornes[k].nom;
                if (k == 0)
                    netlist.relier(reference, borne,
                                   en_chaine ? amont : ("G" + std::to_string(n)));
                else if (k == dernier)
                    netlist.relier(reference, borne, aval);
                else {
                    const std::string noeud =
                        "T" + std::to_string(n) + "_" + std::to_string(k);
                    netlist.relier(reference, borne, noeud);
                    auto& charge = netlist.ajouter(
                        "RC" + std::to_string(n) + "_" + std::to_string(k),
                        "resistance");
                    charge.valeurs["ohms"] = 1000;
                    netlist.relier(charge.reference, "1", noeud);
                    netlist.relier(charge.reference, "2", "GND");
                }
            }
            if (!en_chaine) {
                // Chaque générateur débite dans sa propre charge.
                auto& charge = netlist.ajouter("RG" + std::to_string(n),
                                               "resistance");
                charge.valeurs["ohms"] = 1000;
                netlist.relier(charge.reference, "1", "G" + std::to_string(n));
                netlist.relier(charge.reference, "2", "FIN" + std::to_string(n));
                auto& retour = netlist.ajouter("RR" + std::to_string(n),
                                               "resistance");
                retour.valeurs["ohms"] = 1000;
                netlist.relier(retour.reference, "1", "FIN" + std::to_string(n));
                netlist.relier(retour.reference, "2", "GND");
            }
            amont = aval;
        }
        {   // retour à la masse par une charge, jamais en direct
            auto& retour = netlist.ajouter("RFIN", "resistance");
            retour.valeurs["ohms"] = 1000;
            netlist.relier("RFIN", "1", "FIN");
            netlist.relier("RFIN", "2", "GND");
        }

        coeur::NgspiceEngine moteur;
        const std::string source = moteur.construire(
            netlist,
            {{"D13", coeur::BrocheElectrique::Mode::Sortie, 5.0, 25.0}});

        const std::vector<std::string> doubles = noms_dupliques(source);
        if (!doubles.empty()) {
            ++collisions;
            liste_collisions += " " + modele->type + "(" + doubles.front() + ")";
        }
        if (!moteur.resoudre() || !moteur.erreurs().empty()) {
            ++refuses;
            liste_refuses += " " + modele->type;
        }
    }

    verifier(examines >= 25, "tous les modèles simulables ont été mis en série",
             std::to_string(examines) + " modèles × 5 exemplaires");
    verifier(collisions == 0,
             "aucun nom d'élément SPICE en double entre exemplaires",
             collisions ? ("collisions :" + liste_collisions) : "");
    verifier(refuses == 0, "ngspice accepte les cinq exemplaires de chaque modèle",
             refuses ? ("refusés :" + liste_refuses) : "");

    // --- cas concret : dix LED en parallèle sur la même sortie
    //
    // C'est l'erreur classique du débutant, et le simulateur doit la montrer :
    // la sortie ne peut pas fournir dix fois 12 mA, la tension s'effondre.
    coeur::Netlist grappe;
    for (int n = 1; n <= 10; ++n) {
        auto& led = grappe.ajouter("LED" + std::to_string(n), "led");
        led.textes["couleur"] = "rouge";
        grappe.relier(led.reference, "A", "D13");
        grappe.relier(led.reference, "K", "N" + std::to_string(n));
        auto& r = grappe.ajouter("R" + std::to_string(n), "resistance");
        r.valeurs["ohms"] = 220;
        grappe.relier(r.reference, "1", "N" + std::to_string(n));
        grappe.relier(r.reference, "2", "GND");
    }
    coeur::NgspiceEngine dix;
    dix.construire(grappe,
                   {{"D13", coeur::BrocheElectrique::Mode::Sortie, 5.0, 25.0}});
    verifier(dix.resoudre(), "dix LED en parallèle : le circuit est résolu");

    double total = 0;
    int distinctes = 0;
    for (int n = 1; n <= 10; ++n) {
        const double courant = std::fabs(dix.courant("LED" + std::to_string(n)));
        total += courant;
        if (courant > 1e-6) ++distinctes;
    }
    verifier(distinctes == 10,
             "les dix LED sont bien dix composants distincts, tous parcourus",
             std::to_string(distinctes) + " LED alimentées");
    verifier(total > 0.030,
             "le courant total est celui des dix branches réunies",
             f(total * 1000, 1) + " mA au total");
    verifier(dix.tension("D13") < 4.5,
             "la sortie s'effondre sous la charge — le défaut est visible",
             f(dix.tension("D13")) + " V au lieu de 4,68 V pour une seule LED");
}

// ---------------------------------------------------------------------------
// Un vrai croquis Arduino, tel qu'on l'écrit en TP : setup/loop, millis sans
// delay, machine à états, bouton avec anti-rebond, potentiomètre, PWM et
// liaison série. C'est le sujet de l'épreuve pratique Arduino de la
// formation. S'il tourne ici, l'épreuve se passe dans le simulateur.
static const char* kCroquisTp = R"(
/* Minuterie d'éclairage.
   Bouton D2 (pull-up) : allume pour 3 s. Luminosité réglée par A0.
   LED éclairage sur D9 (PWM), LED témoin sur D8. Aucun delay(). */
enum Etat { REPOS, ALLUME };

Etat etat = REPOS;
unsigned long debut = 0, dernier_rebond = 0, dernier_message = 0;
int precedent = HIGH;

void setup() {
    pinMode(2, INPUT_PULLUP);
    pinMode(8, OUTPUT);
    pinMode(9, OUTPUT);
    Serial.begin(9600);
    Serial.println("pret");
}

void loop() {
    const unsigned long maintenant = millis();

    /* anti-rebond 20 ms sur le front descendant */
    const int lu = digitalRead(2);
    if (lu != precedent && maintenant - dernier_rebond > 20) {
        dernier_rebond = maintenant;
        if (lu == LOW) {
            etat = ALLUME;
            debut = maintenant;
            Serial.println("appui");
        }
        precedent = lu;
    }

    switch (etat) {
        case ALLUME:
            if (maintenant - debut >= 3000) {
                etat = REPOS;
                Serial.println("extinction");
            } else {
                analogWrite(9, map(analogRead(A0), 0, 1023, 0, 255));
                digitalWrite(8, HIGH);
            }
            break;
        case REPOS:
            analogWrite(9, 0);
            digitalWrite(8, LOW);
            break;
    }

    if (maintenant - dernier_message >= 1000) {
        dernier_message = maintenant;
        Serial.print("t=");
        Serial.println((long)(maintenant / 1000));
    }
}
)";

static void test_croquis_arduino() {
    std::printf("\n[11] Un croquis Arduino de TP, tel quel\n");
    if (!coeur::AvrEngine::avr_gpp_disponible()) {
        std::printf("  (avr-g++ absent — section ignorée)\n");
        return;
    }

    const std::string firmware = "/tmp/sim_croquis.elf";
    std::string journal;
    const bool compile =
        coeur::AvrEngine::compiler_source(kCroquisTp, firmware, &journal);
    verifier(compile, "le croquis compile sans être réécrit", journal);
    if (!compile) return;

    coeur::AvrEngine mcu;
    if (!mcu.charger(firmware)) {
        verifier(false, "chargement du croquis", mcu.erreur());
        return;
    }

    std::string serie;
    mcu.sur_octet_serie([&serie](char octet) { serie += octet; });

    // --- au repos : D8 éteinte, et l'horloge doit tourner
    mcu.definir_niveau_externe(2, true);          // bouton relâché
    mcu.definir_tension_adc(0, 2.5);              // potentiomètre à mi-course
    mcu.avancer(16000000ull * 2);                 // 2 secondes simulées

    verifier(serie.find("pret") != std::string::npos,
             "setup() s'exécute et Serial fonctionne",
             "reçu : " + serie.substr(0, 20));
    verifier(mcu.direction_sortie(8) && mcu.direction_sortie(9),
             "pinMode(OUTPUT) configure bien les broches");
    verifier(mcu.pullup_actif(2), "pinMode(INPUT_PULLUP) arme le pull-up");
    verifier(!mcu.niveau_port(8), "au repos, la LED témoin est éteinte");

    // millis() doit avancer à la bonne vitesse : le programme émet « t=1 »
    // puis « t=2 ». Une horloge fausse de quelques pour cent se verrait.
    verifier(serie.find("t=1") != std::string::npos,
             "millis() avance à la bonne cadence",
             "reçu : " + serie.substr(0, 40));

    // --- appui : la minuterie démarre
    serie.clear();
    mcu.definir_niveau_externe(2, false);         // bouton appuyé
    mcu.avancer(16000000ull / 10);                // 100 ms
    verifier(serie.find("appui") != std::string::npos,
             "l'anti-rebond laisse passer l'appui", "reçu : " + serie);
    verifier(mcu.niveau_port(8),
             "la machine à états passe en ALLUME et allume le témoin");

    // --- PWM : la luminosité suit le potentiomètre
    mcu.definir_niveau_externe(2, true);
    int fronts_d9 = 0;
    mcu.sur_changement_broche([&fronts_d9](int broche, bool) {
        if (broche == 9) ++fronts_d9;
    });
    mcu.avancer(16000000ull / 20);                // 50 ms
    verifier(fronts_d9 > 20,
             "analogWrite produit une vraie PWM sur D9",
             std::to_string(fronts_d9) + " fronts en 50 ms");

    // --- la minuterie s'arrête d'elle-même au bout de trois secondes
    serie.clear();
    mcu.avancer(16000000ull * 4);
    verifier(serie.find("extinction") != std::string::npos,
             "la minuterie de 3 s expire toute seule", "reçu : " + serie);
    verifier(!mcu.niveau_port(8), "et le témoin s'éteint");
}

// ---------------------------------------------------------------------------
// Composants à état : un servomoteur, un moteur, un codeur ne se jugent pas
// sur leur impédance mais sur leur mécanique. On les alimente et on regarde
// où ils en sont.
//
// Le circuit n'est pas résolu ici : on éprouve directement le crochet
// `evoluer`, en lui fournissant les formes d'onde qu'il aurait reçues. Cela
// isole la mécanique de la convergence de SPICE.
static coeur::Evolution fenetre_avec(
    const std::map<std::string, std::vector<double>>& courbes,
    const std::vector<double>& temps, double duree) {
    coeur::Evolution evolution;
    evolution.duree = duree;
    evolution.temps = &temps;
    evolution.tension = [&courbes](const std::string& borne)
        -> const std::vector<double>* {
        auto it = courbes.find(borne);
        return it == courbes.end() ? nullptr : &it->second;
    };
    return evolution;
}

// Fabrique un créneau : `largeur` secondes à 5 V, répété toutes les
// `periode`, échantillonné sur `duree`.
static std::pair<std::vector<double>, std::vector<double>> creneau(
    double largeur, double periode, double duree, double pas = 20e-6) {
    std::vector<double> temps, valeurs;
    // Le créneau démarre après un court palier bas : une impulsion qui
    // commencerait à l'instant zéro serait incomplète, et une mesure de
    // largeur sur une impulsion tronquée n'aurait pas de sens.
    const double retard = periode / 4;
    for (double t = 0; t <= duree; t += pas) {
        temps.push_back(t);
        const double phase = t < retard ? -1.0 : std::fmod(t - retard, periode);
        valeurs.push_back(phase >= 0 && phase < largeur ? 5.0 : 0.0);
    }
    return {temps, valeurs};
}

static void test_composants_a_etat() {
    std::printf("\n[12] Composants à mécanique interne\n");
    const coeur::Catalogue& catalogue = coeur::Catalogue::instance();

    // --- servomoteur : une impulsion de 1,5 ms doit donner 90°
    {
        const coeur::Modele* modele = catalogue.modele("servomoteur");
        verifier(modele && modele->evoluer, "le servomoteur a une mécanique");
        if (!modele || !modele->evoluer) return;

        coeur::Netlist netlist;
        auto& servo = netlist.ajouter("SRV1", "servomoteur");
        servo.valeurs["angle"] = 0;
        servo.valeurs["vitesse"] = 100000;      // instantané, pour ce test

        auto [temps, valeurs] = creneau(1.5e-3, 20e-3, 60e-3);
        std::map<std::string, std::vector<double>> courbes{{"SIG", valeurs}};
        modele->evoluer(servo, fenetre_avec(courbes, temps, 60e-3));
        verifier(presque(servo.valeur("angle", -1), 90, 2),
                 "impulsion de 1,5 ms -> 90°",
                 f(servo.valeur("angle", -1), 1) + " °");

        auto [t2, v2] = creneau(1.0e-3, 20e-3, 60e-3);
        courbes["SIG"] = v2;
        modele->evoluer(servo, fenetre_avec(courbes, t2, 60e-3));
        verifier(presque(servo.valeur("angle", -1), 0, 2),
                 "impulsion de 1 ms -> 0°", f(servo.valeur("angle", -1), 1) + " °");

        auto [t3, v3] = creneau(2.0e-3, 20e-3, 60e-3);
        courbes["SIG"] = v3;
        modele->evoluer(servo, fenetre_avec(courbes, t3, 60e-3));
        verifier(presque(servo.valeur("angle", -1), 180, 2),
                 "impulsion de 2 ms -> 180°",
                 f(servo.valeur("angle", -1), 1) + " °");

        // La vitesse est bornée : le palonnier ne se téléporte pas.
        servo.valeurs["angle"] = 0;
        servo.valeurs["vitesse"] = 60;          // 60 °/s
        courbes["SIG"] = v3;                    // consigne 180°
        modele->evoluer(servo, fenetre_avec(courbes, t3, 0.1));   // 100 ms
        verifier(presque(servo.valeur("angle", -1), 6, 1),
                 "le palonnier tourne à vitesse bornée, il ne saute pas",
                 f(servo.valeur("angle", -1), 1) + " ° après 100 ms à 60 °/s");
    }

    // --- moteur à courant continu : montée en vitesse avec inertie
    {
        const coeur::Modele* modele = catalogue.modele("moteur_cc_dynamique");
        coeur::Netlist netlist;
        auto& moteur = netlist.ajouter("M1", "moteur_cc_dynamique");
        moteur.valeurs["k"] = 900;              // tr/min pour 12 V
        moteur.valeurs["inertie"] = 0.25;

        std::vector<double> temps{0, 0.05}, hautes{12, 12}, basses{0, 0};
        std::map<std::string, std::vector<double>> courbes{{"+", hautes},
                                                           {"-", basses}};
        // Après une constante de temps, on doit être à 63 % du régime.
        for (int k = 0; k < 5; ++k)                       // 5 x 50 ms = 250 ms
            modele->evoluer(moteur, fenetre_avec(courbes, temps, 0.05));
        const double apres_tau = moteur.valeur("tr_min", 0);
        verifier(presque(apres_tau, 900 * 0.632, 40),
                 "moteur CC : 63 % du régime après une constante de temps",
                 f(apres_tau, 0) + " tr/min (théorie : 569)");

        for (int k = 0; k < 40; ++k)
            modele->evoluer(moteur, fenetre_avec(courbes, temps, 0.05));
        verifier(presque(moteur.valeur("tr_min", 0), 900, 20),
                 "et il atteint son régime établi",
                 f(moteur.valeur("tr_min", 0), 0) + " tr/min");

        // Coupure : il ralentit, il ne s'arrête pas net.
        courbes["+"] = basses;
        modele->evoluer(moteur, fenetre_avec(courbes, temps, 0.05));
        const double apres_coupure = moteur.valeur("tr_min", 0);
        verifier(apres_coupure > 100 && apres_coupure < 900,
                 "à la coupure il ralentit par inertie, sans s'arrêter net",
                 f(apres_coupure, 0) + " tr/min");
    }

    // --- l'inductance d'induit : le courant ne s'établit pas d'un coup
    {
        coeur::Netlist netlist;
        auto& moteur = netlist.ajouter("M1", "moteur_cc_dynamique");
        moteur.valeurs["resistance"] = 8;
        moteur.valeurs["inductance"] = 5e-3;      // tau = L/R = 0,625 ms
        moteur.valeurs["tr_min"] = 0;             // rotor bloqué : pas de fcem
        netlist.relier("M1", "+", "D9");
        netlist.relier("M1", "-", "GND");

        coeur::NgspiceEngine analogique;
        analogique.oublier_etat();
        // Échelon franc à 1 ms : la broche part de 0 V. Sans cela ngspice
        // calculerait d'abord le point de repos — où une bobine est un simple
        // court-circuit — et le courant serait déjà établi à l'instant zéro.
        const double instant_fermeture = 1e-3;
        analogique.construire_transitoire(
            netlist, {{"D9", coeur::BrocheElectrique::Mode::Sortie, 0.0, 0.1}},
            {{instant_fermeture, "D9", 12.0}}, 6e-3, 5e-6);
        const bool resolu = analogique.resoudre_transitoire();
        verifier(resolu, "moteur avec inductance : le transitoire est calculé");

        if (resolu) {
            const coeur::Formes& formes = analogique.formes();
            auto it = formes.courants.find("m1");
            verifier(it != formes.courants.end(),
                     "le courant d'induit est relevé");
            if (it != formes.courants.end()) {
                auto courant_a = [&](double instant) {
                    for (size_t k = 0; k < formes.temps.size(); ++k)
                        if (formes.temps[k] >= instant)
                            return std::fabs(it->second[k]);
                    return std::fabs(it->second.back());
                };
                // Établissement en L/R : i(t) = I∞ (1 − e^(−t/τ)), I∞ = 12/8.
                const double a_tau = courant_a(instant_fermeture + 0.625e-3);
                const double etabli = courant_a(5e-3);
                verifier(presque(etabli, 1.5, 0.1),
                         "régime établi : I = U / R = 1,5 A",
                         f(etabli, 3) + " A");
                verifier(presque(a_tau, 1.5 * 0.632, 0.15),
                         "à une constante de temps L/R : 63 % du courant final",
                         f(a_tau, 3) + " A (théorie : 0,948)");
                verifier(courant_a(instant_fermeture) < 0.2,
                         "à l'instant de la fermeture, le courant est encore nul",
                         f(courant_a(instant_fermeture), 3) + " A");
                // Sans inductance, le courant serait immédiat : c'est la
                // différence que doit faire le paramètre.
                verifier(courant_a(instant_fermeture + 2e-3) >
                             courant_a(instant_fermeture + 0.2e-3) * 1.5,
                         "le courant monte progressivement, il ne saute pas",
                         f(courant_a(instant_fermeture + 0.2e-3), 3) + " A puis " +
                             f(courant_a(instant_fermeture + 2e-3), 3) + " A");
            }
        }
    }

    // --- moteur asynchrone : vitesse de synchronisme et glissement
    {
        const coeur::Modele* modele = catalogue.modele("moteur_asynchrone");
        coeur::Netlist netlist;
        auto& mas = netlist.ajouter("MAS1", "moteur_asynchrone");
        mas.valeurs["poles"] = 2;               // 2 paires -> Ns = 1500 tr/min
        mas.valeurs["frequence"] = 50;
        mas.valeurs["glissement"] = 4;
        mas.valeurs["demarrage"] = 0.5;

        std::vector<double> temps{0, 0.05}, phase{230, 230}, zero{0, 0};
        std::map<std::string, std::vector<double>> courbes{
            {"U", phase}, {"V", phase}, {"W", phase}};
        for (int k = 0; k < 60; ++k)            // 3 secondes
            modele->evoluer(mas, fenetre_avec(courbes, temps, 0.05));

        verifier(presque(mas.valeur("synchrone", 0), 1500, 1),
                 "synchronisme : Ns = 60 f / p = 1500 tr/min",
                 f(mas.valeur("synchrone", 0), 0) + " tr/min");
        verifier(presque(mas.valeur("tr_min", 0), 1440, 15),
                 "en charge, il tourne 4 % sous le synchronisme",
                 f(mas.valeur("tr_min", 0), 0) + " tr/min (attendu 1440)");

        // À 25 Hz — un variateur de vitesse — le synchronisme est divisé par 2.
        mas.valeurs["frequence"] = 25;
        for (int k = 0; k < 60; ++k)
            modele->evoluer(mas, fenetre_avec(courbes, temps, 0.05));
        verifier(presque(mas.valeur("tr_min", 0), 720, 15),
                 "à 25 Hz (variateur), la vitesse est divisée par deux",
                 f(mas.valeur("tr_min", 0), 0) + " tr/min");

        // Hors tension, il s'arrête.
        courbes["U"] = zero; courbes["V"] = zero; courbes["W"] = zero;
        for (int k = 0; k < 100; ++k)
            modele->evoluer(mas, fenetre_avec(courbes, temps, 0.05));
        verifier(mas.valeur("tr_min", 0) < 20, "hors tension, il s'arrête",
                 f(mas.valeur("tr_min", 0), 1) + " tr/min");
    }

    // --- accéléromètre : la pesanteur doit se lire sur Z au repos
    {
        coeur::Netlist netlist;
        auto& acc = netlist.ajouter("ACC1", "accelerometre");
        acc.valeurs["ax"] = 0;
        acc.valeurs["ay"] = 0;
        acc.valeurs["az"] = 1;                  // au repos, 1 g vers le haut
        netlist.relier("ACC1", "V+", "5V");
        netlist.relier("ACC1", "GND", "GND");
        netlist.relier("ACC1", "X", "NX");
        netlist.relier("ACC1", "Y", "NY");
        netlist.relier("ACC1", "Z", "NZ");

        coeur::NgspiceEngine moteur;
        moteur.construire(netlist, {});
        verifier(moteur.resoudre(), "accéléromètre : le circuit est résolu");
        verifier(presque(moteur.tension("NX"), 1.65, 0.05),
                 "axe X au repos : mi-alimentation (1,65 V)",
                 f(moteur.tension("NX")) + " V");
        verifier(presque(moteur.tension("NZ"), 1.98, 0.05),
                 "axe Z : 1,65 V + 1 g × 0,33 V/g = 1,98 V — la pesanteur",
                 f(moteur.tension("NZ")) + " V");

        acc.valeurs["ax"] = -2;
        moteur.construire(netlist, {});
        moteur.resoudre();
        verifier(presque(moteur.tension("NX"), 0.99, 0.05),
                 "−2 g sur X : 1,65 − 0,66 = 0,99 V",
                 f(moteur.tension("NX")) + " V");
    }

    // --- télémètre à ultrasons : la largeur d'écho est la distance
    {
        const coeur::Modele* modele = catalogue.modele("telemetre_ultrason");
        verifier(modele && modele->vers_spice_transitoire,
                 "le télémètre produit un signal daté");

        coeur::Netlist netlist;
        auto& us = netlist.ajouter("US1", "telemetre_ultrason");
        us.valeurs["distance"] = 100;           // 1 m -> écho de 5,8 ms
        netlist.relier("US1", "V+", "5V");
        netlist.relier("US1", "GND", "GND");
        netlist.relier("US1", "TRIG", "D7");
        netlist.relier("US1", "ECHO", "D6");

        // Impulsion de déclenchement de 10 µs sur TRIG.
        auto [temps, valeurs] = creneau(10e-6, 30e-3, 30e-3, 2e-6);
        std::map<std::string, std::vector<double>> courbes{{"TRIG", valeurs}};
        modele->evoluer(us, fenetre_avec(courbes, temps, 30e-3));
        verifier(us.valeur("_echo_debut", -1) >= 0,
                 "une impulsion de 10 µs sur TRIG arme l'écho");

        coeur::NgspiceEngine moteur;
        moteur.construire_transitoire(
            netlist, {{"D7", coeur::BrocheElectrique::Mode::Entree, 0, 0},
                      {"D6", coeur::BrocheElectrique::Mode::Entree, 0, 0}},
            {}, 20e-3, 50e-6);
        verifier(moteur.resoudre_transitoire(),
                 "le circuit avec écho est résolu");

        // Mesure de la largeur d'impulsion sur ECHO, comme le ferait pulseIn.
        const auto& formes = moteur.formes();
        auto it = formes.tensions.find("d6");
        double largeur = 0;
        if (it != formes.tensions.end()) {
            double debut = -1;
            for (size_t k = 1; k < formes.temps.size(); ++k) {
                const bool haut = it->second[k] > 2.5;
                const bool avant = it->second[k - 1] > 2.5;
                if (!avant && haut) debut = formes.temps[k];
                if (avant && !haut && debut >= 0) {
                    largeur = formes.temps[k] - debut;
                    break;
                }
            }
        }
        verifier(presque(largeur, 5.8e-3, 0.3e-3),
                 "1 m -> écho de 5,8 ms (58 µs par centimètre)",
                 f(largeur * 1000, 2) + " ms");
    }

    // --- codeur incrémental : la fréquence des voies suit la vitesse
    {
        coeur::Netlist netlist;
        auto& cod = netlist.ajouter("COD1", "codeur_incremental");
        cod.valeurs["tr_min"] = 300;            // 300 tr/min
        cod.valeurs["impulsions"] = 20;         // -> 100 Hz
        netlist.relier("COD1", "V+", "5V");
        netlist.relier("COD1", "GND", "GND");
        netlist.relier("COD1", "A", "NA");
        netlist.relier("COD1", "B", "NB");

        coeur::NgspiceEngine moteur;
        moteur.construire_transitoire(netlist, {}, {}, 50e-3, 100e-6);
        verifier(moteur.resoudre_transitoire(), "codeur : le circuit est résolu");

        const auto& formes = moteur.formes();
        auto it = formes.tensions.find("na");
        int fronts = 0;
        if (it != formes.tensions.end())
            for (size_t k = 1; k < it->second.size(); ++k)
                if (it->second[k - 1] <= 2.5 && it->second[k] > 2.5) ++fronts;
        verifier(fronts >= 4 && fronts <= 6,
                 "300 tr/min × 20 impulsions = 100 Hz, soit 5 fronts en 50 ms",
                 std::to_string(fronts) + " fronts montants");
    }

    // --- tout le nouveau catalogue passe dans ngspice
    {
        const char* nouveaux[] = {
            "servomoteur", "moteur_cc_dynamique", "moteur_pas_a_pas",
            "moteur_asynchrone", "alim_triphasee", "accelerometre",
            "telemetre_ultrason", "codeur_incremental", "capteur_courant",
            "capteur_gaz", "capteur_humidite_sol", "capteur_lumiere",
            "capteur_pression", "capteur_ph"};
        int refuses = 0;
        std::string liste;
        for (const char* type : nouveaux) {
            const coeur::Modele* modele = catalogue.modele(type);
            if (!modele || !modele->vers_spice) {
                ++refuses;
                liste += std::string(" ") + type + "(absent)";
                continue;
            }
            coeur::Netlist netlist;
            auto& instance = netlist.ajouter("X1", type);
            for (const auto& propriete : modele->proprietes) {
                if (propriete.genre == coeur::Propriete::Genre::Choix)
                    instance.textes[propriete.cle] = propriete.defaut_texte;
                else
                    instance.valeurs[propriete.cle] = propriete.defaut;
            }
            const int dernier = static_cast<int>(modele->bornes.size()) - 1;
            for (int k = 0; k <= dernier; ++k) {
                const std::string& borne = modele->bornes[k].nom;
                netlist.relier("X1", borne,
                               k == 0 ? "D13"
                                      : (k == dernier ? "FIN"
                                                      : "T" + std::to_string(k)));
                if (k != 0 && k != dernier) {
                    auto& charge =
                        netlist.ajouter("RT" + std::to_string(k), "resistance");
                    charge.valeurs["ohms"] = 10000;
                    netlist.relier(charge.reference, "1", "T" + std::to_string(k));
                    netlist.relier(charge.reference, "2", "GND");
                }
            }
            {
                auto& retour = netlist.ajouter("RFIN", "resistance");
                retour.valeurs["ohms"] = 1000;
                netlist.relier("RFIN", "1", "FIN");
                netlist.relier("RFIN", "2", "GND");
            }
            coeur::NgspiceEngine moteur;
            moteur.construire(
                netlist,
                {{"D13", coeur::BrocheElectrique::Mode::Sortie, 5.0, 25.0}});
            if (!moteur.resoudre() || !moteur.erreurs().empty()) {
                ++refuses;
                liste += std::string(" ") + type;
            }
        }
        verifier(refuses == 0, "les 14 nouveaux modèles sont acceptés par ngspice",
                 refuses ? ("refusés :" + liste) : "");
    }
}

// ---------------------------------------------------------------------------
// [13] Mesures, spectre et distorsion. Ces calculs sont vérifiés contre des
// signaux dont la théorie donne le résultat exact : une sinusoïde n'a pas
// d'harmoniques, un carré parfait a un taux de distorsion de 48,3 %, son
// harmonique 3 vaut le tiers du fondamental. Aucun besoin de ngspice.
// ---------------------------------------------------------------------------
static void test_analyses() {
    std::printf("\n[13] Mesures, spectre et distorsion\n");
    const double pi = 3.14159265358979323846;

    // --- sinusoïde pure : 1 kHz, 2 V crête, décalée de 1 V
    {
        std::vector<double> t, v;
        const int points = 4000;
        for (int k = 0; k < points; ++k) {
            const double instant = k * 5e-3 / points;   // 5 périodes
            t.push_back(instant);
            v.push_back(1.0 + 2.0 * std::sin(2 * pi * 1000 * instant));
        }
        const coeur::Mesures m = coeur::mesurer(t, v);
        verifier(m.valide, "mesures : signal accepté");
        verifier(presque(m.moyenne, 1.0, 0.05),
                 "mesures : composante continue", f(m.moyenne));
        verifier(presque(m.efficace, std::sqrt(1.0 + 2.0), 0.05),
                 "mesures : valeur efficace", f(m.efficace));
        verifier(presque(m.crete_a_crete, 4.0, 0.02), "mesures : crête à crête",
                 f(m.crete_a_crete));
        verifier(presque(m.frequence, 1000.0, 5.0), "mesures : fréquence",
                 f(m.frequence, 1));
        verifier(presque(m.rapport_cyclique, 50.0, 2.0),
                 "mesures : rapport cyclique d'une sinusoïde",
                 f(m.rapport_cyclique, 1));

        const coeur::Spectre s = coeur::analyser_spectre(t, v);
        verifier(s.valide, "spectre : analyse aboutie");
        verifier(presque(s.fondamentale, 1000.0, 5.0), "spectre : fondamentale",
                 f(s.fondamentale, 1));
        verifier(!s.raies.empty() && presque(s.raies[0].amplitude, 2.0, 0.05),
                 "spectre : amplitude du fondamental",
                 s.raies.empty() ? "" : f(s.raies[0].amplitude));
        verifier(presque(s.continu, 1.0, 0.02), "spectre : composante continue",
                 f(s.continu));
        verifier(s.thd < 1.0, "spectre : une sinusoïde n'a pas d'harmoniques",
                 f(s.thd, 2) + " %");
    }

    // --- carré parfait : la théorie donne A1 = 4A/pi, A3 = A1/3, THD = 48,3 %
    {
        std::vector<double> t, v;
        const int points = 20000;
        for (int k = 0; k < points; ++k) {
            const double instant = k * 10e-3 / points;   // 10 périodes de 1 ms
            t.push_back(instant);
            const double phase = std::fmod(instant, 1e-3) / 1e-3;
            v.push_back(phase < 0.5 ? 5.0 : 0.0);
        }
        const coeur::Mesures m = coeur::mesurer(t, v);
        verifier(presque(m.frequence, 1000.0, 5.0), "carré : fréquence",
                 f(m.frequence, 1));
        verifier(presque(m.rapport_cyclique, 50.0, 1.0),
                 "carré : rapport cyclique", f(m.rapport_cyclique, 1));
        verifier(presque(m.moyenne, 2.5, 0.05), "carré : valeur moyenne",
                 f(m.moyenne));

        const coeur::Spectre s = coeur::analyser_spectre(t, v, 9);
        const double attendu = 4.0 * 2.5 / pi;
        verifier(s.valide && presque(s.raies[0].amplitude, attendu, 0.05),
                 "carré : fondamental à 4A/pi",
                 s.raies.empty() ? "" : f(s.raies[0].amplitude));
        verifier(s.raies.size() > 2
                     && presque(s.raies[2].amplitude, attendu / 3.0, 0.05),
                 "carré : harmonique 3 au tiers du fondamental",
                 s.raies.size() > 2 ? f(s.raies[2].amplitude) : "");
        verifier(s.raies.size() > 1 && s.raies[1].amplitude < 0.05,
                 "carré : pas d'harmonique paire",
                 s.raies.size() > 1 ? f(s.raies[1].amplitude) : "");
        // Tronqué au rang 9, le calcul doit donner 42,88 % — c'est la valeur
        // exacte de sqrt(1/9+1/25+1/49+1/81). Ce n'est qu'en poussant les
        // rangs qu'on retrouve les 48,3 % du carré parfait : les deux
        // vérifications ensemble prouvent que rien n'est approché au hasard.
        verifier(presque(s.thd, 42.88, 0.5),
                 "carré : distorsion tronquée au rang 9", f(s.thd, 2) + " %");
        const coeur::Spectre complet = coeur::analyser_spectre(t, v, 99);
        verifier(presque(complet.thd, 48.3, 1.0),
                 "carré : distorsion de 48,3 % avec tous les rangs",
                 f(complet.thd, 2) + " %");
    }

    // --- rapport cyclique de 25 % : ce que doit lire une mesure de PWM
    {
        std::vector<double> t, v;
        const int points = 20000;
        for (int k = 0; k < points; ++k) {
            const double instant = k * 10e-3 / points;
            t.push_back(instant);
            v.push_back(std::fmod(instant, 1e-3) / 1e-3 < 0.25 ? 5.0 : 0.0);
        }
        const coeur::Mesures m = coeur::mesurer(t, v);
        verifier(presque(m.rapport_cyclique, 25.0, 1.0),
                 "PWM : rapport cyclique de 25 %", f(m.rapport_cyclique, 1));
        verifier(presque(m.moyenne, 1.25, 0.05), "PWM : valeur moyenne",
                 f(m.moyenne));
    }

    // --- gain et fréquence de coupure lus sur un diagramme de Bode théorique
    {
        coeur::Balayage bode;
        bode.logarithmique = true;
        coeur::Courbe sortie;
        sortie.nom = "out";
        for (int k = 0; k <= 60; ++k) {
            const double frequence = std::pow(10.0, 1.0 + k / 10.0);  // 10 Hz→10 MHz
            bode.abscisse.push_back(frequence);
            // passe-bas du premier ordre, coupure à 1 kHz
            const double x = frequence / 1000.0;
            sortie.valeurs.push_back(1.0 / std::sqrt(1 + x * x));
            sortie.phases.push_back(-std::atan(x) * 180 / pi);
        }
        bode.courbes.push_back(sortie);
        const double coupure = coeur::frequence_coupure(bode, bode.courbes[0]);
        verifier(presque(coupure, 1000.0, 30.0),
                 "Bode : coupure à -3 dB retrouvée", f(coupure, 1) + " Hz");
        verifier(presque(coeur::gain_maximal(bode.courbes[0]), 0.0, 0.1),
                 "Bode : gain maximal de 0 dB");
        const std::vector<double> gains =
            coeur::gain_decibels(bode.courbes[0]);
        verifier(gains.size() == bode.abscisse.size()
                     && gains.back() < -70.0,
                 "Bode : la pente descend bien de 20 dB par décade",
                 gains.empty() ? "" : f(gains.back(), 1) + " dB");
    }
}

// ---------------------------------------------------------------------------
// [14] Documents produits : nomenclature, contrôle des règles, exports.
// ---------------------------------------------------------------------------
static void test_documents() {
    std::printf("\n[14] Nomenclature, règles électriques et exports\n");

    coeur::Netlist netlist;
    auto& carte = netlist.ajouter("U1", "arduino_uno");
    (void)carte;
    netlist.relier("U1", "D13", "N1");
    netlist.relier("U1", "GND", "GND");
    auto& r1 = netlist.ajouter("R1", "resistance");
    r1.valeurs["ohms"] = 220;
    netlist.relier("R1", "1", "N1");
    netlist.relier("R1", "2", "N2");
    auto& r2 = netlist.ajouter("R2", "resistance");
    r2.valeurs["ohms"] = 220;
    netlist.relier("R2", "1", "N1");
    netlist.relier("R2", "2", "N3");
    auto& r3 = netlist.ajouter("R3", "resistance");
    r3.valeurs["ohms"] = 4700;
    netlist.relier("R3", "1", "N3");
    netlist.relier("R3", "2", "GND");
    netlist.ajouter("LED1", "led");
    netlist.relier("LED1", "A", "N2");
    netlist.relier("LED1", "K", "GND");

    // --- nomenclature
    {
        const auto lignes = coeur::nomenclature(netlist);
        int quantite_220 = 0, lignes_resistance = 0;
        for (const auto& ligne : lignes) {
            if (ligne.type != "resistance") continue;
            ++lignes_resistance;
            if (ligne.valeur.find("220") != std::string::npos)
                quantite_220 = ligne.quantite();
        }
        verifier(lignes_resistance == 2,
                 "nomenclature : deux valeurs distinctes de résistance",
                 std::to_string(lignes_resistance));
        verifier(quantite_220 == 2,
                 "nomenclature : les deux 220 Ω sont regroupées",
                 std::to_string(quantite_220));
        bool carte_listee = false, masse_listee = false;
        for (const auto& ligne : lignes) {
            if (ligne.type == "arduino_uno") carte_listee = true;
            if (ligne.type == "masse") masse_listee = true;
        }
        verifier(carte_listee, "nomenclature : la carte figure au tableau");
        verifier(!masse_listee, "nomenclature : les symboles ne s'achètent pas");

        verifier(coeur::format_ingenieur(4700, "Ω") == "4.7 kΩ",
                 "nomenclature : préfixes d'ingénieur",
                 coeur::format_ingenieur(4700, "Ω"));
        verifier(coeur::format_ingenieur(1e-7, "F") == "100 nF",
                 "nomenclature : 100 nF et non 1e-07 F",
                 coeur::format_ingenieur(1e-7, "F"));

        const std::string csv = coeur::nomenclature_csv(netlist);
        verifier(csv.find("Quantite;Designation") == 0,
                 "nomenclature : en-tête CSV");
        verifier(csv.find("R1 R2") != std::string::npos,
                 "nomenclature : références regroupées dans le CSV");
    }

    // --- contrôle des règles : ce circuit est propre
    {
        const auto anomalies = coeur::controler_regles(netlist);
        int erreurs = 0;
        std::string liste;
        for (const auto& anomalie : anomalies)
            if (anomalie.gravite == coeur::Anomalie::Gravite::Erreur) {
                ++erreurs;
                liste += " " + anomalie.reference + ":" + anomalie.message;
            }
        verifier(erreurs == 0, "ERC : un montage correct ne lève aucune erreur",
                 liste);
        bool led_signalee = false;
        for (const auto& anomalie : anomalies)
            if (anomalie.reference == "LED1") led_signalee = true;
        verifier(!led_signalee,
                 "ERC : la LED protégée par R1 n'est pas signalée");
    }

    // --- contrôle des règles : les fautes classiques sont attrapées
    {
        coeur::Netlist fautif;
        fautif.ajouter("LED1", "led");           // LED sans résistance
        fautif.relier("LED1", "A", "5V");
        fautif.relier("LED1", "K", "GND");
        auto& r = fautif.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 1000;
        fautif.relier("R1", "1", "N9");          // borne 2 en l'air
        auto& carte2 = fautif.ajouter("U1", "arduino_uno");
        (void)carte2;
        fautif.relier("U1", "D2", "GND");        // sortie sur la masse
        auto& pile1 = fautif.ajouter("V1", "pile");
        pile1.valeurs["volts"] = 9;
        fautif.relier("V1", "+", "N5");
        fautif.relier("V1", "-", "GND");
        auto& pile2 = fautif.ajouter("V2", "pile");
        pile2.valeurs["volts"] = 5;
        fautif.relier("V2", "+", "N5");
        fautif.relier("V2", "-", "GND");

        const auto anomalies = coeur::controler_regles(fautif);
        auto contient = [&anomalies](const std::string& reference,
                                     const std::string& fragment) {
            for (const auto& anomalie : anomalies)
                if (anomalie.reference == reference
                    && anomalie.message.find(fragment) != std::string::npos)
                    return true;
            return false;
        };
        verifier(contient("LED1", "résistance série"),
                 "ERC : LED sans résistance de limitation");
        verifier(contient("R1", "non connectée"), "ERC : borne en l'air");
        verifier(contient("U1", "directement"),
                 "ERC : sortie du microcontrôleur sur une alimentation");
        verifier(contient("V1", "parallèle"),
                 "ERC : deux sources en parallèle");
        verifier(anomalies.front().gravite == coeur::Anomalie::Gravite::Erreur,
                 "ERC : les erreurs viennent en tête du rapport");

        coeur::Netlist sans_masse;
        auto& seule = sans_masse.ajouter("R1", "resistance");
        seule.valeurs["ohms"] = 100;
        sans_masse.relier("R1", "1", "N1");
        sans_masse.relier("R1", "2", "N2");
        bool signalee = false;
        for (const auto& anomalie : coeur::controler_regles(sans_masse))
            if (anomalie.message.find("aucune masse") != std::string::npos)
                signalee = true;
        verifier(signalee, "ERC : absence de masse détectée");

        const std::string rapport = coeur::rapport_regles(fautif);
        verifier(rapport.find("[ERREUR]") != std::string::npos,
                 "ERC : le rapport est lisible tel quel");

        // Toute anomalie doit dire QUOI FAIRE. Un diagnostic non actionnable
        // ne vaut rien : les messages disaient déjà bien le quoi et le
        // pourquoi, et laissaient l'élève devant sa propre ignorance du
        // remède. Ce test attrape la règle qu'on ajouterait sans y penser.
        std::string sans_remede;
        for (const auto& anomalie : anomalies)
            if (anomalie.remede.empty())
                sans_remede += " « " + anomalie.message.substr(0, 40) + "… »";
        verifier(sans_remede.empty(),
                 "ERC : chaque anomalie dit quoi faire", sans_remede);
        verifier(rapport.find("\u2192") != std::string::npos,
                 "ERC : le rapport porte les remèdes, pas que les reproches");

        // Le court-circuit d'alimentation, dans ses deux formes vues à
        // l'usage. Aucune des deux n'était détectée : la première noyait le
        // journal sous « le point de repos n'a pas convergé » répété à chaque
        // pas de temps, la seconde tournait sans un mot avec la masse à 5 V —
        // le plus trompeur des deux.
        auto court_circuit = [](const coeur::Netlist& n) {
            for (const auto& anomalie : coeur::controler_regles(n))
                if (anomalie.message.find("court-circuit d'alimentation")
                    != std::string::npos)
                    return true;
            return false;
        };

        // 1. Un générateur posé entre le 5V et la masse d'une carte.
        {
            coeur::Netlist jus;
            jus.ajouter("U1", "arduino_uno");
            jus.relier("U1", "5V", "N1");
            jus.relier("U1", "GND", "GND");
            auto& gbf = jus.ajouter("GBF1", "generateur_signal");
            (void)gbf;
            jus.relier("GBF1", "+", "N1");
            jus.relier("GBF1", "-", "GND");
            verifier(!court_circuit(jus),
                     "ERC : un générateur entre 5V et GND, chacun sur son "
                     "nœud, n'est pas un court-circuit");
            // Le même, mais les deux broches ramenées sur un seul nœud.
            coeur::Netlist jus2;
            jus2.ajouter("U1", "arduino_uno");
            jus2.relier("U1", "5V", "GND");
            jus2.relier("U1", "GND", "GND");
            verifier(court_circuit(jus2),
                     "ERC : le 5V et la masse d'une carte sur le même nœud");
        }

        // 2. Les trois broches d'alimentation réunies : la capture où GND
        //    affichait 5,00 V.
        {
            coeur::Netlist fondu;
            fondu.ajouter("U1", "arduino_uno");
            fondu.relier("U1", "5V", "GND");
            fondu.relier("U1", "3V3", "GND");
            fondu.relier("U1", "GND", "GND");
            verifier(court_circuit(fondu),
                     "ERC : 5V, 3V3 et GND réunis sur un seul nœud");
        }

        // 3. Un symbole de masse posé sur le nœud d'alimentation.
        {
            coeur::Netlist melange;
            auto& r = melange.ajouter("R1", "resistance");
            r.valeurs["ohms"] = 220;
            melange.relier("R1", "1", "5V");
            melange.relier("R1", "2", "GND");
            melange.ajouter("GND1", "masse");
            melange.relier("GND1", "1", "5V");   // la masse sur le 5 V
            melange.ajouter("VCC1", "alim5v");
            melange.relier("VCC1", "1", "5V");
            verifier(court_circuit(melange),
                     "ERC : un symbole de masse posé sur le nœud "
                     "d'alimentation");
        }
    }

    // --- export netlist KiCad
    {
        const std::string kicad = coeur::netlist_kicad(netlist);
        verifier(kicad.find("(export (version D)") == 0,
                 "KiCad : en-tête du format");
        verifier(kicad.find("(comp (ref \"R1\")") != std::string::npos,
                 "KiCad : composant exporté");
        verifier(kicad.find("(footprint \"R_AXIAL_0207\")") != std::string::npos,
                 "KiCad : empreinte exportée — la porte vers le routage");
        verifier(kicad.find("(net (code 1)") != std::string::npos
                     && kicad.find("(node (ref \"LED1\") (pin \"A\"))")
                            != std::string::npos,
                 "KiCad : nœuds et bornes exportés");
        // parenthèses équilibrées : un fichier mal formé serait refusé
        int solde = 0;
        for (char c : kicad) {
            if (c == '(') ++solde;
            if (c == ')') --solde;
        }
        verifier(solde == 0, "KiCad : parenthèses équilibrées",
                 std::to_string(solde));
    }

    // --- export des courbes
    {
        coeur::Formes formes;
        formes.temps = {0.0, 1e-3, 2e-3};
        formes.tensions["n1"] = {0.0, 5.0, 5.0};
        formes.courants["r1"] = {0.0, 0.02, 0.02};
        const std::string csv = coeur::courbes_csv(formes);
        verifier(csv.find("temps;V(n1);I(r1)") == 0,
                 "courbes : en-tête CSV", csv.substr(0, 30));
        verifier(std::count(csv.begin(), csv.end(), '\n') == 4,
                 "courbes : une ligne par point");

        coeur::Balayage bode;
        bode.grandeur = "Fréquence";
        bode.abscisse = {10, 100};
        coeur::Courbe c;
        c.nom = "out";
        c.valeurs = {1.0, 0.7};
        c.phases = {0.0, -45.0};
        bode.courbes.push_back(c);
        const std::string csv_bode = coeur::balayage_csv(bode);
        verifier(csv_bode.find("Fréquence;out;phase(out)") == 0,
                 "balayage : module et phase en colonnes",
                 csv_bode.substr(0, 40));
    }
}

// ---------------------------------------------------------------------------
// [15] Balayages exécutés par ngspice : caractéristique de transfert et
// diagramme de Bode. Chaque résultat est confronté à la théorie.
// ---------------------------------------------------------------------------
static void test_balayages() {
    std::printf("\n[15] Balayage continu et réponse en fréquence\n");

    // --- pont diviseur : la sortie doit valoir le tiers de l'entrée
    {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "continu";
        source.valeurs["offset"] = 0;
        netlist.relier("GBF1", "+", "IN");
        netlist.relier("GBF1", "-", "GND");
        auto& r1 = netlist.ajouter("R1", "resistance");
        r1.valeurs["ohms"] = 2000;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "MID");
        auto& r2 = netlist.ajouter("R2", "resistance");
        r2.valeurs["ohms"] = 1000;
        netlist.relier("R2", "1", "MID");
        netlist.relier("R2", "2", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire_analyse(netlist, {}, ".dc VGBF1 0 5 0.5");
        const bool ok = moteur.resoudre_analyse();
        const coeur::Balayage& balayage = moteur.balayage();
        verifier(ok && balayage.abscisse.size() == 11,
                 "balayage continu : onze points de 0 à 5 V",
                 std::to_string(balayage.abscisse.size()));
        const coeur::Courbe* mid = balayage.courbe("mid");
        verifier(mid != nullptr, "balayage continu : la sortie est relevée");
        if (mid && mid->valeurs.size() == 11) {
            verifier(presque(mid->valeurs.front(), 0.0, 1e-6),
                     "balayage continu : 0 V en entrée donne 0 V",
                     f(mid->valeurs.front()));
            verifier(presque(mid->valeurs.back(), 5.0 / 3.0, 1e-3),
                     "balayage continu : 5 V donne bien V/3",
                     f(mid->valeurs.back()));
            verifier(!mid->complexe(),
                     "balayage continu : résultat réel, sans phase");
        }
    }

    // --- filtre RC : coupure théorique 1/(2 pi R C) = 1591,5 Hz
    {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "sinus";
        source.valeurs["amplitude"] = 1;
        source.valeurs["frequence"] = 1000;
        netlist.relier("GBF1", "+", "IN");
        netlist.relier("GBF1", "-", "GND");
        auto& r = netlist.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 1000;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "OUT");
        auto& c = netlist.ajouter("C1", "condensateur");
        c.valeurs["farads"] = 1e-7;
        netlist.relier("C1", "1", "OUT");
        netlist.relier("C1", "2", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire_analyse(netlist, {}, ".ac dec 40 10 1meg");
        const bool ok = moteur.resoudre_analyse();
        const coeur::Balayage& balayage = moteur.balayage();
        verifier(ok && balayage.logarithmique,
                 "réponse en fréquence : abscisse logarithmique reconnue");
        const coeur::Courbe* sortie = balayage.courbe("out");
        const coeur::Courbe* entree = balayage.courbe("in");
        verifier(sortie && sortie->complexe(),
                 "réponse en fréquence : module et phase relevés");
        if (sortie && entree) {
            const double coupure =
                coeur::frequence_coupure(balayage, *sortie, entree);
            verifier(presque(coupure, 1591.5, 40.0),
                     "réponse en fréquence : coupure à 1/(2 pi RC)",
                     f(coupure, 1) + " Hz");
            const std::vector<double> gains =
                coeur::gain_decibels(*sortie, entree);
            verifier(presque(gains.front(), 0.0, 0.2),
                     "réponse en fréquence : gain unité dans la bande passante",
                     f(gains.front(), 2) + " dB");
            // une décade au-dessus de la coupure : -20 dB, à 1 dB près
            double gain_16k = 0;
            for (size_t k = 0; k < balayage.abscisse.size(); ++k)
                if (balayage.abscisse[k] >= 15915.0) { gain_16k = gains[k]; break; }
            verifier(presque(gain_16k, -20.0, 1.0),
                     "réponse en fréquence : -20 dB par décade",
                     f(gain_16k, 2) + " dB");
            // phase de -45° à la coupure
            double phase_coupure = 0;
            for (size_t k = 0; k < balayage.abscisse.size(); ++k)
                if (balayage.abscisse[k] >= 1591.5) {
                    phase_coupure = sortie->phases[k] - entree->phases[k];
                    break;
                }
            verifier(presque(phase_coupure, -45.0, 3.0),
                     "réponse en fréquence : -45° à la coupure",
                     f(phase_coupure, 1) + "°");
        }
    }

    // --- balayage d'une résistance : ce que fait « .dc R1 » dans LTspice
    {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "continu";
        source.valeurs["offset"] = 6;
        netlist.relier("GBF1", "+", "IN");
        netlist.relier("GBF1", "-", "GND");
        auto& r1 = netlist.ajouter("R1", "resistance");
        r1.valeurs["ohms"] = 1000;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "MID");
        auto& r2 = netlist.ajouter("R2", "resistance");
        r2.valeurs["ohms"] = 1000;
        netlist.relier("R2", "1", "MID");
        netlist.relier("R2", "2", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire_analyse(netlist, {}, ".dc RR2 1k 3k 1k");
        const bool ok = moteur.resoudre_analyse();
        const coeur::Courbe* mid = moteur.balayage().courbe("mid");
        verifier(ok && mid && mid->valeurs.size() == 3,
                 "balayage d'une résistance : trois points");
        if (mid && mid->valeurs.size() == 3) {
            verifier(presque(mid->valeurs[0], 3.0, 1e-3)
                         && presque(mid->valeurs[2], 4.5, 1e-3),
                     "balayage d'une résistance : 3 V puis 4,5 V",
                     f(mid->valeurs[0]) + " / " + f(mid->valeurs[2]));
        }
    }

    // --- spectre d'un signal réellement simulé : sinusoïde écrêtée
    {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "carre";
        source.valeurs["amplitude"] = 2.5;
        source.valeurs["offset"] = 2.5;
        source.valeurs["frequence"] = 1000;
        netlist.relier("GBF1", "+", "IN");
        netlist.relier("GBF1", "-", "GND");
        auto& r = netlist.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 1000;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire_transitoire(netlist, {}, {}, 5e-3, 2e-6);
        const bool ok = moteur.resoudre_transitoire();
        const auto& formes = moteur.formes();
        auto it = formes.tensions.find("in");
        verifier(ok && it != formes.tensions.end(),
                 "générateur : la forme carrée est bien produite");
        if (it != formes.tensions.end()) {
            const coeur::Mesures m = coeur::mesurer(formes.temps, it->second);
            verifier(presque(m.frequence, 1000.0, 20.0),
                     "générateur : 1 kHz mesuré sur la sortie",
                     f(m.frequence, 1) + " Hz");
            verifier(presque(m.crete_a_crete, 5.0, 0.1),
                     "générateur : 5 V crête à crête", f(m.crete_a_crete));
            const coeur::Spectre s =
                coeur::analyser_spectre(formes.temps, it->second, 9);
            verifier(s.valide && presque(s.thd, 42.88, 2.0),
                     "générateur : distorsion du carré retrouvée sur le signal "
                     "simulé",
                     f(s.thd, 2) + " %");
        }
    }
}

// ---------------------------------------------------------------------------
// [16] Multimètres : ce qu'affiche un appareil selon sa position. En continu
// la moyenne, en alternatif la valeur efficace de la partie variable — c'est
// ce que font les multimètres virtuels de Multisim et de Proteus, et ce que
// fait un appareil réel.
// ---------------------------------------------------------------------------
static void test_multimetres() {
    std::printf("\n[16] Multimètres : positions continu et alternatif\n");
    const coeur::Catalogue& catalogue = coeur::Catalogue::instance();
    const double pi = 3.14159265358979323846;

    // Sinusoïde de 5 V crête, décalée de 2 V : moyenne 2 V, efficace 3,536 V.
    std::vector<double> temps, onde;
    for (int k = 0; k <= 10000; ++k) {
        const double t = k * 10e-3 / 10000;
        temps.push_back(t);
        onde.push_back(2.0 + 5.0 * std::sin(2 * pi * 1000 * t));
    }
    std::vector<double> zero(onde.size(), 0.0);

    {   // --- voltmètre
        const coeur::Modele* modele = catalogue.modele("voltmetre");
        verifier(modele && modele->mesure_instrument,
                 "le voltmètre sait lire une forme d'onde");
        if (!modele || !modele->mesure_instrument) return;

        coeur::Modele::Lecture lecture;
        lecture.temps = &temps;
        lecture.tension = [](const std::string&) { return 0.0; };
        lecture.forme_tension =
            [&](const std::string& borne) -> const std::vector<double>* {
            return borne == "+" ? &onde : &zero;
        };

        coeur::Instance continu;
        continu.reference = "VM1";
        continu.type = "voltmetre";
        continu.textes["mode"] = "continu";
        const std::string lu_continu = modele->mesure_instrument(continu, lecture);
        verifier(lu_continu == "2.00 V",
                 "position continu : la valeur moyenne", lu_continu);

        coeur::Instance alternatif = continu;
        alternatif.textes["mode"] = "alternatif";
        const std::string lu_ac = modele->mesure_instrument(alternatif, lecture);
        verifier(lu_ac == "3.54 V ~",
                 "position alternatif : la valeur efficace, hors composante "
                 "continue",
                 lu_ac);

        // Sans forme d'onde — analyse au point de repos — l'appareil retombe
        // sur la valeur instantanée plutôt que d'afficher n'importe quoi.
        coeur::Modele::Lecture ponctuelle;
        ponctuelle.tension = [](const std::string& borne) {
            return borne == "+" ? 4.5 : 0.0;
        };
        const std::string lu_point =
            modele->mesure_instrument(continu, ponctuelle);
        verifier(lu_point == "4.50 V",
                 "sans relevé transitoire, la valeur instantanée", lu_point);
    }

    {   // --- ampèremètre
        const coeur::Modele* modele = catalogue.modele("amperemetre");
        std::vector<double> courant;
        for (double valeur : onde) courant.push_back(valeur / 1000.0);
        coeur::Modele::Lecture lecture;
        lecture.temps = &temps;
        lecture.forme_courant = &courant;

        coeur::Instance i;
        i.reference = "AM1";
        i.type = "amperemetre";
        i.textes["mode"] = "continu";
        const std::string continu = modele->mesure_instrument(i, lecture);
        verifier(continu == "2.00 mA", "ampèremètre en continu : la moyenne",
                 continu);
        i.textes["mode"] = "alternatif";
        const std::string alternatif = modele->mesure_instrument(i, lecture);
        verifier(alternatif == "3.54 mA ~",
                 "ampèremètre en alternatif : la valeur efficace", alternatif);
    }

    {   // --- ohmmètre : il injecte un courant connu et lit la tension
        const coeur::Modele* modele = catalogue.modele("ohmmetre");
        verifier(modele != nullptr, "l'ohmmètre est au catalogue");
        if (!modele) return;
        coeur::Modele::Lecture lecture;
        lecture.tension = [](const std::string& borne) {
            return borne == "-" ? 1.0 : 0.0;    // 1 V pour 1 mA
        };
        coeur::Instance i;
        i.reference = "OM1";
        i.type = "ohmmetre";
        i.valeurs["courant"] = 1e-3;
        const std::string lu = modele->mesure_instrument(i, lecture);
        verifier(lu == "1.00 kΩ", "1 V sous 1 mA se lit 1 kΩ", lu);

        // Et il doit produire une vraie source de courant dans le circuit.
        coeur::Netlist netlist;
        auto& instance = netlist.ajouter("OM1", "ohmmetre");
        instance.valeurs["courant"] = 1e-3;
        netlist.relier("OM1", "+", "A");
        netlist.relier("OM1", "-", "GND");
        auto& r = netlist.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 4700;
        netlist.relier("R1", "1", "A");
        netlist.relier("R1", "2", "GND");
        {
            coeur::NgspiceEngine moteur;
            moteur.construire(netlist, {});
            moteur.resoudre();
            // 1 mA dans 4,7 kΩ : la borne « - » est à la masse, « + » est
            // tirée à -4,7 V par la source, ce qui se relit bien en 4,7 kΩ.
            const double u = std::fabs(moteur.tension("A"));
            verifier(presque(u, 4.7, 0.05),
                     "l'ohmmètre injecte réellement son courant d'essai",
                     f(u) + " V");
        }
    }
}

// ---------------------------------------------------------------------------
// [21] Le solveur intégré confronté à ngspice
//
// C'est le test qui compte le plus pour l'indépendance du projet : le même
// circuit, le même fichier SPICE, les deux moteurs, et la comparaison des
// résultats. Quand ngspice n'est pas là, le test s'annonce comme non
// exécutable plutôt que de se déclarer réussi.
// ---------------------------------------------------------------------------
static void test_solveur_integre() {
    std::printf("\n[21] Solveur intégré confronté à ngspice\n");

    if (!coeur::NgspiceEngine::compile_avec_ngspice()) {
        std::printf("  (ngspice absent : comparaison impossible, le solveur "
                    "intégré reste vérifié contre la théorie)\n");
        return;
    }

    // --- point de repos : pont diviseur, LED, transistor
    {
        coeur::Netlist netlist;
        auto& r1 = netlist.ajouter("R1", "resistance");
        r1.valeurs["ohms"] = 1000;
        netlist.relier("R1", "1", "D13");
        netlist.relier("R1", "2", "MILIEU");
        auto& led = netlist.ajouter("LED1", "led");
        led.textes["couleur"] = "rouge";
        netlist.relier("LED1", "A", "MILIEU");
        netlist.relier("LED1", "K", "GND");
        netlist.ajouter("Q1", "transistor_npn");
        netlist.relier("Q1", "C", "D13");
        netlist.relier("Q1", "B", "MILIEU");
        netlist.relier("Q1", "E", "GND");

        const std::vector<coeur::BrocheElectrique> broches = {
            {"D13", coeur::BrocheElectrique::Mode::Sortie, 5.0, 25.0}};

        std::map<std::string, double> integre, reference;
        for (int moteur_ngspice = 0; moteur_ngspice < 2; ++moteur_ngspice) {
            coeur::NgspiceEngine moteur;
            moteur.preferer_ngspice(moteur_ngspice == 1);
            moteur.construire(netlist, broches);
            if (!moteur.resoudre()) continue;
            (moteur_ngspice ? reference : integre) = moteur.toutes_tensions();
        }
        verifier(!integre.empty() && !reference.empty(),
                 "les deux moteurs résolvent le même point de repos");

        double ecart_maximal = 0;
        std::string pire;
        for (const auto& tension : reference) {
            auto it = integre.find(tension.first);
            if (it == integre.end()) continue;
            const double ecart = std::fabs(it->second - tension.second);
            if (ecart > ecart_maximal) {
                ecart_maximal = ecart;
                pire = tension.first;
            }
        }
        // Vingt millivolts sur cinq volts : le modèle de transistor employé
        // ici est un Ebers-Moll avec effet Early, plus simple que le
        // Gummel-Poon de ngspice. L'écart est là, il est borné, et il est dit.
        verifier(ecart_maximal < 20e-3,
                 "mêmes tensions que ngspice à 20 mV près (diode + transistor)",
                 pire + " : " + f(ecart_maximal * 1000, 3) + " mV");
    }

    // --- transitoire : charge d'un RC, comparée point par point
    {
        coeur::Netlist netlist;
        auto& r = netlist.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 1000;
        netlist.relier("R1", "1", "D13");
        netlist.relier("R1", "2", "SORTIE");
        auto& c = netlist.ajouter("C1", "condensateur");
        c.valeurs["farads"] = 100e-9;
        netlist.relier("C1", "1", "SORTIE");
        netlist.relier("C1", "2", "GND");

        std::vector<double> temps[2];
        std::vector<double> sortie[2];
        for (int moteur_ngspice = 0; moteur_ngspice < 2; ++moteur_ngspice) {
            coeur::NgspiceEngine moteur;
            moteur.preferer_ngspice(moteur_ngspice == 1);
            moteur.oublier_etat();
            moteur.construire_transitoire(
                netlist,
                {{"D13", coeur::BrocheElectrique::Mode::Sortie, 5.0, 25.0}}, {},
                1e-3, 2e-6);
            if (!moteur.resoudre_transitoire()) continue;
            temps[moteur_ngspice] = moteur.formes().temps;
            auto it = moteur.formes().tensions.find("sortie");
            if (it != moteur.formes().tensions.end())
                sortie[moteur_ngspice] = it->second;
        }
        verifier(!sortie[0].empty() && !sortie[1].empty(),
                 "les deux moteurs calculent le même transitoire");

        // Les deux moteurs ne posent pas leurs points aux mêmes instants :
        // on interpole celui de référence là où le nôtre a calculé.
        auto valeur_a = [](const std::vector<double>& t,
                           const std::vector<double>& v, double instant) {
            if (t.empty()) return 0.0;
            for (size_t k = 1; k < t.size(); ++k) {
                if (t[k] < instant) continue;
                const double largeur = t[k] - t[k - 1];
                if (largeur <= 0) return v[k];
                return v[k - 1]
                       + (v[k] - v[k - 1]) * (instant - t[k - 1]) / largeur;
            }
            return v.back();
        };
        double ecart_maximal = 0;
        double instant_pire = 0;
        for (size_t k = 0; k < temps[0].size(); ++k) {
            const double attendu = valeur_a(temps[1], sortie[1], temps[0][k]);
            const double ecart = std::fabs(sortie[0][k] - attendu);
            if (ecart > ecart_maximal) {
                ecart_maximal = ecart;
                instant_pire = temps[0][k];
            }
        }
        verifier(ecart_maximal < 0.02,
                 "même forme d'onde que ngspice à 20 mV près",
                 f(ecart_maximal * 1000, 2) + " mV au pire, à "
                     + f(instant_pire * 1e6, 1) + " µs");
    }

    // --- réponse en fréquence : la coupure doit tomber au même endroit
    {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.valeurs["amplitude"] = 1;
        source.valeurs["frequence"] = 1000;
        netlist.relier("GBF1", "+", "ENTREE");
        netlist.relier("GBF1", "-", "GND");
        auto& r = netlist.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 1000;
        netlist.relier("R1", "1", "ENTREE");
        netlist.relier("R1", "2", "SORTIE");
        auto& c = netlist.ajouter("C1", "condensateur");
        c.valeurs["farads"] = 100e-9;
        netlist.relier("C1", "1", "SORTIE");
        netlist.relier("C1", "2", "GND");

        double coupures[2] = {0, 0};
        for (int moteur_ngspice = 0; moteur_ngspice < 2; ++moteur_ngspice) {
            coeur::NgspiceEngine moteur;
            moteur.preferer_ngspice(moteur_ngspice == 1);
            moteur.construire_analyse(netlist, {}, ".ac dec 40 10 1meg");
            if (!moteur.resoudre_analyse()) continue;
            const coeur::Balayage& balayage = moteur.balayage();
            if (const coeur::Courbe* sortie = balayage.courbe("sortie"))
                coupures[moteur_ngspice] =
                    coeur::frequence_coupure(balayage, *sortie);
        }
        verifier(coupures[0] > 0 && coupures[1] > 0,
                 "les deux moteurs relèvent la réponse en fréquence");
        verifier(presque(coupures[0], coupures[1], coupures[1] * 0.02),
                 "même fréquence de coupure que ngspice, à 2 % près",
                 f(coupures[0], 1) + " Hz contre " + f(coupures[1], 1) + " Hz");
    }
}

// ---------------------------------------------------------------------------
// [22] Le cœur AVR intégré confronté à simavr
//
// Même firmware, les deux cœurs, et comparaison des instants où les broches
// commutent. C'est ce qui distingue « ça a l'air de marcher » de « c'est le
// même microcontrôleur ».
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// [51] AUDIT — le solveur intégré, celui qui sert quand ngspice est absent
//
// C'est le solveur de secours : sur un poste sans ngspice — le cas de la
// plupart des machines d'atelier — c'est LUI qui calcule tout. Il n'était
// jusqu'ici vérifié qu'indirectement, par des essais qui passaient par
// ngspice dès qu'il était installé.
// ---------------------------------------------------------------------------
static void test_solveur_integre_troncature_et_ringing() {
    std::printf("\n[51] Audit : le solveur intégré dit ce qu'il n'a pas pu faire\n");

    // --- 1. UNE SIMULATION TRONQUÉE N'EST PAS UNE SIMULATION RÉUSSIE.
    //
    // Un pas demandé très fin sur une longue fenêtre dépasse le garde-fou de
    // deux millions de pas. La boucle s'arrêtait alors en silence : la
    // fonction rendait « vrai », `erreurs()` restait vide, et l'appelant
    // affichait une courbe qui s'arrête au vingt-cinquième de la fenêtre sans
    // que rien ne le dise.
    {
        const std::string deck =
            "* RC\n"
            "V1 in 0 DC 5\n"
            "R1 in out 1k\n"
            "C1 out 0 1u\n"
            ".tran 1p 50u\n"
            ".end\n";
        coeur::SolveurIntegre solveur;
        coeur::Formes formes;
        verifier(solveur.charger(deck), "le circuit se charge");
        const bool dit_oui = solveur.transitoire(formes);
        const double atteint = formes.temps.empty() ? 0 : formes.temps.back();
        const bool complet = atteint >= 50e-6 * 0.999;
        verifier(complet || !dit_oui || !solveur.erreurs().empty(),
                 "une simulation qui s'arrête avant la fin le DIT",
                 "arrivée à " + f(atteint * 1e6, 3) + " µs sur 50, rendu « "
                     + (dit_oui ? "réussi" : "échoué") + " », "
                     + std::to_string(solveur.erreurs().size()) + " message(s)");
    }

    // --- 2. UNE DÉCHARGE RC NE CHANGE PAS DE SIGNE.
    //
    // Une impulsion de 100 ns sur un RC de 1 µs, dans une fenêtre échantillonnée
    // tous les 5 µs : la règle des trapèzes, appliquée avec un pas très
    // supérieur à la constante de temps, oscille autour de la vraie solution
    // au lieu de la suivre — c'est le « ringing » bien connu de cette méthode,
    // de raison (1−h/2τ)/(1+h/2τ), soit −0,43 ici.
    //
    // Ce n'est pas un cas d'école : les fronts de broche d'un microcontrôleur
    // durent 100 ns, et la résolution par défaut de l'application vaut 50 µs.
    // Tout filtre RC rapide posé sur une sortie numérique tombe dedans.
    {
        const std::string deck =
            "* RC rapide sous impulsion breve\n"
            "V1 in 0 PULSE(0 5 20u 1n 1n 100n 1000)\n"
            "R1 in out 1k\n"
            "C1 out 0 1n\n"
            ".tran 5u 50u\n"
            ".end\n";
        coeur::SolveurIntegre solveur;
        coeur::Formes formes;
        verifier(solveur.charger(deck), "le circuit se charge");
        verifier(solveur.transitoire(formes), "le transitoire se calcule",
                 solveur.erreurs().empty() ? "" : solveur.erreurs().front());
        auto onde = formes.tensions.find("out");
        verifier(onde != formes.tensions.end(), "la sortie est relevée");
        if (onde == formes.tensions.end()) return;

        double sommet = 0;
        std::size_t rang_sommet = 0;
        for (std::size_t k = 0; k < onde->second.size(); ++k)
            if (onde->second[k] > sommet) { sommet = onde->second[k]; rang_sommet = k; }
        // Cent nanosecondes sur une constante de temps d'une microseconde :
        // le condensateur n'a le temps de se charger qu'à 5·(1−e^−0,1), soit
        // 476 mV. C'est cette valeur-là qu'il faut retrouver — pas les cinq
        // volts de l'entrée.
        const double attendu = 5.0 * (1.0 - std::exp(-0.1));
        verifier(std::fabs(sommet - attendu) < attendu * 0.15,
                 "l'impulsion de 100 ns est bien vue, à sa vraie hauteur",
                 f(sommet) + " V au lieu de " + f(attendu));

        // Après le sommet, plus aucune source : la décharge est monotone et
        // ne passe jamais sous zéro.
        //
        // La mesure se fait au millivolt : c'est le plancher que le contrôle
        // de pas s'impose lui-même, et en dessous duquel il laisse le pas
        // repousser. La queue de courbe y garde un frisson de quelques
        // dixièmes de microvolt — sans objet physique, et invisible sur tout
        // écran. Exiger mieux reviendrait à demander au solveur de suivre le
        // bruit de l'arithmétique.
        constexpr double kPlancher = 1e-3;
        double plus_negatif = 0, plus_grande_remontee = 0;
        for (std::size_t k = rang_sommet + 1; k < onde->second.size(); ++k) {
            plus_negatif = std::min(plus_negatif, onde->second[k]);
            plus_grande_remontee = std::max(
                plus_grande_remontee, onde->second[k] - onde->second[k - 1]);
        }
        verifier(plus_negatif > -kPlancher,
                 "la décharge ne repasse jamais sous zéro",
                 f(plus_negatif * 1e3, 4) + " mV au plus bas");
        verifier(plus_grande_remontee < kPlancher,
                 "et elle ne remonte jamais",
                 f(plus_grande_remontee * 1e3, 4) + " mV de remontée au pire");
    }
}

// ---------------------------------------------------------------------------
// [49] AUDIT — un temporisateur préchargé
//
// Précharger TCNTx est le geste de base d'un temporisateur : on part de 200
// au lieu de 0 pour que le débordement arrive au bout de 56 pas, pas de 256.
// C'est ainsi qu'on obtient une période qui n'est pas une puissance de deux —
// une milliseconde, un pas de servo, une note de musique.
// ---------------------------------------------------------------------------
static const char* kPrechargeTimer = R"(
#include <avr/io.h>

int main(void) {
    DDRB |= (1 << 5);                       /* D13 en sortie */
    TCCR0B = (1 << CS02) | (1 << CS00);     /* prédiviseur /1024 */
    while (1) {
        TCNT0 = 200;                        /* 56 pas avant le débordement */
        TIFR0 = (1 << TOV0);                /* on efface le drapeau */
        while (!(TIFR0 & (1 << TOV0))) { }  /* on attend */
        PORTB ^= (1 << 5);                  /* et on bascule */
    }
    return 0;
}
)";

static void test_compteur_precharge() {
    std::printf("\n[49] Audit : un temporisateur préchargé bat au bon rythme\n");

    if (!coeur::AvrEngine::avr_gcc_disponible()) {
        std::printf("  (avr-gcc absent — section ignorée)\n");
        return;
    }
    const std::string firmware = "/tmp/sim_precharge.elf";
    std::string journal;
    if (!coeur::AvrEngine::compiler_source(kPrechargeTimer, firmware,
                                           &journal)) {
        verifier(false, "compilation du firmware de préchargement", journal);
        return;
    }

    // 56 pas de 1024 cycles : 57 344 cycles entre deux bascules. Sans la
    // prise en compte de l'écriture, le compteur repart de 0 et il en faut
    // 262 144 — la LED bat quatre fois et demie trop lentement.
    const double attendue = (256 - 200) * 1024.0;

    for (int avec_simavr = 0; avec_simavr < 2; ++avec_simavr) {
        if (avec_simavr == 1 && !coeur::AvrEngine::compile_avec_simavr())
            continue;
        coeur::AvrEngine mcu;
        mcu.preferer_simavr(avec_simavr == 1);
        if (!mcu.charger(firmware)) {
            verifier(false, "chargement du firmware", mcu.erreur());
            return;
        }
        std::vector<uint64_t> bascules;
        mcu.sur_changement_broche([&](int broche, bool) {
            if (broche == 13) bascules.push_back(mcu.cycle());
        });
        mcu.avancer(600000);

        const std::string qui =
            avec_simavr == 1 ? "simavr" : "cœur intégré";
        verifier(bascules.size() >= 4, qui + " : la LED bascule",
                 std::to_string(bascules.size()) + " bascule(s)");
        if (bascules.size() < 4) continue;
        // On mesure entre la deuxième et la dernière : la première période
        // porte encore le démarrage du programme.
        const double periode =
            static_cast<double>(bascules.back() - bascules[1])
            / static_cast<double>(bascules.size() - 2);
        verifier(std::fabs(periode - attendue) < attendue * 0.05,
                 qui + " : une période de " + f(attendue, 0) + " cycles, "
                 "parce que le compteur repart de 200",
                 f(periode, 0) + " cycles");
    }
}

// ---------------------------------------------------------------------------
// [50] AUDIT — le numérique sur une carte 3,3 V
//
// Le seuil de basculement était figé à 2,5 V et l'amplitude de sortie à 5 V,
// alors que la carte déclare sa `tension_logique` et que celle-ci sert déjà
// pour les broches analogiques. Un 74HC595 posé sur un Pico sortait donc
// 5 V — de quoi griller ce qu'il pilote sur le papier, et fausser tout calcul
// de courant — et lisait ses entrées avec un seuil trop haut pour la carte.
// ---------------------------------------------------------------------------
static void test_numerique_trois_volts_trois() {
    std::printf("\n[50] Audit : le numérique suit la tension de la carte\n");

    auto monter = []() {
        coeur::Netlist netlist;
        netlist.ajouter("IC1", "registre_74hc595");
        netlist.relier("IC1", "SER", "D11");
        netlist.relier("IC1", "SRCLK", "D13");
        netlist.relier("IC1", "RCLK", "D10");
        netlist.relier("IC1", "OE", "VALIDATION");
        for (int k = 0; k < 8; ++k)
            netlist.relier("IC1", "Q" + std::to_string(k),
                           "SORTIE" + std::to_string(k));
        return netlist;
    };
    // Un seul bit décalé, puis verrouillé : Q0 doit monter.
    const std::vector<coeur::FrontNoeud> fronts = {
        {1e-6, "D11", true},  {1.1e-6, "D13", true}, {1.2e-6, "D13", false},
        {2e-6, "D10", true},  {2.1e-6, "D10", false}};

    // --- 1. L'AMPLITUDE EST CELLE DE LA CARTE.
    {
        coeur::Netlist netlist = monter();
        coeur::MoteurNumerique moteur;
        moteur.propager(netlist, fronts, {}, 1e-3, 3.3);
        const coeur::Instance* ic = netlist.trouver("IC1");
        double maximum = 0;
        if (ic) {
            auto onde = ic->ondes.find("Q0");
            if (onde != ic->ondes.end())
                for (const auto& point : onde->second)
                    maximum = std::max(maximum, point.second);
        }
        verifier(std::fabs(maximum - 3.3) < 1e-9,
                 "sur une carte 3,3 V, la sortie du registre monte à 3,3 V",
                 f(maximum) + " V");
    }

    // --- 2. LE SEUIL SUIT, LUI AUSSI.
    //
    // OE tenu à 2,0 V : sur une carte 3,3 V c'est un niveau HAUT (le seuil
    // vaut 1,65 V), donc les sorties sont inhibées. Avec le seuil figé à
    // 2,5 V, le registre le lisait BAS et publiait ses huit sorties.
    {
        const std::map<std::string, double> niveaux = {{"validation", 2.0}};
        struct Cas { double carte; bool inhibe; const char* dit; };
        const Cas cas[] = {
            {3.3, true, "sur une carte 3,3 V, 2,0 V sur OE est un niveau HAUT "
                        "— les sorties restent inhibées"},
            {5.0, false, "sur une carte 5 V, les mêmes 2,0 V sont un niveau "
                         "BAS — les sorties sortent"}};
        for (const Cas& c : cas) {
            coeur::Netlist netlist = monter();
            coeur::MoteurNumerique moteur;
            moteur.propager(netlist, fronts, niveaux, 1e-3, c.carte);
            const coeur::Instance* ic = netlist.trouver("IC1");
            const bool q0 = ic && ic->valeur("_niveau_Q0", 0.0) > 0.5;
            verifier(q0 != c.inhibe, c.dit,
                     std::string("Q0 ") + (q0 ? "haute" : "basse"));
        }
    }
}

static void test_coeur_avr() {
    std::printf("\n[22] Cœur AVR intégré confronté à simavr\n");

    if (!coeur::AvrEngine::compile_avec_simavr()) {
        std::printf("  (simavr absent : comparaison impossible, le cœur "
                    "intégré reste vérifié par les sections 3 à 6 et 11)\n");
        return;
    }
    if (g_firmware.empty()) {
        std::printf("  (aucun firmware compilé — section ignorée)\n");
        return;
    }

    struct Commutation {
        uint64_t cycle;
        int broche;
        bool haut;
    };
    std::vector<Commutation> releves[2];
    uint64_t horloges[2] = {0, 0};

    for (int avec_simavr = 0; avec_simavr < 2; ++avec_simavr) {
        coeur::AvrEngine mcu;
        mcu.preferer_simavr(avec_simavr == 1);
        if (!mcu.charger(g_firmware)) {
            std::printf("  (chargement impossible : %s)\n", mcu.erreur().c_str());
            return;
        }
        mcu.sur_changement_broche([&](int broche, bool haut) {
            releves[avec_simavr].push_back({mcu.cycle(), broche, haut});
        });
        mcu.avancer(4000000);          // 250 ms simulées
        horloges[avec_simavr] = mcu.cycle();
    }

    verifier(!releves[0].empty() && !releves[1].empty(),
             "les deux cœurs exécutent le firmware");
    verifier(releves[0].size() == releves[1].size(),
             "même nombre de commutations de broche",
             std::to_string(releves[0].size()) + " contre "
                 + std::to_string(releves[1].size()));
    verifier(horloges[0] >= 4000000 && horloges[1] >= 4000000,
             "les deux comptent bien quatre millions de cycles");

    if (releves[0].size() != releves[1].size()) return;

    uint64_t ecart_maximal = 0;
    bool memes_broches = true;
    for (size_t k = 0; k < releves[0].size(); ++k) {
        if (releves[0][k].broche != releves[1][k].broche
            || releves[0][k].haut != releves[1][k].haut)
            memes_broches = false;
        const uint64_t a = releves[0][k].cycle, b = releves[1][k].cycle;
        ecart_maximal = std::max(ecart_maximal, a > b ? a - b : b - a);
    }
    verifier(memes_broches, "mêmes broches, mêmes sens de commutation");
    // Le firmware d'essai bascule D13 toutes les 500 ms de temps simulé, par
    // une boucle d'attente : mille cycles d'écart sur huit millions, c'est
    // trois dix-millièmes.
    verifier(ecart_maximal < 20000,
             "mêmes instants de commutation que simavr",
             std::to_string(ecart_maximal) + " cycles d'écart au pire, sur "
                 + std::to_string(horloges[0]));
}

// ---------------------------------------------------------------------------
// [17] Balayage en température et analyse de bruit : deux analyses que
// ngspice sait faire et qu'il fallait seulement savoir lui demander.
// ---------------------------------------------------------------------------
static void test_temperature_et_bruit() {
    std::printf("\n[17] Température et bruit\n");

    // --- une thermistance CTN doit voir sa tension varier avec la
    // température : c'est la vérification qui a du sens ici.
    {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "continu";
        source.valeurs["offset"] = 5;
        netlist.relier("GBF1", "+", "IN");
        netlist.relier("GBF1", "-", "GND");
        auto& r = netlist.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 10000;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "MID");
        netlist.ajouter("D1", "diode");
        netlist.relier("D1", "A", "MID");
        netlist.relier("D1", "K", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire_analyse(netlist, {}, ".dc TEMP -20 100 20");
        const bool ok = moteur.resoudre_analyse();
        const coeur::Balayage& balayage = moteur.balayage();
        verifier(ok && balayage.abscisse.size() == 7,
                 "balayage en température : sept points de -20 à 100 °C",
                 std::to_string(balayage.abscisse.size()));
        const coeur::Courbe* mid = balayage.courbe("mid");
        if (mid && mid->valeurs.size() == 7) {
            // La tension de seuil d'une diode baisse d'environ 2 mV par degré :
            // sur 120 °C, la chute doit être nettement visible.
            const double froid = mid->valeurs.front(), chaud = mid->valeurs.back();
            verifier(chaud < froid - 0.15,
                     "la tension de seuil d'une diode baisse avec la chaleur",
                     f(froid) + " V à -20 °C, " + f(chaud) + " V à 100 °C");
        } else {
            verifier(false, "balayage en température : la sortie est relevée");
        }
    }

    // --- bruit d'une résistance : la théorie donne 4kTR, soit 12,9 nV/√Hz
    // pour 10 kΩ à 27 °C.
    {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "sinus";
        netlist.relier("GBF1", "+", "IN");
        netlist.relier("GBF1", "-", "GND");
        auto& r = netlist.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 10000;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "SORTIE");
        auto& c = netlist.ajouter("C1", "condensateur");
        c.valeurs["farads"] = 1e-9;
        netlist.relier("C1", "1", "SORTIE");
        netlist.relier("C1", "2", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire_analyse(netlist, {},
                                  ".noise V(SORTIE) VGBF1 dec 10 10 1meg");
        const bool ok = moteur.resoudre_analyse();
        const coeur::Balayage& balayage = moteur.balayage();
        verifier(ok && balayage.logarithmique,
                 "l'analyse de bruit produit bien un spectre en fréquence");
        const coeur::Courbe* sortie = balayage.courbe("onoise_spectrum");
        verifier(sortie != nullptr,
                 "le spectre de bruit en sortie est retrouvé, malgré le tracé "
                 "des totaux que ngspice laisse courant");
        if (sortie && !sortie->valeurs.empty()) {
            // 4kTR = 1,66e-16 V²/Hz pour 10 kΩ : 12,9 nV/√Hz en basse
            // fréquence, là où le condensateur n'agit pas encore.
            const double densite = sortie->valeurs.front();
            verifier(presque(densite, 12.9e-9, 1.5e-9),
                     "bruit thermique d'une résistance de 10 kΩ : 4kTR",
                     std::to_string(densite * 1e9) + " nV/√Hz");
            // Le filtre coupe : le bruit doit décroître avec la fréquence.
            verifier(sortie->valeurs.back() < densite / 10,
                     "et le filtre RC coupe ce bruit en haute fréquence");
        }
    }
}

// ---------------------------------------------------------------------------
// [18] Campagnes : balayage paramétrique et Monte-Carlo.
// ---------------------------------------------------------------------------
static coeur::Netlist filtre_rc(double ohms, double farads) {
    coeur::Netlist netlist;
    auto& source = netlist.ajouter("GBF1", "generateur_signal");
    source.textes["forme"] = "sinus";
    netlist.relier("GBF1", "+", "IN");
    netlist.relier("GBF1", "-", "GND");
    auto& r = netlist.ajouter("R1", "resistance");
    r.valeurs["ohms"] = ohms;
    netlist.relier("R1", "1", "IN");
    netlist.relier("R1", "2", "OUT");
    auto& c = netlist.ajouter("C1", "condensateur");
    c.valeurs["farads"] = farads;
    netlist.relier("C1", "1", "OUT");
    netlist.relier("C1", "2", "GND");
    return netlist;
}

static void test_campagnes() {
    std::printf("\n[18] Balayage paramétrique et Monte-Carlo\n");

    // --- .step : la coupure d'un RC doit se déplacer comme 1/R
    {
        const coeur::Netlist netlist = filtre_rc(1000, 1e-7);
        const coeur::Campagne campagne = coeur::balayer_parametre(
            netlist, {}, "R1", "ohms", {500, 1000, 2000},
            ".ac dec 40 10 1meg");
        verifier(campagne.passes.size() == 3,
                 "balayage paramétrique : trois passes",
                 std::to_string(campagne.passes.size()));
        if (campagne.passes.size() == 3) {
            std::vector<double> coupures;
            for (const coeur::Passe& passe : campagne.passes) {
                const coeur::Courbe* sortie = passe.balayage.courbe("out");
                const coeur::Courbe* entree = passe.balayage.courbe("in");
                coupures.push_back(sortie ? coeur::frequence_coupure(
                                       passe.balayage, *sortie, entree)
                                          : 0.0);
            }
            // 1/(2 pi R C) : 3183 Hz, 1592 Hz, 796 Hz.
            verifier(presque(coupures[0], 3183, 80) && presque(coupures[1], 1592, 40)
                         && presque(coupures[2], 796, 20),
                     "chaque passe coupe là où la théorie l'annonce",
                     f(coupures[0], 0) + " / " + f(coupures[1], 0) + " / "
                         + f(coupures[2], 0) + " Hz");
            verifier(coupures[0] > coupures[1] && coupures[1] > coupures[2],
                     "doubler la résistance divise la coupure par deux");
        }
    }

    // --- Monte-Carlo : la dispersion doit rester dans la tolérance
    {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "continu";
        source.valeurs["offset"] = 10;
        netlist.relier("GBF1", "+", "IN");
        netlist.relier("GBF1", "-", "GND");
        auto& r1 = netlist.ajouter("R1", "resistance");
        r1.valeurs["ohms"] = 1000;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "MID");
        auto& r2 = netlist.ajouter("R2", "resistance");
        r2.valeurs["ohms"] = 1000;
        netlist.relier("R2", "1", "MID");
        netlist.relier("R2", "2", "GND");

        const coeur::Campagne campagne =
            coeur::monte_carlo(netlist, {}, 5.0, 30, ".dc VGBF1 10 10 1", 7);
        verifier(campagne.passes.size() == 30, "Monte-Carlo : trente tirages",
                 std::to_string(campagne.passes.size()));
        const coeur::Dispersion d = coeur::disperser(campagne, "mid", 10.0);
        verifier(d.valide && presque(d.moyenne, 5.0, 0.1),
                 "un pont diviseur reste centré sur 5 V", f(d.moyenne));
        // Deux résistances à ±5 % font au pire 5 × (1,05/(1,05+0,95)) = 5,25 V.
        verifier(d.maxi <= 5.30 && d.mini >= 4.70,
                 "la dispersion reste dans ce que la tolérance autorise",
                 f(d.mini) + " à " + f(d.maxi) + " V");
        verifier(d.ecart_type > 0.01,
                 "et les tirages ne sont pas tous identiques",
                 f(d.ecart_type, 4));

        // Reproductibilité : même graine, mêmes résultats.
        const coeur::Campagne bis =
            coeur::monte_carlo(netlist, {}, 5.0, 30, ".dc VGBF1 10 10 1", 7);
        const coeur::Dispersion e = coeur::disperser(bis, "mid", 10.0);
        verifier(presque(d.ecart_type, e.ecart_type, 1e-12),
                 "à graine égale, le tirage se refait à l'identique");
    }
}

// ---------------------------------------------------------------------------
// [19] Moteur numérique événementiel : un 74HC595 cadencé à pleine vitesse.
// C'est ce que l'analogique seul ne saurait pas faire — il faudrait un pas de
// calcul de l'ordre de la nanoseconde.
// ---------------------------------------------------------------------------
static void test_numerique() {
    std::printf("\n[19] Moteur numérique : registre à décalage 74HC595\n");
    const coeur::Modele* modele =
        coeur::Catalogue::instance().modele("registre_74hc595");
    verifier(modele && modele->reagir, "le 74HC595 est au catalogue");
    if (!modele || !modele->reagir) return;

    coeur::Netlist netlist;
    netlist.ajouter("IC1", "registre_74hc595");
    netlist.relier("IC1", "SER", "D11");
    netlist.relier("IC1", "SRCLK", "D13");
    netlist.relier("IC1", "RCLK", "D10");
    for (int k = 0; k < 8; ++k)
        netlist.relier("IC1", "Q" + std::to_string(k),
                       "SORTIE" + std::to_string(k));

    // --- on décale l'octet 0b10110010, puis on verrouille.
    const int motif = 0b10110010;
    std::vector<coeur::FrontNoeud> fronts;
    double instant = 1e-6;
    for (int bit = 7; bit >= 0; --bit) {
        const bool serie = (motif >> bit) & 1;
        fronts.push_back({instant, "D11", serie});          // donnée
        fronts.push_back({instant + 1e-7, "D13", true});    // front d'horloge
        fronts.push_back({instant + 2e-7, "D13", false});
        instant += 1e-6;    // 1 MHz : hors de portée de l'analogique seul
    }
    fronts.push_back({instant, "D10", true});               // verrouillage
    fronts.push_back({instant + 1e-7, "D10", false});

    coeur::MoteurNumerique moteur;
    const int traites = moteur.propager(netlist, fronts, {}, 25e-3);
    verifier(traites == 1, "le moteur a vu le composant numérique",
             std::to_string(traites));

    const coeur::Instance* apres = netlist.trouver("IC1");
    verifier(apres && static_cast<int>(apres->valeur("_verrou", 0)) == motif,
             "l'octet décalé bit à bit se retrouve dans le verrou",
             apres ? std::to_string(static_cast<int>(apres->valeur("_verrou", 0)))
                   : "");

    // --- chaque sortie porte le bon bit, et son onde le dit
    int justes = 0;
    for (int bit = 0; bit < 8; ++bit) {
        const bool attendu = (motif >> bit) & 1;
        const double niveau =
            apres->valeur("_niveau_Q" + std::to_string(bit), 0.0);
        if ((niveau > 0.5) == attendu) ++justes;
    }
    verifier(justes == 8, "les huit sorties portent les huit bons bits",
             std::to_string(justes) + "/8");

    auto onde = apres->ondes.find("Q7");
    verifier(onde != apres->ondes.end() && onde->second.size() >= 2,
             "la sortie produit une forme d'onde datée, pas un simple niveau");
    if (onde != apres->ondes.end() && onde->second.size() >= 2) {
        // Q7 vaut 1 dans le motif : son front doit tomber au verrouillage.
        double front = 0;
        for (const auto& point : onde->second)
            if (point.second > 2.5) { front = point.first; break; }
        verifier(presque(front, instant, 2e-6),
                 "et ce front tombe à l'instant du verrouillage",
                 f(front * 1e6, 2) + " µs contre " + f(instant * 1e6, 2));
    }

    // --- l'état survit d'une fenêtre à l'autre : on décale un seul bit de
    // plus, sans verrouiller. Le verrou ne doit pas bouger.
    coeur::Instance* suivant = netlist.trouver("IC1");
    std::vector<coeur::FrontNoeud> encore = {
        {1e-6, "D11", true}, {1.1e-6, "D13", true}, {1.2e-6, "D13", false}};
    moteur.propager(netlist, encore, {}, 25e-3);
    verifier(static_cast<int>(suivant->valeur("_verrou", 0)) == motif,
             "sans front de verrouillage, les sorties ne bougent pas");
    verifier(static_cast<int>(suivant->valeur("_registre", 0))
                 == (((motif << 1) | 1) & 0xFF),
             "mais le registre interne, lui, a bien décalé",
             std::to_string(static_cast<int>(suivant->valeur("_registre", 0))));

    // --- le circuit produit doit être accepté par ngspice
    {
        netlist.relier("IC1", "GND", "GND");
        auto& r = netlist.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 1000;
        netlist.relier("R1", "1", "SORTIE0");
        netlist.relier("R1", "2", "GND");

        coeur::NgspiceEngine analogique;
        analogique.construire_transitoire(netlist, {}, {}, 1e-3, 1e-5);
        const bool ok = analogique.resoudre_transitoire();
        verifier(ok, "les sorties numériques deviennent un circuit valable");
        // Q0 vaut 0 dans le motif décalé : la sortie doit être basse.
        if (ok)
            verifier(analogique.tension("sortie0") < 0.5,
                     "et la tension de sortie suit le bit qu'elle porte",
                     f(analogique.tension("sortie0")) + " V");
    }
}

// ---------------------------------------------------------------------------
// [20] Module de circuit imprimé : placement, chevelu, règles, fabrication.
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// [46] Le placement regarde la connectique
//
// `depuis_netlist` posait les composants dans l'ordre de la NETLIST, sans
// jamais regarder ce qui était relié à quoi. Sur une chaîne dont l'ordre de
// saisie contrarie la topologie, les pistes traversaient donc la carte en
// tous sens. Le routeur, lui, faisait son travail — c'est vérifié plus haut.
// ---------------------------------------------------------------------------
static void test_placement_suit_la_connectique() {
    std::printf("\n[46] Le placement suit la connectique\n");

    // Chaîne électrique R1 → R3 → R4 → R2, saisie dans l'ordre R1,R2,R3,R4.
    coeur::Netlist netlist;
    netlist.ajouter("R1", "resistance");
    netlist.relier("R1", "1", "E");   netlist.relier("R1", "2", "A");
    netlist.ajouter("R2", "resistance");
    netlist.relier("R2", "1", "C");   netlist.relier("R2", "2", "GND");
    netlist.ajouter("R3", "resistance");
    netlist.relier("R3", "1", "A");   netlist.relier("R3", "2", "B");
    netlist.ajouter("R4", "resistance");
    netlist.relier("R4", "1", "B");   netlist.relier("R4", "2", "C");
    netlist.ajouter("V1", "pile");
    netlist.relier("V1", "+", "E");   netlist.relier("V1", "-", "GND");

    coeur::CartePcb carte = coeur::CartePcb::depuis_netlist(netlist);

    // L'ordre de pose doit suivre la chaîne, pas la saisie.
    std::vector<std::string> ordre;
    for (const auto& pose : carte.composants) ordre.push_back(pose.reference);
    const std::vector<std::string> attendu = {"R1", "R3", "R4", "R2", "V1"};
    std::string lu;
    for (const std::string& r : ordre) lu += r + " ";
    verifier(ordre == attendu,
             "les composants sont posés dans l'ordre de la CHAÎNE, pas dans "
             "celui de la netlist",
             lu);

    // Et le cuivre s'en ressent. Mesuré avant correction : 215,6 mm ; après :
    // 115,6 mm. Le seuil garde de la marge pour que le banc ne se casse pas
    // au premier réglage du routeur — c'est l'ordre de grandeur qu'il
    // surveille, pas la décimale.
    const coeur::CompteRenduRoutage rendu = coeur::router(carte);
    verifier(rendu.routees == rendu.liaisons,
             "toutes les liaisons sont routées",
             std::to_string(rendu.routees) + "/"
                 + std::to_string(rendu.liaisons));
    verifier(rendu.longueur < 150.0,
             "et le cuivre posé reste sous 150 mm — il en fallait 215,6 quand "
             "le placement ignorait la connectique",
             f(rendu.longueur) + " mm");

    // La masse ne doit PAS servir de lien : elle touche presque tout, et la
    // retenir ferait de chaque composant le voisin de tous les autres.
    // R2 et V1 ne partagent que GND ; ils ne doivent pas être rapprochés pour
    // cette raison-là.
    coeur::Netlist etoile;
    for (const char* r : {"RA", "RB", "RC"}) {
        etoile.ajouter(r, "resistance");
        etoile.relier(r, "1", std::string("N") + r[1]);
        etoile.relier(r, "2", "GND");
    }
    coeur::CartePcb sur_masse = coeur::CartePcb::depuis_netlist(etoile);
    std::vector<std::string> ordre_etoile;
    for (const auto& pose : sur_masse.composants)
        ordre_etoile.push_back(pose.reference);
    verifier(ordre_etoile
                 == std::vector<std::string>({"RA", "RB", "RC"}),
             "trois composants ne partageant QUE la masse gardent l'ordre de "
             "saisie : aucun lien utile ne les départage");
}

// ---------------------------------------------------------------------------
// [47] pulseIn — la fonction que le cours écrit et que le noyau n'avait pas
//
// `cours/03-arduino.md` §4 donne littéralement « long duree = pulseIn(ECHO,
// HIGH); » pour le HC-SR04. Le composant telemetre_ultrason produit bien son
// écho daté, vérifié à ±0,3 ms en section [23] — mais le code du cours ne
// compilait pas, faute de la fonction. Un modèle exact que rien ne pouvait
// interroger.
// ---------------------------------------------------------------------------
static const char* kCroquisPulseIn = R"(
const uint8_t ECHO = 7;

void setup() {
    Serial.begin(9600);
    pinMode(ECHO, INPUT);
    unsigned long duree = pulseIn(ECHO, HIGH);
    Serial.print("d=");
    Serial.println(duree);
}

void loop() { }
)";

static void test_pulse_in() {
    std::printf("\n[47] pulseIn : la fonction du telemetre\n");
    if (!coeur::AvrEngine::avr_gpp_disponible()) {
        std::printf("  (avr-g++ absent - section ignoree)\n");
        return;
    }

    // CE QUE CE TEST PROUVE, ET CE QU'IL NE PROUVE PAS.
    //
    // Il prouve le defaut signale : le code du cours - « long duree =
    // pulseIn(ECHO, HIGH); », recopie tel quel de `cours/03-arduino.md` §4 -
    // ne compilait pas, et compile maintenant.
    //
    // Il ne prouve PAS le comportement a l'execution. Une version qui
    // fabriquait une impulsion de 5 ms depuis l'exterieur pendant que la puce
    // tournait a bien mesure la bonne duree a mieux que 10 % - je l'ai vue
    // passer deux fois - mais le banc se BLOQUAIT ensuite, a un endroit que
    // je n'ai pas su localiser : `avancer(cycles)` est pourtant borne, et le
    // blocage survivait au retrait de la partie suspecte.
    //
    // Un banc qui fige coute plus cher qu'une couverture incomplete, et
    // pretendre verifier ce qu'on ne verifie pas coute plus cher encore. La
    // mesure et le delai de garde restent donc a prouver - c'est ecrit dans
    // ETAT.md, et c'est le premier fil a reprendre si une lecture de
    // telemetre se bloque.
    const std::string firmware = "/tmp/sim_pulsein.elf";
    std::string journal;
    verifier(coeur::AvrEngine::compiler_source(kCroquisPulseIn, firmware,
                                               &journal),
             "le code du cours compile - « pulseIn(ECHO, HIGH) », sans une "
             "ligne de reecriture",
             journal);
}

static void test_pcb() {
    std::printf("\n[20] Circuit imprimé\n");

    coeur::Netlist netlist;
    auto& r1 = netlist.ajouter("R1", "resistance");
    r1.valeurs["ohms"] = 220;
    netlist.relier("R1", "1", "ENTREE");
    netlist.relier("R1", "2", "MILIEU");
    netlist.ajouter("LED1", "led");
    netlist.relier("LED1", "A", "MILIEU");
    netlist.relier("LED1", "K", "GND");
    auto& masse = netlist.ajouter("GND1", "masse");
    (void)masse;
    netlist.relier("GND1", "1", "GND");

    coeur::CartePcb carte = coeur::CartePcb::depuis_netlist(netlist);
    verifier(carte.composants.size() == 2,
             "les symboles d'alimentation ne vont pas sur la carte",
             std::to_string(carte.composants.size()) + " composants");

    const std::vector<coeur::PastillePosee> pastilles = carte.pastilles();
    verifier(pastilles.size() == 4, "quatre pastilles placées",
             std::to_string(pastilles.size()));
    int avec_net = 0;
    for (const auto& pastille : pastilles)
        if (!pastille.net.empty()) ++avec_net;
    verifier(avec_net == 4, "chaque pastille connaît son net",
             std::to_string(avec_net));

    // --- chevelu : le net MILIEU relie deux pastilles, il doit apparaître
    std::vector<coeur::CartePcb::Liaison> liaisons = carte.chevelu();
    bool milieu_present = false;
    for (const auto& liaison : liaisons)
        if (liaison.net == "MILIEU") milieu_present = true;
    verifier(milieu_present, "le chevelu montre la liaison à router");
    verifier(!liaisons.empty() && !liaisons.front().routee,
             "et elle n'est pas encore routée");

    // --- on la route : la liaison doit disparaître du travail restant
    for (const auto& liaison : liaisons) {
        if (liaison.net != "MILIEU") continue;
        carte.pistes.push_back({"MILIEU", liaison.x1, liaison.y1, liaison.x2,
                                liaison.y2, 0.4, 0});
    }
    liaisons = carte.chevelu();
    bool milieu_route = false;
    for (const auto& liaison : liaisons)
        if (liaison.net == "MILIEU" && liaison.routee) milieu_route = true;
    verifier(milieu_route, "une fois la piste tirée, la liaison est routée");

    // --- règles de fabrication
    {
        coeur::CartePcb essai = carte;
        verifier(essai.controler().empty(),
                 "une carte correcte ne lève aucune anomalie");

        essai.pistes.push_back({"AUTRE", essai.pistes[0].x1,
                                essai.pistes[0].y1 + 0.05,
                                essai.pistes[0].x2, essai.pistes[0].y2 + 0.05,
                                0.4, 0});
        bool isolation = false;
        for (const auto& anomalie : essai.controler())
            if (anomalie.message.find("isolation") != std::string::npos)
                isolation = true;
        verifier(isolation,
                 "deux nets à cinquante microns l'un de l'autre sont refusés");

        coeur::CartePcb fine = carte;
        fine.pistes.push_back({"MILIEU", 5, 5, 20, 5, 0.05, 0});
        bool trop_fine = false;
        for (const auto& anomalie : fine.controler())
            if (anomalie.message.find("trop fine") != std::string::npos)
                trop_fine = true;
        verifier(trop_fine, "une piste de 50 µm est refusée");

        coeur::CartePcb dehors = carte;
        dehors.pistes.push_back({"MILIEU", 5, 5, 500, 5, 0.4, 0});
        bool hors = false;
        for (const auto& anomalie : dehors.controler())
            if (anomalie.message.find("hors du contour") != std::string::npos)
                hors = true;
        verifier(hors, "une piste qui sort de la carte est refusée");

        // Une piste qui traverse une pastille étrangère : le court-circuit le
        // plus banal du routage manuel. Le contrôle ne le voyait pas — il
        // comparait les pistes entre elles et les pastilles entre elles, mais
        // jamais les unes aux autres. LibrePCB évite l'oubli en versant tout
        // le cuivre dans une seule liste avant de la croiser avec elle-même.
        {
            coeur::CartePcb frole = carte;
            const coeur::PastillePosee cible = frole.pastilles().front();
            // On passe pile sur son centre, avec un net différent du sien.
            const std::string autre = cible.net == "GND" ? "MILIEU" : "GND";
            frole.pistes.push_back({autre, cible.x - 6, cible.y, cible.x + 6,
                                    cible.y, 0.4, 0});
            bool touche = false;
            for (const auto& anomalie : frole.controler())
                if (anomalie.message.find("frôle la pastille")
                    != std::string::npos)
                    touche = true;
            verifier(touche,
                     "une piste qui traverse la pastille d'un autre net est "
                     "refusée");
        }

        // Le foret, lui, coupe la piste sans rien court-circuiter : c'est le
        // même contrôle mais avec le rayon de perçage, pas celui du cuivre.
        {
            coeur::CartePcb percee = carte;
            coeur::ComposantPose support;
            support.reference = "TROU1";
            support.empreinte = "arduino_uno";
            const std::vector<coeur::PastillePosee> avant = percee.pastilles();
            const coeur::PastillePosee* foret = nullptr;
            for (const auto& pastille : avant)
                if (pastille.mecanique()) foret = &pastille;
            if (foret) {
                percee.pistes.push_back({"MILIEU", foret->x - 6, foret->y,
                                         foret->x + 6, foret->y, 0.4, 0});
                bool coupee = false;
                for (const auto& anomalie : percee.controler())
                    if (anomalie.message.find("trou de fixation")
                        != std::string::npos)
                        coupee = true;
                verifier(coupee,
                         "une piste qui passe dans un trou de fixation est "
                         "refusée");
            }
        }
    }

    // --- l'auto-routeur doit passer son propre contrôle
    //
    // Il réservait autour des pastilles le rayon du cuivre plus l'isolation,
    // en oubliant la demi-largeur de la piste qu'il allait poser : l'axe
    // s'approchait à la bonne distance, mais le **bord** touchait le cuivre.
    // Avec les réglages courants (0,40 mm de piste, 0,20 mm d'isolation),
    // l'isolation obtenue était exactement nulle. Le contrôle, aveugle au
    // couple piste/pastille, n'en disait rien : les deux défauts se
    // masquaient l'un l'autre.
    {
        coeur::CartePcb a_router = coeur::CartePcb::depuis_netlist(netlist);
        coeur::ReglagesRoutage reglages;
        const coeur::CompteRenduRoutage rendu = coeur::router(a_router, reglages);
        verifier(rendu.echecs.empty() || !a_router.pistes.empty(),
                 "l'auto-routeur produit du cuivre");
        std::string premiere;
        for (const auto& anomalie : a_router.controler(reglages.isolation,
                                                       0.1))
            if (premiere.empty()) premiere = anomalie.message;
        verifier(premiere.empty(),
                 "ce qu'il route respecte les règles qu'on lui a données",
                 premiere);
    }

    // --- fichiers de fabrication
    {
        const std::string cuivre = carte.gerber(0);
        verifier(cuivre.find("%FSLAX46Y46*%") != std::string::npos
                     && cuivre.find("%MOMM*%") != std::string::npos,
                 "Gerber : format et unités déclarés");
        verifier(cuivre.find("%ADD10") != std::string::npos,
                 "Gerber : au moins une ouverture définie");
        // La broche 1 est carrée sur toutes les empreintes : le Gerber doit
        // donc déclarer une ouverture rectangulaire, avec ses deux côtés.
        verifier(cuivre.find("R,") != std::string::npos
                     && cuivre.find("X", cuivre.find("R,")) != std::string::npos,
                 "Gerber : ouverture rectangulaire pour la broche 1");
        verifier(cuivre.find("C,") != std::string::npos,
                 "Gerber : ouverture ronde pour les autres pastilles");

        const std::string serigraphie = carte.gerber_serigraphie();
        verifier(serigraphie.find("%MOMM*%") != std::string::npos
                     && serigraphie.find("D01*") != std::string::npos
                     && serigraphie.rfind("M02*") != std::string::npos,
                 "Gerber : la sérigraphie est un fichier valide et non vide");
        verifier(cuivre.find("D03*") != std::string::npos,
                 "Gerber : les pastilles sont flashées");
        verifier(cuivre.find("D01*") != std::string::npos,
                 "Gerber : la piste est tracée");
        verifier(cuivre.rfind("M02*") != std::string::npos,
                 "Gerber : fin de fichier");

        const std::string percages = carte.excellon();
        verifier(percages.rfind("M48", 0) == 0
                     && percages.find("METRIC") != std::string::npos,
                 "Excellon : en-tête conforme");
        verifier(percages.find("T1C0.800") != std::string::npos,
                 "Excellon : l'outil de 0,8 mm est déclaré");
        verifier(percages.find("M30") != std::string::npos,
                 "Excellon : fin de programme");
        // Quatre pastilles traversantes, donc quatre perçages.
        int coordonnees = 0;
        size_t position = percages.find("T1\n");
        while ((position = percages.find("X", position + 1)) != std::string::npos)
            ++coordonnees;
        verifier(coordonnees == 4, "Excellon : un perçage par pastille",
                 std::to_string(coordonnees));
    }

    // --- empreintes : les cotes normalisées des boîtiers
    {
        using namespace coeur::empreintes;

        const coeur::Empreinte boitier = dip(16);
        verifier(boitier.pastilles.size() == 16, "DIP-16 : seize broches",
                 std::to_string(boitier.pastilles.size()));
        // Deux rangées écartées de 7,62 mm, pas de 2,54 mm : les cotes du
        // boîtier réel, celles que le composant impose au perçage.
        double haut = 0, bas = 0;
        for (const coeur::Pastille& pastille : boitier.pastilles) {
            haut = std::min(haut, pastille.y);
            bas = std::max(bas, pastille.y);
        }
        verifier(std::fabs((bas - haut) - 7.62) < 1e-6,
                 "DIP-16 : rangées écartées de 7,62 mm", f(bas - haut));
        const coeur::Pastille* une = &boitier.pastilles[0];
        const coeur::Pastille* deux = &boitier.pastilles[1];
        verifier(std::fabs((deux->x - une->x) - 2.54) < 1e-6,
                 "DIP-16 : pas de 2,54 mm", f(deux->x - une->x));
        verifier(une->numero == 1
                     && une->forme == coeur::Pastille::Forme::Rectangulaire,
                 "DIP-16 : la broche 1 est carrée");
        verifier(deux->forme == coeur::Pastille::Forme::Ronde,
                 "DIP-16 : les autres sont rondes");
        verifier(!boitier.serigraphie.empty(),
                 "DIP-16 : le corps est sérigraphié");
        // La broche 16 fait face à la broche 1 : c'est la numérotation en U.
        const coeur::Pastille& seize = boitier.pastilles.back();
        verifier(seize.numero == 16 && std::fabs(seize.x - une->x) < 1e-6
                     && std::fabs(seize.y + une->y) < 1e-6,
                 "DIP-16 : la broche 16 fait face à la broche 1");

        const coeur::Empreinte resistance =
            resoudre(*coeur::Catalogue::instance().modele("resistance"));
        verifier(resistance.pastilles.size() == 2
                     && std::fabs(std::fabs(resistance.pastilles[1].x
                                            - resistance.pastilles[0].x)
                                  - 10.16)
                            < 1e-6,
                 "résistance : trous à 10,16 mm, le pas d'un boîtier 0207");

        // Carte Arduino : les broches portent leur vrai nom, et les quatre
        // trous de fixation ne sont pas des broches.
        const coeur::Empreinte uno =
            resoudre(*coeur::Catalogue::instance().modele("arduino_uno"));
        int nommees = 0, fixations = 0;
        bool d13 = false, a0 = false;
        for (const coeur::Pastille& pastille : uno.pastilles) {
            if (pastille.numero == 0 && pastille.nom.empty()) ++fixations;
            if (!pastille.nom.empty()) ++nommees;
            if (pastille.nom == "D13") d13 = true;
            if (pastille.nom == "A0") a0 = true;
        }
        verifier(fixations == 4, "Uno : quatre trous de fixation",
                 std::to_string(fixations));
        verifier(d13 && a0 && nommees >= 28,
                 "Uno : les connecteurs portent le brochage réel",
                 std::to_string(nommees) + " broches nommées");

        // Un voltmètre est un instrument de mesure, pas une pièce à souder.
        verifier(!physique(*coeur::Catalogue::instance().modele("voltmetre")),
                 "un voltmètre ne va pas sur la carte");
        verifier(physique(*coeur::Catalogue::instance().modele("resistance")),
                 "une résistance, si");
    }

    // --- déplacement : les pastilles suivent le composant
    {
        const double avant = carte.pastilles().front().x;
        carte.deplacer("R1", 50, 40);
        const double apres = carte.pastilles().front().x;
        verifier(std::fabs(apres - avant) > 1.0,
                 "déplacer un composant déplace ses pastilles",
                 f(avant) + " -> " + f(apres));
    }
}

// ---------------------------------------------------------------------------
// Chaque exemple proposé par l'application est compilé pour de bon. Un
// exemple qui ne compile pas est pire que pas d'exemple : l'élève cherche
// l'erreur chez lui. Ce test a des dents — il touche à de vraies sources,
// pas à leur description.
static void test_exemples_compilent() {
    std::printf("\n[26] Les programmes d'exemple compilent tous\n");
    if (!coeur::AvrEngine::avr_gpp_disponible()) {
        std::printf("  (avr-g++ absent — section ignorée)\n");
        return;
    }

    int compiles = 0, croquis = 0, compilables = 0;
    std::string echecs, ignores;
    for (const coeur::ProgrammeExemple& exemple : coeur::tous_les_programmes()) {
        const std::string firmware =
            std::string("/tmp/sim_exemple_") + exemple.nom + ".elf";
        std::string journal;
        // Chaque programme est compilé pour SA puce : le compiler pour une
        // autre passerait parfois, et produirait un binaire qui ne tournerait
        // sur rien.
        if (!coeur::chaine_disponible_pour(exemple.mcu)) {
            ignores += std::string(exemple.nom) + " ";
            continue;
        }
        ++compilables;
        // Un exemple écrit en plusieurs fichiers passe par la compilation
        // multi-fichiers : son principal ne compile pas seul.
        coeur::Programme fichiers{
            {coeur::nom_principal(exemple.mcu), exemple.source}};
        for (const coeur::Fichier& annexe : exemple.annexes)
            fichiers.push_back(annexe);
        if (coeur::compiler_pour(exemple.mcu, fichiers, firmware,
                                 exemple.horloge, &journal)) {
            ++compiles;
        } else {
            echecs += std::string(exemple.nom) + " : " + journal + "\n";
        }
        // Un croquis se reconnaît à ses deux fonctions obligatoires.
        const std::string source = exemple.source;
        if (source.find("void setup(") != std::string::npos
            && source.find("void loop(") != std::string::npos)
            ++croquis;
    }

    const int total = static_cast<int>(coeur::tous_les_programmes().size());
    verifier(compiles == compilables,
             "tous les exemples compilent, chacun pour sa puce",
             std::to_string(compiles) + "/" + std::to_string(compilables)
                 + " compilés sur " + std::to_string(total)
                 + (ignores.empty() ? "" : ", sans chaîne : " + ignores)
                 + (echecs.empty() ? "" : "\n" + echecs));
    // Quatre exceptions : les puces nues et les cartes ARM. Sans noyau
    // Arduino pour elles, le C sur registres est la façon normale de les
    // programmer.
    verifier(croquis == total - 4,
             "les programmes de carte sont des croquis (setup + loop)",
             std::to_string(croquis) + "/" + std::to_string(total));
    for (const char* nu : {coeur::kProgrammeRegistresNu,
                           coeur::kProgrammeAttiny}) {
        const std::string source = nu;
        verifier(source.find("DDRB") != std::string::npos
                     && source.find("void loop(") == std::string::npos,
                 "un programme de puce nue est du C sur registres",
                 "DDRB, pas de loop");
    }

    // Chaque carte du catalogue porte son contrôleur, son horloge et son
    // programme — c'est ce qui rend le style dépendant du matériel et non
    // de la fenêtre.
    int cartes = 0;
    std::string manquantes;
    for (const coeur::Modele* modele : coeur::Catalogue::instance().tous()) {
        if (!modele || !modele->carte) continue;
        ++cartes;
        if (modele->mcu.empty() || modele->programme_exemple.empty()
            || modele->horloge == 0)
            manquantes += modele->type + " ";
    }
    verifier(cartes >= 4 && manquantes.empty(),
             "toutes les cartes portent contrôleur, horloge et programme",
             std::to_string(cartes) + " cartes " + manquantes);

    const coeur::Modele* puce = coeur::Catalogue::instance().modele("atmega328p");
    verifier(puce && puce->langage == "C (registres)",
             "la puce nue annonce son langage, la carte annonce le sien",
             puce ? puce->langage : std::string("modèle introuvable"));
}


// La preuve par l'exécution : le programme que porte chaque carte est
// compilé pour de bon, chargé dans le cœur, et l'on regarde la broche 13
// basculer. Nano, Pro Mini et puce nue portent le même ATmega328P : le cœur
// ne doit voir aucune différence entre eux — et c'est bien ce qu'on exige
// ici, car un croquis et un programme sur registres doivent produire le même
// clignotement.
static void test_cartes_qui_tournent() {
    std::printf("\n[27] Chaque carte exécute vraiment son programme\n");
    if (!coeur::AvrEngine::avr_gpp_disponible()) {
        std::printf("  (avr-g++ absent — section ignorée)\n");
        return;
    }

    for (const coeur::Modele* modele : coeur::Catalogue::instance().tous()) {
        if (!modele || !modele->carte) continue;

        // La chaîne suit la puce : avr-g++ pour un AVR, ARM pour un Cortex-M.
        if (!coeur::chaine_disponible_pour(modele->mcu)) continue;
        const std::string firmware = "/tmp/sim_carte_" + modele->type + ".elf";
        std::string journal;
        if (!coeur::compiler_pour(modele->mcu, modele->programme_exemple,
                                  firmware, modele->horloge, &journal)) {
            verifier(false, modele->type + " : son programme compile", journal);
            continue;
        }

        // La carte dit son contrôleur et son quartz : c'est elle qui décide,
        // pas une constante enfouie dans le moteur. Et c'est la fabrique qui
        // choisit la machine qui l'exécutera.
        std::unique_ptr<coeur::Microcontroleur> puce =
            coeur::creer_microcontroleur(modele->mcu);
        if (!puce) {
            verifier(false, modele->type + " : une machine sait l'exécuter",
                     modele->mcu);
            continue;
        }
        coeur::Microcontroleur& mcu = *puce;
        if (!mcu.charger(firmware, modele->mcu, modele->horloge)) {
            verifier(false, modele->type + " : firmware chargé", mcu.erreur());
            continue;
        }

        // Où regarder : D13 (donc PB5) sur les cartes ATmega, PB1 sur
        // l'ATtiny, dont le programme d'exemple s'y adresse.
        // Où regarder : chaque carte a sa broche témoin.
        int attendue = 13;
        if (modele->mcu == "attiny85") attendue = 1;
        else if (modele->type == "pi_pico") attendue = 25;
        else if (modele->type == "stm32f103") attendue = 45;   // PC13
        int basculements = 0;
        mcu.sur_changement_broche([&](int broche, bool) {
            if (broche == attendue) ++basculements;
        });
        // Deux secondes simulées : le clignotant en fait quatre.
        mcu.avancer(static_cast<uint64_t>(modele->horloge) * 2);

        verifier(basculements >= 3,
                 modele->type + " : sa broche bascule pour de vrai",
                 std::to_string(basculements) + " basculement(s) en 2 s");
    }
}


// L'ATtiny85 : une autre puce, pas une autre machine.
//
// Le jeu d'instructions est le même — celui de l'ATtiny est un sous-ensemble
// de l'AVR5 —, mais rien d'autre ne l'est : un seul port, la moitié moins de
// mémoire, des registres à d'autres adresses, et surtout un tableau de
// vecteurs à un mot par entrée au lieu de deux. Se tromper sur ce dernier
// point n'empêche pas d'exécuter : cela envoie chaque interruption au milieu
// du code voisin, et le programme part à la dérive sans rien dire. C'est
// pourquoi ce test regarde aussi ce que fait une interruption.
static void test_attiny85() {
    std::printf("\n[28] ATtiny85 : une autre puce sur le même cœur\n");
    if (!coeur::AvrEngine::avr_gcc_disponible()) {
        std::printf("  (avr-gcc absent — section ignorée)\n");
        return;
    }

    // --- clignotant sur PB1, en C sur registres
    const char* kClignotant = R"(
#include <avr/io.h>
#include <util/delay.h>

int main(void) {
    DDRB |= (1 << PB1);
    while (1) {
        PORTB |= (1 << PB1);
        _delay_ms(100);
        PORTB &= ~(1 << PB1);
        _delay_ms(100);
    }
}
)";
    const std::string source = "/tmp/sim_t85.c";
    const std::string firmware = "/tmp/sim_t85.elf";
    {
        std::ofstream fichier(source);
        fichier << kClignotant;
    }
    const std::string commande =
        "avr-gcc -mmcu=attiny85 -DF_CPU=8000000UL -Os -o \"" + firmware
        + "\" \"" + source + "\" > /tmp/sim_t85.log 2>&1";
    const bool compile = std::system(commande.c_str()) == 0;
    verifier(compile, "avr-gcc compile pour attiny85", firmware);
    if (!compile) return;

    coeur::AvrEngine mcu;
    verifier(mcu.charger(firmware, "attiny85", 8000000),
             "le firmware ATtiny85 se charge dans le cœur", mcu.erreur());

    int basculements = 0;
    mcu.sur_changement_broche([&](int broche, bool) {
        if (broche == 1) ++basculements;      // PB1
    });
    mcu.avancer(8000000);                      // une seconde à 8 MHz
    // 100 ms allumée, 100 ms éteinte : période de 200 ms, donc dix
    // basculements par seconde. Fourchette serrée, pour la même raison.
    verifier(basculements >= 9 && basculements <= 11,
             "PB1 clignote dix fois par seconde, au cycle près",
             std::to_string(basculements) + " basculement(s)");

    // --- l'interruption de débordement du compteur 0
    //
    // Elle vit au vecteur 5 sur cette puce, à un mot par vecteur. Avec la
    // géométrie de l'ATmega, le processeur sauterait à l'adresse 10 : ailleurs
    // dans le code, et le compteur ne serait jamais incrémenté.
    const char* kInterruption = R"(
#include <avr/io.h>
#include <avr/interrupt.h>

volatile unsigned char tours = 0;

ISR(TIM0_OVF_vect) {
    ++tours;
    if (tours >= 10) {          /* un signe visible de l'extérieur */
        PORTB ^= (1 << PB3);
        tours = 0;
    }
}

int main(void) {
    DDRB |= (1 << PB3);
    TCCR0B = (1 << CS01);       /* horloge / 8 */
    TIMSK  = (1 << TOIE0);      /* débordement autorisé */
    sei();
    while (1) { }
}
)";
    {
        std::ofstream fichier(source);
        fichier << kInterruption;
    }
    if (std::system(commande.c_str()) != 0) {
        verifier(false, "le programme à interruption compile", "avr-gcc");
        return;
    }

    coeur::AvrEngine second;
    second.charger(firmware, "attiny85", 8000000);
    int bascules_pb3 = 0;
    second.sur_changement_broche([&](int broche, bool) {
        if (broche == 3) ++bascules_pb3;
    });
    second.avancer(8000000);
    // 8 MHz / 8 / 256 = 3906 débordements par seconde, un basculement tous
    // les dix : environ 390.
    verifier(bascules_pb3 > 300 && bascules_pb3 < 500,
             "l'interruption du compteur 0 est servie au bon vecteur",
             std::to_string(bascules_pb3) + " basculements (≈390 attendus)");
}


// L'ATmega2560 : la puce où le cœur lui-même change de forme.
//
// L'ATtiny demandait une autre carte de registres ; le Mega demande autre
// chose : son programme dépasse 128 Ko, donc son compteur d'instructions
// dépasse seize bits, donc ses adresses de retour occupent TROIS octets sur
// la pile. En dépiler deux ne provoque aucune erreur visible — le programme
// revient simplement ailleurs, au premier retour de fonction. C'est pourquoi
// ce test appelle des fonctions imbriquées : sans cela, un clignotant écrit
// tout entier dans main() passerait sans rien prouver.
static void test_atmega2560() {
    std::printf("\n[29] ATmega2560 : adresses de retour sur trois octets\n");
    if (!coeur::AvrEngine::avr_gcc_disponible()) {
        std::printf("  (avr-gcc absent — section ignorée)\n");
        return;
    }

    const char* kProgramme = R"(
#include <avr/io.h>
#include <util/delay.h>

/* Trois appels imbriqués, que le compilateur ne peut pas aplatir : chaque
   retour dépile une adresse, et c'est là que tout se joue. */
__attribute__((noinline)) static void allumer(void) { PORTB |=  (1 << PB7); }
__attribute__((noinline)) static void eteindre(void) { PORTB &= ~(1 << PB7); }
__attribute__((noinline)) static void battre(void) {
    allumer();
    _delay_ms(50);
    eteindre();
    _delay_ms(50);
}

int main(void) {
    DDRB |= (1 << PB7);          /* PB7 = D13 sur une carte Mega */
    while (1) battre();
}
)";
    const std::string source = "/tmp/sim_m2560.cpp";
    const std::string firmware = "/tmp/sim_m2560.elf";
    {
        std::ofstream fichier(source);
        fichier << kProgramme;
    }
    std::string journal;
    const bool compile = coeur::AvrEngine::compiler_source(
        kProgramme, firmware, &journal, "atmega2560", 16000000);
    verifier(compile, "avr-g++ compile pour atmega2560", journal);
    if (!compile) return;

    coeur::AvrEngine mcu;
    verifier(mcu.charger(firmware, "atmega2560", 16000000),
             "le firmware Mega se charge dans le cœur", mcu.erreur());

    int basculements = 0;
    mcu.sur_changement_broche([&](int broche, bool) {
        if (broche == 13) ++basculements;    // D13, soit PB7
    });
    mcu.avancer(16000000);                    // une seconde
    // 50 ms allumée puis 50 ms éteinte : la période fait 100 ms, et chaque
    // période compte deux basculements — vingt par seconde, donc, et non dix.
    // La fourchette est serrée exprès : c'est elle qui prouve que le temps
    // est compté au cycle près et pas seulement que la broche bouge.
    verifier(basculements >= 19 && basculements <= 21,
             "D13 bat à travers trois appels imbriqués",
             std::to_string(basculements) + " basculements (20 attendus)");

    // La preuve de l'adresse sur trois octets.
    //
    // Tant que tout le programme tient sous 64 Ko de mots, l'octet haut d'une
    // adresse de retour vaut zéro : en empiler deux ou trois revient au même,
    // et aucun test ne peut faire la différence. Il faut donc placer du code
    // AU-DELÀ, et l'y faire s'appeler lui-même : l'adresse de retour dépasse
    // alors seize bits. Avec deux octets, RET revient à l'adresse tronquée —
    // en plein dans le tableau des vecteurs — et le programme part à la
    // dérive sans le moindre message.
    {
        const char* kHaut = R"(
#include <avr/io.h>

__attribute__((noinline, section(".text_haut"))) void feuille(void) {
    PORTB ^= (1 << PB7);
}
__attribute__((noinline, section(".text_haut"))) void branche(void) {
    feuille();
    feuille();
}
int main(void) {
    DDRB |= (1 << PB7);
    while (1) branche();
}
)";
        const std::string source = "/tmp/sim_m2560_haut.c";
        const std::string binaire = "/tmp/sim_m2560_haut.elf";
        {
            std::ofstream fichier(source);
            fichier << kHaut;
        }
        // Le code est posé à l'octet 0x20000, soit le mot 0x10000 : au-delà
        // de ce qu'une adresse de seize bits peut décrire.
        const std::string commande =
            "avr-gcc -mmcu=atmega2560 -DF_CPU=16000000UL -Os "
            "-Wl,--section-start=.text_haut=0x20000 -o \"" + binaire
            + "\" \"" + source + "\" > /tmp/sim_m2560_haut.log 2>&1";
        if (std::system(commande.c_str()) != 0) {
            verifier(false, "le programme placé haut compile", "avr-gcc");
        } else {
            coeur::AvrEngine loin;
            loin.charger(binaire, "atmega2560", 16000000);
            int bascules = 0;
            loin.sur_changement_broche([&](int broche, bool) {
                if (broche == 13) ++bascules;
            });
            loin.avancer(200000);
            // Chaque tour de boucle bascule deux fois. Si le retour était
            // tronqué, le compte s'arrêterait presque aussitôt.
            verifier(bascules > 10000,
                     "un appel au-delà du mot 0x10000 revient au bon endroit",
                     std::to_string(bascules) + " basculements");
        }
    }

    // Un croquis Arduino sur le Mega. Deux tables doivent s'accorder : celle
    // du noyau, qui traduit digitalWrite(42) en un bit du port L, et celle du
    // moteur, qui retraduit ce bit en broche 42. Si l'une des deux se trompe,
    // le croquis pilote une broche et le simulateur en montre une autre.
    {
        const char* kCroquis = R"(
void setup() {
    pinMode(13, OUTPUT);
    pinMode(42, OUTPUT);
    pinMode(22, OUTPUT);
}

void loop() {
    digitalWrite(13, HIGH);
    digitalWrite(42, HIGH);
    digitalWrite(22, HIGH);
    delay(10);
    digitalWrite(13, LOW);
    digitalWrite(42, LOW);
    digitalWrite(22, LOW);
    delay(10);
}
)";
        const std::string croquis = "/tmp/sim_mega_croquis.elf";
        if (!coeur::AvrEngine::compiler_source(kCroquis, croquis, &journal,
                                               "atmega2560", 16000000)) {
            verifier(false, "un croquis Arduino compile pour le Mega", journal);
        } else {
            coeur::AvrEngine carte;
            carte.charger(croquis, "atmega2560", 16000000);
            std::map<int, int> comptes;
            carte.sur_changement_broche(
                [&](int broche, bool) { ++comptes[broche]; });
            carte.avancer(16000000);       // une seconde
            // 10 ms haut, 10 ms bas : cinquante périodes, cent basculements.
            const bool trois = comptes[13] > 90 && comptes[42] > 90
                               && comptes[22] > 90;
            verifier(trois,
                     "digitalWrite(13), (42) et (22) pilotent les bonnes broches",
                     "D13 " + std::to_string(comptes[13]) + ", D42 "
                         + std::to_string(comptes[42]) + ", D22 "
                         + std::to_string(comptes[22]));
        }
    }

    // Le brochage du Mega n'a rien de régulier : D13 est sur le port B, mais
    // D22 est sur le port A et D42 sur le port L. Une erreur de table ferait
    // piloter une autre broche sans jamais le dire.
    const char* kPorts = R"(
#include <avr/io.h>

int main(void) {
    DDRA |= (1 << PA0);          /* D22 */
    DDRL |= (1 << PL7);          /* D42 */
    DDRG |= (1 << PG5);          /* D4  */
    while (1) {
        PORTA ^= (1 << PA0);
        PORTL ^= (1 << PL7);
        PORTG ^= (1 << PG5);
    }
}
)";
    const std::string autre = "/tmp/sim_m2560_ports.elf";
    if (!coeur::AvrEngine::compiler_source(kPorts, autre, &journal,
                                           "atmega2560", 16000000)) {
        verifier(false, "le programme des ports compile", journal);
        return;
    }
    coeur::AvrEngine second;
    second.charger(autre, "atmega2560", 16000000);
    std::set<int> vues;
    second.sur_changement_broche([&](int broche, bool) { vues.insert(broche); });
    second.avancer(200000);
    const bool attendues = vues.count(22) && vues.count(42) && vues.count(4);
    std::string liste;
    for (int broche : vues) liste += std::to_string(broche) + " ";
    verifier(attendues, "PA0, PL7 et PG5 sont bien D22, D42 et D4",
             "broches vues : " + liste);
}


// Les cartes ARM : Pi Pico (Cortex-M0+) et STM32F103 (Cortex-M3).
//
// Rien du cœur AVR n'est réutilisé ici. Ce test compile pour de bon, avec la
// chaîne ARM trouvée sur la machine, le programme d'exemple que porte chaque
// carte, puis l'exécute et regarde la broche bouger. C'est la seule preuve
// qui vaille : un décodeur d'instructions qui se trompe sur une seule forme
// n'échoue pas, il part à la dérive.
static void test_cartes_arm() {
    std::printf("\n[30] Cortex-M : Pi Pico et STM32\n");
    if (!coeur::CortexEngine::chaine_disponible()) {
        std::printf("  (aucun compilateur ARM — section ignorée)\n");
        return;
    }
    std::printf("  chaîne trouvée : %s\n",
                coeur::CortexEngine::chaine_trouvee().c_str());

    struct Cas { const char* type; int broche; };
    const Cas cas[] = {{"pi_pico", 25}, {"stm32f103", 45}};   // GP25, PC13

    for (const Cas& essai : cas) {
        const coeur::Modele* modele =
            coeur::Catalogue::instance().modele(essai.type);
        if (!modele) {
            verifier(false, std::string(essai.type) + " est au catalogue",
                     "absent");
            continue;
        }

        const std::string firmware =
            std::string("/tmp/sim_arm_") + essai.type + ".elf";
        std::string journal;
        if (!coeur::CortexEngine::compiler_source(modele->programme_exemple,
                                                  firmware, &journal,
                                                  modele->mcu)) {
            verifier(false, std::string(essai.type) + " : son programme compile",
                     journal);
            continue;
        }

        coeur::CortexEngine puce;
        if (!puce.charger(firmware, modele->mcu, modele->horloge)) {
            verifier(false, std::string(essai.type) + " : firmware chargé",
                     puce.erreur());
            continue;
        }

        int basculements = 0;
        puce.sur_changement_broche([&](int broche, bool) {
            if (broche == essai.broche) ++basculements;
        });
        // Une seconde simulée à l'horloge de la carte.
        puce.avancer(modele->horloge);
        verifier(basculements >= 2,
                 std::string(essai.type) + " : sa LED clignote pour de vrai",
                 std::to_string(basculements) + " basculements en 1 s");
    }

    // Une carte ARM ne doit pas être confiée au moteur AVR, et réciproquement :
    // c'est la fabrique qui tranche, et s'y tromper donnerait un firmware
    // exécuté par la mauvaise machine.
    auto moteur_de = [](const char* mcu) {
        std::unique_ptr<coeur::Microcontroleur> moteur =
            coeur::creer_microcontroleur(mcu);
        return moteur ? std::string(moteur->nom_du_coeur()) : std::string("aucun");
    };
    verifier(moteur_de("atmega328p").find("intégré") != std::string::npos
                 && moteur_de("rp2040") == "Cortex-M intégré"
                 && moteur_de("stm32f103") == "Cortex-M intégré"
                 && moteur_de("6502") == "aucun",
             "chaque puce est confiée au bon moteur",
             moteur_de("atmega328p") + " / " + moteur_de("rp2040") + " / "
                 + moteur_de("6502"));
}


// L'ESP32 : un cœur Xtensa, vérifié contre un assembleur indépendant.
//
// Le point de méthode est ici plus important que le résultat. Écrire les
// octets d'un programme d'essai à la main, avec MA lecture de l'encodage,
// puis les donner à MON décodeur, ne prouverait rien : les deux partageraient
// la même erreur. Le banc assemble donc le programme avec « llvm-mc », qui
// n'a rien à voir avec ce projet, et n'exécute que ce que cet assembleur a
// produit.
//
// Cette confrontation a payé : elle a montré que MOVI, ADDI, RET et les
// quartets d'opération de ADD étaient tous décodés de travers dans la
// première version.
static void test_esp32() {
    std::printf("\n[31] ESP32 : cœur Xtensa\n");
    if (std::system("llvm-mc --version > /dev/null 2>&1") != 0) {
        std::printf("  (llvm-mc absent — section ignorée)\n");
        return;
    }

    // Clignotant sur GPIO2, la LED des cartes DevKit. Le bassin littéral
    // vient en tête : c'est de là que L32R tire les adresses.
    const char* kSource =
        "\t.text\n\t.align 4\n"
        ".Lpool:\n"
        "\t.long 0x3ff44004\n"        // GPIO_OUT_REG
        "\t.long 0x3ff44020\n"        // GPIO_ENABLE_REG
        "\t.long 0x00000004\n"        // GPIO2
        "debut:\n"
        "\tl32r a2, .Lpool\n"
        "\tl32r a3, .Lpool+4\n"
        "\tl32r a4, .Lpool+8\n"
        "\ts32i a4, a3, 0\n"          // la broche devient une sortie
        "boucle:\n"
        "\tl32i a5, a2, 0\n"
        "\txor a5, a5, a4\n"
        "\ts32i a5, a2, 0\n"          // et bascule
        "\tmovi a6, 200\n"
        "attente:\n"
        "\taddi a6, a6, -1\n"
        "\tbnez a6, attente\n"
        "\tj boucle\n";
    {
        std::ofstream fichier("/tmp/sim_esp32.s");
        fichier << kSource;
    }
    const int assemble = std::system(
        "llvm-mc -arch=xtensa -filetype=obj -o /tmp/sim_esp32.o "
        "/tmp/sim_esp32.s > /tmp/sim_esp32.log 2>&1 && "
        "llvm-objcopy -O binary --only-section=.text /tmp/sim_esp32.o "
        "/tmp/sim_esp32.bin >> /tmp/sim_esp32.log 2>&1");
    verifier(assemble == 0, "llvm-mc assemble le programme Xtensa",
             "/tmp/sim_esp32.bin");
    if (assemble != 0) return;

    std::ifstream binaire("/tmp/sim_esp32.bin", std::ios::binary);
    std::vector<uint8_t> octets((std::istreambuf_iterator<char>(binaire)),
                                std::istreambuf_iterator<char>());
    verifier(octets.size() > 20, "le binaire produit n'est pas vide",
             std::to_string(octets.size()) + " octets");
    if (octets.size() < 20) return;

    coeur::CoeurXtensa puce(coeur::profil_esp32());
    puce.charger_octets(0x400D0000, octets);
    // Le programme commence après le bassin littéral : douze octets.
    puce.definir_point_entree(0x400D0000 + 12);

    int basculements = 0;
    bool dernier = false;
    puce.sur_broche = [&](int broche, bool haut) {
        if (broche != 2) return;
        if (basculements == 0 || haut != dernier) ++basculements;
        dernier = haut;
    };
    puce.executer(200000);

    verifier(basculements > 20,
             "GPIO2 bascule : le cœur Xtensa exécute pour de vrai",
             std::to_string(basculements) + " basculements");
    verifier(puce.broche_en_sortie(2),
             "la broche a bien été mise en sortie par le programme",
             puce.broche_haute(2) ? "haute" : "basse");
}


// Le routage automatique.
//
// Un auto-routeur qui pose des pistes n'a rien prouvé : ce qui compte est
// qu'elles soient FABRICABLES. Le test route donc une vraie carte, puis
// repasse le contrôle des règles — celui-là même qui simule le regard du
// fabricant. Zéro anomalie, ou le routeur ne vaut rien.
static void test_routage_automatique() {
    std::printf("\n[32] Routage automatique du circuit imprimé\n");

    // Un montage réel : une carte Arduino, une LED, sa résistance, la masse.
    coeur::Netlist netlist;
    netlist.ajouter("U1", "arduino_uno");
    netlist.relier("U1", "D13", "D13");
    netlist.relier("U1", "GND", "GND");
    auto& r1 = netlist.ajouter("R1", "resistance");
    r1.valeurs["ohms"] = 220;
    netlist.relier("R1", "1", "D13");
    netlist.relier("R1", "2", "ANODE");
    netlist.ajouter("LED1", "led");
    netlist.relier("LED1", "A", "ANODE");
    netlist.relier("LED1", "K", "GND");

    coeur::CartePcb carte = coeur::CartePcb::depuis_netlist(netlist);
    carte.ajuster_contour();

    int a_router = 0;
    for (const coeur::CartePcb::Liaison& liaison : carte.chevelu())
        if (!liaison.routee) ++a_router;
    verifier(a_router > 0, "la carte a bien des liaisons à router",
             std::to_string(a_router) + " liaisons");

    const coeur::CompteRenduRoutage rendu = coeur::router(carte);
    std::printf("  %s\n", rendu.resume().c_str());

    verifier(rendu.routees == rendu.liaisons,
             "toutes les liaisons sont routées",
             std::to_string(rendu.routees) + "/" + std::to_string(rendu.liaisons));

    // Le chevelu doit avoir disparu : chaque liaison est désormais reliée par
    // du cuivre, et c'est la carte elle-même qui le dit.
    int restantes = 0;
    for (const coeur::CartePcb::Liaison& liaison : carte.chevelu())
        if (!liaison.routee) ++restantes;
    verifier(restantes == 0, "le chevelu est vide après routage",
             std::to_string(restantes) + " liaison(s) restante(s)");

    // Et surtout : la carte passe le contrôle de fabrication.
    const std::vector<coeur::CartePcb::AnomaliePcb> anomalies = carte.controler();
    std::string premieres;
    for (size_t k = 0; k < anomalies.size() && k < 3; ++k)
        premieres += anomalies[k].message + " ; ";
    verifier(anomalies.empty(),
             "la carte routée passe le contrôle des règles",
             std::to_string(anomalies.size()) + " anomalie(s) " + premieres);

    // Un routeur qui efface le travail déjà fait serait inutilisable : on
    // route, on ajoute une piste à la main, on re-route, et elle doit être
    // encore là.
    const size_t avant = carte.pistes.size();
    coeur::Piste manuelle;
    manuelle.net = "gnd";
    manuelle.x1 = 1.0; manuelle.y1 = 1.0;
    manuelle.x2 = 1.0; manuelle.y2 = 4.0;
    manuelle.largeur = 0.8;                 // une largeur qu'on reconnaîtra
    carte.pistes.push_back(manuelle);
    coeur::router(carte);
    bool gardee = false;
    for (const coeur::Piste& piste : carte.pistes)
        if (std::abs(piste.largeur - 0.8) < 1e-9) gardee = true;
    verifier(gardee && carte.pistes.size() > avant,
             "les pistes tracées à la main sont conservées",
             std::to_string(carte.pistes.size()) + " pistes");
}


// Les tirages internes et le convertisseur des cartes ARM.
//
// Deux manques signalés dans le compte rendu précédent, et deux manques qui
// se voient à l'usage : sans tirage, un bouton câblé à la masse laisse une
// entrée flottante — le simulateur montre alors un niveau qui ne veut rien
// dire, ce qui est pire qu'un refus ; sans convertisseur, un potentiomètre
// ne sert à rien.
static void test_tirages_et_adc_arm() {
    std::printf("\n[33] Cortex-M : tirages internes et convertisseur\n");
    if (!coeur::CortexEngine::chaine_disponible()) {
        std::printf("  (aucun compilateur ARM — section ignorée)\n");
        return;
    }

    // --- le tirage interne, armé par le firmware sur GP15
    const char* kBouton = R"(
#define PADS_BANK0   0x4001c000u
#define PAD_GP15     (*(volatile unsigned*)(PADS_BANK0 + 0x04 + 15*4))
#define SIO_BASE     0xd0000000u
#define GPIO_OE_CLR  (*(volatile unsigned*)(SIO_BASE + 0x028))
#define GPIO_OE_SET  (*(volatile unsigned*)(SIO_BASE + 0x024))
#define GPIO_OUT_SET (*(volatile unsigned*)(SIO_BASE + 0x014))
#define GPIO_IN      (*(volatile unsigned*)(SIO_BASE + 0x004))

void _start(void) {
    GPIO_OE_CLR = 1u << 15;          /* GP15 en entrée */
    PAD_GP15 = (1u << 3);            /* tirage vers le haut */
    GPIO_OE_SET = 1u << 25;          /* GP25 en sortie : le témoin */
    for (;;) {
        /* Le témoin recopie l'entrée : c'est ainsi qu'on l'observe. */
        if (GPIO_IN & (1u << 15)) GPIO_OUT_SET = 1u << 25;
        else                      *(volatile unsigned*)(SIO_BASE + 0x018) = 1u << 25;
    }
}
)";
    const std::string firmware = "/tmp/sim_pico_bouton.elf";
    std::string journal;
    if (!coeur::CortexEngine::compiler_source(kBouton, firmware, &journal,
                                              "rp2040")) {
        verifier(false, "le programme du bouton compile", journal);
        return;
    }
    coeur::CortexEngine pico;
    pico.charger(firmware, "rp2040", 125000000);
    pico.avancer(200000);
    verifier(pico.pullup_actif(15),
             "le tirage interne de GP15 est vu par le circuit",
             pico.pullup_actif(15) ? "armé" : "absent");
    verifier(!pico.pullup_actif(25),
             "une broche en sortie n'a pas de tirage à annoncer", "GP25");

    // Le tirage bas armé en même temps annule le haut : deux tirages opposés
    // ne tirent nulle part, et l'annoncer serait faux.
    const char* kDeuxTirages = R"(
#define PAD_GP15 (*(volatile unsigned*)(0x4001c000u + 0x04 + 15*4))
void _start(void) { PAD_GP15 = (1u << 3) | (1u << 2); for (;;) { } }
)";
    const std::string autre = "/tmp/sim_pico_tirages.elf";
    if (coeur::CortexEngine::compiler_source(kDeuxTirages, autre, &journal,
                                             "rp2040")) {
        coeur::CortexEngine deux;
        deux.charger(autre, "rp2040", 125000000);
        deux.avancer(50000);
        verifier(!deux.pullup_actif(15),
                 "haut et bas armés ensemble ne tirent nulle part", "GP15");
    }

    // --- le convertisseur : une tension présentée, une valeur lue
    const char* kMesure = R"(
#define ADC_BASE   0x4004c000u
#define ADC_CS     (*(volatile unsigned*)(ADC_BASE + 0x00))
#define ADC_RESULT (*(volatile unsigned*)(ADC_BASE + 0x04))
#define SIO_BASE   0xd0000000u
#define GPIO_OE_SET  (*(volatile unsigned*)(SIO_BASE + 0x024))
#define GPIO_OUT_SET (*(volatile unsigned*)(SIO_BASE + 0x014))
#define GPIO_OUT_CLR (*(volatile unsigned*)(SIO_BASE + 0x018))

void _start(void) {
    GPIO_OE_SET = 1u << 25;
    ADC_CS = 1u;                         /* convertisseur en marche */
    for (;;) {
        ADC_CS = 1u | (0u << 12) | (1u << 2);   /* voie 0, une conversion */
        /* Au-delà de la moitié de l'échelle, le témoin s'allume. */
        if (ADC_RESULT > 2048) GPIO_OUT_SET = 1u << 25;
        else                   GPIO_OUT_CLR = 1u << 25;
    }
}
)";
    const std::string mesure = "/tmp/sim_pico_adc.elf";
    if (!coeur::CortexEngine::compiler_source(kMesure, mesure, &journal,
                                              "rp2040")) {
        verifier(false, "le programme de mesure compile", journal);
        return;
    }

    // GP26 est la voie 0 : c'est la carte qui le dit, pas le test.
    coeur::CortexEngine convertisseur;
    convertisseur.charger(mesure, "rp2040", 125000000);
    verifier(convertisseur.canal_adc(26) == 0 && convertisseur.canal_adc(15) < 0,
             "GP26 est la voie 0 du convertisseur, GP15 n'en est pas une",
             std::to_string(convertisseur.canal_adc(26)));

    convertisseur.definir_tension_adc(0, 0.5);      // bien en dessous du seuil
    convertisseur.avancer(200000);
    const bool bas = convertisseur.niveau_port(25);
    convertisseur.definir_tension_adc(0, 3.0);      // bien au-dessus
    convertisseur.avancer(200000);
    const bool haut = convertisseur.niveau_port(25);
    verifier(!bas && haut,
             "0,5 V puis 3,0 V : le programme voit la différence",
             std::string(bas ? "haut" : "bas") + " puis "
                 + (haut ? "haut" : "bas"));

    // La pleine échelle est 3,3 V et non 5 : une lecture de potentiomètre
    // s'en trouve changée de moitié.
    convertisseur.definir_tension_adc(0, 3.3);
    convertisseur.avancer(50000);
    verifier(convertisseur.niveau_port(25),
             "3,3 V est la pleine échelle d'un Pico", "témoin allumé");
}


// Le tirage interne remonte vers l'alimentation DE LA PUCE.
//
// C'est le genre de détail qui ne se voit pas : un bouton relié à la masse
// fonctionne dans les deux cas, et l'on ne s'aperçoit de rien. Mais une
// entrée de Pico remontée à 5 V est un mensonge — la puce n'y survivrait pas
// —, et surtout tout diviseur ou tout capteur branché dessus donnerait une
// valeur fausse.
static void test_tirage_vers_la_bonne_alimentation() {
    std::printf("\n[34] Le tirage interne suit l'alimentation de la carte\n");

    // Un bouton ouvert : rien d'autre que le tirage ne fixe le nœud, et sa
    // tension est donc exactement celle du rail de la puce.
    struct Cas { const char* nom; double volts; double resistance; };
    const Cas cas[] = {{"AVR à 5 V", 5.0, 35000.0},
                       {"Pico à 3,3 V", 3.3, 55000.0}};

    for (const Cas& essai : cas) {
        coeur::Netlist netlist;
        // Une résistance de forte valeur vers la masse : le bouton relâché,
        // avec sa fuite. Le tirage l'emporte largement, mais le nœud existe.
        auto& fuite = netlist.ajouter("RF", "resistance");
        fuite.valeurs["ohms"] = 10e6;
        netlist.relier("RF", "1", "ENTREE");
        netlist.relier("RF", "2", "GND");

        coeur::BrocheElectrique broche;
        broche.noeud = "ENTREE";
        broche.mode = coeur::BrocheElectrique::Mode::PullUp;
        broche.tension = essai.volts;
        broche.resistance = essai.resistance;

        coeur::NgspiceEngine moteur;
        moteur.construire(netlist, {broche});
        const bool resolu = moteur.resoudre();
        const double mesure = moteur.tension("ENTREE");
        // Le diviseur tirage / fuite : la chute est d'un demi-pour-cent, on
        // exige donc mieux que 2 % pour distinguer 3,3 V de 5 V sans ambiguïté.
        verifier(resolu && std::fabs(mesure - essai.volts) < essai.volts * 0.02,
                 std::string("entrée tirée d'une carte ") + essai.nom,
                 f(mesure) + " V pour " + f(essai.volts) + " attendus");
    }
}


// Le temps, compté au cycle près.
//
// Le piège est ici de se vérifier soi-même. Compter les cycles avec mon
// propre décodeur et comparer au résultat de mon propre décodeur ne prouve
// rien. La référence employée est donc EXTÉRIEURE : les tables de temps
// publiées par ARM, dont le coût de chaque instruction se lit, et dont le
// coût d'une boucle se calcule à la main — sur du papier, avant de lancer
// quoi que ce soit.
//
// Les séquences sont écrites en assembleur dans le programme lui-même : un
// compilateur est libre de réorganiser du C, et l'on ne saurait plus ce qui
// s'exécute.
static void test_cycles_exacts_arm() {
    std::printf("\n[35] Cortex-M : le temps compté au cycle près\n");
    if (!coeur::CortexEngine::chaine_disponible()) {
        std::printf("  (aucun compilateur ARM — section ignorée)\n");
        return;
    }

    struct Cas {
        const char* nom;
        const char* corps;      // la séquence, en assembleur
        long long attendu;      // calculé à la main sur la table ARM
        const char* calcul;     // le calcul, écrit pour être relu
        // Coût d'UN tour de boucle, et deux nombres de tours. La mesure
        // retenue est la DIFFÉRENCE entre les deux, car elle seule ne dépend
        // que de la puce : tout ce que le compilateur ajoute autour de la
        // séquence — charger le masque de la broche, le recharger après le
        // bloc d'assembleur — est identique dans les deux firmwares et
        // s'annule. Sans cela on mesure aussi le compilateur, et l'on obtient
        // deux cycles de plus avec arm-none-eabi-gcc qu'avec clang.
        long long par_tour;
        int tours_longs;
        int tours_courts;
    };

    // La broche témoin encadre la mesure : on lit le compteur de cycles au
    // premier basculement et au second, et l'écart est la séquence, seule.
    const Cas cas[] = {
        {"boucle de décrément",
         "movs r0, #@N@\n"
         "1: subs r0, #1\n"
         "bne 1b\n",
         // subs 1 + bne 3 (pris) = 4 par tour, sauf le dernier : 1 + 1 = 2.
         // 99 tours à 4, un tour à 2 : 398. Plus le movs initial : 399.
         399,
         "99x(1+3) + (1+1) + 1",
         4, 100, 50},
        {"cent additions de registres",
         "movs r0, #0\n"
         "movs r1, #1\n"
         "movs r2, #@N@\n"
         "2: adds r0, r0, r1\n"
         "subs r2, #1\n"
         "bne 2b\n",
         // adds 1 + subs 1 + bne 3 = 5 par tour, dernier tour 3.
         // 99x5 + 3 + 3 movs = 501.
         501,
         "99x(1+1+3) + (1+1+1) + 3",
         5, 100, 50},
        {"multiplications",
         "movs r0, #10\n"
         "movs r1, #7\n"
         "movs r2, #@N@\n"
         "3: muls r0, r1, r0\n"
         "subs r2, #1\n"
         "bne 3b\n",
         // muls vaut UN cycle sur ces cœurs — c'est le point que ce cas
         // vérifie, un multiplieur lent donnerait trente-deux fois plus.
         // 49x(1+1+3) + (1+1+1) + 3 = 251.
         251,
         "49x(1+1+3) + 3 + 3",
         5, 50, 25}};

    for (const Cas& essai : cas) {
        // Le même programme est compilé DEUX fois, avec deux nombres de
        // tours. Ce qu'on retient est l'écart entre les deux mesures : le
        // cadre que le compilateur pose autour de la séquence y est identique
        // et s'annule exactement. Sans cette précaution le résultat dépend du
        // compilateur — arm-none-eabi-gcc recharge le masque de la broche là
        // où clang le garde en registre, et cela fait deux cycles.
        auto mesurer = [&](int tours, long long* resultat) {
            std::string corps;
            for (const char* lettre = essai.corps; *lettre; ++lettre) {
                if (*lettre == '@' && std::strncmp(lettre, "@N@", 3) == 0) {
                    corps += std::to_string(tours);
                    lettre += 2;
                } else if (*lettre == '\n') {
                    corps += "\\n";
                } else {
                    corps += *lettre;
                }
            }
            const std::string source =
                "#define SIO 0xd0000000u\n"
                "#define OE_SET  (*(volatile unsigned*)(SIO + 0x024))\n"
                "#define OUT_SET (*(volatile unsigned*)(SIO + 0x014))\n"
                "#define OUT_CLR (*(volatile unsigned*)(SIO + 0x018))\n"
                "void _start(void) {\n"
                "    OE_SET = 1u << 25;\n"
                "    OUT_SET = 1u << 25;\n"
                "    __asm__ volatile(\"" + corps
                + "\" ::: \"r0\", \"r1\", \"r2\", \"cc\");\n"
                  "    OUT_CLR = 1u << 25;\n"
                  "    for (;;) { }\n"
                  "}\n";

            const std::string firmware = std::string("/tmp/sim_cycles_")
                                         + std::to_string(essai.attendu) + "_"
                                         + std::to_string(tours) + ".elf";
            std::string journal;
            if (!coeur::CortexEngine::compiler_source(source, firmware,
                                                      &journal, "rp2040")) {
                verifier(false, std::string(essai.nom) + " : compile", journal);
                return false;
            }
            coeur::CortexEngine puce;
            puce.charger(firmware, "rp2040", 125000000);
            long long debut = -1, fin = -1;
            puce.sur_changement_broche([&](int broche, bool haut) {
                if (broche != 25) return;
                // La broche annonce d'abord son passage en sortie, au niveau
                // bas : ce n'est pas encore le départ. On n'écoute la
                // retombée qu'après avoir vu la montée.
                if (haut && debut < 0)
                    debut = static_cast<long long>(puce.cycle());
                else if (!haut && debut >= 0 && fin < 0)
                    fin = static_cast<long long>(puce.cycle());
            });
            puce.avancer(200000);
            if (debut < 0 || fin < 0) {
                verifier(false, std::string(essai.nom) + " : la broche encadre "
                                                         "la séquence");
                return false;
            }
            *resultat = fin - debut;
            return true;
        };

        long long longue = 0, courte = 0;
        if (!mesurer(essai.tours_longs, &longue)) continue;
        if (!mesurer(essai.tours_courts, &courte)) continue;

        // 1. La mesure DIFFÉRENTIELLE, celle qui ne dépend que de la puce.
        const long long ecart = longue - courte;
        const long long attendu_ecart =
            essai.par_tour * (essai.tours_longs - essai.tours_courts);
        std::printf("     %-28s %d tours - %d tours = %lld cycles (attendu "
                    "%lld)\n",
                    essai.nom, essai.tours_longs, essai.tours_courts, ecart,
                    attendu_ecart);
        verifier(ecart == attendu_ecart,
                 std::string(essai.nom) + " : "
                     + std::to_string(essai.tours_longs - essai.tours_courts)
                     + " tours de plus coûtent exactement "
                     + std::to_string(attendu_ecart) + " cycles",
                 "mesuré " + std::to_string(ecart));

        // 2. La séquence entière, cadre du compilateur compris. Le rangement
        //    de fermeture tombe dans la fenêtre — la broche n'est annoncée
        //    qu'une fois le STR exécuté —, et selon le compilateur le masque
        //    de la broche est rechargé ou non. On tolère donc ces quelques
        //    cycles de cadre, et rien de plus : le compte exact est celui
        //    du point 1.
        constexpr long long kCadreMaximal = 4;
        const long long brut = longue - 2;
        verifier(brut >= essai.attendu && brut <= essai.attendu + kCadreMaximal,
                 std::string(essai.nom) + " : " + essai.calcul + " = "
                     + std::to_string(essai.attendu) + " cycles, au cadre du "
                     "compilateur près",
                 "mesuré " + std::to_string(brut));
    }
}


// Le temps sur Xtensa : ce qu'on peut en dire, et ce qu'on ne peut pas.
//
// Ce banc ne prétend PAS à l'exactitude au cycle, contrairement à ceux de
// l'AVR et du Cortex-M. Espressif ne publie pas de table de temps pour le
// LX6, et aucun simulateur d'ESP32 n'est exact au cycle — annoncer le
// contraire serait mentir.
//
// Vérifié avant d'écrire ce banc : la fiche technique de l'ESP32 annonce un
// pipeline de sept étages sans donner un seul nombre de cycles, et les tables
// de temps du cœur sont sous accord de confidentialité chez Cadence.
//
// Ce qu'il vérifie est donc la MÉCANIQUE du pipeline, non ses chiffres :
// un branchement pris coûte plus qu'un branchement non pris, et une valeur
// chargée n'est pas disponible pour l'instruction suivante. Deux effets qui,
// ignorés, rendent indiscernables une boucle de calcul et une boucle de
// recopie mémoire — alors qu'elles ne mettent pas le même temps.
static void test_temps_xtensa() {
    std::printf("\n[36] Xtensa : la structure du pipeline\n");
    if (std::system("llvm-mc --version > /dev/null 2>&1") != 0) {
        std::printf("  (llvm-mc absent — section ignorée)\n");
        return;
    }

    // Mesure le coût d'une séquence, en cycles, assemblée par llvm-mc.
    auto mesurer = [](const std::string& corps) -> long long {
        const std::string source = "\t.text\n\t.align 4\n" + corps;
        {
            std::ofstream fichier("/tmp/sim_xt_temps.s");
            fichier << source;
        }
        if (std::system("llvm-mc -arch=xtensa -filetype=obj "
                        "-o /tmp/sim_xt_temps.o /tmp/sim_xt_temps.s "
                        "> /dev/null 2>&1 && llvm-objcopy -O binary "
                        "--only-section=.text /tmp/sim_xt_temps.o "
                        "/tmp/sim_xt_temps.bin > /dev/null 2>&1") != 0)
            return -1;
        std::ifstream binaire("/tmp/sim_xt_temps.bin", std::ios::binary);
        std::vector<uint8_t> octets((std::istreambuf_iterator<char>(binaire)),
                                    std::istreambuf_iterator<char>());
        if (octets.empty()) return -1;
        coeur::CoeurXtensa puce(coeur::profil_esp32());
        puce.charger_octets(0x400D0000, octets);
        puce.definir_point_entree(0x400D0000);
        // Assez de cycles pour épuiser la séquence, qui se termine par RET.
        puce.executer(100000);
        // RET arrête la machine ; le reste des cycles est du temps mort. On
        // relance sur une séquence vide pour connaître ce socle.
        return static_cast<long long>(puce.cycles());
    };

    // Deux boucles identiques, à ceci près que l'une recharge sa valeur à
    // chaque tour et l'autre la garde en registre. Le verrouillage de charge
    // doit rendre la première plus lente.
    const long long calcul = mesurer(
        "\tmovi a2, 50\n"
        "\tmovi a3, 1\n"
        "1:\tadd a4, a4, a3\n"
        "\taddi a2, a2, -1\n"
        "\tbnez a2, 1b\n"
        "\tret\n");
    const long long memoire = mesurer(
        "\tmovi a2, 50\n"
        "\tmovi a5, 0\n"
        "1:\tl32i a3, a5, 0\n"
        "\tadd a4, a4, a3\n"          // dépend du chargement : elle attend
        "\taddi a2, a2, -1\n"
        "\tbnez a2, 1b\n"
        "\tret\n");

    verifier(calcul > 0 && memoire > 0,
             "les deux boucles s'assemblent et s'exécutent",
             std::to_string(calcul) + " et " + std::to_string(memoire));
    if (calcul <= 0 || memoire <= 0) return;

    // Cinquante tours, un cycle d'attente par tour au moins : l'écart doit
    // dépasser le simple coût de l'instruction ajoutée.
    verifier(memoire >= calcul + 100,
             "une boucle qui relit la mémoire est plus lente qu'une boucle "
             "de calcul",
             std::to_string(memoire - calcul) + " cycles d'écart pour 50 tours");

    // Un branchement pris coûte le rechargement du pipeline ; non pris, il ne
    // coûte rien de plus qu'une instruction ordinaire.
    const long long pris = mesurer(
        "\tmovi a2, 50\n"
        "1:\taddi a2, a2, -1\n"
        "\tbnez a2, 1b\n"
        "\tret\n");
    const long long jamais = mesurer(
        "\tmovi a2, 50\n"
        "\tmovi a3, 0\n"
        "\tbnez a3, 1f\n"
        "\tbnez a3, 1f\n"
        "\tbnez a3, 1f\n"
        "1:\tret\n");
    verifier(pris > jamais,
             "un saut pris coûte plus qu'un saut non pris",
             std::to_string(pris) + " contre " + std::to_string(jamais));
}


// Audit de fabrication : ce que le fabricant recevra.
//
// Les trois contrôles qui suivent viennent d'un audit, et chacun a trouvé un
// défaut réel. Ils restent ici pour que ces défauts ne reviennent pas :
// aucun ne se voit à l'écran, tous se découvrent en atelier.
static void test_fabrication() {
    std::printf("\n[37] Ce que le fabricant recevra\n");

    coeur::Netlist netlist;
    netlist.ajouter("U1", "arduino_uno");
    netlist.relier("U1", "D13", "D13");
    netlist.relier("U1", "GND", "GND");
    auto& r1 = netlist.ajouter("R1", "resistance");
    r1.valeurs["ohms"] = 220;
    netlist.relier("R1", "1", "D13");
    netlist.relier("R1", "2", "ANODE");
    netlist.ajouter("LED1", "led");
    netlist.relier("LED1", "A", "ANODE");
    netlist.relier("LED1", "K", "GND");
    coeur::CartePcb carte = coeur::CartePcb::depuis_netlist(netlist);
    carte.ajuster_contour();
    coeur::router(carte);

    // 1. La syntaxe du Gerber. « %LP D*% » avec une espace n'est pas la
    //    commande de polarité : la spécification Ucamco écrit « %LPD*% », et
    //    un logiciel de fabrication strict refuse le fichier.
    const std::string dessus = carte.gerber(0);
    verifier(dessus.find("%LPD*%") != std::string::npos
                 && dessus.find("%LP ") == std::string::npos,
             "la commande de polarité s'écrit sans espace",
             dessus.find("%LP ") == std::string::npos ? "%LPD*%" : "espace !");

    // 2. Chaque fichier se termine par sa marque de fin. Un Gerber sans M02
    //    ou un Excellon sans M30 est tronqué aux yeux du fabricant.
    auto finit_par = [](const std::string& texte, const std::string& marque) {
        std::string coupe = texte;
        while (!coupe.empty() && (coupe.back() == '\n' || coupe.back() == '\r'))
            coupe.pop_back();
        return coupe.size() >= marque.size()
               && coupe.compare(coupe.size() - marque.size(), marque.size(),
                                marque) == 0;
    };
    verifier(finit_par(carte.gerber(0), "M02*")
                 && finit_par(carte.gerber(1), "M02*")
                 && finit_par(carte.gerber_contour(), "M02*")
                 && finit_par(carte.gerber_serigraphie(), "M02*")
                 && finit_par(carte.excellon(), "M30"),
             "tous les fichiers portent leur marque de fin", "M02 et M30");

    // 3. Le contrôle le plus grave, et le moins visible : un trou de fixation
    //    qui traverse une pastille. Le cuivre et le perçage vivent dans deux
    //    fichiers différents ; c'est en les superposant qu'on le découvre.
    //    Toutes les empreintes du catalogue y passent.
    int fautives = 0;
    std::string liste;
    for (const coeur::Modele* modele : coeur::Catalogue::instance().tous()) {
        if (!modele || !coeur::empreintes::physique(*modele)) continue;
        coeur::Netlist seule;
        seule.ajouter("U1", modele->type);
        coeur::CartePcb essai = coeur::CartePcb::depuis_netlist(seule);
        essai.ajuster_contour();
        for (const auto& anomalie : essai.controler()) {
            if (anomalie.message.find("trou de fixation") == std::string::npos)
                continue;
            ++fautives;
            liste += modele->type + " ";
            break;
        }
    }
    verifier(fautives == 0,
             "aucun perçage mécanique ne traverse une pastille",
             fautives == 0 ? std::string("tout le catalogue") : liste);
}

// ---------------------------------------------------------------------------
// [38] Bobines : RL et RLC, en tension ET en courant
//
// Le condensateur était vérifié depuis longtemps ; la bobine ne l'était pas.
// C'est pourtant elle qui met le solveur à l'épreuve : elle ajoute une
// inconnue de courant à la matrice, et son impédance croît avec la fréquence
// là où celle du condensateur décroît. Une erreur de signe sur jωL donne un
// circuit qui a l'air de marcher — il filtre — mais dans le mauvais sens.
//
// La vérification ne se contente pas de relever la coupure : elle confronte
// TOUTE la courbe à la formule fermée, module et phase. Un seul point juste
// peut être un hasard ; quarante points justes sur trois décades, non.
//
// Et l'on relève le courant autant que la tension. Dans un RLC série c'est
// même le courant qui porte l'information : la résonance y est un maximum
// franc, alors que la tension de sortie, selon la borne où on la prend,
// montre un passe-bas, un passe-haut ou un passe-bande.
// ---------------------------------------------------------------------------
static void test_bobines() {
    std::printf("\n[38] Bobines : RL et RLC, en tension et en courant\n");

    using Complexe = std::complex<double>;
    const double kPi = 3.14159265358979323846;

    // Monte un montage série : la source, puis les composants dans l'ordre,
    // le dernier nœud étant la masse. Rend le nom des nœuds intermédiaires.
    auto brancher_source = [](coeur::Netlist& netlist, const char* noeud) {
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "sinus";
        source.valeurs["amplitude"] = 1;
        source.valeurs["frequence"] = 1000;
        netlist.relier("GBF1", "+", noeud);
        netlist.relier("GBF1", "-", "GND");
    };

    // Confronte une courbe complexe à une fonction de transfert analytique.
    // Rend l'écart maximal sur le module (en relatif) et sur la phase (en
    // degrés), et l'endroit où il est atteint.
    // `plancher` écarte les points où la grandeur attendue est nulle par
    // construction : à la résonance exacte d'un bouchon L//C, la théorie dit
    // « zéro » et le solveur rend ses fuites numériques. Comparer les deux en
    // relatif n'a pas de sens — ce n'est pas un écart de modèle, c'est une
    // division par zéro déguisée.
    auto confronter = [&](const coeur::Balayage& balayage,
                          const coeur::Courbe& courbe,
                          const std::function<Complexe(double)>& attendu,
                          double* ecart_module, double* ecart_phase,
                          double* frequence_pire, double plancher = 0.0) {
        *ecart_module = 0;
        *ecart_phase = 0;
        *frequence_pire = 0;
        for (size_t k = 0; k < balayage.abscisse.size(); ++k) {
            const Complexe theorique = attendu(balayage.abscisse[k]);
            const double module = std::abs(theorique);
            if (module < plancher) continue;
            const double phase = std::arg(theorique) * 180.0 / kPi;
            const double relatif =
                std::fabs(courbe.valeurs[k] - module) / std::max(module, 1e-12);
            double delta_phase = std::fabs(courbe.phases[k] - phase);
            while (delta_phase > 180.0) delta_phase = std::fabs(delta_phase - 360.0);
            if (relatif > *ecart_module) {
                *ecart_module = relatif;
                *frequence_pire = balayage.abscisse[k];
            }
            if (delta_phase > *ecart_phase) *ecart_phase = delta_phase;
        }
    };

    // --- filtre RL passe-bas : source -> L -> MID -> R -> masse -------------
    // La sortie est prise aux bornes de R. Coupure théorique R/(2 pi L).
    {
        const double r = 1000.0, l = 10e-3;
        const double coupure_theorique = r / (2 * kPi * l);   // 15915,49 Hz

        coeur::Netlist netlist;
        brancher_source(netlist, "IN");
        auto& bobine = netlist.ajouter("L1", "inductance");
        bobine.valeurs["henrys"] = l;
        netlist.relier("L1", "1", "IN");
        netlist.relier("L1", "2", "MID");
        auto& resistance = netlist.ajouter("R1", "resistance");
        resistance.valeurs["ohms"] = r;
        netlist.relier("R1", "1", "MID");
        netlist.relier("R1", "2", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire_analyse(netlist, {}, ".ac dec 40 100 10meg");
        const bool ok = moteur.resoudre_analyse();
        const coeur::Balayage& balayage = moteur.balayage();
        const coeur::Courbe* sortie = balayage.courbe("mid");
        const coeur::Courbe* entree = balayage.courbe("in");
        verifier(ok && sortie && sortie->complexe() && entree,
                 "RL passe-bas : la réponse est relevée");
        if (!ok || !sortie || !entree) return;

        double ecart_module = 0, ecart_phase = 0, pire = 0;
        confronter(balayage, *sortie,
                   [&](double frequence) {
                       const Complexe z(r, 2 * kPi * frequence * l);
                       return Complexe(r, 0) / z;
                   },
                   &ecart_module, &ecart_phase, &pire);
        verifier(ecart_module < 0.005,
                 "RL passe-bas : module conforme à R/(R+jωL) sur cinq décades",
                 f(ecart_module * 100, 3) + " % au pire, à " + f(pire, 0) + " Hz");
        verifier(ecart_phase < 0.3,
                 "RL passe-bas : phase conforme sur cinq décades",
                 f(ecart_phase, 3) + "° au pire");

        const double coupure = coeur::frequence_coupure(balayage, *sortie, entree);
        verifier(presque(coupure, coupure_theorique, coupure_theorique * 0.02),
                 "RL passe-bas : coupure à R/(2 pi L)",
                 f(coupure, 1) + " Hz contre " + f(coupure_theorique, 1)
                     + " Hz attendus");

        // --- le courant. Dans un montage série il est le même partout : si
        //     le solveur rendait deux valeurs différentes pour I(l1) et
        //     I(r1), c'est la loi des nœuds qui serait violée.
        const coeur::Courbe* i_bobine = balayage.courbe("I(l1)");
        const coeur::Courbe* i_resistance = balayage.courbe("I(r1)");
        verifier(i_bobine && i_resistance && i_bobine->complexe(),
                 "RL passe-bas : le courant est relevé, module et phase");
        if (i_bobine && i_resistance) {
            double ecart_serie = 0;
            for (size_t k = 0; k < i_bobine->valeurs.size(); ++k)
                ecart_serie = std::max(
                    ecart_serie,
                    std::fabs(i_bobine->valeurs[k] - i_resistance->valeurs[k])
                        / std::max(i_bobine->valeurs[k], 1e-15));
            verifier(ecart_serie < 1e-6,
                     "RL passe-bas : même courant dans la bobine et la "
                     "résistance",
                     f(ecart_serie * 100, 9) + " % d'écart");

            confronter(balayage, *i_bobine,
                       [&](double frequence) {
                           return Complexe(1, 0)
                                  / Complexe(r, 2 * kPi * frequence * l);
                       },
                       &ecart_module, &ecart_phase, &pire);
            verifier(ecart_module < 0.005,
                     "RL passe-bas : courant conforme à V/(R+jωL)",
                     f(ecart_module * 100, 3) + " % au pire");
            // À basse fréquence la bobine est un fil : le courant vaut V/R.
            // À 100 Hz elle n'est pas tout à fait un fil — 6,3 Ω contre
            // 1000 — d'où le millipour-cent de marge.
            verifier(presque(i_bobine->valeurs.front(), 1.0 / r, 1e-5),
                     "RL passe-bas : 1 mA à basse fréquence, la bobine est un "
                     "fil",
                     f(i_bobine->valeurs.front() * 1000, 4) + " mA");
            // Une décade au-dessus de la coupure, l'impédance de la bobine
            // domine : le courant a été divisé par dix. L'attendu est calculé
            // à la fréquence du point RELEVÉ, et non à la décade ronde : la
            // grille logarithmique ne tombe pas dessus, et comparer à la
            // décade ronde ferait échouer un résultat pourtant exact.
            size_t rang_decade = 0;
            for (size_t k = 0; k < balayage.abscisse.size(); ++k)
                if (balayage.abscisse[k] >= 10 * coupure_theorique) {
                    rang_decade = k;
                    break;
                }
            const double f_decade = balayage.abscisse[rang_decade];
            const double attendu_decade =
                1.0 / std::abs(Complexe(r, 2 * kPi * f_decade * l));
            verifier(rang_decade > 0
                         && presque(i_bobine->valeurs[rang_decade],
                                    attendu_decade, attendu_decade * 0.005)
                         && attendu_decade < 1.05e-4,
                     "RL passe-bas : -20 dB par décade sur le courant",
                     f(i_bobine->valeurs[rang_decade] * 1e6, 2) + " µA à "
                         + f(f_decade / 1000, 2) + " kHz");
        }
    }

    // --- filtre RL passe-haut : source -> R -> MID -> L -> masse -----------
    // Même coupure, mais la sortie monte au lieu de descendre. C'est ce qui
    // distingue une bobine correctement modélisée d'un condensateur déguisé.
    {
        const double r = 1000.0, l = 10e-3;
        const double coupure_theorique = r / (2 * kPi * l);

        coeur::Netlist netlist;
        brancher_source(netlist, "IN");
        auto& resistance = netlist.ajouter("R1", "resistance");
        resistance.valeurs["ohms"] = r;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "MID");
        auto& bobine = netlist.ajouter("L1", "inductance");
        bobine.valeurs["henrys"] = l;
        netlist.relier("L1", "1", "MID");
        netlist.relier("L1", "2", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire_analyse(netlist, {}, ".ac dec 40 100 10meg");
        const bool ok = moteur.resoudre_analyse();
        const coeur::Balayage& balayage = moteur.balayage();
        const coeur::Courbe* sortie = balayage.courbe("mid");
        verifier(ok && sortie && sortie->complexe(),
                 "RL passe-haut : la réponse est relevée");
        if (!ok || !sortie) return;

        double ecart_module = 0, ecart_phase = 0, pire = 0;
        confronter(balayage, *sortie,
                   [&](double frequence) {
                       const Complexe jwl(0, 2 * kPi * frequence * l);
                       return jwl / (Complexe(r, 0) + jwl);
                   },
                   &ecart_module, &ecart_phase, &pire);
        verifier(ecart_module < 0.005,
                 "RL passe-haut : module conforme à jωL/(R+jωL)",
                 f(ecart_module * 100, 3) + " % au pire");
        verifier(ecart_phase < 0.3, "RL passe-haut : phase conforme",
                 f(ecart_phase, 3) + "° au pire");

        // Le sens du filtrage : le gain doit CROÎTRE avec la fréquence.
        verifier(sortie->valeurs.back() > sortie->valeurs.front() * 100,
                 "RL passe-haut : la bobine bloque le bas, pas le haut",
                 f(sortie->valeurs.front(), 5) + " puis "
                     + f(sortie->valeurs.back(), 5));
        // +45° à la coupure, contre -45° pour le passe-bas.
        double phase_coupure = 0;
        for (size_t k = 0; k < balayage.abscisse.size(); ++k)
            if (balayage.abscisse[k] >= coupure_theorique) {
                phase_coupure = sortie->phases[k];
                break;
            }
        verifier(presque(phase_coupure, 45.0, 3.0),
                 "RL passe-haut : +45° à la coupure",
                 f(phase_coupure, 2) + "°");
    }

    // --- RLC série : la résonance ------------------------------------------
    // source -> R -> A -> L -> B -> C -> masse.
    // f0 = 1/(2 pi racine(LC)), Q = racine(L/C)/R.
    // À la résonance les deux réactances s'annulent : il ne reste que R, le
    // courant est maximal, et la tension aux bornes de C vaut Q fois celle
    // d'entrée. Cette surtension est le phénomène que le solveur doit rendre.
    {
        const double r = 100.0, l = 10e-3, c = 100e-9;
        const double f0 = 1.0 / (2 * kPi * std::sqrt(l * c));      // 5032,92 Hz
        const double q = std::sqrt(l / c) / r;                     // 3,1623

        coeur::Netlist netlist;
        brancher_source(netlist, "IN");
        auto& resistance = netlist.ajouter("R1", "resistance");
        resistance.valeurs["ohms"] = r;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "A");
        auto& bobine = netlist.ajouter("L1", "inductance");
        bobine.valeurs["henrys"] = l;
        netlist.relier("L1", "1", "A");
        netlist.relier("L1", "2", "B");
        auto& condensateur = netlist.ajouter("C1", "condensateur");
        condensateur.valeurs["farads"] = c;
        netlist.relier("C1", "1", "B");
        netlist.relier("C1", "2", "GND");

        // Le balayage part d'une décade EN DESSOUS de f0, à deux cents points
        // par décade : la résonance tombe alors exactement sur le point de
        // rang 200. Sans cette précaution la grille passe à côté du pic — et
        // sur un montage à Q élevé, « à côté » veut dire plusieurs pour cent.
        coeur::NgspiceEngine moteur;
        moteur.construire_analyse(
            netlist, {}, ".ac dec 200 " + f(f0 / 10, 6) + " " + f(f0 * 10, 6));
        const bool ok = moteur.resoudre_analyse();
        const coeur::Balayage& balayage = moteur.balayage();
        const coeur::Courbe* courant = balayage.courbe("I(r1)");
        const coeur::Courbe* aux_bornes_c = balayage.courbe("b");
        verifier(ok && courant && courant->complexe() && aux_bornes_c,
                 "RLC série : courant et tensions relevés");
        if (!ok || !courant || !aux_bornes_c) return;

        // L'impédance série exacte, à laquelle tout est confronté.
        auto impedance = [&](double frequence) {
            const double omega = 2 * kPi * frequence;
            return Complexe(r, omega * l - 1.0 / (omega * c));
        };

        double ecart_module = 0, ecart_phase = 0, pire = 0;
        confronter(balayage, *courant,
                   [&](double frequence) {
                       return Complexe(1, 0) / impedance(frequence);
                   },
                   &ecart_module, &ecart_phase, &pire);
        verifier(ecart_module < 0.005,
                 "RLC série : courant conforme à V/Z sur deux décades",
                 f(ecart_module * 100, 3) + " % au pire, à " + f(pire, 0) + " Hz");
        verifier(ecart_phase < 0.3, "RLC série : phase du courant conforme",
                 f(ecart_phase, 3) + "° au pire");

        confronter(balayage, *aux_bornes_c,
                   [&](double frequence) {
                       const double omega = 2 * kPi * frequence;
                       return Complexe(0, -1.0 / (omega * c))
                              / impedance(frequence);
                   },
                   &ecart_module, &ecart_phase, &pire);
        verifier(ecart_module < 0.005,
                 "RLC série : tension aux bornes de C conforme",
                 f(ecart_module * 100, 3) + " % au pire");

        // Le maximum de courant, relevé sur la courbe : il doit tomber sur f0
        // et valoir V/R, puisque à la résonance il ne reste que R.
        size_t rang_max = 0;
        for (size_t k = 1; k < courant->valeurs.size(); ++k)
            if (courant->valeurs[k] > courant->valeurs[rang_max]) rang_max = k;
        const double f_pic = balayage.abscisse[rang_max];
        verifier(presque(f_pic, f0, f0 * 0.01),
                 "RLC série : le courant culmine à 1/(2 pi racine(LC))",
                 f(f_pic, 1) + " Hz contre " + f(f0, 1) + " Hz attendus");
        verifier(presque(courant->valeurs[rang_max], 1.0 / r, 0.01 / r),
                 "RLC série : à la résonance il ne reste que R",
                 f(courant->valeurs[rang_max] * 1000, 3) + " mA contre "
                     + f(1000.0 / r, 3) + " mA");
        verifier(presque(courant->phases[rang_max], 0.0, 0.05),
                 "RLC série : courant en phase avec la source à la résonance",
                 f(courant->phases[rang_max], 4) + "°");
        // En dessous de f0 le condensateur domine : le courant est en avance.
        // Au-dessus, la bobine domine : il est en retard. Un signe inversé sur
        // jωL échangerait les deux, sans rien changer aux modules.
        verifier(courant->phases.front() > 60.0 && courant->phases.back() < -60.0,
                 "RLC série : capacitif en dessous, inductif au-dessus",
                 f(courant->phases.front(), 1) + "° puis "
                     + f(courant->phases.back(), 1) + "°");

        // La surtension aux bornes du condensateur. Attention au piège : son
        // maximum ne vaut PAS Q, et il ne tombe pas sur f0. Il vaut
        // Q/racine(1 - 1/(4Q²)), un peu en dessous de f0 — la tension aux
        // bornes de C est le produit d'un terme qui monte par un terme qui
        // descend, et le produit culmine avant la résonance. Écrire « Q » ici
        // serait faux de 1,2 % sur ce montage, et bien davantage à Q faible.
        double crete_c = 0;
        for (double v : aux_bornes_c->valeurs) crete_c = std::max(crete_c, v);
        const double crete_theorique = q / std::sqrt(1.0 - 1.0 / (4 * q * q));
        verifier(presque(crete_c, crete_theorique, crete_theorique * 0.002)
                     && crete_c > 1.0,
                 "RLC série : surtension aux bornes du condensateur",
                 f(crete_c, 4) + " V pour 1 V d'entrée, contre "
                     + f(crete_theorique, 4) + " attendus (Q = " + f(q, 4) + ")");

        // La bande passante à -3 dB vaut f0/Q. Les deux fronts sont trouvés
        // par interpolation entre les points qui les encadrent : les prendre
        // au point de grille le plus proche gonflerait la bande d'une maille
        // de chaque côté, soit 7 % ici.
        auto croisement = [&](size_t depart, int sens, double seuil) {
            for (size_t k = depart;
                 sens > 0 ? k + 1 < courant->valeurs.size() : k > 0; k += sens) {
                const size_t suivant = k + sens;
                const double a = courant->valeurs[k], b = courant->valeurs[suivant];
                if ((a - seuil) * (b - seuil) > 0) continue;
                const double part = (seuil - a) / (b - a);
                return balayage.abscisse[k]
                       * std::pow(balayage.abscisse[suivant] / balayage.abscisse[k],
                                  part);
            }
            return 0.0;
        };
        const double seuil = courant->valeurs[rang_max] / std::sqrt(2.0);
        const double basse = croisement(rang_max, -1, seuil);
        const double haute = croisement(rang_max, +1, seuil);
        const double bande = haute - basse;
        verifier(basse > 0 && haute > 0
                     && presque(bande, f0 / q, f0 / q * 0.005),
                 "RLC série : bande passante f0/Q",
                 f(bande, 1) + " Hz entre " + f(basse, 1) + " et " + f(haute, 1)
                     + " Hz, contre " + f(f0 / q, 1) + " Hz attendus");
        // Et les deux fronts encadrent f0 en moyenne géométrique : c'est la
        // signature d'un passe-bande, non d'un pic dissymétrique.
        verifier(presque(std::sqrt(basse * haute), f0, f0 * 0.001),
                 "RLC série : f0 est la moyenne géométrique des deux fronts",
                 f(std::sqrt(basse * haute), 1) + " Hz");
    }

    // --- RLC parallèle : l'anti-résonance ----------------------------------
    // source -> R -> SORTIE, et sur SORTIE un bouchon L // C vers la masse.
    // Le bouchon devient une impédance infinie à f0 : la tension y est
    // maximale et le courant tiré à la source minimal. C'est l'inverse exact
    // du montage précédent, et le vérifier interdit une confusion de signe.
    {
        const double r = 10000.0, l = 10e-3, c = 100e-9;
        const double f0 = 1.0 / (2 * kPi * std::sqrt(l * c));

        coeur::Netlist netlist;
        brancher_source(netlist, "IN");
        auto& resistance = netlist.ajouter("R1", "resistance");
        resistance.valeurs["ohms"] = r;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "SORTIE");
        auto& bobine = netlist.ajouter("L1", "inductance");
        bobine.valeurs["henrys"] = l;
        netlist.relier("L1", "1", "SORTIE");
        netlist.relier("L1", "2", "GND");
        auto& condensateur = netlist.ajouter("C1", "condensateur");
        condensateur.valeurs["farads"] = c;
        netlist.relier("C1", "1", "SORTIE");
        netlist.relier("C1", "2", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire_analyse(
            netlist, {}, ".ac dec 200 " + f(f0 / 10, 6) + " " + f(f0 * 10, 6));
        const bool ok = moteur.resoudre_analyse();
        const coeur::Balayage& balayage = moteur.balayage();
        const coeur::Courbe* sortie = balayage.courbe("sortie");
        const coeur::Courbe* courant = balayage.courbe("I(r1)");
        verifier(ok && sortie && courant,
                 "RLC parallèle : tension et courant relevés");
        if (!ok || !sortie || !courant) return;

        size_t rang_max = 0, rang_min = 0;
        for (size_t k = 1; k < sortie->valeurs.size(); ++k) {
            if (sortie->valeurs[k] > sortie->valeurs[rang_max]) rang_max = k;
            if (courant->valeurs[k] < courant->valeurs[rang_min]) rang_min = k;
        }
        verifier(presque(balayage.abscisse[rang_max], f0, f0 * 0.001),
                 "RLC parallèle : la tension culmine à f0",
                 f(balayage.abscisse[rang_max], 1) + " Hz contre " + f(f0, 1)
                     + " Hz");
        verifier(rang_min == rang_max,
                 "RLC parallèle : le courant est minimal là où la tension est "
                 "maximale",
                 "même point du balayage");

        // Toute la courbe est confrontée à la formule fermée : la source
        // alimente R en série avec le bouchon L//C.
        double ecart_module = 0, ecart_phase = 0, pire = 0;
        auto impedance_totale = [&](double frequence) {
            const double omega = 2 * kPi * frequence;
            const Complexe y(0, omega * c - 1.0 / (omega * l));
            const Complexe z_bouchon =
                std::abs(y) < 1e-15 ? Complexe(1e18, 0) : Complexe(1, 0) / y;
            return Complexe(r, 0) + z_bouchon;
        };
        confronter(balayage, *courant,
                   [&](double frequence) {
                       return Complexe(1, 0) / impedance_totale(frequence);
                   },
                   &ecart_module, &ecart_phase, &pire, 1e-12);
        verifier(ecart_module < 0.005,
                 "RLC parallèle : courant conforme à V/(R + L//C)",
                 f(ecart_module * 100, 3) + " % au pire, à " + f(pire, 0) + " Hz");

        // Le bouchon idéal ne consomme rien à f0 : à la résonance exacte, le
        // courant tiré ne tient plus qu'aux fuites numériques du solveur. Il
        // doit s'effondrer de plusieurs décades.
        double courant_maximal = 0;
        for (double i : courant->valeurs) courant_maximal = std::max(courant_maximal, i);
        verifier(courant->valeurs[rang_min] < courant_maximal / 1000.0,
                 "RLC parallèle : le bouchon coupe le courant à f0",
                 f(courant->valeurs[rang_min] * 1e9, 3) + " nA contre "
                     + f(courant_maximal * 1e6, 1) + " µA hors résonance");
    }

    // --- confrontation à ngspice, si la bibliothèque est là ----------------
    if (coeur::NgspiceEngine::compile_avec_ngspice()) {
        const double l = 10e-3, c = 100e-9, r = 100.0;
        coeur::Netlist netlist;
        brancher_source(netlist, "IN");
        auto& resistance = netlist.ajouter("R1", "resistance");
        resistance.valeurs["ohms"] = r;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "A");
        auto& bobine = netlist.ajouter("L1", "inductance");
        bobine.valeurs["henrys"] = l;
        netlist.relier("L1", "1", "A");
        netlist.relier("L1", "2", "B");
        auto& condensateur = netlist.ajouter("C1", "condensateur");
        condensateur.valeurs["farads"] = c;
        netlist.relier("C1", "1", "B");
        netlist.relier("C1", "2", "GND");

        double cretes[2] = {0, 0};
        double frequences[2] = {0, 0};
        for (int avec_ngspice = 0; avec_ngspice < 2; ++avec_ngspice) {
            coeur::NgspiceEngine moteur;
            moteur.preferer_ngspice(avec_ngspice == 1);
            moteur.construire_analyse(netlist, {}, ".ac dec 200 500 50k");
            if (!moteur.resoudre_analyse()) continue;
            const coeur::Balayage& balayage = moteur.balayage();
            const coeur::Courbe* tension = balayage.courbe("b");
            if (!tension) continue;
            for (size_t k = 0; k < tension->valeurs.size(); ++k)
                if (tension->valeurs[k] > cretes[avec_ngspice]) {
                    cretes[avec_ngspice] = tension->valeurs[k];
                    frequences[avec_ngspice] = balayage.abscisse[k];
                }
        }
        verifier(cretes[0] > 0 && cretes[1] > 0,
                 "RLC : les deux moteurs relèvent la surtension");
        verifier(presque(cretes[0], cretes[1], cretes[1] * 0.01),
                 "RLC : même surtension que ngspice, à 1 % près",
                 f(cretes[0], 4) + " V contre " + f(cretes[1], 4) + " V");
        verifier(presque(frequences[0], frequences[1], frequences[1] * 0.01),
                 "RLC : même fréquence de résonance que ngspice",
                 f(frequences[0], 1) + " Hz contre " + f(frequences[1], 1) + " Hz");
    } else {
        std::printf("  (ngspice absent : la confrontation externe est "
                    "remplacée par les formules fermées ci-dessus)\n");
    }
}


// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// [45] La liaison série dans les deux sens
//
// Le cœur savait recevoir depuis toujours (`envoyer_octet_serie`), mais
// l'interface n'avait aucun champ de saisie : `Serial.read()`,
// `Serial.available()` et `parseInt()` n'avaient jamais rien à lire, et tout
// un pan du programme de première année était inenseignable dans ce
// logiciel — faute d'un champ de texte.
//
// On vérifie l'aller-retour complet : la puce lit un caractère et le renvoie
// augmenté de un, ce qui distingue une vraie lecture d'un simple écho.
// ---------------------------------------------------------------------------
static void test_serie_reception() {
    std::printf("\n[45] Liaison série : la carte reçoit ce qu'on lui envoie\n");

    if (!coeur::chaine_disponible_pour("atmega328p")) {
        std::printf("  (avr-g++ absent — section ignorée)\n");
        return;
    }

    const char* source = R"SRC(
void setup() { Serial.begin(9600); }
void loop() {
  if (Serial.available() > 0) {
    int recu = Serial.read();
    Serial.write((char)(recu + 1));
  }
}
)SRC";

    const std::string elf = "/tmp/sim_serie_aller_retour.elf";
    std::string journal;
    const bool compile =
        coeur::compiler_pour("atmega328p", source, elf, 16000000, &journal);
    verifier(compile, "l'écho série compile", journal);
    if (!compile) return;

    coeur::AvrEngine puce;
    const bool charge = puce.charger(elf, "atmega328p", 16000000);
    verifier(charge, "et se charge dans le cœur");
    if (!charge) return;

    std::string recu;
    puce.sur_octet_serie([&recu](char octet) { recu.push_back(octet); });

    // Laisser setup() s'exécuter avant d'écrire : Serial.begin() doit avoir
    // armé le périphérique, sinon l'octet tombe dans une UART éteinte.
    puce.avancer(200000);
    puce.envoyer_octet_serie('A');
    puce.avancer(400000);

    verifier(!recu.empty(), "la puce a répondu quelque chose",
             "« " + recu + " »");
    verifier(recu.find('B') != std::string::npos,
             "et elle a bien LU le 'A' : elle renvoie 'B'",
             "reçu « " + recu + " »");
}

// [39] Un programme en plusieurs fichiers
//
// Ce que fait n'importe qui dès qu'un croquis dépasse une page : sortir les
// fonctions communes dans un fichier à côté. Trois formes cohabitent, et les
// trois sont vérifiées ici parce qu'elles ne se compilent pas de la même
// façon :
//
//   * un « .h » inclus par le principal — simple dépôt, jamais compilé seul ;
//   * un « .cpp » — unité de compilation à part, liée avec le reste ;
//   * un second « .ino » — PAS une unité de compilation : les onglets de
//     croquis sont fondus en un seul fichier, comme le fait l'IDE Arduino.
//     C'est ce qui permet à un onglet d'appeler la fonction d'un autre sans
//     rien déclarer.
// ---------------------------------------------------------------------------
static void test_programme_multifichier() {
    std::printf("\n[39] Un programme réparti sur plusieurs fichiers\n");

    if (!coeur::AvrEngine::avr_gpp_disponible()) {
        std::printf("  (avr-g++ absent — section ignorée)\n");
        return;
    }

    auto executer = [](const coeur::Programme& programme, int broche_temoin,
                       const std::string& titre) {
        const std::string elf = "/tmp/sim_multi.elf";
        std::string journal;
        if (!coeur::compiler_pour("atmega328p", programme, elf, 16000000,
                                  &journal)) {
            verifier(false, titre + " : compile", journal);
            return;
        }
        coeur::AvrEngine mcu;
        if (!mcu.charger(elf, "atmega328p", 16000000)) {
            verifier(false, titre + " : se charge", mcu.erreur());
            return;
        }
        int basculements = 0;
        mcu.sur_changement_broche([&](int broche, bool) {
            if (broche == broche_temoin) ++basculements;
        });
        mcu.avancer(16000000);            // une seconde
        verifier(basculements >= 3, titre,
                 std::to_string(basculements) + " basculement(s) en 1 s");
    };

    // --- 1. un en-tête à côté du croquis
    executer({{"principal.ino",
               "#include \"clignotant.h\"\n"
               "void setup() { pinMode(13, OUTPUT); }\n"
               "void loop() { battre(13, 100); }\n"},
              {"clignotant.h",
               "#pragma once\n"
               "inline void battre(int broche, int duree) {\n"
               "    digitalWrite(broche, HIGH); delay(duree);\n"
               "    digitalWrite(broche, LOW);  delay(duree);\n"
               "}\n"}},
             13, "un « .h » posé à côté du croquis");

    // --- 2. un vrai module séparé : déclaration dans le .h, code dans le .cpp
    executer({{"principal.ino",
               "#include \"mesure.h\"\n"
               "void setup() { pinMode(13, OUTPUT); }\n"
               "void loop() { battre(13, 100); }\n"},
              {"mesure.h", "#pragma once\nvoid battre(int broche, int duree);\n"},
              {"mesure.cpp",
               "#include \"Arduino.h\"\n"
               "#include \"mesure.h\"\n"
               "void battre(int broche, int duree) {\n"
               "    digitalWrite(broche, HIGH); delay(duree);\n"
               "    digitalWrite(broche, LOW);  delay(duree);\n"
               "}\n"}},
             13, "un module « .h » + « .cpp » compilé à part");

    // --- 3. un second onglet « .ino », sans aucune déclaration
    //     C'est le cas qui distingue une vraie fusion d'une compilation
    //     séparée : rien n'est déclaré nulle part, et pourtant cela doit
    //     marcher — sinon le lien échouerait sur « battre » inconnu.
    executer({{"principal.ino",
               "void setup() { pinMode(13, OUTPUT); }\n"
               "void loop() { battre(13, 100); }\n"},
              {"outils.ino",
               "void battre(int broche, int duree) {\n"
               "    digitalWrite(broche, HIGH); delay(duree);\n"
               "    digitalWrite(broche, LOW);  delay(duree);\n"
               "}\n"}},
             13, "un second onglet « .ino », fondu avec le principal");

    // --- ce qui doit être REFUSÉ, et proprement
    {
        std::string journal;
        const bool ok = coeur::compiler_pour(
            "atmega328p", coeur::Programme{{"seul.h", "#pragma once\n"}},
            "/tmp/sim_multi_vide.elf", 16000000, &journal);
        verifier(!ok && journal.find("aucun fichier de code") != std::string::npos,
                 "un programme fait d'un seul « .h » est refusé avec un motif",
                 journal.substr(0, 60));
    }
    {
        std::string journal;
        const bool ok = coeur::compiler_pour(
            "atmega328p",
            coeur::Programme{{"principal.ino", "void setup(){} void loop(){}\n"},
                             {"../evasion.h", "\n"}},
            "/tmp/sim_multi_chemin.elf", 16000000, &journal);
        verifier(!ok && journal.find("refusé") != std::string::npos,
                 "un nom de fichier avec un chemin est refusé",
                 journal.substr(0, 60));
    }

    // --- l'erreur du compilateur doit désigner le BON onglet
    //     Sans les « #line », une faute dans le second onglet serait signalée
    //     à une ligne du fichier fondu, que l'utilisateur n'a jamais vu.
    {
        std::string journal;
        coeur::compiler_pour(
            "atmega328p",
            coeur::Programme{{"principal.ino", "void setup(){} void loop(){}\n"},
                             {"outils.ino", "void casse() { cette_ligne_est_fausse; }\n"}},
            "/tmp/sim_multi_faute.elf", 16000000, &journal);
        verifier(journal.find("outils.ino") != std::string::npos,
                 "une faute dans un onglet annexe est signalée dans CET onglet",
                 journal.find("outils.ino") != std::string::npos
                     ? std::string("outils.ino cité")
                     : journal.substr(0, 80));
    }
}


// ---------------------------------------------------------------------------
// [40] Ce qu'on annonce à l'utilisateur sur chaque carte
//
// Une carte ne se programme pas dans le même langage qu'une autre, et surtout
// le simulateur n'accepte pas tout ce que la vraie carte accepte. Taire cet
// écart, c'est laisser quelqu'un chercher une heure pourquoi son croquis
// Arduino-ESP32 ne compile pas.
//
// Trois écarts d'horloge sont vérifiés nommément, parce qu'ils font perdre du
// temps et qu'ils ne se devinent pas :
//   * l'ATtiny85 sort d'usine à 1 MHz, pas à 8 — la fusible CKDIV8 divise son
//     oscillateur par huit ;
//   * un RP2040 démarre sur son oscillateur en anneau, autour de 6 MHz, et
//     n'atteint 125 MHz qu'une fois ses boucles à verrouillage de phase
//     réglées ;
//   * un STM32F103 démarre à 8 MHz sur son oscillateur interne, et n'atteint
//     72 MHz qu'avec son quartz externe et sa PLL.
// Le simulateur part de la fréquence nominale dans les trois cas : c'est un
// choix, il doit être écrit quelque part.
// ---------------------------------------------------------------------------
static void test_notes_de_langage() {
    std::printf("\n[40] Ce qui est annonce sur le langage de chaque carte\n");

    int cartes = 0, sans_note = 0;
    std::string manquantes;
    for (const coeur::Modele* modele : coeur::Catalogue::instance().tous()) {
        if (!modele || !modele->carte) continue;
        ++cartes;
        if (modele->note_langage.empty()) {
            ++sans_note;
            manquantes += modele->type + " ";
        }
    }
    verifier(cartes >= 9 && sans_note == 0,
             "chaque carte dit dans quel langage elle se programme",
             sans_note == 0 ? std::to_string(cartes) + " cartes" : manquantes);

    auto note = [](const std::string& type) {
        const coeur::Modele* modele = coeur::Catalogue::instance().modele(type);
        return modele ? modele->note_langage : std::string();
    };
    auto contient = [](const std::string& texte, const std::string& morceau) {
        return texte.find(morceau) != std::string::npos;
    };

    verifier(contient(note("attiny85"), "1 MHz")
                 && contient(note("attiny85"), "CKDIV8"),
             "l'ATtiny85 previent qu'il sort d'usine a 1 MHz", "CKDIV8 cite");
    verifier(contient(note("pi_pico"), "6 MHz")
                 && contient(note("pi_pico"), "125 MHz"),
             "le Pico previent qu'il ne demarre pas a 125 MHz",
             "oscillateur en anneau cite");
    verifier(contient(note("stm32f103"), "8 MHz")
                 && contient(note("stm32f103"), "72 MHz"),
             "le STM32 previent qu'il ne demarre pas a 72 MHz",
             "quartz et PLL cites");
    verifier(contient(note("arduino_pro_mini"), "8 MHz"),
             "la Pro Mini previent qu'elle existe en deux versions",
             "5 V/16 MHz et 3,3 V/8 MHz");
    verifier(contient(note("esp32"), "ESP-IDF")
                 && contient(note("esp32"), "ne tourne pas"),
             "l'ESP32 dit franchement qu'un croquis complet ne tourne pas");
    verifier(contient(note("arduino_nano"), "Nano Every"),
             "la Nano met en garde contre la Nano Every, autre puce");

    // Le langage court, celui de l'onglet, doit rester court : c'est un titre.
    int trop_longs = 0;
    for (const coeur::Modele* modele : coeur::Catalogue::instance().tous())
        if (modele && modele->carte && modele->langage.size() > 20) ++trop_longs;
    verifier(trop_longs == 0, "le nom du langage tient dans un titre d'onglet",
             std::to_string(trop_longs) + " trop long(s)");
}


// ---------------------------------------------------------------------------
// [41] ARM : la liaison série, et le Thumb-2 que gcc emploie vraiment
//
// Deux manques trouvés en installant arm-none-eabi-gcc et en demandant à une
// carte ARM de PUBLIER une mesure.
//
// 1. Aucune liaison série n'était modélisée côté ARM. Un firmware Pico ou
//    STM32 n'avait que ses broches pour dire quoi que ce soit — impossible
//    d'en tirer un relevé chiffré.
//
// 2. DEUX instructions ARMv7-M manquaient au décodeur, et gcc les emploie
//    constamment dès qu'on compile en -Os pour un Cortex-M3 :
//
//      * CBZ et CBNZ, « compare à zéro et saute » — tout « if (p) » ;
//      * le bloc IT, « if-then », qui rend conditionnelles les une à quatre
//        instructions suivantes. C'est la particularité même du Thumb-2.
//
//    Aucune des deux ne faisait PLANTER quoi que ce soit : le programme
//    partait à la dérive en silence, ce qui est bien pire. La somme ci-dessous
//    rendait 210 au lieu de 147 — l'addition sous « addne » avait lieu à tous
//    les tours.
// ---------------------------------------------------------------------------
static void test_serie_et_sauts_arm() {
    std::printf("\n[41] ARM : liaison serie et Thumb-2 conditionnel\n");
    if (!coeur::CortexEngine::chaine_disponible()) {
        std::printf("  (aucune chaine ARM — section ignoree)\n");
        return;
    }

    struct Cas {
        const char* mcu;
        uint32_t horloge;
        const char* entete;      // les registres de la liaison série
        const char* attente;     // la boucle d'attente propre à la puce
    };
    const Cas cas[] = {
        // PL011 : le drapeau dit « file PLEINE », on attend qu'il retombe.
        {"rp2040", 125000000,
         "#define SR (*(volatile unsigned*)0x40034018u)\n"
         "#define DR (*(volatile unsigned*)0x40034000u)\n",
         "while (SR & (1u << 5)) { }\n"},
        // USART STMicroelectronics : le drapeau dit « registre VIDE ».
        {"stm32f103", 72000000,
         "#define SR (*(volatile unsigned*)0x40013800u)\n"
         "#define DR (*(volatile unsigned*)0x40013804u)\n",
         "while (!(SR & (1u << 7))) { }\n"}};

    for (const Cas& essai : cas) {
        // Le programme somme 1 à 20 en sautant un nombre sur trois, puis
        // publie le total. Deux précautions :
        //
        //   * pas de division ni de modulo. Un Cortex-M0+ n'a pas de
        //     diviseur, gcc appelle alors __aeabi_uidiv, et « -nostdlib »
        //     n'en fournit aucun : le programme ne se lierait pas ;
        //   * la condition porte sur une variable, « if (reste) », ce qui est
        //     exactement la forme que gcc traduit par un CBZ.
        const std::string source =
            std::string(essai.entete)
            + "static void emettre(const char* t) {\n"
              "    while (*t) { " + essai.attente + " DR = (unsigned)*t++; }\n"
              "}\n"
              "void _start(void) {\n"
              "    unsigned total = 0;\n"
              "    unsigned reste = 3;\n"
              "    for (unsigned n = 1; n <= 20; n++) {\n"
              "        reste--;\n"
              "        if (reste) total += n;\n"
              "        else reste = 3;\n"
              "    }\n"
              // Décimal par soustractions : le même souci de diviseur.
              "    char sortie[8];\n"
              "    int k = 0;\n"
              "    unsigned centaines = 0, dizaines = 0;\n"
              "    while (total >= 100) { total -= 100; centaines++; }\n"
              "    while (total >= 10)  { total -= 10;  dizaines++; }\n"
              "    if (centaines) sortie[k++] = (char)('0' + centaines);\n"
              "    if (centaines || dizaines) sortie[k++] = (char)('0' + dizaines);\n"
              "    sortie[k++] = (char)('0' + total);\n"
              "    sortie[k++] = '\\n';\n"
              "    sortie[k] = 0;\n"
              "    emettre(sortie);\n"
              "    for (;;) { }\n"
              "}\n";

        const std::string firmware =
            std::string("/tmp/sim_serie_") + essai.mcu + ".elf";
        std::string journal;
        if (!coeur::CortexEngine::compiler_source(source, firmware, &journal,
                                                  essai.mcu)) {
            verifier(false, std::string(essai.mcu) + " : le programme compile",
                     journal);
            continue;
        }

        coeur::CortexEngine puce;
        std::string recu;
        puce.sur_octet_serie([&](char octet) { recu += octet; });
        if (!puce.charger(firmware, essai.mcu, essai.horloge)) {
            verifier(false, std::string(essai.mcu) + " : firmware chargé",
                     puce.erreur());
            continue;
        }
        puce.avancer(400000);

        // 1..20 moins un nombre sur trois (3, 6, 9, 12, 15, 18) :
        // 210 - 63 = 147.
        while (!recu.empty() && (recu.back() == '\n' || recu.back() == '\r'))
            recu.pop_back();
        verifier(!recu.empty(),
                 std::string(essai.mcu) + " : la liaison série émet",
                 recu.empty() ? std::string("rien reçu") : "« " + recu + " »");
        verifier(recu == "147",
                 std::string(essai.mcu)
                     + " : Thumb-2 conditionnel décodé — la somme est juste",
                 "« " + recu + " » contre « 147 » attendu");
    }

    // Le Cortex-M0+ ne connaît PAS ces instructions : le décodeur ne doit pas
    // les reconnaître sur une puce ARMv6-M, sans quoi il exécuterait sur un
    // Pico un code que le vrai matériel refuserait.
    verifier(coeur::profil_rp2040().architecture == 6
                 && coeur::profil_stm32f103().architecture == 7,
             "CBZ, CBNZ et IT restent réservées à l'ARMv7-M",
             "Pico en v6-M, STM32 en v7-M");


    // --- La retenue d'ADC et de SBC ---------------------------------------
    //
    // Poser les drapeaux ÉCRASE la retenue. ADC et SBC lisaient donc la
    // retenue SORTANTE au lieu de l'entrante, et rendaient un résultat faux
    // dès qu'elle changeait — c'est-à-dire dans le cas normal.
    //
    // Ce n'est pas un détail d'arithmétique : un Cortex-M0+ n'a pas de
    // diviseur matériel, gcc appelle donc la division logicielle de libgcc,
    // et celle-ci est bâtie sur une chaîne de « subs » suivis d'« adcs ».
    // « 150 / 10 » rendait ZÉRO, en silence, sur toute carte Pi Pico.
    {
        // Chaque puce a sa liaison série, et les deux drapeaux sont de
        // conventions opposées : voir plus haut.
        struct Liaison { const char* mcu; const char* entete; };
        const Liaison liaisons[] = {
            {"rp2040",
             "#define SR (*(volatile unsigned*)0x40034018u)\n"
             "#define DR (*(volatile unsigned*)0x40034000u)\n"
             "static void put(char c){ while(SR&(1u<<5)){} DR=(unsigned)c; }\n"},
            {"stm32f103",
             "#define SR (*(volatile unsigned*)0x40013800u)\n"
             "#define DR (*(volatile unsigned*)0x40013804u)\n"
             "static void put(char c){ while(!(SR&(1u<<7))){} DR=(unsigned)c; }\n"}};
        for (const Liaison& liaison : liaisons) {
        const std::string source =
            std::string(liaison.entete)
            + "volatile unsigned long v = 150, d = 10;\n"
            "void _start(void) {\n"
            "    unsigned long q = v / d;\n"
            "    unsigned r;\n"
            // La retenue prise sur le vif : 150 >= 10 donc pas d'emprunt,
            // donc retenue à un sur un ARM, et adcs doit rendre 1.
            "    __asm__ volatile(\"movs r2, #0\\n cmp %1, %2\\n adcs r2, r2\\n"
            " mov %0, r2\" : \"=r\"(r) : \"r\"(v), \"r\"(d) : \"r2\", \"cc\");\n"
            "    put((char)('0' + (q / 10) % 10));\n"
            "    put((char)('0' + q % 10));\n"
            "    put((char)('0' + r));\n"
            "    for (;;) { }\n"
            "}\n";
        {
            const char* mcu = liaison.mcu;
            std::string journal;
            const std::string firmware =
                std::string("/tmp/sim_retenue_") + mcu + ".elf";
            if (!coeur::CortexEngine::compiler_source(source, firmware,
                                                      &journal, mcu)) {
                verifier(false, std::string(mcu) + " : l'essai compile", journal);
                continue;
            }
            coeur::CortexEngine puce;
            std::string recu;
            puce.sur_octet_serie([&](char octet) { recu += octet; });
            puce.charger(firmware, mcu, 72000000);
            puce.avancer(2000000);
            verifier(recu == "151",
                     std::string(mcu)
                         + " : division logicielle et retenue d'ADC justes",
                     "« " + recu + " » contre « 151 » attendu (15 puis 1)");
        }
        }
    }


    // --- Décalage dont le rang vient d'un REGISTRE -------------------------
    //
    // La forme immédiate et la forme par registre ne suivent pas la même
    // convention, et les confondre est l'erreur classique : en immédiat,
    // « LSR #0 » n'existe pas et l'encodage zéro signifie TRENTE-DEUX, donc
    // résultat nul ; par registre, un rang de zéro signifie zéro et la valeur
    // ne bouge pas.
    //
    // Les deux passaient par la même fonction. Conséquence : « v >> i » dans
    // une boucle où i finit à zéro — la façon dont tout le monde écrit un
    // affichage hexadécimal — perdait son dernier quartet.
    {
        const std::string source =
            "#define SR (*(volatile unsigned*)0x40013800u)\n"
            "#define DR (*(volatile unsigned*)0x40013804u)\n"
            "static void put(char c){ while(!(SR&(1u<<7))){} DR=(unsigned)c; }\n"
            "volatile unsigned v = 0x0123abcdu;\n"
            "volatile int zero = 0;\n"
            "void _start(void) {\n"
            "    int i;\n"
            // Le quartet de poids faible, obtenu par un décalage de rang nul
            // pris dans un registre.
            "    unsigned d = (v >> zero) & 0xfu;\n"
            "    put(d < 10u ? (char)('0' + d) : (char)('a' + d - 10u));\n"
            // Et la boucle entière, qui est le cas réel.
            "    for (i = 28; i >= 0; i -= 4) {\n"
            "        unsigned q = (v >> i) & 0xfu;\n"
            "        put(q < 10u ? (char)('0' + q) : (char)('a' + q - 10u));\n"
            "    }\n"
            "    for (;;) { }\n"
            "}\n";
        std::string journal;
        if (coeur::CortexEngine::compiler_source(source, "/tmp/sim_decalage.elf",
                                                 &journal, "stm32f103")) {
            coeur::CortexEngine puce;
            std::string recu;
            puce.sur_octet_serie([&](char octet) { recu += octet; });
            puce.charger("/tmp/sim_decalage.elf", "stm32f103", 72000000);
            puce.avancer(2000000);
            verifier(recu == "d0123abcd",
                     "décalage de rang nul par registre : la valeur ne bouge pas",
                     "« " + recu + " » contre « d0123abcd » attendu");
        } else {
            verifier(false, "l'essai de décalage compile", journal);
        }
    }

    // Le bloc IT, pris à part et sans ambiguïté : quatre instructions dans un
    // seul bloc, dont deux doivent s'exécuter et deux être sautées. Et une
    // vérification que les drapeaux ne bougent pas — « addne » emploie
    // l'encodage de ADDS, mais dans un bloc IT il ne met rien à jour. Un
    // modèle qui laisserait les drapeaux changer ferait dérailler la
    // condition du reste du bloc.
    {
        const std::string source =
            "#define SR (*(volatile unsigned*)0x40013800u)\n"
            "#define DR (*(volatile unsigned*)0x40013804u)\n"
            "volatile unsigned a = 4, b = 4;\n"
            "void _start(void) {\n"
            "    unsigned r = 0;\n"
            "    unsigned x = a, y = b;\n"
            // ITTEE : deux instructions si égal, deux si différent. Les
            // additions n'ont pas le droit de toucher aux drapeaux, sans quoi
            // les deux dernières prendraient la mauvaise branche.
            "    __asm__ volatile(\n"
            "        \"cmp %1, %2\\n\"\n"
            "        \"ittee eq\\n\"\n"
            "        \"addeq %0, %0, #1\\n\"\n"
            "        \"addeq %0, %0, #2\\n\"\n"
            "        \"addne %0, %0, #8\\n\"\n"
            "        \"addne %0, %0, #16\\n\"\n"
            "        : \"+r\"(r) : \"r\"(x), \"r\"(y) : \"cc\");\n"
            "    while (!(SR & (1u << 7))) { }\n"
            "    DR = (unsigned)('0' + r);\n"
            "    for (;;) { }\n"
            "}\n";
        std::string journal;
        if (coeur::CortexEngine::compiler_source(source, "/tmp/sim_it.elf",
                                                 &journal, "stm32f103")) {
            coeur::CortexEngine puce;
            std::string recu;
            puce.sur_octet_serie([&](char octet) { recu += octet; });
            puce.charger("/tmp/sim_it.elf", "stm32f103", 72000000);
            puce.avancer(200000);
            verifier(recu == "3",
                     "bloc IT à quatre instructions : deux faites, deux sautées",
                     "« " + recu + " » contre « 3 » attendu (1+2)");
        } else {
            verifier(false, "le bloc IT compile", journal);
        }
    }
}


// ---------------------------------------------------------------------------
// [42] Les montages du cours
//
// Les sections précédentes vérifient des mécanismes : un cœur, un solveur, un
// format de fichier. Celle-ci vérifie autre chose — que le simulateur donne
// les bons chiffres sur les montages qu'un élève rencontre dans l'ordre, du
// pont diviseur au trigger de Schmitt.
//
// Chaque cas a une réponse CALCULÉE À LA MAIN, écrite à côté. C'est ce qui
// distingue une vérification d'une capture de comportement : si le modèle
// change et que le résultat bouge, on saura lequel des deux avait tort.
// ---------------------------------------------------------------------------
static void test_montages_du_cours() {
    std::printf("\n[42] Les montages du cours\n");

    auto pile = [](coeur::Netlist& n, double volts, const char* plus) {
        auto& source = n.ajouter("V1", "pile");
        source.valeurs["volts"] = volts;
        n.relier("V1", "+", plus);
        n.relier("V1", "-", "GND");
    };
    auto resistance = [](coeur::Netlist& n, const char* nom, double ohms,
                         const char* a, const char* b) {
        auto& r = n.ajouter(nom, "resistance");
        r.valeurs["ohms"] = ohms;
        n.relier(nom, "1", a);
        n.relier(nom, "2", b);
    };
    auto resoudre = [](coeur::Netlist& n) {
        auto moteur = std::make_shared<coeur::NgspiceEngine>();
        moteur->construire(n, {});
        moteur->resoudre();
        return moteur;
    };

    // --- 1. Lois de Kirchhoff : deux résistances en parallèle -------------
    // 1k // 1k = 500 Ω. Avec 1k en série sur 9 V : V = 9 x 500/1500 = 3 V,
    // et le courant se partage en deux moitiés égales de 3 mA.
    {
        coeur::Netlist n;
        pile(n, 9, "IN");
        resistance(n, "R1", 1000, "IN", "MID");
        resistance(n, "R2", 1000, "MID", "GND");
        resistance(n, "R3", 1000, "MID", "GND");
        auto moteur = resoudre(n);
        verifier(presque(moteur->tension("MID"), 3.0, 0.01),
                 "deux résistances en parallèle : 1k//1k = 500 Ω",
                 f(moteur->tension("MID")) + " V pour 3 V attendus");
        verifier(presque(std::fabs(moteur->courant("R2")), 0.003, 1e-5)
                     && presque(std::fabs(moteur->courant("R3")), 0.003, 1e-5),
                 "le courant se partage également entre les deux branches",
                 f(std::fabs(moteur->courant("R2")) * 1000, 3) + " mA chacune");
    }

    // --- 2. Pont de Wheatstone -------------------------------------------
    // À l'équilibre R1/R2 = R3/R4, la diagonale est à zéro, quelle que soit
    // l'alimentation. C'est LE montage de mesure, et son point remarquable.
    {
        coeur::Netlist n;
        pile(n, 5, "HAUT");
        resistance(n, "R1", 1000, "HAUT", "A");
        resistance(n, "R2", 1000, "A", "GND");
        resistance(n, "R3", 2200, "HAUT", "B");
        resistance(n, "R4", 2200, "B", "GND");
        auto moteur = resoudre(n);
        const double diagonale = moteur->tension("A") - moteur->tension("B");
        verifier(std::fabs(diagonale) < 1e-6,
                 "pont de Wheatstone à l'équilibre : diagonale nulle",
                 f(diagonale * 1e6, 3) + " µV");
    }
    {
        // Déséquilibré : R4 passe de 2200 à 2420 (+10 %).
        // A = 2,5 V ; B = 5 x 2420/4620 = 2,619 V ; A - B = -0,119 V.
        coeur::Netlist n;
        pile(n, 5, "HAUT");
        resistance(n, "R1", 1000, "HAUT", "A");
        resistance(n, "R2", 1000, "A", "GND");
        resistance(n, "R3", 2200, "HAUT", "B");
        resistance(n, "R4", 2420, "B", "GND");
        auto moteur = resoudre(n);
        const double diagonale = moteur->tension("A") - moteur->tension("B");
        verifier(presque(diagonale, -0.11905, 0.001),
                 "pont déséquilibré de 10 % : -119 mV sur la diagonale",
                 f(diagonale * 1000, 2) + " mV");
    }

    // --- 3. Diode Zener en régulation ------------------------------------
    // Une 5V1 alimentée en 12 V à travers 1 kΩ : la sortie doit se tenir au
    // voisinage de 5,1 V, et surtout NE PAS suivre l'entrée.
    {
        double sortie[2] = {0, 0};
        const double entrees[2] = {9.0, 12.0};
        for (int essai = 0; essai < 2; ++essai) {
            coeur::Netlist n;
            pile(n, entrees[essai], "IN");
            resistance(n, "R1", 1000, "IN", "OUT");
            auto& z = n.ajouter("DZ1", "zener");
            z.textes["tension"] = "5V1";
            n.relier("DZ1", "K", "OUT");
            n.relier("DZ1", "A", "GND");
            auto moteur = resoudre(n);
            sortie[essai] = moteur->tension("OUT");
        }
        verifier(presque(sortie[1], 5.1, 0.4),
                 "Zener 5V1 sous 12 V : la sortie se tient à sa tension",
                 f(sortie[1]) + " V");
        verifier(presque(sortie[0], 5.1, 0.4),
                 "Zener 5V1 sous 9 V : elle régule aussi sous le seuil où "
                 "elle ne convergeait pas",
                 f(sortie[0]) + " V");
        // Et la confrontation qui compte : ngspice sur le même montage.
        // Le modèle de claquage suit sa formulation, la comparaison doit donc
        // tomber au millivolt près, pas seulement dans le bon ordre.
        if (coeur::NgspiceEngine::compile_avec_ngspice()) {
            coeur::Netlist n;
            auto& source = n.ajouter("V1", "pile");
            source.valeurs["volts"] = 9;
            n.relier("V1", "+", "IN");
            n.relier("V1", "-", "GND");
            auto& r = n.ajouter("R1", "resistance");
            r.valeurs["ohms"] = 1000;
            n.relier("R1", "1", "IN");
            n.relier("R1", "2", "OUT");
            auto& z = n.ajouter("DZ1", "zener");
            z.textes["tension"] = "5V1";
            n.relier("DZ1", "K", "OUT");
            n.relier("DZ1", "A", "GND");
            double lu[2] = {0, 0};
            for (int avec = 0; avec < 2; ++avec) {
                coeur::NgspiceEngine m;
                m.preferer_ngspice(avec == 1);
                m.construire(n, {});
                m.resoudre();
                lu[avec] = m.tension("OUT");
            }
            verifier(lu[1] > 0 && presque(lu[0], lu[1], 0.03),
                     "Zener : même tension que ngspice à 30 mV près",
                     f(lu[0], 4) + " V contre " + f(lu[1], 4) + " V");
        }
        verifier(std::fabs(sortie[1] - sortie[0]) < 0.25,
                 "et elle ne suit pas l'entrée : +3 V en entrée, presque rien "
                 "en sortie",
                 f(sortie[0]) + " V sous 9 V, " + f(sortie[1]) + " V sous 12 V");
    }

    // --- 4. Amplificateur non inverseur ----------------------------------
    // Gain = 1 + R2/R1. Avec R1 = R2 = 10 k, gain 2 : 1,2 V donne 2,4 V.
    {
        coeur::Netlist n;
        pile(n, 1.2, "IN");
        n.ajouter("A1", "ampli_op");
        n.relier("A1", "IN+", "IN");
        n.relier("A1", "IN-", "RETOUR");
        n.relier("A1", "OUT", "OUT");
        resistance(n, "R1", 10000, "RETOUR", "GND");
        resistance(n, "R2", 10000, "OUT", "RETOUR");
        auto moteur = resoudre(n);
        verifier(presque(moteur->tension("OUT"), 2.4, 0.02),
                 "ampli op non inverseur : gain 1 + R2/R1 = 2",
                 f(moteur->tension("OUT")) + " V pour 2,4 V attendus");
    }

    // --- 5. Amplificateur inverseur, en alimentation simple --------------
    // L'entrée + est portée à 2,5 V, qui devient la masse du signal. La
    // sortie vaut alors 2,5 - (Vin - 2,5) x R2/R1. Avec Vin = 1,5 V et un
    // rapport de 2 : 2,5 + 2 = 4,5 V. Le signe est le point à vérifier —
    // l'entrée descend, la sortie monte.
    {
        coeur::Netlist n;
        pile(n, 1.5, "IN");
        auto& reference = n.ajouter("V2", "pile");
        reference.valeurs["volts"] = 2.5;
        n.relier("V2", "+", "REF");
        n.relier("V2", "-", "GND");
        n.ajouter("A1", "ampli_op");
        n.relier("A1", "IN+", "REF");
        n.relier("A1", "IN-", "SOMME");
        n.relier("A1", "OUT", "OUT");
        resistance(n, "R1", 10000, "IN", "SOMME");
        resistance(n, "R2", 20000, "OUT", "SOMME");
        auto moteur = resoudre(n);
        verifier(presque(moteur->tension("OUT"), 4.5, 0.05),
                 "ampli op inverseur : gain -R2/R1 = -2 autour de 2,5 V",
                 f(moteur->tension("OUT")) + " V pour 4,5 V attendus");
    }

    // --- 6. Charge d'un condensateur : la constante de temps -------------
    // R = 10 k, C = 10 µF, tau = 0,1 s. À t = tau la tension vaut 63,2 % de
    // sa valeur finale ; à 5 tau, 99,3 %. Ce sont les deux nombres que tout
    // le monde retient, et ils doivent tomber juste.
    {
        coeur::Netlist n;
        // Un créneau très lent, et non une tension continue : le point de
        // repos chargerait le condensateur AVANT que le transitoire commence,
        // et l'on ne verrait aucune charge. C'est le comportement normal d'un
        // simulateur, et le piège classique de qui veut voir une exponentielle.
        auto& source = n.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "carre";
        source.valeurs["amplitude"] = 2.5;
        source.valeurs["offset"] = 2.5;
        source.valeurs["frequence"] = 0.5;      /* deux secondes de période */
        n.relier("GBF1", "+", "IN");
        n.relier("GBF1", "-", "GND");
        resistance(n, "R1", 10000, "IN", "OUT");
        auto& c = n.ajouter("C1", "condensateur");
        c.valeurs["farads"] = 10e-6;
        n.relier("C1", "1", "OUT");
        n.relier("C1", "2", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire_transitoire(n, {}, {}, 1.6, 1e-4);
        verifier(moteur.resoudre_transitoire(), "charge RC : le transitoire aboutit");
        const coeur::Formes& formes = moteur.formes();
        auto a_l_instant = [&](double t) {
            auto trace = formes.tensions.find("out");
            if (trace == formes.tensions.end()) return -1.0;
            for (size_t k = 0; k < formes.temps.size(); ++k)
                if (formes.temps[k] >= t) return trace->second[k];
            return trace->second.back();
        };
        // Le créneau monte à 5 V à t = 1 s (il part à 5 V, redescend à 0 à
        // t = 1 s… selon la phase). On repère donc le front en cherchant le
        // minimum, puis on mesure depuis là.
        size_t creux = 0;
        auto trace = formes.tensions.find("out");
        if (trace != formes.tensions.end()) {
            for (size_t k = 1; k < trace->second.size(); ++k)
                if (trace->second[k] < trace->second[creux]) creux = k;
            const double t0 = formes.temps[creux];
            const double depart = trace->second[creux];
            verifier(presque(a_l_instant(t0 + 0.1) - depart,
                             (5.0 - depart) * 0.632, 0.15),
                     "charge RC : 63,2 % de l'écart franchi au bout de tau",
                     f(a_l_instant(t0 + 0.1) - depart) + " V sur "
                         + f(5.0 - depart) + " V");
            verifier(presque(a_l_instant(t0 + 0.5) - depart,
                             (5.0 - depart) * 0.993, 0.15),
                     "charge RC : 99,3 % au bout de cinq tau",
                     f(a_l_instant(t0 + 0.5) - depart) + " V");
        }
    }

    // --- 7. Diode de roue libre ------------------------------------------
    // Couper le courant dans une bobine fait apparaître une surtension : la
    // bobine s'oppose à la variation. La diode de roue libre l'écrête à une
    // chute directe au-dessus de l'alimentation. SANS elle, la pointe est
    // très supérieure. C'est le montage qui protège tout circuit à relais ou
    // à moteur, et le simulateur doit montrer la différence.
    {
        double pointe[2] = {0, 0};
        for (int avec_diode = 0; avec_diode < 2; ++avec_diode) {
            coeur::Netlist n;
            auto& source = n.ajouter("GBF1", "generateur_signal");
            source.textes["forme"] = "carre";
            source.valeurs["amplitude"] = 2.5;
            source.valeurs["offset"] = 2.5;
            source.valeurs["frequence"] = 200;
            n.relier("GBF1", "+", "CMD");
            n.relier("GBF1", "-", "GND");
            resistance(n, "R1", 100, "CMD", "HAUT");
            auto& bobine = n.ajouter("L1", "inductance");
            bobine.valeurs["henrys"] = 0.05;
            n.relier("L1", "1", "HAUT");
            n.relier("L1", "2", "GND");
            if (avec_diode) {
                auto& d = n.ajouter("D1", "diode");
                (void)d;
                n.relier("D1", "A", "GND");
                n.relier("D1", "K", "HAUT");
            }
            coeur::NgspiceEngine moteur;
            moteur.construire_transitoire(n, {}, {}, 0.03, 1e-6);
            if (!moteur.resoudre_transitoire()) continue;
            const coeur::Formes& formes = moteur.formes();
            auto trace = formes.tensions.find("haut");
            if (trace == formes.tensions.end()) continue;
            // La pointe est NÉGATIVE, et c'est le point à comprendre : le
            // courant entrait dans la bobine par le haut et sortait vers la
            // masse. À la coupure il continue dans le MÊME sens, et pour cela
            // il tire le nœud haut en dessous de la masse.
            for (double v : trace->second)
                pointe[avec_diode] = std::min(pointe[avec_diode], v);
        }
        verifier(pointe[0] < -2.0,
                 "sans diode de roue libre : la bobine produit une surtension",
                 f(pointe[0]) + " V de pointe");
        verifier(pointe[1] > pointe[0] && pointe[1] > -1.5,
                 "avec la diode : la pointe est écrêtée à une chute directe",
                 f(pointe[1]) + " V contre " + f(pointe[0]) + " V sans elle");
    }
}


// ---------------------------------------------------------------------------
// [43] Les montages du cours, suite
//
// La suite du balayage : redressement, gain d'un transistor, commutation d'un
// MOSFET, comparateur. Même règle qu'à la section précédente — chaque réponse
// est calculée à la main et écrite à côté.
// ---------------------------------------------------------------------------
static void test_montages_du_cours_suite() {
    std::printf("\n[43] Les montages du cours, suite\n");

    auto resistance = [](coeur::Netlist& n, const char* nom, double ohms,
                         const char* a, const char* b) {
        auto& r = n.ajouter(nom, "resistance");
        r.valeurs["ohms"] = ohms;
        n.relier(nom, "1", a);
        n.relier(nom, "2", b);
    };

    // --- 1. Redresseur simple alternance avec lissage ---------------------
    // 10 V crête à 50 Hz, une diode, 100 µF, charge 1 kΩ.
    // La crête en sortie vaut 10 - 0,7 = 9,3 V. Entre deux crêtes le
    // condensateur se décharge dans la charge pendant une période :
    // dV = I / (f x C) = 9,3 mA / (50 x 100 µF) = 1,9 V d'ondulation.
    {
        coeur::Netlist n;
        auto& source = n.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "sinus";
        source.valeurs["amplitude"] = 10;
        source.valeurs["frequence"] = 50;
        n.relier("GBF1", "+", "AC");
        n.relier("GBF1", "-", "GND");
        n.ajouter("D1", "diode");
        n.relier("D1", "A", "AC");
        n.relier("D1", "K", "SORTIE");
        auto& c = n.ajouter("C1", "condensateur");
        c.valeurs["farads"] = 100e-6;
        n.relier("C1", "1", "SORTIE");
        n.relier("C1", "2", "GND");
        resistance(n, "R1", 1000, "SORTIE", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire_transitoire(n, {}, {}, 0.2, 2e-5);
        verifier(moteur.resoudre_transitoire(),
                 "redresseur : le transitoire aboutit");
        const coeur::Formes& formes = moteur.formes();
        auto trace = formes.tensions.find("sortie");
        if (trace != formes.tensions.end() && !trace->second.empty()) {
            // Sur le dernier tiers, le régime est établi.
            double haut = -1e9, bas = 1e9;
            for (size_t k = trace->second.size() * 2 / 3;
                 k < trace->second.size(); ++k) {
                haut = std::max(haut, trace->second[k]);
                bas = std::min(bas, trace->second[k]);
            }
            verifier(presque(haut, 9.3, 0.5),
                     "redresseur : la crête vaut l'amplitude moins une chute "
                     "directe",
                     f(haut) + " V pour 9,3 V attendus");
            verifier(presque(haut - bas, 1.9, 0.6),
                     "redresseur : ondulation I/(f.C)",
                     f(haut - bas, 2) + " V pour 1,9 V attendus");
            // Et le point qui distingue un redresseur d'un simple filtre : la
            // sortie ne descend JAMAIS en dessous de zéro.
            verifier(bas > 0.0,
                     "redresseur : la sortie ne passe jamais négative",
                     f(bas) + " V au plus bas");
        }
    }

    // --- 2. Gain en courant d'un transistor -------------------------------
    // Le modèle 2N2222 déclare BF = 200. Une base alimentée en 5 V à travers
    // 470 k donne Ib = (5 - 0,7) / 470k = 9,1 µA, donc Ic = 200 x 9,1 = 1,8 mA
    // tant que le transistor n'est pas saturé. Avec Rc = 1 k, la chute vaut
    // 1,8 V : le collecteur reste bien au-dessus de la saturation.
    {
        coeur::Netlist n;
        auto& alim = n.ajouter("V1", "pile");
        alim.valeurs["volts"] = 5;
        n.relier("V1", "+", "VCC");
        n.relier("V1", "-", "GND");
        resistance(n, "RB", 470000, "VCC", "BASE");
        resistance(n, "RC", 1000, "VCC", "COLLECTEUR");
        n.ajouter("Q1", "transistor_npn");
        n.relier("Q1", "B", "BASE");
        n.relier("Q1", "C", "COLLECTEUR");
        n.relier("Q1", "E", "GND");

        coeur::NgspiceEngine moteur;
        moteur.construire(n, {});
        moteur.resoudre();
        const double ib = std::fabs(moteur.courant("RB"));
        const double ic = std::fabs(moteur.courant("RC"));
        verifier(ib > 5e-6 && ib < 15e-6,
                 "transistor : le courant de base suit la loi d'Ohm",
                 f(ib * 1e6, 2) + " µA pour 9,1 µA attendus");
        verifier(ib > 0 && presque(ic / ib, 200.0, 60.0),
                 "transistor : gain en courant voisin du BF déclaré (200)",
                 "beta mesuré = " + f(ic / std::max(ib, 1e-12), 0));
        verifier(moteur.tension("COLLECTEUR") > 2.0,
                 "transistor : le collecteur n'est pas saturé, le gain est donc "
                 "celui du régime linéaire",
                 f(moteur.tension("COLLECTEUR")) + " V");
    }

    // --- 3. MOSFET en commutation -----------------------------------------
    // Grille à la masse : bloqué, le drain reste à l'alimentation. Grille à
    // 5 V : passant, le drain tombe presque à zéro. C'est tout ce qu'on
    // demande à un interrupteur, et c'est ce qu'on vérifie.
    {
        double drain[2] = {0, 0};
        for (int commande = 0; commande < 2; ++commande) {
            coeur::Netlist n;
            auto& alim = n.ajouter("V1", "pile");
            alim.valeurs["volts"] = 5;
            n.relier("V1", "+", "VCC");
            n.relier("V1", "-", "GND");
            auto& grille = n.ajouter("V2", "pile");
            grille.valeurs["volts"] = commande ? 5.0 : 0.0;
            n.relier("V2", "+", "GRILLE");
            n.relier("V2", "-", "GND");
            resistance(n, "RD", 1000, "VCC", "DRAIN");
            n.ajouter("M1", "mosfet_n");
            n.relier("M1", "G", "GRILLE");
            n.relier("M1", "D", "DRAIN");
            n.relier("M1", "S", "GND");
            coeur::NgspiceEngine moteur;
            moteur.construire(n, {});
            moteur.resoudre();
            drain[commande] = moteur.tension("DRAIN");
        }
        verifier(drain[0] > 4.5,
                 "MOSFET bloqué : le drain reste à l'alimentation",
                 f(drain[0]) + " V");
        verifier(drain[1] < 0.5,
                 "MOSFET passant : le drain tombe presque à zéro",
                 f(drain[1]) + " V");
    }

    // --- 4. Comparateur -----------------------------------------------------
    // Un ampli op sans contre-réaction : sa sortie va d'un côté ou de l'autre
    // selon le signe de la différence d'entrée. Quelques millivolts d'écart
    // suffisent — c'est le gain en boucle ouverte qui le veut.
    {
        double sortie[2] = {0, 0};
        const double entrees[2] = {2.49, 2.51};
        for (int essai = 0; essai < 2; ++essai) {
            coeur::Netlist n;
            auto& reference = n.ajouter("V1", "pile");
            reference.valeurs["volts"] = 2.5;
            n.relier("V1", "+", "REF");
            n.relier("V1", "-", "GND");
            auto& signal = n.ajouter("V2", "pile");
            signal.valeurs["volts"] = entrees[essai];
            n.relier("V2", "+", "SIGNAL");
            n.relier("V2", "-", "GND");
            n.ajouter("A1", "ampli_op");
            n.relier("A1", "IN+", "SIGNAL");
            n.relier("A1", "IN-", "REF");
            n.relier("A1", "OUT", "SORTIE");
            coeur::NgspiceEngine moteur;
            moteur.construire(n, {});
            moteur.resoudre();
            sortie[essai] = moteur.tension("SORTIE");
        }
        verifier(sortie[0] < 1.0,
                 "comparateur : 10 mV en dessous du seuil, la sortie bascule bas",
                 f(sortie[0]) + " V");
        verifier(sortie[1] > 4.0,
                 "comparateur : 10 mV au-dessus, elle bascule haut",
                 f(sortie[1]) + " V");
        verifier(sortie[1] - sortie[0] > 3.5,
                 "comparateur : 20 mV d'écart en entrée font toute l'amplitude "
                 "en sortie",
                 f(sortie[1] - sortie[0]) + " V d'excursion");
    }
}


// ---------------------------------------------------------------------------
// [44] Continuité des modèles non linéaires
//
// D'où vient cette section : la Zener ne convergeait pas sous 10 V d'entrée,
// et la cause était un SAUT dans le modèle — le courant passait de zéro à IBV
// à la tension de claquage, sans rien entre les deux. Newton ne traverse pas
// une discontinuité.
//
// Ce défaut a deux propriétés qui le rendent redoutable :
//
//   * il ne se voit qu'à certaines valeurs. Au-dessus du saut tout va bien,
//     et le montage a l'air correct ;
//   * aucun test fonctionnel ne le trouve par hasard, parce qu'il faut tomber
//     précisément dans le trou.
//
// Plutôt que de corriger un modèle et d'espérer, on les balaie TOUS et l'on
// regarde leur caractéristique de près. Un composant physique a une
// caractéristique continue : le courant peut monter très vite — une diode le
// fait —, mais il ne saute pas. Un saut est donc toujours l'aveu d'un modèle
// écrit par morceaux dont les morceaux ne se rejoignent pas.
// ---------------------------------------------------------------------------
static void test_continuite_des_modeles() {
    std::printf("\n[44] Continuite des modeles non lineaires\n");

    // Cherche un saut dans une courbe : un écart entre deux points voisins qui
    // pèse une part notable de toute l'excursion ET qui écrase ses voisins
    // immédiats. Les deux conditions comptent. La première seule signalerait
    // le coude d'une diode, qui est raide mais régulier ; la seconde seule
    // signalerait le bruit numérique là où il ne se passe rien.
    auto chercher_saut = [](const std::vector<double>& valeurs,
                            const std::vector<double>& abscisse,
                            double* ou, double* taille) {
        *ou = 0;
        *taille = 0;
        if (valeurs.size() < 4) return false;
        double mini = valeurs[0], maxi = valeurs[0];
        for (double v : valeurs) {
            mini = std::min(mini, v);
            maxi = std::max(maxi, v);
        }
        const double excursion = maxi - mini;
        if (excursion < 1e-12) return false;
        for (size_t k = 1; k + 1 < valeurs.size(); ++k) {
            const double saut = std::fabs(valeurs[k] - valeurs[k - 1]);
            const double avant =
                k >= 2 ? std::fabs(valeurs[k - 1] - valeurs[k - 2]) : 0.0;
            const double apres = std::fabs(valeurs[k + 1] - valeurs[k]);
            const double voisins = std::max(avant, apres);
            if (saut < 0.10 * excursion) continue;
            if (saut < 20.0 * std::max(voisins, 1e-15)) continue;
            *ou = abscisse[k];
            *taille = saut;
            return true;
        }
        return false;
    };

    // AVANT DE S'EN SERVIR, ON VÉRIFIE QU'IL MORD.
    //
    // Un détecteur qui ne se déclenche jamais ne prouve rien — il rassure, ce
    // qui est pire que rien. On lui donne donc deux courbes fabriquées : celle
    // que le modèle de Zener produisait avant sa correction (le courant saute
    // de zéro à IBV au claquage), et le coude d'une diode, qui est raide mais
    // régulier. Il doit signaler la première et laisser passer la seconde.
    {
        std::vector<double> abscisse, avec_saut, exponentielle;
        for (int k = 0; k < 200; ++k) {
            const double v = -12.0 + k * 0.06;
            abscisse.push_back(v);
            // L'ancien modèle : rien, puis 5 mA d'un coup à -5,1 V.
            avec_saut.push_back(v < -5.1 ? -0.005 - (-5.1 - v) * 1e-3 : 0.0);
            // Une exponentielle : la pente double tous les 40 mV environ.
            exponentielle.push_back(std::exp(v / 0.04) * 1e-14);
        }
        double ou = 0, taille = 0;
        verifier(chercher_saut(avec_saut, abscisse, &ou, &taille),
                 "le détecteur signale le saut que la Zener avait avant "
                 "correction",
                 "saut de " + f(taille * 1000, 2) + " mA à " + f(ou, 2) + " V");
        verifier(!chercher_saut(exponentielle, abscisse, &ou, &taille),
                 "et il laisse passer le coude d'une diode, raide mais régulier",
                 "aucun saut signalé");
    }

    // Un composant à deux bornes, alimenté à travers une résistance, et la
    // source balayée finement. On regarde le courant : c'est lui qui porte la
    // non-linéarité.
    struct Deux { const char* nom; const char* type; const char* choix;
                  double debut; double fin; };
    const Deux passifs[] = {
        {"diode 1N4148", "diode", nullptr, -1.0, 1.5},
        // La plage traverse le claquage : c'est là que se trouvait le saut.
        {"Zener 5V1", "zener", "5V1", -12.0, 1.5},
        {"Zener 3V3", "zener", "3V3", -9.0, 1.5},
        {"LED rouge", "led", nullptr, -1.0, 3.5}};

    for (const Deux& essai : passifs) {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "continu";
        source.valeurs["offset"] = 0;
        netlist.relier("GBF1", "+", "IN");
        netlist.relier("GBF1", "-", "GND");
        auto& r = netlist.ajouter("R1", "resistance");
        r.valeurs["ohms"] = 100;
        netlist.relier("R1", "1", "IN");
        netlist.relier("R1", "2", "HAUT");
        auto& composant = netlist.ajouter("D1", essai.type);
        if (essai.choix) composant.textes["tension"] = essai.choix;
        // La cathode d'une LED s'appelle K, comme celle d'une diode.
        netlist.relier("D1", "A", "HAUT");
        netlist.relier("D1", "K", "GND");

        coeur::NgspiceEngine moteur;
        moteur.preferer_ngspice(false);      // c'est NOTRE modèle qu'on juge
        moteur.construire_analyse(
            netlist, {},
            ".dc VGBF1 " + f(essai.debut, 3) + " " + f(essai.fin, 3) + " 0.02");
        if (!moteur.resoudre_analyse()) {
            verifier(false, std::string(essai.nom) + " : le balayage aboutit",
                     moteur.erreurs().empty() ? "" : moteur.erreurs().front());
            continue;
        }
        const coeur::Balayage& balayage = moteur.balayage();
        const coeur::Courbe* courant = balayage.courbe("I(r1)");
        if (!courant) {
            verifier(false, std::string(essai.nom) + " : le courant est relevé");
            continue;
        }
        double ou = 0, taille = 0;
        const bool saut =
            chercher_saut(courant->valeurs, balayage.abscisse, &ou, &taille);
        verifier(!saut,
                 std::string(essai.nom) + " : caractéristique sans saut",
                 saut ? "saut de " + f(taille * 1000, 3) + " mA à " + f(ou, 2)
                            + " V"
                      : std::to_string(balayage.abscisse.size()) + " points");
    }

    // Le transistor : la grandeur commandée est le courant de collecteur, et
    // la commande est la tension de base. On balaie de zéro à la saturation.
    {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "continu";
        source.valeurs["offset"] = 0;
        netlist.relier("GBF1", "+", "COMMANDE");
        netlist.relier("GBF1", "-", "GND");
        auto& alim = netlist.ajouter("V1", "pile");
        alim.valeurs["volts"] = 5;
        netlist.relier("V1", "+", "VCC");
        netlist.relier("V1", "-", "GND");
        auto& rb = netlist.ajouter("R1", "resistance");
        rb.valeurs["ohms"] = 10000;
        netlist.relier("R1", "1", "COMMANDE");
        netlist.relier("R1", "2", "BASE");
        auto& rc = netlist.ajouter("R2", "resistance");
        rc.valeurs["ohms"] = 1000;
        netlist.relier("R2", "1", "VCC");
        netlist.relier("R2", "2", "COLLECTEUR");
        netlist.ajouter("Q1", "transistor_npn");
        netlist.relier("Q1", "B", "BASE");
        netlist.relier("Q1", "C", "COLLECTEUR");
        netlist.relier("Q1", "E", "GND");

        coeur::NgspiceEngine moteur;
        moteur.preferer_ngspice(false);
        moteur.construire_analyse(netlist, {}, ".dc VGBF1 0 5 0.02");
        if (moteur.resoudre_analyse()) {
            const coeur::Balayage& balayage = moteur.balayage();
            const coeur::Courbe* collecteur = balayage.courbe("collecteur");
            if (collecteur) {
                double ou = 0, taille = 0;
                const bool saut = chercher_saut(collecteur->valeurs,
                                                balayage.abscisse, &ou, &taille);
                verifier(!saut,
                         "transistor NPN : du blocage à la saturation sans saut",
                         saut ? "saut de " + f(taille * 1000, 1) + " mV à "
                                    + f(ou, 2) + " V"
                              : "balayage régulier");
            }
        } else {
            verifier(false, "transistor NPN : le balayage aboutit");
        }
    }

    // Le MOSFET : même question, la grille balayée de zéro à cinq volts. Le
    // passage bloqué -> triode -> saturation est l'endroit classique où un
    // modèle écrit par morceaux se trahit.
    {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "continu";
        source.valeurs["offset"] = 0;
        netlist.relier("GBF1", "+", "GRILLE");
        netlist.relier("GBF1", "-", "GND");
        auto& alim = netlist.ajouter("V1", "pile");
        alim.valeurs["volts"] = 5;
        netlist.relier("V1", "+", "VCC");
        netlist.relier("V1", "-", "GND");
        auto& rd = netlist.ajouter("R1", "resistance");
        rd.valeurs["ohms"] = 1000;
        netlist.relier("R1", "1", "VCC");
        netlist.relier("R1", "2", "DRAIN");
        netlist.ajouter("M1", "mosfet_n");
        netlist.relier("M1", "G", "GRILLE");
        netlist.relier("M1", "D", "DRAIN");
        netlist.relier("M1", "S", "GND");

        coeur::NgspiceEngine moteur;
        moteur.preferer_ngspice(false);
        moteur.construire_analyse(netlist, {}, ".dc VGBF1 0 5 0.02");
        if (moteur.resoudre_analyse()) {
            const coeur::Balayage& balayage = moteur.balayage();
            const coeur::Courbe* drain = balayage.courbe("drain");
            if (drain) {
                double ou = 0, taille = 0;
                const bool saut = chercher_saut(drain->valeurs,
                                                balayage.abscisse, &ou, &taille);
                verifier(!saut,
                         "MOSFET : bloqué, triode, saturation — sans saut",
                         saut ? "saut de " + f(taille * 1000, 1) + " mV à "
                                    + f(ou, 2) + " V"
                              : "balayage régulier");
            }
        } else {
            verifier(false, "MOSFET : le balayage aboutit");
        }
    }

    // L'amplificateur opérationnel : sa sortie est bornée par min et max, ce
    // qui EST une écriture par morceaux. La valeur y reste continue — c'est
    // la pente qui casse —, et c'est justement ce que ce contrôle doit
    // confirmer plutôt que supposer.
    {
        coeur::Netlist netlist;
        auto& source = netlist.ajouter("GBF1", "generateur_signal");
        source.textes["forme"] = "continu";
        source.valeurs["offset"] = 0;
        netlist.relier("GBF1", "+", "IN");
        netlist.relier("GBF1", "-", "GND");
        netlist.ajouter("A1", "ampli_op");
        netlist.relier("A1", "IN+", "IN");
        netlist.relier("A1", "IN-", "RETOUR");
        netlist.relier("A1", "OUT", "OUT");
        auto& r1 = netlist.ajouter("R1", "resistance");
        r1.valeurs["ohms"] = 10000;
        netlist.relier("R1", "1", "RETOUR");
        netlist.relier("R1", "2", "GND");
        auto& r2 = netlist.ajouter("R2", "resistance");
        r2.valeurs["ohms"] = 10000;
        netlist.relier("R2", "1", "OUT");
        netlist.relier("R2", "2", "RETOUR");

        coeur::NgspiceEngine moteur;
        moteur.preferer_ngspice(false);
        moteur.construire_analyse(netlist, {}, ".dc VGBF1 0 4 0.02");
        if (moteur.resoudre_analyse()) {
            const coeur::Balayage& balayage = moteur.balayage();
            const coeur::Courbe* sortie = balayage.courbe("out");
            if (sortie) {
                double ou = 0, taille = 0;
                const bool saut = chercher_saut(sortie->valeurs,
                                                balayage.abscisse, &ou, &taille);
                verifier(!saut,
                         "ampli op : entrée en butée sans saut de sortie",
                         saut ? "saut de " + f(taille, 3) + " V à " + f(ou, 2)
                                    + " V"
                              : "balayage régulier");
            }
        } else {
            verifier(false, "ampli op : le balayage aboutit");
        }
    }
}

int main() {
    console_en_utf8();
    std::printf("============================================================\n");
    std::printf("TESTS DU CŒUR — simulateur embarqué (C++)\n");
    std::printf("============================================================\n");
    std::printf("moteurs : solveur analogique et cœur AVR intégrés   |   "
                "ngspice : %s   |   simavr : %s (comparaison)\n",
                coeur::NgspiceEngine::compile_avec_ngspice() ? "oui" : "non",
                coeur::AvrEngine::compile_avec_simavr() ? "oui" : "non");

    test_netlist();
    test_ngspice();
    test_simavr();
    test_couplage();
    test_couplage_inverse();
    test_adc();
    test_catalogue_complet();
    test_physique_catalogue();
    test_transitoire();
    test_exemplaires_multiples();
    test_croquis_arduino();
    test_composants_a_etat();
    test_analyses();
    test_documents();
    test_balayages();
    test_multimetres();
    test_temperature_et_bruit();
    test_solveur_integre();
    test_numerique_trois_volts_trois();
    test_solveur_integre_troncature_et_ringing();
    test_coeur_avr();
    test_compteur_precharge();
    test_campagnes();
    test_numerique();
    test_pulse_in();
    test_pcb();
    test_placement_suit_la_connectique();
    test_exemples_compilent();
    test_cartes_qui_tournent();
    test_attiny85();
    test_atmega2560();
    test_cartes_arm();
    test_esp32();
    test_routage_automatique();
    test_tirages_et_adc_arm();
    test_tirage_vers_la_bonne_alimentation();
    test_cycles_exacts_arm();
    test_temps_xtensa();
    test_fabrication();
    test_bobines();
    test_notes_de_langage();
    test_serie_et_sauts_arm();
    test_montages_du_cours();
    test_montages_du_cours_suite();
    test_continuite_des_modeles();
    test_serie_reception();
    test_programme_multifichier();

    test_audit_carte_et_analyses();

    std::printf("\n============================================================\n");
    if (!g_echecs.empty()) {
        std::printf("%zu test(s) en échec sur %zu :\n", g_echecs.size(),
                    g_echecs.size() + g_ok);
        for (const auto& titre : g_echecs)
            std::printf("   - %s\n", titre.c_str());
        return 1;
    }
    std::printf("TOUS LES TESTS PASSENT (%d)\n", g_ok);
    return 0;
}
