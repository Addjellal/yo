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
// Le titre et les etiquettes d'un axe sont des objets, dans MATLAB : on
// leur donne une poignee, avec le nom du texte qu'elle designe.
const char* CLASSE_TEXTE = "matlab.graphics.primitive.Text";

Valeur poignee(const char* classe, int figure, int axe) {
    Valeur v = Valeur::structureVide();
    v.poserChamp("NumeroFigure", Valeur::scalaire(figure));
    // Le champ porte l'identifiant de l'axe, pas son rang : « subplot » qui
    // efface une case ne doit pas faire pointer une poignee ailleurs.
    v.poserChamp("NumeroAxe", Valeur::scalaire(axe));
    v.classe = Classe::Objet;
    v.nomObjet = classe;
    return v;
}

Valeur poigneeTexte(int figure, int axe, const char* cible) {
    Valeur v = Valeur::structureVide();
    v.poserChamp("NumeroFigure", Valeur::scalaire(figure));
    v.poserChamp("NumeroAxe", Valeur::scalaire(axe));
    v.poserChamp("Cible", Valeur::texte(cible));
    v.classe = Classe::Objet;
    v.nomObjet = CLASSE_TEXTE;
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
    int identifiant = (int)p.champ("NumeroAxe", 0).scal();
    for (const auto& a : f->axes)
        if (a && a->identifiant == identifiant) return a;
    erreur("MATLAB:class:InvalidHandle", "Invalid or deleted object.");
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
    if (memeNom(nom, "Position") || memeNom(nom, "OuterPosition")) {
        auto b = versVecteur(v);
        if (b.size() != 4)
            erreur("MATLAB:hg:shaped_arrays", "Position must have four elements.");
        a->positionManuelle = true;
        a->posGauche = b[0];
        a->posBas = b[1];
        a->posLargeur = b[2];
        a->posHauteur = b[3];
        return true;
    }
    if (memeNom(nom, "Title")) { a->titre = v.versTexte(); return true; }
    if (memeNom(nom, "XLabel")) { a->etiquetteX = v.versTexte(); return true; }
    if (memeNom(nom, "YLabel")) { a->etiquetteY = v.versTexte(); return true; }
    if (memeNom(nom, "TitleFontSize")) { a->taillePoliceTitre = v.scal(); return true; }
    erreur("MATLAB:hg:InvalidProperty",
           "Unrecognized property '" + nom + "' for class 'Axes'.");
}

// Le titre, l'etiquette en x, celle en y : trois textes, dont on peut
// changer la chaine et la taille — c'est ce qu'on fait de « z =
// title(...) ; set(z,'FontSize',16) ».
bool ecrireTexte(Interpreteur& it, const Valeur& p, const std::string& nom,
                 const Valeur& v) {
    auto a = axesDe(it, p);
    std::string cible = p.champ("Cible", 0).versTexte();
    if (memeNom(nom, "String")) {
        std::string texte = v.versTexte();
        if (cible == "xlabel") a->etiquetteX = texte;
        else if (cible == "ylabel") a->etiquetteY = texte;
        else a->titre = texte;
        return true;
    }
    if (memeNom(nom, "FontSize")) {
        if (cible == "title") a->taillePoliceTitre = v.scal();
        else a->taillePolice = v.scal();
        return true;
    }
    // Les autres proprietes d'un texte — couleur, police, interprete —
    // sont acceptees sans effet : le rendu n'en a pas encore l'usage, et
    // un script qui les pose ne doit pas s'arreter pour autant.
    if (memeNom(nom, "Color") || memeNom(nom, "FontWeight") ||
        memeNom(nom, "FontName") || memeNom(nom, "Interpreter") ||
        memeNom(nom, "Rotation") || memeNom(nom, "HorizontalAlignment") ||
        memeNom(nom, "VerticalAlignment") || memeNom(nom, "Position"))
        return true;
    erreur("MATLAB:hg:InvalidProperty",
           "Unrecognized property '" + nom + "' for class 'Text'.");
}

