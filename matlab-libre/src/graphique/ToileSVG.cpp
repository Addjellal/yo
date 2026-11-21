// ToileSVG.cpp — la toile qui écrit du SVG (voir Toile.h).
//
// Le rendu SVG est vectoriel, lisible, et ne demande aucune bibliothèque :
// « print » et « saveas » l'écrivent, « matlibre_svg » le rend, les tests
// le lisent.
#include <cmath>
#include <sstream>

#include "matlibre/Erreur.h"
#include "matlibre/Toile.h"

namespace matlibre {

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

// Un nombre de pixels : deux décimales au plus, sans zéros inutiles —
// 70 et non 70.00, 12.5 et non 12.50.
std::string px(double v) {
    if (!std::isfinite(v)) return "0";
    std::string s = formater("%.2f", v);
    std::size_t point = s.find('.');
    if (point != std::string::npos) {
        std::size_t fin = s.find_last_not_of('0');
        s.erase(fin == point ? point : fin + 1);
    }
    if (s == "-0") s = "0";
    return s;
}

std::string motif(const std::string& style) {
    if (style == "--") return " stroke-dasharray=\"8,4\"";
    if (style == ":") return " stroke-dasharray=\"2,3\"";
    if (style == "-.") return " stroke-dasharray=\"8,3,2,3\"";
    return std::string();
}

std::string traitSVG(const Trait& t) {
    std::string r = " stroke=\"" + t.couleur + "\"";
    if (t.epaisseur != 1) r += " stroke-width=\"" + px(t.epaisseur) + "\"";
    return r + motif(t.motif);
}

class ToileSVG : public Toile {
public:
    ToileSVG(int largeur, int hauteur) {
        out_ << "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" << largeur
             << "\" height=\"" << hauteur << "\" viewBox=\"0 0 " << largeur << " " << hauteur
             << "\">\n";
        out_ << "<rect width=\"" << largeur << "\" height=\"" << hauteur
             << "\" fill=\"white\"/>\n";
        // Une règle de feuille de style l'emporte sur un attribut : la
        // couleur et la taille par défaut ne s'appliquent donc qu'aux textes
        // qui n'en portent pas, sans quoi « text(...,'Color','w') » ou
        // « FontSize » resteraient sans effet.
        out_ << "<style>text{font-family:Helvetica,Arial,sans-serif}"
                "text:not([font-size]){font-size:12px}text:not([fill]){fill:#222}"
                ".titre:not([font-size]){font-size:15px}"
                ".axe{stroke:#222;stroke-width:1;fill:none}"
                ".grille{stroke:#ccc;stroke-width:0.5}</style>\n";
    }

    std::string fin() {
        out_ << "</svg>\n";
        return out_.str();
    }

    double largeur(const std::vector<Morceau>& texte, double taille, bool gras) const override {
        double l = 0;
        for (const auto& m : texte)
            l += largeurHelvetica(m.texte, taille * m.echelle, gras || m.gras);
        return l;
    }

    void ligne(double x1, double y1, double x2, double y2, const Trait& t) override {
        out_ << "<line";
        if (!t.classe.empty()) out_ << " class=\"" << t.classe << "\"";
        out_ << " x1=\"" << px(x1) << "\" y1=\"" << px(y1) << "\" x2=\"" << px(x2) << "\" y2=\""
             << px(y2) << "\"";
        if (t.classe.empty())
            out_ << " stroke=\"" << t.couleur << "\" stroke-width=\"" << px(t.epaisseur) << "\""
                 << motif(t.motif);
        out_ << "/>\n";
    }

    void polyligne(const std::vector<double>& x, const std::vector<double>& y,
                   const Trait& t) override {
        std::string chemin;
        bool coupe = true;
        for (std::size_t k = 0; k < x.size() && k < y.size(); ++k) {
            if (!std::isfinite(x[k]) || !std::isfinite(y[k])) {
                coupe = true;
                continue;
            }
            chemin += (coupe ? "M " : "L ") + px(x[k]) + " " + px(y[k]) + " ";
            coupe = false;
        }
        if (chemin.empty()) return;
        chemin.pop_back();
        out_ << "<path d=\"" << chemin << "\" fill=\"none\" stroke=\"" << t.couleur
             << "\" stroke-width=\"" << px(t.epaisseur) << "\"" << motif(t.motif) << "/>\n";
    }

