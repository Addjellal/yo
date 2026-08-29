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
void ecrireValeur(std::ostream& os, const Valeur& v, int format, bool compact,
                  int largeur = 80);
std::string rendreValeur(const Valeur& v, int format, bool compact, int largeur = 80);
std::string rendreScalaire(double x, int format);
std::string nombreVersTexte(double x, int chiffres);
std::string descriptionCourte(const Valeur& v);

}  // namespace matlibre
