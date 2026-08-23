// Bibliotheque.h — enregistrement des fonctions natives et utilitaires
// partagés par les modules de la bibliothèque.
#pragma once

#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "matlibre/Arbre.h"
#include "matlibre/Valeur.h"

namespace matlibre {

class Interpreteur;

// Chaque module s'enregistre auprès de l'interpréteur.
void enregistrerBase(Interpreteur& it);
void enregistrerMath(Interpreteur& it);
void enregistrerTableaux(Interpreteur& it);
void enregistrerTexte(Interpreteur& it);
void enregistrerStructures(Interpreteur& it);
void enregistrerFonctionnel(Interpreteur& it);
void enregistrerEntreeSortie(Interpreteur& it);
void enregistrerAlgebre(Interpreteur& it);
void enregistrerStatistiques(Interpreteur& it);
void enregistrerSignal(Interpreteur& it);
void enregistrerPolynomes(Interpreteur& it);
void enregistrerOptimisation(Interpreteur& it);
void enregistrerTemps(Interpreteur& it);
void enregistrerSysteme(Interpreteur& it);
void enregistrerGraphique(Interpreteur& it);
void enregistrerTests(Interpreteur& it);
void enregistrerCartes(Interpreteur& it);
void enregistrerCreuses(Interpreteur& it);

// --- utilitaires communs ---
Valeur construirePlage(const Valeur& debut, const Valeur& pas, const Valeur& fin);
bool comparerCas(const Valeur& sujet, const Valeur& cas);
std::string nomMethodeOperateur(const std::string& op);
std::string texteExpression(const NoeudPtr& n);
Valeur construireObjet(Interpreteur& it, const std::shared_ptr<DefinitionClasse>& def,
                       std::vector<Valeur>& args);

// Vérifications d'arguments, avec les messages de MATLAB.
void exigerArguments(const std::vector<Valeur>& args, std::size_t mini, std::size_t maxi,
                     const char* nom);
double argScalaire(const std::vector<Valeur>& args, std::size_t k, const char* nom);
std::string argTexte(const std::vector<Valeur>& args, std::size_t k, const char* nom);
Dims dimsDepuisArguments(const std::vector<Valeur>& args, std::size_t debut, std::size_t fin);
int dimensionParDefaut(const Valeur& v);
// Vrai si l'un des arguments est l'option « all » : la réduction porte
// alors sur tous les éléments, comme depuis MATLAB R2018b.
bool optionToutesDimensions(const std::vector<Valeur>& args);
Valeur aplatirColonne(const Valeur& v);
Classe classeDepuisNom(const std::string& nom, bool* trouve = nullptr);

// Réductions le long d'une dimension (sum, prod, max, cumsum…).
Valeur reduire(const Valeur& v, int dimension, bool garderDim,
               const std::function<double(const std::vector<double>&)>& f);
void parcourirTranches(const Valeur& v, int dimension,
                       const std::function<void(std::vector<double>&, std::size_t)>& f);

}  // namespace matlibre
