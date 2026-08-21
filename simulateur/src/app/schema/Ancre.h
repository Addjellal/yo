// Une ancre : ce à quoi une extrémité de fil s'accroche.
//
// C'est la leçon prise dans le source de LibrePCB. Chez eux, `SI_NetLineAnchor`
// est la base commune de la broche de symbole, du point de fil et de la
// jonction de bus : un fil relie deux *ancres*, jamais deux broches. Toute la
// souplesse de leur éditeur vient de là — « partir d'un fil » n'est pas un cas
// particulier à prévoir, puisqu'une ancre en vaut une autre.
//
// Notre `ItemFil` reliait deux broches de composant et rien d'autre. Un fil
// qui part d'un fil n'y était pas mal géré : il était inexprimable. C'est la
// vraie cause du basculement en mode sélection qu'on observait — l'interface
// retombait sur le seul geste qu'elle savait faire.
#pragma once

#include <QPointF>

class ItemComposant;
class ItemJonction;

struct Ancre {
    // Exactement l'un des deux est renseigné.
    ItemComposant* composant = nullptr;   // une broche de composant…
    int borne = 0;
    ItemJonction* jonction = nullptr;     // … ou un point posé sur un fil

    Ancre() = default;
    Ancre(ItemComposant* c, int b) : composant(c), borne(b) {}
    explicit Ancre(ItemJonction* j) : jonction(j) {}

    bool valide() const { return composant != nullptr || jonction != nullptr; }
    bool operator==(const Ancre& autre) const {
        return composant == autre.composant && jonction == autre.jonction
               && (jonction != nullptr || borne == autre.borne);
    }
    bool operator!=(const Ancre& autre) const { return !(*this == autre); }

    // Où elle se trouve sur la feuille. Défini dans Ancre.cpp, qui est le seul
    // endroit où les deux types concrets sont connus.
    QPointF position() const;
};
