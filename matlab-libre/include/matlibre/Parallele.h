// Parallele.h — exécution parallèle réelle de parfor, spmd et parfeval.
//
// Le modèle est celui de MATLAB : un pool de travailleurs indépendants.
// Chaque travailleur est un interpréteur complet, avec son propre espace de
// travail ; rien n'est partagé, tout circule par copie. C'est ce qui rend
// l'exécution sûre sans verrou dans l'interpréteur lui-même.
#pragma once

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "matlibre/Arbre.h"
#include "matlibre/Valeur.h"

namespace matlibre {

class Interpreteur;

// Classification des variables d'un corps de parfor, telle que la décrit la
// documentation MathWorks (« Classification of Variables in parfor-Loops »).
struct PlanParfor {
    bool utilisable = false;         // faux : on retombe sur le séquentiel
    std::string raison;              // pourquoi, le cas échéant
    std::string variableBoucle;
    std::vector<std::string> diffusees;    // lues seulement : broadcast
    std::vector<std::string> tranches;     // écrites en X(i) = ...
    std::vector<std::string> reductions;   // X = X op ...
    std::map<std::string, std::string> operateurReduction;  // nom -> "+", "*", "[]"…
    std::vector<std::string> temporaires;  // écrites puis relues dans l'itération
};

PlanParfor analyserParfor(const NoeudPtr& boucle, const std::string& variableBoucle,
                          const Interpreteur& it);

// Nombre de travailleurs du pool courant (0 = pas de pool ouvert).
int taillePool();
void definirTaillePool(int n);
int coeursDisponibles();

// Exécute le corps « boucle » sur les itérations données, en parallèle.
// Rend faux si le plan n'est pas parallélisable : l'appelant reprend alors
// le chemin séquentiel.
bool executerParforParallele(Interpreteur& it, const NoeudPtr& boucle,
                             const std::vector<Valeur>& iterations, const PlanParfor& plan);

// Exécute un bloc spmd sur tous les travailleurs. Les variables écrites
// reviennent en « Composite » : une cellule 1xN, indexable par { }.
bool executerSpmd(Interpreteur& it, const NoeudPtr& bloc);

// Travaux asynchrones de parfeval : la fonction part sur un fil, l'appelant
// récupère plus tard le résultat par son numéro.
long long lancerTravail(Interpreteur& it, const Valeur& fonction, int nargout,
                        std::vector<Valeur> args);
bool travailFini(long long id);
std::vector<Valeur> recupererTravail(long long id);
void annulerTravail(long long id);
int travauxEnCours();

// Applique une fonction à des lots d'arguments, chacun sur un travailleur.
std::vector<std::vector<Valeur>> appliquerEnParallele(
    Interpreteur& it, const std::string& fonction,
    const std::vector<std::vector<Valeur>>& lots, int nargout);

}  // namespace matlibre
