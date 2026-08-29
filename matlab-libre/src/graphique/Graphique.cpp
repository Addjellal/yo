#include "matlibre/Graphique.h"

#include <algorithm>
#include <cmath>
#include <climits>
#include <cstdlib>
#include <fstream>
#include <memory>
#include <sstream>

#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"

namespace matlibre {

std::shared_ptr<Figure> figureCourante(Interpreteur& it) {
    if (it.figureCourante == 0 || !it.figures.count(it.figureCourante)) {
        int numero = it.figureCourante ? it.figureCourante : 1;
        while (it.figures.count(numero)) ++numero;
        auto f = std::make_shared<Figure>();
        f->numero = numero;
        f->axes.push_back(std::make_shared<Axes>());
        it.figures[numero] = f;
        it.figureCourante = numero;
    }
    return it.figures[it.figureCourante];
}

std::shared_ptr<Axes> axesCourants(Interpreteur& it) {
    auto f = figureCourante(it);
    if (f->axes.empty()) f->axes.push_back(std::make_shared<Axes>());
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

}  // namespace

// « axis square » d'abord — elle change la boite —, puis « axis equal »,
// qui elargit les bornes de l'axe qui a trop de place pour que les deux
// echelles aient le meme nombre d'unites par pixel.
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

std::string rendreSVG(const Figure& figure) {
    std::ostringstream out;
    int L = figure.largeur, H = figure.hauteur;
    out << "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" << L << "\" height=\"" << H
        << "\" viewBox=\"0 0 " << L << " " << H << "\">\n";
    out << "<rect width=\"" << L << "\" height=\"" << H << "\" fill=\"white\"/>\n";
    out << "<style>text{font-family:Helvetica,Arial,sans-serif;font-size:12px;fill:#222}"
           ".titre{font-size:15px}.axe{stroke:#222;stroke-width:1;fill:none}"
           ".grille{stroke:#ccc;stroke-width:0.5}</style>\n";

    int lignes = std::max(1, figure.lignes), colonnes = std::max(1, figure.colonnes);
    for (const auto& axesPtr : figure.axes) {
        const Axes& a = *axesPtr;
        int position = std::max(1, a.position);
        int li = (position - 1) / colonnes, co = (position - 1) % colonnes;
        int largeurCase = L / colonnes, hauteurCase = H / lignes;
        int gauche = co * largeurCase + 70;
        int droite = (co + 1) * largeurCase - 30;
        int haut = li * hauteurCase + 40;
        int bas = (li + 1) * hauteurCase - 50;
        if (droite <= gauche + 10 || bas <= haut + 10) continue;

        // Bornes des données.
        double xmin = INFINITY, xmax = -INFINITY, ymin = INFINITY, ymax = -INFINITY;
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
        double margeY = 0.05 * (ymax - ymin);
        ymin -= margeY;
        ymax += margeY;
        if (a.limitesManuellesX) { xmin = a.xmin; xmax = a.xmax; }
        if (a.limitesManuellesY) { ymin = a.ymin; ymax = a.ymax; }
        appliquerProportions(a, gauche, droite, haut, bas, xmin, xmax, ymin, ymax);

        Echelle ex{xmin, xmax, gauche, droite, a.logX};
        Echelle ey{ymin, ymax, bas, haut, a.logY};

        // « axis off » : le cadre, les graduations et leurs nombres
        // disparaissent ; les courbes, elles, restent.
        if (a.axesVisibles)
            out << "<rect x=\"" << gauche << "\" y=\"" << haut << "\" width=\""
                << (droite - gauche) << "\" height=\"" << (bas - haut)
                << "\" fill=\"white\" stroke=\"#222\"/>\n";

        // Les graduations imposees par « ax.XTick = [...] » l'emportent sur
        // celles qu'on choisirait.
        auto tx = a.axesVisibles
                      ? (a.ticksX.empty() ? graduations(xmin, xmax, 6) : a.ticksX)
                      : std::vector<double>{};
        auto ty = a.axesVisibles
                      ? (a.ticksY.empty() ? graduations(ymin, ymax, 6) : a.ticksY)
                      : std::vector<double>{};
        for (double v : tx) {
            double px = ex.versPixel(v);
            if (px < gauche - 1 || px > droite + 1) continue;
            if (a.grille)
                out << "<line class=\"grille\" x1=\"" << px << "\" y1=\"" << haut << "\" x2=\""
                    << px << "\" y2=\"" << bas << "\"/>\n";
            out << "<line class=\"axe\" x1=\"" << px << "\" y1=\"" << bas << "\" x2=\"" << px
                << "\" y2=\"" << (bas - 4) << "\"/>\n";
            out << "<text x=\"" << px << "\" y=\"" << (bas + 16)
                << "\" text-anchor=\"middle\">" << echapperXml(nombreCourt(v)) << "</text>\n";
        }
        for (double v : ty) {
            double py = ey.versPixel(v);
            if (py < haut - 1 || py > bas + 1) continue;
            if (a.grille)
                out << "<line class=\"grille\" x1=\"" << gauche << "\" y1=\"" << py
                    << "\" x2=\"" << droite << "\" y2=\"" << py << "\"/>\n";
            out << "<line class=\"axe\" x1=\"" << gauche << "\" y1=\"" << py << "\" x2=\""
                << (gauche + 4) << "\" y2=\"" << py << "\"/>\n";
            out << "<text x=\"" << (gauche - 8) << "\" y=\"" << (py + 4)
                << "\" text-anchor=\"end\">" << echapperXml(nombreCourt(v)) << "</text>\n";
        }

        out << "<clipPath id=\"c" << position << "\"><rect x=\"" << gauche << "\" y=\"" << haut
            << "\" width=\"" << (droite - gauche) << "\" height=\"" << (bas - haut)
            << "\"/></clipPath>\n";
        out << "<g clip-path=\"url(#c" << position << ")\">\n";

        for (const auto& s : a.series) {
            std::size_t n = std::min(s.x.size(), s.y.size());
            if (s.genre == GenreTrace::Image) {
                int lImage = s.hauteurImage, cImage = s.largeurImage;
                if (lImage <= 0 || cImage <= 0) continue;
                double mn = INFINITY, mx = -INFINITY;
                for (double v : s.z) {
                    mn = std::min(mn, v);
                    mx = std::max(mx, v);
                }
                if (!std::isfinite(mn) || mx == mn) { mn = 0; mx = 1; }
                double dx = (double)(droite - gauche) / cImage;
                double dy = (double)(bas - haut) / lImage;
                for (int i = 0; i < lImage; ++i)
                    for (int j = 0; j < cImage; ++j) {
                        double v = s.z[(std::size_t)i + (std::size_t)j * lImage];
                        double t = (v - mn) / (mx - mn);
                        int r = (int)(255 * std::min(1.0, std::max(0.0, 1.5 - std::fabs(4 * t - 3))));
                        int g = (int)(255 * std::min(1.0, std::max(0.0, 1.5 - std::fabs(4 * t - 2))));
                        int b = (int)(255 * std::min(1.0, std::max(0.0, 1.5 - std::fabs(4 * t - 1))));
                        out << "<rect x=\"" << (gauche + j * dx) << "\" y=\"" << (haut + i * dy)
                            << "\" width=\"" << (dx + 0.5) << "\" height=\"" << (dy + 0.5)
                            << "\" fill=\"rgb(" << r << "," << g << "," << b << ")\"/>\n";
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
                for (std::size_t k = 0; k < n; ++k) {
                    double px = ex.versPixel(s.x[k]), py = ey.versPixel(s.y[k]);
                    if (s.marqueur == "o")
                        out << "<circle cx=\"" << px << "\" cy=\"" << py
                            << "\" r=\"3.5\" fill=\"none\" stroke=\"" << s.couleur << "\"/>\n";
                    else if (s.marqueur == "s")
                        out << "<rect x=\"" << (px - 3) << "\" y=\"" << (py - 3)
                            << "\" width=\"6\" height=\"6\" fill=\"none\" stroke=\"" << s.couleur
                            << "\"/>\n";
                    else if (s.marqueur == "+" || s.marqueur == "x")
                        out << "<path d=\"M " << (px - 4) << " " << py << " L " << (px + 4) << " "
                            << py << " M " << px << " " << (py - 4) << " L " << px << " "
                            << (py + 4) << "\" stroke=\"" << s.couleur << "\"/>\n";
                    else
                        out << "<circle cx=\"" << px << "\" cy=\"" << py << "\" r=\"2\" fill=\""
                            << s.couleur << "\"/>\n";
                }
        }
        out << "</g>\n";

        if (!a.titre.empty())
            out << "<text class=\"titre\" x=\"" << ((gauche + droite) / 2) << "\" y=\""
                << (haut - 14) << "\" text-anchor=\"middle\">" << echapperXml(a.titre)
                << "</text>\n";
        // MATLAB garde le titre sous « axis off », mais pas les etiquettes
        // des axes : elles nomment ce qui n'est plus dessine.
        if (!a.etiquetteX.empty() && a.axesVisibles)
            out << "<text x=\"" << ((gauche + droite) / 2) << "\" y=\"" << (bas + 36)
                << "\" text-anchor=\"middle\">" << echapperXml(a.etiquetteX) << "</text>\n";
        if (!a.etiquetteY.empty() && a.axesVisibles)
            out << "<text x=\"" << (gauche - 46) << "\" y=\"" << ((haut + bas) / 2)
                << "\" text-anchor=\"middle\" transform=\"rotate(-90 " << (gauche - 46) << " "
                << ((haut + bas) / 2) << ")\">" << echapperXml(a.etiquetteY) << "</text>\n";

        if (a.legendeVisible && !a.series.empty()) {
            int y = haut + 16;
            int x = droite - 130;
            out << "<rect x=\"" << (x - 10) << "\" y=\"" << (y - 14) << "\" width=\"135\""
                << " height=\"" << (18 * (int)a.series.size() + 8)
                << "\" fill=\"white\" fill-opacity=\"0.85\" stroke=\"#999\"/>\n";
            for (std::size_t k = 0; k < a.series.size(); ++k) {
                std::string nom = k < a.legende.size()
                                      ? a.legende[k]
                                      : (a.series[k].etiquette.empty()
                                             ? "data" + std::to_string(k + 1)
                                             : a.series[k].etiquette);
                out << "<line x1=\"" << (x - 4) << "\" y1=\"" << (y - 4) << "\" x2=\"" << (x + 18)
                    << "\" y2=\"" << (y - 4) << "\" stroke=\"" << a.series[k].couleur
                    << "\" stroke-width=\"2\"/>\n";
                out << "<text x=\"" << (x + 24) << "\" y=\"" << y << "\">" << echapperXml(nom)
                    << "</text>\n";
                y += 18;
            }
        }
    }
    out << "</svg>\n";
    return out.str();
}

}  // namespace matlibre
