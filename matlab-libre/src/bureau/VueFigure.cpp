// VueFigure.cpp — le rendu des tracés.
#include "VueFigure.h"

#include <QFontInfo>
#include <QFontMetricsF>
#include <QPainter>
#include <QPainterPath>
#include <QPolygonF>
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
        // Une droite « xline » suit les bornes, elle ne les impose pas ;
        // un texte pose non plus.
        if (s.genre == GenreTrace::Constante || s.genre == GenreTrace::Texte) continue;
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
    // Un axe logarithmique ne porte ni le zero ni les negatifs : ses bornes
    // sont celles des donnees strictement positives, sans la marge de cinq
    // pour cent qui n'a de sens qu'en lineaire.
    if (axes.logY && !axes.limitesManuellesY) {
        double bas = 1e308, haut = -1e308;
        bool vuPositif = false;
        for (const auto& s : axes.series)
            for (double v : s.y)
                if (std::isfinite(v) && v > 0) {
                    bas = std::min(bas, v);
                    haut = std::max(haut, v);
                    vuPositif = true;
                }
        if (vuPositif) { ymin = bas; ymax = haut; }
    }
}

// Les graduations — lineaires ou par decades — viennent de Graphique.h :
// le rendu SVG et la fenetre doivent porter les memes.

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

// La police d'un morceau de texte : celle du texte, a l'echelle du morceau
// — un indice est plus petit —, en gras ou en italique s'il le demande.
QFont policeDe(const QFont& base, const MorceauTexte& morceau) {
    QFont police = base;
    if (morceau.echelle != 1.0) {
        if (base.pointSizeF() > 0)
            police.setPointSizeF(base.pointSizeF() * morceau.echelle);
        else
            police.setPixelSize(
                std::max(1, (int)std::lround(base.pixelSize() * morceau.echelle)));
    }
    if (morceau.gras) police.setBold(true);
    if (morceau.italique) police.setItalic(true);
    return police;
}

double largeurMorceaux(const QFont& base, const std::vector<MorceauTexte>& morceaux) {
    double largeur = 0;
    for (const auto& m : morceaux)
        largeur += QFontMetricsF(policeDe(base, m))
                       .horizontalAdvance(QString::fromStdString(m.texte));
    return largeur;
}

// Peint un texte decoupe depuis « origine », posee sur sa ligne de base :
// les morceaux se suivent, chacun dans sa police et a sa hauteur, comme
// les <tspan> du SVG.
void peindreMorceaux(QPainter& peintre, QPointF origine,
                     const std::vector<MorceauTexte>& morceaux) {
    QFont base = peintre.font();
    double taille = QFontInfo(base).pixelSize();
    double x = origine.x();
    for (const auto& m : morceaux) {
        QFont police = policeDe(base, m);
        QString texte = QString::fromStdString(m.texte);
        peintre.setFont(police);
        peintre.drawText(QPointF(x, origine.y() - m.decalage * taille), texte);
        x += QFontMetricsF(police).horizontalAdvance(texte);
    }
    peintre.setFont(base);
}

// Un texte decoupe, aligne dans un rectangle comme « drawText » l'y aurait
// aligne.
void peindreMorceauxDans(QPainter& peintre, const QRectF& rect, Qt::Alignment alignement,
                         const std::vector<MorceauTexte>& morceaux) {
    QFontMetricsF metrique(peintre.font());
    double largeur = largeurMorceaux(peintre.font(), morceaux);
    double x = rect.left();
    if (alignement & Qt::AlignHCenter) x = rect.center().x() - largeur / 2;
    else if (alignement & Qt::AlignRight) x = rect.right() - largeur;
    double y = rect.center().y() + (metrique.ascent() - metrique.descent()) / 2;
    if (alignement & Qt::AlignTop) y = rect.top() + metrique.ascent();
    else if (alignement & Qt::AlignBottom) y = rect.bottom() - metrique.descent();
    peindreMorceaux(peintre, QPointF(x, y), morceaux);
}

// Un marqueur, tel que la courbe et la legende le peignent : la forme que
// le SVG dessine aussi, d'un trait plein — celui de la courbe peut etre en
// tirets, ou absent pour des marqueurs seuls.
void peindreMarqueur(QPainter& peintre, const std::string& marqueur, QPointF centre,
                     const QColor& couleur) {
    FormeMarqueur forme = formeMarqueur(marqueur);
    if (forme.rayonCercle <= 0 && forme.lignes.empty()) return;
    peintre.save();
    peintre.setPen(QPen(couleur, 1));
    peintre.setBrush(forme.plein ? QBrush(couleur) : QBrush(Qt::NoBrush));
    if (forme.rayonCercle > 0)
        peintre.drawEllipse(centre, forme.rayonCercle, forme.rayonCercle);
    for (const auto& ligne : forme.lignes) {
        QPolygonF points;
        for (const auto& p : ligne) points << centre + QPointF(p.first, p.second);
        if (forme.ferme) peintre.drawPolygon(points);
        else peintre.drawPolyline(points);
    }
    peintre.restore();
}

