// VueFigure.cpp — la figure peinte dans la fenêtre.
//
// Le dessin est celui du SVG (dessinerFigure, voir Toile.h) : ici, une
// toile qui peint avec QPainter. La fenêtre montre ainsi exactement ce que
// « print » écrirait — mêmes marges, même légende, même barre de couleurs.
#include "VueFigure.h"

#include <QFontMetricsF>
#include <QPainter>
#include <QPainterPath>
#include <QRegularExpression>
#include <algorithm>
#include <cmath>

#include "matlibre/Toile.h"

using namespace matlibre;

namespace {

// Une couleur de la toile : « #RRGGBB », « #RGB », un nom (« white »),
// « rgb(r,g,b) » ou « none ».
QColor couleurQt(const std::string& texte) {
    if (texte.empty() || texte == "none") return QColor(Qt::transparent);
    if (texte.compare(0, 4, "rgb(") == 0) {
        int r = 0, v = 0, b = 0;
        if (std::sscanf(texte.c_str(), "rgb(%d,%d,%d)", &r, &v, &b) == 3) return QColor(r, v, b);
    }
    QColor c(QString::fromStdString(texte));
    return c.isValid() ? c : QColor(Qt::black);
}

QFont police(double taille, bool gras, bool italique) {
    QFont f;
    // Les métriques d'Helvetica sont celles que le SVG suppose : Arial et
    // Liberation Sans les reprennent.
    f.setFamilies({QStringLiteral("Helvetica"), QStringLiteral("Arial"),
                   QStringLiteral("Liberation Sans"), QStringLiteral("DejaVu Sans")});
    f.setPixelSize(std::max(1, (int)std::lround(taille)));
    f.setBold(gras);
    f.setItalic(italique);
    return f;
}

class ToileQt : public Toile {
public:
    explicit ToileQt(QPainter& peintre) : p_(peintre) {}

    double largeur(const std::vector<Morceau>& texte, double taille, bool gras) const override {
        double l = 0;
        for (const auto& m : texte) {
            QFontMetricsF metrique(police(taille * m.echelle, gras || m.gras, m.italique));
            l += metrique.horizontalAdvance(QString::fromStdString(m.texte));
        }
        return l;
    }

    void ligne(double x1, double y1, double x2, double y2, const Trait& t) override {
        p_.setPen(crayon(t));
        p_.drawLine(QPointF(x1, y1), QPointF(x2, y2));
    }

    void polyligne(const std::vector<double>& x, const std::vector<double>& y,
                   const Trait& t) override {
        QPainterPath chemin;
        bool coupe = true;
        for (std::size_t k = 0; k < x.size() && k < y.size(); ++k) {
            if (!std::isfinite(x[k]) || !std::isfinite(y[k])) {
                coupe = true;
                continue;
            }
            if (coupe) chemin.moveTo(x[k], y[k]);
            else chemin.lineTo(x[k], y[k]);
            coupe = false;
        }
        p_.setPen(crayon(t));
        p_.setBrush(Qt::NoBrush);
        p_.drawPath(chemin);
    }

    void polygone(const std::vector<double>& x, const std::vector<double>& y,
                  const std::string& fond, double opacite, const Trait* bord) override {
        QPolygonF polygone;
        for (std::size_t k = 0; k < x.size() && k < y.size(); ++k) polygone << QPointF(x[k], y[k]);
        p_.setPen(bord ? crayon(*bord) : QPen(Qt::NoPen));
        p_.setBrush(remplissage(fond, opacite));
        p_.drawPolygon(polygone);
        p_.setBrush(Qt::NoBrush);
    }

    void rectangle(double x, double y, double l, double h, const std::string& fond,
                   double opacite, const Trait* bord) override {
        if (!bord) {
            // Sans lissage : les cases voisines d'une image se touchent,
            // et le lissage de leurs bords fractionnaires laissait des
            // coutures claires.
            bool lisse = p_.testRenderHint(QPainter::Antialiasing);
            p_.setRenderHint(QPainter::Antialiasing, false);
            p_.fillRect(QRectF(x, y, l, h), remplissage(fond, opacite));
            p_.setRenderHint(QPainter::Antialiasing, lisse);
            return;
        }
        p_.setPen(crayon(*bord));
        p_.setBrush(remplissage(fond, opacite));
        p_.drawRect(QRectF(x, y, l, h));
        p_.setBrush(Qt::NoBrush);
    }

    void cercle(double cx, double cy, double r, const std::string& fond,
                const Trait* bord) override {
        p_.setPen(bord ? crayon(*bord) : QPen(Qt::NoPen));
        p_.setBrush(remplissage(fond, 1.0));
        p_.drawEllipse(QPointF(cx, cy), r, r);
        p_.setBrush(Qt::NoBrush);
    }

    void texte(double x, double y, const std::vector<Morceau>& morceaux,
               const StyleTexte& s) override {
        double total = largeur(morceaux, s.taille, s.gras);
        double depart = s.ancre == 'c' ? -total / 2 : s.ancre == 'r' ? -total : 0.0;
        p_.save();
        p_.translate(x, y);
        if (s.angle != 0) p_.rotate(-s.angle);
        const QColor couleurTexte =
            s.couleur.empty() ? QColor(0x22, 0x22, 0x22) : couleurQt(s.couleur);
        double curseur = depart;
        for (const auto& m : morceaux) {
            QFont f = police(s.taille * m.echelle, s.gras || m.gras, m.italique);
            p_.setFont(f);
            p_.setPen(m.couleur.empty() ? couleurTexte : couleurQt(m.couleur));
            // Un exposant monte d'un tiers de la taille, un indice descend
            // d'un cinquième : ce que fait « baseline-shift » en SVG.
            double decalage = m.niveau > 0 ? -0.33 * s.taille * m.niveau
                              : m.niveau < 0 ? 0.2 * s.taille * -m.niveau : 0.0;
            QString texte = QString::fromStdString(m.texte);
            p_.drawText(QPointF(curseur, decalage), texte);
            curseur += QFontMetricsF(f).horizontalAdvance(texte);
        }
        p_.restore();
    }

    void decouper(double x, double y, double l, double h) override {
        p_.save();
        p_.setClipRect(QRectF(x, y, l, h), Qt::IntersectClip);
    }
    void finDecoupe() override { p_.restore(); }

private:
    QPen crayon(const Trait& t) const {
        if (t.couleur == "none" || t.motif == "none") return QPen(Qt::NoPen);
        // Un trait plus fin qu'un pixel en prend un à l'écran, comme dans
        // MATLAB : un bord de 0,5 peint en demi-teinte devenait gris pâle.
        double l = std::max(t.epaisseur, 1.0);
        QPen crayon(couleurQt(t.couleur), l);
        // Les motifs du SVG, en largeurs de trait comme Qt les compte.
        if (t.motif == "--") crayon.setDashPattern({8 / l, 4 / l});
        else if (t.motif == ":") crayon.setDashPattern({2 / l, 3 / l});
        else if (t.motif == "-.") crayon.setDashPattern({8 / l, 3 / l, 2 / l, 3 / l});
        return crayon;
    }
    static QBrush remplissage(const std::string& fond, double opacite) {
        if (fond == "none" || fond.empty()) return QBrush(Qt::NoBrush);
        QColor c = couleurQt(fond);
        c.setAlphaF(std::min(std::max(opacite, 0.0), 1.0));
        return QBrush(c);
    }

    QPainter& p_;
};

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
    // La figure se dessine à la taille de la fenêtre : elle suit quand on
    // la redimensionne.
    ToileQt toile(peintre);
    dessinerFigure(figure_.figure, toile, width(), height());
}
