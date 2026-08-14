// Un fil reliant deux bornes. Tracé en équerre, comme sur un schéma
// d'électronique — jamais en diagonale.
#pragma once

#include <QGraphicsItem>
#include <QPainterPath>

#include "app/schematic/Ancre.h"

class ItemComposant;

class ItemFil : public QGraphicsItem {
public:
    enum { Type = UserType + 2 };

    // Le fil relie deux ancres. C'est la forme générale.
    ItemFil(const Ancre& depart, const Ancre& arrivee);
    // Broche à broche : le cas courant, et celui qu'écrivaient tous les
    // appelants avant que l'ancre existe.
    ItemFil(ItemComposant* depart, int borne_depart, ItemComposant* arrivee,
            int borne_arrivee);

    int type() const override { return Type; }

    // Le chemin en équerre entre deux points. Exposé pour que l'aperçu tracé
    // pendant le geste soit EXACTEMENT celui du fil final : un aperçu qui
    // montre une diagonale et pose une équerre est un aperçu qui ment.
    static QPainterPath chemin(const QPointF& a, const QPointF& b);
    QRectF boundingRect() const override;
    QPainterPath shape() const override;
    void paint(QPainter* peintre, const QStyleOptionGraphicsItem* option,
               QWidget* widget) override;

    const Ancre& ancre_depart() const { return depart_; }
    const Ancre& ancre_arrivee() const { return arrivee_; }
    void definir_ancre_arrivee(const Ancre& ancre) { arrivee_ = ancre; }

    // Les quatre accesseurs d'origine. Ils rendent nullptr / 0 quand
    // l'extrémité est une jonction : les appelants qui ne connaissent que les
    // broches — sauvegarde, netlist, surbrillance — testent déjà le nullptr.
    ItemComposant* depart() const { return depart_.composant; }
    ItemComposant* arrivee() const { return arrivee_.composant; }
    int borne_depart() const { return depart_.borne; }
    int borne_arrivee() const { return arrivee_.borne; }

    bool touche(const ItemComposant* composant) const {
        return depart_.composant == composant || arrivee_.composant == composant;
    }
    bool touche(const ItemJonction* jonction) const {
        return depart_.jonction == jonction || arrivee_.jonction == jonction;
    }

    // Ce fil appartient au nœud survolé : il s'entoure d'un halo.
    //
    // La surbrillance ne remplace aucune couleur existante — ni celle de la
    // tension, ni celle de la sélection. Un halo POSÉ DESSOUS répond « ceci
    // est relié » sans effacer la réponse à « combien de volts » ni à « qu'ai-
    // je sélectionné » : les trois questions se posent en même temps.
    void definir_surbrillance(bool active);
    bool surbrillance() const { return surbrillance_; }

    // Tension du nœud, affichée pendant la simulation (NaN = pas de mesure).
    void definir_tension(double volts);
    // Vrai dès qu'une mesure a été portée sur ce fil.
    bool tension_connue() const { return tension_connue_; }
    void rafraichir();

private:
    Ancre depart_;
    Ancre arrivee_;
    double tension_ = 0.0;
    bool tension_connue_ = false;
    bool surbrillance_ = false;

    QPainterPath trace() const;
};
