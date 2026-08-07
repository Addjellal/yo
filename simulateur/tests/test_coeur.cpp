// Tests du cœur : netlist, catalogue, moteur analogique (ngspice) et
// moteur microcontrôleur (simavr), puis leur COUPLAGE — c'est ce couplage
// qui fait un simulateur de type Proteus.
//
// Aucun écran nécessaire : ./tests_coeur

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

#include "core/Device.h"
#include "core/Netlist.h"
#include "core/engines/AvrEngine.h"
#include "core/engines/NgspiceEngine.h"

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
            else if (k == dernier)
                netlist.relier("X1", borne, "GND");
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
