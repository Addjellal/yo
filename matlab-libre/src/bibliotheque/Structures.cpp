// Structures.cpp — cellules, structures et conversions entre les deux.
#include <algorithm>
#include <cmath>
#include <memory>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

FONCTION(fnCell) {
    INUTILISE
    Dims d = dimsDepuisArguments(args, 0, args.size());
    if (args.empty()) d = Dims{0, 0};
    return {Valeur::celluleDims(d)};
}

FONCTION(fnStruct) {
    INUTILISE
    if (args.empty()) return {Valeur::structureVide()};
    if (args.size() % 2 != 0)
        erreur("MATLAB:struct:NoValueForField",
               "Incorrect number of arguments: fields require values.");
    // Une valeur en cellule fabrique un tableau de structures, de la
    // taille de la cellule. Une cellule vide donne donc un tableau vide :
    // « struct('a',{},'b',{}) » est l'idiome qui declare les champs sans
    // creer d'element, et l'on y ajoute ensuite par « s(end+1) ».
    std::size_t n = 1;
    bool vide = false;
    for (std::size_t k = 1; k < args.size(); k += 2)
        if (args[k].classe == Classe::Cellule) {
            if (args[k].nelem() == 0) vide = true;
            n = std::max(n, args[k].nelem());
        }
    if (vide) n = 0;
    Valeur r;
    r.classe = Classe::Structure;
    r.dims = {n == 0 ? 0 : 1, (int)n};
    if (n == 1) r.dims = {1, 1};
    r.st = std::make_shared<ChampsStructure>();
    for (std::size_t k = 0; k + 1 < args.size(); k += 2) {
        std::string nom = args[k].versTexte();
        const Valeur& v = args[k + 1];
        r.st->ordre.push_back(nom);
        std::vector<Valeur> colonne(n);
        for (std::size_t i = 0; i < n; ++i) {
            if (v.classe == Classe::Cellule)
                colonne[i] = v.nelem() == 1 ? v.cellules[0]
                                            : (i < v.cellules.size() ? v.cellules[i]
                                                                     : Valeur::vide());
            else colonne[i] = v;
        }
        r.st->champs[nom] = colonne;
    }
    return {r};
}

// « properties », « isprop » et « ismethod » : ce qu'un objet expose.
// Sans elles, on ne pouvait pas demander a une classe ce qu'elle porte,
// et le code qui s'adapte a l'objet qu'on lui donne devait deviner.
std::vector<std::string> proprietesDe(Interpreteur& it, const Valeur& v) {
    std::vector<std::string> noms;
    if (v.classe == Classe::Objet) {
        auto def = it.classeDefinie(v.nomObjet);
        if (def) {
            for (const auto& nom : def->ordreProprietes) noms.push_back(nom);
            for (const auto& nom : def->dependantes) {
                bool deja = false;
                for (const auto& autre : noms) deja = deja || autre == nom;
                if (!deja) noms.push_back(nom);
            }
            return noms;
        }
    }
    // Un objet sans classdef — une poignee graphique, une carte — n'a
    // que ses champs a montrer.
    if (v.estStructure() || v.classe == Classe::Objet)
        for (const auto& nom : v.champs())
            if (nom.compare(0, 2, "__") != 0) noms.push_back(nom);
    return noms;
}

FONCTION(fnProperties) {
    INUTILISE
    exigerArguments(args, 1, 1, "properties");
    Valeur cible = args[0];
    if (cible.estTexte() || cible.estChaine()) {
        // « properties('maClasse') » : on interroge la classe elle-meme.
        auto def = it.classeDefinie(cible.versTexte());
        if (!def)
            erreur("MATLAB:class:InvalidArgument",
                   "'" + cible.versTexte() + "' n'est pas une classe connue.");
        std::vector<std::string> noms = def->ordreProprietes;
        for (const auto& nom : def->dependantes) {
            bool deja = false;
            for (const auto& autre : noms) deja = deja || autre == nom;
            if (!deja) noms.push_back(nom);
        }
        Valeur r = Valeur::celluleDims({(int)noms.size(), 1});
        for (std::size_t k = 0; k < noms.size(); ++k) r.cellules[k] = Valeur::texte(noms[k]);
        return {r};
    }
    std::vector<std::string> noms = proprietesDe(it, cible);
    Valeur r = Valeur::celluleDims({(int)noms.size(), 1});
    for (std::size_t k = 0; k < noms.size(); ++k) r.cellules[k] = Valeur::texte(noms[k]);
    return {r};
}

FONCTION(fnIsprop) {
    INUTILISE
    exigerArguments(args, 2, 2, "isprop");
    std::string cherche = args[1].versTexte();
    for (const auto& nom : proprietesDe(it, args[0]))
        if (nom == cherche) return {Valeur::booleen(true)};
    return {Valeur::booleen(false)};
}

