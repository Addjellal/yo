// Un point de fil : l'ancre qui n'est pas une broche.
//
// Il naît quand un fil en rencontre un autre. La dérivation en T n'est alors
// pas une opération à part — c'est le fil coupé en deux autour d'un point que
// trois fils se partagent. C'est exactement ce que fait LibrePCB, et la raison
// pour laquelle son code ne connaît aucune notion de « jonction » : le T *est*
// trois fils sur une même ancre.
//
// À l'écran, un disque plein — la convention de tous les schémas : un point
// marque une connexion, son absence marque un croisement.
#pragma once

#include <QGraphicsItem>

class ItemJonction : public QGraphicsItem {
public:
    enum { Type = UserType + 3 };

    explicit ItemJonction(const QPointF& position);

    int type() const override { return Type; }
    QRectF boundingRect() const override;
    QPainterPath shape() const override;
    void paint(QPainter* peintre, const QStyleOptionGraphicsItem* option,
               QWidget* widget) override;

    // Un point isolé — dont il ne part plus qu'un fil ou aucun — n'a plus de
    // raison d'être : c'est la scène qui le balaie, elle seule sait compter.
    int degre = 0;

    // La pastille ne se dessine qu'à partir de trois fils. C'est la convention
    // de tous les schémas, et elle porte un sens : un point marque une
    // connexion. À deux fils il n'y a pas de connexion à marquer — juste un
    // changement de direction —, et l'afficher ferait croire à une dérivation
    // qui n'existe pas.
    bool jonction() const { return degre >= 3; }

    // Ce point appartient au nœud survolé. Un coude à deux fils ne dessine
    // rien d'ordinaire ; allumé, il montre son halo — sans quoi le nœud
    // s'interromprait visuellement à chaque changement de direction.
    void definir_surbrillance(bool active);
    bool surbrillance() const { return surbrillance_; }

private:
    bool surbrillance_ = false;
};
