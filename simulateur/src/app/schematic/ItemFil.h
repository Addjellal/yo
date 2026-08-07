// Un fil reliant deux bornes. Tracé en équerre, comme sur un schéma
// d'électronique — jamais en diagonale.
#pragma once

#include <QGraphicsItem>

class ItemComposant;

class ItemFil : public QGraphicsItem {
public:
    enum { Type = UserType + 2 };

    ItemFil(ItemComposant* depart, int borne_depart, ItemComposant* arrivee,
            int borne_arrivee);

    int type() const override { return Type; }
    QRectF boundingRect() const override;
    QPainterPath shape() const override;
    void paint(QPainter* peintre, const QStyleOptionGraphicsItem* option,
               QWidget* widget) override;

    ItemComposant* depart() const { return depart_; }
    ItemComposant* arrivee() const { return arrivee_; }
    int borne_depart() const { return borne_depart_; }
    int borne_arrivee() const { return borne_arrivee_; }

    bool touche(const ItemComposant* composant) const {
        return depart_ == composant || arrivee_ == composant;
    }

    // Tension du nœud, affichée pendant la simulation (NaN = pas de mesure).
    void definir_tension(double volts);
    void rafraichir();

private:
    ItemComposant* depart_ = nullptr;
    ItemComposant* arrivee_ = nullptr;
    int borne_depart_ = 0;
    int borne_arrivee_ = 0;
    double tension_ = 0.0;
    bool tension_connue_ = false;

    QPainterPath trace() const;
};
