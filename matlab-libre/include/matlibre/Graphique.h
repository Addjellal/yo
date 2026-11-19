// Graphique.h — figures, axes et tracés.
//
// Le rendu se fait en SVG : un format vectoriel, lisible, qu'aucune
// bibliothèque externe n'est nécessaire pour produire, et que tous les
// navigateurs et éditeurs savent afficher. « print » et « saveas » écrivent
// le fichier ; en session interactive, la figure est aussi écrite dans le
// dossier indiqué par MATLIBRE_FIGURES si la variable existe.
#pragma once

#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "matlibre/Valeur.h"

namespace matlibre {

class Interpreteur;

// L'interprete d'un texte de la figure. MATLAB lit par defaut chaque
// titre, etiquette, libelle de legende et texte pose comme du TeX :
// « x_1 » met le 1 en indice. « 'Interpreter','none' » garde le texte tel
// quel, ce qu'on veut pour un nom de fichier.
enum class Interprete { Tex, Aucun, Latex };

enum class GenreTrace {
    Ligne, Barres, Points, Escalier, Tige, Aire, Image, Contour, Surface,
    // Un polygone ferme et rempli : « fill ».
    Polygone,
    // Une droite qui traverse tout l'axe : « xline » et « yline ». Elle
    // suit les bornes au lieu de les imposer, ce qu'aucune serie
    // ordinaire ne sait faire.
    Constante,
    // Un texte pose dans l'axe : « text(x,y,'ici') ». Comme la droite
    // constante, il ne fixe pas les bornes — un mot ne dilate pas le
    // dessin.
    Texte
};

struct Serie {
    // Identifiant stable dans son axe : « h = plot(...) » rend une
    // poignee qui designe la courbe par lui, et non par son rang, ce qui
    // la laisse valide quand une autre courbe est ajoutee ou retiree.
    int identifiant = 0;
    GenreTrace genre = GenreTrace::Ligne;
    std::vector<double> x, y, z;
    // Les coordonnees d'origine d'une courbe de l'espace. « plot3 » range
    // dans x et y la projection — c'est elle qu'on dessine, le rendu etant
    // plan —, et garde ici ce qu'on lui a donne, pour que « XData » et
    // « YData » rendent les vraies valeurs et non l'ombre portee.
    std::vector<double> xVraies, yVraies;
    int largeurImage = 0, hauteurImage = 0;
    std::string couleur = "#0072BD";
    // Le contour d'une surface remplie se règle à part : « patch(x,y,c,
    // 'EdgeColor',k) » veut un bord noir sur un fond clair, et sans ce
    // champ la couleur de remplissage servait aussi de contour — un
    // polygone blanc y devenait invisible.
    std::string couleurBord;
    // L'opacité du remplissage. MATLAB remplit opaque ; « FaceAlpha » la
    // baisse quand on veut voir au travers.
    double opacite = 1.0;
    std::string style = "-";
    std::string marqueur;
    std::string etiquette;
    double epaisseur = 1.5;
    // Pour une droite constante : 'x' pour une verticale — « xline » —,
    // 'y' pour une horizontale. La valeur est dans x[0].
    char axeConstante = 'x';
    // Le texte pose le long de la droite, s'il y en a un ; pour une serie
    // « Texte », c'est le texte lui-meme.
    std::string legendeConstante;
    // Taille de police d'un texte pose ; zero veut dire celle de l'axe.
    double taillePoliceTexte = 0;
    // Alignement horizontal d'un texte pose : 'l', 'c' ou 'r'.
    char alignement = 'l';
    // L'interprete d'un texte pose.
    Interprete interprete = Interprete::Tex;
};

struct Axes {
    // Identifiant stable dans sa figure : les poignees designent un axe par
    // lui, et non par son rang, ce qui les laisse valides quand « subplot »
    // en efface un autre.
    int identifiant = 0;
    std::vector<Serie> series;
    // Compteur des identifiants de courbes de cet axe.
    int prochaineSerie = 0;
    std::string titre, etiquetteX, etiquetteY, etiquetteZ;
    bool grille = false;
    bool tenir = false;
    bool logX = false, logY = false;
    bool limitesManuellesX = false, limitesManuellesY = false;
    double xmin = 0, xmax = 1, ymin = 0, ymax = 1;
    std::vector<std::string> legende;
    bool legendeVisible = false;
    // La « Location » de la legende, en minuscules. Les emplacements
    // « ...outside » se logent hors de l'axe, qui recule d'autant.
    std::string emplacementLegende = "northeast";
    // Le compteur des courbes quand la legende a ete posee. Celles d'avant
    // n'y entrent que si un libelle leur revient ; celles d'apres s'y
    // ajoutent d'elles-memes, comme le fait l'« AutoUpdate » de MATLAB.
    int legendeJusqua = 0;
    Interprete interpreteTitre = Interprete::Tex, interpreteX = Interprete::Tex,
               interpreteY = Interprete::Tex, interpreteZ = Interprete::Tex,
               interpreteLegende = Interprete::Tex;
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
    // La taille du titre, quand « set(z,'FontSize',16) » l'impose ; zéro
    // laisse celle du rendu.
    double taillePoliceTitre = 0;
    // « axis equal » / « axis square » / « axis off ». MATLAB : equal
    // donne la meme echelle aux deux axes — un cercle est rond —, square
    // rend la boite carree, off cache le cadre, les graduations et les
    // etiquettes sans toucher aux courbes.
    enum class Proportions { Auto, Egales, Carre };
    Proportions proportions = Proportions::Auto;
    // Sens des axes : « axis ij » et « set(gca,'YDir','reverse') » font
    // descendre les ordonnees, ce qu'attend toute image affichee par
    // « imagesc » — la ligne 1 en haut.
    bool xInverse = false, yInverse = false;
    bool axesVisibles = true;
};

// Rectangle qu'occupe un axe dans sa figure, en fractions de la largeur et
// de la hauteur, l'origine en HAUT à gauche — celle des deux rendus, le SVG
// et la fenêtre. Sans position imposée, c'est la case du découpage subplot,
// ce qui laisse coexister dans une même figure des découpages différents :
// « subplot(2,2,1) » puis « subplot(2,1,2) » ne se déplacent pas l'un
// l'autre, comme dans MATLAB.
void cadreAxes(const Axes& a, double& x, double& y, double& largeur, double& hauteur);

// Les bornes d'un axe : celles qu'on a fixées, ou celles des données.
// C'est ce que rend « xlim » sans argument, et ce que lit « get(gca,
// 'XLim') » — les deux doivent dire la même chose.
void limitesAxe(const Axes& a, double& xmin, double& xmax, double& ymin, double& ymax);

// Vrai si les deux axes se recouvrent. MATLAB efface les axes qu'une
// nouvelle case recouvre : c'est ce qui fait que « subplot(2,1,1) » après
// « subplot(2,2,1) » remplace bien les deux cases du haut.
bool axesSeRecouvrent(const Axes& a, const Axes& b);

// Graduations d'un axe. En échelle linéaire, un pas de 1, 2 ou 5 fois une
// puissance de dix ; en échelle logarithmique, les décades — 0,01, 0,1, 1,
// 10 —, avec un repli sur les 1-2-5 de la décade quand l'intervalle en
// couvre moins d'une. C'est ce que montre MATLAB.
std::vector<double> graduationsAxe(double bas, double haut, int cible, bool log);

// La couleur d'une valeur normalisee dans [0,1], suivant la carte des
// couleurs employee par « imagesc » et « surf ». Les deux rendus — le SVG
// et la fenetre — passent par la, faute de quoi la meme figure sortait
// bleue d'un cote et verte de l'autre.
void couleurCarte(double t, int& r, int& v, int& b);

// Bornes d'un axe logarithmique : les valeurs nulles ou négatives n'y ont
// pas de place. Rend faux si aucune donnée ne peut être portée.
bool bornesLog(double& bas, double& haut);

// Applique « axis equal » et « axis square » : ajuste la boite en pixels
// et les bornes pour tenir les proportions demandees. Les deux rendus —
// le SVG et le bureau — passent par la, pour donner la meme image.
void appliquerProportions(const Axes& a, int& gauche, int& droite, int& haut, int& bas,
                          double& xmin, double& xmax, double& ymin, double& ymax);

// « 'tex' », « 'none' » ou « 'latex' », sans egard a la casse. Une autre
// valeur est refusee, et le message nomme les trois, comme MATLAB.
Interprete interpreteDepuisTexte(const std::string& valeur, const std::string& classe);
const char* nomInterprete(Interprete interprete);

// Un morceau de texte d'un seul tenant. « echelle » est sa taille
// rapportee a celle du texte, « decalage » la hauteur de sa ligne de base
// au-dessus de celle du texte, en tailles du texte : un exposant monte, un
// indice descend, et tous deux sont plus petits.
struct MorceauTexte {
    std::string texte;
    double echelle = 1.0;
    double decalage = 0.0;
    bool gras = false;
    bool italique = false;
};

// Decoupe un texte selon son interprete. Sous TeX, « _ » et « ^ » font
// descendre ou monter le caractere qui suit, ou le groupe entre accolades ;
// « \alpha » s'ecrit α ; « \bf » et « \it » valent jusqu'a la fin du
// groupe. Les deux rendus peignent les memes morceaux, faute de quoi la
// fenetre et le SVG ne liraient pas « x_1 » de la meme facon.
std::vector<MorceauTexte> decouperTexte(const std::string& texte, Interprete interprete);

// Une entree de la legende : la courbe qu'elle montre, et son libelle.
struct EntreeLegende {
    const Serie* serie = nullptr;
    std::string libelle;
};

// Les entrees de la legende, dans l'ordre ou MATLAB les montre. Un texte
// pose n'en est jamais une : le compter donnait aux courbes une entree de
// trop, « data3 ». Les courbes tracees avant « legend » prennent les
// libelles dans l'ordre et restent dehors s'il en manque ; celles tracees
// apres s'ajoutent sous leur « DisplayName », ou « dataN ». Les deux
// rendus passent par la, et montrent donc les memes entrees.
std::vector<EntreeLegende> entreesLegende(const Axes& a);

// Ce que « Location » accepte, ramene en minuscules. Une autre valeur est
// refusee, avec la liste de celles qu'on accepte.
std::string emplacementLegendeDepuisTexte(const std::string& valeur);

// Loge hors de l'axe une legende de largeur et de hauteur donnees, quand
// son emplacement le veut : le cadre du trace — gauche, haut, droite, bas —
// recule, et la legende prend la bande liberee au bord de la case, au-dela
// des graduations, du titre et des etiquettes, qu'elle ne doit pas
// recouvrir. Rend vrai, et le coin haut-gauche de la boite dans x et y ;
// faux pour un emplacement dans l'axe, ou une case trop petite pour les
// deux.
bool logerLegendeHorsAxe(const std::string& emplacement, double largeur, double hauteur,
                         double caseGauche, double caseHaut, double caseDroite,
                         double caseBas, double& gauche, double& haut, double& droite,
                         double& bas, double& x, double& y);

// Ou tombe un point de donnees, en pixels ; faux s'il ne se place pas — une
// valeur non finie, ou negative sur un axe logarithmique.
using VersPixels = std::function<bool(double x, double y, double& px, double& py)>;

// Le coin haut-gauche de la boite d'une legende posee dans le cadre du
// trace. MATLAB promet a « best » le moins de conflit avec les donnees :
// des huit places de la rose, on garde celle qui en cache le moins.
void placerLegendeDansAxe(const Axes& a, double largeur, double hauteur, double gauche,
                          double haut, double droite, double bas,
                          const VersPixels& versPixels, double& x, double& y);

// La forme d'un marqueur autour de son centre, en pixels, l'ordonnee vers
// le bas : un cercle, ou des lignes brisees — fermees pour un polygone.
// Le SVG et la fenetre la dessinent l'un comme l'autre ; chacun dessinait
// la sienne, et la fenetre faisait de tout marqueur un point.
struct FormeMarqueur {
    double rayonCercle = 0;  // positif : un cercle de ce rayon
    bool plein = false;      // rempli de la couleur, sinon le contour seul
    bool ferme = false;      // les lignes sont des polygones
    std::vector<std::vector<std::pair<double, double>>> lignes;
};
// Vide pour « none » ou une chaine vide.
FormeMarqueur formeMarqueur(const std::string& marqueur);

// Ecrit une propriete de la legende d'un axe : ce que font « set(l, nom,
// valeur) » et les paires de « legend(..., nom, valeur) ». Un nom inconnu
// est refuse, comme dans MATLAB.
void ecrireProprieteLegende(Axes& a, const std::string& nom, const Valeur& valeur);
// Vrai si « nom » est une propriete de la legende : c'est ce qui dit ou
// finissent les libelles dans « legend('a', 'Location', 'best') ».
bool estProprieteLegende(const std::string& nom);

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
// La poignee du titre ou d'une etiquette de l'axe courant : « title »,
// « xlabel » et « ylabel » la rendent quand on la demande.
Valeur poigneeTexteCourant(Interpreteur& it, const std::string& cible);
Valeur poigneeFigureCourante(Interpreteur& it);
// La poignee d'une courbe : « h = plot(x,y) ; set(h,'LineWidth',2) ».
Valeur poigneeLigne(int figure, int axe, int serie);
// La poignee d'un texte pose dans un axe : il est range comme une serie,
// mais MATLAB en nomme la classe autrement, et « class(h) » doit le dire.
Valeur poigneeTexteTrace(int figure, int axe, int serie);
// Plusieurs courbes d'un coup : « h = plot(x, Y) » rend une colonne.
Valeur poigneeLignes(int figure, int axe, const std::vector<int>& series);
// Une couleur ecrite comme MATLAB l'accepte — 'r', 'red', '#D95319' ou
// le triplet [0.85 0.55 0] — rendue sous forme hexadecimale.
std::string couleurDepuisValeur(const Valeur& v);

// Ajoute un axe a une figure et lui donne son identifiant. Tout axe cree
// passe par la.
std::shared_ptr<Axes> ajouterAxes(Figure& f);

std::string rendreSVG(const Figure& figure);
std::shared_ptr<Figure> figureCourante(Interpreteur& it);
std::shared_ptr<Axes> axesCourants(Interpreteur& it);

}  // namespace matlibre
