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

#include "coeur/Device.h"

namespace coeur {
namespace traits {

inline std::string nombre(double valeur) {
    std::ostringstream flux;
    flux << valeur;
    return flux.str();
}

using T = TraitSymbole;

inline T ligne(double x1, double y1, double x2, double y2) {
    return {T::Genre::Ligne, {{x1, y1}, {x2, y2}}, 0, "", false, ""};
}
inline T rect(double x1, double y1, double x2, double y2, bool rempli = false) {
    return {T::Genre::Rect, {{x1, y1}, {x2, y2}}, 0, "", rempli, ""};
}
inline T cercle(double x, double y, double rayon, bool rempli = false) {
    return {T::Genre::Cercle, {{x, y}}, rayon, "", rempli, ""};
}
inline T poly(std::vector<PointSymbole> points, bool rempli = true) {
    return {T::Genre::Polygone, std::move(points), 0, "", rempli, ""};
}
inline T texte(double x, double y, const std::string& contenu,
               double taille = 9) {
    return {T::Genre::Texte, {{x, y}}, taille, contenu, false, ""};
}

// Un trait QUI S'ALLUME, et par quel courant.
//
// Le suffixe s'ajoute à la référence du composant pour trouver le courant :
// « 0 » sur un afficheur AF1 désigne le courant relevé sous « af10 ». C'est ce
// qui permet à un morceau de symbole de s'éclairer seul, là où le halo
// n'éclaire qu'un composant entier.
inline T segment(T trait, const std::string& suffixe) {
    trait.lumiere = suffixe;
    return trait;
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
