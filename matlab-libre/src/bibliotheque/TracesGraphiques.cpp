// TracesGraphiques.cpp — les fonctions de tracé du langage.
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <memory>

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
        case 'r': return "#D95319";
        case 'g': return "#77AC30";
        case 'b': return "#0072BD";
        case 'c': return "#4DBEEE";
        case 'm': return "#7E2F8E";
        case 'y': return "#EDB120";
        case 'k': return "#000000";
        case 'w': return "#FFFFFF";
        default: return "";
    }
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
        if (c == '-' || c == ':' || c == '.') {
            if (c == '.' && !(k + 1 < spec.size() && spec[k + 1] == '-')) {
                s.marqueur = ".";
                continue;
            }
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

void ajouterSerie(Interpreteur& it, Serie s) {
    auto a = axesCourants(it);
    if (!a->tenir && a->series.empty()) { /* premier tracé */ }
    if (s.couleur.empty()) s.couleur = palette(a->series.size());
    a->series.push_back(std::move(s));
}

void nouveauTrace(Interpreteur& it) {
    auto a = axesCourants(it);
    if (!a->tenir) {
        a->series.clear();
        a->legendeVisible = false;
        a->legende.clear();
    }
}

std::vector<Valeur> tracer(Interpreteur& it, std::vector<Valeur>& args, GenreTrace genre,
                           bool logX, bool logY) {
    exigerArguments(args, 1, 0, "plot");
    nouveauTrace(it);
    auto axes = axesCourants(it);
    axes->logX = logX;
    axes->logY = logY;
    std::size_t k = 0;
    std::size_t indexCouleur = axes->series.size();
    while (k < args.size()) {
        Serie s;
        s.genre = genre;
        s.couleur = palette(indexCouleur++);
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
                    ajouterSerie(it, sc);
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
            // Les paires « nom, valeur » ne sont pas des styles.
            if (spec.size() <= 5 && spec.find_first_of("-:.+o*xsdv^<>phrgbcmykw") !=
                                        std::string::npos) {
                decoderStyle(spec, s);
                ++k;
            }
        }
        // Paires nom/valeur.
        while (k + 1 < args.size() && (args[k].estTexte() || args[k].estChaine())) {
            std::string nom = args[k].versTexte();
            for (auto& c : nom) c = (char)std::tolower((unsigned char)c);
            if (nom == "linewidth") s.epaisseur = args[k + 1].scal();
            else if (nom == "color" && (args[k + 1].estTexte() || args[k + 1].estChaine())) {
                std::string couleur = couleurDeLettre(args[k + 1].versTexte()[0]);
                if (!couleur.empty()) s.couleur = couleur;
            } else if (nom == "displayname") {
                s.etiquette = args[k + 1].versTexte();
            } else if (nom == "linestyle") {
                s.style = args[k + 1].versTexte();
            } else if (nom == "marker") {
                s.marqueur = args[k + 1].versTexte();
            }
            k += 2;
        }
        ajouterSerie(it, s);
    }
    return {};
}

FONCTION(fnPlot) { INUTILISE return tracer(it, args, GenreTrace::Ligne, false, false); }
FONCTION(fnSemilogx) { INUTILISE return tracer(it, args, GenreTrace::Ligne, true, false); }
FONCTION(fnSemilogy) { INUTILISE return tracer(it, args, GenreTrace::Ligne, false, true); }
FONCTION(fnLoglog) { INUTILISE return tracer(it, args, GenreTrace::Ligne, true, true); }
FONCTION(fnBar) { INUTILISE return tracer(it, args, GenreTrace::Barres, false, false); }
FONCTION(fnScatter) { INUTILISE return tracer(it, args, GenreTrace::Points, false, false); }
FONCTION(fnStairs) { INUTILISE return tracer(it, args, GenreTrace::Escalier, false, false); }
FONCTION(fnStem) { INUTILISE return tracer(it, args, GenreTrace::Tige, false, false); }
FONCTION(fnPlot3) { INUTILISE return tracer(it, args, GenreTrace::Ligne, false, false); }

