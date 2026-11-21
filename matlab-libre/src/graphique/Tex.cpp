// Tex.cpp — l'interprète TeX des textes de MATLAB.
//
// MATLAB lit par défaut les titres, les étiquettes, les légendes, les
// textes et les graduations avec son sous-ensemble de TeX
// (« Interpreter », 'tex') : « x^2 » met le 2 en exposant, « Z_L » le L
// en indice, « \alpha » écrit α, « \bf » passe en gras. Sans lui, une
// étiquette « \omega (rad/s) » s'affichait telle quelle, antislash
// compris.
//
// Le texte est coupé en morceaux de même allure (Toile.h) ; la toile les
// écrit à la suite, chacun à sa hauteur et à sa taille.
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <string>
#include <vector>

#include "matlibre/Toile.h"

namespace matlibre {

namespace {

// Les symboles du TeX de MATLAB (la table de la propriété « Interpreter »
// de la documentation), en UTF-8.
const std::map<std::string, std::string>& symboles() {
    static const std::map<std::string, std::string> table = {
        {"alpha", "α"},      {"beta", "β"},       {"gamma", "γ"},      {"delta", "δ"},
        {"epsilon", "ϵ"},    {"zeta", "ζ"},       {"eta", "η"},        {"theta", "θ"},
        {"vartheta", "ϑ"},   {"iota", "ι"},       {"kappa", "κ"},      {"lambda", "λ"},
        {"mu", "µ"},         {"nu", "ν"},         {"xi", "ξ"},         {"pi", "π"},
        {"rho", "ρ"},        {"sigma", "σ"},      {"varsigma", "ς"},   {"tau", "τ"},
        {"upsilon", "υ"},    {"phi", "ϕ"},        {"chi", "χ"},        {"psi", "ψ"},
        {"omega", "ω"},      {"Gamma", "Γ"},      {"Delta", "Δ"},      {"Theta", "Θ"},
        {"Lambda", "Λ"},     {"Xi", "Ξ"},         {"Pi", "Π"},         {"Sigma", "Σ"},
        {"Upsilon", "ϒ"},    {"Phi", "Φ"},        {"Psi", "Ψ"},        {"Omega", "Ω"},
        {"varpi", "ϖ"},      {"aleph", "ℵ"},      {"Im", "ℑ"},         {"Re", "ℜ"},
        {"wp", "℘"},         {"sim", "∼"},        {"leq", "≤"},        {"geq", "≥"},
        {"infty", "∞"},      {"clubsuit", "♣"},   {"diamondsuit", "♦"}, {"heartsuit", "♥"},
        {"spadesuit", "♠"},  {"leftrightarrow", "↔"}, {"leftarrow", "←"}, {"uparrow", "↑"},
        {"rightarrow", "→"}, {"downarrow", "↓"},  {"circ", "º"},       {"pm", "±"},
        {"propto", "∝"},     {"partial", "∂"},    {"bullet", "•"},     {"div", "÷"},
        {"neq", "≠"},        {"equiv", "≡"},      {"approx", "≈"},     {"otimes", "⊗"},
        {"oplus", "⊕"},      {"oslash", "∅"},     {"cap", "∩"},        {"cup", "∪"},
        {"supseteq", "⊇"},   {"supset", "⊃"},     {"subseteq", "⊆"},   {"subset", "⊂"},
        {"int", "∫"},        {"in", "∈"},         {"o", "ο"},          {"rfloor", "⌋"},
        {"lceil", "⌈"},      {"nabla", "∇"},      {"lfloor", "⌊"},     {"cdot", "·"},
        {"ldots", "…"},      {"perp", "⊥"},       {"neg", "¬"},        {"prime", "′"},
        {"wedge", "∧"},      {"times", "×"},      {"0", "∅"},          {"rceil", "⌉"},
        {"surd", "√"},       {"mid", "|"},        {"vee", "∨"},        {"copyright", "©"},
        {"langle", "⟨"},     {"rangle", "⟩"},     {"forall", "∀"},     {"exists", "∃"},
        {"ni", "∋"},         {"cong", "≅"},       {"Leftrightarrow", "⇔"}, {"Leftarrow", "⇐"},
        {"Uparrow", "⇑"},    {"Rightarrow", "⇒"}, {"Downarrow", "⇓"},  {"deg", "°"},
        {"sum", "∑"},        {"prod", "∏"},       {"sqrt", "√"},       {"ll", "≪"},
        {"gg", "≫"},         {"to", "→"},         {"degree", "°"},     {"angle", "∠"},
        {"mho", "℧"},        {"hbar", "ℏ"},       {"ell", "ℓ"}};
    return table;
}

// L'allure en cours : elle vaut pour un groupe « {...} » et s'y referme.
struct Allure {
    int niveau = 0;
    bool italique = false;
    bool gras = false;
    double echelle = 1.0;
    std::string couleur;
};

// Une couleur de « \color{nom} » ou « \color[rgb]{r v b} ».
std::string couleurTex(const std::string& nom, bool rvb) {
    if (rvb) {
        double c[3] = {0, 0, 0};
        const char* p = nom.c_str();
        for (int k = 0; k < 3; ++k) {
            char* fin = nullptr;
            c[k] = std::strtod(p, &fin);
            if (fin == p) return std::string();
            p = fin;
            while (*p == ',' || *p == ' ') ++p;
        }
        // Bornées à [0, 1] : 2 donnait 510, écrit « 1FE » sur trois chiffres
        // puis tronqué par snprintf — \color[rgb]{2,0,0} sortait en vert.
        for (double& x : c) x = std::isfinite(x) ? std::min(1.0, std::max(0.0, x)) : 0.0;
        char tampon[8];
        int r = (int)(c[0] * 255 + 0.5), v = (int)(c[1] * 255 + 0.5), b = (int)(c[2] * 255 + 0.5);
        std::snprintf(tampon, sizeof tampon, "#%02X%02X%02X", r, v, b);
        return tampon;
    }
    static const std::map<std::string, std::string> noms = {
        {"red", "#FF0000"},     {"green", "#00FF00"}, {"blue", "#0000FF"},
        {"cyan", "#00FFFF"},    {"magenta", "#FF00FF"}, {"yellow", "#FFFF00"},
        {"black", "#000000"},   {"white", "#FFFFFF"}, {"gray", "#808080"},
        {"darkGreen", "#008000"}, {"orange", "#FF8000"}, {"lightBlue", "#ADD8E6"}};
    auto trouve = noms.find(nom);
    return trouve == noms.end() ? std::string() : trouve->second;
}

class Lecteur {
public:
    explicit Lecteur(const std::string& t) : t_(t) {}

