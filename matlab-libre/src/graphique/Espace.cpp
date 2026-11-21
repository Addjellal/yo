// Espace.cpp — le dessin d'un axe en trois dimensions.
//
// MATLAB projette orthographiquement, par la matrice de « viewmtx » : une
// rotation de l'azimut autour de z, puis une inclinaison de l'élévation.
// Les trois axes sont d'abord ramenés à un cube (PlotBoxAspectRatio
// [1 1 1], le défaut de MATLAB ; « axis equal » le fait proportionnel aux
// données), puis la boîte projetée est mise à l'échelle, uniformément,
// pour tenir dans le cadre de l'axe.
//
// La boîte est celle de MATLAB sans « box on » : les trois plans du fond
// portent la grille, et trois arêtes portent les axes — x et y sur le
// plan du bas, à l'avant ; z sur l'arête verticale la plus à gauche.
//
// Les faces, les segments et les marqueurs sont triés du plus lointain au
// plus proche — l'algorithme du peintre —, ce qui suffit aux surfaces de
// MATLAB, dont les mailles ne se traversent pas.
#include <algorithm>
#include <cmath>

#include "Commun.h"
#include "matlibre/Erreur.h"
#include "matlibre/Toile.h"

namespace matlibre {

using namespace dessin;

namespace {

struct Projection {
    double bornes[3][2];
    double demi[3] = {0.5, 0.5, 0.5};   // la demi-longueur de la boîte par axe
    bool inverse[3] = {false, false, false};
    double r[3][3];                      // les lignes de viewmtx
    double echelleX = 1, echelleY = 1, cx = 0, cy = 0;

