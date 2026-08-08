// Tests du cœur : netlist, catalogue, moteur analogique (ngspice) et
// moteur microcontrôleur (simavr), puis leur COUPLAGE — c'est ce couplage
// qui fait un simulateur de type Proteus.
//
// Aucun écran nécessaire : ./tests_coeur

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <sstream>
#include <string>
#include <vector>

#include "core/Device.h"
#include "core/Netlist.h"
#include "core/analysis/Analyses.h"
#include "core/analysis/Campagne.h"
#include "core/engines/AvrEngine.h"
#include "core/engines/MoteurNumerique.h"
#include "core/engines/NgspiceEngine.h"
#include "core/export/Documents.h"
#include "core/pcb/Pcb.h"

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
    std::printf("\n[2] Moteur analogique (ngspice)\n");
    if (!coeur::NgspiceEngine::compile_avec_ngspice()) {
        std::printf("  (ngspice absent — section ignorée)\n");
        return;
    }

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
    std::printf("\n[3] Moteur microcontrôleur (simavr + avr-gcc)\n");
    if (!coeur::AvrEngine::compile_avec_simavr()) {
        std::printf("  (simavr absent — section ignorée)\n");
        return;
    }
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
    verifier(mcu.charger(g_firmware), "chargement du .elf dans simavr",
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
    if (!coeur::NgspiceEngine::compile_avec_ngspice() ||
        !coeur::AvrEngine::compile_avec_simavr() ||
        !coeur::AvrEngine::avr_gcc_disponible() || g_firmware.empty()) {
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
    if (!coeur::AvrEngine::compile_avec_simavr() ||
        !coeur::AvrEngine::avr_gcc_disponible()) {
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
    if (!coeur::AvrEngine::compile_avec_simavr() ||
        !coeur::AvrEngine::avr_gcc_disponible()) {
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
    if (!coeur::NgspiceEngine::compile_avec_ngspice()) {
        std::printf("  (ngspice absent — section ignorée)\n");
        return;
    }
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
    if (!coeur::NgspiceEngine::compile_avec_ngspice()) {
        std::printf("  (ngspice absent — section ignorée)\n");
        return;
    }
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
    if (!coeur::NgspiceEngine::compile_avec_ngspice()) {
        std::printf("  (ngspice absent — section ignorée)\n");
        return;
    }

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
    if (!coeur::NgspiceEngine::compile_avec_ngspice()) {
        std::printf("  (ngspice absent — section ignorée)\n");
        return;
    }
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
    if (!coeur::AvrEngine::compile_avec_simavr() ||
        !coeur::AvrEngine::avr_gpp_disponible()) {
        std::printf("  (moteurs indisponibles — section ignorée)\n");
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
    if (coeur::NgspiceEngine::compile_avec_ngspice()) {
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
    if (coeur::NgspiceEngine::compile_avec_ngspice()) {
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
    if (coeur::NgspiceEngine::compile_avec_ngspice()) {
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
    if (coeur::NgspiceEngine::compile_avec_ngspice()) {
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
    if (coeur::NgspiceEngine::compile_avec_ngspice()) {
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
    if (!coeur::NgspiceEngine::compile_avec_ngspice()) {
        std::printf("  (ngspice absent — section ignorée)\n");
        return;
    }

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
        if (coeur::NgspiceEngine::compile_avec_ngspice()) {
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
// [17] Balayage en température et analyse de bruit : deux analyses que
// ngspice sait faire et qu'il fallait seulement savoir lui demander.
// ---------------------------------------------------------------------------
static void test_temperature_et_bruit() {
    std::printf("\n[17] Température et bruit\n");
    if (!coeur::NgspiceEngine::compile_avec_ngspice()) {
        std::printf("  (ngspice absent — section ignorée)\n");
        return;
    }

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
    if (!coeur::NgspiceEngine::compile_avec_ngspice()) {
        std::printf("  (ngspice absent — section ignorée)\n");
        return;
    }

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
    coeur::Instance& registre = netlist.ajouter("IC1", "registre_74hc595");
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
    if (coeur::NgspiceEngine::compile_avec_ngspice()) {
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
    }

    // --- fichiers de fabrication
    {
        const std::string cuivre = carte.gerber(0);
        verifier(cuivre.find("%FSLAX46Y46*%") != std::string::npos
                     && cuivre.find("%MOMM*%") != std::string::npos,
                 "Gerber : format et unités déclarés");
        verifier(cuivre.find("%ADD10C,") != std::string::npos,
                 "Gerber : au moins une ouverture définie");
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
int main() {
    std::printf("============================================================\n");
    std::printf("TESTS DU CŒUR — simulateur embarqué (C++)\n");
    std::printf("============================================================\n");
    std::printf("ngspice compilé : %s   |   simavr compilé : %s\n",
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
    test_campagnes();
    test_numerique();
    test_pcb();

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
