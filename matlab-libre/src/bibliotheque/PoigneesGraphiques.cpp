// PoigneesGraphiques.cpp — « ax.XTick = [...] », set(gca,…), get(gcf,…).
//
// MATLAB donne à ses figures et à ses axes des poignées dont on écrit les
// propriétés au point : « ax = gca; ax.XTick = [15 40 60] ». Une poignée
// n'est pas un objet de classe MATLAB : c'est une référence vers une
// figure et un axe, dont les propriétés vivent dans la figure. On la
// représente donc par un objet portant le nom de classe de MATLAB et deux
// champs cachés, et les crochets de l'interpréteur routent la lecture et
// l'écriture vers la figure elle-même.
#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Graphique.h"
#include "matlibre/Interpreteur.h"

namespace matlibre {
namespace {

const char* CLASSE_AXES = "matlab.graphics.axis.Axes";
const char* CLASSE_FIGURE = "matlab.ui.Figure";

Valeur poignee(const char* classe, int figure, int axe) {
    Valeur v = Valeur::structureVide();
    v.poserChamp("NumeroFigure", Valeur::scalaire(figure));
    v.poserChamp("NumeroAxe", Valeur::scalaire(axe));
    v.classe = Classe::Objet;
    v.nomObjet = classe;
    return v;
}

bool estPoignee(const Valeur& v, const char* classe) {
    return v.classe == Classe::Objet && v.nomObjet == classe;
}

std::shared_ptr<Figure> figureDe(Interpreteur& it, const Valeur& p) {
    int numero = (int)p.champ("NumeroFigure", 0).scal();
    auto trouve = it.figures.find(numero);
    if (trouve == it.figures.end() || !trouve->second)
        erreur("MATLAB:class:InvalidHandle", "Invalid or deleted object.");
    return trouve->second;
}

std::shared_ptr<Axes> axesDe(Interpreteur& it, const Valeur& p) {
    auto f = figureDe(it, p);
    int indice = (int)p.champ("NumeroAxe", 0).scal();
    if (indice < 0 || indice >= (int)f->axes.size() || !f->axes[(std::size_t)indice])
        erreur("MATLAB:class:InvalidHandle", "Invalid or deleted object.");
    return f->axes[(std::size_t)indice];
}

// Comparaison sans égard à la casse : MATLAB accepte « xtick », « XTick »
// et « XTICK » indifféremment.
bool memeNom(const std::string& a, const char* b) {
    std::string q = b;
    if (a.size() != q.size()) return false;
    for (std::size_t k = 0; k < a.size(); ++k)
        if (std::tolower((unsigned char)a[k]) != std::tolower((unsigned char)q[k])) return false;
    return true;
}

std::vector<double> versVecteur(const Valeur& v) {
    std::vector<double> r;
    r.reserve(v.re.size());
    for (double x : v.re) r.push_back(x);
    return r;
}

Valeur depuisVecteur(const std::vector<double>& v) {
    Valeur r = Valeur::ligne(v);
    return r;
}

std::vector<std::string> versTextes(const Valeur& v) {
    std::vector<std::string> r;
    if (v.classe == Classe::Cellule) {
        for (const auto& c : v.cellules) r.push_back(c.versTexte());
        return r;
    }
    if (v.estTexte() || v.estChaine()) r.push_back(v.versTexte());
    return r;
}

bool vraiDe(const Valeur& v) {
    if (v.estTexte() || v.estChaine()) {
        std::string s = v.versTexte();
        for (auto& c : s) c = (char)std::tolower((unsigned char)c);
        return s == "on" || s == "true" || s == "1";
    }
    return v.scal() != 0;
}

Valeur marche(bool actif) { return Valeur::texte(actif ? "on" : "off"); }

// --- écriture -----------------------------------------------------------

bool ecrireAxes(Interpreteur& it, const Valeur& p, const std::string& nom,
                const Valeur& v) {
    auto a = axesDe(it, p);
    if (memeNom(nom, "XTick")) { a->ticksX = versVecteur(v); return true; }
    if (memeNom(nom, "YTick")) { a->ticksY = versVecteur(v); return true; }
    if (memeNom(nom, "XTickLabel")) { a->etiquettesTicksX = versTextes(v); return true; }
    if (memeNom(nom, "YTickLabel")) { a->etiquettesTicksY = versTextes(v); return true; }
    if (memeNom(nom, "XLim")) {
        auto b = versVecteur(v);
        if (b.size() != 2) erreur("MATLAB:hg:shaped_arrays", "XLim must have two elements.");
        a->xmin = b[0]; a->xmax = b[1]; a->limitesManuellesX = true;
        return true;
    }
    if (memeNom(nom, "YLim")) {
        auto b = versVecteur(v);
        if (b.size() != 2) erreur("MATLAB:hg:shaped_arrays", "YLim must have two elements.");
        a->ymin = b[0]; a->ymax = b[1]; a->limitesManuellesY = true;
        return true;
    }
    if (memeNom(nom, "XScale")) { a->logX = v.versTexte() == "log"; return true; }
    if (memeNom(nom, "YScale")) { a->logY = v.versTexte() == "log"; return true; }
    if (memeNom(nom, "XGrid") || memeNom(nom, "YGrid")) { a->grille = vraiDe(v); return true; }
    if (memeNom(nom, "Box")) { a->boite = vraiDe(v); return true; }
    if (memeNom(nom, "FontSize")) { a->taillePolice = v.scal(); return true; }
    if (memeNom(nom, "Title")) { a->titre = v.versTexte(); return true; }
    if (memeNom(nom, "XLabel")) { a->etiquetteX = v.versTexte(); return true; }
    if (memeNom(nom, "YLabel")) { a->etiquetteY = v.versTexte(); return true; }
    erreur("MATLAB:hg:InvalidProperty",
           "Unrecognized property '" + nom + "' for class 'Axes'.");
}

bool ecrireFigure(Interpreteur& it, const Valeur& p, const std::string& nom,
                  const Valeur& v) {
    auto f = figureDe(it, p);
    if (memeNom(nom, "Name")) { f->nom = v.versTexte(); return true; }
    if (memeNom(nom, "Position")) {
        auto b = versVecteur(v);
        if (b.size() == 4) { f->largeur = (int)b[2]; f->hauteur = (int)b[3]; }
        return true;
    }
    erreur("MATLAB:hg:InvalidProperty",
           "Unrecognized property '" + nom + "' for class 'Figure'.");
}

// --- lecture -------------------------------------------------------------

// Les limites d'un axe qu'on n'a pas fixees sont celles des donnees : c'est
// ce que rend MATLAB, et non les 0..1 d'un axe vide.
void limitesDonnees(const Axes& a, double& xmin, double& xmax, double& ymin, double& ymax) {
    xmin = ymin = 1e308;
    xmax = ymax = -1e308;
    bool vu = false;
    for (const auto& serie : a.series) {
        for (double v : serie.x) { xmin = std::min(xmin, v); xmax = std::max(xmax, v); vu = true; }
        for (double v : serie.y) { ymin = std::min(ymin, v); ymax = std::max(ymax, v); vu = true; }
    }
    if (!vu) { xmin = 0; xmax = 1; ymin = 0; ymax = 1; }
    if (!(xmax > xmin)) { xmin -= 0.5; xmax += 0.5; }
    if (!(ymax > ymin)) { ymin -= 0.5; ymax += 0.5; }
    if (a.limitesManuellesX) { xmin = a.xmin; xmax = a.xmax; }
    if (a.limitesManuellesY) { ymin = a.ymin; ymax = a.ymax; }
}

bool lireAxes(Interpreteur& it, const Valeur& p, const std::string& nom, Valeur& sortie) {
    auto a = axesDe(it, p);
    if (memeNom(nom, "XTick")) { sortie = depuisVecteur(a->ticksX); return true; }
    if (memeNom(nom, "YTick")) { sortie = depuisVecteur(a->ticksY); return true; }
    if (memeNom(nom, "XLim") || memeNom(nom, "YLim")) {
        double xmin, xmax, ymin, ymax;
        limitesDonnees(*a, xmin, xmax, ymin, ymax);
        sortie = memeNom(nom, "XLim") ? Valeur::ligne({xmin, xmax})
                                      : Valeur::ligne({ymin, ymax});
        return true;
    }
    if (memeNom(nom, "XScale")) {
        sortie = Valeur::texte(a->logX ? "log" : "linear");
        return true;
    }
    if (memeNom(nom, "YScale")) {
        sortie = Valeur::texte(a->logY ? "log" : "linear");
        return true;
    }
    if (memeNom(nom, "XGrid") || memeNom(nom, "YGrid")) { sortie = marche(a->grille); return true; }
    if (memeNom(nom, "Box")) { sortie = marche(a->boite); return true; }
    if (memeNom(nom, "FontSize")) { sortie = Valeur::scalaire(a->taillePolice); return true; }
    if (memeNom(nom, "Title")) { sortie = Valeur::texte(a->titre); return true; }
    if (memeNom(nom, "XLabel")) { sortie = Valeur::texte(a->etiquetteX); return true; }
    if (memeNom(nom, "YLabel")) { sortie = Valeur::texte(a->etiquetteY); return true; }
    if (memeNom(nom, "Type")) { sortie = Valeur::texte("axes"); return true; }
    return false;
}

bool lireFigure(Interpreteur& it, const Valeur& p, const std::string& nom, Valeur& sortie) {
    auto f = figureDe(it, p);
    if (memeNom(nom, "Name")) { sortie = Valeur::texte(f->nom); return true; }
    if (memeNom(nom, "Number")) { sortie = Valeur::scalaire(f->numero); return true; }
    if (memeNom(nom, "Position")) {
        sortie = Valeur::ligne({0.0, 0.0, (double)f->largeur, (double)f->hauteur});
        return true;
    }
    if (memeNom(nom, "Type")) { sortie = Valeur::texte("figure"); return true; }
    return false;
}

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)

// set(poignee, 'Nom', valeur, ...) — la forme historique, toujours en usage.
FONCTION(fnSetPoignee) {
    (void)nargout;
    if (args.empty()) return {};
    const Valeur& p = args[0];
    bool axes = estPoignee(p, CLASSE_AXES);
    bool figure = estPoignee(p, CLASSE_FIGURE);
    if (!axes && !figure) return {};
    for (std::size_t k = 1; k + 1 < args.size(); k += 2) {
        std::string nom = args[k].versTexte();
        if (axes) ecrireAxes(it, p, nom, args[k + 1]);
        else ecrireFigure(it, p, nom, args[k + 1]);
    }
    return {};
}

FONCTION(fnGetPoignee) {
    (void)nargout;
    if (args.size() < 2) return {Valeur::vide()};
    const Valeur& p = args[0];
    std::string nom = args[1].versTexte();
    Valeur sortie;
    if (estPoignee(p, CLASSE_AXES) && lireAxes(it, p, nom, sortie)) return {sortie};
    if (estPoignee(p, CLASSE_FIGURE) && lireFigure(it, p, nom, sortie)) return {sortie};
    return {Valeur::vide()};
}

}  // namespace

