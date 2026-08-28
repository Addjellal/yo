// Icone.cpp — le dessin de l'icône.
#include "Icone.h"

#include <QLinearGradient>
#include <QPainter>
#include <QPainterPath>
#include <QPixmap>
#include <cmath>

void peindreIcone(QPainter& p, double t) {
    p.setRenderHint(QPainter::Antialiasing, true);
    QRectF cadre(t * 0.04, t * 0.04, t * 0.92, t * 0.92);

    QLinearGradient fond(cadre.topLeft(), cadre.bottomRight());
    fond.setColorAt(0.0, QColor("#0b62a8"));
    fond.setColorAt(1.0, QColor("#0a3f6e"));
    QPainterPath carre;
    carre.addRoundedRect(cadre, t * 0.18, t * 0.18);
    p.fillPath(carre, fond);

    // La grille, discrète, comme le fond d'un tracé.
    p.save();
    p.setClipPath(carre);
    p.setPen(QPen(QColor(255, 255, 255, 46), std::max(1.0, t * 0.012)));
    for (int k = 1; k <= 4; ++k) {
        double x = cadre.left() + cadre.width() * k / 5.0;
        double y = cadre.top() + cadre.height() * k / 5.0;
        p.drawLine(QPointF(x, cadre.top()), QPointF(x, cadre.bottom()));
        p.drawLine(QPointF(cadre.left(), y), QPointF(cadre.right(), y));
    }

    // La sinusoïde : le trait qui dit « calcul et tracé ».
    QPainterPath courbe;
    double x0 = cadre.left() + cadre.width() * 0.12;
    double x1 = cadre.right() - cadre.width() * 0.12;
    for (int k = 0; k <= 96; ++k) {
        double u = k / 96.0;
        double x = x0 + (x1 - x0) * u;
        double y = cadre.center().y() - std::sin(u * 6.2831853 * 1.25) * cadre.height() * 0.26;
        if (k == 0) courbe.moveTo(x, y);
        else courbe.lineTo(x, y);
    }
    p.setPen(QPen(QColor("#ffd24a"), t * 0.075, Qt::SolidLine, Qt::RoundCap,
                  Qt::RoundJoin));
    p.drawPath(courbe);

    // Les crochets de MATLAB — ceux du langage, pas ceux d'une marque.
    p.setPen(QPen(Qt::white, t * 0.062, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
    double h = cadre.height() * 0.30, my = cadre.center().y();
    double gx = cadre.left() + cadre.width() * 0.13;
    double dx = cadre.right() - cadre.width() * 0.13;
    double b = cadre.width() * 0.07;
    p.drawPolyline(QPolygonF({QPointF(gx + b, my - h), QPointF(gx, my - h),
                              QPointF(gx, my + h), QPointF(gx + b, my + h)}));
    p.drawPolyline(QPolygonF({QPointF(dx - b, my - h), QPointF(dx, my - h),
                              QPointF(dx, my + h), QPointF(dx - b, my + h)}));
    p.restore();
}

QIcon iconeApplication() {
    QIcon icone;
    for (int taille : {16, 24, 32, 48, 64, 128, 256}) {
        QPixmap image(taille, taille);
        image.fill(Qt::transparent);
        QPainter p(&image);
        peindreIcone(p, taille);
        p.end();
        icone.addPixmap(image);
    }
    return icone;
}
