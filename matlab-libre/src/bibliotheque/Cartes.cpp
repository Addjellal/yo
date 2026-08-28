// Cartes.cpp — containers.Map.
//
// La table vit dans l'interpréteur ; l'objet n'en porte que l'identifiant.
// C'est ce qui donne à containers.Map sa sémantique de poignée : « n = m »
// ne copie pas la table, et « n('a') = 1 » se voit depuis m.
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
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

std::string typeDeCle(const Valeur& v) {
    if (v.estTexte() || v.estChaine()) return "char";
    return "double";
}

FONCTION(fnMap) {
    INUTILISE
    auto table = std::make_shared<CarteAssociative>();
    // containers.Map('KeyType','char','ValueType','any')
    std::size_t debut = 0;
    if (args.size() >= 2 && (args[0].estTexte() || args[0].estChaine())) {
        std::string premier = args[0].versTexte();
        if (premier == "KeyType" || premier == "ValueType" || premier == "UniformValues") {
            for (std::size_t k = 0; k + 1 < args.size(); k += 2) {
                std::string nom = args[k].versTexte();
                if (nom == "KeyType") table->typeCle = args[k + 1].versTexte();
                if (nom == "ValueType") table->typeValeur = args[k + 1].versTexte();
            }
            return {it.creerCarte(table)};
        }
    }
    if (args.size() >= 2) {
        const Valeur& cles = args[debut];
        const Valeur& valeurs = args[debut + 1];
        std::vector<Valeur> listeCles;
        std::vector<Valeur> listeValeurs;
        if (cles.classe == Classe::Cellule)
            for (const auto& c : cles.cellules) listeCles.push_back(c);
        else if (cles.classe == Classe::Chaine)
            for (const auto& c : cles.chaines) listeCles.push_back(Valeur::chaine(c));
        else if (cles.estTexte())
            listeCles.push_back(cles);
        else
            for (std::size_t k = 0; k < cles.nelem(); ++k)
                listeCles.push_back(Valeur::scalaire(cles.re[k]));
        if (valeurs.classe == Classe::Cellule)
            for (const auto& c : valeurs.cellules) listeValeurs.push_back(c);
        else if (valeurs.estTexte() && listeCles.size() == 1)
            listeValeurs.push_back(valeurs);
        else
            for (std::size_t k = 0; k < valeurs.nelem(); ++k)
                listeValeurs.push_back(extraireElement(valeurs, k));
        if (listeCles.size() != listeValeurs.size())
            erreur("MATLAB:Containers:Map:MismatchLength",
                   "The number of keys and values must match.");
        if (!listeCles.empty()) table->typeCle = typeDeCle(listeCles[0]);
        Valeur carte = it.creerCarte(table);
        for (std::size_t k = 0; k < listeCles.size(); ++k)
            it.ecrireCarte(carte, listeCles[k], listeValeurs[k]);
        return {carte};
    }
    return {it.creerCarte(table)};
}

FONCTION(fnKeys) {
    INUTILISE
    exigerArguments(args, 1, 1, "keys");
    auto table = it.carteDe(args[0]);
    Valeur c = Valeur::celluleDims({1, (int)table->ordre.size()});
    for (std::size_t k = 0; k < table->ordre.size(); ++k)
        c.cellules[k] = table->clesOriginales[table->ordre[k]];
    return {c};
}

FONCTION(fnValues) {
    INUTILISE
    exigerArguments(args, 1, 2, "values");
    auto table = it.carteDe(args[0]);
    if (args.size() > 1 && args[1].classe == Classe::Cellule) {
        Valeur c = Valeur::celluleDims({1, (int)args[1].cellules.size()});
        for (std::size_t k = 0; k < args[1].cellules.size(); ++k)
            c.cellules[k] = it.lireCarte(args[0], args[1].cellules[k]);
        return {c};
    }
    Valeur c = Valeur::celluleDims({1, (int)table->ordre.size()});
    for (std::size_t k = 0; k < table->ordre.size(); ++k)
        c.cellules[k] = table->valeurs[table->ordre[k]];
    return {c};
}

FONCTION(fnIsKey) {
    INUTILISE
    exigerArguments(args, 2, 2, "isKey");
    auto table = it.carteDe(args[0]);
    if (args[1].classe == Classe::Cellule) {
        Valeur r = Valeur::matriceDims({1, (int)args[1].cellules.size()});
        r.classe = Classe::Logique;
        for (std::size_t k = 0; k < args[1].cellules.size(); ++k)
            r.re[k] = table->valeurs.count(it.cleCanonique(args[1].cellules[k])) ? 1 : 0;
        return {r};
    }
    return {Valeur::booleen(table->valeurs.count(it.cleCanonique(args[1])) > 0)};
}

FONCTION(fnRemove) {
    INUTILISE
    exigerArguments(args, 2, 2, "remove");
    auto table = it.carteDe(args[0]);
    std::vector<Valeur> aRetirer;
    if (args[1].classe == Classe::Cellule)
        for (const auto& c : args[1].cellules) aRetirer.push_back(c);
    else
        aRetirer.push_back(args[1]);
    for (const auto& cle : aRetirer) {
        std::string k = it.cleCanonique(cle);
        if (!table->valeurs.count(k))
            erreur("MATLAB:Containers:Map:NoKey",
                   "The given key is not present in the container.");
        table->valeurs.erase(k);
        table->clesOriginales.erase(k);
        table->ordre.erase(std::remove(table->ordre.begin(), table->ordre.end(), k),
                           table->ordre.end());
    }
    return {args[0]};
}

FONCTION(fnCountCarte) {
    INUTILISE
    exigerArguments(args, 1, 1, "Count");
    return {Valeur::scalaire((double)it.carteDe(args[0])->ordre.size())};
}

}  // namespace

void enregistrerCartes(Interpreteur& it) {
    it.enregistrer("containers.Map", fnMap, "cartes",
                   "containers.Map  Table associative a semantique de poignee.\n"
                   "  M = containers.Map() cree une table vide.\n"
                   "  M = containers.Map(CLES, VALEURS) l'initialise.\n"
                   "  M('cle') lit, M('cle') = v ecrit, keys/values/isKey/remove.");
    it.enregistrer("keys", fnKeys, "cartes", "keys  Cles d'une containers.Map, triees.");
    it.enregistrer("values", fnValues, "cartes", "values  Valeurs d'une containers.Map.");
    it.enregistrer("isKey", fnIsKey, "cartes", "isKey  La cle est-elle presente.");
    it.enregistrer("remove", fnRemove, "cartes", "remove  Retire une cle.");
    it.enregistrer("mapCount", fnCountCarte, "cartes", "mapCount  Nombre d'entrees.");
}

}  // namespace matlibre
