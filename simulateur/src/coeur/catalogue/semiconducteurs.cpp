// Catalogue — Diodes, transistors et affichage.
//
// Un composant = un bloc. Décrire le symbole, l'empreinte, les propriétés
// réglables et la traduction SPICE suffit : ni l'interface graphique ni les
// moteurs n'ont à être modifiés.
#include "coeur/catalogue/Traits.h"
#include "coeur/Netlist.h"

namespace coeur {

void enregistrer_semiconducteurs(Catalogue& catalogue) {
    using G = Propriete::Genre;
    using namespace traits;
    auto enregistrer = [&catalogue](Modele m) {
        catalogue.enregistrer(std::move(m));
    };

    {   // ------------------------------------------------------------- LED
        Modele m;
        m.type = "led";
        m.libelle = "LED";
        m.categorie = "Affichage";
        m.prefixe = "LED";
        m.bornes = {{"A", {-25, 0}, "anode"}, {"K", {25, 0}, "cathode"}};
        m.proprietes = {{"couleur", "Couleur", G::Choix, 0, 0, 0, "rouge",
                         {"rouge", "vert", "jaune", "bleu", "blanc"}, ""}};
        m.lumineux = true;
        m.couleur_corps = "#e04040";
        // LED 5 mm ordinaire : 20 mA nominal, 30 mA en valeur absolue. Sans
        // résistance sur du 5 V, une rouge encaisse plus de cent milliampères
        // — elle s'éclaire vivement, une fois.
        m.courant_max = 0.030;
        m.symbole = {ligne(-25, 0, -8, 0),
                     poly({{-8, -10}, {-8, 10}, {8, 0}}),   // triangle
                     ligne(8, -10, 8, 10),                  // barre cathode
                     ligne(8, 0, 25, 0),
                     ligne(2, -12, 9, -19), ligne(6, -18, 9, -19),
                     ligne(9, -16, 9, -19),                 // flèches lumière
                     ligne(8, -8, 15, -15), ligne(12, -14, 15, -15),
                     ligne(15, -12, 15, -15)};
        m.empreinte = {"LED_5MM",
                       {{"A", -1.27, 0.0, 1.8, 0.9}, {"K", 1.27, 0.0, 1.8, 0.9}},
                       5.0, 5.0};
        // Modèles SPICE réalistes : la tension de seuil dépend de la couleur.
        m.directives = {
            ".model LED_ROUGE D(IS=1e-20 N=1.7 RS=2.5)",
            ".model LED_VERT  D(IS=1e-21 N=1.8 RS=3.0)",
            ".model LED_JAUNE D(IS=1e-21 N=1.8 RS=3.0)",
            ".model LED_BLEU  D(IS=1e-24 N=2.2 RS=4.0)",
            ".model LED_BLANC D(IS=1e-24 N=2.2 RS=4.0)"};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            std::string couleur = i.texte("couleur", "rouge");
            std::string modele = "LED_ROUGE";
            if (couleur == "vert") modele = "LED_VERT";
            else if (couleur == "jaune") modele = "LED_JAUNE";
            else if (couleur == "bleu") modele = "LED_BLEU";
            else if (couleur == "blanc") modele = "LED_BLANC";
            return std::vector<std::string>{
                "D" + i.reference + " " + noeud("A") + " " + noeud("K") + " "
                + modele};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------- transistor NPN
        Modele m;
        m.type = "transistor_npn";
        // Petit signal type 2N2222 : 800 mA de collecteur, 500 mW dissipés.
        m.courant_max = 0.8;
        m.puissance_max = 0.5;
        m.libelle = "Transistor NPN (2N2222)";
        m.categorie = "Semi-conducteurs";
        m.prefixe = "Q";
        m.bornes = {{"B", {-30, 0}, "base"},
                    {"C", {20, -25}, "collecteur"},
                    {"E", {20, 25}, "émetteur"}};
        m.directives = {".model 2N2222 NPN(IS=1e-14 BF=200 VAF=100 RB=10 "
                        "RC=1 RE=0.5 CJE=25p CJC=8p TF=0.4n TR=50n)"};
        m.symbole = {ligne(-30, 0, -8, 0), ligne(-8, -14, -8, 14),
                     ligne(-8, -7, 20, -25), ligne(20, -25, 20, -25),
                     ligne(-8, 7, 20, 25), ligne(20, -25, 20, -25),
                     poly({{8, 12}, {14, 20}, {4, 19}}),   // flèche émetteur
                     cercle(0, 0, 26)};
        m.empreinte = {"TO-92",
                       {{"E", -1.27, 0, 1.6, 0.8},
                        {"B", 0, 0, 1.6, 0.8},
                        {"C", 1.27, 0, 1.6, 0.8}},
                       4.8, 3.8};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "Q" + i.reference + " " + noeud("C") + " " + noeud("B") + " "
                + noeud("E") + " 2N2222"};
        };
        enregistrer(std::move(m));
    }
    {   // ----------------------------------------------------------- diode
        Modele m;
        m.type = "diode";
        // 1N4148 : 200 mA en direct continu.
        m.courant_max = 0.2;
        m.libelle = "Diode";
        m.categorie = "Semi-conducteurs";
        m.prefixe = "D";
        m.bornes = {{"A", {-25, 0}, "anode"}, {"K", {25, 0}, "cathode"}};
        m.proprietes = {{"reference", "Référence", G::Choix, 0, 0, 0, "1N4148",
                         {"1N4148", "1N4007", "1N5819"}, ""}};
        m.symbole = {ligne(-25, 0, -8, 0), poly({{-8, -10}, {-8, 10}, {8, 0}}),
                     ligne(8, -10, 8, 10), ligne(8, 0, 25, 0)};
        m.directives = {
            ".model D1N4148 D(IS=2.52n RS=0.568 N=1.752 CJO=4p BV=100 IBV=100n)",
            ".model D1N4007 D(IS=7.02n RS=0.0341 N=1.8 BV=1000 IBV=5u)",
            ".model D1N5819 D(IS=31.7u RS=0.051 N=1.37 BV=40 IBV=1m)"};
        m.empreinte = {"D_AXIAL", {{"A", -3.8, 0, 1.6, 0.9}, {"K", 3.8, 0, 1.6, 0.9}},
                       8.0, 3.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "D" + i.reference + " " + noeud("A") + " " + noeud("K") + " D"
                + i.texte("reference", "1N4148")};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------------ diode Zener
        Modele m;
        m.type = "zener";
        // Zener 500 mW : c'est la puissance, pas le courant, qui la tue —
        // 100 mA sous 5,1 V font déjà le double.
        m.puissance_max = 0.5;
        m.libelle = "Diode Zener";
        m.categorie = "Semi-conducteurs";
        m.prefixe = "DZ";
        m.bornes = {{"A", {-25, 0}, "anode"}, {"K", {25, 0}, "cathode"}};
        m.proprietes = {{"tension", "Tension Zener", G::Choix, 0, 0, 0, "5V1",
                         {"3V3", "5V1", "9V1", "12V"}, ""}};
        m.symbole = {ligne(-25, 0, -8, 0), poly({{-8, -10}, {-8, 10}, {8, 0}}),
                     ligne(8, -10, 8, 10), ligne(8, -10, 2, -14),
                     ligne(8, 10, 14, 14), ligne(8, 0, 25, 0)};
        m.directives = {
            ".model DZ3V3 D(IS=1e-14 N=1.6 BV=3.3 IBV=5m RS=15)",
            ".model DZ5V1 D(IS=1e-14 N=1.6 BV=5.1 IBV=5m RS=10)",
            ".model DZ9V1 D(IS=1e-14 N=1.6 BV=9.1 IBV=5m RS=8)",
            ".model DZ12V D(IS=1e-14 N=1.6 BV=12 IBV=5m RS=7)"};
        m.empreinte = {"D_AXIAL", {{"A", -3.8, 0, 1.6, 0.9}, {"K", 3.8, 0, 1.6, 0.9}},
                       8.0, 3.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "D" + i.reference + " " + noeud("A") + " " + noeud("K") + " DZ"
                + i.texte("tension", "5V1")};
        };
        enregistrer(std::move(m));
    }
    {   // -------------------------------------------------- transistor PNP
        Modele m;
        m.type = "transistor_pnp";
        m.courant_max = 0.8;
        m.puissance_max = 0.5;
        m.libelle = "Transistor PNP (2N2907)";
        m.categorie = "Semi-conducteurs";
        m.prefixe = "Q";
        m.bornes = {{"B", {-30, 0}, "base"}, {"C", {20, 25}, "collecteur"},
                    {"E", {20, -25}, "émetteur"}};
        m.symbole = {ligne(-30, 0, -8, 0), ligne(-8, -14, -8, 14),
                     ligne(-8, -7, 20, -25), ligne(-8, 7, 20, 25),
                     poly({{-8, -7}, {0, -6}, {-2, -14}}), cercle(0, 0, 26)};
        m.directives = {".model 2N2907 PNP(IS=1e-14 BF=200 VAF=100 RB=10 RC=1 "
                        "RE=0.5 CJE=25p CJC=8p TF=0.5n TR=60n)"};
        m.empreinte = {"TO-92", {{"E", -1.27, 0, 1.6, 0.8}, {"B", 0, 0, 1.6, 0.8},
                                 {"C", 1.27, 0, 1.6, 0.8}}, 4.8, 3.8};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "Q" + i.reference + " " + noeud("C") + " " + noeud("B") + " "
                + noeud("E") + " 2N2907"};
        };
        enregistrer(std::move(m));
    }
    {   // ---------------------------------------------------- MOSFET canal N
        Modele m;
        m.type = "mosfet_n";
        // Petit MOSFET logique type 2N7000 : 200 mA continus, 400 mW.
        m.courant_max = 0.2;
        m.puissance_max = 0.4;
        m.libelle = "MOSFET canal N (IRF540)";
        m.categorie = "Semi-conducteurs";
        m.prefixe = "M";
        m.bornes = {{"G", {-30, 0}, "grille"}, {"D", {20, -25}, "drain"},
                    {"S", {20, 25}, "source"}};
        m.symbole = {ligne(-30, 0, -14, 0), ligne(-14, -14, -14, 14),
                     ligne(-6, -14, -6, -4), ligne(-6, -2, -6, 2),
                     ligne(-6, 4, -6, 14), ligne(-6, -10, 20, -10),
                     ligne(20, -10, 20, -25), ligne(-6, 10, 20, 10),
                     ligne(20, 10, 20, 25), ligne(-6, 0, 12, 0),
                     poly({{12, -4}, {12, 4}, {20, 0}}), ligne(20, -10, 20, 10),
                     cercle(0, 0, 26)};
        m.directives = {".model IRF540 NMOS(VTO=3.5 KP=20 LAMBDA=0.005 "
                        "RD=0.044 RS=0.01 CGSO=1.5n CGDO=0.5n)"};
        m.empreinte = {"TO-220", {{"G", -2.54, 0, 1.8, 1.1}, {"D", 0, 0, 1.8, 1.1},
                                  {"S", 2.54, 0, 1.8, 1.1}}, 10.0, 4.5};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "M" + i.reference + " " + noeud("D") + " " + noeud("G") + " "
                + noeud("S") + " " + noeud("S") + " IRF540 W=1 L=1"};
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------ afficheur 7 segments
        Modele m;
        m.type = "afficheur_7seg";
        m.libelle = "Afficheur 7 segments";
        m.categorie = "Affichage";
        m.prefixe = "AF";
        m.lumineux = true;
        m.couleur_corps = "#e04040";
        m.bornes = {{"a", {-60, -40}, ""}, {"b", {-60, -25}, ""},
                    {"c", {-60, -10}, ""}, {"d", {-60, 5}, ""},
                    {"e", {-60, 20}, ""},  {"f", {-60, 35}, ""},
                    {"g", {-60, 50}, ""},  {"COM", {60, 5}, "commun"}};
        m.proprietes = {{"type", "Type", G::Choix, 0, 0, 0, "cathode_commune",
                         {"cathode_commune", "anode_commune"}, ""}};
        // LES SEPT SEGMENTS S'ALLUMENT UN PAR UN.
        //
        // `m.lumineux = true` était déclaré et ne produisait RIEN : le halo
        // cherche un courant sous la référence du composant, or les sept
        // diodes de l'afficheur s'appellent D<RÉF>0 à D<RÉF>6. L'afficheur
        // restait donc noir quoi que fasse le circuit, sans le moindre
        // message — et un développeur qui lisait le catalogue le croyait
        // géré.
        //
        // Un halo global n'aurait de toute façon rien appris : ce qui
        // intéresse l'élève qui câble un décodeur, c'est QUELS segments sont
        // alimentés. Chaque trait porte donc le suffixe du courant qui
        // l'allume, dans l'ordre a, b, c, d, e, f, g du modèle SPICE.
        m.symbole = {rect(-40, -50, 40, 60),
                     segment(ligne(-24, -36, 16, -36), "0"),   // a, haut
                     segment(ligne(18, -34, 18, 0), "1"),      // b, haut droit
                     segment(ligne(16, 4, 16, 40), "2"),       // c, bas droit
                     segment(ligne(-28, 42, 16, 42), "3"),     // d, bas
                     segment(ligne(-28, 4, -28, 40), "4"),     // e, bas gauche
                     segment(ligne(-26, -34, -26, 0), "5"),    // f, haut gauche
                     segment(ligne(-26, 2, 18, 2), "6"),       // g, milieu
                     cercle(26, 44, 3, true)};
        m.directives = {".model SEG_LED D(IS=1e-20 N=1.7 RS=2.5)"};
        m.empreinte = {"7SEG_0.56", {}, 19.0, 12.7};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const bool cathode = i.texte("type", "cathode_commune")
                                 == "cathode_commune";
            std::vector<std::string> lignes;
            const char* segments[] = {"a", "b", "c", "d", "e", "f", "g"};
            int k = 0;
            for (const char* segment : segments) {
                const std::string nom = "D" + i.reference + std::to_string(k++);
                if (cathode)
                    lignes.push_back(nom + " " + noeud(segment) + " "
                                     + noeud("COM") + " SEG_LED");
                else
                    lignes.push_back(nom + " " + noeud("COM") + " "
                                     + noeud(segment) + " SEG_LED");
            }
            return lignes;
        };
        enregistrer(std::move(m));
    }
    {   // --------------------------------------------------- optocoupleur
        Modele m;
        m.type = "optocoupleur";
        m.libelle = "Optocoupleur (4N25)";
        m.categorie = "Semi-conducteurs";
        m.prefixe = "OK";
        m.bornes = {{"A", {-40, -20}, "anode"}, {"K", {-40, 20}, "cathode"},
                    {"C", {40, -20}, "collecteur"}, {"E", {40, 20}, "émetteur"}};
        m.symbole = {rect(-30, -35, 30, 35),
                     ligne(-40, -20, -18, -20), ligne(-40, 20, -18, 20),
                     poly({{-18, -8}, {-18, 8}, {-6, 0}}), ligne(-6, -8, -6, 8),
                     ligne(-18, -20, -18, -8), ligne(-18, 8, -18, 20),
                     ligne(-6, -20, -6, -8), ligne(-6, 8, -6, 20),
                     ligne(6, -14, 6, 14), ligne(6, -6, 24, -20),
                     ligne(6, 6, 24, 20), ligne(24, -20, 40, -20),
                     ligne(24, 20, 40, 20), ligne(0, -3, 4, -3),
                     ligne(0, 3, 4, 3)};
        m.directives = {".model OK_LED D(IS=1e-20 N=1.8 RS=3)",
                        ".model OK_NPN NPN(IS=1e-14 BF=250 VAF=100 RB=10 RC=2)"};
        m.empreinte = {"DIP-6", {}, 9.8, 6.4};
        // Couplage optique : le courant de la diode commande la base par une
        // source de courant. Rapport de transfert typique du 4N25 : 50 %.
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const std::string ref = i.reference;
            return std::vector<std::string>{
                "D" + ref + " " + noeud("A") + " " + ref + "_mid OK_LED",
                "V" + ref + "_mes " + ref + "_mid " + noeud("K") + " DC 0",
                "Q" + ref + " " + noeud("C") + " " + ref + "_base "
                    + noeud("E") + " OK_NPN",
                "R" + ref + "_base " + ref + "_base " + noeud("E") + " 1e6",
                "F" + ref + " " + noeud("E") + " " + ref + "_base V"
                    + ref + "_mes 0.5"};
        };
        enregistrer(std::move(m));
    }
}

}  // namespace coeur
