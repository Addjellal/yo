// VueFigure.cpp — le rendu des tracés.
#include "VueFigure.h"

#include <QFontMetricsF>
#include <QPainter>
#include <QPainterPath>
#include <algorithm>
#include <cmath>

using namespace matlibre;

namespace {

// Bornes des données d'un axe, ou celles que l'utilisateur a fixées.
// Les bornes d'un axe : la meme fonction que le rendu SVG, pour que la
// fenetre et le fichier montrent le meme cadrage — arrondi aux
// graduations, serre sur une image, borne par ce qu'on a fixe.
void bornes(const Axes& axes, double& xmin, double& xmax, double& ymin, double& ymax) {
    limitesAxe(axes, xmin, xmax, ymin, ymax);
}

// Un marqueur de MATLAB, par la forme que le rendu SVG emploie aussi.
void peindreMarqueur(QPainter& peintre, const FormeMarqueur& f, QPointF centre,
                     const QColor& bord, const QColor& face, bool creux) {
    peintre.setPen(QPen(bord, 1));
    peintre.setBrush(creux && !f.toujoursPlein ? QBrush(Qt::NoBrush)
                                               : QBrush(f.toujoursPlein ? bord : face));
    switch (f.genre) {
        case FormeMarqueur::Rien:
            break;
        case FormeMarqueur::Cercle:
            peintre.drawEllipse(centre, f.rayon, f.rayon);
            break;
        case FormeMarqueur::Polygone: {
            QPolygonF polygone;
            for (const auto& p : f.points) polygone << centre + QPointF(p.first, p.second);
            peintre.drawPolygon(polygone);
            break;
        }
        case FormeMarqueur::Traits:
            for (std::size_t k = 0; k + 1 < f.points.size(); k += 2)
                peintre.drawLine(centre + QPointF(f.points[k].first, f.points[k].second),
                                 centre + QPointF(f.points[k + 1].first, f.points[k + 1].second));
            break;
    }
    peintre.setBrush(Qt::NoBrush);
}

QString etiquetteNombre(double v) {
    if (std::fabs(v) < 1e-12) return QStringLiteral("0");
    QString s = QString::number(v, 'g', 6);
    return s;
}

// L'etiquette d'une graduation. Sur un axe logarithmique, MATLAB porte les
// puissances de dix en exposant : 10 puissance moins cinq, et non 1e-05.
QString etiquetteGraduation(double v, bool log) {
    if (log && v > 0) {
        double e = std::log10(v);
        double arrondi = std::round(e);
        if (std::fabs(e - arrondi) < 1e-9) {
            static const char* chiffres[] = {"\u2070", "\u00b9", "\u00b2", "\u00b3",
                                             "\u2074", "\u2075", "\u2076", "\u2077",
                                             "\u2078", "\u2079"};
            int n = (int)arrondi;
            QString exposant;
            for (QChar c : QString::number(std::abs(n)))
                exposant += QString::fromUtf8(chiffres[c.digitValue()]);
            if (n < 0) exposant.prepend(QString::fromUtf8("\u207b"));
            return QStringLiteral("10") + exposant;
        }
    }
    return etiquetteNombre(v);
}

QColor couleurDe(const std::string& texte, int rang) {
    if (!texte.empty() && texte[0] == '#') {
        QColor c(QString::fromStdString(texte));
        if (c.isValid()) return c;
    }
    // La palette par défaut de MATLAB depuis R2014b.
    static const char* palette[] = {"#0072BD", "#D95319", "#EDB120", "#7E2F8E",
                                    "#77AC30", "#4DBEEE", "#A2142F"};
    return QColor(QLatin1String(palette[rang % 7]));
}

Qt::PenStyle styleDe(const std::string& style) {
    if (style == "--") return Qt::DashLine;
    if (style == ":") return Qt::DotLine;
    if (style == "-.") return Qt::DashDotLine;
    if (style == "none" || style.empty()) return Qt::NoPen;
    return Qt::SolidLine;
}

}  // namespace

VueFigure::VueFigure(QWidget* parent) : QWidget(parent) {
    setAutoFillBackground(true);
    QPalette p = palette();
    p.setColor(QPalette::Window, Qt::white);
    setPalette(p);
    setMinimumSize(240, 180);
}

