// Campagnes de simulation : plusieurs passes d'une même analyse.
//
// Deux besoins que toute une analyse ne couvre pas :
//   * le BALAYAGE PARAMÉTRIQUE (« .step » de LTspice) — refaire la même
//     analyse pour plusieurs valeurs d'un composant, et superposer les
//     courbes. C'est ainsi qu'on voit une coupure se déplacer quand on change
//     une résistance ;
//   * le MONTE-CARLO — tirer au sort les valeurs dans leur tolérance et
//     recommencer, pour savoir si un montage tient encore avec des composants
//     à 5 %. C'est la question qu'on se pose avant de commander cent cartes.
//
// Les deux se ramènent à la même mécanique : modifier la netlist, relancer,
// garder le résultat. Rien de tout cela n'existe dans ngspice sous cette
// forme — c'est l'atelier qui orchestre.
#pragma once

#include <string>
#include <vector>

#include "coeur/Netlist.h"
#include "coeur/analyses/Analyses.h"
#include "coeur/moteurs/analogique/NgspiceEngine.h"

namespace coeur {

struct Passe {
    std::string etiquette;    // « R1 = 4.7 kΩ », « tirage 3 »
    double valeur = 0;        // valeur du paramètre, quand il y en a un
    Balayage balayage;
};

struct Campagne {
    std::string parametre;    // « R1.ohms », « tolérance 5 % »
    std::vector<Passe> passes;
    std::vector<std::string> erreurs;

    bool vide() const { return passes.empty(); }
};

// Refait `directive` pour chaque valeur de `valeurs`, en remplaçant la
// propriété `propriete` du composant `reference`.
Campagne balayer_parametre(const Netlist& netlist,
                           const std::vector<BrocheElectrique>& broches,
                           const std::string& reference,
                           const std::string& propriete,
                           const std::vector<double>& valeurs,
                           const std::string& directive);

// Valeurs à faire varier lors d'un Monte-Carlo : ce sont celles qui ont une
// tolérance dans la vraie vie — résistances, condensateurs, bobines.
bool valeur_tolerancee(const std::string& type, std::string& propriete);

// `tolerance` en pourcentage (5 pour ±5 %). La graine rend le tirage
// reproductible : un résultat qu'on ne peut pas refaire ne prouve rien.
Campagne monte_carlo(const Netlist& netlist,
                     const std::vector<BrocheElectrique>& broches,
                     double tolerance, int tirages,
                     const std::string& directive, unsigned graine = 1);

// Dispersion d'une courbe à une abscisse donnée, sur toutes les passes.
struct Dispersion {
    bool valide = false;
    int passes = 0;
    double mini = 0, maxi = 0, moyenne = 0, ecart_type = 0;
};
Dispersion disperser(const Campagne& campagne, const std::string& courbe,
                     double abscisse);

}  // namespace coeur
