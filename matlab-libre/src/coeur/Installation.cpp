// Installation.cpp — assemble la bibliothèque native au démarrage.
#include "matlibre/Bibliotheque.h"
#include "matlibre/Interpreteur.h"

namespace matlibre {

void Interpreteur::installerBibliotheque() {
    enregistrerBase(*this);
    enregistrerMath(*this);
    enregistrerTableaux(*this);
    enregistrerTexte(*this);
    enregistrerStructures(*this);
    enregistrerFonctionnel(*this);
    enregistrerEntreeSortie(*this);
    enregistrerAlgebre(*this);
    enregistrerStatistiques(*this);
    enregistrerSignal(*this);
    enregistrerPolynomes(*this);
    enregistrerOptimisation(*this);
    enregistrerTemps(*this);
    enregistrerSysteme(*this);
    enregistrerGraphique(*this);
    // Apres le graphique : « set » et « get » y remplacent les coquilles vides.
    enregistrerPoigneesGraphiques(*this);
    enregistrerTests(*this);
    enregistrerCartes(*this);
    enregistrerCreuses(*this);
    enregistrerParallele(*this);
    enregistrerGenerationC(*this);
    enregistrerDeboguage(*this);
    enregistrerInterface(*this);
}

}  // namespace matlibre