    std::vector<Morceau> lire() {
        Allure allure;
        lireSuite(allure, false);
        fermer();
        return morceaux_;
    }

private:
    // Lit jusqu'à la fin, ou jusqu'à « } » si DANSGROUPE.
    void lireSuite(Allure& allure, bool dansGroupe) {
        while (i_ < t_.size()) {
            char c = t_[i_];
            if (c == '}' && dansGroupe) {
                ++i_;
                return;
            }
            if (c == '{') {
                ++i_;
                Allure interieur = allure;
                lireSuite(interieur, true);
                continue;
            }
            if (c == '^' || c == '_') {
                ++i_;
                Allure decale = allure;
                decale.niveau += c == '^' ? 1 : -1;
                decale.echelle = allure.echelle * (std::abs(decale.niveau) > std::abs(allure.niveau)
                                                       ? 0.75
                                                       : 1.0 / 0.75);
                if (decale.niveau == 0) decale.echelle = 1.0;
                lireUn(decale);
                continue;
            }
            if (c == '\\') {
                lireCommande(allure);
                continue;
            }
            ajouter(allure, std::string(1, c));
            ++i_;
        }
    }

    // Ce qui suit « ^ » ou « _ » : un groupe, une commande, ou un caractère
    // (UTF-8 compris).
    void lireUn(Allure& allure) {
        if (i_ >= t_.size()) return;
        char c = t_[i_];
        if (c == '{') {
            ++i_;
            lireSuite(allure, true);
            return;
        }
        if (c == '\\') {
            lireCommande(allure);
            return;
        }
        std::size_t longueur = 1;
        unsigned char u = (unsigned char)c;
        if (u >= 0xF0) longueur = 4;
        else if (u >= 0xE0) longueur = 3;
        else if (u >= 0xC0) longueur = 2;
        ajouter(allure, t_.substr(i_, longueur));
        i_ += longueur;
    }

    std::string argumentAccolade() {
        if (i_ >= t_.size() || t_[i_] != '{') return std::string();
        std::size_t fin = t_.find('}', i_);
        if (fin == std::string::npos) return std::string();
        std::string a = t_.substr(i_ + 1, fin - i_ - 1);
        i_ = fin + 1;
        return a;
    }

