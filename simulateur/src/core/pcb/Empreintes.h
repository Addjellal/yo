// Bibliothèque d'empreintes.
//
// Une carte n'est crédible que si les empreintes le sont. Une rangée de
// pastilles au pas de 2,54 mm sous chaque composant, c'est un schéma de
// principe, pas un circuit imprimé : sur une vraie carte, un boîtier DIP a
// deux rangées écartées de 7,62 mm, une broche 1 carrée et un détrompeur
// sérigraphié ; une résistance a ses deux trous à 10,16 mm et son corps
// dessiné entre les deux ; une carte Arduino a ses quatre connecteurs à leurs
// vraies positions, avec le décalage de 0,16 pouce que tout le monde connaît.
//
// Ce fichier fabrique ces empreintes à partir des dimensions normalisées des
// boîtiers, et les attribue aux modèles du catalogue par leur nom d'empreinte.
// C'est exactement l'étape « attribution des empreintes » de KiCad ou le
// champ « PCB Package » de Proteus, faite ici une fois pour toutes.
#pragma once

#include <string>

#include "core/Device.h"

namespace coeur {
namespace empreintes {

// --- générateurs ---------------------------------------------------------
// Boîtier DIP : deux rangées écartées de 7,62 mm, pas de 2,54 mm, broche 1
// en bas à gauche, détrompeur à gauche.
Empreinte dip(int broches);
// Barrette de connexion au pas de 2,54 mm.
Empreinte barrette(int colonnes, int rangees);
// Bornier à vis, au pas de 5,08 mm : ce par quoi on raccorde ce qui ne se
// soude pas — moteur, haut-parleur, alimentation. Sur une carte, un moteur
// n'existe pas : il n'y a que le bornier qui l'alimente.
Empreinte bornier(int bornes);
// Composant axial couché : deux trous, le corps entre les deux.
Empreinte axial(const std::string& nom, double pas, double corps,
                double diametre_corps, bool polarise);
// Composant radial debout : deux trous côte à côte, corps circulaire.
Empreinte radial(const std::string& nom, double pas, double diametre,
                 bool polarise);
Empreinte to92();
Empreinte to220();
Empreinte led(double diametre);
// Module ou organe extérieur : un corps et une barrette de raccordement sur
// un bord.
Empreinte module(const std::string& nom, double largeur, double hauteur,
                 int broches);
// Carte Arduino Uno : contour réel, quatre connecteurs, quatre fixations.
Empreinte arduino_uno();

// --- attribution ---------------------------------------------------------
// Empreinte complète d'un modèle : gabarit reconnu par son nom, pastilles
// numérotées, bornes attribuées, sérigraphie.
Empreinte resoudre(const Modele& modele);
// Un composant qui ne déclare aucune empreinte (ni nom, ni pastille, ni
// encombrement) n'est pas une pièce : voltmètre, sonde, symbole
// d'alimentation. Il n'a rien à faire sur la carte.
bool physique(const Modele& modele);

}  // namespace empreintes
}  // namespace coeur