FONCTION(fnIsmethod) {
    INUTILISE
    exigerArguments(args, 2, 2, "ismethod");
    std::string cherche = args[1].versTexte();
    std::string nomClasse;
    if (args[0].estTexte() || args[0].estChaine()) nomClasse = args[0].versTexte();
    else if (args[0].classe == Classe::Objet) nomClasse = args[0].nomObjet;
    if (nomClasse.empty()) return {Valeur::booleen(false)};
    auto def = it.classeDefinie(nomClasse);
    if (!def) return {Valeur::booleen(false)};
    return {Valeur::booleen(def->aMethode(cherche))};
}

FONCTION(fnFieldnames) {
    INUTILISE
    exigerArguments(args, 1, 1, "fieldnames");
    if (!args[0].estStructure())
        erreur("MATLAB:fieldnames:InvalidInputType",
               "Invalid input argument of type '" + args[0].classeNom() + "'.");
    const auto& noms = args[0].champs();
    Valeur r = Valeur::celluleDims({(int)noms.size(), 1});
    for (std::size_t k = 0; k < noms.size(); ++k) r.cellules[k] = Valeur::texte(noms[k]);
    return {r};
}

FONCTION(fnIsfield) {
    INUTILISE
    exigerArguments(args, 2, 2, "isfield");
    const Valeur& s = args[0];
    if (args[1].classe == Classe::Cellule) {
        Valeur r = Valeur::matriceDims(args[1].dims);
        r.classe = Classe::Logique;
        for (std::size_t k = 0; k < args[1].cellules.size(); ++k)
            r.re[k] = s.estStructure() && s.aChamp(args[1].cellules[k].versTexte()) ? 1 : 0;
        return {r};
    }
    return {Valeur::booleen(s.estStructure() && s.aChamp(args[1].versTexte()))};
}

FONCTION(fnRmfield) {
    INUTILISE
    exigerArguments(args, 2, 2, "rmfield");
    Valeur s = args[0];
    if (args[1].classe == Classe::Cellule) {
        for (const auto& c : args[1].cellules) s.retirerChamp(c.versTexte());
    } else {
        if (!s.aChamp(args[1].versTexte()))
            erreur("MATLAB:rmfield:InvalidFieldname",
                   "A field named '" + args[1].versTexte() + "' doesn't exist.");
        s.retirerChamp(args[1].versTexte());
    }
    return {s};
}

FONCTION(fnSetfield) {
    INUTILISE
    exigerArguments(args, 3, 3, "setfield");
    Valeur s = args[0];
    s.poserChamp(args[1].versTexte(), args[2]);
    return {s};
}

FONCTION(fnGetfield) {
    INUTILISE
    exigerArguments(args, 2, 2, "getfield");
    return {args[0].champ(args[1].versTexte())};
}

FONCTION(fnOrderfields) {
    INUTILISE
    exigerArguments(args, 1, 2, "orderfields");
    Valeur s = args[0];
    s.detacherStructure();
    std::sort(s.st->ordre.begin(), s.st->ordre.end());
    return {s};
}

FONCTION(fnStruct2cell) {
    INUTILISE
    exigerArguments(args, 1, 1, "struct2cell");
    const Valeur& s = args[0];
    const auto& noms = s.champs();
    Valeur r = Valeur::celluleDims({(int)noms.size(), 1});
    for (std::size_t k = 0; k < noms.size(); ++k) r.cellules[k] = s.champ(noms[k], 0);
    return {r};
}

FONCTION(fnCell2struct) {
    INUTILISE
    exigerArguments(args, 2, 3, "cell2struct");
    // Le premier argument doit etre une cellule : « c.cellules[k] » n'existe
    // pas ailleurs, et le lire sortait du tableau.
    if (args[0].classe != Classe::Cellule)
        erreur("MATLAB:cell2struct:NotACell", "Input C must be a cell array.");
    exigerSansObjet(args[1], "cell2struct");
    const Valeur& c = args[0];
    const Valeur& noms = args[1];
    Valeur r = Valeur::structureVide();
    for (std::size_t k = 0; k < noms.nelem() && k < c.nelem(); ++k) {
        std::string nom = noms.classe == Classe::Cellule ? noms.cellules[k].versTexte()
                                                         : noms.versTexte();
        r.poserChamp(nom, c.cellules[k]);
    }
    return {r};
}

FONCTION(fnNum2cell) {
    INUTILISE
    exigerArguments(args, 1, 1, "num2cell");
    const Valeur& v = args[0];
    Valeur r = Valeur::celluleDims(v.dims);
    for (std::size_t k = 0; k < v.nelem(); ++k) r.cellules[k] = extraireElement(v, k);
    return {r};
}

