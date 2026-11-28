// Dessin.cpp — le dessin d'une figure, sur une toile (voir Toile.h).
#include <algorithm>
#include <cmath>

#include "matlibre/Erreur.h"
#include "matlibre/Toile.h"
#include "Commun.h"

namespace matlibre {

double largeurHelvetica(const std::string& texte, double taille, bool gras) {
    static const int chasses[95] = {
        278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278,
        556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556,
        1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778,
        667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556,
        333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556,
        556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584};
    double milliemes = 0;
    for (std::size_t i = 0; i < texte.size(); ++i) {
        unsigned char c = (unsigned char)texte[i];
        if ((c & 0xC0) == 0x80) continue;  // suite d'un caractère UTF-8
        milliemes += (c >= 32 && c < 127) ? chasses[c - 32] : 556;
    }
    // Le gras d'Helvetica est plus large d'un douzième environ.
    return milliemes / 1000.0 * taille * (gras ? 1.08 : 1.0);
}

namespace {

struct Echelle {
    double min = 0, max = 1;
    double pixelsMin = 0, pixelsMax = 100;
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

namespace dessin {

Trait traitAxe() {
    Trait t;
    t.couleur = "#222";
    t.classe = "axe";
    return t;
}

Trait traitGrille() {
    Trait t;
    t.couleur = "#ccc";
    t.epaisseur = 0.5;
    t.classe = "grille";
    return t;
}

Trait trait(const std::string& couleur, double epaisseur, const std::string& motif) {
    Trait t;
    t.couleur = couleur;
    t.epaisseur = epaisseur;
    t.motif = motif;
    return t;
}

std::vector<Morceau> simple(const std::string& texte) {
    Morceau m;
    m.texte = texte;
    return {m};
}

// L'étiquette d'une graduation. Sur un axe logarithmique, MATLAB écrit les
// puissances de dix en exposant — 10 puissance moins deux, et non 0,01.
std::vector<Morceau> etiquetteGraduation(double v, bool log) {
    if (log && v > 0) {
        double e = std::log10(v);
        double arrondi = std::round(e);
        if (std::fabs(e - arrondi) < 1e-9) {
            std::vector<Morceau> r = simple("10");
            Morceau exposant;
            exposant.texte = formater("%d", (int)arrondi);
            exposant.niveau = 1;
            exposant.echelle = 0.75;
            r.push_back(exposant);
            return r;
        }
    }
    return simple(nombreCourt(v));
}

// Un marqueur de MATLAB : BORD et FACE sont des couleurs, FACE pouvant
// valoir « none ».
void dessinerMarqueur(Toile& toile, const FormeMarqueur& f, double px, double py,
                      const std::string& bord, const std::string& face) {
    Trait contour = trait(bord, 1);
    switch (f.genre) {
        case FormeMarqueur::Rien:
            return;
        case FormeMarqueur::Cercle:
            toile.cercle(px, py, f.rayon, f.toujoursPlein ? bord : face, &contour);
            return;
        case FormeMarqueur::Polygone: {
            std::vector<double> x, y;
            for (const auto& p : f.points) {
                x.push_back(px + p.first);
                y.push_back(py + p.second);
            }
            toile.polygone(x, y, face, 1.0, &contour);
            return;
        }
        case FormeMarqueur::Traits: {
            std::vector<double> x, y;
            for (std::size_t k = 0; k + 1 < f.points.size(); k += 2) {
                if (k) {
                    x.push_back(NAN);
                    y.push_back(NAN);
                }
                x.push_back(px + f.points[k].first);
                y.push_back(py + f.points[k].second);
                x.push_back(px + f.points[k + 1].first);
                y.push_back(py + f.points[k + 1].second);
            }
            toile.polyligne(x, y, contour);
            return;
        }
    }
}

// Les couleurs de bord et de face des marqueurs d'une série.
void couleursMarqueur(const Serie& s, const std::string& couleur, std::string& bord,
                      std::string& face) {
    bord = s.couleurBordMarqueur.empty() || s.couleurBordMarqueur == "auto"
               ? couleur
               : s.couleurBordMarqueur;
    if (s.couleurFaceMarqueur.empty() || s.couleurFaceMarqueur == "none")
        face = "none";
    else if (s.couleurFaceMarqueur == "auto")
        face = couleur;
    else
        face = s.couleurFaceMarqueur;
}

std::string rvb(int r, int v, int b) { return formater("rgb(%d,%d,%d)", r, v, b); }

extern const double PI;
const double PI = 3.14159265358979323846;

// La couleur du point K d'un nuage : la sienne, celle que la palette donne
// à sa valeur, ou celle de la série.
std::string couleurPoint(const std::vector<double>& palette, double cmin, double cmax,
                         const Serie& s, std::size_t k) {
    if (!s.couleursPoints.empty())
        return s.couleursPoints[std::min(k, s.couleursPoints.size() - 1)];
    if (!s.valeursCouleurPoints.empty()) {
        int r, v, b;
        const std::size_t rang = std::min(k, s.valeursCouleurPoints.size() - 1);
        couleurEchelle(palette, s.valeursCouleurPoints[rang], cmin, cmax, r, v, b);
        return formater("#%02X%02X%02X", r, v, b);
    }
    return s.couleur;
}

// Le bord et la face d'un marqueur de nuage : la couleur du point
// (« flat » dans MATLAB) sauf couleur imposée ; la face est vide, sauf
// sous « 'filled' » ou MarkerFaceColor.
void couleursPoint(const Serie& s, const std::string& couleur, std::string& bord,
                   std::string& face) {
    // Sous « 'filled' », MATLAB ôte le bord (MarkerEdgeColor 'none') :
    // le point est une tache de sa couleur.
    const std::string& b = s.couleurBordMarqueur;
    if (b.empty() && s.pointsRemplis) bord = "none";
    else bord = b.empty() || b == "auto" || b == "flat" ? couleur : b;
    const std::string& f = s.couleurFaceMarqueur;
    if (f == "auto" || f == "flat") face = couleur;
    else if (!f.empty() && f != "none") face = f;
    else face = s.pointsRemplis ? couleur : std::string("none");
}

}  // namespace dessin

using namespace dessin;

namespace {

// La barre de couleurs, du côté que dit sa position. Dehors, elle occupe
// la place que dessinerAxe lui a réservée ; dedans, elle se pose à huit
// pixels du bord de la boîte. Ses graduations et leurs textes sont du côté
// opposé à la boîte quand elle est dehors, du côté du centre quand elle
// est dedans ; son étiquette au-delà.
void dessinerBarre(Toile& toile, const Axes& a, const BarreCouleurs& barre, int gauche,
                   int droite, int haut, int bas, double bordCase, double descenteX,
                   double largeurTextes) {
    const std::string& ou = a.positionBarre;
    const bool verticale = ou.compare(0, 5, "north") != 0 && ou.compare(0, 5, "south") != 0;
    const bool dehors = ou.size() > 7 && ou.compare(ou.size() - 7, 7, "outside") == 0;
    const bool ouest = ou.compare(0, 4, "west") == 0;
    const bool nord = ou.compare(0, 5, "north") == 0;
    const double bande = 14;
    const std::size_t tranches = barre.tranches.size() / 3;
    if (tranches == 0) return;
    auto teinte = [&](std::size_t k) {
        return formater("#%02X%02X%02X", barre.tranches[3 * k], barre.tranches[3 * k + 1],
                        barre.tranches[3 * k + 2]);
    };
    const double etiquette = a.etiquetteBarre.empty() ? 0.0 : 22.0;
    toile.groupe("barreCouleurs");
    StyleTexte st;
    StyleTexte stEtiquette;
    stEtiquette.ancre = 'c';
    if (verticale) {
        const double y0 = dehors ? haut : haut + 8, y1 = dehors ? bas : bas - 8;
        // Les textes à droite de la bande : dehors à l'est, dedans à l'ouest.
        const bool textesADroite = dehors ? !ouest : ouest;
        double x0;
        if (dehors) x0 = ouest ? bordCase + 4 + etiquette + largeurTextes + 7 : droite + 14;
        else x0 = ouest ? gauche + 8 : droite - 8 - bande;
        const double pas = (y1 - y0) / (double)tranches;
        for (std::size_t k = 0; k < tranches; ++k)
            toile.rectangle(x0, y1 - (double)(k + 1) * pas, bande, pas + 0.5, teinte(k), 1.0,
                            nullptr);
        Trait cadre = traitAxe();
        toile.rectangle(x0, y0, bande, y1 - y0, "none", 1.0, &cadre);
        st.ancre = textesADroite ? 'l' : 'r';
        for (std::size_t k = 0; k < barre.valeurs.size(); ++k) {
            double y = y1 - barre.fractions[k] * (y1 - y0);
            if (textesADroite) {
                toile.ligne(x0 + bande, y, x0 + bande + 4, y, traitAxe());
                toile.texte(x0 + bande + 7, y + 4, simple(barre.textes[k]), st);
            } else {
                toile.ligne(x0, y, x0 - 4, y, traitAxe());
                toile.texte(x0 - 7, y + 4, simple(barre.textes[k]), st);
            }
        }
        if (!a.etiquetteBarre.empty()) {
            // Écrite de bas en haut, comme l'étiquette des ordonnées.
            stEtiquette.angle = 90;
            double x = textesADroite ? x0 + bande + 7 + largeurTextes + 16
                                     : x0 - 7 - largeurTextes - 4;
            toile.texte(x, (y0 + y1) / 2,
                        morceauxInterpretes(a.etiquetteBarre, interpreteDe(a, "colorbarlabel")),
                        stEtiquette);
        }
    } else {
        const double xg = dehors ? gauche : gauche + 8, xd = dehors ? droite : droite - 8;
        // Les textes sous la bande : dehors au sud, dedans au nord.
        const bool textesDessous = dehors ? !nord : nord;
        double y0;
        if (dehors)
            y0 = nord ? haut - 8 - bande
                      : bas + 28 + descenteX + (a.etiquetteX.empty() ? 0.0 : 22.0);
        else
            y0 = nord ? haut + 8 : bas - 8 - bande;
        const double pas = (xd - xg) / (double)tranches;
        for (std::size_t k = 0; k < tranches; ++k)
            toile.rectangle(xg + (double)k * pas, y0, pas + 0.5, bande, teinte(k), 1.0, nullptr);
        Trait cadre = traitAxe();
        toile.rectangle(xg, y0, xd - xg, bande, "none", 1.0, &cadre);
        st.ancre = 'c';
        for (std::size_t k = 0; k < barre.valeurs.size(); ++k) {
            double x = xg + barre.fractions[k] * (xd - xg);
            if (textesDessous) {
                toile.ligne(x, y0 + bande, x, y0 + bande + 4, traitAxe());
                toile.texte(x, y0 + bande + 16, simple(barre.textes[k]), st);
            } else {
                toile.ligne(x, y0, x, y0 - 4, traitAxe());
                toile.texte(x, y0 - 7, simple(barre.textes[k]), st);
            }
        }
        if (!a.etiquetteBarre.empty())
            toile.texte((xg + xd) / 2, textesDessous ? y0 + bande + 34 : y0 - 25,
                        morceauxInterpretes(a.etiquetteBarre, interpreteDe(a, "colorbarlabel")),
                        stEtiquette);
    }
    toile.finGroupe();
}

// Le dessin d'un axe : ses graduations, ses séries, sa barre de couleurs,
// ses titres et sa légende.
void dessinerAxe(const Figure& figure, const Axes& a, Toile& toile, int L, int H,
                 int indiceAxe) {
    (void)indiceAxe;
    double fx, fy, fl, fh;
    cadreAxes(a, fx, fy, fl, fh);
    // Les marges d'une case sont bornées par sa taille : une case haute de
    // cent cinquante pixels — la moitié d'un Bode dans un quart de figure —
    // ne peut pas en donner quatre-vingt-dix aux étiquettes.
    double largeurCase = fl * L, hauteurCase = fh * H;
    int gauche = (int)(fx * L + std::min(70.0, 0.22 * largeurCase));
    int droite = (int)((fx + fl) * L - std::min(30.0, 0.10 * largeurCase));
    int haut = (int)(fy * H + std::min(40.0, 0.16 * hauteurCase));
    int bas = (int)((fy + fh) * H - std::min(50.0, 0.22 * hauteurCase));
    // Des étiquettes de graduation écrites à la main (« yticklabels »)
    // peuvent être longues : la marge s'élargit pour qu'elles tiennent,
    // comme MATLAB le fait, au lieu de les rogner au bord.
    double largeurEtiquettesY = 0;
    for (const auto& e : a.etiquettesTicksY)
        largeurEtiquettesY =
            std::max(largeurEtiquettesY,
                     toile.largeur(morceauxInterpretes(e, interpreteDe(a, "ticks")), 12));
    if (a.axesVisibles && largeurEtiquettesY > 0) {
        int requis = (int)(fx * L + largeurEtiquettesY + 14 +
                           (a.etiquetteY.empty() ? 0.0 : 24.0));
        gauche = std::max(gauche, requis);
    }
    // Des étiquettes d'abscisses inclinées (« xtickangle ») descendent plus
    // bas qu'une ligne de texte : la marge s'agrandit d'autant, et
    // l'étiquette de l'axe descend avec elle.
    double descenteX = 0;
    if (a.axesVisibles && a.angleTicksX != 0) {
        double x0, x1, y0, y1;
        limitesAxe(a, x0, x1, y0, y1);
        std::vector<double> t = graduationsEffectives(a, 'x', x0, x1, a.logX);
        double plusLarge = 0;
        for (std::size_t k = 0; k < t.size(); ++k)
            plusLarge = std::max(
                plusLarge, toile.largeur(morceauxInterpretes(k < a.etiquettesTicksX.size()
                                                                 ? a.etiquettesTicksX[k]
                                                                 : nombreCourt(t[k]),
                                                             interpreteDe(a, "ticks")),
                                         12));
        double angle = std::fabs(a.angleTicksX) * PI / 180;
        descenteX = std::max(0.0, plusLarge * std::sin(angle) + 12 * std::cos(angle) - 12);
        bas -= (int)std::ceil(descenteX);
    }
    if (droite <= gauche + 10 || bas <= haut + 10) return;
    int hautTitre = haut;

    // La légende se mesure avant les échelles : placée hors de l'axe, elle
    // lui prend de la place, comme dans MATLAB.
    std::vector<EntreeLegende> entrees;
    if (a.legendeVisible) entrees = entreesLegende(a);
    const double policeLegende = 12, ligneLegende = 18;
    double largeurLegende = 0, hauteurLegende = 0;
    std::vector<double> largeursEntrees;
    for (const auto& e : entrees) {
        double l = 36 +
                   toile.largeur(morceauxInterpretes(e.texte, interpreteDe(a, "legend")),
                                 policeLegende) +
                   10;
        largeursEntrees.push_back(l);
        if (a.legendeHorizontale) largeurLegende += l;
        else largeurLegende = std::max(largeurLegende, l);
    }
    if (!entrees.empty())
        hauteurLegende = a.legendeHorizontale ? ligneLegende + 8
                                              : ligneLegende * (double)entrees.size() + 8;
    const std::string& ou = a.positionLegende;
    auto finitPar = [&](const std::string& fin) {
        return ou.size() >= fin.size() &&
               ou.compare(ou.size() - fin.size(), fin.size(), fin) == 0;
    };
    bool dehors = !entrees.empty() && finitPar("outside");
    double xLegende = 0, yLegende = 0;
    if (dehors) {
        if (ou == "northoutside") {
            yLegende = haut;
            haut += (int)std::ceil(hauteurLegende + 8);
            xLegende = (gauche + droite) / 2.0 - largeurLegende / 2;
        } else if (ou == "southoutside") {
            bas -= (int)std::ceil(hauteurLegende + 10);
            yLegende = bas + 46 + descenteX;
            xLegende = (gauche + droite) / 2.0 - largeurLegende / 2;
        } else if (ou == "westoutside" || ou == "northwestoutside" ||
                   ou == "southwestoutside") {
            xLegende = fx * L + 6;
            gauche += (int)std::ceil(largeurLegende + 12);
            yLegende = ou == "northwestoutside"   ? haut
                       : ou == "southwestoutside" ? bas - hauteurLegende
                                                  : (haut + bas) / 2.0 - hauteurLegende / 2;
        } else {
            droite -= (int)std::ceil(largeurLegende + 12);
            xLegende = droite + 12;
            yLegende = ou == "northeastoutside" || ou == "bestoutside" ? haut
                       : ou == "southeastoutside" ? bas - hauteurLegende
                                                  : (haut + bas) / 2.0 - hauteurLegende / 2;
        }
        if (droite <= gauche + 10 || bas <= haut + 10) return;
    }

    // La barre de couleurs prend sa place hors de la boîte — à droite par
    // défaut, ou du côté que dit sa position —, ou se pose dedans
    // (« east », « south »…) sans rien lui prendre.
    BarreCouleurs barre;
    const std::string& ouBarre = a.positionBarre;
    const bool barreVerticale = ouBarre.compare(0, 5, "north") != 0 &&
                                ouBarre.compare(0, 5, "south") != 0;
    const bool barreDehors = ouBarre.size() > 7 &&
                             ouBarre.compare(ouBarre.size() - 7, 7, "outside") == 0;
    const bool barreOuest = ouBarre.compare(0, 4, "west") == 0;
    const bool barreNord = ouBarre.compare(0, 5, "north") == 0;
    double largeurTextesBarre = 0;
    const double placeEtiquetteBarre = a.etiquetteBarre.empty() ? 0.0 : 22.0;
    if (a.barreCouleurs) {
        barre = barreCouleurs(figure, a);
        for (const auto& t : barre.textes)
            largeurTextesBarre = std::max(largeurTextesBarre, toile.largeur(simple(t), 12));
        if (barreDehors && barreVerticale) {
            int place = (int)std::ceil(std::max((double)LARGEUR_BARRE_COULEURS,
                                                35 + largeurTextesBarre + 8 + placeEtiquetteBarre));
            if (barreOuest) gauche += place;
            else droite -= place;
        } else if (barreDehors) {
            int place = (int)std::ceil(40 + placeEtiquetteBarre);
            if (barreNord) haut += place;
            else bas -= place;
        }
        if (droite <= gauche + 10 || bas <= haut + 10) return;
    }

    // « yyaxis » : le second axe des ordonnées prend sa place à droite —
    // ses graduations, puis son étiquette.
    double yminDroite = 0, ymaxDroite = 1, largeurDroite = 0;
    std::vector<double> tyDroite;
    const bool deuxOrdonnees = a.deuxOrdonnees && !vueEspace(a);
    if (deuxOrdonnees) {
        limitesAxeDroite(a, yminDroite, ymaxDroite);
        if (a.axesVisibles) {
            tyDroite = a.ticksYDroite.empty()
                           ? graduationsAxe(yminDroite, ymaxDroite, 6, a.logYDroite)
                           : a.ticksYDroite;
            for (std::size_t k = 0; k < tyDroite.size(); ++k)
                largeurDroite = std::max(
                    largeurDroite,
                    toile.largeur(k < a.etiquettesTicksYDroite.size()
                                      ? morceauxInterpretes(a.etiquettesTicksYDroite[k],
                                                            interpreteDe(a, "ticks"))
                                      : etiquetteGraduation(tyDroite[k], a.logYDroite),
                                  12));
            droite -= (int)std::ceil(largeurDroite + (a.etiquetteYDroite.empty() ? 0 : 26.0));
        }
        if (droite <= gauche + 10) return;
    }

    // En perspective, l'espace a son propre dessin (Espace.cpp) ; la vue de
    // dessus est le tracé plan.
    const std::vector<double>& palette = paletteEnVigueur(figure, a);
    double cmin, cmax;
    limitesCouleur(a, cmin, cmax);
    const bool espace = vueEspace(a);
    Echelle ex, ey;
    if (espace) {
        dessinerEspace(figure, a, toile, gauche, droite, haut, bas);
    } else {
        // Les bornes : celles qu'on a fixées, ou celles des données, arrondies
        // aux graduations comme le fait MATLAB.
        double xmin, xmax, ymin, ymax;
        limitesAxe(a, xmin, xmax, ymin, ymax);
        // Un axe logarithmique ne porte ni le zéro ni les négatifs : faute de
        // valeur positive, il redevient linéaire.
        bool logX = a.logX, logY = a.logY;
        if (logX && !(xmin > 0 && xmax > xmin) && !bornesLog(xmin, xmax)) logX = false;
        if (logY && !(ymin > 0 && ymax > ymin) && !bornesLog(ymin, ymax)) {
            logY = false;
            ymin = 0;
            ymax = 1;
        }
        appliquerProportions(a, gauche, droite, haut, bas, xmin, xmax, ymin, ymax);

        // Un axe inversé n'échange pas ses bornes mais les pixels où elles
        // tombent : tout le reste du tracé suit sans le savoir.
        ex = Echelle{xmin, xmax, (double)(a.xInverse ? droite : gauche),
                     (double)(a.xInverse ? gauche : droite), logX};
        ey = Echelle{ymin, ymax, (double)(a.yInverse ? haut : bas),
                     (double)(a.yInverse ? bas : haut), logY};
        const Echelle eyGauche = ey;
        const Echelle eyDroite{yminDroite, ymaxDroite, (double)(a.yInverse ? haut : bas),
                               (double)(a.yInverse ? bas : haut), a.logYDroite};

        // « axis off » : le cadre, les graduations et leurs nombres
        // disparaissent ; les courbes, elles, restent.
        if (a.axesVisibles) {
            Trait cadre = trait("#222", 1);
            toile.rectangle(gauche, haut, droite - gauche, bas - haut, "white", 1.0, &cadre);
        }

        // Les graduations imposées par « ax.XTick = [...] » l'emportent sur
        // celles qu'on choisirait.
        auto tx = a.axesVisibles ? graduationsEffectives(a, 'x', xmin, xmax, logX)
                                 : std::vector<double>{};
        auto ty = a.axesVisibles ? graduationsEffectives(a, 'y', ymin, ymax, logY)
                                 : std::vector<double>{};
        // Une étiquette inclinée se termine sur sa graduation, comme dans
        // MATLAB : ancrée par sa fin pour un angle positif, par son début pour
        // un angle négatif, et décalée d'une demi-hauteur de texte pour que la
        // ligne passe par la graduation.
        StyleTexte styleGraduationX;
        styleGraduationX.ancre = a.angleTicksX > 0 ? 'r' : a.angleTicksX < 0 ? 'l' : 'c';
        styleGraduationX.angle = a.angleTicksX;
        const double sinX = std::sin(a.angleTicksX * PI / 180);
        const double cosX = std::cos(a.angleTicksX * PI / 180);
        std::size_t rangTick = 0;
        for (double v : tx) {
            double px = ex.versPixel(v);
            if (px < gauche - 1 || px > droite + 1) continue;
            if (a.grille) toile.ligne(px, haut, px, bas, traitGrille());
            toile.ligne(px, bas, px, bas - 4, traitAxe());
            // « xticklabels({'a','b'}) » l'emporte sur les nombres.
            std::vector<Morceau> texte = rangTick < a.etiquettesTicksX.size()
                                             ? morceauxInterpretes(a.etiquettesTicksX[rangTick],
                                                                   interpreteDe(a, "ticks"))
                                             : etiquetteGraduation(v, logX);
            ++rangTick;
            if (a.angleTicksX == 0) toile.texte(px, bas + 16, texte, styleGraduationX);
            else toile.texte(px + 4 * sinX, bas + 8 + 4 * cosX, texte, styleGraduationX);
        }
        StyleTexte styleGraduationY;
        styleGraduationY.ancre = 'r';
        styleGraduationY.angle = a.angleTicksY;
        // Sous « yyaxis », chaque axe des ordonnées prend la couleur de son
        // côté, comme dans MATLAB.
        if (deuxOrdonnees) styleGraduationY.couleur = couleurCote(0);
        const double sinY = std::sin(a.angleTicksY * PI / 180);
        const double cosY = std::cos(a.angleTicksY * PI / 180);
        rangTick = 0;
        for (double v : ty) {
            double py = ey.versPixel(v);
            if (py < haut - 1 || py > bas + 1) continue;
            if (a.grille) toile.ligne(gauche, py, droite, py, traitGrille());
            toile.ligne(gauche, py, gauche + 4, py, traitAxe());
            std::vector<Morceau> texte = rangTick < a.etiquettesTicksY.size()
                                             ? morceauxInterpretes(a.etiquettesTicksY[rangTick],
                                                                   interpreteDe(a, "ticks"))
                                             : etiquetteGraduation(v, logY);
            ++rangTick;
            toile.texte(gauche - 8 + 4 * sinY, py + 4 * cosY, texte, styleGraduationY);
        }
        if (deuxOrdonnees) {
            StyleTexte styleDroite;
            styleDroite.couleur = couleurCote(1);
            Trait traitDroite = trait(couleurCote(1), 1);
            for (std::size_t k = 0; k < tyDroite.size(); ++k) {
                double py = eyDroite.versPixel(tyDroite[k]);
                if (py < haut - 1 || py > bas + 1) continue;
                toile.ligne(droite, py, droite - 4, py, traitDroite);
                toile.texte(droite + 8, py + 4,
                            k < a.etiquettesTicksYDroite.size()
                                ? morceauxInterpretes(a.etiquettesTicksYDroite[k],
                                                      interpreteDe(a, "ticks"))
                                : etiquetteGraduation(tyDroite[k], a.logYDroite),
                            styleDroite);
            }
            if (a.axesVisibles) {
                toile.ligne(gauche, haut, gauche, bas, trait(couleurCote(0), 1));
                toile.ligne(droite, haut, droite, bas, traitDroite);
            }
        }

        toile.decouper(gauche, haut, droite - gauche, bas - haut);
        for (const auto& serie : a.series) {
            // Une série indexée — un niveau de contour, un polygone de couleur
            // numérique — prend sa couleur dans la palette. Elle est courte : on
            // la copie pour lui poser cette couleur, et l'on ne copie pas les
            // autres, qui peuvent porter un million de points.
            Serie copieIndexee;
            const Serie* source = &serie;
            if (serie.couleurIndexee) {
                copieIndexee = serie;
                copieIndexee.couleur = couleurDeSerie(figure, a, serie);
                source = &copieIndexee;
            }
            const Serie& s = *source;
            // Une série de droite se lit sur l'échelle de droite.
            const Echelle& ey = deuxOrdonnees && s.cote == 1 ? eyDroite : eyGauche;
            std::size_t n = std::min(s.x.size(), s.y.size());
            if (s.genre == GenreTrace::Constante) {
                if (s.x.empty()) continue;
                double px = s.axeConstante == 'x' ? ex.versPixel(s.x[0]) : gauche;
                double py = s.axeConstante == 'y' ? ey.versPixel(s.x[0]) : haut;
                Trait t = trait(s.couleur, s.epaisseur, s.style);
                if (s.axeConstante == 'x') toile.ligne(px, haut, px, bas, t);
                else toile.ligne(gauche, py, droite, py, t);
                if (!s.legendeConstante.empty()) {
                    StyleTexte st;
                    st.couleur = s.couleur;
                    st.ancre = s.axeConstante == 'x' ? 'l' : 'r';
                    toile.texte(s.axeConstante == 'x' ? px + 4 : droite - 4,
                                s.axeConstante == 'x' ? haut + 14 : py - 4,
                                morceauxInterpretes(s.legendeConstante, s.interprete), st);
                }
                continue;
            }
            if (s.genre == GenreTrace::Texte) {
                if (s.x.empty() || s.y.empty()) continue;
                StyleTexte st;
                st.taille = s.taillePoliceTexte > 0 ? s.taillePoliceTexte : 11.0;
                st.tailleExplicite = true;
                st.ancre = s.alignement;
                st.couleur = s.couleur;
                toile.texte(ex.versPixel(s.x[0]), ey.versPixel(s.y[0]),
                            morceauxInterpretes(s.legendeConstante, s.interprete), st);
                continue;
            }
            if (s.genre == GenreTrace::Surface) {
                // Une surface vue de dessus : ses mailles, à plat.
                const int m = s.lignesGrille, c = s.colonnesGrille;
                if (m < 2 || c < 2 || n < (std::size_t)m * (std::size_t)c) continue;
                auto valeur = [&](std::size_t k) {
                    return k < s.valeursCouleurPoints.size() ? s.valeursCouleurPoints[k]
                           : k < s.z.size()                  ? s.z[k]
                                                             : 0.0;
                };
                for (int j = 0; j + 1 < c; ++j)
                    for (int i = 0; i + 1 < m; ++i) {
                        std::size_t k00 = (std::size_t)i + (std::size_t)j * (std::size_t)m;
                        std::size_t k10 = k00 + 1, k01 = k00 + (std::size_t)m, k11 = k01 + 1;
                        std::vector<double> px, py;
                        for (std::size_t k : {k00, k10, k11, k01}) {
                            px.push_back(ex.versPixel(s.x[k]));
                            py.push_back(ey.versPixel(s.y[k]));
                        }
                        double v = s.modeFaces == "interp"
                                       ? (valeur(k00) + valeur(k10) + valeur(k11) + valeur(k01)) / 4
                                       : valeur(k00);
                        int r, vert, b;
                        couleurEchelle(palette, v, cmin, cmax, r, vert, b);
                        std::string maille = formater("#%02X%02X%02X", r, vert, b);
                        auto mode = [&](const std::string& m2) {
                            return m2 == "flat" || m2 == "interp" ? maille : m2;
                        };
                        Trait bord = trait(mode(s.modeAretes), s.epaisseur);
                        std::string fond = mode(s.modeFaces);
                        toile.polygone(px, py, fond, s.opacite,
                                       bord.couleur == "none" || s.style == "none" ? nullptr
                                                                                   : &bord);
                    }
                continue;
            }
            if (s.genre == GenreTrace::Polygone &&
                (!s.couleursPoints.empty() || !s.valeursCouleurPoints.empty() ||
                 std::any_of(s.x.begin(), s.x.end(), [](double v) { return std::isnan(v); }))) {
                // Plusieurs faces, séparées par des NaN, une couleur par face.
                std::size_t debut = 0, rang = 0;
                while (debut < n) {
                    std::size_t fin = debut;
                    while (fin < n && std::isfinite(s.x[fin]) && std::isfinite(s.y[fin])) ++fin;
                    if (fin - debut >= 2) {
                        std::vector<double> px, py;
                        for (std::size_t k = debut; k < fin; ++k) {
                            px.push_back(ex.versPixel(s.x[k]));
                            py.push_back(ey.versPixel(s.y[k]));
                        }
                        std::string couleurFace = s.couleur;
                        if (!s.couleursPoints.empty()) {
                            couleurFace =
                                s.couleursPoints[std::min(rang, s.couleursPoints.size() - 1)];
                        } else if (!s.valeursCouleurPoints.empty()) {
                            int r, vert, b;
                            couleurEchelle(palette,
                                           s.valeursCouleurPoints[std::min(
                                               rang, s.valeursCouleurPoints.size() - 1)],
                                           cmin, cmax, r, vert, b);
                            couleurFace = formater("#%02X%02X%02X", r, vert, b);
                        }
                        auto mode = [&](const std::string& m2) {
                            return m2 == "flat" || m2 == "interp" ? couleurFace : m2;
                        };
                        Trait bord = trait(mode(s.modeAretes), s.epaisseur == 1.5 ? 0.5
                                                                                   : s.epaisseur);
                        toile.polygone(px, py, mode(s.modeFaces), s.opacite, &bord);
                    }
                    ++rang;
                    debut = fin + 1;
                }
                continue;
            }
            if (s.genre == GenreTrace::Aire || s.genre == GenreTrace::Polygone) {
                if (n < 2) continue;
                std::vector<double> px, py;
                for (std::size_t k = 0; k < n; ++k) {
                    px.push_back(ex.versPixel(s.x[k]));
                    py.push_back(ey.versPixel(s.y[k]));
                }
                if (s.genre == GenreTrace::Aire) {
                    // On referme sur la ligne des zéros : c'est la surface sous
                    // la courbe.
                    double zero = ey.versPixel(std::max(ymin, std::min(ymax, 0.0)));
                    px.push_back(ex.versPixel(s.x[n - 1]));
                    py.push_back(zero);
                    px.push_back(ex.versPixel(s.x[0]));
                    py.push_back(zero);
                }
                // Comme dans MATLAB, le bord d'un « fill » ou d'une « area » est
                // noir tant qu'EdgeColor ne dit pas autre chose.
                Trait bord = trait(s.couleurBord.empty() ? std::string("#000000") : s.couleurBord,
                                   s.epaisseur == 1.5 ? 0.5 : s.epaisseur);
                toile.polygone(px, py, s.couleur, s.opacite, &bord);
                continue;
            }
            if (s.genre == GenreTrace::Image) {
                int lImage = s.hauteurImage, cImage = s.largeurImage;
                if (lImage <= 0 || cImage <= 0) continue;
                // L'image occupe l'étendue que la série déclare, et non toute la
                // boîte : « imagesc(x,y,Z) » se pose au bon endroit, et un axe
                // inversé la retourne comme le reste.
                double x0 = s.x.size() > 1 ? s.x[0] : 0.5;
                double x1 = s.x.size() > 1 ? s.x[1] : cImage + 0.5;
                double y0 = s.y.size() > 1 ? s.y[0] : 0.5;
                double y1 = s.y.size() > 1 ? s.y[1] : lImage + 0.5;
                // Les pixels voisins d'une même couleur, sur une ligne, ne font
                // qu'un rectangle : le fichier reste léger.
                for (int i = 0; i < lImage; ++i) {
                    int j = 0;
                    while (j < cImage) {
                        int r, vert, b;
                        couleurPixelImage(palette, s,
                                          (std::size_t)i + (std::size_t)j * (std::size_t)lImage,
                                          cmin, cmax, r, vert, b);
                        int jFin = j + 1;
                        while (jFin < cImage) {
                            int r2, v2, b2;
                            std::size_t suivant =
                                (std::size_t)i + (std::size_t)jFin * (std::size_t)lImage;
                            couleurPixelImage(palette, s, suivant, cmin, cmax, r2, v2, b2);
                            if (r2 != r || v2 != vert || b2 != b) break;
                            ++jFin;
                        }
                        double gx0 = ex.versPixel(x0 + (x1 - x0) * j / cImage);
                        double gx1 = ex.versPixel(x0 + (x1 - x0) * jFin / cImage);
                        double gy0 = ey.versPixel(y0 + (y1 - y0) * i / lImage);
                        double gy1 = ey.versPixel(y0 + (y1 - y0) * (i + 1) / lImage);
                        toile.rectangle(std::min(gx0, gx1), std::min(gy0, gy1),
                                        std::fabs(gx1 - gx0) + 0.5, std::fabs(gy1 - gy0) + 0.5,
                                        rvb(r, vert, b), 1.0, nullptr);
                        j = jFin;
                    }
                }
                continue;
            }
            if (s.genre == GenreTrace::Barres) {
                // La largeur : BarWidth fois le plus petit écart entre deux
                // abscisses, en unités de données ; le pied : la base de la barre
                // empilée, sinon zéro, ramené dans le cadre.
                double demi = s.largeurBarre / 2 * ecartBarres(s.x);
                Trait bord = trait(s.couleurBord.empty() ? std::string("#000000") : s.couleurBord,
                                   s.epaisseur);
                for (std::size_t k = 0; k < n; ++k) {
                    double pied = k < s.basesBarres.size() ? s.basesBarres[k] : 0.0;
                    pied = std::min(std::max(pied, ymin), ymax);
                    double g = ex.versPixel(s.x[k] - demi);
                    double d = ex.versPixel(s.x[k] + demi);
                    double py = ey.versPixel(std::min(std::max(s.y[k], ymin), ymax));
                    double base = ey.versPixel(pied);
                    toile.rectangle(std::min(g, d), std::min(py, base), std::fabs(d - g),
                                    std::fabs(base - py), s.couleur, s.opacite, &bord);
                }
                continue;
            }
            if (s.genre == GenreTrace::Points) {
                // Un nuage : chaque point a son aire et sa couleur, creux par
                // défaut comme dans MATLAB, plein sous « 'filled' ».
                const std::string marqueur = s.marqueur.empty() ? "o" : s.marqueur;
                FormeMarqueur commune = formeMarqueur(marqueur, s.tailleMarqueur);
                if (s.airesPoints.size() == 1)
                    commune = formeMarqueur(marqueur, std::sqrt(std::max(s.airesPoints[0], 0.0)));
                for (std::size_t k = 0; k < n; ++k) {
                    if (!std::isfinite(s.x[k]) || !std::isfinite(s.y[k])) continue;
                    std::string couleur = couleurPoint(palette, cmin, cmax, s, k);
                    std::string bord, face;
                    couleursPoint(s, couleur, bord, face);
                    // Un « + » ou un « x » n'a que son trait : il le garde.
                    if (bord == "none" && commune.genre == FormeMarqueur::Traits) bord = couleur;
                    if (s.airesPoints.size() > 1)
                        dessinerMarqueur(toile,
                                         formeMarqueur(marqueur, std::sqrt(std::max(
                                                                     k < s.airesPoints.size()
                                                                         ? s.airesPoints[k]
                                                                         : 0.0,
                                                                     0.0))),
                                         ex.versPixel(s.x[k]), ey.versPixel(s.y[k]), bord, face);
                    else
                        dessinerMarqueur(toile, commune, ex.versPixel(s.x[k]), ey.versPixel(s.y[k]),
                                         bord, face);
                }
                continue;
            }
            if (s.genre == GenreTrace::Tige) {
                double base = ey.versPixel(0);
                Trait t = trait(s.couleur, 1);
                for (std::size_t k = 0; k < n; ++k) {
                    double px = ex.versPixel(s.x[k]), py = ey.versPixel(s.y[k]);
                    toile.ligne(px, base, px, py, t);
                    toile.cercle(px, py, 3, "none", &t);
                }
                continue;
            }
            // Les points qu'aucun pixel ne distingue sont retirés : le dessin est
            // le même, le fichier tient.
            std::vector<std::size_t> visibles =
                indicesVisibles(s.x, s.y, ex.min, ex.max, (int)(ex.pixelsMax - ex.pixelsMin),
                                ex.log);
            std::vector<double> px, py;
            std::size_t precedent = 0;
            bool premier = true;
            for (std::size_t k : visibles) {
                if (k >= n) continue;
                if (!std::isfinite(s.x[k]) || !std::isfinite(s.y[k])) {
                    if (!premier) {
                        px.push_back(NAN);
                        py.push_back(NAN);
                    }
                    premier = true;
                    continue;
                }
                double x = ex.versPixel(s.x[k]), y = ey.versPixel(s.y[k]);
                if (s.genre == GenreTrace::Escalier && !premier) {
                    px.push_back(x);
                    py.push_back(ey.versPixel(s.y[precedent]));
                }
                px.push_back(x);
                py.push_back(y);
                premier = false;
                precedent = k;
            }
            if (s.style != "none" && !px.empty())
                toile.polyligne(px, py, trait(s.couleur, s.epaisseur, s.style));
            if (!s.marqueur.empty() && s.marqueur != "none") {
                FormeMarqueur forme = formeMarqueur(s.marqueur, s.tailleMarqueur);
                std::string bord, face;
                couleursMarqueur(s, s.couleur, bord, face);
                for (std::size_t k = 0; k < n; ++k) {
                    if (!std::isfinite(s.x[k]) || !std::isfinite(s.y[k])) continue;
                    dessinerMarqueur(toile, forme, ex.versPixel(s.x[k]), ey.versPixel(s.y[k]), bord,
                                     face);
                }
            }
        }
        toile.finDecoupe();
    }

    if (a.barreCouleurs)
        dessinerBarre(toile, a, barre, gauche, droite, haut, bas, fx * L, descenteX,
                      largeurTextesBarre);

    if (!a.titre.empty()) {
        StyleTexte st;
        st.classe = "titre";
        st.ancre = 'c';
        // Gras, comme les titres de MATLAB.
        st.gras = true;
        st.taille = a.taillePoliceTitre > 0 ? a.taillePoliceTitre : 15;
        st.tailleExplicite = a.taillePoliceTitre > 0;
        toile.texte((gauche + droite) / 2, hautTitre - 14,
                    morceauxInterpretes(a.titre, interpreteDe(a, "title")), st);
    }
    // MATLAB garde le titre sous « axis off », mais pas les étiquettes des
    // axes : elles nomment ce qui n'est plus dessiné.
    if (!a.etiquetteX.empty() && a.axesVisibles && !espace) {
        StyleTexte st;
        st.ancre = 'c';
        toile.texte((gauche + droite) / 2, bas + 36 + descenteX,
                    morceauxInterpretes(a.etiquetteX, interpreteDe(a, "xlabel")), st);
    }
    if (deuxOrdonnees && !a.etiquetteYDroite.empty() && a.axesVisibles) {
        StyleTexte st;
        st.ancre = 'c';
        st.angle = 90;
        st.couleur = couleurCote(1);
        toile.texte(droite + 8 + largeurDroite + 20, (haut + bas) / 2,
                    morceauxInterpretes(a.etiquetteYDroite, interpreteDe(a, "ylabeldroite")), st);
    }
    if (!a.etiquetteY.empty() && a.axesVisibles && !espace) {
        StyleTexte st;
        st.ancre = 'c';
        st.angle = 90;
        // À côté de la boîte telle qu'elle est finalement placée : une
        // légende ou une barre de couleurs à l'ouest l'ont décalée.
        const double xEtiquetteY = std::min(gauche - 46.0, gauche - largeurEtiquettesY - 20);
        if (deuxOrdonnees) st.couleur = couleurCote(0);
        toile.texte(xEtiquetteY, (haut + bas) / 2,
                    morceauxInterpretes(a.etiquetteY, interpreteDe(a, "ylabel")), st);
    }

    if (entrees.empty()) return;
    // Les positions intérieures, à huit pixels du cadre ; « best » prend
    // celle qui couvre le moins de points.
    auto placer = [&](const std::string& p, double& x, double& y) {
        bool est = p.find("east") != std::string::npos;
        bool ouest = p.find("west") != std::string::npos;
        bool nord = p.find("north") != std::string::npos;
        bool sud = p.find("south") != std::string::npos;
        x = est ? droite - largeurLegende - 8
                : ouest ? gauche + 8 : (gauche + droite) / 2.0 - largeurLegende / 2;
        y = nord  ? haut + 8
            : sud ? bas - hauteurLegende - 8
                  : (haut + bas) / 2.0 - hauteurLegende / 2;
    };
    if (!dehors) {
        if (ou == "best" && !espace) {
            const char* choix[] = {"northeast", "northwest", "southeast", "southwest",
                                   "north",     "south",     "east",      "west"};
            std::size_t meilleur = (std::size_t)-1;
            for (const char* c : choix) {
                double x, y;
                placer(c, x, y);
                std::size_t dedans = 0;
                for (const auto& serie : a.series) {
                    if (serie.genre == GenreTrace::Texte || serie.genre == GenreTrace::Image)
                        continue;
                    std::size_t m = std::min(serie.x.size(), serie.y.size());
                    std::size_t pas = std::max<std::size_t>(1, m / 400);
                    for (std::size_t k = 0; k < m; k += pas) {
                        double px = ex.versPixel(serie.x[k]), py = ey.versPixel(serie.y[k]);
                        if (px >= x && px <= x + largeurLegende && py >= y &&
                            py <= y + hauteurLegende)
                            ++dedans;
                    }
                }
                if (dedans < meilleur) {
                    meilleur = dedans;
                    xLegende = x;
                    yLegende = y;
                }
            }
        } else {
            placer(ou == "best" ? std::string("northeast") : ou, xLegende, yLegende);
        }
    }
    if (a.boiteLegende) {
        Trait cadre = trait("#999", 1);
        toile.rectangle(xLegende, yLegende, largeurLegende, hauteurLegende, "white", 1.0, &cadre);
    }
    double xe = xLegende, ye = yLegende + 4;
    for (std::size_t k = 0; k < entrees.size(); ++k) {
        const Serie& s = a.series[entrees[k].serie];
        std::string couleur = couleurDeSerie(figure, a, s);
        double milieu = ye + ligneLegende / 2;
        if (s.genre == GenreTrace::Barres || s.genre == GenreTrace::Aire ||
            s.genre == GenreTrace::Polygone) {
            Trait bord = trait(s.couleurBord.empty() ? couleur : s.couleurBord, 1);
            toile.rectangle(xe + 8, milieu - 5, 20, 10, couleur, s.opacite, &bord);
        } else if (s.genre == GenreTrace::Points) {
            std::string bord, face;
            couleursPoint(s, couleurPoint(palette, cmin, cmax, s, 0), bord, face);
            double aire = s.airesPoints.empty() ? s.tailleMarqueur * s.tailleMarqueur
                                                : std::min(s.airesPoints[0], 144.0);
            dessinerMarqueur(toile, formeMarqueur(s.marqueur.empty() ? "o" : s.marqueur,
                                                  std::sqrt(std::max(aire, 1.0))),
                             xe + 18, milieu, bord, face);
        } else {
            if (s.style != "none")
                toile.ligne(xe + 6, milieu, xe + 30, milieu,
                            trait(couleur, std::min(s.epaisseur, 3.0), s.style));
            std::string marqueur = s.genre == GenreTrace::Tige ? "o" : s.marqueur;
            if (!marqueur.empty() && marqueur != "none") {
                std::string bord, face;
                couleursMarqueur(s, couleur, bord, face);
                dessinerMarqueur(toile, formeMarqueur(marqueur, s.tailleMarqueur), xe + 18, milieu,
                                 bord, face);
            }
        }
        toile.texte(xe + 36, milieu + 4,
                    morceauxInterpretes(entrees[k].texte, interpreteDe(a, "legend")),
                    StyleTexte());
        if (a.legendeHorizontale) xe += largeursEntrees[k];
        else ye += ligneLegende;
    }
}

}  // namespace

void dessinerFigure(const Figure& figure, Toile& toile, int largeur, int hauteur) {
    int indiceAxe = 0;
    for (const auto& axesPtr : figure.axes) {
        if (!axesPtr) continue;
        dessinerAxe(figure, *axesPtr, toile, largeur, hauteur, ++indiceAxe);
    }
}

}  // namespace matlibre
