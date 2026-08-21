// Catalogue — capteurs.
//
// Deux familles s'y côtoient.
//
// Les **capteurs analogiques** sortent une tension : accéléromètre ADXL335,
// capteur de courant ACS712, gaz, humidité du sol. Ils se décrivent par une
// source, comme n'importe quelle alimentation — rien de particulier.
//
// Les **capteurs à protocole** répondent par un signal daté : le télémètre à
// ultrasons renvoie une impulsion dont la largeur est la distance, le codeur
// incrémental émet deux voies en quadrature. Ceux-là ont besoin de savoir où
// on en est dans la fenêtre de calcul : ils utilisent `vers_spice_transitoire`
// et gardent leur état d'une fenêtre à l'autre.
#include <cmath>
#include <sstream>
#include <string>
#include <vector>

#include "coeur/Netlist.h"
#include "coeur/catalogue/Traits.h"

namespace coeur {

namespace {

std::string arrondi(double valeur, int decimales) {
    char tampon[48];
    std::snprintf(tampon, sizeof tampon, "%.*f", decimales, valeur);
    return tampon;
}

// Source de tension continue derrière une résistance de sortie : c'est la
// forme que prend tout capteur analogique vu du circuit.
std::vector<std::string> sortie_analogique(const Instance& i,
                                           const std::string& borne_sortie,
                                           const std::string& masse,
                                           double volts, const char* suffixe,
                                           double impedance = 1000) {
    const std::string interne = i.reference + "_" + suffixe;
    return {"V" + i.reference + suffixe + " " + interne + " " + masse + " DC " +
                traits::nombre(volts),
            "R" + i.reference + suffixe + " " + interne + " " + borne_sortie +
                " " + traits::nombre(impedance)};
}

}  // namespace

void enregistrer_capteurs_avances(Catalogue& catalogue) {
    using G = Propriete::Genre;
    using namespace traits;
    auto enregistrer = [&catalogue](Modele m) {
        catalogue.enregistrer(std::move(m));
    };

    {   // ------------------------------------------- accéléromètre analogique
        Modele m;
        m.type = "accelerometre";
        m.libelle = "Accéléromètre 3 axes (ADXL335)";
        m.categorie = "Entrées";
        m.prefixe = "ACC";
        m.bornes = {{"V+", {-40, -30}, "3,3 V"}, {"GND", {-40, 30}, ""},
                    {"X", {40, -30}, ""}, {"Y", {40, 0}, ""}, {"Z", {40, 30}, ""}};
        m.proprietes = {
            {"ax", "Accélération X", G::Curseur, 0, -3, 3, "", {}, "g"},
            {"ay", "Accélération Y", G::Curseur, 0, -3, 3, "", {}, "g"},
            {"az", "Accélération Z", G::Curseur, 1, -3, 3, "", {}, "g"},
            {"sensibilite", "Sensibilité", G::Nombre, 0.33, 0, 0, "", {}, "V/g"}};
        m.symbole = {rect(-30, -40, 30, 40), texte(-24, -14, "ADXL", 10),
                     texte(-24, 2, "335", 10),
                     ligne(-40, -30, -30, -30), ligne(-40, 30, -30, 30),
                     ligne(30, -30, 40, -30), ligne(30, 0, 40, 0),
                     ligne(30, 30, 40, 30),
                     texte(-10, 24, "X Y Z", 9)};
        m.empreinte = {"ADXL335_MODULE", {}, 19.0, 19.0};
        // Zéro à mi-alimentation, puis 330 mV par g : c'est la fiche technique.
        // Au repos, Z lit 1 g — la pesanteur. Un débutant qui l'ignore croit
        // son capteur faux.
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const double zero = 1.65;
            const double s = i.valeur("sensibilite", 0.33);
            std::vector<std::string> lignes;
            const struct { const char* borne; const char* cle; const char* sfx; }
                axes[] = {{"X", "ax", "x"}, {"Y", "ay", "y"}, {"Z", "az", "z"}};
            for (const auto& axe : axes) {
                double volts = zero + i.valeur(axe.cle, 0) * s;
                if (volts < 0) volts = 0;
                if (volts > 3.3) volts = 3.3;
                for (const std::string& ligne : sortie_analogique(
                         i, noeud(axe.borne), noeud("GND"), volts, axe.sfx, 32000))
                    lignes.push_back(ligne);
            }
            return lignes;
        };
        m.lecture = [](const Instance& i) {
            return "X " + arrondi(i.valeur("ax", 0), 2) + "  Y " +
                   arrondi(i.valeur("ay", 0), 2) + "  Z " +
                   arrondi(i.valeur("az", 1), 2) + " g";
        };
        enregistrer(std::move(m));
    }

