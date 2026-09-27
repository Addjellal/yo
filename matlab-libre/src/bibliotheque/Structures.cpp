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
    // Un argument seul : « struct([]) » est le tableau de structures vide,
    // sans champ, d'où l'on part pour ajouter ; une structure se rend
    // telle quelle ; un objet donne la structure de ses proprietes.
    if (args.size() == 1) {
        const Valeur& a = args[0];
        if (a.classe == Classe::Structure) return {a};
        if (a.classe == Classe::Objet && a.st) {
            Valeur r = a;
            r.classe = Classe::Structure;
            r.nomObjet.clear();
            r.poigneeObjet = false;
            r.st = std::make_shared<ChampsStructure>(*a.st);
            return {r};
        }
        if (a.estVide() && a.classe != Classe::Cellule) {
            Valeur r;
            r.classe = Classe::Structure;
            r.dims = {0, 0};
            r.st = std::make_shared<ChampsStructure>();
            return {r};
        }
        erreur("MATLAB:invalidConversion",
               formater("Conversion to struct from %s is not possible.",
                        a.classeNom().c_str()));
    }
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

// Le nom des membres d'une classe, par famille. MATLAB en fait quatre
// fonctions du meme dessin : « methods », « events », « enumeration » et
// « properties ». Les trois premieres manquaient.
static std::vector<Valeur> membresDeClasse(Interpreteur& it, Arguments& args,
                                           const char* nomFonction, char famille) {
    exigerArguments(args, 1, 2, nomFonction);
    std::string nomClasse = (args[0].estTexte() || args[0].estChaine())
                                ? args[0].versTexte()
                                : args[0].classeNom();
    auto def = it.classeDefinie(nomClasse);
    if (!def) {
        // Une classe native n'a pas de definition a lire : elle n'a ni
        // methode ni evenement declares, et le dire vaut mieux que de
        // faire croire a une erreur.
        return {Valeur::celluleDims({0, 1})};
    }
    std::vector<std::string> noms;
    if (famille == 'm') {
        for (const auto& kv : def->methodes) noms.push_back(kv.first);
        std::sort(noms.begin(), noms.end());
    } else if (famille == 'e') {
        noms = def->evenements;
    } else {
        noms = def->enumerations;
    }
    Valeur r = Valeur::celluleDims({(int)noms.size(), 1});
    for (std::size_t k = 0; k < noms.size(); ++k) r.cellules[k] = Valeur::texte(noms[k]);
    return {r};
}

FONCTION(fnMethods) {
    INUTILISE
    return membresDeClasse(it, args, "methods", 'm');
}

FONCTION(fnEvents) {
    INUTILISE
    return membresDeClasse(it, args, "events", 'e');
}

// [M, S] = enumeration(C) : les membres de l'énumération, et leurs noms.
// Sans sortie, la liste s'affiche. Une seule sortie demandée — un argument
// d'une autre fonction, « isempty(enumeration(x)) » — n'en rend qu'une.
FONCTION(fnEnumeration) {
    exigerArguments(args, 1, 1, "enumeration");
    std::string nomClasse = (args[0].estTexte() || args[0].estChaine())
                                ? args[0].versTexte()
                                : args[0].classeNom();
    auto def = it.classeDefinie(nomClasse);
    if (!def || !def->estEnumeration()) {
        if (nargout == 0) {
            it.sortie() << "No enumeration members for class '" << nomClasse << "'.\n";
            return {};
        }
        std::vector<Valeur> vides = {def ? it.valeurVideDeClasse(nomClasse, {0, 1})
                                         : Valeur::matriceDims({0, 1}),
                                     Valeur::celluleDims({0, 1})};
        if (nargout < 2) vides.resize(1);
        return vides;
    }
    Valeur noms = Valeur::celluleDims({(int)def->enumerations.size(), 1});
    for (std::size_t k = 0; k < def->enumerations.size(); ++k)
        noms.cellules[k] = Valeur::texte(def->enumerations[k]);
    if (nargout == 0) {
        it.sortie() << "Enumeration members for class '" << def->nom << "':\n\n";
        for (const auto& n : def->enumerations) it.sortie() << "    " << n << "\n";
        it.sortie() << "\n";
        return {};
    }
    std::vector<Valeur> r = {it.membresEnumeration(def), noms};
    if (nargout < 2) r.resize(1);
    return r;
}

