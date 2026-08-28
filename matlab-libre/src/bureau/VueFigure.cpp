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
void bornes(const Axes& axes, double& xmin, double& xmax, double& ymin, double& ymax) {
    xmin = ymin = 1e308;
    xmax = ymax = -1e308;
    bool vu = false;
    for (const auto& s : axes.series) {
        for (double v : s.x) { xmin = std::min(xmin, v); xmax = std::max(xmax, v); vu = true; }
        for (double v : s.y) { ymin = std::min(ymin, v); ymax = std::max(ymax, v); vu = true; }
    }
    if (!vu) { xmin = 0; xmax = 1; ymin = 0; ymax = 1; }
    if (axes.limitesManuellesX) { xmin = axes.xmin; xmax = axes.xmax; }
    if (axes.limitesManuellesY) { ymin = axes.ymin; ymax = axes.ymax; }
    // Un axe plat reste lisible : on lui donne une hauteur.
    if (!(xmax > xmin)) { xmin -= 0.5; xmax += 0.5; }
    if (!(ymax > ymin)) { ymin -= 0.5; ymax += 0.5; }
    if (!axes.limitesManuellesY) {
        double marge = 0.05 * (ymax - ymin);
        ymin -= marge;
        ymax += marge;
    }
}

// Graduations « rondes » : pas de 1, 2 ou 5 fois une puissance de dix,
// comme le fait MATLAB.
std::vector<double> graduations(double bas, double haut, int cible) {
    std::vector<double> valeurs;
    if (!(haut > bas) || cible < 2) return valeurs;
    double brut = (haut - bas) / cible;
    double magnitude = std::pow(10.0, std::floor(std::log10(brut)));
    double norme = brut / magnitude;
    double pas = (norme < 1.5 ? 1 : norme < 3 ? 2 : norme < 7 ? 5 : 10) * magnitude;
    double debut = std::ceil(bas / pas) * pas;
    for (double v = debut; v <= haut + pas * 1e-9; v += pas) valeurs.push_back(v);
    return valeurs;
}

QString etiquetteNombre(double v) {
    if (std::fabs(v) < 1e-12) return QStringLiteral("0");
    QString s = QString::number(v, 'g', 6);
    return s;
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
    int lignes = std::max(1, figure_.figure.lignes);
    int colonnes = std::max(1, figure_.figure.colonnes);
    double largeurCase = width() / (double)colonnes;
    double hauteurCase = height() / (double)lignes;
    for (const auto& axes : figure_.figure.axes) {
        if (!axes) continue;
        int position = std::max(1, axes->position);
        int i = (position - 1) / colonnes;
        int j = (position - 1) % colonnes;
        QRectF cadre(j * largeurCase, i * hauteurCase, largeurCase, hauteurCase);
        peindreAxes(peintre, *axes, cadre);
    }
}

