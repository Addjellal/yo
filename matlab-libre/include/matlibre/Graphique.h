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
    // Graduations imposées par l'utilisateur : « ax.XTick = [15 40 60] ».
    // Vides, les graduations sont choisies automatiquement.
    std::vector<double> ticksX, ticksY;
    std::vector<std::string> etiquettesTicksX, etiquettesTicksY;
    bool boite = true;
    double taillePolice = 10;
};

struct Figure {
    int numero = 1;
    std::vector<std::shared_ptr<Axes>> axes;
    int axeCourant = 0;
    int lignes = 1, colonnes = 1;
    int largeur = 800, hauteur = 600;
    std::string nom;
};

// Réduit une polyligne à ce qu'un écran peut montrer.
//
// Un tracé de cent mille points sur huit cents pixels de large dessine
// cent vingt-cinq points par colonne : cent vingt-quatre d'entre eux sont
// invisibles, mais ils pèsent — un SVG de 1,6 Mo que le navigateur met des
// secondes à lire. Pour chaque colonne de pixels on ne garde donc que ce
// qui se voit : le premier point, le minimum, le maximum et le dernier,
// dans l'ordre où ils arrivent. L'enveloppe tracée est identique au pixel
// près ; c'est ce que font les bibliothèques de tracé sérieuses.
//
// Les indices sont rendus dans l'ordre croissant. Un tracé déjà court, ou
// dont les x ne progressent pas régulièrement, est rendu tel quel.
std::vector<std::size_t> indicesVisibles(const std::vector<double>& x,
                                         const std::vector<double>& y, double xmin,
                                         double xmax, int colonnes);

// Poignées de MATLAB : « ax = gca » puis « ax.XTick = [...] ».
Valeur poigneeAxesCourants(Interpreteur& it);
Valeur poigneeFigureCourante(Interpreteur& it);

std::string rendreSVG(const Figure& figure);
std::shared_ptr<Figure> figureCourante(Interpreteur& it);
std::shared_ptr<Axes> axesCourants(Interpreteur& it);

}  // namespace matlibre
