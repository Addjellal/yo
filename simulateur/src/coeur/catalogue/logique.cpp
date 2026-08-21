// Catalogue — portes logiques et circuits intégrés analogiques.
//
// Les portes ne sont pas simulées « en logique » : elles sont décrites par
// des sources comportementales de ngspice (sources B). Elles vivent donc dans
// le même solveur que le reste du circuit, avec de vraies tensions, une vraie
// impédance de sortie, et elles chargent réellement ce qui les alimente.
#include <string>
#include <vector>

#include "coeur/Netlist.h"
#include "coeur/catalogue/Traits.h"

namespace coeur {

namespace {

using namespace traits;

// Symbole rectangulaire à deux entrées et une sortie.
void symbole_porte(Modele& m, const std::string& etiquette, bool inverseuse) {
    m.symbole = {rect(-25, -25, 20, 25), texte(-20, 6, etiquette, 12),
                 ligne(-40, -14, -25, -14), ligne(-40, 14, -25, 14),
                 ligne(inverseuse ? 26 : 20, 0, 40, 0)};
    if (inverseuse) m.symbole.push_back(cercle(23, 0, 3.5));
}

// Fabrique une porte à deux entrées à partir de son expression booléenne.
// `expression` utilise $a et $b, déjà seuillés à 2,5 V. Attention à la syntaxe
// des sources B : ngspice veut && et ||, jamais & ni |.
Modele porte(const std::string& type, const std::string& libelle,
             const std::string& etiquette, const std::string& expression,
             bool inverseuse) {
    Modele m;
    m.type = type;
    m.libelle = libelle;
    m.categorie = "Logique";
    m.prefixe = "U";
    m.bornes = {{"A", {-40, -14}, ""}, {"B", {-40, 14}, ""},
                {"Y", {40, 0}, "sortie"}};
    symbole_porte(m, etiquette, inverseuse);
    m.empreinte = {"DIP-14", {}, 19.0, 6.4};
    m.vers_spice = [expression](const Instance& i, const auto& noeud) {
        const std::string ref = i.reference;
        // Seuil d'entrée 2,5 V, sortie 0 ou 5 V derrière 50 Ω : le
        // comportement d'une famille CMOS alimentée en 5 V.
        std::string formule = expression;
        const std::string a = "(V(" + noeud("A") + ") > 2.5)";
        const std::string b = "(V(" + noeud("B") + ") > 2.5)";
        std::string::size_type position;
        while ((position = formule.find("$a")) != std::string::npos)
            formule.replace(position, 2, a);
        while ((position = formule.find("$b")) != std::string::npos)
            formule.replace(position, 2, b);
        return std::vector<std::string>{
            "B" + ref + " " + ref + "_out 0 V = (" + formule + ") ? 5 : 0",
            "R" + ref + " " + ref + "_out " + noeud("Y") + " 50"};
    };
    return m;
}

}  // namespace

void enregistrer_logique(Catalogue& catalogue) {
    using G = Propriete::Genre;

    catalogue.enregistrer(porte("porte_et", "Porte ET", "&", "$a && $b", false));
    catalogue.enregistrer(porte("porte_ou", "Porte OU", "≥1", "$a || $b", false));
    catalogue.enregistrer(
        porte("porte_nand", "Porte NON-ET", "&", "!($a && $b)", true));
    catalogue.enregistrer(
        porte("porte_nor", "Porte NON-OU", "≥1", "!($a || $b)", true));
    catalogue.enregistrer(
        porte("porte_xor", "Porte OU exclusif", "=1", "$a != $b", false));

    {   // ------------------------------------------------------- inverseur
        Modele m;
        m.type = "porte_non";
        m.libelle = "Inverseur";
        m.categorie = "Logique";
        m.prefixe = "U";
        m.bornes = {{"A", {-40, 0}, ""}, {"Y", {40, 0}, "sortie"}};
        m.symbole = {poly({{-22, -22}, {-22, 22}, {18, 0}}, false),
                     cercle(21, 0, 3.5), ligne(-40, 0, -22, 0),
                     ligne(25, 0, 40, 0)};
        m.empreinte = {"DIP-14", {}, 19.0, 6.4};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const std::string ref = i.reference;
            return std::vector<std::string>{
                "B" + ref + " " + ref + "_out 0 V = (V(" + noeud("A")
                    + ") > 2.5) ? 0 : 5",
                "R" + ref + " " + ref + "_out " + noeud("Y") + " 50"};
        };
        catalogue.enregistrer(std::move(m));
    }
    {   // ----------------------------------------- amplificateur opérationnel
        Modele m;
        m.type = "ampli_op";
        m.libelle = "Amplificateur opérationnel";
        m.categorie = "Logique";
        m.prefixe = "A";
        m.bornes = {{"IN+", {-40, -15}, "entrée +"}, {"IN-", {-40, 15}, "entrée −"},
                    {"OUT", {40, 0}, "sortie"}};
        m.proprietes = {
            {"gain", "Gain en boucle ouverte", G::Nombre, 200000, 0, 0, "", {}, ""},
            {"vmax", "Tension de sortie maximale", G::Nombre, 4.9, 0, 0, "", {}, "V"}};
        m.symbole = {poly({{-25, -30}, {-25, 30}, {25, 0}}, false),
                     ligne(-40, -15, -25, -15), ligne(-40, 15, -25, 15),
                     ligne(25, 0, 40, 0), texte(-20, -10, "+", 11),
                     texte(-20, 20, "−", 11)};
        m.empreinte = {"DIP-8", {}, 9.8, 6.4};
        // Macromodèle : gain énorme, sortie bornée par l'alimentation, et une
        // résistance de sortie qui empêche la source idéale de tout imposer.
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const std::string ref = i.reference;
            const double gain = i.valeur("gain", 200000);
            const double vmax = i.valeur("vmax", 4.9);
            return std::vector<std::string>{
                // ngspice n'a pas de limit() à trois arguments : le bornage
                // se fait avec min et max, qui eux sont bien définis.
                "B" + ref + " " + ref + "_out 0 V = min(max(" + nombre(gain)
                    + " * (V(" + noeud("IN+") + ") - V(" + noeud("IN-")
                    + ")), 0.05), " + nombre(vmax) + ")",
                "R" + ref + " " + ref + "_out " + noeud("OUT") + " 75",
                "R" + ref + "_inp " + noeud("IN+") + " 0 1e9",
                "R" + ref + "_inn " + noeud("IN-") + " 0 1e9"};
        };
        catalogue.enregistrer(std::move(m));
    }
    {   // ---------------------------------------------- régulateur 5 V (7805)
        Modele m;
        m.type = "regulateur_5v";
        m.libelle = "Régulateur 5 V (7805)";
        m.categorie = "Alimentation";
        m.prefixe = "REG";
        m.bornes = {{"IN", {-40, 0}, "entrée"}, {"GND", {0, 30}, ""},
                    {"OUT", {40, 0}, "sortie"}};
        m.symbole = {rect(-28, -20, 28, 20), texte(-22, 4, "7805", 11),
                     ligne(-40, 0, -28, 0), ligne(28, 0, 40, 0),
                     ligne(0, 20, 0, 30)};
        m.empreinte = {"TO-220", {{"IN", -2.54, 0, 1.8, 1.1},
                                  {"GND", 0, 0, 1.8, 1.1},
                                  {"OUT", 2.54, 0, 1.8, 1.1}}, 10.0, 4.5};
        // 5 V en sortie, sauf si l'entrée est trop basse : il faut environ
        // 2 V de marge, comme sur le composant réel.
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const std::string ref = i.reference;
            return std::vector<std::string>{
                "B" + ref + " " + ref + "_out " + noeud("GND")
                    + " V = min(V(" + noeud("IN") + "," + noeud("GND")
                    + ") - 2, 5)",
                "R" + ref + " " + ref + "_out " + noeud("OUT") + " 0.1"};
        };
        catalogue.enregistrer(std::move(m));
    }
}

}  // namespace coeur