    void polygone(const std::vector<double>& x, const std::vector<double>& y,
                  const std::string& fond, double opacite, const Trait* bord) override {
        std::string chemin;
        for (std::size_t k = 0; k < x.size() && k < y.size(); ++k)
            chemin += (k ? " L " : "M ") + px(x[k]) + " " + px(y[k]);
        if (chemin.empty()) return;
        out_ << "<path d=\"" << chemin << " Z\" fill=\"" << fond << "\"";
        if (fond != "none") out_ << " fill-opacity=\"" << px(opacite) << "\"";
        if (bord)
            out_ << " stroke=\"" << bord->couleur << "\" stroke-width=\"" << px(bord->epaisseur)
                 << "\"";
        else out_ << " stroke=\"none\"";
        out_ << "/>\n";
    }

    void rectangle(double x, double y, double l, double h, const std::string& fond,
                   double opacite, const Trait* bord) override {
        out_ << "<rect";
        if (bord && !bord->classe.empty()) out_ << " class=\"" << bord->classe << "\"";
        out_ << " x=\"" << px(x) << "\" y=\"" << px(y) << "\" width=\"" << px(l)
             << "\" height=\"" << px(h) << "\"";
        if (!(bord && !bord->classe.empty())) {
            out_ << " fill=\"" << fond << "\"";
            if (opacite < 1) out_ << " fill-opacity=\"" << px(opacite) << "\"";
            if (bord) out_ << traitSVG(*bord);
        }
        out_ << "/>\n";
    }

    void cercle(double cx, double cy, double r, const std::string& fond,
                const Trait* bord) override {
        out_ << "<circle cx=\"" << px(cx) << "\" cy=\"" << px(cy) << "\" r=\"" << px(r)
             << "\" fill=\"" << fond << "\"";
        if (bord) out_ << traitSVG(*bord);
        out_ << "/>\n";
    }

    void texte(double x, double y, const std::vector<Morceau>& morceaux,
               const StyleTexte& s) override {
        out_ << "<text";
        if (!s.classe.empty()) out_ << " class=\"" << s.classe << "\"";
        out_ << " x=\"" << px(x) << "\" y=\"" << px(y) << "\"";
        if (s.ancre == 'c') out_ << " text-anchor=\"middle\"";
        else if (s.ancre == 'r') out_ << " text-anchor=\"end\"";
        if (s.tailleExplicite) out_ << " font-size=\"" << px(s.taille) << "px\"";
        if (s.gras) out_ << " font-weight=\"bold\"";
        if (s.angle != 0)
            out_ << " transform=\"rotate(" << px(-s.angle) << " " << px(x) << " " << px(y)
                 << ")\"";
        // La couleur en dernier : « fill="#FFFFFF">blanc » se lit d'un coup.
        if (!s.couleur.empty()) out_ << " fill=\"" << s.couleur << "\"";
        out_ << ">";
        for (const auto& m : morceaux) {
            bool simple = m.niveau == 0 && !m.italique && !m.gras && m.echelle == 1.0;
            if (simple) {
                out_ << echapperXml(m.texte);
                continue;
            }
            out_ << "<tspan";
            if (m.niveau > 0) out_ << " baseline-shift=\"super\"";
            else if (m.niveau < 0) out_ << " baseline-shift=\"sub\"";
            if (m.echelle != 1.0) out_ << " font-size=\"" << px(s.taille * m.echelle) << "px\"";
            if (m.italique) out_ << " font-style=\"italic\"";
            if (m.gras) out_ << " font-weight=\"bold\"";
            out_ << ">" << echapperXml(m.texte) << "</tspan>";
        }
        out_ << "</text>\n";
    }

    void decouper(double x, double y, double l, double h) override {
        ++decoupes_;
        out_ << "<clipPath id=\"c" << decoupes_ << "\"><rect x=\"" << px(x) << "\" y=\"" << px(y)
             << "\" width=\"" << px(l) << "\" height=\"" << px(h) << "\"/></clipPath>\n";
        out_ << "<g clip-path=\"url(#c" << decoupes_ << ")\">\n";
    }
    void finDecoupe() override { out_ << "</g>\n"; }

    void groupe(const std::string& classe) override {
        out_ << "<g class=\"" << classe << "\">\n";
    }
    void finGroupe() override { out_ << "</g>\n"; }

private:
    std::ostringstream out_;
    int decoupes_ = 0;
};

}  // namespace

std::string rendreSVG(const Figure& figure) {
    ToileSVG toile(figure.largeur, figure.hauteur);
    dessinerFigure(figure, toile, figure.largeur, figure.hauteur);
    return toile.fin();
}

}  // namespace matlibre