void VueFigure::peindreAxes(QPainter& peintre, const Axes& axes, const QRectF& cadre) {
    QFontMetricsF metrique(peintre.font());
    double margeGauche = 62, margeDroite = 18, margeHaut = 30, margeBas = 44;
    if (axes.titre.empty()) margeHaut = 16;
    QRectF trace(cadre.left() + margeGauche, cadre.top() + margeHaut,
                 cadre.width() - margeGauche - margeDroite,
                 cadre.height() - margeHaut - margeBas);
    if (trace.width() < 10 || trace.height() < 10) return;

    double xmin, xmax, ymin, ymax;
    bornes(axes, xmin, xmax, ymin, ymax);
    auto versEcranX = [&](double x) {
        return trace.left() + (x - xmin) / (xmax - xmin) * trace.width();
    };
    auto versEcranY = [&](double y) {
        return trace.bottom() - (y - ymin) / (ymax - ymin) * trace.height();
    };

    // Grille et graduations.
    // « ax.XTick = [15 40 60] » l'emporte sur les graduations calculees.
    std::vector<double> gx = axes.ticksX.empty() ? graduations(xmin, xmax, 6) : axes.ticksX;
    std::vector<double> gy = axes.ticksY.empty() ? graduations(ymin, ymax, 6) : axes.ticksY;
    peintre.setPen(QPen(QColor("#d8d8d8"), 1));
    if (axes.grille) {
        for (double v : gx) peintre.drawLine(QPointF(versEcranX(v), trace.top()),
                                             QPointF(versEcranX(v), trace.bottom()));
        for (double v : gy) peintre.drawLine(QPointF(trace.left(), versEcranY(v)),
                                             QPointF(trace.right(), versEcranY(v)));
    }
    peintre.setPen(QPen(QColor("#303030"), 1));
    if (axes.boite) peintre.drawRect(trace);
    else {
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
                            : etiquetteNombre(v);
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
                             : etiquetteNombre(v));
    }

    // Les séries. Le tracé est découpé au cadre : une limite manuelle ne
    // doit pas laisser une courbe déborder sur les étiquettes.
    peintre.save();
    peintre.setClipRect(trace);
    int rang = 0;
    for (const auto& serie : axes.series) {
        QColor couleur = couleurDe(serie.couleur, rang);
        std::size_t n = std::min(serie.x.size(), serie.y.size());
        QPen crayon(couleur, serie.epaisseur);
        crayon.setStyle(styleDe(serie.style));
        switch (serie.genre) {
            case GenreTrace::Barres: {
                double largeur = n > 1 ? (versEcranX(serie.x[1]) - versEcranX(serie.x[0])) * 0.7
                                       : trace.width() / 3;
                peintre.setPen(Qt::NoPen);
                peintre.setBrush(couleur);
                for (std::size_t k = 0; k < n; ++k) {
                    double x = versEcranX(serie.x[k]);
                    double y = versEcranY(serie.y[k]);
                    double zero = versEcranY(std::max(ymin, std::min(ymax, 0.0)));
                    peintre.drawRect(QRectF(x - largeur / 2, std::min(y, zero),
                                            std::fabs(largeur), std::fabs(zero - y)));
                }
                peintre.setBrush(Qt::NoBrush);
                break;
            }
            case GenreTrace::Points: {
                peintre.setPen(QPen(couleur, 1));
                peintre.setBrush(couleur);
                std::vector<std::size_t> visibles =
                    indicesVisibles(serie.x, serie.y, xmin, xmax, (int)trace.width());
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
                        indicesVisibles(serie.x, serie.y, xmin, xmax, (int)trace.width());
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
                    indicesVisibles(serie.x, serie.y, xmin, xmax, (int)trace.width());
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
                    peintre.setBrush(couleur);
                    for (std::size_t k = 0; k < n; ++k)
                        peintre.drawEllipse(
                            QPointF(versEcranX(serie.x[k]), versEcranY(serie.y[k])), 2.5, 2.5);
                    peintre.setBrush(Qt::NoBrush);
                }
                break;
            }
        }
        ++rang;
    }
    peintre.restore();

    // Titres et étiquettes.
    peintre.setPen(QColor("#101010"));
    if (!axes.titre.empty()) {
        QFont gras = peintre.font();
        gras.setBold(true);
        peintre.save();
        peintre.setFont(gras);
        peintre.drawText(QRectF(trace.left(), cadre.top() + 4, trace.width(), margeHaut - 6),
                         Qt::AlignCenter, QString::fromStdString(axes.titre));
        peintre.restore();
    }
    if (!axes.etiquetteX.empty())
        peintre.drawText(QRectF(trace.left(), cadre.bottom() - 20, trace.width(), 18),
                         Qt::AlignCenter, QString::fromStdString(axes.etiquetteX));
    if (!axes.etiquetteY.empty()) {
        peintre.save();
        peintre.translate(cadre.left() + 14, trace.center().y());
        peintre.rotate(-90);
        peintre.drawText(QRectF(-trace.height() / 2, -9, trace.height(), 18), Qt::AlignCenter,
                         QString::fromStdString(axes.etiquetteY));
        peintre.restore();
    }

    // Légende.
    if (axes.legendeVisible && !axes.legende.empty()) {
        double hauteurLigne = metrique.height() + 4;
        double largeur = 40;
        // 32 px pour le trait et sa marge, 10 pour la marge de droite : sans
        // cette derniere, la derniere lettre etait rognee.
        for (const auto& e : axes.legende)
            largeur = std::max(largeur, 42 + metrique.horizontalAdvance(
                                                 QString::fromStdString(e)));
        QRectF boite(trace.right() - largeur - 10, trace.top() + 10, largeur,
                     hauteurLigne * (double)axes.legende.size() + 8);
        peintre.setBrush(QColor(255, 255, 255, 225));
        peintre.setPen(QColor("#909090"));
        peintre.drawRect(boite);
        peintre.setBrush(Qt::NoBrush);
        for (std::size_t k = 0; k < axes.legende.size(); ++k) {
            double y = boite.top() + 4 + hauteurLigne * (double)k + hauteurLigne / 2;
            QColor couleur = k < axes.series.size() ? couleurDe(axes.series[k].couleur, (int)k)
                                                    : couleurDe("", (int)k);
            peintre.setPen(QPen(couleur, 2));
            peintre.drawLine(QPointF(boite.left() + 6, y), QPointF(boite.left() + 26, y));
            peintre.setPen(QColor("#101010"));
            peintre.drawText(QRectF(boite.left() + 32, y - hauteurLigne / 2,
                                    boite.width() - 40, hauteurLigne),
                             Qt::AlignVCenter | Qt::AlignLeft,
                             QString::fromStdString(axes.legende[k]));
        }
    }
}