// L'echantillon d'une entree de legende, de x0 a x1 sur la ligne y : le
// trait avec son style et son epaisseur, le marqueur au milieu ; le
// marqueur seul quand la courbe n'a pas de trait ; un pave plein pour ce
// qui se remplit. Le SVG dessine le meme.
void peindreEchantillon(QPainter& peintre, const Serie& serie, int rang, double x0,
                        double x1, double y) {
    QColor couleur = couleurDe(serie.couleur, rang);
    QPointF milieu((x0 + x1) / 2, y);
    peintre.save();
    switch (serie.genre) {
        case GenreTrace::Barres:
        case GenreTrace::Aire:
        case GenreTrace::Polygone:
        case GenreTrace::Image: {
            QColor remplissage = couleur;
            if (serie.genre == GenreTrace::Aire) remplissage.setAlpha(90);
            if (serie.genre == GenreTrace::Polygone) remplissage.setAlphaF(serie.opacite);
            QColor bord =
                serie.couleurBord.empty() ? couleur : couleurDe(serie.couleurBord, rang);
            peintre.setPen(bord);
            peintre.setBrush(remplissage);
            peintre.drawRect(QRectF(x0, y - 5, x1 - x0, 10));
            break;
        }
        case GenreTrace::Points:
            peintre.setPen(QPen(couleur, 1));
            peintre.setBrush(couleur);
            peintre.drawEllipse(milieu, 3, 3);
            break;
        case GenreTrace::Tige:
            peintre.setPen(QPen(couleur, serie.epaisseur));
            peintre.drawLine(QPointF(x0, y), QPointF(x1, y));
            peintre.drawEllipse(milieu, 3, 3);
            break;
        default: {
            QPen crayon(couleur, serie.epaisseur);
            crayon.setStyle(styleDe(serie.style));
            peintre.setPen(crayon);
            peintre.drawLine(QPointF(x0, y), QPointF(x1, y));
            peindreMarqueur(peintre, serie.marqueur, milieu, couleur);
            break;
        }
    }
    peintre.restore();
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
    QRectF trace(cadre.left() + margeGauche, cadre.top() + margeHaut,
                 cadre.width() - margeGauche - margeDroite,
                 cadre.height() - margeHaut - margeBas);
    if (trace.width() < 10 || trace.height() < 10) return;

    // La legende se mesure avant le trace : logee hors de l'axe, elle lui
    // prend de la place. Sa largeur est celle du plus long libelle.
    std::vector<EntreeLegende> entrees = entreesLegende(axes);
    std::vector<std::vector<MorceauTexte>> libelles;
    std::vector<double> largeursLibelles;
    double hauteurLigne = metrique.height() + 4;
    double largeurLegende = 0, hauteurLegende = 0, xLegende = 0, yLegende = 0;
    bool legendeLogee = false;
    if (!entrees.empty()) {
        double plusLong = 0;
        for (const auto& e : entrees) {
            libelles.push_back(decouperTexte(e.libelle, axes.interpreteLegende));
            largeursLibelles.push_back(largeurMorceaux(peintre.font(), libelles.back()));
            plusLong = std::max(plusLong, largeursLibelles.back());
        }
        // L'echantillon de 6 a 28, le libelle a 34, et 10 de marge a
        // droite : sans elle, la derniere lettre etait rognee.
        largeurLegende = std::ceil(plusLong) + 44;
        hauteurLegende = hauteurLigne * (double)entrees.size() + 8;
        double g = trace.left(), h = trace.top(), d = trace.right(), b = trace.bottom();
        legendeLogee = logerLegendeHorsAxe(axes.emplacementLegende, largeurLegende,
                                           hauteurLegende, cadre.left(), cadre.top(),
                                           cadre.right(), cadre.bottom(), g, h, d, b,
                                           xLegende, yLegende);
        if (legendeLogee) trace = QRectF(QPointF(g, h), QPointF(d, b));
    }
    // Ce que la case laisse aux graduations, au titre et aux etiquettes :
    // toute la case, moins la bande d'une legende logee dehors.
    QRectF bande(trace.left() - margeGauche, trace.top() - margeHaut,
                 trace.width() + margeGauche + margeDroite,
                 trace.height() + margeHaut + margeBas);

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
        peintre.drawText(QRectF(bande.left() + 4, y - metrique.height() / 2,
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
    int rang = 0;
    for (const auto& serie : axes.series) {
        QColor couleur = couleurDe(serie.couleur, rang);
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
                std::vector<MorceauTexte> morceaux =
                    decouperTexte(serie.legendeConstante, serie.interprete);
                double x = versEcranX(serie.x[0]);
                double y = versEcranY(serie.y[0]);
                if (serie.alignement != 'l') {
                    double largeur = largeurMorceaux(police, morceaux);
                    x -= serie.alignement == 'c' ? largeur / 2.0 : largeur;
                }
                peindreMorceaux(peintre, QPointF(x, y), morceaux);
                break;
            }
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
                QPen contour = crayon;
                if (!serie.couleurBord.empty())
                    contour.setColor(couleurDe(serie.couleurBord, rang));
                peintre.setPen(contour);
                peintre.setBrush(remplissage);
                peintre.drawPath(chemin);
                peintre.setBrush(Qt::NoBrush);
                break;
            }
            case GenreTrace::Image: {
                // Sans ce cas, une image tombait dans le trace par
                // defaut : la fenetre montrait une diagonale la ou le
                // SVG montrait la carte.
                int lImage = serie.hauteurImage, cImage = serie.largeurImage;
                if (lImage <= 0 || cImage <= 0) break;
                double mn = 1e308, mx = -1e308;
                for (double v : serie.z) {
                    mn = std::min(mn, v);
                    mx = std::max(mx, v);
                }
                if (!std::isfinite(mn) || mx == mn) { mn = 0; mx = 1; }
                double x0 = serie.x.size() > 1 ? serie.x[0] : 0.5;
                double x1 = serie.x.size() > 1 ? serie.x[1] : cImage + 0.5;
                double y0 = serie.y.size() > 1 ? serie.y[0] : 0.5;
                double y1 = serie.y.size() > 1 ? serie.y[1] : lImage + 0.5;
                for (int i = 0; i < lImage; ++i)
                    for (int j = 0; j < cImage; ++j) {
                        double v = serie.z[(std::size_t)i + (std::size_t)j * lImage];
                        int r, vert, b;
                        couleurCarte((v - mn) / (mx - mn), r, vert, b);
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
                if ((double)n < trace.width())
                    for (std::size_t k = 0; k < n; ++k) {
                        QPointF point(versEcranX(serie.x[k]), versEcranY(serie.y[k]));
                        peindreMarqueur(peintre, serie.marqueur, point, couleur);
                    }
                break;
            }
        }
        ++rang;
    }
    peintre.restore();

    // Titres et étiquettes, lus par leur interprete : « x_1 » met le 1 en
    // indice, comme le SVG.
    peintre.setPen(QColor("#101010"));
    if (!axes.titre.empty()) {
        QFont gras = peintre.font();
        gras.setBold(true);
        // « set(get(gca,'Title'),'FontSize',16) » : la taille imposée.
        if (axes.taillePoliceTitre > 0) gras.setPointSizeF(axes.taillePoliceTitre);
        peintre.save();
        peintre.setFont(gras);
        QRectF place(trace.left(), bande.top() + 4, trace.width(), margeHaut - 6);
        peindreMorceauxDans(peintre, place, Qt::AlignCenter,
                            decouperTexte(axes.titre, axes.interpreteTitre));
        peintre.restore();
    }
    if (!axes.etiquetteX.empty() && axes.axesVisibles) {
        QRectF place(trace.left(), bande.bottom() - 20, trace.width(), 18);
        peindreMorceauxDans(peintre, place, Qt::AlignCenter,
                            decouperTexte(axes.etiquetteX, axes.interpreteX));
    }
    if (!axes.etiquetteY.empty() && axes.axesVisibles) {
        peintre.save();
        peintre.translate(bande.left() + 14, trace.center().y());
        peintre.rotate(-90);
        QRectF place(-trace.height() / 2, -9, trace.height(), 18);
        peindreMorceauxDans(peintre, place, Qt::AlignCenter,
                            decouperTexte(axes.etiquetteY, axes.interpreteY));
        peintre.restore();
    }

    // Légende : les memes entrees que dans le SVG, placees par les memes
    // regles ; seule la mesure des libelles differe, Qt sachant mesurer.
    if (!entrees.empty()) {
        if (!legendeLogee) {
            VersPixels versPixels = [&](double x, double y, double& px, double& py) {
                if (!std::isfinite(x) || !std::isfinite(y)) return false;
                if ((logX && x <= 0) || (logY && y <= 0)) return false;
                px = versEcranX(x);
                py = versEcranY(y);
                return true;
            };
            placerLegendeDansAxe(axes, largeurLegende, hauteurLegende, trace.left(),
                                 trace.top(), trace.right(), trace.bottom(), versPixels,
                                 xLegende, yLegende);
        }
        QRectF boite(xLegende, yLegende, largeurLegende, hauteurLegende);
        // Peinte apres tout le reste, sur un fond opaque : une courbe qui
        // passe dans le coin passe dessous, au lieu de transparaitre.
        peintre.setBrush(Qt::white);
        peintre.setPen(QColor("#909090"));
        peintre.drawRect(boite);
        peintre.setBrush(Qt::NoBrush);
        for (std::size_t k = 0; k < entrees.size(); ++k) {
            double y = boite.top() + 4 + hauteurLigne * (double)k + hauteurLigne / 2;
            const Serie& serie = *entrees[k].serie;
            int rangSerie = (int)(&serie - axes.series.data());
            peindreEchantillon(peintre, serie, rangSerie, boite.left() + 6,
                               boite.left() + 28, y);
            peintre.setPen(QColor("#101010"));
            peindreMorceauxDans(peintre,
                                QRectF(boite.left() + 34, y - hauteurLigne / 2,
                                       largeursLibelles[k] + 1, hauteurLigne),
                                Qt::AlignVCenter | Qt::AlignLeft, libelles[k]);
        }
    }
}
