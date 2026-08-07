#include "app/schematic/ItemFil.h"

#include <QPainter>
#include <QPainterPath>
#include <QPainterPathStroker>
#include <QStyleOptionGraphicsItem>

#include <cmath>

#include "app/schematic/ItemComposant.h"

ItemFil::ItemFil(ItemComposant* depart, int borne_depart,
                 ItemComposant* arrivee, int borne_arrivee)
    : depart_(depart), arrivee_(arrivee), borne_depart_(borne_depart),
      borne_arrivee_(borne_arrivee) {
    setFlag(ItemIsSelectable, true);
    setZValue(-1);   // les fils passent sous les composants
}

QPainterPath ItemFil::trace() const {
    QPainterPath chemin;
    if (!depart_ || !arrivee_) return chemin;
    const QPointF a = depart_->position_borne(borne_depart_);
    const QPointF b = arrivee_->position_borne(borne_arrivee_);
    chemin.moveTo(a);
    // Équerre en trois segments : on part horizontalement, on descend au
    // milieu, on repart horizontalement.
    const double milieu = (a.x() + b.x()) / 2.0;
    chemin.lineTo(milieu, a.y());
    chemin.lineTo(milieu, b.y());
    chemin.lineTo(b);
    return chemin;
}

QRectF ItemFil::boundingRect() const {
    return trace().boundingRect().adjusted(-14, -18, 14, 14);
}

QPainterPath ItemFil::shape() const {
    QPainterPathStroker epaississeur;
    epaississeur.setWidth(8);
    return epaississeur.createStroke(trace());
}

void ItemFil::definir_tension(double volts) {
    if (tension_connue_ && std::fabs(volts - tension_) < 0.01) return;
    tension_ = volts;
    tension_connue_ = true;
    update();
}

void ItemFil::rafraichir() {
    prepareGeometryChange();
    update();
}

void ItemFil::paint(QPainter* peintre, const QStyleOptionGraphicsItem* option,
                    QWidget*) {
    peintre->setRenderHint(QPainter::Antialiasing, true);
    const bool selectionne = option->state & QStyle::State_Selected;

    QColor couleur(20, 90, 40);
    if (tension_connue_) {
        // Code couleur habituel : masse en noir, potentiel élevé en rouge.
        const double fraction = std::max(0.0, std::min(1.0, tension_ / 5.0));
        couleur = QColor(static_cast<int>(30 + 200 * fraction),
                         static_cast<int>(90 - 60 * fraction),
                         static_cast<int>(40 + 20 * (1 - fraction)));
    }
    if (selectionne) couleur = QColor(0, 120, 215);

    peintre->setPen(QPen(couleur, selectionne ? 3.0 : 2.0, Qt::SolidLine,
                         Qt::RoundCap, Qt::RoundJoin));
    peintre->setBrush(Qt::NoBrush);
    peintre->drawPath(trace());

    if (tension_connue_) {
        const QPointF a = depart_->position_borne(borne_depart_);
        const QPointF b = arrivee_->position_borne(borne_arrivee_);
        const QPointF milieu((a.x() + b.x()) / 2.0, (a.y() + b.y()) / 2.0);
        QFont police = peintre->font();
        police.setPointSizeF(8.0);
        peintre->setFont(police);
        peintre->setPen(QPen(couleur.darker(140), 1));
        peintre->drawText(QRectF(milieu.x() - 40, milieu.y() - 18, 80, 14),
                          Qt::AlignCenter,
                          QString("%1 V").arg(tension_, 0, 'f', 2));
    }
}
