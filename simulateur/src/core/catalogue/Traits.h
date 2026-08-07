// Raccourcis partagés par les fichiers de catalogue.
//
// Ils n'existent que pour une raison : qu'un composant se décrive en un bloc
// lisible. Si décrire un composant devient pénible, on en ajoutera peu — et
// l'ambition d'un catalogue fourni tombe.
#pragma once

#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "core/Device.h"

namespace coeur {
namespace traits {

inline std::string nombre(double valeur) {
    std::ostringstream flux;
    flux << valeur;
    return flux.str();
}

using T = TraitSymbole;

inline T ligne(double x1, double y1, double x2, double y2) {
    return {T::Genre::Ligne, {{x1, y1}, {x2, y2}}, 0, "", false};
}
inline T rect(double x1, double y1, double x2, double y2, bool rempli = false) {
    return {T::Genre::Rect, {{x1, y1}, {x2, y2}}, 0, "", rempli};
}
inline T cercle(double x, double y, double rayon, bool rempli = false) {
    return {T::Genre::Cercle, {{x, y}}, rayon, "", rempli};
}
inline T poly(std::vector<PointSymbole> points, bool rempli = true) {
    return {T::Genre::Polygone, std::move(points), 0, "", rempli};
}
inline T texte(double x, double y, const std::string& contenu,
               double taille = 9) {
    return {T::Genre::Texte, {{x, y}}, taille, contenu, false};
}

// Corps rectangulaire avec deux rangées de broches : la forme de la plupart
// des circuits intégrés.
inline void boitier(Modele& m, double largeur, double hauteur,
                    const std::string& etiquette) {
    m.symbole.push_back(rect(-largeur / 2, -hauteur / 2, largeur / 2, hauteur / 2));
    m.symbole.push_back(texte(-largeur / 2 + 6, 4, etiquette, 10));
}

}  // namespace traits
}  // namespace coeur
