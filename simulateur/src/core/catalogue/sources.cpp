// Catalogue — sources de signal.
//
// Le générateur de signaux est l'instrument qui manque dès qu'on veut faire
// autre chose qu'allumer une LED : c'est lui qui permet de tracer une
// caractéristique de transfert (balayage continu), un diagramme de Bode
// (balayage fréquentiel) et un spectre. Il porte donc trois descriptions à la
// fois, comme dans SPICE : une valeur continue pour le point de repos, une
// amplitude alternative pour l'analyse fréquentielle, et une forme d'onde pour
// le régime transitoire.
#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

#include "core/Netlist.h"
#include "core/catalogue/Traits.h"

namespace coeur {

namespace {

// Description SPICE de la forme d'onde, en régime transitoire.
std::string forme_onde(const Instance& i) {
    const std::string forme = i.texte("forme", "sinus");
    const double amplitude = i.valeur("amplitude", 1.0);
    const double frequence = i.valeur("frequence", 1000.0);
    const double offset = i.valeur("offset", 0.0);
    const double periode = frequence > 0 ? 1.0 / frequence : 1e-3;
    using traits::nombre;

    if (forme == "carre") {
        const double rapport =
            std::min(99.0, std::max(1.0, i.valeur("rapport", 50.0))) / 100.0;
        return "PULSE(" + nombre(offset - amplitude) + " "
               + nombre(offset + amplitude) + " 0 1e-7 1e-7 "
               + nombre(rapport * periode) + " " + nombre(periode) + ")";
    }
    if (forme == "triangle") {
        // un PULSE dont les fronts occupent toute la période : c'est
        // exactement un triangle.
        return "PULSE(" + nombre(offset - amplitude) + " "
               + nombre(offset + amplitude) + " 0 " + nombre(periode / 2) + " "
               + nombre(periode / 2) + " 1e-9 " + nombre(periode) + ")";
    }
    if (forme == "continu") return "";
    return "SIN(" + nombre(offset) + " " + nombre(amplitude) + " "
           + nombre(frequence) + ")";
}

}  // namespace

void enregistrer_sources(Catalogue& catalogue) {
    using G = Propriete::Genre;
    using namespace traits;

    {   // ------------------------------------------- générateur de signaux
        Modele m;
        m.type = "generateur_signal";
        m.libelle = "Générateur de signaux";
        m.categorie = "Instruments";
        m.prefixe = "GBF";
        m.generateur = true;
        m.bornes = {{"+", {0, -34}, ""}, {"-", {0, 34}, ""}};
        m.proprietes = {
            {"forme", "Forme", G::Choix, 0, 0, 0, "sinus",
             {"sinus", "carre", "triangle", "continu"}, ""},
            {"amplitude", "Amplitude", G::Nombre, 1.0, 0, 0, "", {}, "V"},
            {"frequence", "Fréquence", G::Nombre, 1000.0, 0, 0, "", {}, "Hz"},
            {"offset", "Décalage continu", G::Nombre, 0.0, 0, 0, "", {}, "V"},
            {"rapport", "Rapport cyclique", G::Nombre, 50.0, 0, 0, "", {}, "%"}};
        m.symbole = {cercle(0, 0, 24), ligne(0, -34, 0, -24), ligne(0, 24, 0, 34)};
        // Une sinusoïde dessinée point par point : plus parlante qu'un texte,
        // et le symbole reste de la donnée.
        for (int k = 0; k < 12; ++k) {
            const double x0 = -12 + k * 2.0, x1 = x0 + 2.0;
            const double y0 = -9 * std::sin(x0 / 12.0 * 3.14159265358979);
            const double y1 = -9 * std::sin(x1 / 12.0 * 3.14159265358979);
            m.symbole.push_back(ligne(x0, y0, x1, y1));
        }
        m.empreinte = {"", {}, 0, 0};
        m.vers_spice = [](const Instance& i, const auto& noeud) {
            // « DC » sert au point de repos et au balayage continu, « AC 1 »
            // à l'analyse fréquentielle, la forme d'onde au transitoire. Les
            // trois cohabitent sur la même ligne, comme le veut SPICE.
            std::string ligne_source = "V" + i.reference + " " + noeud("+") + " "
                                       + noeud("-") + " DC "
                                       + nombre(i.valeur("offset", 0.0))
                                       + " AC " + nombre(i.valeur("ac", 1.0));
            const std::string onde = forme_onde(i);
            if (!onde.empty()) ligne_source += " " + onde;
            return std::vector<std::string>{ligne_source};
        };
        m.lecture = [](const Instance& i) {
            const std::string forme = i.texte("forme", "sinus");
            if (forme == "continu") return nombre(i.valeur("offset", 0.0)) + " V";
            return nombre(i.valeur("frequence", 1000.0)) + " Hz";
        };
        catalogue.enregistrer(std::move(m));
    }
}

}  // namespace coeur
