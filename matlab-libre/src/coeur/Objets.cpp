// Objets.cpp — classes définies par l'utilisateur et tables associatives.
//
// Trois mécanismes du langage sont regroupés ici :
//   - la résolution des méthodes et des accesseurs d'une classe ;
//   - la construction de la structure « substruct » que reçoivent subsref
//     et subsasgn, telle que la documente MathWorks ;
//   - les tables « containers.Map », dont l'état vit dans l'interpréteur
//     pour leur donner la sémantique de poignée.
#include <algorithm>
#include <cmath>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {

std::shared_ptr<DefinitionClasse> Interpreteur::classeDe(const Valeur& v) {
    if (v.classe != Classe::Objet || v.nomObjet.empty()) return nullptr;
    return classeDefinie(v.nomObjet);
}

bool Interpreteur::classePossede(const Valeur& v, const std::string& methode) {
    auto def = classeDe(v);
    return def && def->aMethode(methode);
}

bool Interpreteur::dansMethodeDe(const std::string& classe) const {
    if (classe.empty()) return false;
    for (auto it = piles_.rbegin(); it != piles_.rend(); ++it) {
        const auto& p = *it;
        if (!p || !p->fonction) continue;
        return p->fonction->classeProprietaire == classe;
    }
    return false;
}

std::vector<Valeur> Interpreteur::appelerMethode(const Valeur& objet,
                                                 const std::string& methode,
                                                 std::vector<Valeur> args, int nargout) {
    auto def = classeDe(objet);
    if (!def || !def->aMethode(methode))
        erreur("MATLAB:noSuchMethodOrField",
               "Unrecognized method '" + methode + "' for class '" + objet.nomObjet + "'.");
    std::vector<Valeur> complet;
    if (!def->estStatique(methode)) complet.push_back(objet);
    for (auto& a : args) complet.push_back(a);
    return appelerUtilisateur(def->methodes[methode], complet, nargout);
}

// La structure attendue par subsref : un tableau 1xN de champs « type » et
// « subs ». type vaut '()', '{}' ou '.', subs une cellule d'indices ou le
// nom du champ.
Valeur Interpreteur::substruct(const std::vector<ElementAcces>& chaine, std::size_t debut,
                               const Valeur* base) {
    std::size_t n = chaine.size() - debut;
    Valeur s;
    s.classe = Classe::Structure;
    s.dims = {1, (int)n};
    s.st = std::make_shared<ChampsStructure>();
    s.st->ordre = {"type", "subs"};
    s.st->champs["type"] = std::vector<Valeur>(n, Valeur::vide());
    s.st->champs["subs"] = std::vector<Valeur>(n, Valeur::vide());
    for (std::size_t k = 0; k < n; ++k) {
        const ElementAcces& e = chaine[debut + k];
        if (e.genre == '.' || e.genre == '?') {
            std::string nom = e.nom;
            if (e.genre == '?') {
                auto args = evaluerListe(e.args);
                if (!args.empty()) nom = args[0].versTexte();
            }
            s.st->champs["type"][k] = Valeur::texte(".");
            s.st->champs["subs"][k] = Valeur::texte(nom);
        } else {
            auto idx = evaluerIndices(e.args, k == 0 ? base : nullptr, 0, (int)e.args.size());
            Valeur cellule = Valeur::celluleLigne(idx);
            s.st->champs["type"][k] = Valeur::texte(e.genre == '(' ? "()" : "{}");
            s.st->champs["subs"][k] = cellule;
        }
    }
    return s;
}

