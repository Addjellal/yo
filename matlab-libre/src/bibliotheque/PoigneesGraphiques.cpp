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
// Une courbe : ce que rend « h = plot(x,y) ». Elle designe sa figure, son
// axe et son identifiant de serie.
const char* CLASSE_LIGNE = "matlab.graphics.chart.primitive.Line";
// La legende et la barre de couleurs sont des objets a part dans MATLAB,
// et il le faut : leur chaine n'est pas celle du titre. Confondues avec
// un texte d'axe, « set(l,'String',...) » ecrasait le titre de l'axe.
const char* CLASSE_LEGENDE = "matlab.graphics.illustration.Legend";
const char* CLASSE_BARRE = "matlab.graphics.illustration.ColorBar";

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
    if (std::string(cible) == "legend") {
        v.nomObjet = CLASSE_LEGENDE;
    } else if (std::string(cible) == "colorbar") {
        v.nomObjet = CLASSE_BARRE;
    } else {
        v.nomObjet = CLASSE_TEXTE;
    }
    return v;
}

Valeur poigneeLigneInterne(int figure, int axe, int serie, bool texte) {
    Valeur v = Valeur::structureVide();
    v.poserChamp("NumeroFigure", Valeur::scalaire(figure));
    v.poserChamp("NumeroAxe", Valeur::scalaire(axe));
    v.poserChamp("NumeroSerie", Valeur::scalaire(serie));
    v.classe = Classe::Objet;
    v.nomObjet = texte ? CLASSE_TEXTE : CLASSE_LIGNE;
    return v;
}

// Plusieurs courbes : « h = plot(x, Y) » rend un tableau de poignees en
// colonne, comme MATLAB, et non une cellule — « h(2) » doit designer une
// courbe, non une cellule qui en contient une.
Valeur poigneeLignesInterne(int figure, int axe, const std::vector<int>& series) {
    Valeur v = Valeur::structureVide();
    v.dims = {(int)series.size(), 1};
    for (std::size_t k = 0; k < series.size(); ++k) {
        v.poserChamp("NumeroFigure", Valeur::scalaire(figure), k);
        v.poserChamp("NumeroAxe", Valeur::scalaire(axe), k);
        v.poserChamp("NumeroSerie", Valeur::scalaire(series[k]), k);
    }
    v.classe = Classe::Objet;
    v.nomObjet = CLASSE_LIGNE;
    return v;
}

bool estPoignee(const Valeur& v, const char* classe) {
    return v.classe == Classe::Objet && v.nomObjet == classe;
}

// Deux sortes de poignees portent le nom de classe d'un texte : celle
// d'un titre ou d'une etiquette d'axe, qui designe sa cible par un nom,
// et celle d'un texte pose dans l'axe, qui est range comme une serie et
// porte donc un numero. C'est ce champ qui les distingue — le nom de
// classe, lui, est le meme sous MATLAB, et doit l'etre ici aussi.
bool estPoigneeSerie(const Valeur& v) {
    if (v.classe != Classe::Objet) return false;
    if (v.nomObjet != CLASSE_LIGNE && v.nomObjet != CLASSE_TEXTE) return false;
    return v.aChamp("NumeroSerie");
}

bool estPoigneeEtiquette(const Valeur& v) {
    return estPoignee(v, CLASSE_TEXTE) && !v.aChamp("NumeroSerie");
}

bool estPoigneeLegende(const Valeur& v) {
    return estPoignee(v, CLASSE_LEGENDE);
}

