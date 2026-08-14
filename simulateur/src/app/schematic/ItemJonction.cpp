#include "app/schematic/ItemJonction.h"

#include <QPainter>
#include <QPainterPath>

#include "app/schematic/Ancre.h"
#include "app/schematic/ItemComposant.h"

namespace {
// Rayon du disque. Assez gros pour se voir au zoom courant, assez petit pour
// ne pas masquer le fil qu'il relie.
constexpr double kRayon = 4.0;
}  // namespace

ItemJonction::ItemJonction(const QPointF& position) {
    setPos(position);
    setFlag(ItemIsSelectable, true);
    // Au-dessus des fils, sous les composants : on doit pouvoir le viser.
    setZValue(-0.5);
}

QRectF ItemJonction::boundingRect() const {
    // Le cadre doit couvrir le HALO du survol, pas seulement le disque : Qt
    // n'efface que ce qu'on lui déclare, et un halo peint hors cadre reste à
    // l'écran quand le survol passe au nœud voisin.
    constexpr double kDebord = kRayon + 4.0;
    return QRectF(-kDebord, -kDebord, 2 * kDebord, 2 * kDebord);
}

QPainterPath ItemJonction::shape() const {
    QPainterPath chemin;
    // Zone de préhension plus large que le dessin : on vise un point de quatre
    // pixels à la souris, pas au pixel près.
    chemin.addEllipse(QPointF(0, 0), kRayon + 4, kRayon + 4);
    return chemin;
}

void ItemJonction::definir_surbrillance(bool active) {
    if (surbrillance_ == active) return;
    surbrillance_ = active;
    update();
}

void ItemJonction::paint(QPainter* peintre, const QStyleOptionGraphicsItem*,
                         QWidget*) {
    // Le halo se dessine même sur un simple coude : le nœud allumé doit se
    // suivre d'un bout à l'autre, et un trou au milieu d'un fil se lirait
    // comme une coupure — l'inverse de ce qu'on veut montrer.
    if (surbrillance_) {
        peintre->setPen(Qt::NoPen);
        peintre->setBrush(QColor(255, 233, 168));
        peintre->drawEllipse(QPointF(0, 0), kRayon + 3.5, kRayon + 3.5);
    }
    if (!jonction() && !isSelected()) return;   // simple coude : rien à voir
    peintre->setPen(Qt::NoPen);
    peintre->setBrush(isSelected() ? QColor(0, 120, 215) : QColor(20, 90, 40));
    peintre->drawEllipse(QPointF(0, 0), kRayon, kRayon);
}

// L'unique endroit où les deux types concrets d'ancre sont connus.
QPointF Ancre::position() const {
    if (jonction) return jonction->pos();
    if (composant) return composant->position_borne(borne);
    return {};
}
