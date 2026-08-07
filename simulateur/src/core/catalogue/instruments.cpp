// Catalogue — instruments de mesure.
//
// Un instrument est un composant comme les autres : il a une place dans le
// circuit et il le charge, très peu mais réellement. Un voltmètre parfait
// n'existe pas, et un ampèremètre non plus — les modéliser ainsi évite
// d'enseigner une mesure sans influence sur le montage.
#include <string>
#include <vector>

#include "core/Netlist.h"
#include "core/catalogue/Traits.h"

namespace coeur {

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
        enregistrer(std::move(m));
    }
}

}  // namespace coeur
