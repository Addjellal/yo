// Catalogue — Passifs et alimentation.
//
// Un composant = un bloc. Décrire le symbole, l'empreinte, les propriétés
// réglables et la traduction SPICE suffit : ni l'interface graphique ni les
// moteurs n'ont à être modifiés.
#include "core/catalogue/Traits.h"
#include "core/Netlist.h"

namespace coeur {

void enregistrer_base(Catalogue& catalogue) {
    using G = Propriete::Genre;
    using namespace traits;
    auto enregistrer = [&catalogue](Modele m) {
        catalogue.enregistrer(std::move(m));
    };

    {   // ----------------------------------------------------- résistance
        Modele m;
        m.type = "resistance";
        m.libelle = "Résistance";
        m.categorie = "Passifs";
        m.prefixe = "R";
        m.bornes = {{"1", {-30, 0}, ""}, {"2", {30, 0}, ""}};
        m.proprietes = {{"ohms", "Valeur", G::Nombre, 220, 0, 0, "", {}, "Ω"},
                        {"watts", "Puissance admissible", G::Nombre, 0.25, 0, 0,
                         "", {}, "W"}};
        // La traversante ordinaire du tiroir : un quart de watt. C'est la
        // limite que l'on dépasse sans s'en apercevoir en mettant 12 V aux
        // bornes d'un 220 Ω — 0,65 W, elle brunit puis se coupe.
        m.puissance_max = 0.25;
        m.symbole = {ligne(-30, 0, -18, 0), rect(-18, -7, 18, 7),
                     ligne(18, 0, 30, 0)};
        m.empreinte = {"R_AXIAL_0207",
                       {{"1", -5.0, 0.0, 1.6, 0.8}, {"2", 5.0, 0.0, 1.6, 0.8}},
                       12.0, 3.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("1") + " " + noeud("2") + " "
                + nombre(i.valeur("ohms", 220))};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------------ condensateur
        Modele m;
        m.type = "condensateur";
        m.libelle = "Condensateur";
        m.categorie = "Passifs";
        m.prefixe = "C";
        m.bornes = {{"1", {-25, 0}, ""}, {"2", {25, 0}, ""}};
        m.proprietes = {{"farads", "Capacité", G::Nombre, 1e-7, 0, 0, "", {}, "F"},
                        {"volts_max", "Tension de service", G::Nombre, 50, 0, 0,
                         "", {}, "V"}};
        // 50 V : la tenue d'un céramique ou d'un film courant. Un
        // électrolytique de 16 V se déclare par la propriété — et c'est lui
        // qui explose pour de bon quand on l'oublie.
        m.tension_max = 50;
        m.symbole = {ligne(-25, 0, -4, 0), ligne(-4, -12, -4, 12),
                     ligne(4, -12, 4, 12), ligne(4, 0, 25, 0)};
        m.empreinte = {"C_DISC_5MM",
                       {{"1", -2.5, 0, 1.6, 0.8}, {"2", 2.5, 0, 1.6, 0.8}},
                       5.0, 3.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "C" + i.reference + " " + noeud("1") + " " + noeud("2") + " "
                + nombre(i.valeur("farads", 1e-7))};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------------------ masse
        Modele m;
        m.type = "masse";
        m.libelle = "Masse (GND)";
        m.categorie = "Alimentation";
        m.prefixe = "GND";
        m.bornes = {{"1", {0, -20}, ""}};
        m.noeud_impose = Netlist::kMasse;
        m.symbole = {ligne(0, -20, 0, 0), ligne(-14, 0, 14, 0),
                     ligne(-9, 6, 9, 6), ligne(-4, 12, 4, 12)};
        enregistrer(std::move(m));
    }
    {   // ---------------------------------------------------- alimentation 5 V
        Modele m;
        m.type = "alim5v";
        m.libelle = "Alimentation +5 V";
        m.categorie = "Alimentation";
        m.prefixe = "V5";
        m.bornes = {{"1", {0, 20}, ""}};
        m.noeud_impose = Netlist::kAlim;
        m.symbole = {ligne(0, 20, 0, 0), ligne(-12, 0, 12, 0),
                     texte(-10, -6, "+5V", 10)};
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------------------ bobine
        Modele m;
        m.type = "inductance";
        m.libelle = "Bobine";
        m.categorie = "Passifs";
        m.prefixe = "L";
        m.bornes = {{"1", {-30, 0}, ""}, {"2", {30, 0}, ""}};
        m.proprietes = {{"henrys", "Inductance", G::Nombre, 1e-3, 0, 0, "", {}, "H"}};
        m.symbole = {ligne(-30, 0, -18, 0), ligne(18, 0, 30, 0),
                     cercle(-12, -3, 6), cercle(-4, -3, 6),
                     cercle(4, -3, 6), cercle(12, -3, 6)};
        m.empreinte = {"L_AXIAL", {{"1", -5, 0, 1.6, 0.8}, {"2", 5, 0, 1.6, 0.8}},
                       12.0, 5.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "L" + i.reference + " " + noeud("1") + " " + noeud("2") + " "
                + nombre(i.valeur("henrys", 1e-3))};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------- source de tension
        Modele m;
        m.type = "pile";
        m.libelle = "Source de tension";
        m.generateur = true;
        m.categorie = "Alimentation";
        m.prefixe = "V";
        m.bornes = {{"+", {0, -30}, ""}, {"-", {0, 30}, ""}};
        m.proprietes = {{"volts", "Tension", G::Nombre, 9, 0, 0, "", {}, "V"}};
        m.symbole = {ligne(0, -30, 0, -12), ligne(-16, -12, 16, -12),
                     ligne(-8, -5, 8, -5), ligne(-16, 2, 16, 2),
                     ligne(-8, 9, 8, 9), ligne(0, 9, 0, 30),
                     texte(-24, -16, "+", 11)};
        m.empreinte = {"PILE", {{"+", -2.5, 0, 1.8, 1.0}, {"-", 2.5, 0, 1.8, 1.0}},
                       10.0, 5.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "V" + i.reference + " " + noeud("+") + " " + noeud("-") + " DC "
                + nombre(i.valeur("volts", 9))};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------- étiquette de nœud
        Modele m;
        m.type = "etiquette";
        m.libelle = "Étiquette de nœud";
        m.categorie = "Alimentation";
        m.prefixe = "NET";
        m.bornes = {{"1", {-30, 0}, ""}};
        m.proprietes = {{"nom", "Nom du nœud", G::Choix, 0, 0, 0, "A",
                         {"A", "B", "C", "D", "E", "F", "SIG", "CLK", "DATA",
                          "IN", "OUT"}, ""}};
        m.noeud_depuis_texte = "nom";
        m.symbole = {ligne(-30, 0, -14, 0),
                     poly({{-14, -9}, {20, -9}, {28, 0}, {20, 9}, {-14, 9}},
                          false)};
        enregistrer(std::move(m));
    }
    {   // -------------------------------------------------- alimentation 3,3 V
        Modele m;
        m.type = "alim3v3";
        m.libelle = "Alimentation +3,3 V";
        m.categorie = "Alimentation";
        m.prefixe = "V33";
        m.bornes = {{"1", {0, 20}, ""}};
        m.noeud_impose = "3V3";
        m.symbole = {ligne(0, 20, 0, 0), ligne(-14, 0, 14, 0),
                     texte(-13, -6, "+3V3", 10)};
        enregistrer(std::move(m));
    }
}

}  // namespace coeur
