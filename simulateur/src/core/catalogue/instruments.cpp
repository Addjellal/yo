// Catalogue — instruments de mesure.
//
// Un instrument est un composant comme les autres : il a une place dans le
// circuit et il le charge, très peu mais réellement. Un voltmètre parfait
// n'existe pas, et un ampèremètre non plus — les modéliser ainsi évite
// d'enseigner une mesure sans influence sur le montage.
#include <string>
#include <vector>

#include "core/Netlist.h"
#include <cmath>
#include <sstream>

#include "core/catalogue/Traits.h"

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
        m.proprietes = {{"impedance", "Impédance d'entrée", G::Nombre, 1e7, 0, 0,
                         "", {}, "Ω"}};
        m.symbole = {cercle(0, 0, 22), ligne(-30, 0, -22, 0), ligne(22, 0, 30, 0),
                     texte(-7, 6, "V", 14)};
        m.empreinte = {"", {}, 0, 0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("+") + " " + noeud("-") + " "
                + nombre(i.valeur("impedance", 1e7))};
        };
        m.mesure_instrument = [](const Instance&, const auto& tension, double) {
            return format_mesure(tension("+") - tension("-"), "V");
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
        m.proprietes = {{"shunt", "Résistance de shunt", G::Nombre, 0.01, 0, 0,
                         "", {}, "Ω"}};
        m.symbole = {cercle(0, 0, 22), ligne(-30, 0, -22, 0), ligne(22, 0, 30, 0),
                     texte(-7, 6, "A", 14)};
        m.empreinte = {"", {}, 0, 0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return std::vector<std::string>{
                "R" + i.reference + " " + noeud("+") + " " + noeud("-") + " "
                + nombre(i.valeur("shunt", 0.01))};
        };
        m.mesure_instrument = [](const Instance&, const auto&, double courant) {
            return format_mesure(courant, "A");
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
        m.mesure_instrument = [](const Instance&, const auto& tension, double) {
            return format_mesure(tension("1"), "V");
        };
        enregistrer(std::move(m));
    }
}

}  // namespace coeur
