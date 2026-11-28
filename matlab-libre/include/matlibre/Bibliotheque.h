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
void enregistrerMat(Interpreteur& it);
void enregistrerAlgebre(Interpreteur& it);
void enregistrerStatistiques(Interpreteur& it);
void enregistrerSignal(Interpreteur& it);
void enregistrerPolynomes(Interpreteur& it);
void enregistrerOptimisation(Interpreteur& it);
void enregistrerTemps(Interpreteur& it);
void enregistrerSysteme(Interpreteur& it);
void enregistrerGraphique(Interpreteur& it);
void enregistrerPoigneesGraphiques(Interpreteur& it);
void enregistrerTests(Interpreteur& it);
void enregistrerCartes(Interpreteur& it);
void enregistrerCreuses(Interpreteur& it);
void enregistrerParallele(Interpreteur& it);
void enregistrerGenerationC(Interpreteur& it);
void enregistrerDeboguage(Interpreteur& it);
void enregistrerInterface(Interpreteur& it);
void enregistrerArchives(Interpreteur& it);

// --- utilitaires communs ---
Valeur construirePlage(const Valeur& debut, const Valeur& pas, const Valeur& fin);
bool comparerCas(const Valeur& sujet, const Valeur& cas);
std::string nomMethodeOperateur(const std::string& op);
std::string texteExpression(const NoeudPtr& n);
std::string texteExpression(const NoeudPtr& n, int priorite);
Valeur construireObjet(Interpreteur& it, const std::shared_ptr<DefinitionClasse>& def,
                       std::vector<Valeur>& args);

// Vérifications d'arguments, avec les messages de MATLAB.
void exigerArguments(const std::vector<Valeur>& args, std::size_t mini, std::size_t maxi,
                     const char* nom);
double argScalaire(const std::vector<Valeur>& args, std::size_t k, const char* nom);
std::string argTexte(const std::vector<Valeur>& args, std::size_t k, const char* nom);
void rognerDimsFinales(Dims& d);
Dims dimsDepuisArguments(const std::vector<Valeur>& args, std::size_t debut, std::size_t fin);
int dimensionParDefaut(const Valeur& v);
// Vrai si l'un des arguments est l'option « all » : la réduction porte
// alors sur tous les éléments, comme depuis MATLAB R2018b.
bool optionToutesDimensions(const std::vector<Valeur>& args);
// Vrai si l'un des arguments est « omitnan » ; l'option, quelle qu'elle
// soit, est retirée de la liste au passage. Sans elle, un seul NaN suffit
// à rendre NaN toute la colonne, comme dans MATLAB.
bool optionOmettreNaN(std::vector<Valeur>& args);
// Le même vecteur, privé de ses NaN.
std::vector<double> sansNaN(const std::vector<double>& t);
Valeur aplatirColonne(const Valeur& v);
Classe classeDepuisNom(const std::string& nom, bool* trouve = nullptr);
// Une valeur convertie dans une classe, comme par int32(v), char(v)...
Valeur convertirValeurVers(const Valeur& v, Classe c);

// Réductions le long d'une dimension (sum, prod, max, cumsum…).
// Refuse une dimension negative : « all(1,-1) » indexait avant le
// tableau et corrompait le tas.
void exigerDimension(int dimension);
// Refuse ce qui ne porte pas de nombres — cellule, structure, objet,
// poignee : « re » y est vide alors que « nelem » annonce des elements.
void exigerNumerique(const Valeur& v, const char* nom);
// Idem, cellules admises : « sort » et « setdiff » les acceptent.
void exigerSansObjet(const Valeur& v, const char* nom);
// Un fichier nommé sans dossier — « fisheriris.mat » —, cherché dans le
// dossier courant puis dans les dossiers du chemin, comme MATLAB le fait
// pour LOAD et WHICH. Rend son chemin, ou une chaîne vide.
std::string fichierSurChemin(Interpreteur& it, const std::string& nom);

// Applique F élément par élément à des arguments numériques qui ont tous
// la même taille ou sont scalaires — la règle des fonctions de loi de
// MATLAB (normcdf, betainc...). Un scalaire vaut pour chaque élément ;
// deux tailles différentes lèvent « nom:InputSizeMismatch ». F reçoit
// les valeurs dans l'ordre des arguments.
Valeur appliquerParElements(const std::vector<Valeur>& arguments, const char* nom,
                            const std::function<double(const double*)>& f);

// Quantile de la loi normale centrée réduite (AS 241 de Wichura, poli
// par un pas de Newton) : juste sur tout ]0,1[, queues comprises.
double quantileNormal(double p);
// Une taille : finie, positive, representable.
int argTaille(double x, const char* nom);
// L'ordre de PERMUTE doit etre une permutation de 1..N.
void exigerPermutation(const Valeur& ordre, const Valeur& v, const char* nom);
Valeur reduire(const Valeur& v, int dimension, bool garderDim,
               const std::function<double(const std::vector<double>&)>& f);
void parcourirTranches(const Valeur& v, int dimension,
                       const std::function<void(std::vector<double>&, std::size_t)>& f);

}  // namespace matlibre