Valeur Interpreteur::lireProprieteObjet(const Valeur& objet, const std::string& nom) {
    if (estCarte(objet)) {
        auto table = carteDe(objet);
        if (nom == "Count") return Valeur::scalaire((double)table->ordre.size());
        if (nom == "KeyType") return Valeur::texte(table->typeCle);
        if (nom == "ValueType") return Valeur::texte(table->typeValeur);
        if (nom == "keys" || nom == "values" || nom == "length") {
            std::vector<Valeur> args = {objet};
            auto r = appeler(nom, args, 1);
            return r.empty() ? Valeur::vide() : r[0];
        }
        erreur("MATLAB:noSuchMethodOrField",
               "Unrecognized property '" + nom + "' for class 'containers.Map'.");
    }
    auto def = classeDe(objet);
    if (def) {
        // Une propriété dépendante passe par son accesseur get.
        std::string accesseur = "get." + nom;
        if (def->aMethode(accesseur)) {
            auto r = appelerMethode(objet, accesseur, {}, 1);
            return r.empty() ? Valeur::vide() : r[0];
        }
    }
    if (!objet.aChamp(nom))
        erreur("MATLAB:noSuchMethodOrField",
               "Unrecognized property '" + nom + "' for class '" + objet.nomObjet + "'.");
    return objet.champ(nom, 0);
}

Valeur Interpreteur::ecrireProprieteObjet(Valeur objet, const std::string& nom,
                                          const Valeur& valeur) {
    auto def = classeDe(objet);
    if (def) {
        std::string accesseur = "set." + nom;
        if (def->aMethode(accesseur)) {
            auto r = appelerMethode(objet, accesseur, {valeur}, 1);
            if (!r.empty()) {
                Valeur o = r[0];
                o.classe = Classe::Objet;
                o.nomObjet = objet.nomObjet;
                o.poigneeObjet = objet.poigneeObjet;
                return o;
            }
            return objet;
        }
    }
    objet.poserChamp(nom, valeur, 0);
    return objet;
}

// ------------------------------------------------------- containers.Map

bool Interpreteur::estCarte(const Valeur& v) const {
    return v.classe == Classe::Objet && v.nomObjet == "containers.Map";
}

std::shared_ptr<CarteAssociative> Interpreteur::carteDe(const Valeur& v) {
    if (!estCarte(v)) erreur("MATLAB:Map:invalidHandle", "Not a containers.Map object.");
    long long id = (long long)v.champ("__id", 0).scal();
    auto it = cartes.find(id);
    if (it == cartes.end())
        erreur("MATLAB:Map:invalidHandle", "This containers.Map handle is no longer valid.");
    return it->second;
}

// Une clé de containers.Map est un texte ou un nombre ; on la ramène à une
// chaîne pour l'ordre, en gardant la valeur d'origine pour « keys ».
std::string Interpreteur::cleCanonique(const Valeur& cle) {
    if (cle.estTexte() || cle.estChaine()) return "s:" + cle.versTexte();
    if (cle.estNumerique() || cle.classe == Classe::Logique)
        return "n:" + formater("%.17g", cle.scal());
    erreur("MATLAB:Map:invalidKeyType",
           "Keys must be a character vector, a string, or a numeric scalar.");
}

Valeur Interpreteur::lireCarte(const Valeur& carte, const Valeur& cle) {
    auto table = carteDe(carte);
    std::string k = cleCanonique(cle);
    auto it = table->valeurs.find(k);
    if (it == table->valeurs.end())
        erreur("MATLAB:Containers:Map:NoKey",
               "The given key is not present in the container.");
    return it->second;
}

void Interpreteur::ecrireCarte(const Valeur& carte, const Valeur& cle, const Valeur& valeur) {
    auto table = carteDe(carte);
    std::string k = cleCanonique(cle);
    if (!table->valeurs.count(k)) {
        table->ordre.push_back(k);
        std::sort(table->ordre.begin(), table->ordre.end());
        table->clesOriginales[k] = cle;
    }
    table->valeurs[k] = valeur;
}

Valeur Interpreteur::creerCarte(std::shared_ptr<CarteAssociative> carte) {
    long long id = prochaineCarte++;
    cartes[id] = std::move(carte);
    Valeur v = Valeur::structureVide();
    v.classe = Classe::Objet;
    v.nomObjet = "containers.Map";
    v.poigneeObjet = true;
    v.poserChamp("__id", Valeur::scalaire((double)id));
    return v;
}

}  // namespace matlibre
