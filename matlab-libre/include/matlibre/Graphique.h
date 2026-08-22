// Graphique.h — figures, axes et tracés.
//
// Le rendu se fait en SVG : un format vectoriel, lisible, qu'aucune
// bibliothèque externe n'est nécessaire pour produire, et que tous les
// navigateurs et éditeurs savent afficher. « print » et « saveas » écrivent
// le fichier ; en session interactive, la figure est aussi écrite dans le
// dossier indiqué par MATLIBRE_FIGURES si la variable existe.
#pragma once

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "matlibre/Valeur.h"

namespace matlibre {

class Interpreteur;

enum class GenreTrace { Ligne, Barres, Points, Escalier, Tige, Aire, Image, Contour, Surface };

struct Serie {
    GenreTrace genre = GenreTrace::Ligne;
    std::vector<double> x, y, z;
    int largeurImage = 0, hauteurImage = 0;
    std::string couleur = "#0072BD";
    std::string style = "-";
    std::string marqueur;
    std::string etiquette;
    double epaisseur = 1.5;
};

struct Axes {
    std::vector<Serie> series;
    std::string titre, etiquetteX, etiquetteY, etiquetteZ;
    bool grille = false;
    bool tenir = false;
    bool logX = false, logY = false;
    bool limitesManuellesX = false, limitesManuellesY = false;
    double xmin = 0, xmax = 1, ymin = 0, ymax = 1;
    std::vector<std::string> legende;
    bool legendeVisible = false;
    int rangee = 1, colonne = 1, position = 1;  // découpage subplot
};

struct Figure {
    int numero = 1;
    std::vector<std::shared_ptr<Axes>> axes;
    int axeCourant = 0;
    int lignes = 1, colonnes = 1;
    int largeur = 800, hauteur = 600;
    std::string nom;
};

std::string rendreSVG(const Figure& figure);
std::shared_ptr<Figure> figureCourante(Interpreteur& it);
std::shared_ptr<Axes> axesCourants(Interpreteur& it);

}  // namespace matlibre