bool lireTexte(Interpreteur& it, const Valeur& p, const std::string& nom, Valeur& sortie) {
    auto a = axesDe(it, p);
    std::string cible = p.champ("Cible", 0).versTexte();
    if (memeNom(nom, "String")) {
        sortie = Valeur::texte(cible == "xlabel"   ? a->etiquetteX
                               : cible == "ylabel" ? a->etiquetteY
                                                   : a->titre);
        return true;
    }
    if (memeNom(nom, "FontSize")) {
        double taille = cible == "title" && a->taillePoliceTitre > 0 ? a->taillePoliceTitre
                                                                     : a->taillePolice;
        sortie = Valeur::scalaire(taille);
        return true;
    }
    if (memeNom(nom, "Type")) {
        sortie = Valeur::texte("text");
        return true;
    }
    return false;
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

bool lireAxes(Interpreteur& it, const Valeur& p, const std::string& nom, Valeur& sortie) {
    auto a = axesDe(it, p);
    if (memeNom(nom, "XTick")) { sortie = depuisVecteur(a->ticksX); return true; }
    if (memeNom(nom, "YTick")) { sortie = depuisVecteur(a->ticksY); return true; }
    if (memeNom(nom, "XLim") || memeNom(nom, "YLim")) {
        double xmin, xmax, ymin, ymax;
        limitesAxe(*a, xmin, xmax, ymin, ymax);
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
    if (memeNom(nom, "Position") || memeNom(nom, "OuterPosition")) {
        // La position est rendue a la façon de MATLAB : gauche, bas,
        // largeur, hauteur, l'origine en bas a gauche de la figure.
        double x, y, largeur, hauteur;
        cadreAxes(*a, x, y, largeur, hauteur);
        sortie = Valeur::ligne({x, 1.0 - y - hauteur, largeur, hauteur});
        return true;
    }
    // « get(gca,'Title') » rend la poignee du texte, comme MATLAB : c'est
    // sur elle qu'on ecrit ensuite la taille de police.
    if (memeNom(nom, "Title") || memeNom(nom, "XLabel") || memeNom(nom, "YLabel")) {
        const char* cible = memeNom(nom, "XLabel")   ? "xlabel"
                            : memeNom(nom, "YLabel") ? "ylabel"
                                                     : "title";
        sortie = poigneeTexte((int)p.champ("NumeroFigure", 0).scal(),
                              (int)p.champ("NumeroAxe", 0).scal(), cible);
        return true;
    }
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
    bool texte = estPoignee(p, CLASSE_TEXTE);
    if (!axes && !figure && !texte) return {};
    for (std::size_t k = 1; k + 1 < args.size(); k += 2) {
        std::string nom = args[k].versTexte();
        if (axes) ecrireAxes(it, p, nom, args[k + 1]);
        else if (texte) ecrireTexte(it, p, nom, args[k + 1]);
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
    if (estPoignee(p, CLASSE_TEXTE) && lireTexte(it, p, nom, sortie)) return {sortie};
    if (estPoignee(p, CLASSE_FIGURE) && lireFigure(it, p, nom, sortie)) return {sortie};
    return {Valeur::vide()};
}

}  // namespace

Valeur poigneeAxesCourants(Interpreteur& it) {
    auto a = axesCourants(it);
    return poignee(CLASSE_AXES, figureCourante(it)->numero, a->identifiant);
}

Valeur poigneeTexteCourant(Interpreteur& it, const std::string& cible) {
    auto a = axesCourants(it);
    return poigneeTexte(figureCourante(it)->numero, a->identifiant, cible.c_str());
}

Valeur poigneeFigureCourante(Interpreteur& it) {
    auto f = figureCourante(it);
    return poignee(CLASSE_FIGURE, f->numero, 0);
}

void enregistrerPoigneesGraphiques(Interpreteur& it) {
    crochetEcrirePropriete = [](Interpreteur& moteur, const Valeur& objet,
                                const std::string& nom, const Valeur& valeur) {
        if (estPoignee(objet, CLASSE_AXES)) return ecrireAxes(moteur, objet, nom, valeur);
        if (estPoignee(objet, CLASSE_TEXTE)) return ecrireTexte(moteur, objet, nom, valeur);
        if (estPoignee(objet, CLASSE_FIGURE)) return ecrireFigure(moteur, objet, nom, valeur);
        return false;
    };
    crochetLirePropriete = [](Interpreteur& moteur, const Valeur& objet,
                              const std::string& nom, Valeur& sortie) {
        if (estPoignee(objet, CLASSE_AXES)) return lireAxes(moteur, objet, nom, sortie);
        if (estPoignee(objet, CLASSE_TEXTE)) return lireTexte(moteur, objet, nom, sortie);
        if (estPoignee(objet, CLASSE_FIGURE)) return lireFigure(moteur, objet, nom, sortie);
        return false;
    };
    it.enregistrer("set", fnSetPoignee, "graphique",
                   "set  Ecrit une propriete d'une poignee graphique.");
    it.enregistrer("get", fnGetPoignee, "graphique",
                   "get  Lit une propriete d'une poignee graphique.");
}

}  // namespace matlibre
