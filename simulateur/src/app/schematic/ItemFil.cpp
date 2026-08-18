#include "app/schematic/ItemFil.h"

#include <QPainter>
#include <QPainterPath>
#include <QPainterPathStroker>
#include <QStyleOptionGraphicsItem>

#include <cmath>

#include "app/schematic/ItemComposant.h"
#include "app/schematic/ItemJonction.h"

ItemFil::ItemFil(const Ancre& depart, const Ancre& arrivee)
    : depart_(depart), arrivee_(arrivee) {
    setFlag(ItemIsSelectable, true);
    setZValue(-1);   // les fils passent sous les composants
}

ItemFil::ItemFil(ItemComposant* depart, int borne_depart,
                 ItemComposant* arrivee, int borne_arrivee)
    : ItemFil(Ancre(depart, borne_depart), Ancre(arrivee, borne_arrivee)) {}

QList<QPointF> ItemFil::sommets(const QPointF& a, const QPointF& b) {
    // Deux bornes presque alignées donnent un fil DROIT.
    //
    // Sans cette tolérance, trois pixels d'écart vertical entre une broche et
    // la suivante suffisent à produire une équerre en trois segments : un
    // petit décrochement inutile, au milieu du fil, qui salit le schéma et
    // qu'aucun électronicien ne dessinerait à la main. Simulink fait de même —
    // en deçà d'un seuil, la liaison reste une ligne.
    //
    // Le seuil vaut une demi-maille : à l'intérieur d'un demi-pas de grille,
    // deux points sont « en face », et le léger biais du trait est invisible.
    constexpr double kTolerance = 5.0;
    const double dx = std::fabs(b.x() - a.x());
    const double dy = std::fabs(b.y() - a.y());
    if (dy <= kTolerance || dx <= kTolerance) return {a, b};

    // Équerre en trois segments : on part horizontalement, on descend au
    // milieu, on repart horizontalement.
    const double milieu = (a.x() + b.x()) / 2.0;
    return {a, QPointF(milieu, a.y()), QPointF(milieu, b.y()), b};
}

QPainterPath ItemFil::chemin(const QPointF& a, const QPointF& b) {
    const QList<QPointF> points = sommets(a, b);
    QPainterPath trace;
    trace.moveTo(points.first());
    for (int k = 1; k < points.size(); ++k) trace.lineTo(points[k]);
    return trace;
}

QPainterPath ItemFil::trace() const {
    if (!depart_.valide() || !arrivee_.valide()) return QPainterPath();
    return chemin(depart_.position(), arrivee_.position());
}

QRectF ItemFil::boundingRect() const {
    // La tension s'écrit au milieu du fil, dans une boîte de quatre-vingts
    // pixels : le cadre doit la contenir, sinon elle reste imprimée à l'écran
    // quand le fil bouge.
    return trace().boundingRect().adjusted(-42, -20, 42, 16);
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

void ItemFil::definir_surbrillance(bool active) {
    if (surbrillance_ == active) return;
    surbrillance_ = active;
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

    // Le halo du nœud survolé, tracé AVANT le fil pour passer dessous. C'est
    // la même teinte que la surbrillance des pastilles du circuit imprimé :
    // deux pages, un seul signe pour « ceci appartient au même nœud ».
    if (surbrillance_) {
        peintre->setPen(QPen(QColor(255, 233, 168), 9.0, Qt::SolidLine,
                             Qt::RoundCap, Qt::RoundJoin));
        peintre->setBrush(Qt::NoBrush);
        peintre->drawPath(trace());
    }

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
        const QPointF a = depart_.position();
        const QPointF b = arrivee_.position();
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