    // Une coordonnée de données, dans la boîte : de -demi à +demi.
    double normale(int axe, double v) const {
        double bas = bornes[axe][0], haut = bornes[axe][1];
        double t = haut > bas ? (v - bas) / (haut - bas) - 0.5 : 0.0;
        if (inverse[axe]) t = -t;
        return 2 * demi[axe] * t;
    }
    // Un point de la boîte vers l'écran, et sa profondeur (plus grande :
    // plus proche de l'observateur).
    void ecranBoite(double ux, double uy, double uz, double& sx, double& sy,
                    double& profondeur) const {
        double px = r[0][0] * ux + r[0][1] * uy + r[0][2] * uz;
        double py = r[1][0] * ux + r[1][1] * uy + r[1][2] * uz;
        profondeur = r[2][0] * ux + r[2][1] * uy + r[2][2] * uz;
        sx = cx + echelleX * px;
        sy = cy - echelleY * py;
    }
    void ecran(double x, double y, double z, double& sx, double& sy, double& profondeur) const {
        ecranBoite(normale(0, x), normale(1, y), normale(2, z), sx, sy, profondeur);
    }
};

// Ce qui se dessine dans la boîte, à trier par profondeur.
struct Primitive {
    enum Genre { Face, Segment, Marqueur } genre = Face;
    double profondeur = 0;
    std::vector<double> x, y;
    std::string fond, bord;
    double opacite = 1, epaisseur = 1;
    std::string motif = "-";
    FormeMarqueur forme;
};

std::string hexa(int r, int v, int b) { return formater("#%02X%02X%02X", r, v, b); }

// La couleur d'une valeur, à travers la palette et CLim.
std::string couleurValeur(const std::vector<double>& palette, double cmin, double cmax,
                          double valeur) {
    int r, v, b;
    couleurEchelle(palette, valeur, cmin, cmax, r, v, b);
    return hexa(r, v, b);
}

// Une face ou une arête : « flat » ou « interp » prennent la couleur de la
// maille, « none » rien, sinon la couleur dite.
std::string selonMode(const std::string& mode, const std::string& couleurMaille) {
    if (mode == "flat" || mode == "interp") return couleurMaille;
    return mode.empty() ? std::string("none") : mode;
}

}  // namespace

namespace dessin {

void dessinerEspace(const Figure& figure, const Axes& a, Toile& toile, int gauche, int droite,
                    int haut, int bas) {
    Projection p;
    limitesAxe(a, p.bornes[0][0], p.bornes[0][1], p.bornes[1][0], p.bornes[1][1]);
    limitesAxeZ(a, p.bornes[2][0], p.bornes[2][1]);
    p.inverse[0] = a.xInverse;
    p.inverse[1] = a.yInverse;
    // « axis equal » : une unité a la même longueur sur les trois axes.
    if (a.proportions == Axes::Proportions::Egales) {
        double etendues[3], plusGrande = 0;
        for (int k = 0; k < 3; ++k) {
            etendues[k] = p.bornes[k][1] - p.bornes[k][0];
            plusGrande = std::max(plusGrande, etendues[k]);
        }
        for (int k = 0; k < 3; ++k)
            p.demi[k] = plusGrande > 0 ? 0.5 * etendues[k] / plusGrande : 0.5;
    }
    const double az = a.azimut * PI / 180, el = a.elevation * PI / 180;
    const double ca = std::cos(az), sa = std::sin(az), ce = std::cos(el), se = std::sin(el);
    const double r[3][3] = {{ca, sa, 0}, {-se * sa, se * ca, ce}, {ce * sa, -ce * ca, se}};
    for (int i = 0; i < 3; ++i)
        for (int j = 0; j < 3; ++j) p.r[i][j] = r[i][j];

    // La boîte projetée, mise à l'échelle pour tenir dans le cadre.
    double sxMin = INFINITY, sxMax = -INFINITY, syMin = INFINITY, syMax = -INFINITY;
    for (int c = 0; c < 8; ++c) {
        double ux = (c & 1 ? 1 : -1) * p.demi[0], uy = (c & 2 ? 1 : -1) * p.demi[1];
        double uz = (c & 4 ? 1 : -1) * p.demi[2];
        double px = r[0][0] * ux + r[0][1] * uy + r[0][2] * uz;
        double py = r[1][0] * ux + r[1][1] * uy + r[1][2] * uz;
        sxMin = std::min(sxMin, px);
        sxMax = std::max(sxMax, px);
        syMin = std::min(syMin, py);
        syMax = std::max(syMax, py);
    }
    // MATLAB étire la boîte pour remplir le cadre (« stretch-to-fill »),
    // sauf quand les proportions sont imposées (« axis equal ») : alors
    // une même échelle dans les deux sens.
    const double largeur = droite - gauche, hauteur = bas - haut;
    p.echelleX = largeur / std::max(sxMax - sxMin, 1e-9);
    p.echelleY = hauteur / std::max(syMax - syMin, 1e-9);
    if (a.proportions != Axes::Proportions::Auto)
        p.echelleX = p.echelleY = std::min(p.echelleX, p.echelleY);
    p.cx = (gauche + droite) / 2.0 - p.echelleX * (sxMin + sxMax) / 2;
    p.cy = (haut + bas) / 2.0 + p.echelleY * (syMin + syMax) / 2;

    // Les plans du fond : du côté opposé à l'observateur, dont la direction
    // est la troisième ligne de viewmtx.
    const double fond[3] = {r[2][0] > 0 ? -p.demi[0] : p.demi[0],
                            r[2][1] > 0 ? -p.demi[1] : p.demi[1],
                            r[2][2] >= 0 ? -p.demi[2] : p.demi[2]};
    auto point = [&](double ux, double uy, double uz, double& sx, double& sy) {
        double profondeur;
        p.ecranBoite(ux, uy, uz, sx, sy, profondeur);
    };
    auto segmentBoite = [&](double x0, double y0, double z0, double x1, double y1, double z1,
                            const Trait& t) {
        double ax, ay, bx, by;
        point(x0, y0, z0, ax, ay);
        point(x1, y1, z1, bx, by);
        toile.ligne(ax, ay, bx, by, t);
    };

    std::vector<double> graduations[3];
    if (a.axesVisibles) {
        graduations[0] = graduationsEffectives(a, 'x', p.bornes[0][0], p.bornes[0][1], false);
        graduations[1] = graduationsEffectives(a, 'y', p.bornes[1][0], p.bornes[1][1], false);
        graduations[2] = a.ticksZ.empty() ? graduationsAxe(p.bornes[2][0], p.bornes[2][1], 6, false)
                                          : a.ticksZ;
        for (int k = 0; k < 3; ++k) {
            std::vector<double> dedans;
            for (double v : graduations[k])
                if (v >= p.bornes[k][0] - 1e-9 * (std::fabs(v) + 1) &&
                    v <= p.bornes[k][1] + 1e-9 * (std::fabs(v) + 1))
                    dedans.push_back(v);
            graduations[k] = dedans;
        }
    }

    // La grille, sur les trois plans du fond.
    if (a.axesVisibles && a.grille) {
        const Trait g = traitGrille();
        for (double v : graduations[0]) {
            double u = p.normale(0, v);
            segmentBoite(u, -p.demi[1], fond[2], u, p.demi[1], fond[2], g);
            segmentBoite(u, fond[1], -p.demi[2], u, fond[1], p.demi[2], g);
        }
        for (double v : graduations[1]) {
            double u = p.normale(1, v);
            segmentBoite(-p.demi[0], u, fond[2], p.demi[0], u, fond[2], g);
            segmentBoite(fond[0], u, -p.demi[2], fond[0], u, p.demi[2], g);
        }
        for (double v : graduations[2]) {
            double u = p.normale(2, v);
            segmentBoite(fond[0], -p.demi[1], u, fond[0], p.demi[1], u, g);
            segmentBoite(-p.demi[0], fond[1], u, p.demi[0], fond[1], u, g);
        }
    }

    // Les séries, réduites à des primitives.
    const std::vector<double>& palette = paletteEnVigueur(figure, a);
    double cmin, cmax;
    limitesCouleur(a, cmin, cmax);
    std::vector<Primitive> primitives;
    bool desFaces = false;
    struct TextePose {
        double x, y;
        std::vector<Morceau> texte;
        StyleTexte style;
    };
    std::vector<TextePose> textes;
    for (const auto& s : a.series) {
        const std::size_t n = std::min(s.x.size(), s.y.size());
        auto z = [&](std::size_t k) { return k < s.z.size() ? s.z[k] : 0.0; };
        const std::string couleurSerie = couleurDeSerie(figure, a, s);
        if (s.genre == GenreTrace::Surface) {
            const int m = s.lignesGrille, c = s.colonnesGrille;
            if (m < 2 || c < 2 || n < (std::size_t)m * (std::size_t)c) continue;
            std::vector<double> sx(n), sy(n), sp(n);
            for (std::size_t k = 0; k < n; ++k) p.ecran(s.x[k], s.y[k], z(k), sx[k], sy[k], sp[k]);
            auto valeur = [&](std::size_t k) {
                return k < s.valeursCouleurPoints.size() ? s.valeursCouleurPoints[k] : z(k);
            };
            for (int j = 0; j + 1 < c; ++j)
                for (int i = 0; i + 1 < m; ++i) {
                    std::size_t k00 = (std::size_t)i + (std::size_t)j * (std::size_t)m;
                    std::size_t k10 = k00 + 1, k01 = k00 + (std::size_t)m, k11 = k01 + 1;
                    bool fini = true;
                    for (std::size_t k : {k00, k10, k11, k01})
                        if (!std::isfinite(sx[k]) || !std::isfinite(sy[k])) fini = false;
                    if (!fini) continue;
                    double v = s.modeFaces == "interp" || s.modeAretes == "interp"
                                   ? (valeur(k00) + valeur(k10) + valeur(k11) + valeur(k01)) / 4
                                   : valeur(k00);
                    std::string couleurMaille = couleurValeur(palette, cmin, cmax, v);
                    Primitive f;
                    f.genre = Primitive::Face;
                    f.x = {sx[k00], sx[k10], sx[k11], sx[k01]};
                    f.y = {sy[k00], sy[k10], sy[k11], sy[k01]};
                    f.profondeur = (sp[k00] + sp[k10] + sp[k11] + sp[k01]) / 4;
                    f.fond = selonMode(s.modeFaces, couleurMaille);
                    f.bord = selonMode(s.modeAretes, couleurMaille);
                    f.opacite = s.opacite;
                    f.epaisseur = s.epaisseur;
                    f.motif = s.style == "none" ? "-" : s.style;
                    if (s.style == "none") f.bord = "none";
                    primitives.push_back(std::move(f));
                    desFaces = true;
                }
            continue;
        }
        if (s.genre == GenreTrace::Polygone) {
            // Des faces séparées par des NaN, une couleur par face.
            std::size_t debut = 0, rang = 0;
            while (debut < n) {
                std::size_t fin = debut;
                while (fin < n && std::isfinite(s.x[fin]) && std::isfinite(s.y[fin])) ++fin;
                if (fin - debut >= 3) {
                    Primitive f;
                    f.genre = Primitive::Face;
                    double somme = 0;
                    for (std::size_t k = debut; k < fin; ++k) {
                        double ex, ey, pr;
                        p.ecran(s.x[k], s.y[k], z(k), ex, ey, pr);
                        f.x.push_back(ex);
                        f.y.push_back(ey);
                        somme += pr;
                    }
                    f.profondeur = somme / (double)(fin - debut);
                    std::string couleurFace = couleurSerie;
                    if (!s.couleursPoints.empty())
                        couleurFace = s.couleursPoints[std::min(rang, s.couleursPoints.size() - 1)];
                    else if (!s.valeursCouleurPoints.empty())
                        couleurFace = couleurValeur(
                            palette, cmin, cmax,
                            s.valeursCouleurPoints[std::min(rang,
                                                            s.valeursCouleurPoints.size() - 1)]);
                    f.fond = selonMode(s.modeFaces, couleurFace);
                    f.bord = selonMode(s.modeAretes, couleurFace);
                    f.opacite = s.opacite;
                    f.epaisseur = s.epaisseur == 1.5 ? 0.5 : s.epaisseur;
                    primitives.push_back(std::move(f));
                    desFaces = true;
                }
                ++rang;
                debut = fin + 1;
            }
            continue;
        }
        if (s.genre == GenreTrace::Texte) {
            if (s.x.empty() || s.y.empty()) continue;
            TextePose t;
            double pr;
            p.ecran(s.x[0], s.y[0], z(0), t.x, t.y, pr);
            t.texte = morceauxInterpretes(s.legendeConstante, s.interprete);
            t.style.taille = s.taillePoliceTexte > 0 ? s.taillePoliceTexte : 11.0;
            t.style.tailleExplicite = true;
            t.style.ancre = s.alignement;
            t.style.couleur = s.couleur;
            textes.push_back(std::move(t));
            continue;
        }
        if (s.genre == GenreTrace::Points) {
            const std::string marqueur = s.marqueur.empty() ? "o" : s.marqueur;
            for (std::size_t k = 0; k < n; ++k) {
                Primitive m;
                m.genre = Primitive::Marqueur;
                double ex, ey;
                p.ecran(s.x[k], s.y[k], z(k), ex, ey, m.profondeur);
                if (!std::isfinite(ex) || !std::isfinite(ey)) continue;
                m.x = {ex};
                m.y = {ey};
                double aire = s.airesPoints.empty()
                                  ? s.tailleMarqueur * s.tailleMarqueur
                                  : s.airesPoints[std::min(k, s.airesPoints.size() - 1)];
                m.forme = formeMarqueur(marqueur, std::sqrt(std::max(aire, 0.0)));
                couleursPoint(s, couleurPoint(palette, cmin, cmax, s, k), m.bord, m.fond);
                if (m.bord == "none" && m.forme.genre == FormeMarqueur::Traits)
                    m.bord = couleurPoint(palette, cmin, cmax, s, k);
                primitives.push_back(std::move(m));
            }
            continue;
        }
        if (s.genre != GenreTrace::Ligne) continue;
        // Une courbe : ses segments, et ses marqueurs.
        std::vector<double> sx(n), sy(n), sp(n);
        for (std::size_t k = 0; k < n; ++k) p.ecran(s.x[k], s.y[k], z(k), sx[k], sy[k], sp[k]);
        if (s.style != "none")
            for (std::size_t k = 0; k + 1 < n; ++k) {
                if (!std::isfinite(sx[k]) || !std::isfinite(sx[k + 1]) || !std::isfinite(sy[k]) ||
                    !std::isfinite(sy[k + 1]))
                    continue;
                Primitive t;
                t.genre = Primitive::Segment;
                t.x = {sx[k], sx[k + 1]};
                t.y = {sy[k], sy[k + 1]};
                t.profondeur = (sp[k] + sp[k + 1]) / 2;
                t.bord = couleurSerie;
                t.epaisseur = s.epaisseur;
                t.motif = s.style;
                primitives.push_back(std::move(t));
            }
        if (!s.marqueur.empty() && s.marqueur != "none") {
            FormeMarqueur forme = formeMarqueur(s.marqueur, s.tailleMarqueur);
            std::string bord, face;
            couleursMarqueur(s, couleurSerie, bord, face);
            for (std::size_t k = 0; k < n; ++k) {
                if (!std::isfinite(sx[k]) || !std::isfinite(sy[k])) continue;
                Primitive m;
                m.genre = Primitive::Marqueur;
                m.x = {sx[k]};
                m.y = {sy[k]};
                m.profondeur = sp[k];
                m.forme = forme;
                m.bord = bord;
                m.fond = face;
                primitives.push_back(std::move(m));
            }
        }
    }

    // Du plus lointain au plus proche. Sans face, l'ordre des séries suffit
    // et les segments d'une courbe se rejoignent en une seule ligne.
    if (desFaces)
        std::stable_sort(primitives.begin(), primitives.end(),
                         [](const Primitive& u, const Primitive& v) {
                             return u.profondeur < v.profondeur;
                         });
    for (std::size_t k = 0; k < primitives.size(); ++k) {
        const Primitive& q = primitives[k];
        if (q.genre == Primitive::Face) {
            Trait bord = trait(q.bord, q.epaisseur, q.motif);
            toile.polygone(q.x, q.y, q.fond, q.opacite, q.bord == "none" ? nullptr : &bord);
        } else if (q.genre == Primitive::Marqueur) {
            dessinerMarqueur(toile, q.forme, q.x[0], q.y[0], q.bord, q.fond);
        } else {
            // Les segments qui se suivent, d'un même trait, ne font qu'une
            // ligne : un fichier léger, des pointillés continus.
            std::vector<double> lx = q.x, ly = q.y;
            while (k + 1 < primitives.size() && primitives[k + 1].genre == Primitive::Segment &&
                   primitives[k + 1].bord == q.bord && primitives[k + 1].motif == q.motif &&
                   primitives[k + 1].epaisseur == q.epaisseur &&
                   primitives[k + 1].x[0] == lx.back() && primitives[k + 1].y[0] == ly.back()) {
                ++k;
                lx.push_back(primitives[k].x[1]);
                ly.push_back(primitives[k].y[1]);
            }
            toile.polyligne(lx, ly, trait(q.bord, q.epaisseur, q.motif));
        }
    }
    for (const auto& t : textes) toile.texte(t.x, t.y, t.texte, t.style);

    if (!a.axesVisibles) return;

    // Les trois axes : x et y sur le plan du fond en z, à l'avant ; z sur
    // l'arête verticale la plus à gauche.
    const double avantX = -fond[0], avantY = -fond[1];
    double coinX = -p.demi[0], coinY = -p.demi[1], plusAGauche = INFINITY;
    for (int c = 0; c < 4; ++c) {
        double ux = (c & 1 ? 1 : -1) * p.demi[0], uy = (c & 2 ? 1 : -1) * p.demi[1];
        double sx, sy;
        point(ux, uy, fond[2], sx, sy);
        if (sx < plusAGauche - 1e-9) {
            plusAGauche = sx;
            coinX = ux;
            coinY = uy;
        }
    }
    double centreX, centreY;
    point(0, 0, 0, centreX, centreY);
    struct Axe {
        int indice;
        const std::string* etiquette;
        const std::vector<std::string>* textes;
        const char* cible;
    };
    const Axe axes[3] = {{0, &a.etiquetteX, &a.etiquettesTicksX, "xlabel"},
                         {1, &a.etiquetteY, &a.etiquettesTicksY, "ylabel"},
                         {2, &a.etiquetteZ, &a.etiquettesTicksZ, "zlabel"}};
    for (const Axe& axe : axes) {
        // L'arête de l'axe, d'un bout à l'autre.
        auto lieu = [&](double u, double& sx, double& sy) {
            if (axe.indice == 0) point(u, avantY, fond[2], sx, sy);
            else if (axe.indice == 1) point(avantX, u, fond[2], sx, sy);
            else point(coinX, coinY, u, sx, sy);
        };
        const double demi = p.demi[axe.indice];
        double x0, y0, x1, y1;
        lieu(-demi, x0, y0);
        lieu(demi, x1, y1);
        if (std::hypot(x1 - x0, y1 - y0) < 2) continue;  // vue dans l'axe : rien à graduer
        toile.ligne(x0, y0, x1, y1, traitAxe());
        // La normale à l'arête, vers l'extérieur de la boîte.
        double nx = -(y1 - y0), ny = x1 - x0, norme = std::hypot(nx, ny);
        nx /= norme;
        ny /= norme;
        if (nx * ((x0 + x1) / 2 - centreX) + ny * ((y0 + y1) / 2 - centreY) < 0) {
            nx = -nx;
            ny = -ny;
        }
        // Chaque étiquette est centrée sur la normale, à douze pixels de
        // l'arête : celles de x et de y, qui partent du même coin, s'en
        // écartent chacune de son côté au lieu de se toucher.
        StyleTexte st;
        st.ancre = 'c';
        double plusLarge = 0;
        const std::vector<double>& t = graduations[axe.indice];
        for (std::size_t k = 0; k < t.size(); ++k) {
            double sx, sy;
            lieu(p.normale(axe.indice, t[k]), sx, sy);
            toile.ligne(sx, sy, sx - 5 * nx, sy - 5 * ny, traitAxe());
            std::vector<Morceau> texte =
                k < axe.textes->size()
                    ? morceauxInterpretes((*axe.textes)[k], interpreteDe(a, "ticks"))
                    : etiquetteGraduation(t[k], false);
            double l = toile.largeur(texte, 12);
            plusLarge = std::max(plusLarge, l);
            toile.texte(sx + nx * (12 + l / 2), sy + ny * (10 + 7) + 4, texte, st);
        }
        if (!axe.etiquette->empty()) {
            // Au-delà des graduations, le long de l'arête, comme dans MATLAB.
            double recul = 22 + std::fabs(nx) * plusLarge + std::fabs(ny) * 16;
            double angle = -std::atan2(y1 - y0, x1 - x0) * 180 / PI;
            if (angle > 90) angle -= 180;
            if (angle < -90) angle += 180;
            StyleTexte se;
            se.ancre = 'c';
            se.angle = angle;
            toile.texte((x0 + x1) / 2 + recul * nx, (y0 + y1) / 2 + recul * ny + 4,
                        morceauxInterpretes(*axe.etiquette, interpreteDe(a, axe.cible)), se);
        }
    }
}

}  // namespace dessin
}  // namespace matlibre