Valeur poigneeAxesCourants(Interpreteur& it) {
    auto f = figureCourante(it);
    if (f->axes.empty()) axesCourants(it);
    return poignee(CLASSE_AXES, f->numero, f->axeCourant);
}

Valeur poigneeFigureCourante(Interpreteur& it) {
    auto f = figureCourante(it);
    return poignee(CLASSE_FIGURE, f->numero, 0);
}

void enregistrerPoigneesGraphiques(Interpreteur& it) {
    crochetEcrirePropriete = [](Interpreteur& moteur, const Valeur& objet,
                                const std::string& nom, const Valeur& valeur) {
        if (estPoignee(objet, CLASSE_AXES)) return ecrireAxes(moteur, objet, nom, valeur);
        if (estPoignee(objet, CLASSE_FIGURE)) return ecrireFigure(moteur, objet, nom, valeur);
        return false;
    };
    crochetLirePropriete = [](Interpreteur& moteur, const Valeur& objet,
                              const std::string& nom, Valeur& sortie) {
        if (estPoignee(objet, CLASSE_AXES)) return lireAxes(moteur, objet, nom, sortie);
        if (estPoignee(objet, CLASSE_FIGURE)) return lireFigure(moteur, objet, nom, sortie);
        return false;
    };
    it.enregistrer("set", fnSetPoignee, "graphique",
                   "set  Ecrit une propriete d'une poignee graphique.");
    it.enregistrer("get", fnGetPoignee, "graphique",
                   "get  Lit une propriete d'une poignee graphique.");
}

}  // namespace matlibre