    void lireCommande(Allure& allure) {
        ++i_;  // l'antislash
        if (i_ >= t_.size()) {
            ajouter(allure, "\\");
            return;
        }
        char c = t_[i_];
        // \\ \{ \} \_ \^ : le caractère lui-même.
        if (c == '\\' || c == '{' || c == '}' || c == '_' || c == '^') {
            ajouter(allure, std::string(1, c));
            ++i_;
            return;
        }
        std::size_t debut = i_;
        while (i_ < t_.size() && std::isalpha((unsigned char)t_[i_])) ++i_;
        if (i_ == debut && t_[i_] == '0') ++i_;
        std::string nom = t_.substr(debut, i_ - debut);
        if (nom.empty()) {
            ajouter(allure, "\\");
            return;
        }
        // Un changement de police n'écrit rien : l'espace qui le sépare du
        // mot suivant (« \bf gras ») n'est qu'un séparateur.
        if (nom == "bf" || nom == "it" || nom == "sl" || nom == "rm") {
            if (nom == "bf") allure.gras = true;
            else if (nom == "rm") allure.gras = allure.italique = false;
            else allure.italique = true;
            if (i_ < t_.size() && t_[i_] == ' ') ++i_;
            return;
        }
        if (nom == "fontname") { argumentAccolade(); return; }
        if (nom == "fontsize") {
            std::string taille = argumentAccolade();
            double v = std::atof(taille.c_str());
            // Relative à la taille de 12 pixels que la toile suppose.
            if (v > 0) allure.echelle = v * (96.0 / 72.0) / 12.0;
            return;
        }
        if (nom == "color") {
            bool rvb = false;
            if (i_ < t_.size() && t_[i_] == '[') {
                std::size_t fin = t_.find(']', i_);
                rvb = fin != std::string::npos && t_.substr(i_ + 1, fin - i_ - 1) == "rgb";
                if (fin != std::string::npos) i_ = fin + 1;
            }
            std::string couleur = couleurTex(argumentAccolade(), rvb);
            if (!couleur.empty()) allure.couleur = couleur;
            return;
        }
        auto trouve = symboles().find(nom);
        if (trouve != symboles().end()) {
            // L'espace qui suit reste, comme dans MATLAB (et non comme dans
            // TeX) : « \omega (rad/s) » s'écrit « ω (rad/s) ».
            ajouter(allure, trouve->second);
            return;
        }
        // Une commande inconnue reste écrite, comme dans MATLAB.
        ajouter(allure, "\\" + nom);
    }

    void ajouter(const Allure& allure, const std::string& texte) {
        bool meme = ouvert_ && courant_.niveau == allure.niveau &&
                    courant_.italique == allure.italique && courant_.gras == allure.gras &&
                    courant_.echelle == allure.echelle && courant_.couleur == allure.couleur;
        if (!meme) {
            fermer();
            courant_ = Morceau();
            courant_.niveau = allure.niveau;
            courant_.italique = allure.italique;
            courant_.gras = allure.gras;
            courant_.echelle = allure.echelle;
            courant_.couleur = allure.couleur;
            ouvert_ = true;
        }
        courant_.texte += texte;
    }

    void fermer() {
        if (ouvert_ && !courant_.texte.empty()) morceaux_.push_back(courant_);
        ouvert_ = false;
    }

    const std::string& t_;
    std::size_t i_ = 0;
    std::vector<Morceau> morceaux_;
    Morceau courant_;
    bool ouvert_ = false;
};

}  // namespace

std::vector<Morceau> morceauxTexte(const std::string& texte, bool tex) {
    if (!tex || texte.find_first_of("^_\\{}") == std::string::npos) {
        Morceau m;
        m.texte = texte;
        return {m};
    }
    std::vector<Morceau> r = Lecteur(texte).lire();
    if (r.empty()) r.push_back(Morceau());
    return r;
}

std::vector<Morceau> morceauxInterpretes(const std::string& texte, const std::string& interprete) {
    if (interprete == "none") return morceauxTexte(texte, false);
    if (interprete == "latex") {
        // Le LaTeX de MATLAB passe par MathJax ; MatLibre en lit ce que le
        // TeX sait faire — exposants, indices, lettres grecques — après
        // avoir ôté les dollars des formules.
        std::string sansDollars;
        for (char c : texte)
            if (c != '$') sansDollars += c;
        return morceauxTexte(sansDollars, true);
    }
    return morceauxTexte(texte, true);
}

}  // namespace matlibre
