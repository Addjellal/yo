// GenerationC.h — traduction d'une fonction MATLAB en C.
//
// Le générateur travaille sur l'arbre syntaxique produit par l'analyseur,
// pas sur le texte : il connaît donc la forme exacte du programme, et peut
// propager les types et les dimensions. Les tableaux sont de taille fixe,
// rangés par colonnes comme dans MATLAB, ce qui donne du C sans allocation
// dynamique — ce qu'on veut embarquer.
#pragma once

#include <string>
#include <vector>

#include "matlibre/Arbre.h"

namespace matlibre {

class Interpreteur;

// Type d'une variable dans le code produit : une classe de base et des
// dimensions connues à la compilation.
struct TypeC {
    enum class Base {
        Double, Single, Int8, Int16, Int32, Int64,
        UInt8, UInt16, UInt32, UInt64, Logique, Caractere
    };
    Base base = Base::Double;
    int lignes = 1;
    int colonnes = 1;
    bool estScalaire() const { return lignes == 1 && colonnes == 1; }
    int elements() const { return lignes * colonnes; }
    std::string nomC() const;
    std::string nomMatlab() const;
    bool entier() const;
    bool signe() const;
    double minimum() const;
    double maximum() const;
};

TypeC typeDepuisTexte(const std::string& classe, int lignes, int colonnes);

struct OptionsC {
    std::string nomFonction;
    std::vector<TypeC> entrees;
    int nargout = 1;
    std::string langage = "c";      // « c » ou « c++ »
    std::string prefixe;            // préfixe des symboles produits
    bool principal = false;         // produire aussi un main de démonstration
    bool commentaires = true;       // reprendre les lignes MATLAB en commentaire
};

struct ResultatC {
    std::string source;                       // le .c
    std::string entete;                       // le .h
    std::vector<std::string> avertissements;  // ce qui n'a pas pu être traduit
    std::vector<std::string> fonctions;       // noms des fonctions produites
};

// Traduit la fonction nommée dans les options. Lève une erreur MATLAB si le
// programme sort du sous-ensemble traduisible, en disant quoi et où.
ResultatC genererC(Interpreteur& it, const OptionsC& options);

}  // namespace matlibre
