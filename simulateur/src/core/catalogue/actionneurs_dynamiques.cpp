// Catalogue — actionneurs à mécanique interne.
//
// Ces composants ne se résument pas à une impédance : ils ont une position,
// une vitesse, une inertie. Le circuit les alimente, ils avancent, et leur
// état devient une grandeur qu'on affiche — l'angle d'un servomoteur, la
// vitesse d'un moteur. C'est ce que le crochet `evoluer` rend possible.
#include <cmath>
#include <string>
#include <vector>

#include "core/Netlist.h"
#include "core/catalogue/Traits.h"

namespace coeur {

namespace {

std::string arrondi(double valeur, int decimales) {
    char tampon[48];
    std::snprintf(tampon, sizeof tampon, "%.*f", decimales, valeur);
    return tampon;
}

}  // namespace

void enregistrer_actionneurs_dynamiques(Catalogue& catalogue) {
    using G = Propriete::Genre;
    using namespace traits;
    auto enregistrer = [&catalogue](Modele m) {
        catalogue.enregistrer(std::move(m));
    };

    {   // ------------------------------------------------------ servomoteur
        Modele m;
        m.type = "servomoteur";
        m.libelle = "Servomoteur (SG90)";
        m.categorie = "Actionneurs";
        m.prefixe = "SRV";
        m.bornes = {{"+", {-40, -20}, "5 V"},
                    {"GND", {-40, 0}, ""},
                    {"SIG", {-40, 20}, "commande"}};
        m.proprietes = {
            {"angle", "Angle", G::Curseur, 90, 0, 180, "", {}, "°"},
            {"vitesse", "Vitesse de rotation", G::Nombre, 360, 0, 0, "", {}, "°/s"}};
        m.symbole = {rect(-30, -35, 30, 35),
                     ligne(-40, -20, -30, -20), ligne(-40, 0, -30, 0),
                     ligne(-40, 20, -30, 20),
                     cercle(8, -18, 10), ligne(8, -18, 8, -30),
                     texte(-24, 14, "SERVO", 10)};
        m.empreinte = {"SERVO_SG90", {}, 22.8, 12.2};

        // Électriquement, un servo est une charge quelconque : ce qui compte
        // est ce qu'il fait de l'impulsion. On le représente par sa
        // consommation au repos, sinon son alimentation serait « en l'air ».
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("+") + " " + noeud("GND") + " 500",
                "R" + i.reference + "_sig " + noeud("SIG") + " " + noeud("GND") +
                    " 4.7k"};
        };

