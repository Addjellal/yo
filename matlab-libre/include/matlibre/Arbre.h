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
    // Nom de la classe propriétaire quand la fonction est une méthode : à
    // l'intérieur d'une méthode, l'indexation d'un objet de cette classe
    // reste l'indexation par défaut, subsref/subsasgn ne sont pas appelés.
    std::string classeProprietaire;
    // Sous-fonctions du même fichier, visibles seulement depuis lui. Les
    // références sont faibles : les fonctions d'un fichier se voient
    // toutes entre elles, et des références fortes feraient des cycles que
    // rien ne libère — l'arbre d'un fichier oublié du cache restait en
    // mémoire. Ce qui les fait vivre, c'est leur groupe.
    std::map<std::string, std::weak_ptr<FonctionUtilisateur>> voisines;
    // Le groupe des fonctions du fichier : un pointeur vers l'une d'elles
    // rendu hors du fichier en partage le compte, si bien que tant que
    // l'une vit, toutes vivent.
    std::weak_ptr<void> groupe;
    // Les groupes que cette fonction fait vivre : les fonctions locales
    // d'un script qu'elle enveloppe, ou celles qu'un texte exécuté pendant
    // qu'elle tourne a définies.
    std::vector<std::shared_ptr<void>> groupesPossedes;
    // Fonctions imbriquées, écrites dans le corps de celle-ci : elles
    // partagent son espace de travail, comme le veut MATLAB.
    std::map<std::string, std::shared_ptr<FonctionUtilisateur>> imbriquees;
    bool imbriquee = false;   // vraie pour une fonction écrite dans une autre
    // Vraie pour un fichier .m sans « function » : un script. MATLAB
    // l'exécute dans l'espace de travail de l'appelant, pas dans le sien —
    // c'est toute la différence entre un script et une fonction.
    bool script = false;
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
    std::vector<std::string> dependantes;   // propriétés calculées par get.
    std::vector<std::string> statiques;     // méthodes appelables sans objet
    std::vector<std::string> evenements;    // noms déclarés par « events »
    // Noms déclarés par « enumeration », et les arguments de chacun —
    // « Mardi(2) » : la valeur d'un membre d'une énumération entière, ou
    // ce que reçoit le constructeur.
    std::vector<std::string> enumerations;
    std::vector<std::vector<NoeudPtr>> argumentsEnumeration;
    bool estEnumeration() const { return !enumerations.empty(); }
    // Les ancetres transitifs, parents des parents compris. « isa » les
    // consulte : un objet est de la classe de chacun d'eux.
    std::vector<std::string> ancetres;
    bool heritageFait = false;
    std::string aide;
    std::string fichier;   // d'où elle vient, pour « help » et le navigateur
    // Le groupe de ses méthodes et des fonctions locales de son fichier.
    std::shared_ptr<void> groupe;
    bool aMethode(const std::string& nom) const { return methodes.count(nom) > 0; }
    bool estStatique(const std::string& nom) const {
        for (const auto& s : statiques)
            if (s == nom) return true;
        return false;
    }
};

struct UniteCompilee {
    NoeudPtr script;  // instructions de tête (script) — peut être nul
    std::vector<std::shared_ptr<FonctionUtilisateur>> fonctions;
    std::vector<std::shared_ptr<DefinitionClasse>> classes;
    std::string aide;
};

}  // namespace matlibre
