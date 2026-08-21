// Troisième moteur : la simulation numérique événementielle.
//
// Les deux autres ne suffisent pas pour un 74HC595 ou un afficheur piloté en
// série. L'analogique demanderait un pas de calcul de l'ordre de la
// nanoseconde pour suivre une horloge à quelques mégahertz — la simulation
// deviendrait inutilisable. Or ces fronts sont DÉJÀ datés au cycle près par
// le microcontrôleur : il n'y a rien à échantillonner, seulement à propager.
//
// Ce moteur prend donc les événements de la fenêtre, les distribue aux
// composants numériques, récupère les événements de leurs sorties, et les
// rend sous forme de formes d'onde. Elles redeviennent des sources linéaires
// par morceaux dans le circuit analogique : les deux mondes se rejoignent
// sans qu'aucun des deux ne soit dégradé.
#pragma once

#include <map>
#include <string>
#include <vector>

#include "coeur/Device.h"
#include "coeur/Netlist.h"

namespace coeur {

// Un front sur un nœud du circuit, daté depuis le début de la fenêtre.
struct FrontNoeud {
    double instant = 0;
    std::string noeud;
    bool haut = false;
};

class MoteurNumerique {
public:
    // Propage les fronts dans les composants numériques de la netlist et
    // remplit leurs `ondes`. `niveaux` donne l'état des nœuds au début de la
    // fenêtre (issu de la résolution précédente).
    // Renvoie le nombre de composants qui ont réagi.
    int propager(Netlist& netlist, const std::vector<FrontNoeud>& fronts,
                 const std::map<std::string, double>& niveaux, double duree,
                 double tension_haute = 5.0);

    // Vrai si la netlist contient au moins un composant numérique : inutile
    // de faire tourner ce moteur sur un montage qui n'en a pas.
    static bool circuit_numerique(const Netlist& netlist);

private:
    double seuil_ = 2.5;
};

}  // namespace coeur
