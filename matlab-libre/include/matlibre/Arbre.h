// Arbre.h — l'arbre syntaxique produit par l'analyseur.
//
// Un seul type de nœud porte toutes les formes du langage : c'est moins
// typé qu'une hiérarchie de classes, mais l'interpréteur n'a alors qu'un
// seul « switch » à tenir, et l'arbre se sérialise sans effort.
#pragma once

#include <map>
#include <memory>
#include <string>
#include <vector>

namespace matlibre {

enum class TypeN {
    // --- expressions ---
    Nombre, Litteral, LitteralChaine, Ident, FinIndice, DeuxPointsSeul,
    OpBinaire, OpUnaire, OpPostfixe, Plage, Matrice, Cellule, Acces,
    Anonyme, PoigneeNom,
    // --- instructions ---
    Bloc, Expression, Affectation, Si, Pour, TantQue, FaireJusqua, Choix,
    Essayer, Rupture, Continuer, Retour, Global, Persistant, Commande,
    Rien
};

struct Noeud;
using NoeudPtr = std::shared_ptr<Noeud>;

struct ElementAcces {
    char genre = '(';  // '(' indice, '{' cellule, '.' champ, '?' champ dynamique
    std::vector<NoeudPtr> args;
    std::string nom;
};

struct Noeud {
    TypeN type = TypeN::Rien;
    std::string texte;              // nom, opérateur, littéral
    double nombre = 0.0;
    bool imaginaire = false;
    bool afficher = false;          // instruction sans point-virgule
    bool drapeau = false;           // « else » présent, « otherwise » présent…
    int ligne = 0;
    std::vector<NoeudPtr> enfants;
    std::vector<NoeudPtr> cibles;   // membres de gauche d'une affectation
    std::vector<std::vector<NoeudPtr>> rangees;  // littéraux [ ] et { }
    std::vector<ElementAcces> acces;
    std::vector<std::string> noms;  // paramètres d'une fonction anonyme, global…

    static NoeudPtr creer(TypeN t) {
        auto n = std::make_shared<Noeud>();
        n->type = t;
        return n;
    }
};

struct FonctionUtilisateur {
    std::string nom;
    std::vector<std::string> entrees;
    std::vector<std::string> sorties;
    NoeudPtr corps;
    std::string fichier;
    std::string aide;  // bloc de commentaires d'en-tête
    // Sous-fonctions du même fichier, visibles seulement depuis lui.
    std::map<std::string, std::shared_ptr<FonctionUtilisateur>> voisines;
    bool variadiqueEntree() const {
        return !entrees.empty() && entrees.back() == "varargin";
    }
    bool variadiqueSortie() const {
        return !sorties.empty() && sorties.back() == "varargout";
    }
};

// Description d'une classe « classdef ».
struct DefinitionClasse {
    std::string nom;
    std::vector<std::string> parents;
    bool poignee = false;  // < handle
    std::vector<std::string> ordreProprietes;
    std::map<std::string, NoeudPtr> defauts;  // valeur par défaut (expression)
    std::map<std::string, std::shared_ptr<FonctionUtilisateur>> methodes;
    std::vector<std::string> constantes;
    std::string aide;
};

struct UniteCompilee {
    NoeudPtr script;  // instructions de tête (script) — peut être nul
    std::vector<std::shared_ptr<FonctionUtilisateur>> fonctions;
    std::vector<std::shared_ptr<DefinitionClasse>> classes;
    std::string aide;
};

}  // namespace matlibre