        // Le cœur du composant : décoder la largeur d'impulsion. Un servo
        // standard attend 1 ms pour 0°, 2 ms pour 180°, toutes les 20 ms.
        m.evoluer = [](Instance& i, const Evolution& evolution) {
            const double largeur = evolution.largeur_impulsion("SIG");
            if (largeur < 400e-6 || largeur > 2800e-6) return;   // hors gabarit

            double consigne = (largeur - 1000e-6) / (1000e-6) * 180.0;
            if (consigne < 0) consigne = 0;
            if (consigne > 180) consigne = 180;

            // Le palonnier ne saute pas : il tourne à vitesse bornée, comme
            // un vrai servo. C'est ce qui fait qu'un balayage se voit.
            const double angle = i.valeur("angle", 90);
            const double pas = i.valeur("vitesse", 360) * evolution.duree;
            const double ecart = consigne - angle;
            i.valeurs["angle"] =
                std::fabs(ecart) <= pas ? consigne : angle + (ecart > 0 ? pas : -pas);
            i.valeurs["consigne"] = consigne;
        };
        m.lecture = [](const Instance& i) {
            return arrondi(i.valeur("angle", 90), 0) + " °";
        };
        // L'angle réel ET la consigne : superposés à l'oscilloscope, ils
        // montrent que le palonnier MET DU TEMPS à rejoindre l'ordre reçu —
        // la première cause de « mon servo saccade ».
        m.grandeurs = {{"angle", "angle du palonnier", "°"},
                       {"consigne", "angle demandé", "°"}};
        enregistrer(std::move(m));
    }

    {   // -------------------------------------------- moteur à courant continu
        Modele m;
        m.type = "moteur_cc_dynamique";
        m.libelle = "Moteur CC (avec inertie)";
        m.categorie = "Actionneurs";
        m.prefixe = "M";
        m.bornes = {{"+", {-35, 0}, ""}, {"-", {35, 0}, ""}};
        m.proprietes = {
            {"resistance", "Résistance d'induit", G::Nombre, 8, 0, 0, "", {}, "Ω"},
            {"inductance", "Inductance d'induit", G::Nombre, 5e-3, 0, 0, "", {}, "H"},
            {"k", "Constante de vitesse", G::Nombre, 900, 0, 0, "", {}, "tr/min/V"},
            {"inertie", "Temps de montée", G::Nombre, 0.25, 0, 0, "", {}, "s"}};
        m.symbole = {cercle(0, 0, 24), ligne(-35, 0, -24, 0), ligne(24, 0, 35, 0),
                     texte(-8, 5, "M", 14)};
        m.empreinte = {"MOTEUR", {{"+", -5, 0, 2.0, 1.2}, {"-", 5, 0, 2.0, 1.2}},
                       25.0, 20.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            // La force contre-électromotrice s'oppose à la tension appliquée :
            // c'est elle qui fait qu'un moteur lancé consomme moins qu'un
            // moteur bloqué. On la représente par une source proportionnelle
            // à la vitesse atteinte.
            const double k = i.valeur("k", 900);
            const double fcem = k > 0 ? i.valeur("tr_min", 0) / k : 0.0;
            // Le modèle complet d'un induit : R en série avec L, puis la
            // force contre-électromotrice. C'est l'inductance qui empêche le
            // courant de s'établir d'un coup — donc qui produit la pointe à
            // la coupure, et qui rend la diode de roue libre indispensable.
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("+") + " " + i.reference + "_a " +
                    nombre(i.valeur("resistance", 8)),
                "L" + i.reference + " " + i.reference + "_a " + i.reference +
                    "_b " + nombre(i.valeur("inductance", 5e-3)),
                "V" + i.reference + "_fcem " + i.reference + "_b " +
                    noeud("-") + " DC " + nombre(fcem)};
        };
        m.evoluer = [](Instance& i, const Evolution& evolution) {
            // Vitesse de régime proportionnelle à la tension moyenne, atteinte
            // avec une constante de temps : un moteur ne démarre pas d'un coup.
            const double u = evolution.moyenne("+") - evolution.moyenne("-");
            const double cible = u * i.valeur("k", 900) / 12.0;
            const double tau = std::max(0.01, i.valeur("inertie", 0.25));
            const double actuel = i.valeur("tr_min", 0);
            const double alpha = 1.0 - std::exp(-evolution.duree / tau);
            i.valeurs["tr_min"] = actuel + (cible - actuel) * alpha;
        };
        m.lecture = [](const Instance& i) {
            return arrondi(i.valeur("tr_min", 0), 0) + " tr/min";
        };
        // La vitesse était CALCULÉE à chaque fenêtre, avec sa constante de
        // temps, et seulement écrite en texte sous le symbole. La déclarer la
        // rend traçable : on voit alors la montée exponentielle vers le
        // régime — la même courbe qu'un RC, ce que le cours enseigne déjà.
        m.grandeurs = {{"tr_min", "vitesse", "tr/min"}};
        enregistrer(std::move(m));
    }

    {   // ------------------------------------------------- moteur pas à pas
        Modele m;
        m.type = "moteur_pas_a_pas";
        m.libelle = "Moteur pas à pas (unipolaire)";
        m.categorie = "Actionneurs";
        m.prefixe = "PAP";
        m.bornes = {{"A", {-40, -30}, ""}, {"B", {-40, -10}, ""},
                    {"C", {-40, 10}, ""},  {"D", {-40, 30}, ""},
                    {"COM", {40, 0}, "commun"}};
        m.proprietes = {
            {"bobine", "Résistance par bobine", G::Nombre, 50, 0, 0, "", {}, "Ω"},
            {"inductance", "Inductance par bobine", G::Nombre, 30e-3, 0, 0, "", {}, "H"},
            {"pas_par_tour", "Pas par tour", G::Nombre, 200, 0, 0, "", {}, ""}};
        m.symbole = {cercle(0, 0, 26),
                     ligne(-40, -30, -26, -30), ligne(-40, -10, -26, -10),
                     ligne(-40, 10, -26, 10), ligne(-40, 30, -26, 30),
                     ligne(26, 0, 40, 0), texte(-14, 5, "PAP", 11)};
        m.empreinte = {"NEMA17", {}, 42.0, 42.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            const std::string r = nombre(i.valeur("bobine", 50));
            const std::string l = nombre(i.valeur("inductance", 30e-3));
            std::vector<std::string> lignes;
            const char* phases[] = {"A", "B", "C", "D"};
            // Chaque phase est une vraie bobine : R en série avec L. Sans
            // l'inductance, on ne verrait ni la montée du courant ni la
            // surtension à la commutation — c'est pourtant ce qui dimensionne
            // le circuit de commande d'un pas à pas.
            for (const char* phase : phases) {
                const std::string milieu =
                    i.reference + "_" + std::string(phase) + "m";
                lignes.push_back("R" + i.reference + phase + " " + noeud(phase) +
                                 " " + milieu + " " + r);
                lignes.push_back("L" + i.reference + phase + " " + milieu + " " +
                                 noeud("COM") + " " + l);
            }
            return lignes;
        };
        m.evoluer = [](Instance& i, const Evolution& evolution) {
            // Une phase alimentée attire le rotor sur sa position. On suit la
            // séquence : le passage d'une phase à la suivante avance d'un pas.
            const char* phases[] = {"A", "B", "C", "D"};
            int active = -1;
            double plus_bas = 2.5;      // une phase tirée au bas est alimentée
            for (int k = 0; k < 4; ++k) {
                const double moyenne = evolution.moyenne(phases[k]);
                if (moyenne < plus_bas) {
                    plus_bas = moyenne;
                    active = k;
                }
            }
            if (active < 0) return;

            const int precedente = static_cast<int>(i.valeur("phase", 0));
            if (active != precedente) {
                // Sens de rotation : +1 si on avance dans la séquence.
                int delta = active - precedente;
                if (delta > 2) delta -= 4;
                if (delta < -2) delta += 4;
                i.valeurs["pas"] = i.valeur("pas", 0) + delta;
                i.valeurs["phase"] = active;
            }
            const double par_tour = std::max(1.0, i.valeur("pas_par_tour", 200));
            i.valeurs["angle"] =
                std::fmod(i.valeur("pas", 0) * 360.0 / par_tour, 360.0);
        };
        m.lecture = [](const Instance& i) {
            return arrondi(i.valeur("angle", 0), 1) + " ° (" +
                   arrondi(i.valeur("pas", 0), 0) + " pas)";
        };
        // Le NOMBRE DE PAS autant que l'angle : c'est lui que le programme
        // compte, et pouvoir comparer son compte logiciel à la mécanique
        // réelle est tout l'intérêt du pas à pas. La phase dit quelle bobine
        // est alimentée — ce qu'on cherche quand la séquence ne fait pas
        // avancer le moteur.
        m.grandeurs = {{"pas", "pas effectués", "pas"},
                       {"angle", "angle", "°"},
                       {"phase", "phase alimentée", ""}};
        enregistrer(std::move(m));
    }

    {   // --------------------------------------------- moteur asynchrone 3~
        Modele m;
        m.type = "moteur_asynchrone";
        m.libelle = "Moteur asynchrone triphasé";
        m.categorie = "Actionneurs";
        m.prefixe = "MAS";
        m.bornes = {{"U", {-40, -30}, "phase 1"},
                    {"V", {-40, 0}, "phase 2"},
                    {"W", {-40, 30}, "phase 3"}};
        m.proprietes = {
            {"stator", "Résistance statorique", G::Nombre, 12, 0, 0, "", {}, "Ω"},
            {"inductance", "Inductance statorique", G::Nombre, 30e-3, 0, 0, "", {}, "H"},
            {"poles", "Paires de pôles", G::Nombre, 2, 0, 0, "", {}, ""},
            {"frequence", "Fréquence d'alimentation", G::Curseur, 50, 0, 60,
             "", {}, "Hz"},
            {"glissement", "Glissement en charge", G::Nombre, 4, 0, 0, "", {}, "%"},
            {"demarrage", "Temps de démarrage", G::Nombre, 1.5, 0, 0, "", {}, "s"}};
        m.symbole = {cercle(0, 0, 30),
                     ligne(-40, -30, -22, -30), ligne(-40, 0, -30, 0),
                     ligne(-40, 30, -22, 30),
                     texte(-14, 6, "M", 15), texte(4, 12, "3~", 10)};
        m.empreinte = {"MOTEUR_3PH", {}, 120.0, 120.0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            // Couplage étoile : trois enroulements vers un neutre interne.
            const std::string r = nombre(i.valeur("stator", 12));
            const std::string l = nombre(i.valeur("inductance", 30e-3));
            const std::string neutre = i.reference + "_n";
            // Une machine asynchrone est très inductive : c'est son inductance
            // statorique qui donne le déphasage courant/tension, donc le
            // facteur de puissance qu'on compense en armoire.
            std::vector<std::string> lignes;
            const char* phases[] = {"U", "V", "W"};
            for (const char* phase : phases) {
                const std::string milieu =
                    i.reference + "_" + std::string(phase) + "m";
                lignes.push_back("R" + i.reference + phase + " " + noeud(phase) +
                                 " " + milieu + " " + r);
                lignes.push_back("L" + i.reference + phase + " " + milieu + " " +
                                 neutre + " " + l);
            }
            lignes.push_back("R" + i.reference + "_n " + neutre + " 0 1e6");
            return lignes;
        };
        m.evoluer = [](Instance& i, const Evolution& evolution) {
            // Le moteur tourne s'il est alimenté. La vitesse de synchronisme
            // vaut 60 f / p ; la vitesse réelle est plus faible du glissement,
            // et c'est précisément ce glissement qui crée le couple.
            const bool alimente = evolution.moyenne("U") > 1.0 ||
                                  evolution.moyenne("V") > 1.0 ||
                                  evolution.moyenne("W") > 1.0;
            const double poles = std::max(1.0, i.valeur("poles", 2));
            const double synchrone = 60.0 * i.valeur("frequence", 50) / poles;
            const double cible =
                alimente ? synchrone * (1.0 - i.valeur("glissement", 4) / 100.0)
                         : 0.0;
            const double tau = std::max(0.05, i.valeur("demarrage", 1.5));
            const double actuel = i.valeur("tr_min", 0);
            const double alpha = 1.0 - std::exp(-evolution.duree / tau);
            i.valeurs["tr_min"] = actuel + (cible - actuel) * alpha;
            i.valeurs["synchrone"] = synchrone;
        };
        m.lecture = [](const Instance& i) {
            return arrondi(i.valeur("tr_min", 0), 0) + " tr/min  (Ns = " +
                   arrondi(i.valeur("synchrone", 1500), 0) + ")";
        };
        // La vitesse et le SYNCHRONISME : leur écart est le glissement, LE
        // concept du cours sur l'asynchrone. Les deux courbes côte à côte le
        // montrent sans qu'on ait à le calculer de tête.
        m.grandeurs = {{"tr_min", "vitesse", "tr/min"},
                       {"synchrone", "vitesse de synchronisme", "tr/min"}};
        enregistrer(std::move(m));
    }

    {   // ------------------------------------------ alimentation triphasée
        Modele m;
        m.type = "alim_triphasee";
        m.libelle = "Alimentation triphasée";
        m.generateur = true;
        m.categorie = "Alimentation";
        m.prefixe = "T";
        m.bornes = {{"U", {40, -30}, ""}, {"V", {40, 0}, ""}, {"W", {40, 30}, ""}};
        m.proprietes = {
            {"tension", "Tension simple efficace", G::Nombre, 230, 0, 0, "", {}, "V"},
            {"frequence", "Fréquence", G::Curseur, 50, 0, 60, "", {}, "Hz"},
            {"en_marche", "Sous tension", G::Nombre, 1, 0, 1, "", {}, ""}};
        m.symbole = {rect(-40, -45, 20, 45), texte(-32, -18, "3~", 13),
                     ligne(20, -30, 40, -30), ligne(20, 0, 40, 0),
                     ligne(20, 30, 40, 30),
                     texte(24, -34, "U", 10), texte(24, -4, "V", 10),
                     texte(24, 26, "W", 10)};
        // Trois sinusoïdes décalées de 120° : c'est la définition du triphasé.
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            if (i.valeur("en_marche", 1) < 0.5) return std::vector<std::string>{};
            const double crete = i.valeur("tension", 230) * 1.41421356;
            const std::string f = nombre(i.valeur("frequence", 50));
            const std::string a = nombre(crete);
            return std::vector<std::string>{
                "V" + i.reference + "U " + noeud("U") + " 0 SIN(0 " + a + " " + f + ")",
                "V" + i.reference + "V " + noeud("V") + " 0 SIN(0 " + a + " " + f +
                    " 0 0 -120)",
                "V" + i.reference + "W " + noeud("W") + " 0 SIN(0 " + a + " " + f +
                    " 0 0 -240)"};
        };
        enregistrer(std::move(m));
    }
}

}  // namespace coeur
