// Catalogue — instruments de mesure.
//
// Un instrument est un composant comme les autres : il a une place dans le
// circuit et il le charge, très peu mais réellement. Un voltmètre parfait
// n'existe pas, et un ampèremètre non plus — les modéliser ainsi évite
// d'enseigner une mesure sans influence sur le montage.
#include <string>
#include <vector>

#include "coeur/Netlist.h"
#include <algorithm>
#include <cmath>
#include <sstream>

#include "coeur/catalogue/Traits.h"

namespace coeur {

namespace {

// Mise en forme d'une mesure avec son préfixe : « 4.72 V », « 12.8 mA ».
// Un instrument qui afficherait « 0.0128 A » ne serait pas lisible.
std::string format_mesure(double valeur, const std::string& unite) {
    const double absolue = std::fabs(valeur);
    double reduite = valeur;
    std::string prefixe;
    if (absolue >= 1e6) { reduite = valeur / 1e6; prefixe = "M"; }
    else if (absolue >= 1e3) { reduite = valeur / 1e3; prefixe = "k"; }
    else if (absolue < 1e-9) { reduite = 0; }
    else if (absolue < 1e-6) { reduite = valeur * 1e9; prefixe = "n"; }
    else if (absolue < 1e-3) { reduite = valeur * 1e6; prefixe = "µ"; }
    else if (absolue < 1.0)  { reduite = valeur * 1e3; prefixe = "m"; }

    std::ostringstream flux;
    flux.setf(std::ios::fixed);
    flux.precision(std::fabs(reduite) >= 100 ? 0 : 2);
    flux << reduite << " " << prefixe << unite;
    return flux.str();
}

// Moyenne d'une forme d'onde, pondérée par le temps : les points d'une
// analyse transitoire ne sont pas régulièrement espacés.
double moyenne_temporelle(const std::vector<double>& temps,
                          const std::vector<double>& valeurs) {
    const size_t n = std::min(temps.size(), valeurs.size());
    if (n < 2) return n == 1 ? valeurs[0] : 0.0;
    const double duree = temps[n - 1] - temps[0];
    if (duree <= 0) return valeurs[n - 1];
    double integrale = 0;
    for (size_t k = 1; k < n; ++k)
        integrale += 0.5 * (valeurs[k] + valeurs[k - 1]) * (temps[k] - temps[k - 1]);
    return integrale / duree;
}

// Valeur efficace de la PARTIE VARIABLE, c'est-à-dire ce qu'affiche un
// multimètre en position alternatif : la composante continue est retirée
// avant le calcul, comme le fait le couplage alternatif d'un appareil réel.
double efficace_alternatif(const std::vector<double>& temps,
                           const std::vector<double>& valeurs) {
    const size_t n = std::min(temps.size(), valeurs.size());
    if (n < 2) return 0.0;
    const double duree = temps[n - 1] - temps[0];
    if (duree <= 0) return 0.0;
    const double continu = moyenne_temporelle(temps, valeurs);
    double integrale = 0;
    for (size_t k = 1; k < n; ++k) {
        const double a = valeurs[k - 1] - continu, b = valeurs[k] - continu;
        integrale += 0.5 * (a * a + b * b) * (temps[k] - temps[k - 1]);
    }
    return std::sqrt(std::max(0.0, integrale / duree));
}

// Ce qu'affiche un multimètre selon sa position, à partir d'une forme d'onde
// quand elle existe, et de la valeur instantanée sinon.
double lecture_multimetre(const std::string& mode, double instantane,
                          const std::vector<double>* temps,
                          const std::vector<double>* forme) {
    if (!temps || !forme || temps->size() < 2) return mode == "alternatif" ? 0.0
                                                                          : instantane;
    return mode == "alternatif" ? efficace_alternatif(*temps, *forme)
                                : moyenne_temporelle(*temps, *forme);
}

}  // namespace

void enregistrer_instruments(Catalogue& catalogue) {
    using G = Propriete::Genre;
    using namespace traits;
    auto enregistrer = [&catalogue](Modele m) {
        catalogue.enregistrer(std::move(m));
    };

    {   // -------------------------------------------------------- voltmètre
        Modele m;
        m.type = "voltmetre";
        m.libelle = "Voltmètre";
        m.categorie = "Instruments";
        m.prefixe = "VM";
        m.bornes = {{"+", {-30, 0}, ""}, {"-", {30, 0}, ""}};
        m.proprietes = {
            {"mode", "Position", G::Choix, 0, 0, 0, "continu",
             {"continu", "alternatif"}, ""},
            {"impedance", "Impédance d'entrée", G::Nombre, 1e7, 0, 0, "", {},
             "Ω"}};
        m.symbole = {cercle(0, 0, 22), ligne(-30, 0, -22, 0), ligne(22, 0, 30, 0),
                     texte(-7, 6, "V", 14)};
        m.empreinte = {"", {}, 0, 0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("+") + " " + noeud("-") + " "
                + nombre(i.valeur("impedance", 1e7))};
        };
        m.mesure_instrument = [](const Instance& i, const Modele::Lecture& l) {
            const std::string mode = i.texte("mode", "continu");
            // Le voltmètre lit une différence de potentiel : il faut donc la
            // forme d'onde des deux bornes, pas d'une seule.
            std::vector<double> difference;
            if (l.temps && l.forme_tension) {
                const std::vector<double>* plus = l.forme_tension("+");
                const std::vector<double>* moins = l.forme_tension("-");
                if (plus) {
                    difference = *plus;
                    if (moins)
                        for (size_t k = 0; k < difference.size()
                                           && k < moins->size(); ++k)
                            difference[k] -= (*moins)[k];
                }
            }
            const double instantane =
                l.tension ? l.tension("+") - l.tension("-") : 0.0;
            const double valeur = lecture_multimetre(
                mode, instantane, l.temps,
                difference.empty() ? nullptr : &difference);
            return format_mesure(valeur, "V")
                   + (mode == "alternatif" ? " ~" : "");
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------------- ampèremètre
        Modele m;
        m.type = "amperemetre";
        m.libelle = "Ampèremètre";
        m.categorie = "Instruments";
        m.prefixe = "AM";
        m.bornes = {{"+", {-30, 0}, ""}, {"-", {30, 0}, ""}};
        m.proprietes = {
            {"mode", "Position", G::Choix, 0, 0, 0, "continu",
             {"continu", "alternatif"}, ""},
            {"shunt", "Résistance de shunt", G::Nombre, 0.01, 0, 0, "", {},
             "Ω"}};
        m.symbole = {cercle(0, 0, 22), ligne(-30, 0, -22, 0), ligne(22, 0, 30, 0),
                     texte(-7, 6, "A", 14)};
        m.empreinte = {"", {}, 0, 0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("+") + " " + noeud("-") + " "
                + nombre(i.valeur("shunt", 0.01))};
        };
        m.mesure_instrument = [](const Instance& i, const Modele::Lecture& l) {
            const std::string mode = i.texte("mode", "continu");
            const double valeur = lecture_multimetre(mode, l.courant, l.temps,
                                                     l.forme_courant);
            return format_mesure(valeur, "A")
                   + (mode == "alternatif" ? " ~" : "");
        };
        enregistrer(std::move(m));
    }
    {   // ------------------------------------------------------- ohmmètre
        // Un ohmmètre ne se contente pas de lire : il injecte un courant connu
        // et mesure la tension qui en résulte. C'est ainsi que fonctionne un
        // multimètre en position Ω, et c'est pourquoi la mesure n'a de sens
        // que sur un composant hors circuit — un générateur voisin fausserait
        // tout, exactement comme sur une paillasse.
        Modele m;
        m.type = "ohmmetre";
        m.libelle = "Ohmmètre";
        m.categorie = "Instruments";
        m.prefixe = "OM";
        m.bornes = {{"+", {-30, 0}, ""}, {"-", {30, 0}, ""}};
        m.proprietes = {{"courant", "Courant d'essai", G::Nombre, 1e-3, 0, 0, "",
                         {}, "A"}};
        m.symbole = {cercle(0, 0, 22), ligne(-30, 0, -22, 0), ligne(22, 0, 30, 0),
                     texte(-7, 6, "Ω", 14)};
        m.empreinte = {"", {}, 0, 0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "I" + i.reference + " " + noeud("+") + " " + noeud("-") + " DC "
                + nombre(i.valeur("courant", 1e-3))};
        };
        m.mesure_instrument = [](const Instance& i, const Modele::Lecture& l) {
            const double essai = i.valeur("courant", 1e-3);
            if (essai <= 0 || !l.tension) return std::string("—");
            // R = U / I, avec le signe de la source d'essai.
            const double u = l.tension("-") - l.tension("+");
            return format_mesure(u / essai, "Ω");
        };
        enregistrer(std::move(m));
    }
    {   // -------------------------------------------------- sonde de tension
        // Une sonde n'est pas un composant : elle ne charge pas le circuit et
        // n'émet aucune ligne SPICE. C'est le seul « instrument » qu'on peut
        // greffer n'importe où sans changer le montage — un oscilloscope posé
        // sur le schéma, lui, n'aurait pas de sens électrique.
        Modele m;
        m.type = "sonde_tension";
        m.libelle = "Sonde de tension";
        m.categorie = "Instruments";
        m.prefixe = "SND";
        m.bornes = {{"1", {0, 22}, ""}};
        m.symbole = {ligne(0, 22, 0, 6), poly({{-7, 6}, {7, 6}, {0, -4}}, false),
                     cercle(0, -12, 9), texte(-4, -8, "V", 11)};
        m.empreinte = {"", {}, 0, 0};
        m.mesure_instrument = [](const Instance&, const Modele::Lecture& l) {
            // Une sonde montre l'instant présent : c'est un point de mesure,
            // pas un appareil à moyenne.
            return format_mesure(l.tension ? l.tension("1") : 0.0, "V");
        };
        enregistrer(std::move(m));
    }
    {   // --------------------------------------------------------- oscilloscope
        // Le scope est un COMPOSANT DU SCHÉMA, pas un appareil posé à côté.
        //
        // C'est le modèle de Simulink : le Scope est un bloc, on lui câble ce
        // qu'on veut voir, et un double-clic ouvre SA fenêtre. Ce qui est
        // câblé est ce qui s'affiche — il n'y a rien à choisir dans une liste
        // de signaux, et le schéma documente lui-même ce qu'on observe.
        //
        // L'autre modèle — un oscilloscope unique sur le côté, dont on
        // promène les sondes — est celui de la paillasse, et l'application
        // l'a déjà. Il ne se remplace pas : il ne sait pas montrer deux
        // endroits éloignés dans deux fenêtres, et c'est précisément ce que
        // demande la comparaison entrée/sortie d'un filtre.
        //
        // QUATRE VOIES, et c'est le seul oscilloscope du logiciel.
        //
        // Il y en avait deux : celui-ci, et un appareil d'atelier à quatre
        // voies dont on promenait les sondes depuis un onglet. Deux réponses
        // à la même question — « comment je regarde un signal ? » — dont
        // aucune n'était la bonne à coup sûr, et un débutant qui trouve deux
        // oscilloscopes en cherche un troisième.
        //
        // Le bloc l'emporte parce que c'est le modèle de MATLAB : ce qui est
        // CÂBLÉ est ce qui s'affiche, et le schéma documente alors lui-même
        // ce qu'on observe. Il hérite des quatre voies de l'appareil qu'il
        // remplace : rien n'est perdu au change.
        //
        // Chaque voie se mesure par rapport à la masse : c'est ce que fait une
        // sonde ordinaire, et la mesure différentielle demanderait un appareil
        // que l'on n'a pas.
        Modele m;
        m.type = "scope";
        m.libelle = "Oscilloscope (bloc)";
        m.categorie = "Instruments";
        m.prefixe = "SCP";
        m.bornes = {{"A", {-40, -30}, "voie 1"},
                    {"B", {-40, -10}, "voie 2"},
                    {"C", {-40, 10}, "voie 3"},
                    {"D", {-40, 30}, "voie 4"}};
        m.symbole = {
            rect(-30, -40, 30, 40),
            ligne(-40, -30, -30, -30), ligne(-40, -10, -30, -10),
            ligne(-40, 10, -30, 10), ligne(-40, 30, -30, 30),
            // Une sinusoïde stylisée dans l'écran : on reconnaît l'appareil
            // avant d'avoir lu son étiquette.
            ligne(-22, 0, -16, -12), ligne(-16, -12, -10, 0),
            ligne(-10, 0, -4, 12), ligne(-4, 12, 2, 0),
            ligne(2, 0, 8, -12), ligne(8, -12, 14, 0),
            ligne(14, 0, 20, 12), ligne(20, 12, 24, 6)};
        m.empreinte = {"", {}, 0, 0};
        // Il faut une lecture pour que le double-clic ouvre l'appareil plutôt
        // que le panneau de propriétés ; l'étiquette dit ce qu'il montre.
        m.mesure_instrument = [](const Instance&, const Modele::Lecture& l) {
            // L'étiquette ne montre que les deux premières voies : quatre
            // tensions à côté d'un symbole en font une bouillie, et le détail
            // est dans la fenêtre, à un double-clic.
            const double a = l.tension ? l.tension("A") : 0.0;
            const double b = l.tension ? l.tension("B") : 0.0;
            return format_mesure(a, "V") + " / " + format_mesure(b, "V");
        };
        enregistrer(std::move(m));
    }
}

}  // namespace coeur
