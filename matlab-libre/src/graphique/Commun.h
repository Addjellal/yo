// Commun.h — ce que partagent le dessin plan (Dessin.cpp) et celui de
// l'espace (Espace.cpp) : traits, textes, marqueurs, couleurs des points.
#pragma once

#include <string>
#include <vector>

#include "matlibre/Toile.h"

namespace matlibre {
namespace dessin {

extern const double PI;

// Le trait des axes et des graduations, celui de la grille, et un trait
// quelconque.
Trait traitAxe();
Trait traitGrille();
Trait trait(const std::string& couleur, double epaisseur, const std::string& motif = "-");

// Un texte sans interprète, en un seul morceau.
std::vector<Morceau> simple(const std::string& texte);
// L'étiquette d'une graduation : 10 puissance n sur un axe logarithmique.
std::vector<Morceau> etiquetteGraduation(double v, bool log);

// Un marqueur de MATLAB en (PX, PY) : BORD et FACE sont des couleurs, FACE
// pouvant valoir « none ».
void dessinerMarqueur(Toile& toile, const FormeMarqueur& f, double px, double py,
                      const std::string& bord, const std::string& face);
// Les couleurs de bord et de face des marqueurs d'une courbe.
void couleursMarqueur(const Serie& s, const std::string& couleur, std::string& bord,
                      std::string& face);
// Une couleur « rgb(r,v,b) ».
std::string rvb(int r, int v, int b);
// La couleur du point K d'un nuage, et le bord et la face de son marqueur.
std::string couleurPoint(const std::vector<double>& palette, double cmin, double cmax,
                         const Serie& s, std::size_t k);
void couleursPoint(const Serie& s, const std::string& couleur, std::string& bord,
                   std::string& face);

// Le dessin d'un axe en perspective (Espace.cpp), dans le cadre donné.
void dessinerEspace(const Figure& figure, const Axes& a, Toile& toile, int gauche, int droite,
                    int haut, int bas);

}  // namespace dessin
}  // namespace matlibre
