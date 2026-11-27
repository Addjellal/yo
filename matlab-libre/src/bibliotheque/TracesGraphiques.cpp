// TracesGraphiques.cpp — les fonctions de tracé du langage.
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <memory>
#include <set>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Graphique.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

const char* palette(std::size_t k) {
    static const char* couleurs[] = {"#0072BD", "#D95319", "#EDB120", "#7E2F8E",
                                     "#77AC30", "#4DBEEE", "#A2142F"};
    return couleurs[k % 7];
}

std::string couleurDeLettre(char c) {
    switch (c) {
        // Les lettres de MATLAB sont des couleurs pures : 'r' vaut [1 0 0],
        // et non le rouge orangé de la palette par défaut.
        case 'r': return "#FF0000";
        case 'g': return "#00FF00";
        case 'b': return "#0000FF";
        case 'c': return "#00FFFF";
        case 'm': return "#FF00FF";
        case 'y': return "#FFFF00";
        case 'k': return "#000000";
        case 'w': return "#FFFFFF";
        default: return "";
    }
}

}  // namespace

// Une couleur écrite comme MATLAB l'accepte : la lettre 'r', le nom
// « red », le code « #D95319 », ou le triplet [0.85 0.55 0]. Rendue sous
// la forme hexadécimale, seule que garde une Serie.
std::string couleurDepuisValeur(const Valeur& v) {
    if (v.estTexte() || v.estChaine()) {
        std::string t = v.versTexte();
        if (t.empty()) return "";
        if (t[0] == '#') return t;
        std::string bas = t;
        for (auto& c : bas) c = (char)std::tolower((unsigned char)c);
        if (bas == "red") return "#FF0000";
        if (bas == "green") return "#00FF00";
        if (bas == "blue") return "#0000FF";
        if (bas == "cyan") return "#00FFFF";
        if (bas == "magenta") return "#FF00FF";
        if (bas == "yellow") return "#FFFF00";
        if (bas == "black") return "#000000";
        if (bas == "white") return "#FFFFFF";
        if (bas == "none") return "none";
        if (t.size() == 1) return couleurDeLettre(t[0]);
        return "";
    }
    if (v.classe == Classe::Cellule || v.classe == Classe::Structure ||
        v.classe == Classe::Objet || v.classe == Classe::Fonction)
        return "";
    if (v.nelem() != 3) return "";
    char tampon[8];
    int composantes[3];
    for (int k = 0; k < 3; ++k) {
        double x = v.re[(std::size_t)k];
        if (x < 0) x = 0;
        if (x > 1) x = 1;
        composantes[k] = (int)(x * 255.0 + 0.5);
    }
    std::snprintf(tampon, sizeof tampon, "#%02X%02X%02X", composantes[0], composantes[1],
                  composantes[2]);
    return tampon;
}

