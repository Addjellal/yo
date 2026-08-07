// Catalogue — Électromécanique et actionneurs.
//
// Un composant = un bloc. Décrire le symbole, l'empreinte, les propriétés
// réglables et la traduction SPICE suffit : ni l'interface graphique ni les
// moteurs n'ont à être modifiés.
#include "core/catalogue/Traits.h"
#include "core/Netlist.h"

namespace coeur {

void enregistrer_electromecanique(Catalogue& catalogue) {
    using G = Propriete::Genre;
    using namespace traits;
    auto enregistrer = [&catalogue](Modele m) {
        catalogue.enregistrer(std::move(m));
    };

    {   // ------------------------------------------------------------ buzzer
        Modele m;
        m.type = "buzzer";
        m.libelle = "Buzzer piézo";
        m.categorie = "Affichage";
        m.prefixe = "BZ";
        m.bornes = {{"+", {-20, 20}, ""}, {"-", {20, 20}, ""}};
        m.symbole = {ligne(-20, 20, -20, 6), ligne(20, 20, 20, 6),
                     cercle(0, -2, 18), cercle(0, -2, 6, true),
                     ligne(-20, 6, 20, 6)};
        m.empreinte = {"BUZZER_12MM",
                       {{"+", -3.5, 0, 1.8, 1.0}, {"-", 3.5, 0, 1.8, 1.0}},
                       12.0, 12.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("+") + " " + noeud("-") + " 300"};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------------------ relais
        Modele m;
        m.type = "relais";
        m.libelle = "Relais 5 V (1 RT)";
        m.categorie = "Actionneurs";
        m.prefixe = "K";
        m.bornes = {{"A", {-40, -25}, "bobine +"}, {"B", {-40, 25}, "bobine −"},
                    {"COM", {40, 0}, "commun"}, {"NO", {40, -30}, "travail"},
                    {"NC", {40, 30}, "repos"}};
        m.proprietes = {
            {"bobine", "Résistance de bobine", G::Nombre, 120, 0, 0, "", {}, "Ω"}};
        m.symbole = {rect(-30, -20, -10, 20),
                     ligne(-40, -25, -20, -25), ligne(-20, -25, -20, -20),
                     ligne(-40, 25, -20, 25), ligne(-20, 25, -20, 20),
                     ligne(-10, 0, 6, 0),                  // liaison mécanique
                     cercle(10, 0, 2.5, true), ligne(40, 0, 12, 0),
                     cercle(24, -30, 2.5, true), ligne(40, -30, 26, -30),
                     cercle(24, 30, 2.5, true), ligne(40, 30, 26, 30),
                     ligne(12, 0, 24, 28)};
        m.directives = {".model RELAIS_SW SW(VT=2.5 VH=0.4 RON=0.05 ROFF=1e9)"};
        m.empreinte = {"RELAY_SRD05", {}, 19.0, 15.5};
        // Le contact est réellement commandé par la tension de bobine : c'est
        // un interrupteur SPICE, pas une case à cocher.
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const std::string ref = i.reference;
            return std::vector<std::string>{
                "R" + ref + "_bobine " + noeud("A") + " " + noeud("B") + " "
                    + nombre(i.valeur("bobine", 120)),
                "S" + ref + "_no " + noeud("COM") + " " + noeud("NO") + " "
                    + noeud("A") + " " + noeud("B") + " RELAIS_SW",
                // contact repos : commandé par la négation de la bobine
                "B" + ref + "_inv " + ref + "_inv 0 V = (V(" + noeud("A")
                    + "," + noeud("B") + ") > 2.5) ? 0 : 5",
                "S" + ref + "_nc " + noeud("COM") + " " + noeud("NC") + " "
                    + ref + "_inv 0 RELAIS_SW"};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------------- moteur à CC
        Modele m;
        m.type = "moteur_cc";
        m.libelle = "Moteur à courant continu";
        m.categorie = "Actionneurs";
        m.prefixe = "M";
        m.bornes = {{"+", {-35, 0}, ""}, {"-", {35, 0}, ""}};
        m.proprietes = {
            {"resistance", "Résistance d'induit", G::Nombre, 8, 0, 0, "", {}, "Ω"},
            {"inductance", "Inductance", G::Nombre, 1e-3, 0, 0, "", {}, "H"}};
        m.symbole = {cercle(0, 0, 24), ligne(-35, 0, -24, 0), ligne(24, 0, 35, 0),
                     texte(-8, 5, "M", 14)};
        m.empreinte = {"MOTEUR", {{"+", -5, 0, 2.0, 1.2}, {"-", 5, 0, 2.0, 1.2}},
                       25.0, 20.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const std::string ref = i.reference;
            return std::vector<std::string>{
                "R" + ref + " " + noeud("+") + " " + ref + "_int "
                    + nombre(i.valeur("resistance", 8)),
                "L" + ref + " " + ref + "_int " + noeud("-") + " "
                    + nombre(i.valeur("inductance", 1e-3))};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------------ haut-parleur
        Modele m;
        m.type = "haut_parleur";
        m.libelle = "Haut-parleur 8 Ω";
        m.categorie = "Actionneurs";
        m.prefixe = "HP";
        m.bornes = {{"+", {-35, -15}, ""}, {"-", {-35, 15}, ""}};
        m.proprietes = {
            {"impedance", "Impédance", G::Nombre, 8, 0, 0, "", {}, "Ω"}};
        m.symbole = {ligne(-35, -15, -18, -15), ligne(-35, 15, -18, 15),
                     rect(-18, -16, -4, 16, true),
                     poly({{-4, -16}, {-4, 16}, {16, 30}, {16, -30}}, false)};
        m.empreinte = {"HP_28MM", {{"+", -8, 0, 2.0, 1.2}, {"-", 8, 0, 2.0, 1.2}},
                       28.0, 28.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("+") + " " + noeud("-") + " "
                + nombre(i.valeur("impedance", 8))};
        };
        enregistrer(std::move(m));
    }
}

}  // namespace coeur
