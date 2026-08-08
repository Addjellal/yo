// Rendre une barre de réglages rétrécissable.
//
// Une rangée de boutons et de listes déroulantes annonce, comme taille
// minimale, la somme de tout ce qu'elle contient. Posée dans un panneau, elle
// impose cette largeur au panneau, le panneau à la fenêtre — et plus rien ne
// peut alors être étiré : chaque séparateur est déjà collé à sa butée. C'est
// exactement ce qui bloquait l'élargissement de la palette et l'agrandissement
// du panneau du bas.
//
// Déposée ici, la barre garde sa taille souhaitée tant qu'il y a la place, et
// devient défilante quand il n'y en a plus. Rien n'est jamais inatteignable,
// et le panneau redevient libre de rétrécir.
#pragma once

#include <QFrame>
#include <QLayout>
#include <QScrollArea>
#include <QSizePolicy>
#include <QWidget>

#include <algorithm>

namespace ihm {

// Emballe un widget déjà construit.
inline QScrollArea* barre_defilante(QWidget* contenu) {
    auto* zone = new QScrollArea;
    zone->setWidget(contenu);
    zone->setWidgetResizable(true);
    zone->setFrameShape(QFrame::NoFrame);
    // Verticalement « Maximum » : la barre prend sa hauteur souhaitée, jamais
    // plus — la courbe ou le dessin gardent tout le reste.
    zone->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Maximum);
    zone->setFocusPolicy(Qt::NoFocus);
    // Une zone défilante hérite sinon du minimum de ce qu'elle contient — et
    // le contenu, lui, réclame la somme de ses listes déroulantes. Un minimum
    // posé explicitement l'emporte : c'est ce qui coupe la chaîne.
    zone->setMinimumWidth(80);
    // Même chose en hauteur, mais sans jamais réclamer plus que la barre
    // elle-même : une barre d'une seule rangée garde sa hauteur naturelle,
    // une grille de quatre rangées accepte d'en montrer deux et de défiler.
    zone->setMinimumHeight(std::min(contenu->sizeHint().height() + 4, 60));
    return zone;
}

// Emballe une disposition : le cas courant, quand la barre n'existe que sous
// forme de QHBoxLayout ou de QGridLayout.
inline QScrollArea* barre_defilante(QLayout* disposition) {
    auto* contenu = new QWidget;
    disposition->setContentsMargins(0, 0, 0, 0);
    contenu->setLayout(disposition);
    return barre_defilante(contenu);
}

}  // namespace ihm
