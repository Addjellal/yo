#include "matlibre/Graphique.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <climits>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <memory>
#include <sstream>

#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"

namespace matlibre {

std::shared_ptr<Axes> ajouterAxes(Figure& f) {
    auto a = std::make_shared<Axes>();
    a->identifiant = f.prochainIdentifiant++;
    f.axes.push_back(a);
    return a;
}

std::shared_ptr<Figure> figureCourante(Interpreteur& it) {
    if (it.figureCourante == 0 || !it.figures.count(it.figureCourante)) {
        int numero = it.figureCourante ? it.figureCourante : 1;
        while (it.figures.count(numero)) ++numero;
        auto f = std::make_shared<Figure>();
        f->numero = numero;
        ajouterAxes(*f);
        it.figures[numero] = f;
        it.figureCourante = numero;
    }
    return it.figures[it.figureCourante];
}

std::shared_ptr<Axes> axesCourants(Interpreteur& it) {
    auto f = figureCourante(it);
    if (f->axes.empty()) ajouterAxes(*f);
    if (f->axeCourant >= (int)f->axes.size()) f->axeCourant = 0;
    return f->axes[(std::size_t)f->axeCourant];
}

// --------------------------------------------------------------- rendu SVG

namespace {

std::string echapperXml(const std::string& s) {
    std::string r;
    for (char c : s) {
        switch (c) {
            case '<': r += "&lt;"; break;
            case '>': r += "&gt;"; break;
            case '&': r += "&amp;"; break;
            case '"': r += "&quot;"; break;
            default: r += c; break;
        }
    }
    return r;
}

struct Echelle {
    double min = 0, max = 1;
    int pixelsMin = 0, pixelsMax = 100;
    bool log = false;
    double versPixel(double v) const {
        double a = log ? std::log10(std::max(v, 1e-300)) : v;
        double lo = log ? std::log10(std::max(min, 1e-300)) : min;
        double hi = log ? std::log10(std::max(max, 1e-300)) : max;
        if (hi == lo) return (pixelsMin + pixelsMax) / 2.0;
        return pixelsMin + (a - lo) / (hi - lo) * (pixelsMax - pixelsMin);
    }
};

}  // namespace

std::vector<std::size_t> indicesVisibles(const std::vector<double>& x,
                                         const std::vector<double>& y, double xmin,
                                         double xmax, int colonnes) {
    std::size_t n = std::min(x.size(), y.size());
    std::vector<std::size_t> gardes;
    // En dessous de quatre points par colonne il n'y a rien a gagner, et le
    // trace garde exactement les points d'origine.
    if (colonnes < 2 || n <= (std::size_t)colonnes * 4 || !(xmax > xmin)) {
        gardes.reserve(n);
        for (std::size_t k = 0; k < n; ++k) gardes.push_back(k);
        return gardes;
    }
    gardes.reserve((std::size_t)colonnes * 4 + 8);
    std::size_t k = 0;
    long long colonneCourante = LLONG_MIN;
    std::size_t premier = 0, dernier = 0, bas = 0, haut = 0;
    bool ouverte = false;
    auto fermer = [&]() {
        if (!ouverte) return;
        // Premier, minimum, maximum, dernier — dans l'ordre des indices, et
        // sans doublon : c'est ce qui rend l'enveloppe a l'identique.
        std::size_t quatre[4] = {premier, bas, haut, dernier};
        std::sort(quatre, quatre + 4);
        for (int i = 0; i < 4; ++i)
            if (i == 0 || quatre[i] != quatre[i - 1]) gardes.push_back(quatre[i]);
        ouverte = false;
    };
    for (; k < n; ++k) {
        if (!std::isfinite(x[k]) || !std::isfinite(y[k])) {
            // Une coupure separe deux morceaux : elle se garde telle quelle.
            fermer();
            gardes.push_back(k);
            colonneCourante = LLONG_MIN;
            continue;
        }
        long long colonne =
            (long long)((x[k] - xmin) / (xmax - xmin) * (double)colonnes);
        if (!ouverte || colonne != colonneCourante) {
            fermer();
            colonneCourante = colonne;
            premier = dernier = bas = haut = k;
            ouverte = true;
            continue;
        }
        dernier = k;
        if (y[k] < y[bas]) bas = k;
        if (y[k] > y[haut]) haut = k;
    }
    fermer();
    return gardes;
}

namespace {

std::vector<double> graduations(double min, double max, int cible) {
    std::vector<double> t;
    if (!std::isfinite(min) || !std::isfinite(max) || max <= min) {
        t.push_back(min);
        t.push_back(max);
        return t;
    }
    double brut = (max - min) / std::max(1, cible);
    double magnitude = std::pow(10.0, std::floor(std::log10(brut)));
    double normalise = brut / magnitude;
    double pas = magnitude * (normalise < 1.5 ? 1 : normalise < 3 ? 2 : normalise < 7 ? 5 : 10);
    double debut = std::ceil(min / pas) * pas;
    for (double v = debut; v <= max + pas * 1e-6; v += pas) t.push_back(v);
    return t;
}

std::string nombreCourt(double v) {
    if (v == 0) return "0";
    double a = std::fabs(v);
    if (a >= 1e5 || a < 1e-3) return formater("%.3g", v);
    std::string s = formater("%.6g", v);
    return s;
}

// Le motif d'un trait : ce que le SVG appelle « stroke-dasharray ».
std::string motifTrait(const std::string& style) {
    if (style == "--") return " stroke-dasharray=\"8,4\"";
    if (style == ":") return " stroke-dasharray=\"2,3\"";
    if (style == "-.") return " stroke-dasharray=\"8,3,2,3\"";
    return std::string();
}

// L'etiquette d'une graduation. Sur un axe logarithmique, MATLAB ecrit les
// puissances de dix en exposant — 10 puissance moins deux, et non 0,01 ;
// le SVG le rend avec un « tspan » releve.
std::string etiquetteGraduation(double v, bool log) {
    if (log && v > 0) {
        double e = std::log10(v);
        double arrondi = std::round(e);
        if (std::fabs(e - arrondi) < 1e-9)
            return "10<tspan baseline-shift=\"super\" font-size=\"9px\">" +
                   formater("%d", (int)arrondi) + "</tspan>";
    }
    return echapperXml(nombreCourt(v));
}

}  // namespace

// « axis square » d'abord — elle change la boite —, puis « axis equal »,
// qui elargit les bornes de l'axe qui a trop de place pour que les deux
// echelles aient le meme nombre d'unites par pixel.
std::vector<double> graduationsAxe(double bas, double haut, int cible, bool log) {
    if (!log) return graduations(bas, haut, cible);
    std::vector<double> valeurs;
    double lo = std::log10(std::max(bas, 1e-300));
    double hi = std::log10(std::max(haut, 1e-300));
    if (!(hi > lo)) return valeurs;
    int premier = (int)std::ceil(lo - 1e-9), dernier = (int)std::floor(hi + 1e-9);
    int decades = dernier - premier + 1;
    if (decades >= 2) {
        // Dix décades sur trois cents pixels : une graduation sur deux, sur
        // trois… mais toujours des puissances de dix.
        int pas = 1;
        while ((decades + pas - 1) / pas > cible + 2) ++pas;
        for (int k = premier; k <= dernier; k += pas) valeurs.push_back(std::pow(10.0, k));
        return valeurs;
    }
    // Moins d'une décade : les 1, 2 et 5 qui tombent dans l'intervalle.
    for (int k = premier - 2; k <= dernier + 1; ++k)
        for (double m : {1.0, 2.0, 5.0}) {
            double v = m * std::pow(10.0, k);
            if (v >= bas * (1 - 1e-9) && v <= haut * (1 + 1e-9)) valeurs.push_back(v);
        }
    std::sort(valeurs.begin(), valeurs.end());
    return valeurs;
}

bool bornesLog(double& bas, double& haut) {
    if (haut <= 0) return false;
    if (bas <= 0) bas = haut / 1000.0;
    if (!(haut > bas)) { bas = haut / 10.0; }
    return true;
}

void couleurCarte(double t, int& r, int& v, int& b) {
    if (!(t >= 0)) t = 0;
    if (t > 1) t = 1;
    r = (int)(255 * std::min(1.0, std::max(0.0, 1.5 - std::fabs(4 * t - 3))));
    v = (int)(255 * std::min(1.0, std::max(0.0, 1.5 - std::fabs(4 * t - 2))));
    b = (int)(255 * std::min(1.0, std::max(0.0, 1.5 - std::fabs(4 * t - 1))));
}

void limitesAxe(const Axes& a, double& xmin, double& xmax, double& ymin, double& ymax) {
    xmin = ymin = INFINITY;
    xmax = ymax = -INFINITY;
    bool vu = false;
    for (const auto& s : a.series) {
        if (s.genre == GenreTrace::Constante || s.genre == GenreTrace::Texte) continue;
        for (double v : s.x) {
            if (!std::isfinite(v)) continue;
            xmin = std::min(xmin, v);
            xmax = std::max(xmax, v);
            vu = true;
        }
        for (double v : s.y) {
            if (!std::isfinite(v)) continue;
            ymin = std::min(ymin, v);
            ymax = std::max(ymax, v);
            vu = true;
        }
    }
    if (!vu || !std::isfinite(xmin)) { xmin = 0; xmax = 1; ymin = 0; ymax = 1; }
    if (!(xmax > xmin)) { xmin -= 0.5; xmax += 0.5; }
    if (!(ymax > ymin)) { ymin -= 0.5; ymax += 0.5; }
    if (a.limitesManuellesX) { xmin = a.xmin; xmax = a.xmax; }
    if (a.limitesManuellesY) { ymin = a.ymin; ymax = a.ymax; }
}

void cadreAxes(const Axes& a, double& x, double& y, double& largeur, double& hauteur) {
    if (a.positionManuelle) {
        x = a.posGauche;
        largeur = a.posLargeur;
        hauteur = a.posHauteur;
        // MATLAB compte la hauteur depuis le bas ; les deux rendus dessinent
        // depuis le haut.
        y = 1.0 - a.posBas - a.posHauteur;
        return;
    }
    int lignes = std::max(1, a.rangee), colonnes = std::max(1, a.colonne);
    int premiere = std::max(1, a.position);
    int derniere = a.positionFin > 0 ? std::max(premiere, a.positionFin) : premiere;
    int li0 = (premiere - 1) / colonnes, co0 = (premiere - 1) % colonnes;
    int li1 = (derniere - 1) / colonnes, co1 = (derniere - 1) % colonnes;
    if (co1 < co0 && li1 > li0) { co0 = 0; co1 = colonnes - 1; }
    x = (double)co0 / colonnes;
    largeur = (double)(co1 - co0 + 1) / colonnes;
    y = (double)li0 / lignes;
    hauteur = (double)(li1 - li0 + 1) / lignes;
}

bool axesSeRecouvrent(const Axes& a, const Axes& b) {
    double ax, ay, al, ah, bx, by, bl, bh;
    cadreAxes(a, ax, ay, al, ah);
    cadreAxes(b, bx, by, bl, bh);
    const double marge = 1e-6;
    return ax < bx + bl - marge && bx < ax + al - marge && ay < by + bh - marge &&
           by < ay + ah - marge;
}

void appliquerProportions(const Axes& a, int& gauche, int& droite, int& haut, int& bas,
                          double& xmin, double& xmax, double& ymin, double& ymax) {
    if (a.proportions == Axes::Proportions::Auto) return;
    if (a.proportions == Axes::Proportions::Carre) {
        int cote = std::min(droite - gauche, bas - haut);
        int centreX = (gauche + droite) / 2, centreY = (haut + bas) / 2;
        gauche = centreX - cote / 2;
        droite = gauche + cote;
        haut = centreY - cote / 2;
        bas = haut + cote;
        return;
    }
    double largeur = droite - gauche, hauteur = bas - haut;
    if (largeur <= 0 || hauteur <= 0) return;
    double echelle = std::max((xmax - xmin) / largeur, (ymax - ymin) / hauteur);
    if (!(echelle > 0)) return;
    double cx = (xmin + xmax) / 2, cy = (ymin + ymax) / 2;
    double demiX = echelle * largeur / 2, demiY = echelle * hauteur / 2;
    xmin = cx - demiX;
    xmax = cx + demiX;
    ymin = cy - demiY;
    ymax = cy + demiY;
}

// ------------------------------------------------------------------ textes

Interprete interpreteDepuisTexte(const std::string& valeur, const std::string& classe) {
    std::string bas = valeur;
    for (auto& c : bas) c = (char)std::tolower((unsigned char)c);
    if (bas == "tex") return Interprete::Tex;
    if (bas == "none") return Interprete::Aucun;
    if (bas == "latex") return Interprete::Latex;
    erreur("MATLAB:datatypes:InvalidEnumValueFor",
           "Error setting property 'Interpreter' of class '" + classe + "':\n'" + valeur +
               "' is not a valid value. Use one of these values: "
               "'none' | 'tex' | 'latex'.");
}

const char* nomInterprete(Interprete interprete) {
    switch (interprete) {
        case Interprete::Aucun: return "none";
        case Interprete::Latex: return "latex";
        case Interprete::Tex: break;
    }
    return "tex";
}

namespace {

struct SymboleTeX {
    const char* nom;
    const char* texte;
};

// Les commandes de l'interprete TeX de MATLAB, et ce qu'elles ecrivent.
const SymboleTeX SYMBOLES_TEX[] = {
    {"alpha", "α"}, {"beta", "β"}, {"gamma", "γ"}, {"delta", "δ"},
    {"epsilon", "ε"}, {"zeta", "ζ"}, {"eta", "η"}, {"theta", "θ"},
    {"vartheta", "ϑ"}, {"iota", "ι"}, {"kappa", "κ"},
    {"lambda", "λ"}, {"mu", "μ"}, {"nu", "ν"}, {"xi", "ξ"},
    {"pi", "π"}, {"varpi", "ϖ"}, {"rho", "ρ"}, {"sigma", "σ"},
    {"varsigma", "ς"}, {"tau", "τ"}, {"upsilon", "υ"}, {"phi", "φ"},
    {"chi", "χ"}, {"psi", "ψ"}, {"omega", "ω"}, {"Gamma", "Γ"},
    {"Delta", "Δ"}, {"Theta", "Θ"}, {"Lambda", "Λ"}, {"Xi", "Ξ"},
    {"Pi", "Π"}, {"Sigma", "Σ"}, {"Upsilon", "ϒ"}, {"Phi", "Φ"},
    {"Psi", "Ψ"}, {"Omega", "Ω"}, {"sim", "∼"}, {"leq", "≤"},
    {"geq", "≥"}, {"neq", "≠"}, {"infty", "∞"}, {"pm", "±"},
    {"times", "×"}, {"div", "÷"}, {"cdot", "·"}, {"circ", "∘"},
    {"bullet", "•"}, {"ldots", "…"}, {"approx", "≈"},
    {"equiv", "≡"}, {"propto", "∝"}, {"cong", "≅"},
    {"partial", "∂"}, {"nabla", "∇"}, {"int", "∫"}, {"surd", "√"},
    {"forall", "∀"}, {"exists", "∃"}, {"in", "∈"}, {"ni", "∋"},
    {"cap", "∩"}, {"cup", "∪"}, {"subset", "⊂"}, {"supset", "⊃"},
    {"subseteq", "⊆"}, {"supseteq", "⊇"}, {"oplus", "⊕"},
    {"otimes", "⊗"}, {"oslash", "⊘"}, {"wedge", "∧"}, {"vee", "∨"},
    {"neg", "¬"}, {"perp", "⊥"}, {"angle", "∠"}, {"ast", "∗"},
    {"prime", "′"}, {"mid", "|"}, {"aleph", "ℵ"}, {"Re", "ℜ"},
    {"Im", "ℑ"}, {"wp", "℘"}, {"o", "ø"}, {"copyright", "©"},
    {"leftarrow", "←"}, {"rightarrow", "→"}, {"uparrow", "↑"},
    {"downarrow", "↓"}, {"leftrightarrow", "↔"}, {"Leftarrow", "⇐"},
    {"Rightarrow", "⇒"}, {"lceil", "⌈"}, {"rceil", "⌉"},
    {"lfloor", "⌊"}, {"rfloor", "⌋"}, {"langle", "⟨"},
    {"rangle", "⟩"}, {"clubsuit", "♣"}, {"diamondsuit", "♦"},
    {"heartsuit", "♥"}, {"spadesuit", "♠"},
};

struct EtatTeX {
    double echelle = 1.0, decalage = 0.0;
    bool gras = false, italique = false;
};

void ajouterMorceau(std::vector<MorceauTexte>& morceaux, const std::string& texte,
                    const EtatTeX& etat) {
    if (texte.empty()) return;
    if (!morceaux.empty()) {
        MorceauTexte& dernier = morceaux.back();
        if (dernier.echelle == etat.echelle && dernier.decalage == etat.decalage &&
            dernier.gras == etat.gras && dernier.italique == etat.italique) {
            dernier.texte += texte;
            return;
        }
    }
    MorceauTexte m;
    m.texte = texte;
    m.echelle = etat.echelle;
    m.decalage = etat.decalage;
    m.gras = etat.gras;
    m.italique = etat.italique;
    morceaux.push_back(m);
}

// Le nombre d'octets du caractere UTF-8 qui commence en k : un indice porte
// sur un caractere, et « x_é » ne doit pas couper le « é » en deux.
std::size_t longueurCaractere(const std::string& s, std::size_t k) {
    unsigned char c = (unsigned char)s[k];
    std::size_t n = 1;
    if ((c >> 5) == 0x6) n = 2;
    else if ((c >> 4) == 0xE) n = 3;
    else if ((c >> 3) == 0x1E) n = 4;
    return std::min(n, s.size() - k);
}

// Une commande, « \alpha » ou « \bf » ; k est sur la barre oblique.
void lireCommandeTeX(const std::string& s, std::size_t& k, EtatTeX& etat, bool latex,
                     std::vector<MorceauTexte>& morceaux) {
    std::size_t debut = k + 1, fin = debut;
    while (fin < s.size() && std::isalpha((unsigned char)s[fin])) ++fin;
    if (fin == debut) {
        // Une barre suivie d'un signe : les echappements « \_ », « \{ »...
        char signe = debut < s.size() ? s[debut] : '\0';
        if (signe != '\0' && std::strchr("_^{}\\$", signe) != nullptr) {
            ajouterMorceau(morceaux, std::string(1, signe), etat);
            k = debut + 1;
        } else if (signe == '0') {
            ajouterMorceau(morceaux, "∅", etat);
            k = debut + 1;
        } else {
            if (!latex) ajouterMorceau(morceaux, "\\", etat);
            k = debut;
        }
        return;
    }
    std::string nom = s.substr(debut, fin - debut);
    k = fin;
    if (nom == "bf") {
        etat.gras = true;
        return;
    }
    if (nom == "it" || nom == "sl") {
        etat.italique = true;
        return;
    }
    if (nom == "rm") {
        etat.gras = etat.italique = false;
        return;
    }
    if (nom == "color" || nom == "fontname" || nom == "fontsize") {
        // Le rendu ne suit ni la couleur ni la police ; leur parametre ne
        // doit pas s'ecrire pour autant.
        for (char ouvrante : {'[', '{'}) {
            if (k >= s.size() || s[k] != ouvrante) continue;
            std::size_t f = s.find(ouvrante == '[' ? ']' : '}', k);
            k = f == std::string::npos ? s.size() : f + 1;
        }
        return;
    }
    for (const auto& symbole : SYMBOLES_TEX)
        if (nom == symbole.nom) {
            ajouterMorceau(morceaux, symbole.texte, etat);
            return;
        }
    // Une commande inconnue s'ecrit telle quelle sous TeX, comme dans
    // MATLAB. Sous LaTeX, ou elle sert surtout de mise en forme — \mathrm,
    // \text —, on n'en garde que l'argument.
    if (!latex) ajouterMorceau(morceaux, "\\" + nom, etat);
}

// L'analyse tient ses groupes dans une pile, et non dans la pile d'appels :
// un texte de mille accolades ouvrantes ne doit pas faire tomber le
// programme.
std::vector<MorceauTexte> decouperTexteTeX(const std::string& s, bool latex) {
    std::vector<MorceauTexte> morceaux;
    std::vector<EtatTeX> pile(1);
    std::size_t k = 0;
    while (k < s.size()) {
        char c = s[k];
        if (c == '{') {
            EtatTeX copie = pile.back();
            pile.push_back(copie);
            ++k;
        } else if (c == '}' && pile.size() > 1) {
            pile.pop_back();
            ++k;
        } else if (c == '_' || c == '^') {
            // Un exposant monte de 0,4 de la taille courante, un indice
            // descend de 0,25 ; tous deux s'ecrivent aux trois quarts.
            EtatTeX deplace = pile.back();
            deplace.decalage += (c == '^' ? 0.4 : -0.25) * deplace.echelle;
            deplace.echelle *= 0.75;
            ++k;
            if (k >= s.size()) break;
            if (s[k] == '{') {
                pile.push_back(deplace);
                ++k;
            } else if (s[k] == '\\') {
                lireCommandeTeX(s, k, deplace, latex, morceaux);
            } else {
                std::size_t n = longueurCaractere(s, k);
                ajouterMorceau(morceaux, s.substr(k, n), deplace);
                k += n;
            }
        } else if (c == '\\') {
            lireCommandeTeX(s, k, pile.back(), latex, morceaux);
        } else {
            std::size_t n = longueurCaractere(s, k);
            ajouterMorceau(morceaux, s.substr(k, n), pile.back());
            k += n;
        }
    }
    return morceaux;
}

}  // namespace

std::vector<MorceauTexte> decouperTexte(const std::string& texte, Interprete interprete) {
    if (interprete == Interprete::Aucun) {
        std::vector<MorceauTexte> seul;
        if (!texte.empty()) {
            MorceauTexte m;
            m.texte = texte;
            seul.push_back(m);
        }
        return seul;
    }
    if (interprete == Interprete::Tex) return decouperTexteTeX(texte, false);
    // LaTeX : les dollars ouvrent et ferment le mode mathematique, dont les
    // indices et les lettres grecques s'ecrivent comme en TeX. Le reste de
    // LaTeX — fractions, racines — n'est pas compose.
    std::string sansDollars;
    for (std::size_t k = 0; k < texte.size(); ++k) {
        if (texte[k] == '\\' && k + 1 < texte.size()) {
            sansDollars += texte[k];
            sansDollars += texte[++k];
        } else if (texte[k] != '$') {
            sansDollars += texte[k];
        }
    }
    return decouperTexteTeX(sansDollars, true);
}

// ----------------------------------------------------------------- legende

std::vector<EntreeLegende> entreesLegende(const Axes& a) {
    std::vector<EntreeLegende> entrees;
    if (!a.legendeVisible) return entrees;
    std::size_t libelle = 0;
    for (const auto& s : a.series) {
        if (s.genre == GenreTrace::Texte) continue;
        EntreeLegende e;
        e.serie = &s;
        if (s.identifiant <= a.legendeJusqua && !a.legende.empty()) {
            if (libelle >= a.legende.size()) continue;
            e.libelle = a.legende[libelle++];
        } else {
            e.libelle = s.etiquette.empty() ? "data" + std::to_string(entrees.size() + 1)
                                            : s.etiquette;
        }
        entrees.push_back(e);
    }
    return entrees;
}

namespace {

const char* const EMPLACEMENTS_LEGENDE[] = {
    "north", "south", "east", "west", "northeast", "northwest", "southeast", "southwest",
    "northoutside", "southoutside", "eastoutside", "westoutside", "northeastoutside",
    "northwestoutside", "southeastoutside", "southwestoutside", "best", "bestoutside",
    "layout", "none"};

bool commencePar(const std::string& s, const char* debut) {
    return s.compare(0, std::strlen(debut), debut) == 0;
}

bool finitPar(const std::string& s, const char* fin) {
    std::size_t n = std::strlen(fin);
    return s.size() >= n && s.compare(s.size() - n, n, fin) == 0;
}

// Ce que la legende cache, place par place, quand on la cherche « best » :
// les traits en pixels de longueur, les points et les textes poses en
// pixels equivalents, les barres a proportion de leur surface couverte.
struct Obstacles {
    std::vector<std::array<double, 4>> segments;
    std::vector<std::array<double, 3>> points;      // x, y, poids
    std::vector<std::array<double, 4>> rectangles;  // gauche, haut, droite, bas
};

Obstacles obstaclesDe(const Axes& a, const VersPixels& versPixels, double gauche,
                      double haut, double droite, double bas) {
    // Un marqueur cache vaut quelques pixels de trait ; un texte pose,
    // davantage : c'est l'annotation qu'on a voulue.
    const double poidsPoint = 8, poidsTexte = 24;
    Obstacles o;
    for (const auto& s : a.series) {
        std::size_t n = std::min(s.x.size(), s.y.size());
        double px = 0, py = 0;
        switch (s.genre) {
            case GenreTrace::Image:
                // Une image couvre tout : elle ne departage aucune place.
                break;
            case GenreTrace::Constante:
                if (s.x.empty()) break;
                if (s.axeConstante == 'x' && versPixels(s.x[0], 1.0, px, py))
                    o.segments.push_back({px, haut, px, bas});
                else if (s.axeConstante == 'y' && versPixels(1.0, s.x[0], px, py))
                    o.segments.push_back({gauche, py, droite, py});
                break;
            case GenreTrace::Texte:
                if (n && versPixels(s.x[0], s.y[0], px, py))
                    o.points.push_back({px, py, poidsTexte});
                break;
            case GenreTrace::Points:
                for (std::size_t k = 0; k < n; ++k)
                    if (versPixels(s.x[k], s.y[k], px, py))
                        o.points.push_back({px, py, poidsPoint});
                break;
            case GenreTrace::Barres:
            case GenreTrace::Tige: {
                // Une barre a la largeur que lui donne le rendu : sept
                // dixiemes de l'ecart entre deux abscisses.
                double demi = 0, x1 = 0, y1 = 0;
                if (s.genre == GenreTrace::Barres && n > 1 &&
                    versPixels(s.x[0], s.y[0], px, py) &&
                    versPixels(s.x[1], s.y[1], x1, y1))
                    demi = 0.35 * std::fabs(x1 - px);
                for (std::size_t k = 0; k < n; ++k) {
                    double base = 0;
                    if (!versPixels(s.x[k], s.y[k], px, py) ||
                        !versPixels(s.x[k], 0.0, x1, base))
                        continue;
                    if (s.genre == GenreTrace::Tige) {
                        o.segments.push_back({px, base, px, py});
                        o.points.push_back({px, py, poidsPoint});
                    } else {
                        o.rectangles.push_back({px - demi, std::min(py, base), px + demi,
                                                std::max(py, base)});
                    }
                }
                break;
            }
            default: {
                bool precedent = false;
                double avantX = 0, avantY = 0;
                for (std::size_t k = 0; k < n; ++k) {
                    if (!versPixels(s.x[k], s.y[k], px, py)) {
                        precedent = false;
                        continue;
                    }
                    if (precedent) {
                        if (s.genre == GenreTrace::Escalier) {
                            o.segments.push_back({avantX, avantY, px, avantY});
                            o.segments.push_back({px, avantY, px, py});
                        } else {
                            o.segments.push_back({avantX, avantY, px, py});
                        }
                    }
                    if (!s.marqueur.empty() && s.marqueur != "none")
                        o.points.push_back({px, py, poidsPoint});
                    precedent = true;
                    avantX = px;
                    avantY = py;
                }
                break;
            }
        }
    }
    return o;
}

// La longueur du segment qui tombe dans le rectangle : l'algorithme de
// Liang et Barsky, qui rogne le parametre du segment bord apres bord.
double longueurDans(const std::array<double, 4>& s, double g, double h, double d,
                    double b) {
    double dx = s[2] - s[0], dy = s[3] - s[1];
    double t0 = 0, t1 = 1;
    auto rogner = [&](double p, double q) {
        if (p == 0) return q >= 0;
        double r = q / p;
        if (p < 0) {
            if (r > t1) return false;
            t0 = std::max(t0, r);
        } else {
            if (r < t0) return false;
            t1 = std::min(t1, r);
        }
        return true;
    };
    if (!rogner(-dx, s[0] - g) || !rogner(dx, d - s[0]) || !rogner(-dy, s[1] - h) ||
        !rogner(dy, b - s[1]))
        return 0;
    return std::max(0.0, t1 - t0) * std::hypot(dx, dy);
}

double gene(const Obstacles& o, double g, double h, double d, double b) {
    double total = 0;
    for (const auto& s : o.segments) total += longueurDans(s, g, h, d, b);
    for (const auto& p : o.points)
        if (p[0] >= g && p[0] <= d && p[1] >= h && p[1] <= b) total += p[2];
    for (const auto& r : o.rectangles) {
        double l = std::min(r[2], d) - std::max(r[0], g);
        double t = std::min(r[3], b) - std::max(r[1], h);
        if (l > 0 && t > 0) total += l * t / 4;
    }
    return total;
}

void coinLegende(const std::string& emplacement, double largeur, double hauteur,
                 double gauche, double haut, double droite, double bas, double& x,
                 double& y) {
    // Assez pour que le cadre de l'axe ne se confonde pas avec celui de la
    // legende.
    const double marge = 8;
    if (finitPar(emplacement, "east")) x = droite - marge - largeur;
    else if (finitPar(emplacement, "west")) x = gauche + marge;
    else x = (gauche + droite - largeur) / 2;
    if (commencePar(emplacement, "north")) y = haut + marge;
    else if (commencePar(emplacement, "south")) y = bas - marge - hauteur;
    else y = (haut + bas - hauteur) / 2;
}

}  // namespace

std::string emplacementLegendeDepuisTexte(const std::string& valeur) {
    std::string bas = valeur;
    for (auto& c : bas) c = (char)std::tolower((unsigned char)c);
    for (const char* e : EMPLACEMENTS_LEGENDE)
        if (bas == e) return bas;
    std::string liste;
    for (const char* e : EMPLACEMENTS_LEGENDE)
        liste += std::string(liste.empty() ? "" : " | ") + "'" + e + "'";
    erreur("MATLAB:datatypes:InvalidEnumValueFor",
           "Error setting property 'Location' of class 'Legend':\n'" + valeur +
               "' is not a valid value. Use one of these values: " + liste + ".");
}

bool logerLegendeHorsAxe(const std::string& emplacement, double largeur, double hauteur,
                         double caseGauche, double caseHaut, double caseDroite,
                         double caseBas, double& gauche, double& haut, double& droite,
                         double& bas, double& x, double& y) {
    // « bestoutside » est, pour une legende verticale, le coin haut droit ;
    // « layout » n'a de case a lui que dans un « tiledlayout », et se range
    // a droite comme une legende « eastoutside ».
    std::string e = emplacement == "bestoutside" ? "northeastoutside"
                    : emplacement == "layout"    ? "eastoutside"
                                                 : emplacement;
    if (!finitPar(e, "outside")) return false;
    e.erase(e.size() - 7);
    // L'ecart entre le cadre et la legende, puis entre la legende et le
    // bord de la case.
    const double ecart = 8, bord = 4;
    double g = gauche, h = haut, d = droite, b = bas;
    if (finitPar(e, "east")) {
        d = std::min(droite, caseDroite - bord - largeur - ecart);
        x = d + ecart;
    } else if (finitPar(e, "west")) {
        // Les graduations et l'etiquette des y restent collees au cadre :
        // la legende passe au-dela, contre le bord de la case.
        g = gauche + bord + largeur + ecart;
        x = caseGauche + bord;
    } else if (e == "north") {
        // Au-dessus du titre, que le cadre emmene avec lui en descendant.
        h = haut + bord + hauteur + ecart;
        y = caseHaut + bord;
    } else {
        // Sous l'etiquette des x.
        b = bas - bord - hauteur - ecart;
        y = caseBas - bord - hauteur;
    }
    if (d - g < 20 || b - h < 20) return false;
    if (e == "north" || e == "south") x = (g + d - largeur) / 2;
    else if (commencePar(e, "north")) y = h;
    else if (commencePar(e, "south")) y = b - hauteur;
    else y = (h + b - hauteur) / 2;
    gauche = g;
    haut = h;
    droite = d;
    bas = b;
    return true;
}

void placerLegendeDansAxe(const Axes& a, double largeur, double hauteur, double gauche,
                          double haut, double droite, double bas,
                          const VersPixels& versPixels, double& x, double& y) {
    std::string e = a.emplacementLegende;
    if (e == "best") {
        // Les coins d'abord, puis les milieux des bords : a gene egale, une
        // legende dans un coin derange moins qu'au milieu d'un bord.
        static const char* const places[] = {"northeast", "northwest", "southeast",
                                             "southwest", "north",     "south",
                                             "east",      "west"};
        Obstacles o = obstaclesDe(a, versPixels, gauche, haut, droite, bas);
        double moindre = INFINITY;
        for (const char* place : places) {
            double cx, cy;
            coinLegende(place, largeur, hauteur, gauche, haut, droite, bas, cx, cy);
            double g = gene(o, cx, cy, cx + largeur, cy + hauteur);
            if (g < moindre) {
                moindre = g;
                e = place;
            }
        }
    } else if (finitPar(e, "outside") || e == "layout" || e == "none") {
        // Hors de l'axe faute de place, ou « none » sans position donnee :
        // la place par defaut.
        e = "northeast";
    }
    coinLegende(e, largeur, hauteur, gauche, haut, droite, bas, x, y);
}

namespace {

// Une etoile a « branches » pointes, de rayons exterieur et interieur
// donnes, une pointe en haut : le pentagramme « p » et l'hexagramme « h ».
std::vector<std::pair<double, double>> etoile(int branches, double exterieur,
                                              double interieur) {
    std::vector<std::pair<double, double>> sommets;
    const double pi = 3.14159265358979323846;
    for (int k = 0; k < 2 * branches; ++k) {
        double angle = -pi / 2 + k * pi / branches;
        double r = k % 2 == 0 ? exterieur : interieur;
        sommets.push_back({r * std::cos(angle), r * std::sin(angle)});
    }
    return sommets;
}

}  // namespace

FormeMarqueur formeMarqueur(const std::string& marqueur) {
    FormeMarqueur f;
    if (marqueur.empty() || marqueur == "none") return f;
    using Ligne = std::vector<std::pair<double, double>>;
    const Ligne plus1 = {{-4, 0}, {4, 0}}, plus2 = {{0, -4}, {0, 4}};
    const Ligne croix1 = {{-3, -3}, {3, 3}}, croix2 = {{-3, 3}, {3, -3}};
    if (marqueur == "o") {
        f.rayonCercle = 3.5;
    } else if (marqueur == "+") {
        f.lignes = {plus1, plus2};
    } else if (marqueur == "x") {
        f.lignes = {croix1, croix2};
    } else if (marqueur == "*") {
        f.lignes = {plus1, plus2, croix1, croix2};
    } else if (marqueur == "s") {
        f.ferme = true;
        f.lignes = {{{-3, -3}, {3, -3}, {3, 3}, {-3, 3}}};
    } else if (marqueur == "d") {
        f.ferme = true;
        f.lignes = {{{0, -4}, {4, 0}, {0, 4}, {-4, 0}}};
    } else if (marqueur == "^" || marqueur == "v" || marqueur == ">" ||
               marqueur == "<") {
        // Le triangle pointe vers le haut ; les trois autres s'en deduisent
        // par symetrie ou quart de tour.
        f.ferme = true;
        Ligne triangle = {{0, -4}, {3.5, 3}, {-3.5, 3}};
        for (auto& p : triangle) {
            if (marqueur == "v") p.second = -p.second;
            else if (marqueur == ">") p = {-p.second, p.first};
            else if (marqueur == "<") p = {p.second, p.first};
        }
        f.lignes = {triangle};
    } else if (marqueur == "p") {
        f.ferme = true;
        f.lignes = {etoile(5, 4.5, 1.8)};
    } else if (marqueur == "h") {
        f.ferme = true;
        f.lignes = {etoile(6, 4.5, 2.4)};
    } else {
        // « . », et ce qu'on ne connait pas : un point plein.
        f.rayonCercle = 2;
        f.plein = true;
    }
    return f;
}

// --------------------------------------------------------------- rendu SVG

namespace {

// La chasse des caracteres ASCII de Helvetica, de l'espace au tilde, en
// milliemes de la taille. Le SVG ne sait pas mesurer un texte, et
// Helvetica est la police qu'il demande — Arial et Liberation Sans, qui la
// remplacent, en reprennent les mesures. Sans cette table, la boite de la
// legende avait une largeur fixe et un libelle long en sortait.
const short CHASSE_HELVETICA[95] = {
    278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278,
    556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556,
    1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778,
    667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556,
    333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556,
    556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584};

// La largeur d'un texte decoupe, en pixels, pour une taille de police
// donnee. Hors de l'ASCII on compte large : une lettre accentuee ou
// grecque comme une minuscule ronde, un symbole comme une capitale.
double largeurTexteSVG(const std::vector<MorceauTexte>& morceaux, double taille) {
    double total = 0;
    for (const auto& m : morceaux) {
        double milliemes = 0;
        for (std::size_t k = 0; k < m.texte.size();) {
            unsigned char c = (unsigned char)m.texte[k];
            std::size_t n = longueurCaractere(m.texte, k);
            if (c >= 32 && c < 127) milliemes += CHASSE_HELVETICA[c - 32];
            else if (c >= 0x80) milliemes += n == 2 ? 600 : 800;
            k += n;
        }
        // Le gras de Helvetica est d'un dixieme plus large.
        total += milliemes / 1000.0 * taille * m.echelle * (m.gras ? 1.1 : 1.0);
    }
    return total;
}

// Le contenu d'un element <text> : chaque morceau qui monte, descend ou
// change de graisse va dans un <tspan>. Le decalage passe par « dy », que
// tous les lecteurs de SVG suivent, quand « baseline-shift » n'est pas
// compris partout ; « dy » se cumulant, chaque <tspan> part de la hauteur
// du precedent.
std::string contenuTexteSVG(const std::vector<MorceauTexte>& morceaux, double taille) {
    std::string r;
    double decalage = 0;
    for (const auto& m : morceaux) {
        bool memeLigne = m.decalage == decalage;
        if (memeLigne && m.echelle == 1.0 && !m.gras && !m.italique) {
            r += echapperXml(m.texte);
            continue;
        }
        r += "<tspan";
        if (!memeLigne)
            r += " dy=\"" + formater("%g", (decalage - m.decalage) * taille) + "\"";
        if (m.echelle != 1.0)
            r += " font-size=\"" + formater("%g", m.echelle * taille) + "\"";
        if (m.gras) r += " font-weight=\"bold\"";
        if (m.italique) r += " font-style=\"italic\"";
        r += ">" + echapperXml(m.texte) + "</tspan>";
        decalage = m.decalage;
    }
    return r;
}

// Un marqueur, tel que le trace et la legende le dessinent : l'echantillon
// de la legende doit montrer ce qu'on voit sur la courbe.
std::string marqueurSVG(const std::string& marqueur, double px, double py,
                        const std::string& couleur) {
    std::ostringstream m;
    FormeMarqueur f = formeMarqueur(marqueur);
    if (f.rayonCercle > 0) {
        m << "<circle cx=\"" << px << "\" cy=\"" << py << "\" r=\"" << f.rayonCercle
          << "\"";
        if (f.plein) m << " fill=\"" << couleur << "\"/>\n";
        else m << " fill=\"none\" stroke=\"" << couleur << "\"/>\n";
    }
    if (f.lignes.empty()) return m.str();
    if (f.ferme) {
        for (const auto& polygone : f.lignes) {
            m << "<polygon points=\"";
            for (std::size_t k = 0; k < polygone.size(); ++k)
                m << (k ? " " : "") << (px + polygone[k].first) << ","
                  << (py + polygone[k].second);
            m << "\" fill=\"none\" stroke=\"" << couleur << "\"/>\n";
        }
        return m.str();
    }
    m << "<path d=\"";
    for (const auto& ligne : f.lignes)
        for (std::size_t k = 0; k < ligne.size(); ++k)
            m << (k ? " L " : " M ") << (px + ligne[k].first) << " "
              << (py + ligne[k].second);
    m << "\" fill=\"none\" stroke=\"" << couleur << "\"/>\n";
    return m.str();
}

// L'echantillon d'une entree de legende, de x0 a x1 sur la ligne y : le
// trait avec ses tirets et son epaisseur, le marqueur au milieu ; le
// marqueur seul quand la courbe n'a pas de trait ; un pave plein pour ce
// qui se remplit. Un trait plein pour tout, c'etait mentir sur les
// marqueurs et les pointilles.
std::string echantillonSVG(const Serie& s, double x0, double x1, double y) {
    std::ostringstream e;
    double milieu = (x0 + x1) / 2;
    switch (s.genre) {
        case GenreTrace::Barres:
        case GenreTrace::Aire:
        case GenreTrace::Polygone:
        case GenreTrace::Image: {
            double opacite = s.genre == GenreTrace::Barres  ? 0.75
                             : s.genre == GenreTrace::Image ? 1.0
                                                            : s.opacite;
            e << "<rect x=\"" << x0 << "\" y=\"" << (y - 5) << "\" width=\"" << (x1 - x0)
              << "\" height=\"10\" fill=\"" << s.couleur << "\" fill-opacity=\""
              << opacite << "\" stroke=\""
              << (s.couleurBord.empty() ? s.couleur : s.couleurBord) << "\"/>\n";
            return e.str();
        }
        case GenreTrace::Points:
            e << "<circle cx=\"" << milieu << "\" cy=\"" << y << "\" r=\"3\" fill=\""
              << s.couleur << "\"/>\n";
            return e.str();
        case GenreTrace::Tige:
            e << "<line x1=\"" << x0 << "\" y1=\"" << y << "\" x2=\"" << x1 << "\" y2=\""
              << y << "\" stroke=\"" << s.couleur << "\"/>\n";
            e << "<circle cx=\"" << milieu << "\" cy=\"" << y
              << "\" r=\"3\" fill=\"none\" stroke=\"" << s.couleur << "\"/>\n";
            return e.str();
        default:
            break;
    }
    if (s.style != "none")
        e << "<line x1=\"" << x0 << "\" y1=\"" << y << "\" x2=\"" << x1 << "\" y2=\"" << y
          << "\" stroke=\"" << s.couleur << "\" stroke-width=\"" << s.epaisseur << "\""
          << motifTrait(s.style) << "/>\n";
    e << marqueurSVG(s.marqueur, milieu, y, s.couleur);
    return e.str();
}

}  // namespace

std::string rendreSVG(const Figure& figure) {
    std::ostringstream out;
    int L = figure.largeur, H = figure.hauteur;
    out << "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" << L << "\" height=\"" << H
        << "\" viewBox=\"0 0 " << L << " " << H << "\">\n";
    out << "<rect width=\"" << L << "\" height=\"" << H << "\" fill=\"white\"/>\n";
    out << "<style>text{font-family:Helvetica,Arial,sans-serif;font-size:12px;fill:#222}"
           ".titre{font-size:15px}.axe{stroke:#222;stroke-width:1;fill:none}"
           ".grille{stroke:#ccc;stroke-width:0.5}</style>\n";

    int indiceAxe = 0;
    for (const auto& axesPtr : figure.axes) {
        const Axes& a = *axesPtr;
        ++indiceAxe;
        double fx, fy, fl, fh;
        cadreAxes(a, fx, fy, fl, fh);
        // Les marges d'une case sont bornees par sa taille : une case
        // haute de cent cinquante pixels — la moitie d'un Bode dans un
        // quart de figure — ne peut pas en donner quatre-vingt-dix aux
        // etiquettes.
        double largeurCase = fl * L, hauteurCase = fh * H;
        int gauche = (int)(fx * L + std::min(70.0, 0.22 * largeurCase));
        int droite = (int)((fx + fl) * L - std::min(30.0, 0.10 * largeurCase));
        int haut = (int)(fy * H + std::min(40.0, 0.16 * hauteurCase));
        int bas = (int)((fy + fh) * H - std::min(50.0, 0.22 * hauteurCase));
        if (droite <= gauche + 10 || bas <= haut + 10) continue;

        // La legende se mesure avant le trace : logee hors de l'axe, elle
        // lui prend de la place. Sa largeur est celle du plus long
        // libelle — fixe, elle laissait deborder un libelle long.
        const double tailleTexte = 12;
        std::vector<EntreeLegende> entrees = entreesLegende(a);
        std::vector<std::vector<MorceauTexte>> libelles;
        std::vector<double> largeursLibelles;
        double largeurLegende = 0, hauteurLegende = 0, xLegende = 0, yLegende = 0;
        bool legendeLogee = false;
        if (!entrees.empty()) {
            double plusLong = 0;
            for (const auto& e : entrees) {
                libelles.push_back(decouperTexte(e.libelle, a.interpreteLegende));
                largeursLibelles.push_back(largeurTexteSVG(libelles.back(), tailleTexte));
                plusLong = std::max(plusLong, largeursLibelles.back());
            }
            // L'echantillon de 6 a 30, le libelle a 36, 8 de marge a droite.
            largeurLegende = std::ceil(plusLong) + 44;
            hauteurLegende = 18.0 * (double)entrees.size() + 8;
            double g = gauche, h = haut, d = droite, b = bas;
            legendeLogee = logerLegendeHorsAxe(a.emplacementLegende, largeurLegende,
                                               hauteurLegende, fx * L, fy * H,
                                               (fx + fl) * L, (fy + fh) * H, g, h, d, b,
                                               xLegende, yLegende);
            if (legendeLogee) {
                gauche = (int)std::lround(g);
                haut = (int)std::lround(h);
                droite = (int)std::lround(d);
                bas = (int)std::lround(b);
            }
        }

        // Bornes des données.
        double xmin = INFINITY, xmax = -INFINITY, ymin = INFINITY, ymax = -INFINITY;
        for (const auto& s : a.series) {
            // Une droite « xline » suit les bornes, elle ne les impose pas.
            if (s.genre == GenreTrace::Constante || s.genre == GenreTrace::Texte) continue;
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
        double margeY = 0.05 * (ymax - ymin);
        ymin -= margeY;
        ymax += margeY;
        if (a.limitesManuellesX) { xmin = a.xmin; xmax = a.xmax; }
        if (a.limitesManuellesY) { ymin = a.ymin; ymax = a.ymax; }
        // Un axe logarithmique ne porte pas le zero : ses bornes sont
        // ramenees dans les positifs, et la marge de cinq pour cent que le
        // lineaire s'accorde n'a pas de sens ici.
        bool logX = a.logX, logY = a.logY;
        if (logX && !bornesLog(xmin, xmax)) logX = false;
        if (logY) {
            ymin = INFINITY;
            ymax = -INFINITY;
            for (const auto& s : a.series)
                for (double v : s.y) {
                    if (!std::isfinite(v) || v <= 0) continue;
                    ymin = std::min(ymin, v);
                    ymax = std::max(ymax, v);
                }
            if (a.limitesManuellesY) { ymin = a.ymin; ymax = a.ymax; }
            if (!std::isfinite(ymin) || !bornesLog(ymin, ymax)) {
                logY = false;
                ymin = 0;
                ymax = 1;
            }
        }
        appliquerProportions(a, gauche, droite, haut, bas, xmin, xmax, ymin, ymax);

        // Un axe inverse n'echange pas ses bornes mais les pixels ou
        // elles tombent : tout le reste du trace suit sans le savoir.
        Echelle ex{xmin, xmax, a.xInverse ? droite : gauche,
                   a.xInverse ? gauche : droite, logX};
        Echelle ey{ymin, ymax, a.yInverse ? haut : bas,
                   a.yInverse ? bas : haut, logY};

        // « axis off » : le cadre, les graduations et leurs nombres
        // disparaissent ; les courbes, elles, restent.
        if (a.axesVisibles)
            out << "<rect x=\"" << gauche << "\" y=\"" << haut << "\" width=\""
                << (droite - gauche) << "\" height=\"" << (bas - haut)
                << "\" fill=\"white\" stroke=\"#222\"/>\n";

        // Les graduations imposees par « ax.XTick = [...] » l'emportent sur
        // celles qu'on choisirait.
        auto tx = a.axesVisibles
                      ? (a.ticksX.empty() ? graduationsAxe(xmin, xmax, 6, logX) : a.ticksX)
                      : std::vector<double>{};
        auto ty = a.axesVisibles
                      ? (a.ticksY.empty() ? graduationsAxe(ymin, ymax, 6, logY) : a.ticksY)
                      : std::vector<double>{};
        std::size_t rangTick = 0;
        for (double v : tx) {
            double px = ex.versPixel(v);
            if (px < gauche - 1 || px > droite + 1) continue;
            if (a.grille)
                out << "<line class=\"grille\" x1=\"" << px << "\" y1=\"" << haut << "\" x2=\""
                    << px << "\" y2=\"" << bas << "\"/>\n";
            out << "<line class=\"axe\" x1=\"" << px << "\" y1=\"" << bas << "\" x2=\"" << px
                << "\" y2=\"" << (bas - 4) << "\"/>\n";
            // « xticklabels({'a','b'}) » l'emporte sur les nombres.
            std::string texte = rangTick < a.etiquettesTicksX.size()
                                    ? echapperXml(a.etiquettesTicksX[rangTick])
                                    : etiquetteGraduation(v, logX);
            ++rangTick;
            out << "<text x=\"" << px << "\" y=\"" << (bas + 16)
                << "\" text-anchor=\"middle\">" << texte << "</text>\n";
        }
        rangTick = 0;
        for (double v : ty) {
            double py = ey.versPixel(v);
            if (py < haut - 1 || py > bas + 1) continue;
            if (a.grille)
                out << "<line class=\"grille\" x1=\"" << gauche << "\" y1=\"" << py
                    << "\" x2=\"" << droite << "\" y2=\"" << py << "\"/>\n";
            out << "<line class=\"axe\" x1=\"" << gauche << "\" y1=\"" << py << "\" x2=\""
                << (gauche + 4) << "\" y2=\"" << py << "\"/>\n";
            std::string texteY = rangTick < a.etiquettesTicksY.size()
                                     ? echapperXml(a.etiquettesTicksY[rangTick])
                                     : etiquetteGraduation(v, logY);
            ++rangTick;
            out << "<text x=\"" << (gauche - 8) << "\" y=\"" << (py + 4)
                << "\" text-anchor=\"end\">" << texteY << "</text>\n";
        }

        out << "<clipPath id=\"c" << indiceAxe << "\"><rect x=\"" << gauche << "\" y=\"" << haut
            << "\" width=\"" << (droite - gauche) << "\" height=\"" << (bas - haut)
            << "\"/></clipPath>\n";
        out << "<g clip-path=\"url(#c" << indiceAxe << ")\">\n";

        for (const auto& s : a.series) {
            std::size_t n = std::min(s.x.size(), s.y.size());
            if (s.genre == GenreTrace::Constante) {
                if (s.x.empty()) continue;
                double px = s.axeConstante == 'x' ? ex.versPixel(s.x[0]) : gauche;
                double py = s.axeConstante == 'y' ? ey.versPixel(s.x[0]) : haut;
                if (s.axeConstante == 'x')
                    out << "<line x1=\"" << px << "\" y1=\"" << haut << "\" x2=\"" << px
                        << "\" y2=\"" << bas << "\" stroke=\"" << s.couleur
                        << "\" stroke-width=\"" << s.epaisseur << "\""
                        << motifTrait(s.style) << "/>\n";
                else
                    out << "<line x1=\"" << gauche << "\" y1=\"" << py << "\" x2=\"" << droite
                        << "\" y2=\"" << py << "\" stroke=\"" << s.couleur
                        << "\" stroke-width=\"" << s.epaisseur << "\""
                        << motifTrait(s.style) << "/>\n";
                if (!s.legendeConstante.empty()) {
                    double tx = s.axeConstante == 'x' ? px + 4 : droite - 4;
                    double ty = s.axeConstante == 'x' ? haut + 14 : py - 4;
                    out << "<text x=\"" << tx << "\" y=\"" << ty << "\" text-anchor=\""
                        << (s.axeConstante == 'x' ? "start" : "end") << "\" fill=\""
                        << s.couleur << "\">" << echapperXml(s.legendeConstante)
                        << "</text>\n";
                }
                continue;
            }
            if (s.genre == GenreTrace::Texte) {
                if (s.x.empty() || s.y.empty()) continue;
                double taille = s.taillePoliceTexte > 0 ? s.taillePoliceTexte : 11.0;
                const char* ancre = s.alignement == 'c'   ? "middle"
                                    : s.alignement == 'r' ? "end"
                                                          : "start";
                auto morceaux = decouperTexte(s.legendeConstante, s.interprete);
                out << "<text x=\"" << ex.versPixel(s.x[0]) << "\" y=\""
                    << ey.versPixel(s.y[0]) << "\" text-anchor=\"" << ancre
                    << "\" font-size=\"" << taille << "\" fill=\"" << s.couleur << "\">"
                    << contenuTexteSVG(morceaux, taille) << "</text>\n";
                continue;
            }
            if (s.genre == GenreTrace::Aire || s.genre == GenreTrace::Polygone) {
                if (n < 2) continue;
                std::string chemin;
                for (std::size_t k = 0; k < n; ++k) {
                    chemin += (k ? " L " : "M ") + formater("%g", ex.versPixel(s.x[k])) + " " +
                              formater("%g", ey.versPixel(s.y[k]));
                }
                if (s.genre == GenreTrace::Aire) {
                    // On referme sur la ligne des zeros : c'est la surface
                    // sous la courbe.
                    double zero = ey.versPixel(std::max(ymin, std::min(ymax, 0.0)));
                    chemin += " L " + formater("%g", ex.versPixel(s.x[n - 1])) + " " +
                              formater("%g", zero);
                    chemin += " L " + formater("%g", ex.versPixel(s.x[0])) + " " +
                              formater("%g", zero);
                }
                chemin += " Z";
                out << "<path d=\"" << chemin << "\" fill=\"" << s.couleur
                    << "\" fill-opacity=\"" << s.opacite << "\" stroke=\""
                    << (s.couleurBord.empty() ? s.couleur : s.couleurBord)
                    << "\" stroke-width=\"" << s.epaisseur << "\"/>\n";
                continue;
            }
            if (s.genre == GenreTrace::Image) {
                int lImage = s.hauteurImage, cImage = s.largeurImage;
                if (lImage <= 0 || cImage <= 0) continue;
                double mn = INFINITY, mx = -INFINITY;
                for (double v : s.z) {
                    mn = std::min(mn, v);
                    mx = std::max(mx, v);
                }
                if (!std::isfinite(mn) || mx == mn) { mn = 0; mx = 1; }
                // L'image occupe l'etendue que la serie declare, et non
                // toute la boite : « imagesc(x,y,Z) » se pose au bon
                // endroit, et un axe inverse la retourne comme le reste.
                double x0 = s.x.size() > 1 ? s.x[0] : 0.5;
                double x1 = s.x.size() > 1 ? s.x[1] : cImage + 0.5;
                double y0 = s.y.size() > 1 ? s.y[0] : 0.5;
                double y1 = s.y.size() > 1 ? s.y[1] : lImage + 0.5;
                for (int i = 0; i < lImage; ++i)
                    for (int j = 0; j < cImage; ++j) {
                        double v = s.z[(std::size_t)i + (std::size_t)j * lImage];
                        int r, vert, b;
                        couleurCarte((v - mn) / (mx - mn), r, vert, b);
                        double gx0 = ex.versPixel(x0 + (x1 - x0) * j / cImage);
                        double gx1 = ex.versPixel(x0 + (x1 - x0) * (j + 1) / cImage);
                        double gy0 = ey.versPixel(y0 + (y1 - y0) * i / lImage);
                        double gy1 = ey.versPixel(y0 + (y1 - y0) * (i + 1) / lImage);
                        out << "<rect x=\"" << std::min(gx0, gx1) << "\" y=\""
                            << std::min(gy0, gy1) << "\" width=\""
                            << (std::fabs(gx1 - gx0) + 0.5) << "\" height=\""
                            << (std::fabs(gy1 - gy0) + 0.5) << "\" fill=\"rgb(" << r << ","
                            << vert << "," << b << ")\"/>\n";
                    }
                continue;
            }
            if (s.genre == GenreTrace::Barres) {
                double largeurBarre = n > 1 ? 0.7 * (ex.versPixel(s.x[1]) - ex.versPixel(s.x[0]))
                                            : 30.0;
                largeurBarre = std::fabs(largeurBarre);
                if (largeurBarre < 1) largeurBarre = 20;
                double base = ey.versPixel(std::max(0.0, ymin));
                for (std::size_t k = 0; k < n; ++k) {
                    double px = ex.versPixel(s.x[k]);
                    double py = ey.versPixel(s.y[k]);
                    out << "<rect x=\"" << (px - largeurBarre / 2) << "\" y=\""
                        << std::min(py, base) << "\" width=\"" << largeurBarre << "\" height=\""
                        << std::fabs(base - py) << "\" fill=\"" << s.couleur
                        << "\" fill-opacity=\"0.75\" stroke=\"" << s.couleur << "\"/>\n";
                }
                continue;
            }
            if (s.genre == GenreTrace::Points) {
                for (std::size_t k = 0; k < n; ++k)
                    out << "<circle cx=\"" << ex.versPixel(s.x[k]) << "\" cy=\""
                        << ey.versPixel(s.y[k]) << "\" r=\"3\" fill=\"" << s.couleur << "\"/>\n";
                continue;
            }
            if (s.genre == GenreTrace::Tige) {
                double base = ey.versPixel(0);
                for (std::size_t k = 0; k < n; ++k) {
                    double px = ex.versPixel(s.x[k]), py = ey.versPixel(s.y[k]);
                    out << "<line x1=\"" << px << "\" y1=\"" << base << "\" x2=\"" << px
                        << "\" y2=\"" << py << "\" stroke=\"" << s.couleur << "\"/>\n";
                    out << "<circle cx=\"" << px << "\" cy=\"" << py << "\" r=\"3\" fill=\"none\" "
                           "stroke=\""
                        << s.couleur << "\"/>\n";
                }
                continue;
            }
            // Les points qu'aucun pixel ne distingue sont retires : le
            // dessin est le meme, le fichier tient.
            std::vector<std::size_t> visibles =
                indicesVisibles(s.x, s.y, ex.min, ex.max, ex.pixelsMax - ex.pixelsMin);
            std::string chemin;
            bool premier = true;
            std::size_t precedent = 0;
            for (std::size_t indice : visibles) {
                std::size_t k = indice;
                if (k >= n) continue;
                if (!std::isfinite(s.x[k]) || !std::isfinite(s.y[k])) {
                    premier = true;
                    continue;
                }
                double px = ex.versPixel(s.x[k]), py = ey.versPixel(s.y[k]);
                if (s.genre == GenreTrace::Escalier && !premier)
                    chemin += formater("L %.2f %.2f ", px, ey.versPixel(s.y[precedent]));
                chemin += formater("%s %.2f %.2f ", premier ? "M" : "L", px, py);
                premier = false;
                precedent = k;
            }
            std::string tirets;
            if (s.style == "--") tirets = " stroke-dasharray=\"8,4\"";
            else if (s.style == ":") tirets = " stroke-dasharray=\"2,3\"";
            else if (s.style == "-.") tirets = " stroke-dasharray=\"8,3,2,3\"";
            if (s.style != "none" && !chemin.empty())
                out << "<path d=\"" << chemin << "\" fill=\"none\" stroke=\"" << s.couleur
                    << "\" stroke-width=\"" << s.epaisseur << "\"" << tirets << "/>\n";
            if (!s.marqueur.empty())
                for (std::size_t k = 0; k < n; ++k)
                    out << marqueurSVG(s.marqueur, ex.versPixel(s.x[k]),
                                       ey.versPixel(s.y[k]), s.couleur);
        }
        out << "</g>\n";

        auto contenu = [](const std::string& texte, Interprete interprete,
                          double taille) {
            return contenuTexteSVG(decouperTexte(texte, interprete), taille);
        };
        if (!a.titre.empty()) {
            double tailleTitre = a.taillePoliceTitre > 0 ? a.taillePoliceTitre : 15;
            out << "<text class=\"titre\" x=\"" << ((gauche + droite) / 2) << "\" y=\""
                << (haut - 14) << "\" text-anchor=\"middle\""
                << (a.taillePoliceTitre > 0
                        ? " font-size=\"" + formater("%g", a.taillePoliceTitre) + "px\""
                        : std::string())
                << ">" << contenu(a.titre, a.interpreteTitre, tailleTitre) << "</text>\n";
        }
        // MATLAB garde le titre sous « axis off », mais pas les etiquettes
        // des axes : elles nomment ce qui n'est plus dessine.
        if (!a.etiquetteX.empty() && a.axesVisibles)
            out << "<text x=\"" << ((gauche + droite) / 2) << "\" y=\"" << (bas + 36)
                << "\" text-anchor=\"middle\">"
                << contenu(a.etiquetteX, a.interpreteX, tailleTexte) << "</text>\n";
        if (!a.etiquetteY.empty() && a.axesVisibles)
            out << "<text x=\"" << (gauche - 46) << "\" y=\"" << ((haut + bas) / 2)
                << "\" text-anchor=\"middle\" transform=\"rotate(-90 " << (gauche - 46) << " "
                << ((haut + bas) / 2) << ")\">"
                << contenu(a.etiquetteY, a.interpreteY, tailleTexte) << "</text>\n";

        if (!entrees.empty()) {
            if (!legendeLogee) {
                VersPixels versPixels = [&](double x, double y, double& px, double& py) {
                    if (!std::isfinite(x) || !std::isfinite(y)) return false;
                    if ((logX && x <= 0) || (logY && y <= 0)) return false;
                    px = ex.versPixel(x);
                    py = ey.versPixel(y);
                    return true;
                };
                placerLegendeDansAxe(a, largeurLegende, hauteurLegende, gauche, haut,
                                     droite, bas, versPixels, xLegende, yLegende);
            }
            // La legende vient apres tout le reste de l'axe, sur un fond
            // opaque : une courbe qui passe dans le coin passe dessous, comme
            // dans MATLAB, au lieu de transparaitre au travers.
            out << "<g class=\"legende\">\n";
            out << "<rect x=\"" << xLegende << "\" y=\"" << yLegende << "\" width=\""
                << largeurLegende << "\" height=\"" << hauteurLegende
                << "\" fill=\"white\" stroke=\"#999\"/>\n";
            for (std::size_t k = 0; k < entrees.size(); ++k) {
                double ligneDeBase = yLegende + 4 + 18.0 * (double)k + 13;
                out << echantillonSVG(*entrees[k].serie, xLegende + 6, xLegende + 30,
                                      ligneDeBase - 4);
                // « textLength » tient le libelle dans la largeur mesuree,
                // quelle que soit la police que le lecteur met a la place
                // de Helvetica : la boite le contient a coup sur.
                out << "<text x=\"" << (xLegende + 36) << "\" y=\"" << ligneDeBase
                    << "\"";
                if (largeursLibelles[k] > 0)
                    out << " textLength=\"" << formater("%.2f", largeursLibelles[k])
                        << "\" lengthAdjust=\"spacingAndGlyphs\"";
                out << ">" << contenuTexteSVG(libelles[k], tailleTexte) << "</text>\n";
            }
            out << "</g>\n";
        }
    }
    out << "</svg>\n";
    return out.str();
}

}  // namespace matlibre