bool estPoigneeBarre(const Valeur& v) {
    return estPoignee(v, CLASSE_BARRE);
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

Serie* serieDe(Interpreteur& it, const Valeur& p) {
    auto a = axesDe(it, p);
    int identifiant = (int)p.champ("NumeroSerie", 0).scal();
    for (auto& s : a->series)
        if (s.identifiant == identifiant) return &s;
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
    if (memeNom(nom, "XDir")) { a->xInverse = v.versTexte() == "reverse"; return true; }
    if (memeNom(nom, "YDir")) { a->yInverse = v.versTexte() == "reverse"; return true; }
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

// Une courbe : ce que « set(h,'LineWidth',2) » et « h.Color = 'r' »
// atteignent. Les donnees elles-memes — XData, YData — s'ecrivent aussi,
// ce dont se servent les animations.
bool ecrireLigne(Interpreteur& it, const Valeur& p, const std::string& nom,
                 const Valeur& v) {
    Serie* s = serieDe(it, p);
    if (memeNom(nom, "XData")) {
        s->x = versVecteur(v);
        if (!s->xVraies.empty()) s->xVraies = s->x;
        return true;
    }
    if (memeNom(nom, "YData")) {
        s->y = versVecteur(v);
        if (!s->yVraies.empty()) s->yVraies = s->y;
        return true;
    }
    if (memeNom(nom, "ZData")) { s->z = versVecteur(v); return true; }
    if (memeNom(nom, "Color")) {
        std::string couleur = couleurDepuisValeur(v);
        if (!couleur.empty()) s->couleur = couleur;
        return true;
    }
    if (memeNom(nom, "LineWidth")) { s->epaisseur = v.scal(); return true; }
    if (memeNom(nom, "LineStyle")) { s->style = v.versTexte(); return true; }
    if (memeNom(nom, "Marker")) { s->marqueur = v.versTexte(); return true; }
    if (memeNom(nom, "DisplayName")) { s->etiquette = v.versTexte(); return true; }
    // Un texte pose par « text(x,y,'ici') » : sa chaine et sa taille.
    if (memeNom(nom, "String")) { s->legendeConstante = v.versTexte(); return true; }
    if (memeNom(nom, "FontSize")) { s->taillePoliceTexte = v.scal(); return true; }
    if (memeNom(nom, "Position")) {
        auto b = versVecteur(v);
        if (b.size() >= 2) { s->x = {b[0]}; s->y = {b[1]}; }
        return true;
    }
    if (memeNom(nom, "HorizontalAlignment")) {
        std::string a = v.versTexte();
        s->alignement = a.empty() ? 'l' : (a[0] == 'c' ? 'c' : (a[0] == 'r' ? 'r' : 'l'));
        return true;
    }
    // Ce que le rendu de MatLibre n'emploie pas encore, mais qu'un script
    // pose couramment : accepte sans effet plutot que de s'arreter.
    if (memeNom(nom, "MarkerSize") || memeNom(nom, "MarkerFaceColor") ||
        memeNom(nom, "MarkerEdgeColor") || memeNom(nom, "Visible") ||
        memeNom(nom, "Tag") || memeNom(nom, "UserData"))
        return true;
    erreur("MATLAB:hg:InvalidProperty",
           "Unrecognized property '" + nom + "' for class 'Line'.");
}

bool lireLigne(Interpreteur& it, const Valeur& p, const std::string& nom, Valeur& sortie) {
    Serie* s = serieDe(it, p);
    // Une courbe de l'espace garde ses vraies coordonnees a cote de la
    // projection : ce sont elles qu'on rend.
    if (memeNom(nom, "XData")) {
        sortie = depuisVecteur(s->xVraies.empty() ? s->x : s->xVraies);
        return true;
    }
    if (memeNom(nom, "YData")) {
        sortie = depuisVecteur(s->yVraies.empty() ? s->y : s->yVraies);
        return true;
    }
    if (memeNom(nom, "ZData")) { sortie = depuisVecteur(s->z); return true; }
    if (memeNom(nom, "Color")) { sortie = Valeur::texte(s->couleur); return true; }
    if (memeNom(nom, "LineWidth")) { sortie = Valeur::scalaire(s->epaisseur); return true; }
    if (memeNom(nom, "LineStyle")) { sortie = Valeur::texte(s->style); return true; }
    if (memeNom(nom, "Marker")) {
        sortie = Valeur::texte(s->marqueur.empty() ? "none" : s->marqueur);
        return true;
    }
    if (memeNom(nom, "DisplayName")) { sortie = Valeur::texte(s->etiquette); return true; }
    if (memeNom(nom, "String")) { sortie = Valeur::texte(s->legendeConstante); return true; }
    if (memeNom(nom, "FontSize")) {
        sortie = Valeur::scalaire(s->taillePoliceTexte > 0 ? s->taillePoliceTexte : 11.0);
        return true;
    }
    if (memeNom(nom, "Position")) {
        double x = s->x.empty() ? 0 : s->x[0];
        double y = s->y.empty() ? 0 : s->y[0];
        sortie = Valeur::ligne({x, y, 0.0});
        return true;
    }
    if (memeNom(nom, "Type")) {
        sortie = Valeur::texte(s->genre == GenreTrace::Texte ? "text" : "line");
        return true;
    }
    if (memeNom(nom, "Parent")) {
        sortie = poignee(CLASSE_AXES, (int)p.champ("NumeroFigure", 0).scal(),
                         (int)p.champ("NumeroAxe", 0).scal());
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
    if (memeNom(nom, "XDir")) {
        sortie = Valeur::texte(a->xInverse ? "reverse" : "normal");
        return true;
    }
    if (memeNom(nom, "YDir")) {
        sortie = Valeur::texte(a->yInverse ? "reverse" : "normal");
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
    // Le parent d'un axe est sa figure, et une figure est une poignee :
    // rendre son numero obligeait a savoir de quel cote de l'arbre on se
    // trouvait pour lire la suite.
    if (memeNom(nom, "Parent")) {
        sortie = poignee(CLASSE_FIGURE, (int)p.champ("NumeroFigure", 0).scal(), 0);
        return true;
    }
    // « get(gca,'Children') » : les courbes de l'axe, la derniere tracee
    // en tete, comme MATLAB les empile.
    if (memeNom(nom, "Children")) {
        std::vector<int> series;
        for (auto it2 = a->series.rbegin(); it2 != a->series.rend(); ++it2)
            series.push_back(it2->identifiant);
        sortie = poigneeLignesInterne((int)p.champ("NumeroFigure", 0).scal(),
                                      (int)p.champ("NumeroAxe", 0).scal(), series);
        return true;
    }
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
    // « get(gcf,'Children') » : les axes de la figure, le dernier cree en
    // tete, comme MATLAB les empile. Sans eux, un parcours de l'arbre
    // graphique s'arretait a la figure.
    if (memeNom(nom, "Children")) {
        std::vector<int> identifiants;
        for (auto axe = f->axes.rbegin(); axe != f->axes.rend(); ++axe)
            if (*axe) identifiants.push_back((*axe)->identifiant);
        Valeur v = Valeur::structureVide();
        v.dims = {(int)identifiants.size(), 1};
        for (std::size_t k = 0; k < identifiants.size(); ++k) {
            v.poserChamp("NumeroFigure", Valeur::scalaire(f->numero), k);
            v.poserChamp("NumeroAxe", Valeur::scalaire(identifiants[k]), k);
        }
        v.classe = Classe::Objet;
        v.nomObjet = CLASSE_AXES;
        sortie = v;
        return true;
    }
    return false;
}

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)

// set(poignee, 'Nom', valeur, ...) — la forme historique, toujours en usage.
// Déclarées ici : SET les appelle avant que le fichier ne les définisse.
bool lireLegende(Interpreteur& it, const Valeur& p, const std::string& nom, Valeur& sortie);
bool ecrireLegende(Interpreteur& it, const Valeur& p, const std::string& nom, const Valeur& v);
bool lireBarre(Interpreteur& it, const Valeur& p, const std::string& nom, Valeur& sortie);
bool ecrireBarre(Interpreteur& it, const Valeur& p, const std::string& nom, const Valeur& v);

FONCTION(fnSetPoignee) {
    (void)nargout;
    if (args.empty()) return {};
    const Valeur& p = args[0];
    bool axes = estPoignee(p, CLASSE_AXES);
    bool figure = estPoignee(p, CLASSE_FIGURE);
    // Une poignee de texte pose dans l'axe porte le nom de classe d'un
    // texte mais se traite comme une serie : c'est « NumeroSerie » qui
    // tranche, non le nom.
    bool texte = estPoigneeEtiquette(p);
    bool ligne = estPoigneeSerie(p);
    bool legende = estPoigneeLegende(p);
    bool barre = estPoigneeBarre(p);
    if (!axes && !figure && !texte && !ligne && !legende && !barre) return {};
    // « set(h, ...) » sur un tableau de poignees ecrit sur chacune.
    std::size_t combien = ligne ? std::max<std::size_t>(1, p.nelem()) : 1;
    for (std::size_t e = 0; e < combien; ++e) {
        Valeur cible = p;
        if (ligne && combien > 1) {
            cible = Valeur::structureVide();
            cible.poserChamp("NumeroFigure", p.champ("NumeroFigure", e));
            cible.poserChamp("NumeroAxe", p.champ("NumeroAxe", e));
            cible.poserChamp("NumeroSerie", p.champ("NumeroSerie", e));
            cible.classe = Classe::Objet;
            cible.nomObjet = p.nomObjet;
        }
        for (std::size_t k = 1; k + 1 < args.size(); k += 2) {
            std::string nom = args[k].versTexte();
            if (axes) ecrireAxes(it, cible, nom, args[k + 1]);
            else if (texte) ecrireTexte(it, cible, nom, args[k + 1]);
            else if (legende) ecrireLegende(it, cible, nom, args[k + 1]);
            else if (barre) ecrireBarre(it, cible, nom, args[k + 1]);
            else if (ligne) ecrireLigne(it, cible, nom, args[k + 1]);
            else ecrireFigure(it, cible, nom, args[k + 1]);
        }
    }
    return {};
}

// La legende a ses propres proprietes : sa chaine est la liste de ses
// entrees, non le titre de l'axe. « String » y rend une cellule quand il
// y a plusieurs entrees, comme dans MATLAB.
bool lireLegende(Interpreteur& it, const Valeur& p, const std::string& nom, Valeur& sortie) {
    auto a = axesDe(it, p);
    if (memeNom(nom, "String")) {
        if (a->legende.size() == 1) {
            sortie = Valeur::texte(a->legende[0]);
        } else {
            sortie = Valeur::celluleDims({1, (int)a->legende.size()});
            for (std::size_t k = 0; k < a->legende.size(); ++k)
                sortie.cellules[k] = Valeur::texte(a->legende[k]);
        }
        return true;
    }
    if (memeNom(nom, "Visible")) {
        sortie = Valeur::texte(a->legendeVisible ? "on" : "off");
        return true;
    }
    if (memeNom(nom, "FontSize")) {
        sortie = Valeur::scalaire(a->taillePolice);
        return true;
    }
    if (memeNom(nom, "Location") || memeNom(nom, "Box") ||
        memeNom(nom, "Orientation") || memeNom(nom, "Interpreter")) {
        sortie = Valeur::texte("");
        return true;
    }
    return false;
}

bool ecrireLegende(Interpreteur& it, const Valeur& p, const std::string& nom,
                   const Valeur& v) {
    auto a = axesDe(it, p);
    if (memeNom(nom, "String")) {
        a->legende.clear();
        if (v.classe == Classe::Cellule) {
            for (const auto& c : v.cellules) a->legende.push_back(c.versTexte());
        } else if (v.classe == Classe::Chaine && v.nelem() > 1) {
            for (const auto& s : v.chaines) a->legende.push_back(s);
        } else {
            a->legende.push_back(v.versTexte());
        }
        return true;
    }
    if (memeNom(nom, "Visible")) {
        a->legendeVisible = v.versTexte() != "off";
        return true;
    }
    if (memeNom(nom, "FontSize")) {
        a->taillePolice = v.scal();
        return true;
    }
    // Les autres proprietes sont acceptees sans effet : le rendu n'en a
    // pas l'usage, et un programme qui les pose ne doit pas s'arreter.
    if (memeNom(nom, "Location") || memeNom(nom, "Box") ||
        memeNom(nom, "Orientation") || memeNom(nom, "Interpreter") ||
        memeNom(nom, "Color") || memeNom(nom, "Position") ||
        memeNom(nom, "NumColumns") || memeNom(nom, "AutoUpdate"))
        return true;
    erreur("MATLAB:hg:InvalidProperty",
           "Unrecognized property '" + nom + "' for class 'Legend'.");
}

// La barre de couleurs n'est pas encore dessinee : ses proprietes se
// posent et se relisent sans effet sur le trace, ce qui suffit a ce
// qu'un programme qui la regle ne s'arrete pas.
bool lireBarre(Interpreteur& it, const Valeur& p, const std::string& nom, Valeur& sortie) {
    // La poignee designe bien un axe existant : le verifier ici fait que
    // lire une propriete d'une barre supprimee echoue comme il se doit.
    axesDe(it, p);
    if (memeNom(nom, "Visible")) {
        sortie = Valeur::texte("on");
        return true;
    }
    if (memeNom(nom, "Location") || memeNom(nom, "Label")) {
        sortie = Valeur::texte("");
        return true;
    }
    return false;
}

bool ecrireBarre(Interpreteur& it, const Valeur& p, const std::string& nom,
                 const Valeur& v) {
    (void)it; (void)p; (void)v;
    if (memeNom(nom, "Visible") ||
        memeNom(nom, "Location") || memeNom(nom, "Label") ||
        memeNom(nom, "FontSize") || memeNom(nom, "Ticks") ||
        memeNom(nom, "TickLabels"))
        return true;
    erreur("MATLAB:hg:InvalidProperty",
           "Unrecognized property '" + nom + "' for class 'ColorBar'.");
}

FONCTION(fnGetPoignee) {
    (void)nargout;
    if (args.size() < 2) return {Valeur::vide()};
    const Valeur& p = args[0];
    std::string nom = args[1].versTexte();
    Valeur sortie;
    if (estPoignee(p, CLASSE_AXES) && lireAxes(it, p, nom, sortie)) return {sortie};
    if (estPoigneeEtiquette(p) && lireTexte(it, p, nom, sortie)) return {sortie};
    if (estPoigneeLegende(p) && lireLegende(it, p, nom, sortie)) return {sortie};
    if (estPoigneeBarre(p) && lireBarre(it, p, nom, sortie)) return {sortie};
    if (estPoigneeSerie(p) && lireLigne(it, p, nom, sortie)) return {sortie};
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

Valeur poigneeLigne(int figure, int axe, int serie) {
    return poigneeLigneInterne(figure, axe, serie, false);
}

// Un texte pose dans un axe : meme poignee, mais MATLAB en nomme la
// classe autrement, et « class(h) » doit le dire.
Valeur poigneeTexteTrace(int figure, int axe, int serie) {
    return poigneeLigneInterne(figure, axe, serie, true);
}

Valeur poigneeLignes(int figure, int axe, const std::vector<int>& series) {
    return poigneeLignesInterne(figure, axe, series);
}

// Supprimer une poignee, c'est retirer du trace ce qu'elle designe : une
// serie de son axe, un axe de sa figure, une figure de la liste. Rendre
// faux laisse DELETE chercher un fichier, ce qu'il faut pour « delete
// ('vieux.txt') ».
bool supprimerGraphique(Interpreteur& moteur, const Valeur& p) {
    if (p.classe != Classe::Objet) return false;
    if (!p.aChamp("NumeroFigure")) return false;
    for (std::size_t e = 0; e < std::max<std::size_t>(p.nelem(), 1); ++e) {
        int numeroFigure = (int)p.champ("NumeroFigure", e).scal();
        auto trouve = moteur.figures.find(numeroFigure);
        if (trouve == moteur.figures.end() || !trouve->second) continue;
        auto f = trouve->second;
        if (!p.aChamp("NumeroAxe") || estPoignee(p, CLASSE_FIGURE)) {
            moteur.figures.erase(numeroFigure);
            if (!moteur.figures.count(moteur.figureCourante))
                moteur.figureCourante =
                    moteur.figures.empty() ? 0 : moteur.figures.begin()->first;
            continue;
        }
        int identifiantAxe = (int)p.champ("NumeroAxe", e).scal();
        std::shared_ptr<Axes> a;
        for (const auto& candidat : f->axes)
            if (candidat && candidat->identifiant == identifiantAxe) a = candidat;
        if (!a) continue;
        if (p.aChamp("NumeroSerie")) {
            int serie = (int)p.champ("NumeroSerie", e).scal();
            for (std::size_t k = 0; k < a->series.size(); ++k)
                if (a->series[k].identifiant == serie) {
                    a->series.erase(a->series.begin() + (long)k);
                    break;
                }
            continue;
        }
        for (std::size_t k = 0; k < f->axes.size(); ++k)
            if (f->axes[k] && f->axes[k]->identifiant == identifiantAxe) {
                f->axes.erase(f->axes.begin() + (long)k);
                break;
            }
    }
    return true;
}

void enregistrerPoigneesGraphiques(Interpreteur& it) {
    crochetEcrirePropriete = [](Interpreteur& moteur, const Valeur& objet,
                                const std::string& nom, const Valeur& valeur) {
        if (estPoignee(objet, CLASSE_AXES)) return ecrireAxes(moteur, objet, nom, valeur);
        if (estPoigneeEtiquette(objet)) return ecrireTexte(moteur, objet, nom, valeur);
        if (estPoigneeLegende(objet)) return ecrireLegende(moteur, objet, nom, valeur);
        if (estPoigneeBarre(objet)) return ecrireBarre(moteur, objet, nom, valeur);
        if (estPoigneeSerie(objet)) return ecrireLigne(moteur, objet, nom, valeur);
        if (estPoignee(objet, CLASSE_FIGURE)) return ecrireFigure(moteur, objet, nom, valeur);
        return false;
    };
    crochetLirePropriete = [](Interpreteur& moteur, const Valeur& objet,
                              const std::string& nom, Valeur& sortie) {
        if (estPoignee(objet, CLASSE_AXES)) return lireAxes(moteur, objet, nom, sortie);
        if (estPoigneeEtiquette(objet)) return lireTexte(moteur, objet, nom, sortie);
        if (estPoigneeLegende(objet)) return lireLegende(moteur, objet, nom, sortie);
        if (estPoigneeBarre(objet)) return lireBarre(moteur, objet, nom, sortie);
        if (estPoigneeSerie(objet)) return lireLigne(moteur, objet, nom, sortie);
        if (estPoignee(objet, CLASSE_FIGURE)) return lireFigure(moteur, objet, nom, sortie);
        return false;
    };
    crochetSupprimerGraphique = [](Interpreteur& moteur, const Valeur& objet) {
        return supprimerGraphique(moteur, objet);
    };
    it.enregistrer("set", fnSetPoignee, "graphique",
                   "set  Ecrit une propriete d'une poignee graphique.");
    it.enregistrer("get", fnGetPoignee, "graphique",
                   "get  Lit une propriete d'une poignee graphique.");
}

}  // namespace matlibre
