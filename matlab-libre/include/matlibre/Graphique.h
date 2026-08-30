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
    // Identifiant stable dans sa figure : les poignees designent un axe par
    // lui, et non par son rang, ce qui les laisse valides quand « subplot »
    // en efface un autre.
    int identifiant = 0;
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
    // « subplot(2,2,[1 2]) » : la case va de « position » à « positionFin ».
    // Zéro veut dire une seule case.
    int positionFin = 0;
    // Position imposée, à la façon de MATLAB : « axes('Position',[g b l h]) »
    // ou « ax.Position = [...] », en fractions de la figure, l'origine en
    // bas à gauche. Sans elle, la case du découpage donne le rectangle.
    bool positionManuelle = false;
    double posGauche = 0, posBas = 0, posLargeur = 1, posHauteur = 1;
    // Graduations imposées par l'utilisateur : « ax.XTick = [15 40 60] ».
    // Vides, les graduations sont choisies automatiquement.
    std::vector<double> ticksX, ticksY;
    std::vector<std::string> etiquettesTicksX, etiquettesTicksY;
    bool boite = true;
    double taillePolice = 10;
    // « axis equal » / « axis square » / « axis off ». MATLAB : equal
    // donne la meme echelle aux deux axes — un cercle est rond —, square
    // rend la boite carree, off cache le cadre, les graduations et les
    // etiquettes sans toucher aux courbes.
    enum class Proportions { Auto, Egales, Carre };
    Proportions proportions = Proportions::Auto;
    bool axesVisibles = true;
};

// Rectangle qu'occupe un axe dans sa figure, en fractions de la largeur et
// de la hauteur, l'origine en HAUT à gauche — celle des deux rendus, le SVG
// et la fenêtre. Sans position imposée, c'est la case du découpage subplot,
// ce qui laisse coexister dans une même figure des découpages différents :
// « subplot(2,2,1) » puis « subplot(2,1,2) » ne se déplacent pas l'un
// l'autre, comme dans MATLAB.
void cadreAxes(const Axes& a, double& x, double& y, double& largeur, double& hauteur);

// Vrai si les deux axes se recouvrent. MATLAB efface les axes qu'une
// nouvelle case recouvre : c'est ce qui fait que « subplot(2,1,1) » après
// « subplot(2,2,1) » remplace bien les deux cases du haut.
bool axesSeRecouvrent(const Axes& a, const Axes& b);

// Graduations d'un axe. En échelle linéaire, un pas de 1, 2 ou 5 fois une
// puissance de dix ; en échelle logarithmique, les décades — 0,01, 0,1, 1,
// 10 —, avec un repli sur les 1-2-5 de la décade quand l'intervalle en
// couvre moins d'une. C'est ce que montre MATLAB.
std::vector<double> graduationsAxe(double bas, double haut, int cible, bool log);

// Bornes d'un axe logarithmique : les valeurs nulles ou négatives n'y ont
// pas de place. Rend faux si aucune donnée ne peut être portée.
bool bornesLog(double& bas, double& haut);

// Applique « axis equal » et « axis square » : ajuste la boite en pixels
// et les bornes pour tenir les proportions demandees. Les deux rendus —
// le SVG et le bureau — passent par la, pour donner la meme image.
void appliquerProportions(const Axes& a, int& gauche, int& droite, int& haut, int& bas,
                          double& xmin, double& xmax, double& ymin, double& ymax);

struct Figure {
    int numero = 1;
    int prochainIdentifiant = 1;
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

// Ajoute un axe a une figure et lui donne son identifiant. Tout axe cree
// passe par la.
std::shared_ptr<Axes> ajouterAxes(Figure& f);

std::string rendreSVG(const Figure& figure);
std::shared_ptr<Figure> figureCourante(Interpreteur& it);
std::shared_ptr<Axes> axesCourants(Interpreteur& it);

}  // namespace matlibre
