// Catalogue — Entrées et capteurs.
//
// Un composant = un bloc. Décrire le symbole, l'empreinte, les propriétés
// réglables et la traduction SPICE suffit : ni l'interface graphique ni les
// moteurs n'ont à être modifiés.
#include "core/catalogue/Traits.h"
#include "core/Netlist.h"

#include <cmath>

namespace coeur {

void enregistrer_capteurs(Catalogue& catalogue) {
    using G = Propriete::Genre;
    using namespace traits;
    auto enregistrer = [&catalogue](Modele m) {
        catalogue.enregistrer(std::move(m));
    };

    {   // -------------------------------------------------- bouton poussoir
        Modele m;
        m.type = "bouton";
        m.libelle = "Bouton poussoir";
        m.categorie = "Entrées";
        m.prefixe = "BP";
        m.bornes = {{"1", {-25, 0}, ""}, {"2", {25, 0}, ""}};
        m.proprietes = {{"appuye", "Appuyé", G::Nombre, 0, 0, 1, "", {}, ""}};
        m.symbole = {ligne(-25, 0, -12, 0), ligne(12, 0, 25, 0),
                     cercle(-12, 0, 2.5, true), cercle(12, 0, 2.5, true),
                     ligne(-14, -8, 14, -8),      // lame mobile
                     ligne(0, -8, 0, -16), rect(-8, -20, 8, -16, true)};
        m.empreinte = {"SW_PUSH_6MM",
                       {{"1", -3.25, 0.0, 1.8, 1.0}, {"2", 3.25, 0.0, 1.8, 1.0}},
                       6.0, 6.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            // fermé : 50 mΩ ; ouvert : 100 MΩ (jamais l'infini, SPICE n'aime pas)
            const bool appuye = i.valeur("appuye", 0) > 0.5;
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("1") + " " + noeud("2") + " "
                + (appuye ? "0.05" : "100e6")};
        };
        enregistrer(std::move(m));
    }
    {   // ---------------------------------------------------- potentiomètre
        Modele m;
        m.type = "potentiometre";
        m.libelle = "Potentiomètre";
        m.categorie = "Entrées";
        m.prefixe = "POT";
        m.bornes = {{"A", {-30, 15}, ""},
                    {"W", {0, -25}, "curseur"},
                    {"B", {30, 15}, ""}};
        m.proprietes = {
            {"ohms", "Valeur", G::Nombre, 10000, 0, 0, "", {}, "Ω"},
            {"position", "Position", G::Curseur, 50, 0, 100, "", {}, "%"}};
        m.symbole = {ligne(-30, 15, -18, 15), rect(-18, 8, 18, 22),
                     ligne(18, 15, 30, 15),
                     ligne(0, -25, 0, -6),
                     poly({{-5, -6}, {5, -6}, {0, 4}})};   // flèche du curseur
        m.empreinte = {"POT_TRIM_3362",
                       {{"A", -2.54, 0, 1.8, 1.0},
                        {"W", 0, 2.54, 1.8, 1.0},
                        {"B", 2.54, 0, 1.8, 1.0}},
                       9.5, 10.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            double total = i.valeur("ohms", 10000);
            double position = i.valeur("position", 50) / 100.0;
            if (position < 0) position = 0;
            if (position > 1) position = 1;
            double bas = total * position;          // curseur -> B
            double haut = total * (1.0 - position); // A -> curseur
            if (haut < 1) haut = 1;
            if (bas < 1) bas = 1;
            return std::vector<std::string>{
                "R" + i.reference + "A " + noeud("A") + " " + noeud("W") + " "
                    + nombre(haut),
                "R" + i.reference + "B " + noeud("W") + " " + noeud("B") + " "
                    + nombre(bas)};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------- capteur analogique
        Modele m;
        m.type = "capteur";
        m.libelle = "Capteur analogique";
        m.categorie = "Entrées";
        m.prefixe = "CAP";
        m.bornes = {{"V+", {-30, 20}, ""}, {"GND", {0, 20}, ""},
                    {"OUT", {30, 20}, "sortie"}};
        m.proprietes = {
            {"valeur", "Grandeur mesurée", G::Curseur, 25, 0, 100, "", {}, ""},
            {"mini", "Minimum", G::Nombre, 0, 0, 0, "", {}, ""},
            {"maxi", "Maximum", G::Nombre, 100, 0, 0, "", {}, ""}};
        m.symbole = {rect(-30, -20, 30, 20), texte(-24, 4, "CAPT", 11),
                     ligne(-30, 20, -30, 20)};
        m.empreinte = {"TO-92",
                       {{"V+", -1.27, 0, 1.6, 0.8}, {"GND", 0, 0, 1.6, 0.8},
                        {"OUT", 1.27, 0, 1.6, 0.8}},
                       4.8, 3.8};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            double mini = i.valeur("mini", 0), maxi = i.valeur("maxi", 100);
            double v = i.valeur("valeur", 25);
            double etendue = (maxi - mini) != 0 ? (maxi - mini) : 1;
            double fraction = (v - mini) / etendue;
            if (fraction < 0) fraction = 0;
            if (fraction > 1) fraction = 1;
            return std::vector<std::string>{
                "V" + i.reference + " " + i.reference + "_int " + noeud("GND")
                    + " DC " + nombre(fraction * 5.0),
                "R" + i.reference + " " + i.reference + "_int " + noeud("OUT")
                    + " 1k"};
        };
        enregistrer(std::move(m));
    }
    {   // -------------------------------------------------- photorésistance
        Modele m;
        m.type = "ldr";
        m.libelle = "Photorésistance (LDR)";
        m.categorie = "Entrées";
        m.prefixe = "LDR";
        m.bornes = {{"1", {-30, 0}, ""}, {"2", {30, 0}, ""}};
        m.proprietes = {
            {"luminosite", "Luminosité", G::Curseur, 50, 0, 100, "", {}, "%"}};
        m.symbole = {ligne(-30, 0, -18, 0), rect(-18, -8, 18, 8),
                     ligne(18, 0, 30, 0),
                     ligne(-10, -22, -4, -12), ligne(-6, -14, -4, -12),
                     ligne(-4, -16, -4, -12),
                     ligne(4, -22, 10, -12), ligne(8, -14, 10, -12),
                     ligne(10, -16, 10, -12)};
        m.empreinte = {"LDR_5MM", {{"1", -2.5, 0, 1.8, 0.9}, {"2", 2.5, 0, 1.8, 0.9}},
                       5.5, 4.5};
        // Réponse logarithmique : ~1 MΩ dans le noir, ~100 Ω en plein soleil.
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const double fraction = i.valeur("luminosite", 50) / 100.0;
            const double exposant = 6.0 - 4.0 * fraction;   // 10^6 .. 10^2
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("1") + " " + noeud("2") + " "
                + nombre(std::pow(10.0, exposant))};
        };
        enregistrer(std::move(m));
    }
    {   // -------------------------------------------------- thermistance CTN
        Modele m;
        m.type = "thermistance";
        m.libelle = "Thermistance CTN 10 kΩ";
        m.categorie = "Entrées";
        m.prefixe = "TH";
        m.bornes = {{"1", {-30, 0}, ""}, {"2", {30, 0}, ""}};
        m.proprietes = {
            {"temperature", "Température", G::Curseur, 25, -20, 120, "", {}, "°C"},
            {"r25", "Résistance à 25 °C", G::Nombre, 10000, 0, 0, "", {}, "Ω"},
            {"beta", "Coefficient B", G::Nombre, 3950, 0, 0, "", {}, "K"}};
        m.symbole = {ligne(-30, 0, -18, 0), rect(-18, -8, 18, 8),
                     ligne(18, 0, 30, 0), ligne(-22, 14, 22, -14),
                     texte(14, -12, "t", 9)};
        m.empreinte = {"TH_AXIAL", {{"1", -2.5, 0, 1.8, 0.9}, {"2", 2.5, 0, 1.8, 0.9}},
                       6.0, 3.0};
        // Loi de Steinhart simplifiée : R = R25 · exp(B·(1/T − 1/T25)).
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const double t = i.valeur("temperature", 25) + 273.15;
            const double r25 = i.valeur("r25", 10000);
            const double beta = i.valeur("beta", 3950);
            const double r = r25 * std::exp(beta * (1.0 / t - 1.0 / 298.15));
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("1") + " " + noeud("2") + " "
                + nombre(r)};
        };
        enregistrer(std::move(m));
    }
    {   // ---------------------------------------- capteur de température LM35
        Modele m;
        m.type = "lm35";
        m.libelle = "Capteur LM35 (10 mV/°C)";
        m.categorie = "Entrées";
        m.prefixe = "TC";
        m.bornes = {{"V+", {-25, 25}, ""}, {"OUT", {0, 25}, "sortie"},
                    {"GND", {25, 25}, ""}};
        m.proprietes = {
            {"temperature", "Température", G::Curseur, 25, -10, 120, "", {}, "°C"}};
        m.symbole = {poly({{-25, 25}, {25, 25}, {25, -5}, {-25, -5}}, false),
                     cercle(0, -5, 25), rect(-26, -6, 26, 26, true),
                     texte(-18, 12, "LM35", 10)};
        m.empreinte = {"TO-92", {{"V+", -1.27, 0, 1.6, 0.8}, {"OUT", 0, 0, 1.6, 0.8},
                                 {"GND", 1.27, 0, 1.6, 0.8}}, 4.8, 3.8};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const double volts = i.valeur("temperature", 25) * 0.01;
            return std::vector<std::string>{
                "V" + i.reference + " " + i.reference + "_int " + noeud("GND")
                    + " DC " + nombre(volts),
                "R" + i.reference + " " + i.reference + "_int " + noeud("OUT")
                    + " 100"};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------ interrupteur simple
        Modele m;
        m.type = "interrupteur";
        m.libelle = "Interrupteur";
        m.categorie = "Entrées";
        m.prefixe = "SW";
        m.bornes = {{"1", {-25, 0}, ""}, {"2", {25, 0}, ""}};
        m.proprietes = {{"ferme", "Fermé", G::Nombre, 0, 0, 1, "", {}, ""}};
        m.symbole = {ligne(-25, 0, -12, 0), ligne(12, 0, 25, 0),
                     cercle(-12, 0, 2.5, true), cercle(12, 0, 2.5, true),
                     ligne(-12, 0, 10, -14)};
        m.empreinte = {"SW_SPST", {{"1", -3.5, 0, 1.8, 1.0}, {"2", 3.5, 0, 1.8, 1.0}},
                       8.0, 5.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("1") + " " + noeud("2") + " "
                + (i.valeur("ferme", 0) > 0.5 ? "0.05" : "100e6")};
        };
        enregistrer(std::move(m));
    }
    {   // ----------------------------------------------------- DIP switch × 4
        Modele m;
        m.type = "dip_switch4";
        m.libelle = "Interrupteurs DIP × 4";
        m.categorie = "Entrées";
        m.prefixe = "DIP";
        for (int k = 0; k < 4; ++k) {
            const double y = -30 + k * 20;
            m.bornes.push_back({"A" + std::to_string(k + 1), {-35, y}, ""});
            m.bornes.push_back({"B" + std::to_string(k + 1), {35, y}, ""});
            m.symbole.push_back(ligne(-35, y, -18, y));
            m.symbole.push_back(ligne(18, y, 35, y));
            m.symbole.push_back(ligne(-18, y, 14, y - 8));
        }
        m.symbole.insert(m.symbole.begin(), rect(-22, -40, 22, 40));
        m.proprietes = {
            {"etat1", "Voie 1 fermée", G::Nombre, 0, 0, 1, "", {}, ""},
            {"etat2", "Voie 2 fermée", G::Nombre, 0, 0, 1, "", {}, ""},
            {"etat3", "Voie 3 fermée", G::Nombre, 0, 0, 1, "", {}, ""},
            {"etat4", "Voie 4 fermée", G::Nombre, 0, 0, 1, "", {}, ""}};
        m.empreinte = {"DIP-8", {}, 10.0, 9.8};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            std::vector<std::string> lignes;
            for (int k = 1; k <= 4; ++k) {
                const std::string voie = std::to_string(k);
                const bool ferme = i.valeur("etat" + voie, 0) > 0.5;
                lignes.push_back("R" + i.reference + voie + " " + noeud("A" + voie)
                                 + " " + noeud("B" + voie) + " "
                                 + (ferme ? "0.05" : "100e6"));
            }
            return lignes;
        };
        enregistrer(std::move(m));
    }
}

}  // namespace coeur