// ISENUM(X) : vrai pour un membre d'énumération — c'est l'interpréteur qui
// le reconnaît —, faux pour tout le reste.
FONCTION(fnIsenum) {
    exigerArguments(args, 1, 1, "isenum");
    (void)nargout;
    return {Valeur::booleen(it.estEnumeration(args[0]))};
}

// La description d'une classe, reunie en une structure : son nom, ses
// proprietes, ses methodes, ses evenements et ses ancetres. MATLAB rend
// ici un objet « meta.class » ; il n'y a pas de hierarchie meta ici, et
// une structure porte la meme information sans pretendre au contraire.
FONCTION(fnMetaclass) {
    INUTILISE
    exigerArguments(args, 1, 1, "metaclass");
    std::string nomClasse = (args[0].estTexte() || args[0].estChaine())
                                ? args[0].versTexte()
                                : args[0].classeNom();
    Valeur r = Valeur::structureVide();
    r.poserChamp("Name", Valeur::texte(nomClasse));
    auto enCellule = [](const std::vector<std::string>& v) {
        Valeur c = Valeur::celluleDims({(int)v.size(), 1});
        for (std::size_t k = 0; k < v.size(); ++k) c.cellules[k] = Valeur::texte(v[k]);
        return c;
    };
    auto def = it.classeDefinie(nomClasse);
    if (!def) {
        std::vector<std::string> vide;
        r.poserChamp("PropertyList", enCellule(vide));
        r.poserChamp("MethodList", enCellule(vide));
        r.poserChamp("EventList", enCellule(vide));
        r.poserChamp("EnumerationMemberList", enCellule(vide));
        r.poserChamp("SuperclassList", enCellule(vide));
        r.poserChamp("HandleCompatible", Valeur::booleen(false));
        return {r};
    }
    std::vector<std::string> methodes;
    for (const auto& kv : def->methodes) methodes.push_back(kv.first);
    std::sort(methodes.begin(), methodes.end());
    std::vector<std::string> ancetres;
    for (const auto& a : def->ancetres) {
        bool deja = false;
        for (const auto& q : ancetres) deja = deja || q == a;
        if (!deja) ancetres.push_back(a);
    }
    r.poserChamp("PropertyList", enCellule(def->ordreProprietes));
    r.poserChamp("MethodList", enCellule(methodes));
    r.poserChamp("EventList", enCellule(def->evenements));
    r.poserChamp("EnumerationMemberList", enCellule(def->enumerations));
    r.poserChamp("SuperclassList", enCellule(ancetres));
    r.poserChamp("HandleCompatible", Valeur::booleen(def->poignee));
    return {r};
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
    // les champs cachés d'un membre d'énumération n'en sont pas
    std::vector<std::string> noms;
    for (const auto& nom : args[0].champs())
        if (nom.empty() || nom[0] != '\x01') noms.push_back(nom);
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

// Les indices que porte une cellule de GETFIELD ou SETFIELD : « {2} »,
// « {1, ':'} ».
static std::vector<Valeur> indicesDe(const Valeur& cellule) {
    std::vector<Valeur> idx(cellule.cellules.begin(), cellule.cellules.end());
    return idx;
}

static std::string nomDeChamp(const Valeur& v, const char* fonction) {
    if (!v.estTexte() && !(v.estChaine() && v.estScalaire()))
        erreur("MATLAB:" + std::string(fonction) + ":InvalidFieldName",
               formater("%s : un nom de champ est un texte, ou une cellule d'indices.",
                        fonction));
    return v.versTexte();
}

static Valeur lireChampDe(Interpreteur& it, const Valeur& base, const std::string& nom) {
    if (base.classe == Classe::Objet) return it.lireProprieteObjet(base, nom);
    if (base.classe != Classe::Structure)
        erreur("MATLAB:getfield:InvalidType",
               formater("getfield : on lit le champ '%s' d'une structure, pas d'un %s.",
                        nom.c_str(), base.classeNom().c_str()));
    if (!base.aChamp(nom))
        erreur("MATLAB:nonExistentField",
               formater("Reference to non-existent field '%s'.", nom.c_str()));
    if (base.nelem() == 0)
        erreur("MATLAB:index:expected_one_output",
               "getfield : la structure est vide, son champ n'a pas de valeur.");
    return base.champ(nom, 0);
}

// SETFIELD(S, CHAMP1, {I}, CHAMP2, ..., V) : l'écriture en profondeur, de
// la valeur V vers S, chaque niveau reposant ce qu'il a changé.
static Valeur poserEnProfondeur(Interpreteur& it, Valeur base, Arguments args, std::size_t k) {
    const std::size_t dernier = args.size() - 1;
    if (k == dernier) return args[dernier];
    const Valeur& cle = args[k];
    if (cle.classe == Classe::Cellule) {
        std::vector<Valeur> idx = indicesDe(cle);
        Valeur dedans = Valeur::vide();
        bool existe = true;
        try {
            std::vector<Valeur> copie = idx;
            dedans = it.indexer(base, copie, '(');
        } catch (...) {
            existe = false;
        }
        if (!existe) dedans = Valeur::vide();
        Valeur nouveau = poserEnProfondeur(it, dedans, args, k + 1);
        return it.ecrireIndex(base, idx, nouveau, '(');
    }
    const std::string nom = nomDeChamp(cle, "setfield");
    if (base.classe == Classe::Objet) {
        Valeur dedans = k + 1 < dernier ? it.lireProprieteObjet(base, nom) : Valeur::vide();
        Valeur nouveau = poserEnProfondeur(it, dedans, args, k + 1);
        return it.ecrireProprieteObjet(base, nom, nouveau);
    }
    if (base.classe != Classe::Structure) {
        if (!base.estVide())
            erreur("MATLAB:setfield:InvalidType",
                   formater("setfield : on pose le champ '%s' dans une structure, pas dans "
                            "un %s.", nom.c_str(), base.classeNom().c_str()));
        base = Valeur::structureVide();
    }
    if (base.nelem() == 0) {
        base.dims = {1, 1};
        base.detacherStructure();
        for (auto& kv : base.st->champs) kv.second.assign(1, Valeur::vide());
    }
    Valeur dedans = base.aChamp(nom) ? base.champ(nom, 0) : Valeur::vide();
    Valeur nouveau = poserEnProfondeur(it, dedans, args, k + 1);
    base.poserChamp(nom, nouveau);
    return base;
}

FONCTION(fnSetfield) {
    INUTILISE
    exigerArguments(args, 3, 0, "setfield");
    // Un premier argument en cellule désigne l'élément d'un tableau de
    // structures : « setfield(S, {2}, 'a', 5) ».
    return {poserEnProfondeur(it, args[0], args, 1)};
}

FONCTION(fnGetfield) {
    INUTILISE
    exigerArguments(args, 2, 0, "getfield");
    // « getfield(S, 'a', {2}, 'b') » : S.a(2).b, en autant de niveaux
    // qu'on en donne ; une cellule porte les indices du niveau qui la
    // précède.
    Valeur courant = args[0];
    for (std::size_t k = 1; k < args.size(); ++k) {
        if (args[k].classe == Classe::Cellule) {
            std::vector<Valeur> idx = indicesDe(args[k]);
            courant = it.indexer(courant, idx, '(');
            continue;
        }
        courant = lireChampDe(it, courant, nomDeChamp(args[k], "getfield"));
    }
    return {courant};
}

FONCTION(fnOrderfields) {
    INUTILISE
    exigerArguments(args, 1, 2, "orderfields");
    Valeur s = args[0];
    if (s.classe != Classe::Structure)
        erreur("MATLAB:orderfields:InvalidInput",
               "orderfields : le premier argument est une structure.");
    s.detacherStructure();
    const std::vector<std::string> avant = s.st->ordre;
    std::vector<std::string> ordre;
    if (args.size() == 1) {
        ordre = avant;
        std::sort(ordre.begin(), ordre.end());
    } else {
        // Le second argument donne l'ordre : une structure aux mêmes
        // champs, une cellule de noms, ou une permutation des rangs.
        const Valeur& modele = args[1];
        if (modele.classe == Classe::Structure) {
            ordre = modele.champs();
        } else if (modele.classe == Classe::Cellule) {
            for (const Valeur& c : modele.cellules) ordre.push_back(c.versTexte());
        } else if (modele.estNumerique()) {
            for (std::size_t k = 0; k < modele.nelem(); ++k) {
                double r = modele.re[k];
                if (r != std::floor(r) || r < 1 || r > (double)avant.size())
                    erreur("MATLAB:orderfields:InvalidPermutation",
                           "orderfields : la permutation porte les rangs 1 a N des champs.");
                ordre.push_back(avant[(std::size_t)r - 1]);
            }
        } else {
            erreur("MATLAB:orderfields:InvalidInput",
                   "orderfields : l'ordre se donne par une structure, une cellule de noms "
                   "ou une permutation.");
        }
        std::vector<std::string> a = avant, b = ordre;
        std::sort(a.begin(), a.end());
        std::sort(b.begin(), b.end());
        if (a != b)
            erreur("MATLAB:orderfields:InvalidFieldNames",
                   "orderfields : le nouvel ordre doit nommer chaque champ une fois, et "
                   "seulement eux.");
    }
    s.st->ordre = ordre;
    std::vector<Valeur> sorties = {s};
    if (nargout > 1) {
        Valeur p = Valeur::matrice((int)ordre.size(), 1);
        for (std::size_t k = 0; k < ordre.size(); ++k)
            p.re[k] = (double)(std::find(avant.begin(), avant.end(), ordre[k]) -
                               avant.begin() + 1);
        sorties.push_back(p);
    }
    return sorties;
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
    exigerArguments(args, 1, 2, "num2cell");
    const Valeur& v = args[0];
    if (args.size() == 1) {
        Valeur r = Valeur::celluleDims(v.dims);
        for (std::size_t k = 0; k < v.nelem(); ++k) r.cellules[k] = extraireElement(v, k);
        return {r};
    }
    // « num2cell(A, dims) » : chaque cellule porte A tout entier le long des
    // dimensions données, une par position des autres. num2cell(A, 1) rend
    // les colonnes de A.
    exigerNumerique(args[1], "num2cell");
    std::vector<bool> reunie;
    for (std::size_t k = 0; k < args[1].nelem(); ++k) {
        double d = args[1].re[k];
        if (d < 1 || d != std::floor(d))
            erreur("MATLAB:num2cell:InvalidDimension",
                   "num2cell : les dimensions sont des entiers positifs.");
        if ((std::size_t)d > reunie.size()) reunie.resize((std::size_t)d, false);
        reunie[(std::size_t)d - 1] = true;
    }
    Dims source = v.dims;
    std::size_t nd = std::max(source.size(), reunie.size());
    source.resize(nd, 1);
    reunie.resize(nd, false);
    Dims taille = source;
    for (std::size_t d = 0; d < nd; ++d)
        if (reunie[d]) taille[d] = 1;
    while (taille.size() > 2 && taille.back() == 1) taille.pop_back();
    nd = std::max<std::size_t>(nd, taille.size());
    Valeur r = Valeur::celluleDims(taille);
    std::size_t n = produitDims(taille);
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t reste = k;
        std::vector<Valeur> idx(nd);
        for (std::size_t d = 0; d < nd; ++d) {
            std::size_t t = d < taille.size() ? (std::size_t)std::max(1, taille[d]) : 1;
            std::size_t coord = reste % t;
            reste /= t;
            idx[d] = reunie[d] ? Valeur::texte(":") : Valeur::scalaire((double)coord + 1);
        }
        r.cellules[k] = it.indexer(v, idx, '(');
    }
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
    it.enregistrer("methods", fnMethods, "structures",
                   "methods  Methodes d'un objet ou d'une classe.");
    it.enregistrer("events", fnEvents, "structures",
                   "events  Evenements declares par une classe.");
    it.enregistrer("isenum", fnIsenum, "structures",
                   "isenum  Vrai pour un membre d'enumeration.");
    it.enregistrer("enumeration", fnEnumeration, "structures",
                   "enumeration  Membres enumeres d'une classe.");
    it.enregistrer("metaclass", fnMetaclass, "structures",
                   "metaclass  Description d'une classe.");
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
