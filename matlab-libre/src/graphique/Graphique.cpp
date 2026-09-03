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
                out << "<text x=\"" << ex.versPixel(s.x[0]) << "\" y=\""
                    << ey.versPixel(s.y[0]) << "\" text-anchor=\"" << ancre
                    << "\" font-size=\"" << taille << "\" fill=\"" << s.couleur << "\">"
                    << echapperXml(s.legendeConstante) << "</text>\n";
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
                    << "\" fill-opacity=\"0.4\" stroke=\"" << s.couleur
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
                << (haut - 14) << "\" text-anchor=\"middle\""
                << (a.taillePoliceTitre > 0
                        ? " font-size=\"" + formater("%g", a.taillePoliceTitre) + "px\""
                        : std::string())
                << ">" << echapperXml(a.titre) << "</text>\n";
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