FONCTION(fnCell2mat) {
    INUTILISE
    exigerArguments(args, 1, 1, "cell2mat");
    const Valeur& c = args[0];
    if (c.classe != Classe::Cellule)
        erreur("MATLAB:cell2mat:NotACell", "Input must be a cell array.");
    if (c.estVide()) return {Valeur::vide()};
    int l = c.nlignes(), co = c.ncolonnes();
    std::vector<std::vector<Valeur>> rangees;
    for (int i = 0; i < l; ++i) {
        std::vector<Valeur> ligne;
        for (int j = 0; j < co; ++j)
            ligne.push_back(c.cellules[(std::size_t)i + (std::size_t)j * l]);
        rangees.push_back(ligne);
    }
    return {concatenerRangees(rangees)};
}

FONCTION(fnMat2cell) {
    INUTILISE
    exigerArguments(args, 2, 3, "mat2cell");
    exigerNumerique(args[0], "mat2cell");
    for (std::size_t k = 1; k < args.size(); ++k) exigerNumerique(args[k], "mat2cell");
    const Valeur& v = args[0];
    std::vector<int> lignes, colonnes;
    for (std::size_t k = 0; k < args[1].nelem(); ++k) lignes.push_back((int)args[1].re[k]);
    if (args.size() > 2)
        for (std::size_t k = 0; k < args[2].nelem(); ++k) colonnes.push_back((int)args[2].re[k]);
    else colonnes.push_back(v.ncolonnes());
    Valeur r = Valeur::celluleDims({(int)lignes.size(), (int)colonnes.size()});
    int decalageLigne = 0;
    for (std::size_t i = 0; i < lignes.size(); ++i) {
        int decalageColonne = 0;
        for (std::size_t j = 0; j < colonnes.size(); ++j) {
            Valeur bloc = Valeur::matrice(lignes[i], colonnes[j]);
            for (int a = 0; a < lignes[i]; ++a)
                for (int b = 0; b < colonnes[j]; ++b)
                    bloc.re[(std::size_t)a + (std::size_t)b * lignes[i]] =
                        v.re[(std::size_t)(decalageLigne + a) +
                             (std::size_t)(decalageColonne + b) * v.nlignes()];
            r.cellules[i + j * lignes.size()] = bloc;
            decalageColonne += colonnes[j];
        }
        decalageLigne += lignes[i];
    }
    return {r};
}

FONCTION(fnDeal) {
    INUTILISE
    exigerArguments(args, 1, 0, "deal");
    int n = std::max(1, nargout);
    std::vector<Valeur> sorties;
    if (args.size() == 1) {
        for (int k = 0; k < n; ++k) sorties.push_back(args[0]);
        return sorties;
    }
    if ((int)args.size() < n)
        erreur("MATLAB:deal:narginMismatch",
               "The number of outputs should match the number of inputs.");
    for (int k = 0; k < n; ++k) sorties.push_back(args[(std::size_t)k]);
    return sorties;
}

}  // namespace

void enregistrerStructures(Interpreteur& it) {
    it.enregistrer("cell", fnCell, "structures", "cell  Tableau de cellules vide.");
    it.enregistrer("struct", fnStruct, "structures", "struct  Construit une structure.");
    it.enregistrer("properties", fnProperties, "structures",
                   "properties  Proprietes d'un objet ou d'une classe.");
    it.enregistrer("isprop", fnIsprop, "structures", "isprop  L'objet a-t-il cette propriete.");
    it.enregistrer("ismethod", fnIsmethod, "structures", "ismethod  La classe a-t-elle cette methode.");
    it.enregistrer("fieldnames", fnFieldnames, "structures", "fieldnames  Noms des champs.");
    it.enregistrer("isfield", fnIsfield, "structures", "isfield  Le champ existe-t-il.");
    it.enregistrer("rmfield", fnRmfield, "structures", "rmfield  Retire un champ.");
    it.enregistrer("setfield", fnSetfield, "structures", "setfield  Pose un champ.");
    it.enregistrer("getfield", fnGetfield, "structures", "getfield  Lit un champ.");
    it.enregistrer("orderfields", fnOrderfields, "structures", "orderfields  Trie les champs.");
    it.enregistrer("struct2cell", fnStruct2cell, "structures", "struct2cell  Structure -> cellule.");
    it.enregistrer("cell2struct", fnCell2struct, "structures", "cell2struct  Cellule -> structure.");
    it.enregistrer("num2cell", fnNum2cell, "structures", "num2cell  Tableau -> cellule.");
    it.enregistrer("cell2mat", fnCell2mat, "structures", "cell2mat  Cellule -> tableau.");
    it.enregistrer("mat2cell", fnMat2cell, "structures", "mat2cell  Decoupe en blocs.");
    it.enregistrer("deal", fnDeal, "structures", "deal  Distribue des valeurs.");
}

}  // namespace matlibre