FONCTION(fnHistogramme) {
    INUTILISE
    exigerArguments(args, 1, 3, "histogram");
    for (std::size_t k = 0; k < args.size(); ++k) exigerNumerique(args[k], "histogram");
    std::vector<Valeur> a = {args[0]};
    if (args.size() > 1) a.push_back(args[1]);
    auto comptes = it.appeler("histcounts", a, 2);
    if (comptes.size() < 2) return {};
    std::vector<double> centres;
    const Valeur& bords = comptes[1];
    for (std::size_t k = 0; k + 1 < bords.nelem(); ++k)
        centres.push_back(0.5 * (bords.re[k] + bords.re[k + 1]));
    nouveauTrace(it);
    Serie s;
    s.genre = GenreTrace::Barres;
    s.x = centres;
    s.y = valeursDe(comptes[0]);
    s.couleur = palette(axesCourants(it)->series.size());
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

FONCTION(fnImagesc) {
    INUTILISE
    exigerArguments(args, 1, 3, "imagesc");
    const Valeur& z = args[args.size() - 1];
    nouveauTrace(it);
    Serie s;
    s.genre = GenreTrace::Image;
    s.hauteurImage = z.nlignes();
    s.largeurImage = z.ncolonnes();
    s.z = valeursDe(z);
    s.x = {0.5, (double)s.largeurImage + 0.5};
    s.y = {0.5, (double)s.hauteurImage + 0.5};
    ajouterSerie(it, s);
    return {};
}

FONCTION(fnSurf) {
    INUTILISE
    exigerArguments(args, 1, 4, "surf");
    std::vector<Valeur> a = {args[args.size() - 1]};
    return fnImagesc(it, a, nargout);
}

FONCTION(fnContour) {
    INUTILISE
    return fnSurf(it, args, nargout);
}

FONCTION(fnFigure) {
    INUTILISE
    int numero = 0;
    if (!args.empty() && args[0].estNumerique() && !args[0].estVide())
        numero = (int)args[0].scal();
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

FONCTION(fnClose) {
    INUTILISE
    if (args.empty()) {
        it.figures.erase(it.figureCourante);
        it.figureCourante = it.figures.empty() ? 0 : it.figures.begin()->first;
        return {};
    }
    if (args[0].estTexte() && args[0].versTexte() == "all") {
        it.figures.clear();
        it.figureCourante = 0;
        return {};
    }
    it.figures.erase((int)args[0].scal());
    if (!it.figures.count(it.figureCourante))
        it.figureCourante = it.figures.empty() ? 0 : it.figures.begin()->first;
    return {};
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

FONCTION(fnXlabel) {
    axesCourants(it)->etiquetteX = args.empty() ? "" : args[0].versTexte();
    // MATLAB rend la poignee du texte : « z = title(...) ; set(z,...) ».
    if (nargout > 0) return {poigneeTexteCourant(it, "xlabel")};
    return {};
}
FONCTION(fnYlabel) {
    axesCourants(it)->etiquetteY = args.empty() ? "" : args[0].versTexte();
    // MATLAB rend la poignee du texte : « z = title(...) ; set(z,...) ».
    if (nargout > 0) return {poigneeTexteCourant(it, "ylabel")};
    return {};
}
FONCTION(fnZlabel) {
    INUTILISE
    axesCourants(it)->etiquetteZ = args.empty() ? "" : args[0].versTexte();
    return {};
}
FONCTION(fnTitle) {
    axesCourants(it)->titre = args.empty() ? "" : args[0].versTexte();
    // MATLAB rend la poignee du texte : « z = title(...) ; set(z,...) ».
    if (nargout > 0) return {poigneeTexteCourant(it, "title")};
    return {};
}

FONCTION(fnLegend) {
    INUTILISE
    auto a = axesCourants(it);
    a->legende.clear();
    for (const auto& arg : args) {
        if (arg.classe == Classe::Cellule) {
            for (const auto& c : arg.cellules) a->legende.push_back(c.versTexte());
        } else if (arg.estTexte() || arg.estChaine()) {
            std::string s = arg.versTexte();
            if (s == "off") {
                a->legendeVisible = false;
                return {};
            }
            if (s == "Location" || s == "location") break;
            a->legende.push_back(s);
        }
    }
    a->legendeVisible = true;
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
    xmin = INFINITY;
    xmax = -INFINITY;
    ymin = INFINITY;
    ymax = -INFINITY;
    for (const auto& s : a.series) {
        for (double v : s.x) {
            if (!std::isfinite(v)) continue;
            xmin = std::min(xmin, v);
            xmax = std::max(xmax, v);
        }
        for (double v : s.y) {
            if (!std::isfinite(v)) continue;
            ymin = std::min(ymin, v);
            ymax = std::max(ymax, v);
        }
    }
    if (!std::isfinite(xmin)) { xmin = 0; xmax = 1; }
    if (!std::isfinite(ymin)) { ymin = 0; ymax = 1; }
    if (xmax == xmin) { xmin -= 0.5; xmax += 0.5; }
    if (ymax == ymin) { ymin -= 0.5; ymax += 0.5; }
    if (a.limitesManuellesX) { xmin = a.xmin; xmax = a.xmax; }
    if (a.limitesManuellesY) { ymin = a.ymin; ymax = a.ymax; }
}

FONCTION(fnAxis) {
    INUTILISE
    auto a = axesCourants(it);
    // « v = axis » rend [xmin xmax ymin ymax], comme sous MATLAB.
    auto rendreBornes = [&]() -> std::vector<Valeur> {
        double xmin, xmax, ymin, ymax;
        bornesAffichees(*a, xmin, xmax, ymin, ymax);
        std::vector<double> v = {xmin, xmax, ymin, ymax};
        return {Valeur::ligne(v)};
    };
    if (args.empty()) return nargout > 0 ? rendreBornes() : std::vector<Valeur>{};
    if (args[0].estTexte() || args[0].estChaine()) {
        std::string s = args[0].versTexte();
        for (auto& c : s) c = (char)std::tolower((unsigned char)c);
        if (s == "auto") {
            a->limitesManuellesX = false;
            a->limitesManuellesY = false;
        } else if (s == "manual" || s == "tight" || s == "image") {
            // « tight » serre sur les donnees et fige ; « manual » fige ce
            // qui est affiche ; « image » y ajoute des echelles egales.
            double xmin, xmax, ymin, ymax;
            bornesAffichees(*a, xmin, xmax, ymin, ymax);
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
    return nargout > 0 ? rendreBornes() : std::vector<Valeur>{};
}

FONCTION(fnXlim) {
    INUTILISE
    auto a = axesCourants(it);
    if (args.empty() || args[0].nelem() < 2) {
        std::vector<double> v = {a->xmin, a->xmax};
        return {Valeur::ligne(v)};
    }
    a->xmin = args[0].re[0];
    a->xmax = args[0].re[1];
    a->limitesManuellesX = true;
    return {};
}

FONCTION(fnYlim) {
    INUTILISE
    auto a = axesCourants(it);
    if (args.empty() || args[0].nelem() < 2) {
        std::vector<double> v = {a->ymin, a->ymax};
        return {Valeur::ligne(v)};
    }
    a->ymin = args[0].re[0];
    a->ymax = args[0].re[1];
    a->limitesManuellesY = true;
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

FONCTION(fnPrint) {
    INUTILISE
    std::string fichier = "figure.svg";
    for (const auto& a : args)
        if (a.estTexte() || a.estChaine()) {
            std::string s = a.versTexte();
            if (!s.empty() && s[0] != '-') fichier = s;
        }
    if (fichier.size() < 4 || fichier.substr(fichier.size() - 4) != ".svg") fichier += ".svg";
    std::ofstream f(fichier);
    if (!f) erreur("MATLAB:print:CannotOpen", "Unable to write '" + fichier + "'.");
    f << rendreSVG(*figureCourante(it));
    return {};
}

FONCTION(fnSaveas) {
    INUTILISE
    exigerArguments(args, 2, 3, "saveas");
    std::vector<Valeur> a = {args[1]};
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

FONCTION(fnColormap) { INUTILISE return {}; }
FONCTION(fnColorbar) { INUTILISE return {}; }
FONCTION(fnBox) { INUTILISE return {}; }
FONCTION(fnShading) { INUTILISE return {}; }

FONCTION(fnText) {
    INUTILISE
    return {};
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
    it.enregistrer("plot3", fnPlot3, "graphique", "plot3  Trace une courbe 3-D (projetee).");
    it.enregistrer("semilogx", fnSemilogx, "graphique", "semilogx  Axe des x logarithmique.");
    it.enregistrer("semilogy", fnSemilogy, "graphique", "semilogy  Axe des y logarithmique.");
    it.enregistrer("loglog", fnLoglog, "graphique", "loglog  Deux axes logarithmiques.");
    it.enregistrer("bar", fnBar, "graphique", "bar  Diagramme en barres.");
    it.enregistrer("scatter", fnScatter, "graphique", "scatter  Nuage de points.");
    it.enregistrer("stairs", fnStairs, "graphique", "stairs  Trace en escalier.");
    it.enregistrer("stem", fnStem, "graphique", "stem  Trace en tiges.");
    it.enregistrer("histogram", fnHistogramme, "graphique", "histogram  Histogramme.");
    it.enregistrer("hist", fnHist, "graphique", "hist  Histogramme (ancienne forme).");
    it.enregistrer("imagesc", fnImagesc, "graphique", "imagesc  Image en fausses couleurs.");
    it.enregistrer("image", fnImagesc, "graphique", "image  Affiche une matrice comme image.");
    it.enregistrer("surf", fnSurf, "graphique", "surf  Surface (rendue en carte de couleurs).");
    it.enregistrer("mesh", fnSurf, "graphique", "mesh  Maillage (rendu en carte de couleurs).");
    it.enregistrer("contour", fnContour, "graphique", "contour  Lignes de niveau.");
    it.enregistrer("pcolor", fnImagesc, "graphique", "pcolor  Damier colore.");
    it.enregistrer("figure", fnFigure, "graphique", "figure  Cree ou choisit une figure.");
    it.enregistrer("clf", fnClf, "graphique", "clf  Vide la figure courante.");
    it.enregistrer("close", fnClose, "graphique", "close  Ferme une figure.");
    it.enregistrer("subplot", fnSubplot, "graphique", "subplot  Decoupe la figure en cases.");
    it.enregistrer("axes", fnAxes, "graphique", "axes  Cree un axe ou en designe un.");
    it.enregistrer("xlabel", fnXlabel, "graphique", "xlabel  Etiquette de l'axe des x.");
    it.enregistrer("ylabel", fnYlabel, "graphique", "ylabel  Etiquette de l'axe des y.");
    it.enregistrer("zlabel", fnZlabel, "graphique", "zlabel  Etiquette de l'axe des z.");
    it.enregistrer("title", fnTitle, "graphique", "title  Titre des axes.");
    it.enregistrer("legend", fnLegend, "graphique", "legend  Legende des courbes.");
    it.enregistrer("grid", fnGrid, "graphique", "grid  Affiche la grille.");
    it.enregistrer("hold", fnHold, "graphique", "hold  Conserve les traces precedents.");
    it.enregistrer("axis", fnAxis, "graphique", "axis  Regle les limites des axes.");
    it.enregistrer("xlim", fnXlim, "graphique", "xlim  Limites en x.");
    it.enregistrer("ylim", fnYlim, "graphique", "ylim  Limites en y.");
    it.enregistrer("gcf", fnGcf, "graphique", "gcf  Numero de la figure courante.");
    it.enregistrer("gca", fnGca, "graphique", "gca  Axes courants.");
    it.enregistrer("print", fnPrint, "graphique", "print  Ecrit la figure dans un fichier SVG.");
    it.enregistrer("saveas", fnSaveas, "graphique", "saveas  Enregistre la figure.");
    it.enregistrer("drawnow", fnDrawnow, "graphique", "drawnow  Rafraichit l'affichage.");
    it.enregistrer("colormap", fnColormap, "graphique", "colormap  Palette de couleurs.");
    it.enregistrer("colorbar", fnColorbar, "graphique", "colorbar  Barre de couleurs.");
    it.enregistrer("box", fnBox, "graphique", "box  Cadre autour des axes.");
    it.enregistrer("shading", fnShading, "graphique", "shading  Mode d'ombrage.");
    it.enregistrer("text", fnText, "graphique", "text  Texte dans les axes.");
    it.enregistrer("matlibre_svg", fnFigureSVG, "graphique",
                   "matlibre_svg  Rend la figure courante en SVG (texte).");
}

}  // namespace matlibre