    {   // --------------------------------------- télémètre à ultrasons HC-SR04
        Modele m;
        m.type = "telemetre_ultrason";
        m.libelle = "Télémètre à ultrasons (HC-SR04)";
        m.categorie = "Entrées";
        m.prefixe = "US";
        m.bornes = {{"V+", {-40, -30}, "5 V"}, {"TRIG", {-40, -10}, "déclenche"},
                    {"ECHO", {-40, 10}, "écho"}, {"GND", {-40, 30}, ""}};
        m.proprietes = {
            {"distance", "Distance mesurée", G::Curseur, 50, 2, 400, "", {}, "cm"}};
        m.symbole = {rect(-30, -40, 30, 40), cercle(-12, -16, 12),
                     cercle(12, -16, 12), texte(-26, 22, "HC-SR04", 9),
                     ligne(-40, -30, -30, -30), ligne(-40, -10, -30, -10),
                     ligne(-40, 10, -30, 10), ligne(-40, 30, -30, 30)};
        m.empreinte = {"HCSR04", {}, 45.0, 20.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "R" + i.reference + "_trig " + noeud("TRIG") + " " +
                    noeud("GND") + " 100k",
                "R" + i.reference + "_echo " + noeud("ECHO") + " " +
                    noeud("GND") + " 200"};
        };
        // L'écho est une impulsion datée : sa largeur est le temps de vol,
        // 58 µs par centimètre aller-retour. C'est ce que mesure pulseIn().
        m.vers_spice_transitoire = [](const Instance& i, const auto& noeud,
                                      double duree) {
            std::vector<std::string> lignes = {
                "R" + i.reference + "_trig " + noeud("TRIG") + " " +
                    noeud("GND") + " 100k"};

            const double debut = i.valeur("_echo_debut", -1);
            const double largeur = i.valeur("distance", 50) * 58e-6;
            if (debut < 0 || largeur <= 0 || debut > duree) {
                lignes.push_back("R" + i.reference + "_echo " + noeud("ECHO") +
                                 " " + noeud("GND") + " 200");
                return lignes;
            }
            const double fin = std::min(duree, debut + largeur);
            const double front = 1e-6;
            std::ostringstream f;
            f << "V" << i.reference << "_echo " << i.reference << "_es "
              << noeud("GND") << " PWL(";
            // Une PWL n'accepte pas deux points au même instant : quand
            // l'écho démarre à l'origine de la fenêtre, on part directement
            // du niveau haut au lieu d'insérer un front de largeur nulle.
            if (debut <= front)
                f << "0 5";
            else
                f << "0 0 " << nombre(debut - front) << " 0 " << nombre(debut)
                  << " 5";
            f << " " << nombre(fin) << " 5 " << nombre(fin + front) << " 0 "
              << nombre(duree + front * 2) << " 0)";
            lignes.push_back(f.str());
            lignes.push_back("R" + i.reference + "_echo " + i.reference + "_es " +
                             noeud("ECHO") + " 200");
            return lignes;
        };
        m.evoluer = [](Instance& i, const Evolution& evolution) {
            // Le module attend une impulsion d'au moins 10 µs sur TRIG, puis
            // répond après un court délai. On arme l'écho pour la fenêtre
            // suivante : c'est plus simple et invisible à l'échelle du
            // programme, qui attend de toute façon des millisecondes.
            // Le module réel ne répond pas instantanément : il émet sa salve
            // puis attend le retour. Ce délai n'est pas cosmétique — sans lui
            // l'écho commencerait à l'instant zéro de la fenêtre, sans front
            // montant, et aucun pulseIn() ne le mesurerait.
            const double declenche = evolution.largeur_impulsion("TRIG");
            i.valeurs["_echo_debut"] = declenche >= 5e-6 ? 450e-6 : -1.0;
            if (declenche >= 5e-6) i.valeurs["_mesures"] = i.valeur("_mesures", 0) + 1;
        };
        m.lecture = [](const Instance& i) {
            return arrondi(i.valeur("distance", 50), 0) + " cm";
        };
        enregistrer(std::move(m));
    }

    {   // ------------------------------------------- codeur incrémental
        Modele m;
        m.type = "codeur_incremental";
        m.libelle = "Codeur incrémental (quadrature)";
        m.categorie = "Entrées";
        m.prefixe = "COD";
        m.bornes = {{"V+", {-40, -30}, "5 V"}, {"A", {40, -15}, "voie A"},
                    {"B", {40, 15}, "voie B"}, {"GND", {-40, 30}, ""}};
        m.proprietes = {
            {"tr_min", "Vitesse", G::Curseur, 60, -300, 300, "", {}, "tr/min"},
            {"impulsions", "Impulsions par tour", G::Nombre, 20, 0, 0, "", {}, ""}};
        m.symbole = {cercle(0, 0, 30), ligne(0, -30, 0, 30),
                     ligne(-30, 0, 30, 0), cercle(0, 0, 8, true),
                     ligne(-40, -30, -21, -21), ligne(-40, 30, -21, 21),
                     ligne(30, -15, 40, -15), ligne(30, 15, 40, 15)};
        m.empreinte = {"CODEUR", {}, 30.0, 30.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "R" + i.reference + "A " + noeud("A") + " " + noeud("GND") + " 1k",
                "R" + i.reference + "B " + noeud("B") + " " + noeud("GND") + " 1k"};
        };
        // Deux créneaux décalés d'un quart de période : le décalage donne le
        // sens de rotation, et c'est tout l'intérêt d'un codeur en quadrature.
        m.vers_spice_transitoire = [](const Instance& i, const auto& noeud,
                                      double duree) {
            const double tr_min = i.valeur("tr_min", 60);
            const double par_tour = std::max(1.0, i.valeur("impulsions", 20));
            const double frequence = std::fabs(tr_min) / 60.0 * par_tour;
            if (frequence < 0.5) {
                return std::vector<std::string>{
                    "R" + i.reference + "A " + noeud("A") + " " + noeud("GND") + " 1k",
                    "R" + i.reference + "B " + noeud("B") + " " + noeud("GND") + " 1k"};
            }
            const double periode = 1.0 / frequence;
            const double phase = i.valeur("_phase", 0);
            // Un retard négatif inverse le décalage, donc le sens lu.
            const double retard = (tr_min >= 0 ? 0.25 : -0.25) * periode;

            auto creneau = [&](const char* voie, double decalage) {
                std::ostringstream f;
                f << "V" << i.reference << voie << " " << i.reference << "_" << voie
                  << " " << noeud("GND") << " PULSE(0 5 "
                  << nombre(std::fmod(periode * 4 + decalage - phase * periode,
                                      periode))
                  << " 1u 1u " << nombre(periode / 2 - 2e-6) << " "
                  << nombre(periode) << ")";
                return f.str();
            };
            (void)duree;
            return std::vector<std::string>{
                creneau("A", 0), creneau("B", retard),
                "R" + i.reference + "A " + i.reference + "_A " + noeud("A") + " 220",
                "R" + i.reference + "B " + i.reference + "_B " + noeud("B") + " 220"};
        };
        m.evoluer = [](Instance& i, const Evolution& evolution) {
            // On garde la phase d'une fenêtre à l'autre, sinon les créneaux
            // repartiraient de zéro à chaque trame et le comptage serait faux.
            const double tr_min = i.valeur("tr_min", 60);
            const double par_tour = std::max(1.0, i.valeur("impulsions", 20));
            const double frequence = std::fabs(tr_min) / 60.0 * par_tour;
            const double avance = frequence * evolution.duree;
            i.valeurs["_phase"] = std::fmod(i.valeur("_phase", 0) + avance, 1.0);
            i.valeurs["tours"] =
                i.valeur("tours", 0) + tr_min * evolution.duree / 60.0;
        };
        m.lecture = [](const Instance& i) {
            return arrondi(i.valeur("tr_min", 60), 0) + " tr/min";
        };
        enregistrer(std::move(m));
    }

    {   // --------------------------------------- capteur de courant ACS712
        Modele m;
        m.type = "capteur_courant";
        m.libelle = "Capteur de courant (ACS712)";
        m.categorie = "Instruments";
        m.prefixe = "CC";
        m.bornes = {{"IP+", {-40, -25}, "entrée"}, {"IP-", {40, -25}, "sortie"},
                    {"V+", {-40, 25}, "5 V"}, {"OUT", {40, 25}, "mesure"},
                    {"GND", {0, 45}, ""}};
        m.proprietes = {
            {"calibre", "Calibre", G::Choix, 0, 0, 0, "5 A", {"5 A", "20 A", "30 A"}, ""}};
        m.symbole = {rect(-32, -35, 32, 35), texte(-26, -6, "ACS712", 10),
                     ligne(-40, -25, -32, -25), ligne(32, -25, 40, -25),
                     ligne(-40, 25, -32, 25), ligne(32, 25, 40, 25),
                     ligne(0, 35, 0, 45)};
        m.empreinte = {"SOIC-8", {}, 6.0, 5.0};
        // Le conducteur mesuré traverse une résistance de 1,2 mΩ : c'est
        // l'intérêt du capteur à effet Hall, il n'insère quasiment rien.
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const std::string calibre = i.texte("calibre", "5 A");
            const double sensibilite =
                calibre == "20 A" ? 0.100 : (calibre == "30 A" ? 0.066 : 0.185);
            const double sortie = 2.5 + i.valeur("_courant", 0) * sensibilite;
            std::vector<std::string> lignes = {
                "R" + i.reference + "_shunt " + noeud("IP+") + " " + noeud("IP-") +
                    " 0.0012"};
            for (const std::string& ligne : sortie_analogique(
                     i, noeud("OUT"), noeud("GND"),
                     sortie < 0 ? 0 : (sortie > 5 ? 5 : sortie), "out", 1200))
                lignes.push_back(ligne);
            return lignes;
        };
        m.evoluer = [](Instance& i, const Evolution& evolution) {
            // Le courant mesuré est celui qui traverse réellement le shunt :
            // le capteur mesure le circuit, il ne le simule pas.
            const double amont = evolution.moyenne("IP+");
            const double aval = evolution.moyenne("IP-");
            i.valeurs["_courant"] = (amont - aval) / 0.0012;
        };
        m.lecture = [](const Instance& i) {
            return arrondi(i.valeur("_courant", 0), 2) + " A";
        };
        enregistrer(std::move(m));
    }

    {   // ------------------------------------- capteurs analogiques simples
        //
        // Même forme pour tous : un curseur règle la grandeur, une source la
        // traduit en tension. Les décrire ensemble évite cinq blocs jumeaux.
        struct Simple {
            const char* type;
            const char* libelle;
            const char* prefixe;
            const char* grandeur;   // libellé du curseur
            const char* unite;
            double mini, maxi, defaut;
            double volts_min, volts_max;
            const char* abrege;
        };
        const Simple simples[] = {
            {"capteur_gaz", "Capteur de gaz (MQ-2)", "MQ", "Concentration",
             "ppm", 0, 1000, 100, 0.3, 4.5, "MQ-2"},
            {"capteur_humidite_sol", "Humidité du sol", "HS", "Humidité",
             "%", 0, 100, 40, 4.5, 0.8, "SOL"},
            {"capteur_lumiere", "Capteur de lumière (module LDR)", "LUM",
             "Éclairement", "%", 0, 100, 50, 0.2, 4.8, "LUM"},
            {"capteur_pression", "Capteur de pression (MPX)", "PRS", "Pression",
             "kPa", 0, 100, 50, 0.2, 4.7, "MPX"},
            {"capteur_ph", "Sonde pH", "PH", "pH", "", 0, 14, 7, 0.5, 4.5, "pH"},
        };

        for (const Simple& s : simples) {
            Modele m;
            m.type = s.type;
            m.libelle = s.libelle;
            m.categorie = "Entrées";
            m.prefixe = s.prefixe;
            m.bornes = {{"V+", {-30, 25}, "5 V"}, {"GND", {0, 25}, ""},
                        {"OUT", {30, 25}, "sortie"}};
            m.proprietes = {{"valeur", s.grandeur, G::Curseur, s.defaut, s.mini,
                             s.maxi, "", {}, s.unite}};
            m.symbole = {rect(-32, -25, 32, 25), texte(-26, 4, s.abrege, 11),
                         ligne(-30, 25, -30, 25)};
            m.empreinte = {"MODULE_3P", {}, 20.0, 15.0};

            const double mini = s.mini, maxi = s.maxi;
            const double v_min = s.volts_min, v_max = s.volts_max;
            m.vers_spice = [mini, maxi, v_min, v_max](const Instance& i,
                                                      const auto& noeud) {
                const double etendue = (maxi - mini) != 0 ? (maxi - mini) : 1;
                double fraction = (i.valeur("valeur", 0) - mini) / etendue;
                if (fraction < 0) fraction = 0;
                if (fraction > 1) fraction = 1;
                // Une sonde d'humidité du sol renvoie une tension qui *baisse*
                // quand la terre est humide : v_min peut donc dépasser v_max,
                // et l'interpolation le gère sans cas particulier.
                const double volts = v_min + (v_max - v_min) * fraction;
                return sortie_analogique(i, noeud("OUT"), noeud("GND"), volts,
                                         "out", 1000);
            };
            const std::string unite = s.unite;
            m.lecture = [unite](const Instance& i) {
                return arrondi(i.valeur("valeur", 0), 1) +
                       (unite.empty() ? "" : " " + unite);
            };
            enregistrer(std::move(m));
        }
    }
}

}  // namespace coeur
