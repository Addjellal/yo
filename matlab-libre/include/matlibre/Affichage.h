// Affichage.h — mise en forme des résultats, à la manière de MATLAB.
//
// « x = 3 » affiche « x = 3 » ; une matrice s'affiche en colonnes alignées,
// avec au besoin un facteur commun (« 1.0e+03 * »), et découpée en paquets
// de colonnes quand la fenêtre est trop étroite.
#pragma once

#include <iosfwd>
#include <string>

#include "matlibre/Valeur.h"

namespace matlibre {

class Interpreteur;

void afficherResultat(Interpreteur& it, const std::string& nom, const Valeur& v);
// Écrit la valeur au fil de l'eau. « rendreValeur » rend la même chose
// dans une chaîne, ce qui demande de tout tenir en mémoire : un vecteur de
// dix millions d'éléments s'y écrit en cent soixante mégaoctets avant
// qu'un seul caractère paraisse, et l'interruption ne rendait la main
// qu'après. Tout ce qui affiche à l'écran passe donc par la forme en flux.
//
// « nom » est celui de la variable qu'on affiche : il met les en-têtes de
// MATLAB — « 2×2 cell array », « struct with fields: », « 1×3 int8 row
// vector » — et nomme les pages d'un tableau à trois dimensions,
// « x(:,:,2) = ». Sans nom, c'est la forme de « disp », sans en-tête.
void ecrireValeur(std::ostream& os, const Valeur& v, int format, bool compact,
                  int largeur = 80, const std::string& nom = std::string());
std::string rendreValeur(const Valeur& v, int format, bool compact, int largeur = 80,
                         const std::string& nom = std::string());
// Une carte (containers.Map), par ses propriétés : Count, KeyType,
// ValueType.
void ecrireCarte(std::ostream& os, Interpreteur& it, const Valeur& v, bool compact);
// Un scalaire, mis en forme. « simple » dit que la valeur est un
// « single » : elle ne porte que sept décimales sûres, et MATLAB n'en
// montre pas davantage — « format long » rend 3.1415927, non
// 3.141592741012573, qui n'est que la lecture en double d'un single.
std::string rendreScalaire(double x, int format, bool simple = false);
std::string nombreVersTexte(double x, int chiffres);
std::string descriptionCourte(const Valeur& v);

}  // namespace matlibre
