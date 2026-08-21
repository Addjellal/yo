// Routage automatique.
//
// Ce que fait un auto-routeur, et ce qu'il ne fait pas, mérite d'être dit
// avant le code. Il ne remplace pas le routeur humain : sur une carte
// sérieuse, on route à la main ce qui compte — les masses, les signaux
// rapides, les pistes de puissance — et l'on confie le reste à la machine.
// C'est ainsi qu'on s'en sert dans ARES comme dans KiCad, et c'est pourquoi
// celui-ci ACCEPTE les pistes déjà tracées comme des obstacles au lieu de
// les effacer.
//
// La méthode est celle de Lee, guidée par A* : la carte devient une grille,
// chaque case est libre ou occupée, et l'on cherche le chemin le moins cher
// d'une pastille à l'autre. Deux couches, avec un coût pour changer de face —
// un via coûte cher à percer, et une carte pleine de vias est une carte mal
// routée.
//
// Le point délicat n'est pas l'algorithme, c'est ce qui compte comme
// obstacle : le cuivre déjà posé, mais élargi de l'isolation exigée. Router
// au ras d'une piste voisine produit une carte que le fabricant refuse — et
// le contrôle des règles, lui, ne pardonne pas.
#pragma once

#include <string>
#include <vector>

#include "coeur/pcb/Pcb.h"

namespace coeur {

struct ReglagesRoutage {
    double pas = 0.4;           // maille de la grille, en millimètres
    double largeur = 0.4;       // largeur des pistes posées
    double isolation = 0.25;    // distance minimale à tout autre cuivre
    // Ce que coûte un changement de face, exprimé en cases. Élevé exprès :
    // un via se perce, se métallise, et fragilise la carte.
    double cout_via = 12.0;
    // Ce que coûte un virage, en cases. Une piste droite est plus courte à
    // graver, plus facile à contrôler, et plus jolie — ce dernier point n'est
    // pas un détail sur une carte qu'on montre à un élève.
    double cout_virage = 1.0;
    bool deux_couches = true;
};

struct CompteRenduRoutage {
    int liaisons = 0;           // à router au départ
    int routees = 0;
    int vias = 0;
    double longueur = 0;        // millimètres de cuivre posés
    std::vector<std::string> echecs;   // les nets qu'on n'a pas su relier
    std::string resume() const;
};

// Route ce qui reste à router sur cette carte. Les pistes déjà présentes sont
// conservées et respectées. Renvoie le compte rendu ; la carte est modifiée.
CompteRenduRoutage router(CartePcb& carte, const ReglagesRoutage& reglages = {});

}  // namespace coeur