namespace {

// Vrai si la chaine ne porte que des caracteres de style : « r--o » oui,
// « Color » non, « LineWidth » non plus.
bool estSpecificationStyle(const std::string& spec) {
    static const char* permis = "-:.+o*xsd^v><phrgbcmykw";
    if (spec.empty() || spec.size() > 4) return false;
    for (char c : spec)
        if (std::strchr(permis, c) == nullptr) return false;
    return true;
}

// Décode une spécification « r--o » comme le fait plot.
void decoderStyle(const std::string& spec, Serie& s) {
    std::string style;
    for (std::size_t k = 0; k < spec.size(); ++k) {
        char c = spec[k];
        std::string couleur = couleurDeLettre(c);
        if (!couleur.empty()) {
            s.couleur = couleur;
            continue;
        }
        // Le point n'appartient au style que dans le tiret-point « -. » ;
        // ailleurs, « .- » compris, c'est le marqueur point, comme MATLAB.
        if (c == '.') {
            if (k > 0 && spec[k - 1] == '-' && style == "-") style += c;
            else s.marqueur = ".";
            continue;
        }
        if (c == '-' || c == ':') {
            style += c;
            continue;
        }
        if (std::strchr("o+*xsd^v><ph", c)) s.marqueur = std::string(1, c);
    }
    if (!style.empty()) s.style = style;
    else if (!s.marqueur.empty()) s.style = "none";
}

std::vector<double> valeursDe(const Valeur& v) {
    std::vector<double> x;
    for (std::size_t k = 0; k < v.nelem(); ++k) x.push_back(v.re.empty() ? 0.0 : v.re[k]);
    return x;
}

std::shared_ptr<Axes> axesDeLaPoignee(Interpreteur& it, const Valeur& p, std::size_t e = 0) {
    if (p.classe != Classe::Objet || !p.aChamp("NumeroFigure") || !p.aChamp("NumeroAxe"))
        return nullptr;
    int numero = (int)p.champ("NumeroFigure", e).scal();
    auto trouve = it.figures.find(numero);
    if (trouve == it.figures.end() || !trouve->second)
        erreur("MATLAB:class:InvalidHandle", "Invalid or deleted object.");
    int identifiant = (int)p.champ("NumeroAxe", e).scal();
    for (const auto& a : trouve->second->axes)
        if (a && a->identifiant == identifiant) return a;
    erreur("MATLAB:class:InvalidHandle", "Invalid or deleted object.");
}

bool estPoigneeAxes(const Valeur& p) {
    return p.classe == Classe::Objet && p.nomObjet == "matlab.graphics.axis.Axes";
}

bool estPoigneeFigure(const Valeur& p) {
    return p.classe == Classe::Objet && p.nomObjet == "matlab.ui.Figure";
}

std::string enMinuscules(std::string t) {
    for (auto& c : t) c = (char)std::tolower((unsigned char)c);
    return t;
}

// Le côté des ordonnées que vise un tracé : celui de la poignée qui le
// nomme (« plotyy » rend une poignée par côté), sinon le côté actif de
// « yyaxis », sinon la gauche.
int coteVise(const Axes& a, const Valeur* poignee) {
    if (poignee && poignee->aChamp("Cote")) return (int)poignee->champ("Cote", 0).scal();
    return a.deuxOrdonnees ? a.coteActif : 0;
}

int ajouterSerie(Interpreteur& it, Serie s) {
    auto a = axesCourants(it);
    if (s.couleur.empty()) s.couleur = palette(a->series.size());
    // Sous « yyaxis », la série va du côté actif, et en prend la couleur
    // tant qu'aucune ne lui a été imposée : une couleur de la palette par
    // défaut est celle que le tracé a choisie d'office.
    if (a->deuxOrdonnees) {
        s.cote = a->coteActif;
        for (std::size_t k = 0; k < 7; ++k)
            if (s.couleur == palette(k)) s.couleur = couleurCote(s.cote);
    }
    s.identifiant = ++a->prochaineSerie;
    int identifiant = s.identifiant;
    a->series.push_back(std::move(s));
    return identifiant;
}

void nouveauTrace(Interpreteur& it) {
    auto a = axesCourants(it);
    if (!a->tenir && a->deuxOrdonnees) {
        // Sous « yyaxis », un tracé ne remplace que ceux de son côté.
        std::vector<Serie> gardees;
        for (auto& s : a->series)
            if (s.cote != a->coteActif) gardees.push_back(std::move(s));
        a->series = std::move(gardees);
        return;
    }
    if (!a->tenir) {
        a->series.clear();
        a->legendeVisible = false;
        a->legende.clear();
        // Un tracé plan qui remplace un tracé de l'espace revient à la vue
        // de dessus, et sans la grille que l'espace avait posée.
        if (vueEspace(*a)) {
            a->azimut = 0;
            a->elevation = 90;
            a->grille = false;
        }
        a->limitesManuellesZ = false;
    }
}

// Un tracé de l'espace (« plot3 », « surf »…) sur un axe neuf prend la vue
// par défaut de MATLAB — azimut -37,5, élévation 30 — et sa grille, comme
// le font view(3) et grid on dans surf.m. Sous « hold on », l'axe garde
// sa vue.
void passerEnEspace(Interpreteur& it) {
    auto a = axesCourants(it);
    bool seul = true;
    for (const auto& s : a->series)
        if (!serieEspace(s)) seul = false;
    if (a->tenir && !a->series.empty() && !seul) return;
    if (a->tenir && vueEspace(*a)) return;
    a->azimut = -37.5;
    a->elevation = 30;
    a->grille = true;
    // L'axe neuf a ses sens ordinaires : une image avant lui avait pu
    // retourner les ordonnées.
    if (!a->tenir) {
        a->xInverse = false;
        a->yInverse = false;
    }
}

// La couleur de face ou de bord d'un marqueur : « none », « auto », ou une
// couleur que MATLAB accepte.
std::string couleurMarqueurDepuis(const Valeur& v) {
    if (v.estTexte() || v.estChaine()) {
        std::string t = v.versTexte();
        for (auto& c : t) c = (char)std::tolower((unsigned char)c);
        if (t == "none" || t == "auto") return t;
    }
    std::string couleur = couleurDepuisValeur(v);
    return couleur.empty() ? std::string("none") : couleur;
}

std::vector<Valeur> tracer(Interpreteur& it, std::vector<Valeur>& args, GenreTrace genre,
                           bool logX, bool logY, int nargout) {
    exigerArguments(args, 1, 0, "plot");
    nouveauTrace(it);
    auto axes = axesCourants(it);
    // Sous « hold on », un plot garde l'échelle de l'axe, comme dans
    // MATLAB : semilogy puis plot restait sinon en échelle linéaire.
    if (axes->deuxOrdonnees && axes->coteActif == 1) {
        // L'échelle logarithmique d'un tracé de droite est celle de droite.
        axes->logX = axes->logX || logX;
        axes->logYDroite = logY || (axes->tenir && axes->logYDroite);
    } else if (axes->tenir && !axes->series.empty()) {
        axes->logX = axes->logX || logX;
        axes->logY = axes->logY || logY;
    } else {
        axes->logX = logX;
        axes->logY = logY;
    }
    std::size_t k = 0;
    std::size_t indexCouleur = axes->series.size();
    // « h = plot(x,y) » rend une poignee par courbe tracee.
    std::vector<int> identifiants;
    while (k < args.size()) {
        Serie s;
        s.genre = genre;
        // La couleur est prise dans la palette au moment d'ajouter la
        // serie, non ici : la branche « une courbe par colonne » abandonne
        // ce « s », et lui reserver une couleur decalait toutes les
        // autres — « plot(x,Y) » commencait au deuxieme ton.
        s.couleur.clear();
        const Valeur& premier = args[k];
        if (premier.estTexte() || premier.estChaine()) break;
        if (k + 1 < args.size() && args[k + 1].estNumerique() && !args[k + 1].estVide()) {
            const Valeur& X = args[k];
            const Valeur& Y = args[k + 1];
            // Une matrice en second argument trace une courbe par colonne.
            if (Y.ncolonnes() > 1 && Y.nlignes() == X.nlignes() && X.ncolonnes() == 1) {
                for (int c = 0; c < Y.ncolonnes(); ++c) {
                    Serie sc;
                    sc.genre = genre;
                    sc.couleur = palette(indexCouleur++);
                    sc.x = valeursDe(X);
                    for (int i = 0; i < Y.nlignes(); ++i)
                        sc.y.push_back(Y.re[(std::size_t)i + (std::size_t)c * Y.nlignes()]);
                    identifiants.push_back(ajouterSerie(it, sc));
                }
                k += 2;
                if (k < args.size() && (args[k].estTexte() || args[k].estChaine())) ++k;
                continue;
            }
            s.x = valeursDe(X);
            s.y = valeursDe(Y);
            k += 2;
        } else {
            s.y = valeursDe(premier);
            for (std::size_t i = 0; i < s.y.size(); ++i) s.x.push_back((double)(i + 1));
            k += 1;
        }
        if (k < args.size() && (args[k].estTexte() || args[k].estChaine())) {
            std::string spec = args[k].versTexte();
            // Une specification de style n'est faite que de caracteres de
            // style : il ne suffit pas qu'elle en contienne un. « Color »
            // en porte trois — 'o', 'o', 'r' — et etait pris pour un
            // style rouge a marqueurs ronds, au lieu d'ouvrir la paire
            // « 'Color', [r g b] ».
            if (estSpecificationStyle(spec)) {
                decoderStyle(spec, s);
                ++k;
            }
        }
        // Paires nom/valeur.
        while (k + 1 < args.size() && (args[k].estTexte() || args[k].estChaine())) {
            std::string nom = args[k].versTexte();
            for (auto& c : nom) c = (char)std::tolower((unsigned char)c);
            if (nom == "linewidth") s.epaisseur = args[k + 1].scal();
            else if (nom == "color") {
                std::string couleur = couleurDepuisValeur(args[k + 1]);
                if (!couleur.empty()) s.couleur = couleur;
            } else if (nom == "displayname") {
                s.etiquette = args[k + 1].versTexte();
            } else if (nom == "linestyle") {
                s.style = args[k + 1].versTexte();
            } else if (nom == "marker") {
                s.marqueur = args[k + 1].versTexte();
            } else if (nom == "markersize") {
                s.tailleMarqueur = args[k + 1].scal();
            } else if (nom == "markerfacecolor") {
                s.couleurFaceMarqueur = couleurMarqueurDepuis(args[k + 1]);
            } else if (nom == "markeredgecolor") {
                s.couleurBordMarqueur = couleurMarqueurDepuis(args[k + 1]);
            }
            k += 2;
        }
        if (s.couleur.empty()) s.couleur = palette(indexCouleur++);
        identifiants.push_back(ajouterSerie(it, s));
    }
    if (nargout <= 0 || identifiants.empty()) return {};
    int numeroFigure = figureCourante(it)->numero;
    if (identifiants.size() == 1)
        return {poigneeLigne(numeroFigure, axes->identifiant, identifiants[0])};
    return {poigneeLignes(numeroFigure, axes->identifiant, identifiants)};
}

FONCTION(fnPlot) { INUTILISE return tracer(it, args, GenreTrace::Ligne, false, false, nargout); }
FONCTION(fnSemilogx) { INUTILISE return tracer(it, args, GenreTrace::Ligne, true, false, nargout); }
FONCTION(fnSemilogy) { INUTILISE return tracer(it, args, GenreTrace::Ligne, false, true, nargout); }
FONCTION(fnLoglog) { INUTILISE return tracer(it, args, GenreTrace::Ligne, true, true, nargout); }
// bar(y), bar(x,y), bar(...,largeur), bar(...,'grouped'|'stacked'),
// bar(...,couleur), et les paires FaceColor, EdgeColor, BarWidth,
// LineWidth, DisplayName, FaceAlpha. Une matrice Y trace une série par
// colonne : groupées côte à côte autour de chaque abscisse, ou empilées.
// Le tracé générique de plot lisait la largeur comme une série de plus —
// une barre parasite de hauteur 0,4 — et ignorait les couleurs de face.
FONCTION(fnBar) {
    INUTILISE
    exigerArguments(args, 1, 0, "bar");
    std::size_t k = 0;
    std::vector<const Valeur*> nombres;
    while (k < args.size() && args[k].estNumerique() && nombres.size() < 3)
        nombres.push_back(&args[k++]);
    if (nombres.empty())
        erreur("MATLAB:bar:InvalidData", "Input arguments must be numeric.");
    double largeur = 0.8;
    Valeur X, Y;
    bool xDonne = false;
    if (nombres.size() == 1) {
        Y = *nombres[0];
    } else if (nombres.size() == 2) {
        if (nombres[1]->estScalaire() && !nombres[0]->estScalaire()) {
            Y = *nombres[0];
            largeur = nombres[1]->scal();
        } else {
            X = *nombres[0];
            Y = *nombres[1];
            xDonne = true;
        }
    } else {
        X = *nombres[0];
        Y = *nombres[1];
        largeur = nombres[2]->scal();
        xDonne = true;
    }
    bool empile = false;
    std::string couleurFace, couleurBord = "#000000", etiquette;
    double epaisseur = 0.5, opacite = 1.0;
    while (k < args.size()) {
        if (!args[k].estTexte() && !args[k].estChaine())
            erreur("MATLAB:bar:InvalidArgument", "Argument de bar inattendu.");
        std::string nom = args[k].versTexte();
        std::string bas = nom;
        for (auto& c : bas) c = (char)std::tolower((unsigned char)c);
        if (bas == "grouped" || bas == "stacked") {
            empile = bas == "stacked";
            ++k;
            continue;
        }
        if (bas == "hist" || bas == "histc")
            erreur("MatLibre:bar:Hist",
                   "bar(...,'" + nom +
                       "') n'est pas fait : employez histogram, ou bar sans style.");
        bool paire = bas == "facecolor" || bas == "edgecolor" || bas == "barwidth" ||
                     bas == "linewidth" || bas == "displayname" || bas == "facealpha" ||
                     bas == "basevalue";
        if (!paire && estSpecificationStyle(nom)) {
            Serie temporaire;
            temporaire.couleur.clear();
            decoderStyle(nom, temporaire);
            if (!temporaire.couleur.empty()) couleurFace = temporaire.couleur;
            ++k;
            continue;
        }
        if (k + 1 >= args.size())
            erreur("MATLAB:bar:InvalidArgument", "Option " + nom + " requires a value.");
        const Valeur& valeur = args[k + 1];
        if (bas == "facecolor") {
            std::string c = couleurDepuisValeur(valeur);
            if (!c.empty() && c != "flat") couleurFace = c;
        } else if (bas == "edgecolor") {
            std::string c = couleurDepuisValeur(valeur);
            if (!c.empty()) couleurBord = c;
        } else if (bas == "barwidth") {
            largeur = valeur.scal();
        } else if (bas == "linewidth") {
            epaisseur = valeur.scal();
        } else if (bas == "displayname") {
            etiquette = valeur.versTexte();
        } else if (bas == "facealpha") {
            opacite = valeur.scal();
        } else if (bas == "basevalue") {
            if (valeur.scal() != 0)
                erreur("MatLibre:bar:BaseValue",
                       "bar : une ligne de base non nulle n'est pas faite.");
        } else {
            erreur("MATLAB:bar:InvalidArgument", "Option de bar inconnue : " + nom + ".");
        }
        k += 2;
    }
    // Les séries : une par colonne d'une matrice, une seule pour un vecteur.
    int lignes = Y.nlignes(), colonnes = Y.ncolonnes();
    bool matrice = lignes > 1 && colonnes > 1;
    if (!matrice) {
        lignes = (int)Y.nelem();
        colonnes = 1;
    }
    std::vector<double> positions;
    if (xDonne) {
        positions = valeursDe(X);
        if ((int)positions.size() != lignes)
            erreur("MATLAB:bar:XYSizeMismatch",
                   "The length of X must match the number of rows of Y.");
    } else {
        for (int i = 0; i < lignes; ++i) positions.push_back((double)(i + 1));
    }
    double ecart = 1.0;
    if (positions.size() > 1) {
        std::vector<double> tri = positions;
        std::sort(tri.begin(), tri.end());
        ecart = INFINITY;
        for (std::size_t i = 1; i < tri.size(); ++i)
            if (tri[i] > tri[i - 1]) ecart = std::min(ecart, tri[i] - tri[i - 1]);
        if (!std::isfinite(ecart)) ecart = 1.0;
    }
    nouveauTrace(it);
    auto axes = axesCourants(it);
    std::size_t indexCouleur = axes->series.size();
    std::vector<int> identifiants;
    std::vector<double> hautPositif((std::size_t)lignes, 0.0);
    std::vector<double> hautNegatif((std::size_t)lignes, 0.0);
    // Groupées : le groupe occupe min(0,8, n/(n+1,5)) de l'écart, partagé
    // entre ses n barres, comme le fait MATLAB.
    double groupe = colonnes > 1 && !empile
                        ? std::min(0.8, (double)colonnes / (colonnes + 1.5)) : 0.0;
    for (int c = 0; c < colonnes; ++c) {
        Serie s;
        s.genre = GenreTrace::Barres;
        s.couleur = couleurFace.empty() ? palette(indexCouleur++) : couleurFace;
        s.couleurBord = couleurBord;
        s.epaisseur = epaisseur;
        s.opacite = opacite;
        s.etiquette = etiquette;
        double decalage = 0.0;
        if (groupe > 0) {
            decalage = (-groupe / 2 + (c + 0.5) * groupe / colonnes) * ecart;
            s.largeurBarre = groupe / colonnes * largeur / 0.8;
        } else {
            s.largeurBarre = largeur;
        }
        for (int i = 0; i < lignes; ++i) {
            double y = matrice ? Y.re[(std::size_t)i + (std::size_t)c * Y.nlignes()]
                               : Y.re[(std::size_t)i];
            s.x.push_back(positions[(std::size_t)i] + decalage);
            // La position du groupe, sans le décalage de la barre : c'est
            // l'XData de MATLAB, et là que tombent les graduations.
            s.xVraies.push_back(positions[(std::size_t)i]);
            if (empile) {
                double& haut = y >= 0 ? hautPositif[(std::size_t)i] : hautNegatif[(std::size_t)i];
                s.basesBarres.push_back(haut);
                haut += y;
                s.y.push_back(haut);
            } else {
                s.y.push_back(y);
            }
        }
        identifiants.push_back(ajouterSerie(it, s));
    }
    if (nargout <= 0 || identifiants.empty()) return {};
    int numeroFigure = figureCourante(it)->numero;
    if (identifiants.size() == 1)
        return {poigneeLigne(numeroFigure, axes->identifiant, identifiants[0])};
    return {poigneeLignes(numeroFigure, axes->identifiant, identifiants)};
}
FONCTION(fnStairs) { INUTILISE return tracer(it, args, GenreTrace::Escalier, false, false, nargout); }
FONCTION(fnStem) { INUTILISE return tracer(it, args, GenreTrace::Tige, false, false, nargout); }
// plot3(X,Y,Z), plot3(X,Y,Z,style), plusieurs triplets, et les paires
// LineWidth, Color, DisplayName, LineStyle, Marker, MarkerSize,
// MarkerFaceColor, MarkerEdgeColor. Des matrices tracent une courbe par
// colonne, comme plot. Les coordonnées sont gardées telles quelles : le
// dessin les projette selon la vue de l'axe.
FONCTION(fnPlot3) {
    INUTILISE
    exigerArguments(args, 3, 0, "plot3");
    nouveauTrace(it);
    auto axes = axesCourants(it);
    std::size_t indexCouleur = axes->series.size();
    std::vector<int> identifiants;
    std::size_t k = 0;
    while (k + 2 < args.size() && args[k].estNumerique() && args[k + 1].estNumerique() &&
           args[k + 2].estNumerique()) {
        const Valeur& X = args[k];
        const Valeur& Y = args[k + 1];
        const Valeur& Z = args[k + 2];
        k += 3;
        Serie modele;
        modele.genre = GenreTrace::Ligne;
        modele.couleur.clear();
        if (k < args.size() && (args[k].estTexte() || args[k].estChaine()) &&
            estSpecificationStyle(args[k].versTexte())) {
            decoderStyle(args[k].versTexte(), modele);
            ++k;
        }
        while (k + 1 < args.size() && (args[k].estTexte() || args[k].estChaine())) {
            std::string nom = enMinuscules(args[k].versTexte());
            const Valeur& v = args[k + 1];
            if (nom == "linewidth") modele.epaisseur = v.scal();
            else if (nom == "color") {
                std::string couleur = couleurDepuisValeur(v);
                if (!couleur.empty()) modele.couleur = couleur;
            } else if (nom == "displayname") modele.etiquette = v.versTexte();
            else if (nom == "linestyle") modele.style = v.versTexte();
            else if (nom == "marker") modele.marqueur = v.versTexte();
            else if (nom == "markersize") modele.tailleMarqueur = v.scal();
            else if (nom == "markerfacecolor")
                modele.couleurFaceMarqueur = couleurMarqueurDepuis(v);
            else if (nom == "markeredgecolor")
                modele.couleurBordMarqueur = couleurMarqueurDepuis(v);
            k += 2;
        }
        // Une courbe par colonne quand les trois sont des matrices de même
        // forme ; sinon une seule, sur tous les éléments.
        bool colonnes = X.nlignes() > 1 && X.ncolonnes() > 1 && X.dims == Y.dims &&
                        X.dims == Z.dims;
        int nb = colonnes ? X.ncolonnes() : 1;
        std::size_t hauteur = colonnes ? (std::size_t)X.nlignes() : 0;
        for (int c = 0; c < nb; ++c) {
            Serie s = modele;
            if (colonnes) {
                for (std::size_t i = 0; i < hauteur; ++i) {
                    std::size_t rang = i + (std::size_t)c * hauteur;
                    s.x.push_back(X.re[rang]);
                    s.y.push_back(Y.re[rang]);
                    s.z.push_back(Z.re[rang]);
                }
            } else {
                s.x = valeursDe(X);
                s.y = valeursDe(Y);
                s.z = valeursDe(Z);
                if (s.x.size() != s.y.size() || s.x.size() != s.z.size())
                    erreur("MATLAB:plot3:XYZLengthMismatch",
                           "Vectors must be the same length.");
            }
            if (s.couleur.empty()) s.couleur = palette(indexCouleur++);
            identifiants.push_back(ajouterSerie(it, s));
        }
    }
    if (identifiants.empty())
        erreur("MATLAB:plot3:Arguments", "PLOT3 attend au moins X, Y et Z.");
    passerEnEspace(it);
    if (nargout <= 0) return {};
    int numeroFigure = figureCourante(it)->numero;
    if (identifiants.size() == 1)
        return {poigneeLigne(numeroFigure, axes->identifiant, identifiants[0])};
    return {poigneeLignes(numeroFigure, axes->identifiant, identifiants)};
}

FONCTION(fnHistogramme) {
    INUTILISE
    exigerArguments(args, 1, 0, "histogram");
    exigerNumerique(args[0], "histogram");
    // Les donnees, un nombre de classes ou des bords, puis des couples
    // nom-valeur. Ceux du dessin restent ici — FaceColor colore les
    // barres ; les aretes et la transparence, que ce trace n'a pas, sont
    // acceptees sans effet —, les autres vont a histcounts, qui refuse en
    // le nommant ce qu'il ne traite pas. Les trois arguments au plus d'hier
    // prenaient « histogram(x,'BinWidth',1) » pour des bords : les codes des
    // caracteres de 'BinWidth', et sept effectifs nuls.
    static const std::set<std::string> dessin = {"facecolor", "edgecolor", "facealpha",
                                                 "edgealpha", "linewidth"};
    std::vector<Valeur> a = {args[0]};
    std::string couleur;
    for (std::size_t k = 1; k < args.size(); ++k) {
        if ((args[k].estTexte() || args[k].estChaine()) && k + 1 < args.size()) {
            std::string nom = args[k].versTexte();
            for (auto& c : nom) c = (char)std::tolower((unsigned char)c);
            if (dessin.count(nom)) {
                if (nom == "facecolor") couleur = couleurDepuisValeur(args[k + 1]);
                ++k;
                continue;
            }
            a.push_back(args[k]);
            a.push_back(args[k + 1]);
            ++k;
            continue;
        }
        a.push_back(args[k]);
    }
    auto comptes = it.appeler("histcounts", a, 2);
    if (comptes.size() < 2) return {};
    std::vector<double> centres;
    const Valeur& bords = comptes[1];
    for (std::size_t k = 0; k + 1 < bords.nelem(); ++k)
        centres.push_back(0.5 * (bords.re[k] + bords.re[k + 1]));
    nouveauTrace(it);
    Serie s;
    s.genre = GenreTrace::Barres;
    s.histogramme = true;
    s.x = centres;
    s.y = valeursDe(comptes[0]);
    s.couleur = palette(axesCourants(it)->series.size());
    if (!couleur.empty() && couleur != "none") s.couleur = couleur;
    ajouterSerie(it, s);
    if (nargout > 0) return {comptes[0]};
    return {};
}

// MATLAB : « hist(x) » trace ; « [n,c] = hist(x) » rend les effectifs et
// les centres des classes, SANS tracer. C'est la forme historique,
// remplacee par histogram et histcounts, mais encore tres ecrite.
FONCTION(fnHist) {
    INUTILISE
    exigerArguments(args, 1, 3, "hist");
    if (nargout == 0) return fnHistogramme(it, args, 0);
    std::vector<Valeur> a = {args[0]};
    if (args.size() > 1) a.push_back(args[1]);
    auto comptes = it.appeler("histcounts", a, 2);
    if (comptes.size() < 2) return {};
    std::vector<double> centres;
    const Valeur& bords = comptes[1];
    for (std::size_t k = 0; k + 1 < bords.nelem(); ++k)
        centres.push_back(0.5 * (bords.re[k] + bords.re[k + 1]));
    if (nargout == 1) return {comptes[0]};
    return {comptes[0], Valeur::ligne(centres)};
}

// Les couples nom-valeur qui terminent l'appel d'une surface ou d'une
// image, retirés. Le tracé est ici une image vue de dessus : les arêtes,
// la transparence, l'éclairage n'y changent rien, si bien que ces
// propriétés sont acceptées sans effet. Un nom inconnu est refusé. Sans
// ce tri, « surf(Z,'EdgeColor','none') » prenait 'none' pour les données,
// et en dessinait les codes de caractères.
std::vector<Valeur> sansProprietes(Arguments args, const char* fonction) {
    static const std::set<std::string> connues = {
        "edgecolor", "facecolor", "facealpha", "edgealpha", "linestyle", "linewidth",
        "displayname", "alphadata", "alphadatamapping", "cdatamapping", "facelighting",
        "meshstyle", "marker", "tag", "userdata"};
    std::size_t fin = args.size();
    while (fin >= 3 && (args[fin - 2].estTexte() || args[fin - 2].estChaine())) {
        std::string nom = args[fin - 2].versTexte();
        for (auto& c : nom) c = (char)std::tolower((unsigned char)c);
        if (!connues.count(nom))
            erreur("MATLAB:hg:InvalidProperty",
                   formater("%s: unrecognized property '%s'.", fonction,
                            args[fin - 2].versTexte().c_str()));
        fin -= 2;
    }
    return std::vector<Valeur>(args.begin(), args.begin() + (long)fin);
}

// Le corps commun de « imagesc », « image », « pcolor » et « surf ».
// « sensMatrice » dit si la premiere ligne va en haut — c'est le cas
// d'une image, ce ne l'est pas d'une surface, dont les ordonnees montent.
std::vector<Valeur> traceImage(Interpreteur& it, Arguments argsBruts, int nargout,
                               bool sensMatrice, bool direct) {
    std::vector<Valeur> args(argsBruts.begin(), argsBruts.end());
    // « imagesc(C, clims) » et « imagesc(x, y, C, clims) » : les bornes de
    // couleur viennent en dernier, deux nombres.
    std::vector<double> bornesCouleur;
    if (!direct && (args.size() == 2 || args.size() == 4) && args.back().nelem() == 2 &&
        args.back().estNumerique() && args[args.size() - 2].nelem() > 2) {
        bornesCouleur = valeursDe(args.back());
        args.pop_back();
    }
    exigerArguments(args, 1, 3, "imagesc");
    const Valeur& z = args[args.size() - 1];
    if (!(z.estNumerique() || z.classe == Classe::Logique))
        erreur("MATLAB:image:InvalidCData", "Image data must be numeric or logical.");
    nouveauTrace(it);
    Serie s;
    s.genre = GenreTrace::Image;
    s.hauteurImage = z.nlignes();
    s.largeurImage = z.ncolonnes();
    s.z = valeursDe(z);
    // Un tableau m x n x 3 est une image en couleurs vraies : ses valeurs
    // sont des intensités, dans [0,1] pour un double, sur toute l'étendue
    // du type pour un entier.
    if (z.dims.size() == 3 && z.dims[2] == 3) {
        s.imageRvb = true;
        // « ncolonnes » compte les colonnes de toutes les pages : la largeur
        // de l'image est la deuxième dimension seule.
        s.largeurImage = z.dims[1];
        double echelle = 1.0;
        if (z.classe == Classe::UInt8) echelle = 255.0;
        else if (z.classe == Classe::UInt16) echelle = 65535.0;
        if (echelle != 1.0)
            for (auto& v : s.z) v /= echelle;
    } else if (z.dims.size() > 2) {
        erreur("MATLAB:image:InvalidCData",
               "Image data must be an m-by-n matrix or an m-by-n-by-3 array.");
    }
    s.imageDirecte = direct;
    s.imageEntiere = classeEntiere(z.classe);
    if (!bornesCouleur.empty()) {
        auto a = axesCourants(it);
        if (!(bornesCouleur[1] > bornesCouleur[0]))
            erreur("MATLAB:imagesc:InvalidCLim", "CLim must be increasing.");
        a->climManuelle = true;
        a->cmin = bornesCouleur[0];
        a->cmax = bornesCouleur[1];
    }
    s.x = {0.5, (double)s.largeurImage + 0.5};
    s.y = {0.5, (double)s.hauteurImage + 0.5};
    // « imagesc(x,y,Z) » : les deux premiers arguments donnent l'etendue
    // reelle, et non les indices de colonne et de ligne.
    if (args.size() >= 3 && args[0].nelem() >= 2 && args[1].nelem() >= 2) {
        exigerNumerique(args[0], "imagesc");
        exigerNumerique(args[1], "imagesc");
        const Valeur& X = args[0];
        const Valeur& Y = args[1];
        s.x = {X.re.front(), X.re.back()};
        s.y = {Y.re.front(), Y.re.back()};
    }
    // MATLAB : une image se lit comme une matrice, la premiere ligne en
    // haut. C'est l'axe qui est retourne, pas l'image.
    axesCourants(it)->yInverse = sensMatrice;
    int identifiant = ajouterSerie(it, s);
    if (nargout > 0)
        return {poigneeLigne(figureCourante(it)->numero, axesCourants(it)->identifiant,
                             identifiant)};
    return {};
}

FONCTION(fnImagesc) {
    INUTILISE
    std::vector<Valeur> donnees = sansProprietes(args, "imagesc");
    return traceImage(it, donnees, nargout, true, false);
}

// « image(C) » : comme dans MATLAB, les valeurs de C sont des rangs dans la
// palette (CDataMapping 'direct'), à partir de 1 pour un double et de 0
// pour un entier ; « 'CDataMapping','scaled' » les met à l'échelle comme
// imagesc. Un tableau m x n x 3 est en couleurs vraies.
FONCTION(fnImage) {
    INUTILISE
    bool direct = true;
    std::vector<Valeur> restants;
    for (std::size_t k = 0; k < args.size(); ++k) {
        if ((args[k].estTexte() || args[k].estChaine()) && k + 1 < args.size()) {
            std::string nom = args[k].versTexte();
            for (auto& c : nom) c = (char)std::tolower((unsigned char)c);
            if (nom == "cdatamapping") {
                std::string mode = args[k + 1].versTexte();
                for (auto& c : mode) c = (char)std::tolower((unsigned char)c);
                direct = mode != "scaled";
                ++k;
                continue;
            }
            if (nom == "cdata" || nom == "xdata" || nom == "ydata") {
                restants.push_back(args[k + 1]);
                ++k;
                continue;
            }
        }
        restants.push_back(args[k]);
    }
    std::vector<Valeur> donnees = sansProprietes(restants, "image");
    return traceImage(it, donnees, nargout, true, direct);
}

// « pcolor » suit les ordonnees croissantes vers le haut, comme une
// surface vue de dessus, et non comme une image.
FONCTION(fnPcolor) {
    INUTILISE
    std::vector<Valeur> donnees = sansProprietes(args, "pcolor");
    return traceImage(it, donnees, nargout, false, false);
}

// surf(Z), surf(Z,C), surf(X,Y,Z), surf(X,Y,Z,C), surf(ax,...) et les
// paires FaceColor, EdgeColor, FaceAlpha, LineStyle, LineWidth,
// DisplayName ; mesh de même. X et Y sont des vecteurs (colonnes et
// lignes de la grille) ou des matrices de la forme de Z ; C donne la
// couleur de chaque sommet, Z par défaut. surf remplit les mailles de la
// couleur de leur premier sommet, bordées de noir ; mesh les laisse
// blanches et colore les arêtes.
std::vector<Valeur> surface(Interpreteur& it, Arguments args, int nargout, bool maillage) {
    const char* nom = maillage ? "mesh" : "surf";
    std::size_t k = 0;
    std::shared_ptr<Axes> cible;
    if (!args.empty() && estPoigneeAxes(args[0])) {
        cible = axesDeLaPoignee(it, args[0]);
        k = 1;
    }
    std::vector<const Valeur*> nombres;
    while (k < args.size() && nombres.size() < 4 && !args[k].estTexte() && !args[k].estChaine())
        nombres.push_back(&args[k++]);
    if (nombres.empty()) erreur("MATLAB:narginchk:notEnoughInputs", "Not enough input arguments.");
    for (const Valeur* v : nombres) exigerNumerique(*v, nom);
    const Valeur* Z = nullptr;
    const Valeur* X = nullptr;
    const Valeur* Y = nullptr;
    const Valeur* C = nullptr;
    if (nombres.size() <= 2) {
        Z = nombres[0];
        if (nombres.size() == 2) C = nombres[1];
    } else {
        X = nombres[0];
        Y = nombres[1];
        Z = nombres[2];
        if (nombres.size() == 4) C = nombres[3];
    }
    const int m = Z->nlignes(), n = Z->ncolonnes();
    if (m < 2 || n < 2)
        erreur("MATLAB:" + std::string(nom) + ":NonMatrixData",
               "Z must be a matrix, not a scalar or vector.");
    Serie s;
    s.genre = GenreTrace::Surface;
    s.lignesGrille = m;
    s.colonnesGrille = n;
    s.epaisseur = 0.5;
    s.couleur = "#000000";
    s.modeFaces = maillage ? "#FFFFFF" : "flat";
    s.modeAretes = maillage ? "flat" : "#000000";
    const std::size_t total = (std::size_t)m * (std::size_t)n;
    s.x.resize(total);
    s.y.resize(total);
    s.z.assign(Z->re.begin(), Z->re.begin() + (std::ptrdiff_t)total);
    auto coordonnee = [&](const Valeur* V, bool enX, std::vector<double>& sortie) {
        if (!V) {
            for (int j = 0; j < n; ++j)
                for (int i = 0; i < m; ++i)
                    sortie[(std::size_t)i + (std::size_t)j * (std::size_t)m] = enX ? j + 1 : i + 1;
            return;
        }
        if (V->nlignes() == m && V->ncolonnes() == n) {
            sortie.assign(V->re.begin(), V->re.begin() + (std::ptrdiff_t)total);
            return;
        }
        std::size_t attendu = enX ? (std::size_t)n : (std::size_t)m;
        if (V->nelem() != attendu)
            erreur("MATLAB:" + std::string(nom) + ":InvalidDimensions",
                   std::string("Data dimensions must agree: the length of ") +
                       (enX ? "X" : "Y") + " must match the number of " +
                       (enX ? "columns of Z." : "rows of Z."));
        for (int j = 0; j < n; ++j)
            for (int i = 0; i < m; ++i)
                sortie[(std::size_t)i + (std::size_t)j * (std::size_t)m] =
                    V->re[enX ? (std::size_t)j : (std::size_t)i];
    };
    coordonnee(X, true, s.x);
    coordonnee(Y, false, s.y);
    if (C) {
        if (C->nlignes() != m || C->ncolonnes() != n)
            erreur("MATLAB:" + std::string(nom) + ":InvalidCData",
                   "C must be the same size as Z.");
        s.valeursCouleurPoints.assign(C->re.begin(), C->re.begin() + (std::ptrdiff_t)total);
    } else {
        s.valeursCouleurPoints = s.z;
    }
    while (k < args.size()) {
        if (!args[k].estTexte() && !args[k].estChaine())
            erreur("MATLAB:" + std::string(nom) + ":InvalidArgument",
                   std::string("Argument de ") + nom + " inattendu.");
        std::string propriete = enMinuscules(args[k].versTexte());
        if (k + 1 >= args.size())
            erreur("MATLAB:" + std::string(nom) + ":InvalidArgument",
                   "Option " + args[k].versTexte() + " requires a value.");
        const Valeur& v = args[k + 1];
        auto mode = [&](const Valeur& valeur) {
            if (valeur.estTexte() || valeur.estChaine()) {
                std::string t = enMinuscules(valeur.versTexte());
                if (t == "flat" || t == "interp" || t == "none") return t;
                if (t == "texturemap") return std::string("interp");
            }
            std::string couleur = couleurDepuisValeur(valeur);
            if (couleur.empty())
                erreur("MATLAB:" + std::string(nom) + ":InvalidColor",
                       "Couleur inconnue : " + valeur.versTexte() + ".");
            return couleur;
        };
        if (propriete == "facecolor") s.modeFaces = mode(v);
        else if (propriete == "edgecolor") s.modeAretes = mode(v);
        else if (propriete == "facealpha") s.opacite = v.scal();
        else if (propriete == "linestyle") s.style = v.versTexte();
        else if (propriete == "linewidth") s.epaisseur = v.scal();
        else if (propriete == "displayname") s.etiquette = v.versTexte();
        else if (propriete == "edgealpha" || propriete == "facelighting" ||
                 propriete == "edgelighting" || propriete == "ambientstrength" ||
                 propriete == "diffusestrength" || propriete == "specularstrength" ||
                 propriete == "meshstyle" || propriete == "cdatamapping") {
            // L'éclairage n'est pas rendu : accepté sans effet.
        } else {
            erreur("MATLAB:hg:InvalidProperty",
                   "Unrecognized property '" + args[k].versTexte() + "' for class 'Surface'.");
        }
        k += 2;
    }
    if (cible) {
        auto f = figureCourante(it);
        for (std::size_t i = 0; i < f->axes.size(); ++i)
            if (f->axes[i] == cible) f->axeCourant = (int)i;
    }
    nouveauTrace(it);
    auto axes = axesCourants(it);
    int identifiant = ajouterSerie(it, s);
    passerEnEspace(it);
    if (nargout <= 0) return {};
    return {poigneeLigne(figureCourante(it)->numero, axes->identifiant, identifiant)};
}

FONCTION(fnSurf) { return surface(it, args, nargout, false); }
FONCTION(fnMesh) { return surface(it, args, nargout, true); }

// ---------------------------------------------------------- contours
//
// Marching squares : dans chaque maille, la ligne de niveau coupe les
// aretes ou Z passe de part et d'autre du niveau. On interpole
// lineairement le point de coupe, on relie les deux points de la maille,
// puis on chaine les segments bout a bout pour en faire des polylignes —
// c'est ce chainage qui permet un trait pointille continu et une
// etiquette posee au milieu d'une courbe.

struct Segment {
    double x1, y1, x2, y2;
};

// Le point ou le niveau coupe l'arete entre (xa,za) et (xb,zb).
double interpoler(double a, double b, double za, double zb, double niveau) {
    double d = zb - za;
    if (d == 0) return a;
    double t = (niveau - za) / d;
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    return a + t * (b - a);
}

std::vector<Segment> segmentsNiveau(const std::vector<double>& x,
                                    const std::vector<double>& y, const Valeur& Z,
                                    double niveau) {
    std::vector<Segment> segments;
    int lignes = Z.nlignes(), colonnes = Z.ncolonnes();
    auto valeur = [&](int i, int j) {
        return Z.re[(std::size_t)i + (std::size_t)j * lignes];
    };
    for (int i = 0; i + 1 < lignes; ++i) {
        for (int j = 0; j + 1 < colonnes; ++j) {
            double z00 = valeur(i, j), z10 = valeur(i + 1, j);
            double z01 = valeur(i, j + 1), z11 = valeur(i + 1, j + 1);
            if (std::isnan(z00) || std::isnan(z10) || std::isnan(z01) || std::isnan(z11))
                continue;
            double x0 = x[(std::size_t)j], x1 = x[(std::size_t)j + 1];
            double y0 = y[(std::size_t)i], y1 = y[(std::size_t)i + 1];
            // Le code de la maille : un bit par sommet au-dessus du niveau.
            int code = (z00 >= niveau ? 1 : 0) | (z01 >= niveau ? 2 : 0) |
                       (z11 >= niveau ? 4 : 0) | (z10 >= niveau ? 8 : 0);
            if (code == 0 || code == 15) continue;
            // Les quatre points de coupe possibles, un par arete.
            double hautX = interpoler(x0, x1, z00, z01, niveau), hautY = y0;
            double droiteX = x1, droiteY = interpoler(y0, y1, z01, z11, niveau);
            double basX = interpoler(x0, x1, z10, z11, niveau), basY = y1;
            double gaucheX = x0, gaucheY = interpoler(y0, y1, z00, z10, niveau);
            // Un sommet pose exactement sur le niveau fait coincider les
            // deux points de coupe : le segment est de longueur nulle et
            // n'appartient a aucune courbe. On l'ecarte, faute de quoi il
            // ressort comme une courbe a deux points confondus.
            double maille = std::max(std::fabs(x1 - x0), std::fabs(y1 - y0));
            double minuscule = 1e-12 * std::max(maille, 1.0);
            auto ajouter = [&](double ax, double ay, double bx, double by) {
                if (std::fabs(ax - bx) <= minuscule && std::fabs(ay - by) <= minuscule)
                    return;
                segments.push_back({ax, ay, bx, by});
            };
            switch (code) {
                case 1: case 14: ajouter(gaucheX, gaucheY, hautX, hautY); break;
                case 2: case 13: ajouter(hautX, hautY, droiteX, droiteY); break;
                case 3: case 12: ajouter(gaucheX, gaucheY, droiteX, droiteY); break;
                case 4: case 11: ajouter(droiteX, droiteY, basX, basY); break;
                case 6: case 9: ajouter(hautX, hautY, basX, basY); break;
                case 8: case 7: ajouter(gaucheX, gaucheY, basX, basY); break;
                case 5:
                    // Point-selle : on tranche par la moyenne de la maille.
                    if ((z00 + z01 + z11 + z10) / 4 >= niveau) {
                        ajouter(gaucheX, gaucheY, hautX, hautY);
                        ajouter(droiteX, droiteY, basX, basY);
                    } else {
                        ajouter(gaucheX, gaucheY, basX, basY);
                        ajouter(hautX, hautY, droiteX, droiteY);
                    }
                    break;
                case 10:
                    if ((z00 + z01 + z11 + z10) / 4 >= niveau) {
                        ajouter(hautX, hautY, gaucheX, gaucheY);
                        ajouter(basX, basY, droiteX, droiteY);
                    } else {
                        ajouter(hautX, hautY, droiteX, droiteY);
                        ajouter(gaucheX, gaucheY, basX, basY);
                    }
                    break;
                default: break;
            }
        }
    }
    return segments;
}

// Les segments chaines bout a bout : chaque polyligne suit la ligne de
// niveau aussi loin qu'elle va.
std::vector<std::pair<std::vector<double>, std::vector<double>>> chainer(
    std::vector<Segment> segments, double tolerance) {
    std::vector<std::pair<std::vector<double>, std::vector<double>>> courbes;
    std::vector<bool> pris(segments.size(), false);
    auto proche = [tolerance](double ax, double ay, double bx, double by) {
        return std::fabs(ax - bx) <= tolerance && std::fabs(ay - by) <= tolerance;
    };
    for (std::size_t depart = 0; depart < segments.size(); ++depart) {
        if (pris[depart]) continue;
        pris[depart] = true;
        std::vector<double> px = {segments[depart].x1, segments[depart].x2};
        std::vector<double> py = {segments[depart].y1, segments[depart].y2};
        bool avance = true;
        while (avance) {
            avance = false;
            for (std::size_t k = 0; k < segments.size(); ++k) {
                if (pris[k]) continue;
                const Segment& t = segments[k];
                if (proche(px.back(), py.back(), t.x1, t.y1)) {
                    px.push_back(t.x2); py.push_back(t.y2);
                } else if (proche(px.back(), py.back(), t.x2, t.y2)) {
                    px.push_back(t.x1); py.push_back(t.y1);
                } else if (proche(px.front(), py.front(), t.x1, t.y1)) {
                    px.insert(px.begin(), t.x2); py.insert(py.begin(), t.y2);
                } else if (proche(px.front(), py.front(), t.x2, t.y2)) {
                    px.insert(px.begin(), t.x1); py.insert(py.begin(), t.y1);
                } else {
                    continue;
                }
                pris[k] = true;
                avance = true;
            }
        }
        if (px.size() >= 2) courbes.push_back({px, py});
    }
    return courbes;
}

// Les niveaux choisis d'office : MATLAB en prend une dizaine, arrondis.
std::vector<double> niveauxAutomatiques(const Valeur& Z, int combien) {
    double bas = INFINITY, haut = -INFINITY;
    for (double v : Z.re) {
        if (!std::isfinite(v)) continue;
        bas = std::min(bas, v);
        haut = std::max(haut, v);
    }
    if (!std::isfinite(bas) || haut <= bas) return {};
    std::vector<double> niveaux;
    for (int k = 1; k <= combien; ++k)
        niveaux.push_back(bas + (haut - bas) * k / (combien + 1.0));
    return niveaux;
}

// Les arguments communs a contour, contourf, contour3 et contourc.
void lireArgumentsContour(Interpreteur& it, std::vector<Valeur>& args, const char* nom,
                          std::vector<double>& x, std::vector<double>& y, Valeur& Z,
                          std::vector<double>& niveaux, std::string& style) {
    (void)it;
    exigerArguments(args, 1, 0, nom);
    std::size_t k = 0;
    // Style de trait eventuel, en dernier.
    std::size_t fin = args.size();
    while (fin > 0 && (args[fin - 1].estTexte() || args[fin - 1].estChaine())) {
        style = args[fin - 1].versTexte();
        --fin;
    }
    if (fin >= 3 && !args[2].estVide() && args[2].nlignes() > 1) {
        exigerNumerique(args[0], nom);
        exigerNumerique(args[1], nom);
        exigerNumerique(args[2], nom);
        // contour(X,Y,Z) : X et Y sont des vecteurs ou des grilles.
        Z = versDouble(args[2]);
        const Valeur& X = args[0];
        const Valeur& Y = args[1];
        if (X.nlignes() > 1 && X.ncolonnes() > 1)
            for (int j = 0; j < X.ncolonnes(); ++j)
                x.push_back(X.re[(std::size_t)j * X.nlignes()]);
        else
            for (double v : X.re) x.push_back(v);
        if (Y.nlignes() > 1 && Y.ncolonnes() > 1)
            for (int i = 0; i < Y.nlignes(); ++i) y.push_back(Y.re[(std::size_t)i]);
        else
            for (double v : Y.re) y.push_back(v);
        k = 3;
    } else {
        exigerNumerique(args[0], nom);
        Z = versDouble(args[0]);
        for (int j = 0; j < Z.ncolonnes(); ++j) x.push_back(j + 1);
        for (int i = 0; i < Z.nlignes(); ++i) y.push_back(i + 1);
        k = 1;
    }
    if ((int)x.size() != Z.ncolonnes() || (int)y.size() != Z.nlignes())
        erreur("MATLAB:contour:SizeMismatch",
               "X and Y must match the size of Z.");
    // MATLAB veut au moins deux lignes et deux colonnes : une maille ne
    // se decoupe pas autrement. Sans ce controle, « contourf([]) »
    // lisait le premier element d'un vecteur vide et tombait.
    if (Z.nlignes() < 2 || Z.ncolonnes() < 2)
        erreur("MATLAB:contour:ZMustBeAtLeast2x2",
               "Z must be at least a 2x2 matrix.");
    if (k < fin && args[k].estNumerique() && !args[k].estVide()) {
        if (args[k].nelem() == 1) {
            int combien = (int)args[k].scal();
            if (combien < 1) combien = 1;
            niveaux = niveauxAutomatiques(Z, combien);
        } else {
            for (double v : args[k].re) niveaux.push_back(v);
        }
    }
    if (niveaux.empty()) niveaux = niveauxAutomatiques(Z, 9);
    std::sort(niveaux.begin(), niveaux.end());
}

// La matrice de contours de MATLAB : pour chaque courbe, une colonne
// [niveau ; nombre de points] puis les points, en x sur la premiere
// ligne et en y sur la seconde.
Valeur matriceContours(
    const std::vector<std::pair<double,
                                std::pair<std::vector<double>, std::vector<double>>>>& courbes) {
    std::vector<double> ligne1, ligne2;
    for (const auto& c : courbes) {
        ligne1.push_back(c.first);
        ligne2.push_back((double)c.second.first.size());
        for (std::size_t k = 0; k < c.second.first.size(); ++k) {
            ligne1.push_back(c.second.first[k]);
            ligne2.push_back(c.second.second[k]);
        }
    }
    Valeur r = Valeur::matrice(2, (int)ligne1.size());
    for (std::size_t k = 0; k < ligne1.size(); ++k) {
        r.re[(std::size_t)0 + k * 2] = ligne1[k];
        r.re[(std::size_t)1 + k * 2] = ligne2[k];
    }
    return r;
}

std::vector<Valeur> tracerContours(Interpreteur& it, std::vector<Valeur>& args,
                                   const char* nom, bool remplir, int nargout) {
    std::vector<double> x, y, niveaux;
    Valeur Z;
    std::string style;
    lireArgumentsContour(it, args, nom, x, y, Z, niveaux, style);
    const bool espace = std::string(nom) == "contour3";
    nouveauTrace(it);
    auto axes = axesCourants(it);
    if (remplir) {
        // Le fond colore, puis les traits par-dessus : c'est ce que
        // contourf montre. MatLibre ne decoupe pas de polygones par
        // bande — le rendu est le meme a l'oeil, et rien n'est faux.
        Serie fond;
        fond.genre = GenreTrace::Image;
        fond.hauteurImage = Z.nlignes();
        fond.largeurImage = Z.ncolonnes();
        fond.z = valeursDe(Z);
        fond.x = {x.front(), x.back()};
        fond.y = {y.front(), y.back()};
        ajouterSerie(it, fond);
    }
    // La tolerance de chainage : bien plus petite qu'une maille.
    double pasX = x.size() > 1 ? std::fabs(x[1] - x[0]) : 1.0;
    double pasY = y.size() > 1 ? std::fabs(y[1] - y[0]) : 1.0;
    double tolerance = 1e-9 * std::max(1.0, std::max(pasX, pasY));

    std::vector<std::pair<double, std::pair<std::vector<double>, std::vector<double>>>>
        courbes;
    // Comme dans MATLAB, un appel à « contour » fait un seul objet : la
    // légende n'en montre que la première ligne, et chaque niveau prend sa
    // couleur dans la palette, par CLim — l'étendue de Z. Un style qui
    // nomme une couleur (« 'k' ») l'impose à tous les niveaux ; contourf
    // trace ses lignes en noir sur le fond coloré.
    double zBas = INFINITY, zHaut = -INFINITY;
    for (double v : Z.re)
        if (std::isfinite(v)) {
            zBas = std::min(zBas, v);
            zHaut = std::max(zHaut, v);
        }
    bool couleurImposee = remplir;
    for (char c : style)
        if (!couleurDeLettre(c).empty()) couleurImposee = true;
    std::vector<int> identifiants;
    bool premiere = true;
    for (double niveau : niveaux) {
        auto segments = segmentsNiveau(x, y, Z, niveau);
        if (segments.empty()) continue;
        auto polylignes = chainer(segments, tolerance);
        for (const auto& courbe : polylignes) {
            Serie s;
            s.genre = GenreTrace::Ligne;
            s.x = courbe.first;
            s.y = courbe.second;
            // contour3 pose chaque ligne à la hauteur de son niveau.
            if (espace) s.z.assign(s.x.size(), niveau);
            s.couleur = "#000000";
            if (!style.empty()) decoderStyle(style, s);
            if (!couleurImposee) {
                s.couleurIndexee = true;
                s.valeurCouleur = niveau;
                if (premiere) {
                    s.cBas = zBas;
                    s.cHaut = zHaut;
                }
            }
            s.horsLegende = !premiere;
            premiere = false;
            identifiants.push_back(ajouterSerie(it, s));
            courbes.push_back({niveau, courbe});
        }
    }
    if (espace) passerEnEspace(it);
    if (nargout <= 0) return {};
    Valeur C = matriceContours(courbes);
    if (nargout == 1) return {C};
    if (identifiants.empty()) return {C, Valeur::vide()};
    if (identifiants.size() == 1)
        return {C, poigneeLigne(figureCourante(it)->numero, axes->identifiant,
                                identifiants[0])};
    return {C, poigneeLignes(figureCourante(it)->numero, axes->identifiant, identifiants)};
}

FONCTION(fnContour) {
    INUTILISE
    return tracerContours(it, args, "contour", false, nargout);
}

FONCTION(fnContourf) {
    INUTILISE
    return tracerContours(it, args, "contourf", true, nargout);
}

// « contour3 » dessine les memes lignes, chacune a la hauteur de son
// niveau, en perspective.
FONCTION(fnContour3) {
    INUTILISE
    return tracerContours(it, args, "contour3", false, nargout);
}

// « contourc » calcule sans tracer : il rend la seule matrice C.
FONCTION(fnContourc) {
    INUTILISE
    std::vector<double> x, y, niveaux;
    Valeur Z;
    std::string style;
    lireArgumentsContour(it, args, "contourc", x, y, Z, niveaux, style);
    double pasX = x.size() > 1 ? std::fabs(x[1] - x[0]) : 1.0;
    double pasY = y.size() > 1 ? std::fabs(y[1] - y[0]) : 1.0;
    double tolerance = 1e-9 * std::max(1.0, std::max(pasX, pasY));
    std::vector<std::pair<double, std::pair<std::vector<double>, std::vector<double>>>>
        courbes;
    for (double niveau : niveaux) {
        auto segments = segmentsNiveau(x, y, Z, niveau);
        if (segments.empty()) continue;
        for (const auto& courbe : chainer(segments, tolerance))
            courbes.push_back({niveau, courbe});
    }
    return {matriceContours(courbes)};
}

FONCTION(fnFigure) {
    INUTILISE
    int numero = 0;
    std::size_t premierCouple = 0;
    if (!args.empty() && args[0].estNumerique() && !args[0].estVide()) {
        numero = (int)args[0].scal();
        premierCouple = 1;
    }
    if (numero == 0) {
        numero = 1;
        while (it.figures.count(numero)) ++numero;
    }
    if (!it.figures.count(numero)) {
        auto f = std::make_shared<Figure>();
        f->numero = numero;
        ajouterAxes(*f);
        it.figures[numero] = f;
    }
    it.figureCourante = numero;
    // Les couples nom-valeur etaient lus puis jetes : « figure('Position',
    // [0 0 1200 400]) » rendait une toile de huit cents pixels sur six
    // cents, sans rien dire. Ils sont desormais appliques, et un nom que
    // la figure ne porte pas est refuse plutot qu'ignore.
    auto& fig = *it.figures[numero];
    for (std::size_t k = premierCouple; k < args.size(); k += 2) {
        // un nom en chaîne vaut un nom en char : c'est ainsi qu'arrive
        // « figure(Position=[...]) »
        if (!args[k].estTexte() && !args[k].estChaine())
            erreur("MATLAB:hg:InvalidProperty",
                   "Invalid parameter/value pair arguments.");
        std::string nom = args[k].versTexte();
        for (auto& c : nom) c = (char)std::tolower((unsigned char)c);
        if (k + 1 >= args.size())
            erreur("MATLAB:hg:PairedArgs",
                   "Value missing for property '" + nom + "'.");
        const Valeur& v = args[k + 1];
        if (nom == "position" || nom == "outerposition") {
            if (v.re.size() != 4)
                erreur("MATLAB:hg:shaped_arrays", "Position must have four elements.");
            double largeur = v.re[2], hauteur = v.re[3];
            if (!(largeur > 0) || !(hauteur > 0))
                erreur("MATLAB:hg:shaped_arrays",
                       "Position must have positive width and height.");
            fig.largeur = (int)largeur;
            fig.hauteur = (int)hauteur;
        } else if (nom == "name") {
            fig.nom = v.versTexte();
        } else if (nom == "units") {
            std::string unite = v.versTexte();
            for (auto& c : unite) c = (char)std::tolower((unsigned char)c);
            if (unite != "pixels")
                erreur("MATLAB:hg:InvalidProperty",
                       "MatLibre measures figures in pixels only: unit '" +
                           v.versTexte() + "' would have no effect.");
        } else if (nom == "numbertitle" || nom == "visible" || nom == "menubar" ||
                   nom == "toolbar") {
            // Rien a faire : il n'y a ni fenetre, ni menu, ni barre. Les
            // accepter en silence ne ment pas, puisque le resultat est le
            // meme, et laisse tourner les programmes ecrits pour MATLAB.
        } else {
            erreur("MATLAB:hg:InvalidProperty",
                   "Unrecognized property '" + args[k].versTexte() +
                       "' for class 'Figure'.");
        }
    }
    if (nargout > 0) return {Valeur::scalaire(numero)};
    return {};
}

FONCTION(fnClf) {
    INUTILISE
    auto f = figureCourante(it);
    f->axes.clear();
    ajouterAxes(*f);
    f->axeCourant = 0;
    f->lignes = 1;
    f->colonnes = 1;
    return {};
}

int numeroDeFigure(const Valeur& v);

// La liste des figures ouvertes. ISHANDLE en a besoin pour dire si un
// numero designe encore quelque chose, et rien d'autre ne l'expose.
FONCTION(fnFiguresOuvertes) {
    INUTILISE
    std::vector<double> numeros;
    for (const auto& f : it.figures)
        if (f.second) numeros.push_back((double)f.first);
    return {Valeur::ligne(numeros)};
}

FONCTION(fnClose) {
    INUTILISE
    if (args.empty()) {
        it.figures.erase(it.figureCourante);
        it.figureCourante = it.figures.empty() ? 0 : it.figures.begin()->first;
        return {};
    }
    if ((args[0].estTexte() || args[0].estChaine()) && args[0].versTexte() == "all") {
        it.figures.clear();
        it.figureCourante = 0;
        return {};
    }
    it.figures.erase(numeroDeFigure(args[0]));
    if (!it.figures.count(it.figureCourante))
        it.figureCourante = it.figures.empty() ? 0 : it.figures.begin()->first;
    return {};
}

// « close(gcf) » est l'ecriture la plus courante, et GCF rend une poignee,
// non un numero. Lire le numero dans la poignee evite d'avoir a ecrire
// « close(get(gcf,'Number')) », que personne n'ecrit.
int numeroDeFigure(const Valeur& v) {
    if (v.classe == Classe::Objet && v.aChamp("NumeroFigure"))
        return (int)v.champ("NumeroFigure", 0).scal();
    return (int)v.scal();
}

FONCTION(fnSubplot) {
    exigerArguments(args, 1, 4, "subplot");
    int lignes, colonnes;
    std::vector<int> cases;
    if (args.size() >= 3) {
        lignes = (int)args[0].scal();
        colonnes = (int)args[1].scal();
        for (double v : args[2].re) cases.push_back((int)v);
    } else {
        int code = (int)args[0].scal();
        lignes = code / 100;
        colonnes = (code / 10) % 10;
        cases.push_back(code % 10);
    }
    if (lignes < 1 || colonnes < 1)
        erreur("MATLAB:subplot:InvalidGridSpec",
               "The number of rows and columns must be positive integers.");
    if (cases.empty()) erreur("MATLAB:minrhs", "Not enough input arguments.");
    std::sort(cases.begin(), cases.end());
    if (cases.front() < 1 || cases.back() > lignes * colonnes)
        erreur("MATLAB:subplot:SubplotIndexTooLarge",
               "Index exceeds number of subplots.");

    auto f = figureCourante(it);
    f->lignes = lignes;
    f->colonnes = colonnes;
    // Une case deja ouverte au meme endroit du meme decoupage est reprise :
    // « subplot(2,2,1) » deux fois de suite revient au meme axe. Le
    // decoupage compte : « subplot(2,1,1) » ne doit pas atterrir dans la
    // premiere case d'un decoupage en quatre.
    for (std::size_t k = 0; k < f->axes.size(); ++k) {
        const Axes& a = *f->axes[k];
        if (!a.positionManuelle && a.rangee == lignes && a.colonne == colonnes &&
            a.position == cases.front() &&
            (a.positionFin == 0 ? cases.front() : a.positionFin) == cases.back()) {
            f->axeCourant = (int)k;
            return nargout > 0 ? std::vector<Valeur>{poigneeAxesCourants(it)}
                               : std::vector<Valeur>{};
        }
    }

    auto a = std::make_shared<Axes>();
    a->identifiant = f->prochainIdentifiant++;
    a->rangee = lignes;
    a->colonne = colonnes;
    a->position = cases.front();
    a->positionFin = cases.back();
    // MATLAB efface les axes que la nouvelle case recouvre : c'est ainsi
    // qu'un decoupage en deux remplace celui en quatre qu'il chevauche.
    auto fin = std::remove_if(f->axes.begin(), f->axes.end(),
                              [&](const std::shared_ptr<Axes>& autre) {
                                  return autre && axesSeRecouvrent(*autre, *a);
                              });
    f->axes.erase(fin, f->axes.end());
    f->axes.push_back(a);
    f->axeCourant = (int)f->axes.size() - 1;
    return nargout > 0 ? std::vector<Valeur>{poigneeAxesCourants(it)}
                       : std::vector<Valeur>{};
}

// « axes » : creer un axe, ou en designer un.
//
//   axes                         un axe neuf, occupant toute la figure
//   axes('Position',[g b l h])   un axe a l'endroit qu'on veut
//   axes(h)                      rend courant l'axe de la poignee h
//
// La position est celle de MATLAB : gauche, bas, largeur, hauteur, en
// fractions de la figure, l'origine en bas a gauche.
FONCTION(fnAxes) {
    if (!args.empty() && args[0].classe == Classe::Objet) {
        const Valeur& p = args[0];
        int numero = (int)p.champ("NumeroFigure", 0).scal();
        int identifiant = (int)p.champ("NumeroAxe", 0).scal();
        auto trouve = it.figures.find(numero);
        if (trouve == it.figures.end() || !trouve->second)
            erreur("MATLAB:class:InvalidHandle", "Invalid or deleted object.");
        auto& liste = trouve->second->axes;
        for (std::size_t k = 0; k < liste.size(); ++k)
            if (liste[k] && liste[k]->identifiant == identifiant) {
                it.figureCourante = numero;
                trouve->second->axeCourant = (int)k;
                return nargout > 0 ? std::vector<Valeur>{poigneeAxesCourants(it)}
                                   : std::vector<Valeur>{};
            }
        erreur("MATLAB:class:InvalidHandle", "Invalid or deleted object.");
    }
    auto f = figureCourante(it);
    auto a = std::make_shared<Axes>();
    a->identifiant = f->prochainIdentifiant++;
    for (std::size_t k = 0; k + 1 < args.size(); k += 2) {
        std::string nom = args[k].versTexte();
        for (auto& c : nom) c = (char)std::tolower((unsigned char)c);
        if (nom == "position" || nom == "outerposition") {
            const Valeur& r = args[k + 1];
            if (r.re.size() != 4)
                erreur("MATLAB:hg:shaped_arrays", "Position must have four elements.");
            a->positionManuelle = true;
            a->posGauche = r.re[0];
            a->posBas = r.re[1];
            a->posLargeur = r.re[2];
            a->posHauteur = r.re[3];
        }
    }
    auto fin = std::remove_if(f->axes.begin(), f->axes.end(),
                              [&](const std::shared_ptr<Axes>& autre) {
                                  return autre && axesSeRecouvrent(*autre, *a);
                              });
    f->axes.erase(fin, f->axes.end());
    f->axes.push_back(a);
    f->axeCourant = (int)f->axes.size() - 1;
    return nargout > 0 ? std::vector<Valeur>{poigneeAxesCourants(it)}
                       : std::vector<Valeur>{};
}

// Un interprète de texte : 'tex', 'latex' ou 'none', comme MATLAB.
std::string interpreteDepuis(const Valeur& v) {
    std::string mode = enMinuscules(v.versTexte());
    if (mode != "tex" && mode != "latex" && mode != "none")
        erreur("MATLAB:hg:InvalidInterpreter",
               "Interpreter must be 'tex', 'latex', or 'none'.");
    return mode;
}

// Le texte d'un titre ou d'une étiquette : une cellule donne une ligne par
// élément dans MATLAB ; MatLibre, qui écrit sur une seule ligne, les met
// bout à bout.
std::string texteDe(const Valeur& v) {
    if (v.classe == Classe::Cellule) {
        std::string t;
        for (const auto& c : v.cellules) t += (t.empty() ? "" : " ") + c.versTexte();
        return t;
    }
    if (v.estChaine() && v.nelem() > 1) {
        std::string t;
        for (const auto& c : v.chaines) t += (t.empty() ? "" : " ") + c;
        return t;
    }
    return v.versTexte();
}

// title, xlabel, ylabel, zlabel : TITLE(TEXTE), TITLE(AX,TEXTE), et les
// paires Interpreter et FontSize ; les autres (Color, FontWeight…) sont
// acceptées sans effet. Rend la poignée du texte : « z = title(...) ;
// set(z,...) ».
std::vector<Valeur> texteAxe(Interpreteur& it, Arguments args, int nargout,
                             const std::string& cible) {
    auto a = axesCourants(it);
    std::size_t k = 0;
    if (!args.empty() && estPoigneeAxes(args[0])) {
        a = axesDeLaPoignee(it, args[0]);
        k = 1;
    }
    std::string texte = k < args.size() ? texteDe(args[k++]) : std::string();
    const bool droite = cible == "ylabel" && coteVise(*a, k == 1 ? &args[0] : nullptr) == 1;
    if (cible == "title") a->titre = texte;
    else if (cible == "xlabel") a->etiquetteX = texte;
    else if (droite) a->etiquetteYDroite = texte;
    else if (cible == "ylabel") a->etiquetteY = texte;
    else a->etiquetteZ = texte;
    for (; k + 1 < args.size(); k += 2) {
        std::string nom = enMinuscules(args[k].versTexte());
        if (nom == "interpreter")
            a->interpretes[droite ? "ylabeldroite" : cible] = interpreteDepuis(args[k + 1]);
        else if (nom == "fontsize" && cible == "title") a->taillePoliceTitre = args[k + 1].scal();
    }
    if (nargout > 0) return {poigneeTexteCourant(it, cible)};
    return {};
}

FONCTION(fnXlabel) { return texteAxe(it, args, nargout, "xlabel"); }
FONCTION(fnYlabel) { return texteAxe(it, args, nargout, "ylabel"); }
FONCTION(fnZlabel) { return texteAxe(it, args, nargout, "zlabel"); }
FONCTION(fnTitle) { return texteAxe(it, args, nargout, "title"); }

// Les axes que désigne une poignée graphique : celle d'un axe, ou d'une
// courbe (son axe). Nul si la valeur n'est pas une poignée graphique.

// Les positions qu'accepte « legend(...,'Location',L) ».
bool positionLegendeConnue(const std::string& p) {
    static const std::set<std::string> connues = {
        "north", "south", "east", "west", "northeast", "northwest", "southeast", "southwest",
        "northoutside", "southoutside", "eastoutside", "westoutside", "northeastoutside",
        "northwestoutside", "southeastoutside", "southwestoutside", "best", "bestoutside",
        "layout", "none"};
    return connues.count(p) > 0;
}

// legend(étiquettes...), legend(h, ...), legend(ax, ...), suivies de
// propriétés — 'Location', 'Orientation', 'Box' et celles, sans effet sur
// le rendu, que les scripts posent couramment. Les commandes 'off',
// 'show', 'hide', 'toggle', 'boxoff' et 'boxon'.
FONCTION(fnLegend) {
    INUTILISE
    auto a = axesCourants(it);
    std::size_t k = 0;
    std::vector<int> designees;
    if (k < args.size() && args[k].classe == Classe::Objet && args[k].aChamp("NumeroFigure")) {
        if (estPoigneeAxes(args[k])) {
            a = axesDeLaPoignee(it, args[k]);
        } else if (args[k].aChamp("NumeroSerie")) {
            a = axesDeLaPoignee(it, args[k]);
            for (std::size_t e = 0; e < std::max<std::size_t>(args[k].nelem(), 1); ++e)
                designees.push_back((int)args[k].champ("NumeroSerie", e).scal());
        }
        ++k;
    }
    if (k + 1 == args.size() && (args[k].estTexte() || args[k].estChaine())) {
        std::string commande = enMinuscules(args[k].versTexte());
        if (commande == "off" || commande == "hide") {
            a->legendeVisible = false;
            return {};
        }
        if (commande == "show" || commande == "toggle") {
            a->legendeVisible = commande == "show" ? true : !a->legendeVisible;
            if (nargout > 0) return {poigneeTexteCourant(it, "legend")};
            return {};
        }
        if (commande == "boxoff" || commande == "boxon") {
            a->boiteLegende = commande == "boxon";
            a->legendeVisible = true;
            return {};
        }
    }
    static const std::set<std::string> proprietes = {
        "location", "orientation", "box", "fontsize", "textcolor", "color", "edgecolor",
        "interpreter", "autoupdate", "numcolumns", "title", "fontname", "fontweight",
        "fontangle", "linewidth", "visible", "position", "units", "direction", "itemhitfcn",
        "contextmenu", "iconcolumnwidth", "string"};
    std::vector<std::string> etiquettes;
    bool etiquettesDonnees = false;
    for (; k < args.size(); ++k) {
        const Valeur& arg = args[k];
        if ((arg.estTexte() || (arg.estChaine() && arg.nelem() == 1)) && k + 1 < args.size() &&
            proprietes.count(enMinuscules(arg.versTexte())))
            break;
        if (arg.classe == Classe::Cellule) {
            for (const auto& c : arg.cellules) etiquettes.push_back(c.versTexte());
            etiquettesDonnees = true;
        } else if (arg.estChaine()) {
            for (const auto& c : arg.chaines) etiquettes.push_back(c);
            etiquettesDonnees = true;
        } else if (arg.estTexte()) {
            // Un tableau de caractères à plusieurs lignes : une étiquette par ligne.
            if (arg.nlignes() > 1) {
                int l = arg.nlignes(), c = arg.ncolonnes();
                for (int i = 0; i < l; ++i) {
                    std::string ligne;
                    for (int j = 0; j < c; ++j)
                        ligne += (char)(int)arg.re[(std::size_t)i + (std::size_t)j * l];
                    while (!ligne.empty() && ligne.back() == ' ') ligne.pop_back();
                    etiquettes.push_back(ligne);
                }
            } else {
                etiquettes.push_back(arg.versTexte());
            }
            etiquettesDonnees = true;
        } else {
            erreur("MATLAB:legend:InvalidInput",
                   "Labels must be character vectors, a cell array, or a string "
                   "array.");
        }
    }
    for (; k + 1 < args.size(); k += 2) {
        std::string nom = enMinuscules(args[k].versTexte());
        const Valeur& valeur = args[k + 1];
        if (nom == "location") {
            std::string position = enMinuscules(valeur.versTexte());
            if (!positionLegendeConnue(position))
                erreur("MATLAB:legend:InvalidLocation",
                       "'" + valeur.versTexte() + "' is not a valid legend location.");
            a->positionLegende =
                (position == "layout" || position == "none") ? "northeast" : position;
        } else if (nom == "orientation") {
            a->legendeHorizontale = enMinuscules(valeur.versTexte()) == "horizontal";
        } else if (nom == "box") {
            a->boiteLegende = enMinuscules(valeur.versTexte()) != "off";
        } else if (nom == "visible") {
            a->legendeVisible = enMinuscules(valeur.versTexte()) != "off";
        } else if (nom == "interpreter") {
            a->interpretes["legend"] = interpreteDepuis(valeur);
        } else if (nom == "string") {
            etiquettes.clear();
            if (valeur.classe == Classe::Cellule)
                for (const auto& c : valeur.cellules) etiquettes.push_back(c.versTexte());
            else
                etiquettes.push_back(valeur.versTexte());
            etiquettesDonnees = true;
        } else if (!proprietes.count(nom)) {
            erreur("MATLAB:legend:UnknownParameter",
                   "Unrecognized legend property '" + args[k].versTexte() + "'.");
        }
    }
    if (etiquettesDonnees || !designees.empty()) a->legende = etiquettes;
    a->seriesLegende = designees;
    a->legendeVisible = true;
    // MATLAB rend la poignee de la legende : « l = legend(...) » sert a
    // la deplacer ou a la masquer ensuite.
    if (nargout > 0) return {poigneeTexteCourant(it, "legend")};
    return {};
}

FONCTION(fnGrid) {
    INUTILISE
    auto a = axesCourants(it);
    if (args.empty()) {
        a->grille = !a->grille;
        return {};
    }
    std::string s = args[0].versTexte();
    a->grille = (s != "off");
    return {};
}

// « ishold » : l'etat de « hold », pour qu'une fonction qui trace par
// dessus puisse le rendre comme elle l'a trouve.
FONCTION(fnIshold) {
    INUTILISE
    return {Valeur::booleen(axesCourants(it)->tenir)};
}

FONCTION(fnHold) {
    INUTILISE
    auto a = axesCourants(it);
    if (args.empty()) {
        a->tenir = !a->tenir;
        return {};
    }
    std::string s = args[0].versTexte();
    if (s == "on") a->tenir = true;
    else if (s == "off") a->tenir = false;
    else a->tenir = !a->tenir;
    return {};
}

// Bornes qu'on verrait a l'ecran : celles qu'on a fixees, sinon celles des
// donnees. C'est ce que rend « v = axis », et ce que fige « axis manual ».
static void bornesAffichees(const Axes& a, double& xmin, double& xmax, double& ymin,
                            double& ymax) {
    limitesAxe(a, xmin, xmax, ymin, ymax);
}

FONCTION(fnAxis) {
    INUTILISE
    auto a = axesCourants(it);
    // « v = axis » rend [xmin xmax ymin ymax], comme sous MATLAB.
    // En perspective, six bornes : [xmin xmax ymin ymax zmin zmax].
    auto rendreBornes = [&]() -> std::vector<Valeur> {
        double xmin, xmax, ymin, ymax;
        bornesAffichees(*a, xmin, xmax, ymin, ymax);
        std::vector<double> v = {xmin, xmax, ymin, ymax};
        if (vueEspace(*a)) {
            double zmin, zmax;
            limitesAxeZ(*a, zmin, zmax);
            v.push_back(zmin);
            v.push_back(zmax);
        }
        return {Valeur::ligne(v)};
    };
    if (args.empty()) return nargout > 0 ? rendreBornes() : std::vector<Valeur>{};
    if (args[0].estTexte() || args[0].estChaine()) {
        std::string s = args[0].versTexte();
        for (auto& c : s) c = (char)std::tolower((unsigned char)c);
        if (s == "auto") {
            a->limitesManuellesX = false;
            a->limitesManuellesY = false;
            a->limitesManuellesZ = false;
        } else if (s == "manual" || s == "tight" || s == "image") {
            // En perspective, la troisième dimension suit.
            if (vueEspace(*a) && s != "image") {
                double zmin = INFINITY, zmax = -INFINITY;
                if (s == "manual") {
                    limitesAxeZ(*a, zmin, zmax);
                } else {
                    for (const auto& serie : a->series)
                        if (serieEspace(serie) && serie.genre != GenreTrace::Texte)
                            for (double v : serie.z)
                                if (std::isfinite(v)) {
                                    zmin = std::min(zmin, v);
                                    zmax = std::max(zmax, v);
                                }
                }
                if (std::isfinite(zmin) && zmax > zmin) {
                    a->zmin = zmin;
                    a->zmax = zmax;
                    a->limitesManuellesZ = true;
                }
            }
            // « tight » serre sur les donnees et fige ; « manual » fige ce
            // qui est affiche ; « image » y ajoute des echelles egales.
            double xmin, xmax, ymin, ymax;
            if (s == "manual") bornesAffichees(*a, xmin, xmax, ymin, ymax);
            else etendueDonnees(*a, xmin, xmax, ymin, ymax);
            a->xmin = xmin;
            a->xmax = xmax;
            a->ymin = ymin;
            a->ymax = ymax;
            a->limitesManuellesX = true;
            a->limitesManuellesY = true;
            if (s == "image") a->proportions = Axes::Proportions::Egales;
        } else if (s == "equal") {
            a->proportions = Axes::Proportions::Egales;
        } else if (s == "square") {
            a->proportions = Axes::Proportions::Carre;
        } else if (s == "normal") {
            a->proportions = Axes::Proportions::Auto;
        } else if (s == "xy") {
            a->yInverse = false;
        } else if (s == "ij") {
            // MATLAB : « axis ij » met l'origine en haut a gauche, comme
            // les lignes et colonnes d'une matrice.
            a->yInverse = true;
        } else if (s == "off") {
            a->axesVisibles = false;
        } else if (s == "on") {
            a->axesVisibles = true;
        } else {
            erreur("MATLAB:axis:InvalidOption",
                   "Unknown command option '" + args[0].versTexte() + "'.");
        }
        // MATLAB accepte « axis equal tight » : on traite les mots
        // suivants de la meme facon.
        if (args.size() > 1) {
            std::vector<Valeur> reste(args.begin() + 1, args.end());
            fnAxis(it, reste, 0);
        }
        return nargout > 0 ? rendreBornes() : std::vector<Valeur>{};
    }
    if (args[0].nelem() >= 4) {
        a->xmin = args[0].re[0];
        a->xmax = args[0].re[1];
        a->ymin = args[0].re[2];
        a->ymax = args[0].re[3];
        a->limitesManuellesX = true;
        a->limitesManuellesY = true;
    }
    if (args[0].nelem() >= 6) {
        a->zmin = args[0].re[4];
        a->zmax = args[0].re[5];
        a->limitesManuellesZ = true;
    }
    return nargout > 0 ? rendreBornes() : std::vector<Valeur>{};
}

// « xline(3) », « yline(0, '--r', 'seuil') » : une droite qui traverse
// tout l'axe. Elle ne fixe pas les bornes — c'est ce qui la distingue
// d'un plot a deux points — et porte au besoin une etiquette.
std::vector<Valeur> droiteConstante(Interpreteur& it, Arguments args, int nargout,
                                    char axe) {
    exigerArguments(args, 1, 3, axe == 'x' ? "xline" : "yline");
    exigerNumerique(args[0], axe == 'x' ? "xline" : "yline");
    std::string style = args.size() > 1 ? args[1].versTexte() : std::string("-");
    std::string etiquette = args.size() > 2 ? args[2].versTexte() : std::string();
    auto a = axesCourants(it);
    std::vector<int> identifiants;
    for (double v : args[0].re) {
        Serie s;
        s.genre = GenreTrace::Constante;
        s.axeConstante = axe;
        s.x = {v};
        s.legendeConstante = etiquette;
        s.couleur = "#404040";
        s.style = "-";
        decoderStyle(style, s);
        if (s.couleur.empty()) s.couleur = "#404040";
        s.identifiant = ++a->prochaineSerie;
        identifiants.push_back(s.identifiant);
        a->series.push_back(s);
    }
    if (nargout <= 0 || identifiants.empty()) return {};
    if (identifiants.size() == 1)
        return {poigneeLigne(figureCourante(it)->numero, a->identifiant, identifiants[0])};
    return {poigneeLignes(figureCourante(it)->numero, a->identifiant, identifiants)};
}

// « area(x,y) » : la courbe et la surface sous elle. « fill(x,y,c) » : un
// polygone ferme et rempli.
std::vector<Valeur> surfaceRemplie(Interpreteur& it, Arguments args, GenreTrace genre,
                                   const char* nom, int nargout) {
    exigerArguments(args, 1, 0, nom);
    nouveauTrace(it);
    std::size_t k = 0;
    auto axes = axesCourants(it);
    std::size_t indexCouleur = axes->series.size();
    std::vector<int> identifiants;
    while (k < args.size()) {
        Serie s;
        s.genre = genre;
        exigerNumerique(args[k], nom);
        std::vector<double> premier = valeursDe(args[k]);
        ++k;
        if (k < args.size() && !args[k].estTexte() && !args[k].estChaine() &&
            args[k].nelem() == premier.size()) {
            s.x = premier;
            s.y = valeursDe(args[k]);
            ++k;
        } else {
            s.y = premier;
            s.x.resize(s.y.size());
            for (std::size_t i = 0; i < s.x.size(); ++i) s.x[i] = (double)(i + 1);
        }
        if (k < args.size() && (args[k].estTexte() || args[k].estChaine()) &&
            estSpecificationStyle(args[k].versTexte())) {
            decoderStyle(args[k].versTexte(), s);
            ++k;
        } else if (genre == GenreTrace::Polygone && k < args.size() && args[k].estNumerique() &&
                   !args[k].estVide()) {
            // « fill(X,Y,C) » : C est la couleur, non un autre polygone. Un
            // triplet est une couleur RVB ; un scalaire ou une valeur par
            // sommet passent par la palette et CLim, comme dans MATLAB (le
            // polygone prend ici une seule couleur, celle de la moyenne).
            const Valeur& C = args[k];
            if (C.nelem() == 3 && C.nlignes() == 1) {
                s.couleur = couleurDepuisValeur(C);
            } else {
                double somme = 0;
                std::size_t compte = 0;
                for (double c : valeursDe(C))
                    if (std::isfinite(c)) {
                        somme += c;
                        ++compte;
                    }
                s.couleurIndexee = true;
                s.valeurCouleur = compte ? somme / (double)compte : NAN;
                s.couleur = "#000000";
            }
            ++k;
        }
        // Les paires « nom, valeur » : « fill(x,y,'FaceColor',[0 0 1]) ».
        while (k + 1 < args.size() && (args[k].estTexte() || args[k].estChaine())) {
            std::string nomPropriete = args[k].versTexte();
            for (auto& c : nomPropriete) c = (char)std::tolower((unsigned char)c);
            if (nomPropriete == "facecolor" || nomPropriete == "color") {
                std::string couleur = couleurDepuisValeur(args[k + 1]);
                if (!couleur.empty()) s.couleur = couleur;
            } else if (nomPropriete == "edgecolor") {
                std::string bord = couleurDepuisValeur(args[k + 1]);
                if (!bord.empty()) s.couleurBord = bord;
            } else if (nomPropriete == "facealpha") {
                s.opacite = args[k + 1].scal();
            } else if (nomPropriete == "linewidth") {
                s.epaisseur = args[k + 1].scal();
            } else if (nomPropriete == "displayname") {
                s.etiquette = args[k + 1].versTexte();
            } else if (nomPropriete == "linestyle") {
                s.style = args[k + 1].versTexte();
            }
            k += 2;
        }
        if (s.couleur.empty()) s.couleur = palette(indexCouleur++);
        identifiants.push_back(ajouterSerie(it, s));
    }
    if (nargout <= 0 || identifiants.empty()) return {};
    int numeroFigure = figureCourante(it)->numero;
    if (identifiants.size() == 1)
        return {poigneeLigne(numeroFigure, axes->identifiant, identifiants[0])};
    return {poigneeLignes(numeroFigure, axes->identifiant, identifiants)};
}

FONCTION(fnArea) {
    INUTILISE
    return surfaceRemplie(it, args, GenreTrace::Aire, "area", nargout);
}
FONCTION(fnFill) {
    INUTILISE
    return surfaceRemplie(it, args, GenreTrace::Polygone, "fill", nargout);
}

// « line(x,y) » ajoute une courbe sans effacer ce qui est déjà tracé et
// sans toucher au titre : c'est le tracé de bas niveau de MATLAB.
FONCTION(fnLine) {
    INUTILISE
    exigerArguments(args, 2, 0, "line");
    exigerNumerique(args[0], "line");
    exigerNumerique(args[1], "line");
    Serie s;
    s.genre = GenreTrace::Ligne;
    s.x = valeursDe(args[0]);
    s.y = valeursDe(args[1]);
    // line(x,y,z) : une ligne de l'espace.
    std::size_t debutPaires = 2;
    if (args.size() >= 3 && args[2].estNumerique() && !args[2].estTexte()) {
        s.z = valeursDe(args[2]);
        if (s.z.size() != s.x.size())
            erreur("MATLAB:line:XYZLengthMismatch", "Vectors must be the same length.");
        debutPaires = 3;
    }
    for (std::size_t k = debutPaires; k + 1 < args.size(); k += 2) {
        std::string propriete = args[k].versTexte();
        for (auto& c : propriete) c = (char)std::tolower((unsigned char)c);
        if (propriete == "color") {
            std::string couleur = couleurDepuisValeur(args[k + 1]);
            if (!couleur.empty()) s.couleur = couleur;
        } else if (propriete == "linewidth") {
            s.epaisseur = args[k + 1].scal();
        } else if (propriete == "linestyle") {
            s.style = args[k + 1].versTexte();
        } else if (propriete == "marker") {
            s.marqueur = args[k + 1].versTexte();
        } else if (propriete == "markersize") {
            s.tailleMarqueur = args[k + 1].scal();
        } else if (propriete == "markerfacecolor") {
            s.couleurFaceMarqueur = couleurMarqueurDepuis(args[k + 1]);
        } else if (propriete == "markeredgecolor") {
            s.couleurBordMarqueur = couleurMarqueurDepuis(args[k + 1]);
        }
    }
    int identifiant = ajouterSerie(it, s);
    if (nargout > 0)
        return {poigneeLigne(figureCourante(it)->numero, axesCourants(it)->identifiant,
                             identifiant)};
    return {};
}

// zlim([bas haut]), zlim('auto'), zlim() : les bornes de la troisième
// dimension.
FONCTION(fnZlim) {
    INUTILISE
    auto a = axesCourants(it);
    std::size_t k = 0;
    if (!args.empty() && estPoigneeAxes(args[0])) {
        a = axesDeLaPoignee(it, args[0]);
        k = 1;
    }
    if (k >= args.size()) {
        double bas, haut;
        limitesAxeZ(*a, bas, haut);
        return {Valeur::ligne({bas, haut})};
    }
    if (args[k].estTexte() || args[k].estChaine()) {
        std::string mode = enMinuscules(args[k].versTexte());
        if (mode == "auto") a->limitesManuellesZ = false;
        else if (mode == "manual") {
            double bas, haut;
            limitesAxeZ(*a, bas, haut);
            a->zmin = bas;
            a->zmax = haut;
            a->limitesManuellesZ = true;
        } else {
            erreur("MATLAB:zlim:InvalidMode", "zlim : 'auto', 'manual' ou deux bornes.");
        }
        return {};
    }
    exigerNumerique(args[k], "zlim");
    if (args[k].nelem() != 2 || !(args[k].re[1] > args[k].re[0]))
        erreur("MATLAB:zlim:InvalidLimits",
               "Limits must be a 2-element vector of increasing numeric values.");
    a->zmin = args[k].re[0];
    a->zmax = args[k].re[1];
    a->limitesManuellesZ = true;
    return {};
}

// view(az,el), view([az el]), view(2) — la vue de dessus —, view(3) — la
// vue par défaut de l'espace, azimut -37,5, élévation 30 —, view(ax,...),
// et [az,el] = view : la vue de l'axe.
FONCTION(fnView) {
    INUTILISE
    auto a = axesCourants(it);
    std::size_t k = 0;
    if (!args.empty() && estPoigneeAxes(args[0])) {
        a = axesDeLaPoignee(it, args[0]);
        k = 1;
    }
    if (k < args.size()) {
        exigerNumerique(args[k], "view");
        std::vector<double> v = valeursDe(args[k]);
        if (k + 1 < args.size()) {
            exigerNumerique(args[k + 1], "view");
            v = {args[k].scal(), args[k + 1].scal()};
        }
        if (v.size() == 1 && (v[0] == 2 || v[0] == 3)) {
            a->azimut = v[0] == 2 ? 0 : -37.5;
            a->elevation = v[0] == 2 ? 90 : 30;
        } else if (v.size() == 2 && std::isfinite(v[0]) && std::isfinite(v[1])) {
            a->azimut = v[0];
            a->elevation = v[1];
        } else if (v.size() == 3) {
            // Une direction d'observation [x y z], comme MATLAB.
            double r = std::hypot(v[0], v[1]);
            a->azimut = std::atan2(v[0], -v[1]) * 180 / 3.14159265358979323846;
            a->elevation = std::atan2(v[2], r) * 180 / 3.14159265358979323846;
        } else {
            erreur("MATLAB:view:InvalidInput",
                   "View must be 2, 3, [az el], az and el, or a direction [x y z].");
        }
        if (nargout <= 0) return {};
    }
    if (nargout >= 2) return {Valeur::scalaire(a->azimut), Valeur::scalaire(a->elevation)};
    return {Valeur::ligne({a->azimut, a->elevation})};
}

FONCTION(fnXline) { return droiteConstante(it, args, nargout, 'x'); }
FONCTION(fnYline) { return droiteConstante(it, args, nargout, 'y'); }

// « xticks([0 5 10]) » pose les graduations ; sans argument, il les rend.
std::vector<Valeur> graduationsAxe(Interpreteur& it, Arguments args, char axe) {
    auto a = axesCourants(it);
    const bool droite = axe == 'y' && a->deuxOrdonnees && a->coteActif == 1;
    std::vector<double>& cible = axe == 'x'   ? a->ticksX
                                 : droite     ? a->ticksYDroite
                                 : axe == 'y' ? a->ticksY
                                              : a->ticksZ;
    if (args.empty() && droite) {
        double ymin, ymax;
        limitesAxeDroite(*a, ymin, ymax);
        return {Valeur::ligne(a->ticksYDroite.empty()
                                  ? matlibre::graduationsAxe(ymin, ymax, 6, a->logYDroite)
                                  : a->ticksYDroite)};
    }
    if (args.empty()) {
        // Les graduations montrées, même choisies d'office, comme MATLAB.
        double xmin, xmax, ymin, ymax;
        limitesAxe(*a, xmin, xmax, ymin, ymax);
        if (axe == 'z') {
            double zmin, zmax;
            limitesAxeZ(*a, zmin, zmax);
            return {Valeur::ligne(a->ticksZ.empty() ? matlibre::graduationsAxe(zmin, zmax, 6, false)
                                                    : a->ticksZ)};
        }
        return {Valeur::ligne(axe == 'x' ? graduationsEffectives(*a, 'x', xmin, xmax, a->logX)
                                         : graduationsEffectives(*a, 'y', ymin, ymax, a->logY))};
    }
    if (args[0].estTexte() || args[0].estChaine()) {
        // « xticks('auto') » rend le choix automatique.
        std::string mode = args[0].versTexte();
        if (mode == "auto") cible.clear();
        return {};
    }
    exigerNumerique(args[0], axe == 'x' ? "xticks" : axe == 'y' ? "yticks" : "zticks");
    cible.assign(args[0].re.begin(), args[0].re.end());
    return {};
}

FONCTION(fnXticks) { INUTILISE return graduationsAxe(it, args, 'x'); }
FONCTION(fnYticks) { INUTILISE return graduationsAxe(it, args, 'y'); }
FONCTION(fnZticks) { INUTILISE return graduationsAxe(it, args, 'z'); }

std::vector<Valeur> etiquettesAxe(Interpreteur& it, Arguments args, char axe) {
    auto a = axesCourants(it);
    const bool droite = axe == 'y' && a->deuxOrdonnees && a->coteActif == 1;
    std::vector<std::string>& cible = axe == 'x'   ? a->etiquettesTicksX
                                      : droite     ? a->etiquettesTicksYDroite
                                      : axe == 'y' ? a->etiquettesTicksY
                                                   : a->etiquettesTicksZ;
    if (args.empty()) {
        std::vector<Valeur> c;
        for (const std::string& t : cible) c.push_back(Valeur::texte(t));
        return {Valeur::celluleLigne(c)};
    }
    cible.clear();
    if (args[0].classe == Classe::Cellule) {
        for (const Valeur& v : args[0].cellules) cible.push_back(v.versTexte());
    } else if ((args[0].estTexte() || args[0].estChaine()) && args[0].versTexte() == "auto") {
        // rien : les nombres reviennent
    } else if (args[0].estTexte() || args[0].estChaine()) {
        cible.push_back(args[0].versTexte());
    } else {
        for (double v : args[0].re) {
            char tampon[32];
            std::snprintf(tampon, sizeof(tampon), "%g", v);
            cible.push_back(tampon);
        }
    }
    return {};
}

FONCTION(fnXticklabels) { INUTILISE return etiquettesAxe(it, args, 'x'); }
FONCTION(fnYticklabels) { INUTILISE return etiquettesAxe(it, args, 'y'); }
FONCTION(fnZticklabels) { INUTILISE return etiquettesAxe(it, args, 'z'); }

// « cla » vide l'axe courant sans toucher aux autres.
FONCTION(fnCla) {
    INUTILISE
    auto a = axesCourants(it);
    a->series.clear();
    a->titre.clear();
    a->etiquetteX.clear();
    a->etiquetteY.clear();
    a->legende.clear();
    a->legendeVisible = false;
    a->limitesManuellesX = false;
    a->limitesManuellesY = false;
    a->ticksX.clear();
    a->ticksY.clear();
    a->etiquettesTicksX.clear();
    a->etiquettesTicksY.clear();
    a->deuxOrdonnees = false;
    a->coteActif = 0;
    a->limitesManuellesYDroite = false;
    a->logYDroite = false;
    a->ticksYDroite.clear();
    a->etiquettesTicksYDroite.clear();
    a->etiquetteYDroite.clear();
    return {};
}

FONCTION(fnXlim) {
    INUTILISE
    auto a = axesCourants(it);
    if (!args.empty()) exigerNumerique(args[0], "xlim");
    if (args.empty() || args[0].nelem() < 2) {
        double xmin, xmax, ymin, ymax;
        limitesAxe(*a, xmin, xmax, ymin, ymax);
        return {Valeur::ligne({xmin, xmax})};
    }
    a->xmin = args[0].re[0];
    a->xmax = args[0].re[1];
    a->limitesManuellesX = true;
    return {};
}

FONCTION(fnYlim) {
    INUTILISE
    auto a = axesCourants(it);
    std::size_t k = 0;
    if (!args.empty() && estPoigneeAxes(args[0])) {
        a = axesDeLaPoignee(it, args[0]);
        k = 1;
    }
    // Sous « yyaxis », les bornes du côté visé.
    const int cote = coteVise(*a, k == 1 ? &args[0] : nullptr);
    if (k < args.size() && (args[k].estTexte() || args[k].estChaine())) {
        if (enMinuscules(args[k].versTexte()) == "auto") {
            if (cote == 1) a->limitesManuellesYDroite = false;
            else a->limitesManuellesY = false;
        }
        return {};
    }
    if (k < args.size()) exigerNumerique(args[k], "ylim");
    if (k >= args.size() || args[k].nelem() < 2) {
        double xmin, xmax, ymin, ymax;
        if (cote == 1) limitesAxeDroite(*a, ymin, ymax);
        else limitesAxe(*a, xmin, xmax, ymin, ymax);
        return {Valeur::ligne({ymin, ymax})};
    }
    if (cote == 1) {
        a->yminDroite = args[k].re[0];
        a->ymaxDroite = args[k].re[1];
        a->limitesManuellesYDroite = true;
    } else {
        a->ymin = args[k].re[0];
        a->ymax = args[k].re[1];
        a->limitesManuellesY = true;
    }
    return {};
}

// matlibre_cote_axe(ax, cote) : la poignée de l'axe AX qui vise un côté
// de ses ordonnées (0 à gauche, 1 à droite). « plotyy » rend ses deux
// axes ainsi : ylim(AX(2), ...) et ylabel(AX(2), ...) visent la droite.
FONCTION(fnCoteAxe) {
    INUTILISE
    exigerArguments(args, 2, 2, "matlibre_cote_axe");
    if (!estPoigneeAxes(args[0]))
        erreur("MATLAB:matlibre_cote_axe:InvalidAxes", "First argument must be an axes.");
    Valeur p = args[0];
    p.poserChamp("Cote", Valeur::scalaire(args[1].scal() != 0 ? 1.0 : 0.0));
    return {p};
}

// yyaxis left, yyaxis right, yyaxis(ax, ...) : un second axe des
// ordonnées, à droite. Le premier appel range à gauche ce qui est déjà
// tracé ; ensuite, les tracés, ylim, ylabel et yticks visent le côté
// actif. Chaque côté prend sa couleur : la première de MATLAB à gauche,
// la deuxième à droite.
FONCTION(fnYyaxis) {
    INUTILISE
    auto a = axesCourants(it);
    std::size_t k = 0;
    if (!args.empty() && estPoigneeAxes(args[0])) {
        a = axesDeLaPoignee(it, args[0]);
        k = 1;
    }
    if (k >= args.size()) erreur("MATLAB:narginchk:notEnoughInputs", "Not enough input arguments.");
    std::string cote = enMinuscules(args[k].versTexte());
    if (cote != "left" && cote != "right")
        erreur("MATLAB:yyaxis:InvalidSide", "Specify 'left' or 'right'.");
    if (!a->deuxOrdonnees) {
        a->deuxOrdonnees = true;
        for (auto& s : a->series) {
            s.cote = 0;
            for (std::size_t c = 0; c < 7; ++c)
                if (s.couleur == palette(c)) s.couleur = couleurCote(0);
        }
    }
    a->coteActif = cote == "right" ? 1 : 0;
    return {};
}

FONCTION(fnGcf) {
    INUTILISE
    return {poigneeFigureCourante(it)};
}
FONCTION(fnGca) {
    INUTILISE
    return {poigneeAxesCourants(it)};
}

// MatLibre dessine en SVG, et seulement en SVG : le trace est vectoriel
// de bout en bout, sans matriceur. Demander un PNG doit donc le dire, non
// deposer en silence un fichier « x.png.svg » que l'appelant ne trouvera
// jamais a l'endroit ou il l'attend.
static std::string extensionDe(const std::string& nom) {
    auto point = nom.find_last_of('.');
    auto barre = nom.find_last_of("/\\");
    if (point == std::string::npos) return "";
    if (barre != std::string::npos && point < barre) return "";
    std::string ext = nom.substr(point + 1);
    for (char& c : ext) c = (char)std::tolower((unsigned char)c);
    return ext;
}

FONCTION(fnPrint) {
    INUTILISE
    std::string fichier = "figure.svg";
    std::string format;
    for (const auto& a : args)
        if (a.estTexte() || a.estChaine()) {
            std::string s = a.versTexte();
            if (s.size() > 2 && s[0] == '-' && s[1] == 'd') {
                format = s.substr(2);
                for (char& c : format) c = (char)std::tolower((unsigned char)c);
            } else if (!s.empty() && s[0] != '-') {
                fichier = s;
            }
        }
    std::string extension = format.empty() ? extensionDe(fichier) : format;
    if (!extension.empty() && extension != "svg")
        erreur("MATLAB:print:UnsupportedFormat",
               "MatLibre n'enregistre les figures qu'en SVG ; '" + extension +
                   "' n'est pas geré. Donnez un nom en .svg.");
    if (extension.empty()) fichier += ".svg";
    std::ofstream f(fichier);
    if (!f) erreur("MATLAB:print:CannotOpen", "Unable to write '" + fichier + "'.");
    f << rendreSVG(*figureCourante(it));
    return {};
}

FONCTION(fnSaveas) {
    INUTILISE
    exigerArguments(args, 2, 3, "saveas");
    std::vector<Valeur> a = {args[1]};
    // « saveas(h, nom, format) » : le format explicite prime, et PRINT
    // l'attend prefixe par -d.
    if (args.size() > 2 && (args[2].estTexte() || args[2].estChaine()))
        a.push_back(Valeur::texte("-d" + args[2].versTexte()));
    return fnPrint(it, a, nargout);
}

FONCTION(fnDrawnow) {
    INUTILISE
    const char* dossier = std::getenv("MATLIBRE_FIGURES");
    if (!dossier) return {};
    auto f = figureCourante(it);
    std::string fichier = std::string(dossier) + "/figure" + std::to_string(f->numero) + ".svg";
    std::ofstream out(fichier);
    out << rendreSVG(*f);
    return {};
}

// Une palette donnée par son nom — « gray », « jet » : une fonction qu'on
// appelle — ou par une matrice m x 3 de valeurs dans [0,1]. « default »
// rend la palette vide : celle par défaut.
std::vector<double> paletteDepuis(Interpreteur& it, const Valeur& v) {
    Valeur carte = v;
    if (v.estTexte() || v.estChaine()) {
        std::string nom = enMinuscules(v.versTexte());
        if (nom == "default") return {};
        if (nom == "parula")
            erreur("MatLibre:colormap:parula",
                   "parula est propre à MathWorks ; MatLibre emploie viridis par défaut "
                   "(colormap('default')).");
        auto r = it.appeler(nom, {}, 1);
        if (r.empty()) erreur("MATLAB:colormap:InvalidColormap", "Palette inconnue : " + nom + ".");
        carte = r[0];
    }
    if (!carte.estNumerique() || carte.dims.size() != 2 || carte.ncolonnes() != 3 ||
        carte.nlignes() < 1)
        erreur("MATLAB:colormap:InvalidColormap", "Colormap must have 3 columns: [R,G,B].");
    std::vector<double> palette;
    int m = carte.nlignes();
    palette.reserve((std::size_t)m * 3);
    for (int i = 0; i < m; ++i)
        for (int j = 0; j < 3; ++j) {
            double c = carte.re[(std::size_t)i + (std::size_t)j * (std::size_t)m];
            if (!(c >= 0 && c <= 1))
                erreur("MATLAB:colormap:InvalidColormap",
                       "Colormap values must be between 0 and 1.");
            palette.push_back(c);
        }
    return palette;
}

Valeur paletteEnValeur(const std::vector<double>& palette) {
    int m = (int)(palette.size() / 3);
    Valeur v = Valeur::matrice(m, 3);
    for (int i = 0; i < m; ++i)
        for (int j = 0; j < 3; ++j)
            v.re[(std::size_t)i + (std::size_t)j * (std::size_t)m] =
                palette[3 * (std::size_t)i + j];
    return v;
}

// colormap(map), colormap(nom), colormap(cible, map), cmap = colormap(...).
// Sans cible, la palette est celle de la figure ; une cible axe lui donne
// sa propre palette, comme « imshow » le fait.
FONCTION(fnColormap) {
    INUTILISE
    auto figure = figureCourante(it);
    std::shared_ptr<Axes> axe;
    std::size_t k = 0;
    if (!args.empty() && args[0].classe == Classe::Objet && args[0].aChamp("NumeroFigure")) {
        if (estPoigneeFigure(args[0])) {
            int numero = (int)args[0].champ("NumeroFigure").scal();
            auto trouve = it.figures.find(numero);
            if (trouve == it.figures.end() || !trouve->second)
                erreur("MATLAB:class:InvalidHandle", "Invalid or deleted object.");
            figure = trouve->second;
        } else {
            axe = axesDeLaPoignee(it, args[0]);
            int numero = (int)args[0].champ("NumeroFigure").scal();
            figure = it.figures[numero];
        }
        k = 1;
    }
    if (k < args.size()) {
        std::vector<double> palette = paletteDepuis(it, args[k]);
        if (axe) axe->palette = palette;
        else figure->palette = palette;
    }
    if (nargout > 0 || k >= args.size()) {
        if (axe) return {paletteEnValeur(paletteEnVigueur(*figure, *axe))};
        return {paletteEnValeur(figure->palette.size() >= 3 ? figure->palette
                                                            : paletteParDefaut())};
    }
    return {};
}

// clim([bas haut]), clim('auto'), clim('manual'), clim(ax, ...), et
// « lims = clim » : les bornes de couleur de l'axe, que la palette suit.
// caxis est le nom ancien.
std::vector<Valeur> bornesCouleur(Interpreteur& it, const Arguments& args, int nargout,
                                  const char* nom) {
    auto a = axesCourants(it);
    std::size_t k = 0;
    if (!args.empty() && estPoigneeAxes(args[0])) {
        a = axesDeLaPoignee(it, args[0]);
        k = 1;
    }
    if (k < args.size()) {
        const Valeur& v = args[k];
        if (v.estTexte() || v.estChaine()) {
            std::string mode = enMinuscules(v.versTexte());
            if (mode == "auto") {
                a->climManuelle = false;
            } else if (mode == "manual") {
                double bas, haut;
                limitesCouleur(*a, bas, haut);
                a->climManuelle = true;
                a->cmin = bas;
                a->cmax = haut;
            } else if (mode == "mode") {
                return {Valeur::texte(a->climManuelle ? "manual" : "auto")};
            } else {
                erreur(formater("MATLAB:%s:InvalidInput", nom),
                       formater("%s : 'auto', 'manual', ou deux bornes croissantes.", nom));
            }
        } else {
            if (!v.estNumerique() || v.nelem() != 2 || !(v.re[1] > v.re[0]))
                erreur(formater("MATLAB:%s:InvalidLimits", nom),
                       "Color limits must be a 2-element vector of increasing values.");
            a->climManuelle = true;
            a->cmin = v.re[0];
            a->cmax = v.re[1];
        }
        if (nargout <= 0) return {};
    }
    double bas, haut;
    limitesCouleur(*a, bas, haut);
    return {Valeur::ligne({bas, haut})};
}

FONCTION(fnClim) {
    INUTILISE
    return bornesCouleur(it, args, nargout, "clim");
}

FONCTION(fnCaxis) {
    INUTILISE
    return bornesCouleur(it, args, nargout, "caxis");
}
// colorbar, colorbar(ax), colorbar('off'), colorbar(position) et les
// paires Location, Ticks, TickLabels. Les huit positions de MATLAB : hors
// de la boîte (« eastoutside », le défaut, « westoutside »,
// « northoutside », « southoutside ») ou dedans (« east »…).
FONCTION(fnColorbar) {
    INUTILISE
    auto a = axesCourants(it);
    std::size_t k = 0;
    if (!args.empty() && estPoigneeAxes(args[0])) {
        a = axesDeLaPoignee(it, args[0]);
        k = 1;
    }
    bool visible = true;
    auto position = [&](const std::string& mot) {
        static const char* permises[] = {"east",         "west",        "north",
                                         "south",        "eastoutside", "westoutside",
                                         "northoutside", "southoutside"};
        for (const char* p : permises)
            if (mot == p) {
                a->positionBarre = mot;
                return;
            }
        erreur("MATLAB:colorbar:InvalidLocation",
               "Invalid location '" + mot + "' for a colorbar.");
    };
    for (; k < args.size(); ++k) {
        if (!(args[k].estTexte() || args[k].estChaine()))
            erreur("MATLAB:colorbar:InvalidInput",
                   "Expected a location, 'off', or name-value arguments.");
        std::string mot = enMinuscules(args[k].versTexte());
        if (mot == "off" || mot == "delete" || mot == "hide") {
            visible = false;
        } else if (mot == "on" || mot == "show") {
            visible = true;
        } else if (mot == "location" || mot == "ticks" || mot == "ticklabels" ||
                   mot == "fontsize") {
            if (k + 1 >= args.size())
                erreur("MATLAB:colorbar:InvalidInput",
                       "Value missing for colorbar property '" + args[k].versTexte() + "'.");
            const Valeur& v = args[++k];
            if (mot == "location") {
                position(enMinuscules(v.versTexte()));
            } else if (mot == "ticks") {
                exigerNumerique(v, "colorbar");
                a->ticksBarre = valeursDe(v);
            } else if (mot == "ticklabels") {
                a->etiquettesTicksBarre.clear();
                if (v.classe == Classe::Cellule)
                    for (const auto& c : v.cellules)
                        a->etiquettesTicksBarre.push_back(c.versTexte());
                else if (v.estChaine())
                    for (const auto& c : v.chaines) a->etiquettesTicksBarre.push_back(c);
                else
                    a->etiquettesTicksBarre.push_back(v.versTexte());
            }
        } else {
            position(mot);
        }
    }
    a->barreCouleurs = visible;
    if (nargout > 0 && visible) return {poigneeTexteCourant(it, "colorbar")};
    return {};
}
// scatter(x,y), scatter(x,y,sz), scatter(x,y,sz,c), scatter(...,'filled'),
// scatter(...,marqueur), scatter(ax,...) et les paires MarkerEdgeColor,
// MarkerFaceColor, LineWidth, DisplayName, SizeData, CData. SZ est l'aire
// des marqueurs en points carrés (36 par défaut : un marqueur de taille
// 6), un nombre ou un par point ; C une couleur, un triplet, une valeur
// par point que la palette met à l'échelle, ou une ligne RVB par point.
// Les marqueurs sont creux, comme dans MATLAB, sauf sous 'filled'. Le
// tracé générique de plot lisait SZ comme une seconde courbe.
std::vector<Valeur> nuage(Interpreteur& it, Arguments args, int nargout, bool espace) {
    const std::size_t premiers = espace ? 3 : 2;
    std::size_t k = 0;
    std::shared_ptr<Axes> cible;
    if (!args.empty() && estPoigneeAxes(args[0])) {
        cible = axesDeLaPoignee(it, args[0]);
        k = 1;
    }
    std::vector<const Valeur*> nombres;
    while (k < args.size() && nombres.size() < premiers + 2 && !args[k].estTexte() &&
           !args[k].estChaine())
        nombres.push_back(&args[k++]);
    if (nombres.size() < premiers)
        erreur("MATLAB:scatter:NotEnoughInputs",
               espace ? "scatter3 attend au moins X, Y et Z." : "scatter attend au moins X et Y.");
    for (const Valeur* v : nombres) exigerNumerique(*v, espace ? "scatter3" : "scatter");
    Serie s;
    s.genre = GenreTrace::Points;
    s.couleur.clear();
    s.marqueur = "o";
    s.style = "none";
    s.x = valeursDe(*nombres[0]);
    s.y = valeursDe(*nombres[1]);
    if (espace) {
        s.z = valeursDe(*nombres[2]);
        if (s.z.size() != s.x.size())
            erreur("MATLAB:scatter3:InvalidData",
                   "X, Y and Z must be vectors of the same length.");
        // Les tailles et les couleurs suivent Z.
        nombres.erase(nombres.begin() + 2);
    }
    if (s.x.size() != s.y.size())
        erreur("MATLAB:scatter:InvalidXYData",
               "X and Y must be vectors of the same length.");
    const std::size_t n = s.x.size();
    auto lireAires = [&](const Valeur& v) {
        if (v.estVide()) return;
        std::vector<double> aires = valeursDe(v);
        if (aires.size() != 1 && aires.size() != n)
            erreur("MATLAB:scatter:InvalidSizeData",
                   "S must be a scalar or a vector of the same length as X.");
        for (double a : aires)
            if (!(a > 0))
                erreur("MATLAB:scatter:InvalidSizeData",
                       "Marker sizes must be positive.");
        s.airesPoints = aires;
    };
    auto lireCouleurs = [&](const Valeur& c) {
        if (c.estVide()) return;
        if (c.estTexte() || c.estChaine()) {
            std::string couleur = couleurDepuisValeur(c);
            if (couleur.empty() || couleur == "none")
                erreur("MATLAB:scatter:InvalidCData", "Couleur inconnue : " + c.versTexte() + ".");
            s.couleur = couleur;
            return;
        }
        // Un triplet : une seule couleur. Ambigu pour trois points, il est
        // lu comme couleur s'il tient dans [0,1], comme dans MATLAB.
        bool triplet = c.nlignes() == 1 && c.ncolonnes() == 3;
        if (triplet && n == 3)
            for (std::size_t i = 0; i < 3; ++i)
                if (c.re[i] < 0 || c.re[i] > 1) triplet = false;
        if (triplet) {
            s.couleur = couleurDepuisValeur(c);
            return;
        }
        if (c.ncolonnes() == 3 && (std::size_t)c.nlignes() == n && n != 1) {
            for (std::size_t i = 0; i < n; ++i) {
                Valeur ligne = Valeur::ligne({c.re[i], c.re[i + n], c.re[i + 2 * n]});
                s.couleursPoints.push_back(couleurDepuisValeur(ligne));
            }
            return;
        }
        if (c.nelem() == n) {
            s.valeursCouleurPoints = valeursDe(c);
            return;
        }
        erreur("MATLAB:scatter:InvalidCData",
               "Color must be a name, one RGB triplet, one value per point, or one RGB "
               "triplet per point.");
    };
    if (nombres.size() >= 3) lireAires(*nombres[2]);
    if (nombres.size() >= 4) lireCouleurs(*nombres[3]);
    while (k < args.size()) {
        if (!args[k].estTexte() && !args[k].estChaine())
            erreur("MATLAB:scatter:InvalidArgument", "Argument de scatter inattendu.");
        std::string mot = args[k].versTexte();
        std::string bas = enMinuscules(mot);
        if (bas == "filled") {
            s.pointsRemplis = true;
            ++k;
            continue;
        }
        bool paire = bas == "markeredgecolor" || bas == "markerfacecolor" || bas == "linewidth" ||
                     bas == "displayname" || bas == "sizedata" || bas == "cdata" ||
                     bas == "marker" || bas == "markerfacealpha" || bas == "markeredgealpha";
        if (!paire && estSpecificationStyle(mot)) {
            Serie style;
            style.couleur.clear();
            decoderStyle(mot, style);
            if (!style.marqueur.empty()) s.marqueur = style.marqueur;
            if (!style.couleur.empty()) s.couleur = style.couleur;
            ++k;
            continue;
        }
        if (k + 1 >= args.size())
            erreur("MATLAB:scatter:InvalidArgument", "Option " + mot + " requires a value.");
        const Valeur& v = args[k + 1];
        if (bas == "markeredgecolor") s.couleurBordMarqueur = couleurMarqueurDepuis(v);
        else if (bas == "markerfacecolor") s.couleurFaceMarqueur = couleurMarqueurDepuis(v);
        else if (bas == "linewidth") s.epaisseur = v.scal();
        else if (bas == "displayname") s.etiquette = v.versTexte();
        else if (bas == "sizedata") lireAires(v);
        else if (bas == "cdata") lireCouleurs(v);
        else if (bas == "marker") s.marqueur = v.versTexte();
        else if (bas == "markerfacealpha" || bas == "markeredgealpha") s.opacite = v.scal();
        else
            erreur("MatLibre:scatter:Option",
                   "MatLibre ne connaît pas l'option '" + mot + "' de scatter.");
        k += 2;
    }
    // MarkerFaceColor 'flat' : la couleur du point, comme 'filled'.
    if (s.couleurFaceMarqueur == "flat") s.pointsRemplis = true;
    if (s.airesPoints.empty()) s.tailleMarqueur = 6;
    if (cible) {
        auto f = figureCourante(it);
        for (std::size_t i = 0; i < f->axes.size(); ++i)
            if (f->axes[i] == cible) f->axeCourant = (int)i;
    }
    nouveauTrace(it);
    auto axes = axesCourants(it);
    int identifiant = ajouterSerie(it, s);
    if (espace) passerEnEspace(it);
    if (nargout <= 0) return {};
    return {poigneeLigne(figureCourante(it)->numero, axes->identifiant, identifiant)};
}

FONCTION(fnScatter) { return nuage(it, args, nargout, false); }
FONCTION(fnScatter3) { return nuage(it, args, nargout, true); }

// Des faces : fill3(X,Y,Z,C) et le « patch » de bas niveau. X, Y et Z sont
// des vecteurs (une face) ou des matrices (une face par colonne) ; C une
// couleur, un triplet, une valeur (mise à l'échelle par CLim), une valeur
// ou un triplet par face, ou une valeur par sommet (la face prend leur
// moyenne). Les faces sont rangées dans une seule série, séparées par des
// NaN. HAUTNIVEAU : fill3 remplace le tracé (sauf « hold on ») et passe en
// perspective ; patch ajoute ses faces sans rien changer d'autre.
std::vector<Valeur> faces(Interpreteur& it, Arguments args, int nargout, bool hautNiveau,
                          const char* nom) {
    std::size_t k = 0;
    std::vector<const Valeur*> nombres;
    while (k < args.size() && nombres.size() < 4 && !args[k].estTexte() && !args[k].estChaine())
        nombres.push_back(&args[k++]);
    const Valeur* couleurTexte = nullptr;
    if (nombres.size() == 3 && k < args.size() && (args[k].estTexte() || args[k].estChaine()) &&
        (k + 1 >= args.size() || estSpecificationStyle(args[k].versTexte()) ||
         !couleurDepuisValeur(args[k]).empty())) {
        // fill3(X,Y,Z,'r') : la couleur écrite.
        std::string mot = enMinuscules(args[k].versTexte());
        static const std::set<std::string> proprietes = {"facecolor", "edgecolor", "facealpha",
                                                         "linewidth", "linestyle", "displayname"};
        if (!proprietes.count(mot)) couleurTexte = &args[k++];
    }
    if (nombres.size() < 3)
        erreur("MATLAB:narginchk:notEnoughInputs", "Not enough input arguments.");
    for (const Valeur* v : nombres) exigerNumerique(*v, nom);
    const Valeur& X = *nombres[0];
    const Valeur& Y = *nombres[1];
    const Valeur& Z = *nombres[2];
    const bool avecZ = !Z.estVide();
    const bool vecteur = X.nlignes() == 1 || X.ncolonnes() == 1;
    const std::size_t sommets = vecteur ? X.nelem() : (std::size_t)X.nlignes();
    const std::size_t nbFaces = vecteur ? 1 : (std::size_t)X.ncolonnes();
    if (Y.nelem() != X.nelem() || (avecZ && Z.nelem() != X.nelem()))
        erreur("MATLAB:" + std::string(nom) + ":InvalidDimensions",
               "X, Y and Z must be the same size.");
    Serie s;
    s.genre = GenreTrace::Polygone;
    s.couleur.clear();
    s.modeFaces = "flat";
    s.modeAretes = "#000000";
    s.epaisseur = 0.5;
    for (std::size_t f = 0; f < nbFaces; ++f) {
        if (f) {
            s.x.push_back(NAN);
            s.y.push_back(NAN);
            if (avecZ) s.z.push_back(NAN);
        }
        for (std::size_t i = 0; i < sommets; ++i) {
            std::size_t r = i + f * sommets;
            if (!std::isfinite(X.re[r]) || !std::isfinite(Y.re[r])) continue;
            s.x.push_back(X.re[r]);
            s.y.push_back(Y.re[r]);
            if (avecZ) s.z.push_back(Z.re[r]);
        }
    }
    auto lireCouleur = [&](const Valeur& C) {
        if (C.estVide()) return;
        if (C.estTexte() || C.estChaine()) {
            std::string couleur = couleurDepuisValeur(C);
            if (couleur.empty())
                erreur("MATLAB:" + std::string(nom) + ":InvalidColor",
                       "Couleur inconnue : " + C.versTexte() + ".");
            s.couleur = couleur;
            return;
        }
        if (C.nlignes() == 1 && C.ncolonnes() == 3 && nbFaces != 3) {
            s.couleur = couleurDepuisValeur(C);
            return;
        }
        if (C.nelem() == 1) {
            s.valeursCouleurPoints = {C.re[0]};
            return;
        }
        if ((std::size_t)C.nlignes() == nbFaces && C.ncolonnes() == 3 && nbFaces > 1) {
            for (std::size_t f = 0; f < nbFaces; ++f)
                s.couleursPoints.push_back(couleurDepuisValeur(
                    Valeur::ligne({C.re[f], C.re[f + nbFaces], C.re[f + 2 * nbFaces]})));
            return;
        }
        if (C.nelem() == nbFaces) {
            s.valeursCouleurPoints = valeursDe(C);
            return;
        }
        if (C.nelem() == X.nelem()) {
            // Une valeur par sommet : la face prend leur moyenne.
            for (std::size_t f = 0; f < nbFaces; ++f) {
                double somme = 0;
                std::size_t compte = 0;
                for (std::size_t i = 0; i < sommets; ++i) {
                    double v = C.re[i + f * sommets];
                    if (std::isfinite(v)) {
                        somme += v;
                        ++compte;
                    }
                }
                s.valeursCouleurPoints.push_back(compte ? somme / (double)compte : NAN);
            }
            return;
        }
        erreur("MATLAB:" + std::string(nom) + ":InvalidColor",
               "Color must be a color, one value or RGB triplet per face, or one value "
               "per vertex.");
    };
    if (couleurTexte) lireCouleur(*couleurTexte);
    else if (nombres.size() == 4) lireCouleur(*nombres[3]);
    auto mode = [&](const Valeur& v) {
        if (v.estTexte() || v.estChaine()) {
            std::string t = enMinuscules(v.versTexte());
            if (t == "flat" || t == "interp" || t == "none") return t;
        }
        std::string couleur = couleurDepuisValeur(v);
        if (couleur.empty())
            erreur("MATLAB:" + std::string(nom) + ":InvalidColor",
                   "Couleur inconnue : " + v.versTexte() + ".");
        return couleur;
    };
    while (k < args.size()) {
        if (!(args[k].estTexte() || args[k].estChaine()) || k + 1 >= args.size())
            erreur("MATLAB:" + std::string(nom) + ":InvalidArgument",
                   std::string("Argument de ") + nom + " inattendu.");
        std::string propriete = enMinuscules(args[k].versTexte());
        const Valeur& v = args[k + 1];
        if (propriete == "facecolor") {
            // Une couleur imposée aux faces garde les couleurs par face,
            // dont les arêtes peuvent se servir (« EdgeColor », 'flat').
            s.modeFaces = mode(v);
        } else if (propriete == "edgecolor") {
            s.modeAretes = mode(v);
        } else if (propriete == "facealpha") {
            s.opacite = v.scal();
        } else if (propriete == "linewidth") {
            s.epaisseur = v.scal();
        } else if (propriete == "linestyle") {
            s.style = v.versTexte();
            if (s.style == "none") s.modeAretes = "none";
        } else if (propriete == "displayname") {
            s.etiquette = v.versTexte();
        } else if (propriete == "edgealpha" || propriete == "facelighting" ||
                   propriete == "edgelighting") {
            // L'éclairage n'est pas rendu : accepté sans effet.
        } else {
            erreur("MATLAB:hg:InvalidProperty",
                   "Unrecognized property '" + args[k].versTexte() + "' for class 'Patch'.");
        }
        k += 2;
    }
    // Le tracé plan d'une face unie lit couleur et bord comme « fill ».
    if (s.modeFaces == "none") s.couleur = "none";
    else if (s.modeFaces != "flat" && s.modeFaces != "interp") s.couleur = s.modeFaces;
    if (s.modeAretes != "flat" && s.modeAretes != "interp") s.couleurBord = s.modeAretes;
    if (hautNiveau) nouveauTrace(it);
    auto axes = axesCourants(it);
    if (s.couleur.empty() && s.valeursCouleurPoints.empty() && s.couleursPoints.empty())
        s.couleur = palette(axes->series.size());
    if (s.couleur.empty()) s.couleur = "#000000";
    int identifiant = ajouterSerie(it, s);
    if (hautNiveau && avecZ) passerEnEspace(it);
    if (nargout <= 0) return {};
    return {poigneeLigne(figureCourante(it)->numero, axes->identifiant, identifiant)};
}

FONCTION(fnFill3) { return faces(it, args, nargout, true, "fill3"); }
FONCTION(fnPatchFaces) { return faces(it, args, nargout, false, "patch"); }

FONCTION(fnBox) { INUTILISE return {}; }
// shading faceted | flat | interp : le rendu des surfaces de l'axe
// courant — mailles bordées de noir, mailles sans bord, couleurs fondues.
FONCTION(fnShading) {
    INUTILISE
    auto a = axesCourants(it);
    std::size_t k = 0;
    if (!args.empty() && estPoigneeAxes(args[0])) {
        a = axesDeLaPoignee(it, args[0]);
        k = 1;
    }
    if (k >= args.size()) erreur("MATLAB:narginchk:notEnoughInputs", "Not enough input arguments.");
    std::string mode = enMinuscules(args[k].versTexte());
    if (mode != "faceted" && mode != "flat" && mode != "interp")
        erreur("MATLAB:shading:InvalidInput",
               "Shading type must be 'flat', 'faceted', or 'interp'.");
    for (auto& s : a->series) {
        if (s.genre != GenreTrace::Surface && !(s.genre == GenreTrace::Polygone && !s.z.empty()))
            continue;
        bool maillage = s.modeFaces == "#FFFFFF" || s.modeFaces == "none";
        if (mode == "faceted") {
            if (!maillage) s.modeFaces = "flat";
            s.modeAretes = maillage ? "flat" : "#000000";
        } else {
            if (!maillage) s.modeFaces = mode;
            s.modeAretes = maillage ? mode : "none";
        }
    }
    return {};
}

// « text(x,y,'ici') » pose un texte dans l'axe, aux coordonnees des
// donnees. Il ne dilate pas les bornes — un mot n'est pas une donnee —
// et rend une poignee, sur laquelle on ecrit ensuite couleur et taille.
FONCTION(fnText) {
    INUTILISE
    exigerArguments(args, 3, 0, "text");
    exigerNumerique(args[0], "text");
    exigerNumerique(args[1], "text");
    std::vector<double> xs = valeursDe(args[0]);
    std::vector<double> ys = valeursDe(args[1]);
    // text(x,y,z,'texte') : un texte posé dans l'espace.
    std::size_t rangTexte = 2;
    std::vector<double> zs;
    if (args.size() >= 4 && args[2].estNumerique() && !args[2].estTexte()) {
        zs = valeursDe(args[2]);
        rangTexte = 3;
    }
    // Le troisieme argument : un texte, ou une cellule de textes, un par
    // point.
    std::vector<std::string> textes;
    const Valeur& source = args[rangTexte];
    if (source.classe == Classe::Cellule)
        for (const auto& c : source.cellules) textes.push_back(c.versTexte());
    else if (source.estChaine() && source.nelem() > 1)
        for (const auto& c : source.chaines) textes.push_back(c);
    else
        textes.push_back(source.versTexte());

    std::string couleur = "#000000";
    double taille = 0;
    char alignement = 'l';
    std::string interprete = "tex";
    for (std::size_t k = rangTexte + 1; k + 1 < args.size(); k += 2) {
        std::string propriete = args[k].versTexte();
        for (auto& c : propriete) c = (char)std::tolower((unsigned char)c);
        if (propriete == "color") {
            std::string trouvee = couleurDepuisValeur(args[k + 1]);
            if (!trouvee.empty()) couleur = trouvee;
        } else if (propriete == "fontsize") {
            taille = args[k + 1].scal();
        } else if (propriete == "horizontalalignment") {
            std::string a = args[k + 1].versTexte();
            alignement = a.empty() ? 'l' : (a[0] == 'c' ? 'c' : (a[0] == 'r' ? 'r' : 'l'));
        } else if (propriete == "interpreter") {
            interprete = interpreteDepuis(args[k + 1]);
        }
    }

    auto axes = axesCourants(it);
    std::vector<int> identifiants;
    std::size_t combien = std::min(xs.size(), ys.size());
    for (std::size_t k = 0; k < combien; ++k) {
        Serie s;
        s.genre = GenreTrace::Texte;
        s.x = {xs[k]};
        s.y = {ys[k]};
        if (!zs.empty()) s.z = {zs[std::min(k, zs.size() - 1)]};
        s.legendeConstante = textes[std::min(k, textes.size() - 1)];
        s.couleur = couleur;
        s.taillePoliceTexte = taille;
        s.alignement = alignement;
        s.interprete = interprete;
        s.identifiant = ++axes->prochaineSerie;
        identifiants.push_back(s.identifiant);
        axes->series.push_back(s);
    }
    if (nargout <= 0 || identifiants.empty()) return {};
    if (identifiants.size() == 1)
        return {poigneeTexteTrace(figureCourante(it)->numero, axes->identifiant,
                                  identifiants[0])};
    return {poigneeLignes(figureCourante(it)->numero, axes->identifiant, identifiants)};
}

FONCTION(fnFigureSVG) {
    INUTILISE
    // matlibre_svg() rend le SVG de la figure courante sous forme de texte :
    // utile aux tests et à la documentation.
    return {Valeur::texte(rendreSVG(*figureCourante(it)))};
}

}  // namespace

