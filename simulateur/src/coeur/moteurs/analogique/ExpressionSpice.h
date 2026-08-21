// Expressions des sources comportementales (« B »).
//
// Le catalogue s'en sert pour tout ce qui n'est pas une équation de composant
// mais une règle : une porte logique compare ses entrées à 2,5 V, un
// amplificateur opérationnel sature entre deux rails, un relais bascule.
// SPICE appelle cela une source B ; sa valeur est une expression des tensions
// du circuit.
//
//   Bref  sortie 0 V = (V(A) > 2.5) ? 5 : 0
//   Bao   sortie 0 V = min(max(1e5 * (V(P) - V(N)), 0.05), 12)
//
// Ce fichier lit ces expressions et les évalue. Rien de plus : pas de
// fonctions au hasard, seulement celles que le catalogue emploie.
#pragma once

#include <functional>
#include <string>
#include <vector>

namespace coeur {

class ExpressionSpice {
public:
    // Compile l'expression. `resoudre_noeud` donne l'indice d'un nœud du
    // circuit (−1 pour la masse). Renvoie faux si l'expression est mal formée.
    bool compiler(const std::string& texte,
                  const std::function<int(const std::string&)>& resoudre_noeud);

    // Évalue avec l'état courant du circuit. `tensions` est indexé par numéro
    // de nœud ; la masse vaut zéro.
    double evaluer(const std::vector<double>& tensions) const;

    // Nœuds dont la valeur dépend : ce sont eux qu'il faut dériver pour
    // linéariser la source à chaque itération de Newton.
    const std::vector<int>& dependances() const { return dependances_; }

    bool valide() const { return racine_ >= 0; }
    const std::string& erreur() const { return erreur_; }

private:
    enum class Op {
        Nombre, Tension, Plus, Moins, Fois, Divise, Oppose, Non,
        Sup, Inf, SupEgal, InfEgal, Egal, Different, Et, Ou,
        Ternaire, Mini, Maxi, Valeur_absolue, Exponentielle, Logarithme,
        Racine
    };
    struct Noeud {
        Op op = Op::Nombre;
        double valeur = 0;
        int a = -1, b = -1, c = -1;      // sous-expressions
        int noeud_plus = -1, noeud_moins = -1;   // pour Tension
    };

    std::vector<Noeud> arbre_;
    int racine_ = -1;
    std::vector<int> dependances_;
    std::string erreur_;

    // --- analyse syntaxique ---
    std::vector<std::string> jetons_;
    size_t position_ = 0;
    std::function<int(const std::string&)> resoudre_;

    bool fin() const { return position_ >= jetons_.size(); }
    const std::string& jeton() const;
    bool accepter(const std::string& attendu);

    int ajouter(Noeud noeud);
    int lire_ternaire();
    int lire_ou();
    int lire_et();
    int lire_comparaison();
    int lire_somme();
    int lire_produit();
    int lire_unaire();
    int lire_terme();

    double evaluer_noeud(int rang, const std::vector<double>& tensions) const;
};

}  // namespace coeur
