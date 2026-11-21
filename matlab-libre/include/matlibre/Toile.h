// Toile.h — ce sur quoi une figure se dessine.
//
// Une figure se dessine deux fois : en SVG, pour « print », « saveas » et
// les captures, et dans la fenêtre du bureau. Les deux rendus étaient deux
// copies du même dessin, écrites l'une à côté de l'autre, et s'écartaient :
// la fenêtre plaçait la légende, les marges et la barre de couleurs à sa
// façon, et chaque nouveauté — un texte incliné, une barre de couleurs en
// bas — était à écrire deux fois.
//
// Le dessin est donc fait une seule fois, par « dessinerFigure », sur une
// Toile : quelques primitives — traits, polygones, rectangles, cercles,
// textes, découpe. ToileSVG les écrit en SVG ; la toile du bureau les
// peint avec QPainter. La mise en page, les graduations, la légende ne
// connaissent que la Toile.
#pragma once

#include <string>
#include <vector>

#include "matlibre/Graphique.h"

namespace matlibre {

// Un trait : sa couleur (« #RRGGBB », un nom SVG), son épaisseur en
// pixels, son motif — « - », « -- », « : », « -. » — et, pour le SVG, une
// classe de la feuille de style (« axe », « grille ») qui remplace alors
// couleur et épaisseur.
struct Trait {
    std::string couleur = "#222";
    double epaisseur = 1;
    std::string motif = "-";
    std::string classe;
};

// Un morceau de texte. L'interpréteur TeX coupe un texte en morceaux :
// un indice, un exposant, une lettre grecque en italique… NIVEAU compte
// les exposants (positif) et les indices (négatif) ; ECHELLE est la taille
// relative à celle du texte.
struct Morceau {
    std::string texte;
    int niveau = 0;
    bool italique = false;
    bool gras = false;
    double echelle = 1.0;
    // Vide : la couleur du texte ; sinon celle de « \color{...} ».
    std::string couleur;
};

struct StyleTexte {
    // La taille en pixels. EXPLICITE : imposée par le programme — le SVG ne
    // l'écrit qu'alors, la feuille de style donnant celle par défaut.
    double taille = 12;
    bool tailleExplicite = false;
    // Vide : la couleur par défaut des textes.
    std::string couleur;
    // Le point d'ancrage, sur la ligne de base : à gauche, au centre, à
    // droite (« l », « c », « r »).
    char ancre = 'l';
    // En degrés, dans le sens trigonométrique, autour du point d'ancrage :
    // 90 écrit de bas en haut, comme une étiquette d'ordonnées.
    double angle = 0;
    bool gras = false;
    // Une classe de la feuille de style du SVG (« titre »).
    std::string classe;
};

class Toile {
public:
    virtual ~Toile() = default;

    // La largeur qu'occupera un texte : ce qui dimensionne une légende,
    // une marge d'étiquettes.
    virtual double largeur(const std::vector<Morceau>& texte, double taille,
                           bool gras = false) const = 0;

    virtual void ligne(double x1, double y1, double x2, double y2, const Trait& trait) = 0;
    // Une ligne brisée ; un point non fini la coupe.
    virtual void polyligne(const std::vector<double>& x, const std::vector<double>& y,
                           const Trait& trait) = 0;
    // Un polygone fermé, rempli de FOND (« none » : creux), d'opacité
    // OPACITE, bordé de BORD (nul : sans bord).
    virtual void polygone(const std::vector<double>& x, const std::vector<double>& y,
                          const std::string& fond, double opacite, const Trait* bord) = 0;
    virtual void rectangle(double x, double y, double largeur, double hauteur,
                           const std::string& fond, double opacite, const Trait* bord) = 0;
    virtual void cercle(double cx, double cy, double rayon, const std::string& fond,
                        const Trait* bord) = 0;
    virtual void texte(double x, double y, const std::vector<Morceau>& texte,
                       const StyleTexte& style) = 0;

    // Ce qui suit est découpé au rectangle, jusqu'à finDecoupe.
    virtual void decouper(double x, double y, double largeur, double hauteur) = 0;
    virtual void finDecoupe() = 0;
    // Un groupe nommé : le SVG l'écrit, la fenêtre l'ignore.
    virtual void groupe(const std::string& classe) { (void)classe; }
    virtual void finGroupe() {}
};

// Dessine la figure sur la toile, à la taille donnée en pixels.
void dessinerFigure(const Figure& figure, Toile& toile, int largeur, int hauteur);

// Les morceaux d'un texte : un seul morceau sans interprète, ceux que
// donne le TeX de MATLAB sinon (Tex.cpp).
std::vector<Morceau> morceauxTexte(const std::string& texte, bool tex = true);
// Selon la propriété « Interpreter » de MATLAB : 'tex' (le défaut),
// 'none' (le texte tel quel) ou 'latex' (lu comme du TeX, sans dollars).
std::vector<Morceau> morceauxInterpretes(const std::string& texte,
                                         const std::string& interprete);

// La chasse d'un texte en Helvetica (Arial et Liberation Sans ont les
// mêmes), d'après les métriques AFM : ce que mesure la toile SVG.
double largeurHelvetica(const std::string& texte, double taille, bool gras = false);

}  // namespace matlibre