void enregistrerGraphique(Interpreteur& it) {
    it.enregistrer("plot", fnPlot, "graphique", "plot  Trace des courbes 2-D.");
    it.enregistrer("plot3", fnPlot3, "graphique", "plot3  Trace une courbe de l'espace.");
    it.enregistrer("semilogx", fnSemilogx, "graphique", "semilogx  Axe des x logarithmique.");
    it.enregistrer("semilogy", fnSemilogy, "graphique", "semilogy  Axe des y logarithmique.");
    it.enregistrer("loglog", fnLoglog, "graphique", "loglog  Deux axes logarithmiques.");
    it.enregistrer("bar", fnBar, "graphique", "bar  Diagramme en barres.");
    it.enregistrer("scatter", fnScatter, "graphique", "scatter  Nuage de points.");
    it.enregistrer("scatter3", fnScatter3, "graphique", "scatter3  Nuage de points de l'espace.");
    it.enregistrer("fill3", fnFill3, "graphique", "fill3  Polygones remplis de l'espace.");
    it.enregistrer("matlibre_patch", fnPatchFaces, "graphique",
                   "matlibre_patch  Faces d'un patch, sans effacer le trace.");
    it.enregistrer("stairs", fnStairs, "graphique", "stairs  Trace en escalier.");
    it.enregistrer("stem", fnStem, "graphique", "stem  Trace en tiges.");
    it.enregistrer("histogram", fnHistogramme, "graphique", "histogram  Histogramme.");
    it.enregistrer("hist", fnHist, "graphique", "hist  Histogramme (ancienne forme).");
    it.enregistrer("imagesc", fnImagesc, "graphique", "imagesc  Image en fausses couleurs.");
    it.enregistrer("image", fnImage, "graphique",
                   "image  Affiche une image : indices de palette, ou couleurs vraies.");
    it.enregistrer("surf", fnSurf, "graphique", "surf  Surface en trois dimensions.");
    it.enregistrer("mesh", fnMesh, "graphique", "mesh  Maillage en trois dimensions.");
    it.enregistrer("contourf", fnContourf, "graphique",
                   "contourf  Lignes de niveau, sur fond colore.");
    it.enregistrer("contour3", fnContour3, "graphique",
                   "contour3  Lignes de niveau (rendu plan).");
    it.enregistrer("contourc", fnContourc, "graphique",
                   "contourc  Matrice des lignes de niveau, sans tracer.");
    it.enregistrer("contour", fnContour, "graphique", "contour  Lignes de niveau.");
    it.enregistrer("pcolor", fnPcolor, "graphique", "pcolor  Damier colore.");
    it.enregistrer("figure", fnFigure, "graphique", "figure  Cree ou choisit une figure.");
    it.enregistrer("clf", fnClf, "graphique", "clf  Vide la figure courante.");
    it.enregistrer("close", fnClose, "graphique", "close  Ferme une figure.");
    it.enregistrer("matlibre_figures_ouvertes", fnFiguresOuvertes, "graphique",
                   "matlibre_figures_ouvertes  Numeros des figures ouvertes.");
    it.enregistrer("subplot", fnSubplot, "graphique", "subplot  Decoupe la figure en cases.");
    it.enregistrer("xline", fnXline, "graphique", "xline  Droite verticale.");
    it.enregistrer("yline", fnYline, "graphique", "yline  Droite horizontale.");
    it.enregistrer("xticks", fnXticks, "graphique", "xticks  Graduations de l'axe des x.");
    it.enregistrer("yticks", fnYticks, "graphique", "yticks  Graduations de l'axe des y.");
    it.enregistrer("xticklabels", fnXticklabels, "graphique",
                   "xticklabels  Etiquettes des graduations en x.");
    it.enregistrer("yticklabels", fnYticklabels, "graphique",
                   "yticklabels  Etiquettes des graduations en y.");
    it.enregistrer("zticks", fnZticks, "graphique", "zticks  Graduations de l'axe des z.");
    it.enregistrer("zticklabels", fnZticklabels, "graphique",
                   "zticklabels  Textes des graduations de l'axe des z.");
    it.enregistrer("cla", fnCla, "graphique", "cla  Vide l'axe courant.");
    it.enregistrer("area", fnArea, "graphique", "area  Trace une aire remplie.");
    it.enregistrer("fill", fnFill, "graphique", "fill  Remplit un polygone.");
    it.enregistrer("line", fnLine, "graphique", "line  Ajoute une courbe sans effacer.");
    it.enregistrer("zlim", fnZlim, "graphique", "zlim  Bornes de l'axe des z.");
    it.enregistrer("view", fnView, "graphique", "view  Point de vue d'un trace 3D.");
    it.enregistrer("axes", fnAxes, "graphique", "axes  Cree un axe ou en designe un.");
    it.enregistrer("xlabel", fnXlabel, "graphique", "xlabel  Etiquette de l'axe des x.");
    it.enregistrer("ylabel", fnYlabel, "graphique", "ylabel  Etiquette de l'axe des y.");
    it.enregistrer("zlabel", fnZlabel, "graphique", "zlabel  Etiquette de l'axe des z.");
    it.enregistrer("title", fnTitle, "graphique", "title  Titre des axes.");
    it.enregistrer("legend", fnLegend, "graphique", "legend  Legende des courbes.");
    it.enregistrer("grid", fnGrid, "graphique", "grid  Affiche la grille.");
    it.enregistrer("hold", fnHold, "graphique", "hold  Conserve les traces precedents.");
    it.enregistrer("ishold", fnIshold, "graphique", "ishold  L'etat de hold.");
    it.enregistrer("axis", fnAxis, "graphique", "axis  Regle les limites des axes.");
    it.enregistrer("xlim", fnXlim, "graphique", "xlim  Limites en x.");
    it.enregistrer("ylim", fnYlim, "graphique", "ylim  Limites en y.");
    it.enregistrer("yyaxis", fnYyaxis, "graphique",
                   "yyaxis  Second axe des ordonnees, a droite.");
    it.enregistrer("matlibre_cote_axe", fnCoteAxe, "graphique",
                   "matlibre_cote_axe  Poignee d'un cote d'un axe a deux ordonnees.");
    it.enregistrer("gcf", fnGcf, "graphique", "gcf  Numero de la figure courante.");
    it.enregistrer("gca", fnGca, "graphique", "gca  Axes courants.");
    it.enregistrer("print", fnPrint, "graphique", "print  Ecrit la figure dans un fichier SVG.");
    it.enregistrer("saveas", fnSaveas, "graphique", "saveas  Enregistre la figure.");
    it.enregistrer("drawnow", fnDrawnow, "graphique", "drawnow  Rafraichit l'affichage.");
    it.enregistrer("colormap", fnColormap, "graphique", "colormap  Palette de couleurs.");
    it.enregistrer("clim", fnClim, "graphique", "clim  Bornes de couleur de l'axe.");
    it.enregistrer("caxis", fnCaxis, "graphique", "caxis  Bornes de couleur (nom ancien de clim).");
    it.enregistrer("colorbar", fnColorbar, "graphique", "colorbar  Barre de couleurs.");
    it.enregistrer("box", fnBox, "graphique", "box  Cadre autour des axes.");
    it.enregistrer("shading", fnShading, "graphique", "shading  Mode d'ombrage.");
    it.enregistrer("text", fnText, "graphique", "text  Texte dans les axes.");
    it.enregistrer("matlibre_svg", fnFigureSVG, "graphique",
                   "matlibre_svg  Rend la figure courante en SVG (texte).");
}

}  // namespace matlibre