void VueFigure::definirFigure(const FigureCopiee& figure) {
    figure_ = figure;
    aFigure_ = true;
    update();
}

void VueFigure::paintEvent(QPaintEvent*) {
    QPainter peintre(this);
    peintre.setRenderHint(QPainter::Antialiasing, true);
    peintre.fillRect(rect(), Qt::white);
    if (!aFigure_ || figure_.figure.axes.empty()) {
        peintre.setPen(QColor("#909090"));
        peintre.drawText(rect(), Qt::AlignCenter, QStringLiteral("figure vide"));
        return;
    }
    // Chaque axe porte son propre decoupage : deux « subplot » de grilles
    // differentes coexistent dans la meme figure sans se deplacer.
    for (const auto& axes : figure_.figure.axes) {
        if (!axes) continue;
        double fx, fy, fl, fh;
        cadreAxes(*axes, fx, fy, fl, fh);
        QRectF cadre(fx * width(), fy * height(), fl * width(), fh * height());
        peindreAxes(peintre, *axes, cadre);
    }
}

void VueFigure::peindreAxes(QPainter& peintre, const Axes& axes, const QRectF& cadre) {
    QFontMetricsF metrique(peintre.font());
    double margeGauche = std::min(62.0, 0.22 * cadre.width());
    double margeDroite = std::min(18.0, 0.10 * cadre.width());
    double margeHaut = std::min(30.0, 0.16 * cadre.height());
    double margeBas = std::min(44.0, 0.22 * cadre.height());
    if (axes.titre.empty()) margeHaut = std::min(16.0, margeHaut);
    // La barre de couleurs prend sa place à droite, comme dans le SVG.
    if (axes.barreCouleurs) margeDroite += LARGEUR_BARRE_COULEURS;
    // Des étiquettes de graduation écrites à la main peuvent être longues :
    // la marge s'élargit pour qu'elles tiennent, comme dans le SVG.
    double largeurEtiquettesY = 0;
    for (const auto& e : axes.etiquettesTicksY)
        largeurEtiquettesY =
            std::max(largeurEtiquettesY, metrique.horizontalAdvance(QString::fromStdString(e)));
    if (axes.axesVisibles && largeurEtiquettesY > 0)
        margeGauche = std::max(margeGauche, largeurEtiquettesY + 14 +
                                                (axes.etiquetteY.empty() ? 0.0 : 24.0));
    QRectF trace(cadre.left() + margeGauche, cadre.top() + margeHaut,
                 cadre.width() - margeGauche - margeDroite,
                 cadre.height() - margeHaut - margeBas);
    if (trace.width() < 10 || trace.height() < 10) return;

    double xmin, xmax, ymin, ymax;
    bornes(axes, xmin, xmax, ymin, ymax);
    // « axis equal » et « axis square » passent par la meme fonction que
    // le rendu SVG : les deux images doivent se ressembler.
    if (axes.proportions != Axes::Proportions::Auto) {
        int gauche = (int)std::lround(trace.left()), droite = (int)std::lround(trace.right());
        int haut = (int)std::lround(trace.top()), bas = (int)std::lround(trace.bottom());
        appliquerProportions(axes, gauche, droite, haut, bas, xmin, xmax, ymin, ymax);
        trace = QRectF(gauche, haut, droite - gauche, bas - haut);
        if (trace.width() < 10 || trace.height() < 10) return;
    }
    // « semilogx », « semilogy » et « loglog » : l'echelle est celle du
    // logarithme decimal, et les bornes sont ramenees dans les positifs.
    bool logX = axes.logX, logY = axes.logY;
    if (logX && !bornesLog(xmin, xmax)) logX = false;
    if (logY && !bornesLog(ymin, ymax)) logY = false;
    auto place = [](double v, double bas, double haut, bool log) {
        if (log) {
            v = std::log10(std::max(v, 1e-300));
            bas = std::log10(std::max(bas, 1e-300));
            haut = std::log10(std::max(haut, 1e-300));
        }
        if (!(haut > bas)) return 0.5;
        return (v - bas) / (haut - bas);
    };
    // Un axe inverse retourne la fraction, et rien d'autre : le trace,
    // les graduations et la grille suivent tous versEcran.
    auto versEcranX = [&](double x) {
        double f = place(x, xmin, xmax, logX);
        if (axes.xInverse) f = 1 - f;
        return trace.left() + f * trace.width();
    };
    auto versEcranY = [&](double y) {
        double f = place(y, ymin, ymax, logY);
        if (axes.yInverse) f = 1 - f;
        return trace.bottom() - f * trace.height();
    };

    // Grille et graduations.
    // « ax.XTick = [15 40 60] » l'emporte sur les graduations calculees.
    std::vector<double> gx =
        axes.ticksX.empty() ? graduationsAxe(xmin, xmax, 6, logX) : axes.ticksX;
    std::vector<double> gy =
        axes.ticksY.empty() ? graduationsAxe(ymin, ymax, 6, logY) : axes.ticksY;
    peintre.setPen(QPen(QColor("#d8d8d8"), 1));
    if (axes.grille) {
        for (double v : gx) peintre.drawLine(QPointF(versEcranX(v), trace.top()),
                                             QPointF(versEcranX(v), trace.bottom()));
        for (double v : gy) peintre.drawLine(QPointF(trace.left(), versEcranY(v)),
                                             QPointF(trace.right(), versEcranY(v)));
    }
    peintre.setPen(QPen(QColor("#303030"), 1));
    // « axis off » : ni cadre, ni graduations, ni nombres — les courbes
    // seules, comme sous MATLAB.
    if (!axes.axesVisibles) {
        gx.clear();
        gy.clear();
    } else if (axes.boite) {
        peintre.drawRect(trace);
    } else {
        peintre.drawLine(trace.bottomLeft(), trace.bottomRight());
        peintre.drawLine(trace.bottomLeft(), trace.topLeft());
    }
    for (std::size_t k = 0; k < gx.size(); ++k) {
        double v = gx[k];
        double x = versEcranX(v);
        if (x < trace.left() - 1 || x > trace.right() + 1) continue;
        peintre.drawLine(QPointF(x, trace.bottom()), QPointF(x, trace.bottom() - 5));
        QString texte = k < axes.etiquettesTicksX.size()
                            ? QString::fromStdString(axes.etiquettesTicksX[k])
                            : etiquetteGraduation(v, logX);
        peintre.drawText(QRectF(x - 40, trace.bottom() + 4, 80, metrique.height() + 2),
                         Qt::AlignHCenter | Qt::AlignTop, texte);
    }
    for (std::size_t k = 0; k < gy.size(); ++k) {
        double v = gy[k];
        double y = versEcranY(v);
        if (y < trace.top() - 1 || y > trace.bottom() + 1) continue;
        peintre.drawLine(QPointF(trace.left(), y), QPointF(trace.left() + 5, y));
        peintre.drawText(QRectF(cadre.left() + 4, y - metrique.height() / 2,
                                margeGauche - 12, metrique.height()),
                         Qt::AlignRight | Qt::AlignVCenter,
                         k < axes.etiquettesTicksY.size()
                             ? QString::fromStdString(axes.etiquettesTicksY[k])
                             : etiquetteGraduation(v, logY));
    }

    // Les séries. Le tracé est découpé au cadre : une limite manuelle ne
    // doit pas laisser une courbe déborder sur les étiquettes.
    peintre.save();
    peintre.setClipRect(trace);
    const std::vector<double>& palette = paletteEnVigueur(figure_.figure, axes);
    double cmin, cmax;
    limitesCouleur(axes, cmin, cmax);
    int rang = 0;
    for (const auto& serie : axes.series) {
        QColor couleur = couleurDe(couleurDeSerie(figure_.figure, axes, serie), rang);
        std::size_t n = std::min(serie.x.size(), serie.y.size());
        QPen crayon(couleur, serie.epaisseur);
        crayon.setStyle(styleDe(serie.style));
        switch (serie.genre) {
            case GenreTrace::Constante: {
                if (serie.x.empty()) break;
                peintre.setPen(crayon);
                if (serie.axeConstante == 'x') {
                    double x = versEcranX(serie.x[0]);
                    peintre.drawLine(QPointF(x, trace.top()), QPointF(x, trace.bottom()));
                    if (!serie.legendeConstante.empty())
                        peintre.drawText(QPointF(x + 4, trace.top() + 14),
                                         QString::fromStdString(serie.legendeConstante));
                } else {
                    double y = versEcranY(serie.x[0]);
                    peintre.drawLine(QPointF(trace.left(), y), QPointF(trace.right(), y));
                    if (!serie.legendeConstante.empty())
                        peintre.drawText(QPointF(trace.right() - 60, y - 4),
                                         QString::fromStdString(serie.legendeConstante));
                }
                break;
            }
            case GenreTrace::Texte: {
                if (serie.x.empty() || serie.y.empty()) break;
                peintre.setPen(QPen(couleur));
                QFont police = peintre.font();
                if (serie.taillePoliceTexte > 0)
                    police.setPointSizeF(serie.taillePoliceTexte);
                peintre.setFont(police);
                QString texte = QString::fromStdString(serie.legendeConstante);
                double x = versEcranX(serie.x[0]);
                double y = versEcranY(serie.y[0]);
                if (serie.alignement != 'l') {
                    int largeur = peintre.fontMetrics().horizontalAdvance(texte);
                    x -= serie.alignement == 'c' ? largeur / 2.0 : largeur;
                }
                peintre.drawText(QPointF(x, y), texte);
                break;
            }
            case GenreTrace::Barres: {
                // Comme le rendu SVG : BarWidth fois le plus petit écart des
                // abscisses, le pied d'une barre empilée, un bord noir.
                double demi = serie.largeurBarre / 2 * ecartBarres(serie.x);
                QColor bord(QString::fromStdString(serie.couleurBord.empty()
                                                       ? std::string("#000000")
                                                       : serie.couleurBord));
                if (serie.couleurBord == "none") peintre.setPen(Qt::NoPen);
                else peintre.setPen(QPen(bord, std::max(serie.epaisseur, 0.5)));
                QColor remplissage = couleur;
                remplissage.setAlphaF(std::min(std::max(serie.opacite, 0.0), 1.0));
                peintre.setBrush(remplissage);
                for (std::size_t k = 0; k < n; ++k) {
                    double pied = k < serie.basesBarres.size() ? serie.basesBarres[k] : 0.0;
                    pied = std::max(ymin, std::min(ymax, pied));
                    double gauche = versEcranX(serie.x[k] - demi);
                    double droite = versEcranX(serie.x[k] + demi);
                    double y = versEcranY(std::max(ymin, std::min(ymax, serie.y[k])));
                    double base = versEcranY(pied);
                    peintre.drawRect(QRectF(std::min(gauche, droite), std::min(y, base),
                                            std::fabs(droite - gauche), std::fabs(base - y)));
                }
                peintre.setBrush(Qt::NoBrush);
                break;
            }
            case GenreTrace::Points: {
                peintre.setPen(QPen(couleur, 1));
                peintre.setBrush(couleur);
                std::vector<std::size_t> visibles =
                    indicesVisibles(serie.x, serie.y, xmin, xmax, (int)trace.width(), logX);
                for (std::size_t indice : visibles) {
                    if (indice >= n) continue;
                    peintre.drawEllipse(
                        QPointF(versEcranX(serie.x[indice]), versEcranY(serie.y[indice])), 3, 3);
                }
                peintre.setBrush(Qt::NoBrush);
                break;
            }
            case GenreTrace::Tige: {
                peintre.setPen(QPen(couleur, serie.epaisseur));
                double zero = versEcranY(std::max(ymin, std::min(ymax, 0.0)));
                if ((double)n > trace.width() * 2) {
                    // Plus de deux tiges par pixel : elles ne se distinguent
                    // plus, on trace l'enveloppe.
                    std::vector<std::size_t> visibles =
                        indicesVisibles(serie.x, serie.y, xmin, xmax, (int)trace.width(), logX);
                    for (std::size_t indice : visibles) {
                        if (indice >= n) continue;
                        double x = versEcranX(serie.x[indice]);
                        peintre.drawLine(QPointF(x, zero),
                                         QPointF(x, versEcranY(serie.y[indice])));
                    }
                    break;
                }
                for (std::size_t k = 0; k < n; ++k) {
                    double x = versEcranX(serie.x[k]);
                    double y = versEcranY(serie.y[k]);
                    peintre.drawLine(QPointF(x, zero), QPointF(x, y));
                    peintre.drawEllipse(QPointF(x, y), 3, 3);
                }
                break;
            }
            case GenreTrace::Escalier: {
                peintre.setPen(crayon);
                QPainterPath chemin;
                for (std::size_t k = 0; k < n; ++k) {
                    double x = versEcranX(serie.x[k]), y = versEcranY(serie.y[k]);
                    if (k == 0) chemin.moveTo(x, y);
                    else { chemin.lineTo(x, chemin.currentPosition().y()); chemin.lineTo(x, y); }
                }
                peintre.drawPath(chemin);
                break;
            }
            case GenreTrace::Polygone: {
                if (n < 2) break;
                QPainterPath chemin;
                chemin.moveTo(versEcranX(serie.x[0]), versEcranY(serie.y[0]));
                for (std::size_t k = 1; k < n; ++k)
                    chemin.lineTo(versEcranX(serie.x[k]), versEcranY(serie.y[k]));
                chemin.closeSubpath();
                // Le remplissage suit « FaceAlpha », et le contour
                // « EdgeColor ». Une opacite figee a 0,4 et un contour pris
                // sur la couleur de fond donnaient, ici, un tout autre
                // dessin que le SVG : un triangle blanc au bord blanc
                // disparaissait, et un fond opaque paraissait delave.
                QColor remplissage = couleur;
                remplissage.setAlphaF(serie.opacite);
                // Bord noir par défaut, comme EdgeColor dans MATLAB.
                QPen contour = crayon;
                contour.setColor(serie.couleurBord.empty() ? QColor(Qt::black)
                                                           : couleurDe(serie.couleurBord, rang));
                peintre.setPen(contour);
                peintre.setBrush(remplissage);
                peintre.drawPath(chemin);
                peintre.setBrush(Qt::NoBrush);
                break;
            }
            case GenreTrace::Image: {
                // Sans ce cas, une image tombait dans le trace par
                // defaut : la fenetre montrait une diagonale la ou le
                // SVG montrait la carte. La couleur de chaque pixel vient
                // de la meme fonction que dans le SVG.
                int lImage = serie.hauteurImage, cImage = serie.largeurImage;
                if (lImage <= 0 || cImage <= 0) break;
                double x0 = serie.x.size() > 1 ? serie.x[0] : 0.5;
                double x1 = serie.x.size() > 1 ? serie.x[1] : cImage + 0.5;
                double y0 = serie.y.size() > 1 ? serie.y[0] : 0.5;
                double y1 = serie.y.size() > 1 ? serie.y[1] : lImage + 0.5;
                for (int i = 0; i < lImage; ++i)
                    for (int j = 0; j < cImage; ++j) {
                        int r, vert, b;
                        couleurPixelImage(palette, serie,
                                          (std::size_t)i + (std::size_t)j * (std::size_t)lImage,
                                          cmin, cmax, r, vert, b);
                        double gx0 = versEcranX(x0 + (x1 - x0) * j / cImage);
                        double gx1 = versEcranX(x0 + (x1 - x0) * (j + 1) / cImage);
                        double gy0 = versEcranY(y0 + (y1 - y0) * i / lImage);
                        double gy1 = versEcranY(y0 + (y1 - y0) * (i + 1) / lImage);
                        QRectF case_(QPointF(std::min(gx0, gx1), std::min(gy0, gy1)),
                                     QSizeF(std::fabs(gx1 - gx0) + 0.5,
                                            std::fabs(gy1 - gy0) + 0.5));
                        peintre.fillRect(case_, QColor(r, vert, b));
                    }
                break;
            }
            case GenreTrace::Aire: {
                QPainterPath chemin;
                double zero = versEcranY(std::max(ymin, std::min(ymax, 0.0)));
                for (std::size_t k = 0; k < n; ++k) {
                    double x = versEcranX(serie.x[k]), y = versEcranY(serie.y[k]);
                    if (k == 0) chemin.moveTo(x, zero);
                    chemin.lineTo(x, y);
                }
                if (n) chemin.lineTo(versEcranX(serie.x[n - 1]), zero);
                chemin.closeSubpath();
                QColor remplissage = couleur;
                remplissage.setAlpha(90);
                peintre.fillPath(chemin, remplissage);
                peintre.setPen(crayon);
                peintre.drawPath(chemin);
                break;
            }
            default: {
                peintre.setPen(crayon);
                QPainterPath chemin;
                bool commence = false;
                // Un million de points sur mille pixels : neuf cent
                // quatre-vingt-dix-neuf sur mille se superposent, et
                // QPainterPath les garde tous. La fenetre gelait. On ne
                // trace que l'enveloppe visible de chaque colonne — le
                // dessin est le meme, le nombre de segments s'effondre.
                std::vector<std::size_t> visibles =
                    indicesVisibles(serie.x, serie.y, xmin, xmax, (int)trace.width(), logX);
                for (std::size_t indice : visibles) {
                    if (indice >= n) continue;
                    double x = versEcranX(serie.x[indice]), y = versEcranY(serie.y[indice]);
                    if (!std::isfinite(x) || !std::isfinite(y)) { commence = false; continue; }
                    if (!commence) { chemin.moveTo(x, y); commence = true; }
                    else chemin.lineTo(x, y);
                }
                peintre.drawPath(chemin);
                // Les marqueurs ne se dessinent que s'ils se distinguent :
                // au-dela d'un point par pixel ils forment un trait plein.
                if (!serie.marqueur.empty() && serie.marqueur != "none" &&
                    (double)n < trace.width()) {
                    FormeMarqueur forme = formeMarqueur(serie.marqueur, serie.tailleMarqueur);
                    QColor bord = serie.couleurBordMarqueur.empty() ||
                                          serie.couleurBordMarqueur == "auto"
                                      ? couleur
                                      : couleurDe(serie.couleurBordMarqueur, rang);
                    bool creux = serie.couleurFaceMarqueur.empty() ||
                                 serie.couleurFaceMarqueur == "none";
                    QColor face = serie.couleurFaceMarqueur == "auto"
                                      ? couleur
                                      : (creux ? couleur
                                               : couleurDe(serie.couleurFaceMarqueur, rang));
                    for (std::size_t k = 0; k < n; ++k)
                        peindreMarqueur(peintre, forme,
                                        QPointF(versEcranX(serie.x[k]), versEcranY(serie.y[k])),
                                        bord, face, creux);
                }
                break;
            }
        }
        ++rang;
    }
    peintre.restore();

    if (axes.barreCouleurs) {
        BarreCouleurs barre = barreCouleurs(figure_.figure, axes);
        const double x0 = trace.right() + 14, largeurBande = 14;
        const std::size_t tranches = barre.tranches.size() / 3;
        const double pas = trace.height() / (double)tranches;
        for (std::size_t k = 0; k < tranches; ++k)
            peintre.fillRect(QRectF(x0, trace.bottom() - (double)(k + 1) * pas, largeurBande,
                                    pas + 0.5),
                             QColor(barre.tranches[3 * k], barre.tranches[3 * k + 1],
                                    barre.tranches[3 * k + 2]));
        peintre.setPen(QColor("#222222"));
        peintre.setBrush(Qt::NoBrush);
        peintre.drawRect(QRectF(x0, trace.top(), largeurBande, trace.height()));
        for (std::size_t k = 0; k < barre.valeurs.size(); ++k) {
            double y = trace.bottom() - barre.fractions[k] * trace.height();
            peintre.drawLine(QPointF(x0 + largeurBande, y), QPointF(x0 + largeurBande + 4, y));
            peintre.drawText(QPointF(x0 + largeurBande + 7, y + 4),
                             etiquetteGraduation(barre.valeurs[k], false));
        }
    }

    // Titres et étiquettes.
    peintre.setPen(QColor("#101010"));
    if (!axes.titre.empty()) {
        QFont gras = peintre.font();
        gras.setBold(true);
        // « set(get(gca,'Title'),'FontSize',16) » : la taille imposée.
        if (axes.taillePoliceTitre > 0) gras.setPointSizeF(axes.taillePoliceTitre);
        peintre.save();
        peintre.setFont(gras);
        peintre.drawText(QRectF(trace.left(), cadre.top() + 4, trace.width(), margeHaut - 6),
                         Qt::AlignCenter, QString::fromStdString(axes.titre));
        peintre.restore();
    }
    if (!axes.etiquetteX.empty() && axes.axesVisibles)
        peintre.drawText(QRectF(trace.left(), cadre.bottom() - 20, trace.width(), 18),
                         Qt::AlignCenter, QString::fromStdString(axes.etiquetteX));
    if (!axes.etiquetteY.empty() && axes.axesVisibles) {
        peintre.save();
        peintre.translate(cadre.left() + 14, trace.center().y());
        peintre.rotate(-90);
        peintre.drawText(QRectF(-trace.height() / 2, -9, trace.height(), 18), Qt::AlignCenter,
                         QString::fromStdString(axes.etiquetteY));
        peintre.restore();
    }

    // Légende : les mêmes entrées que dans le SVG, avec le style et le
    // marqueur de chaque courbe.
    std::vector<EntreeLegende> entrees;
    if (axes.legendeVisible) entrees = entreesLegende(axes);
    if (!entrees.empty()) {
        double hauteurLigne = metrique.height() + 4;
        double largeur = 40;
        for (const auto& e : entrees)
            largeur = std::max(largeur, 46 + metrique.horizontalAdvance(
                                                 QString::fromStdString(e.texte)));
        double hauteur = hauteurLigne * (double)entrees.size() + 8;
        const std::string& ou = axes.positionLegende;
        double x = trace.right() - largeur - 10, y = trace.top() + 10;
        if (ou.find("west") != std::string::npos) x = trace.left() + 10;
        else if (ou == "north" || ou == "south" || ou == "northoutside" || ou == "southoutside")
            x = trace.center().x() - largeur / 2;
        if (ou.find("south") != std::string::npos) y = trace.bottom() - hauteur - 10;
        else if (ou == "east" || ou == "west" || ou == "eastoutside" || ou == "westoutside")
            y = trace.center().y() - hauteur / 2;
        QRectF boite(x, y, largeur, hauteur);
        if (axes.boiteLegende) {
            peintre.setBrush(QColor(255, 255, 255, 235));
            peintre.setPen(QColor("#909090"));
            peintre.drawRect(boite);
            peintre.setBrush(Qt::NoBrush);
        }
        for (std::size_t k = 0; k < entrees.size(); ++k) {
            const Serie& serie = axes.series[entrees[k].serie];
            double yLigne = boite.top() + 4 + hauteurLigne * (double)k + hauteurLigne / 2;
            QColor couleur =
                couleurDe(couleurDeSerie(figure_.figure, axes, serie), (int)entrees[k].serie);
            if (serie.genre == GenreTrace::Barres || serie.genre == GenreTrace::Aire ||
                serie.genre == GenreTrace::Polygone) {
                peintre.fillRect(QRectF(boite.left() + 8, yLigne - 5, 20, 10), couleur);
            } else {
                if (serie.style != "none") {
                    QPen crayon(couleur, std::min(serie.epaisseur, 3.0));
                    crayon.setStyle(styleDe(serie.style));
                    peintre.setPen(crayon);
                    peintre.drawLine(QPointF(boite.left() + 6, yLigne),
                                     QPointF(boite.left() + 30, yLigne));
                }
                std::string marqueur = serie.genre == GenreTrace::Tige ? "o" : serie.marqueur;
                if (serie.genre == GenreTrace::Points) marqueur = ".";
                if (!marqueur.empty() && marqueur != "none")
                    peindreMarqueur(peintre, formeMarqueur(marqueur, serie.tailleMarqueur),
                                    QPointF(boite.left() + 18, yLigne), couleur, couleur,
                                    serie.couleurFaceMarqueur.empty() ||
                                        serie.couleurFaceMarqueur == "none");
            }
            peintre.setPen(QColor("#101010"));
            peintre.drawText(QRectF(boite.left() + 36, yLigne - hauteurLigne / 2,
                                    boite.width() - 40, hauteurLigne),
                             Qt::AlignVCenter | Qt::AlignLeft,
                             QString::fromStdString(entrees[k].texte));
        }
    }
}
