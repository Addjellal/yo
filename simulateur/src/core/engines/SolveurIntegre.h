// Solveur analogique intégré : le simulateur n'a plus besoin de ngspice.
//
// Pourquoi l'écrire alors que ngspice existe ? Parce qu'une dépendance
// binaire externe est, en pratique, ce qui empêche le projet de se construire
// : sous Windows il faut trouver la bonne archive, la décompresser au bon
// endroit, la désigner à CMake, puis traîner sa DLL à côté de l'exécutable.
// Ici tout est dans les sources.
//
// Ce qu'il fait, c'est ce que fait SPICE :
//   * il lit le même fichier de circuit que ngspice — le catalogue n'a pas
//     changé d'une ligne ;
//   * il assemble le système d'analyse nodale modifiée (MNA) ;
//   * il le résout par élimination de Gauss, et par la méthode de Newton
//     quand le circuit est non linéaire (diodes, transistors) ;
//   * il intègre dans le temps par la règle des trapèzes, avec arrêt sur
//     chaque point de rupture des sources linéaires par morceaux.
//
// Analyses : `.op`, `.tran`, `.dc` (source, résistance, température), `.ac`
// et `.noise`. Éléments : R, C, L, V, I, D, Q, M, S, B, F.
//
// Il reste plus modeste que ngspice — pas de pas de temps adaptatif sur
// l'erreur, pas de capacités de jonction, pas de modèle BSIM. Chaque
// résultat qu'il produit est en revanche confronté à ngspice dans les tests,
// et à la théorie quand elle donne la réponse.
#pragma once

#include <map>
#include <string>
#include <vector>

#include "core/analysis/Analyses.h"
#include "core/engines/ExpressionSpice.h"

namespace coeur {

struct Formes;   // défini dans NgspiceEngine.h

class SolveurIntegre {
public:
    SolveurIntegre();
    ~SolveurIntegre();

    // Lit un fichier de circuit SPICE. Renvoie faux et remplit `erreurs()`
    // si une carte est incompréhensible.
    bool charger(const std::string& deck);

    // Analyses. Chacune suppose `charger` réussi.
    bool point_repos();
    bool transitoire(Formes& formes);
    bool analyse(Balayage& balayage);

    const std::map<std::string, double>& tensions() const { return tensions_; }
    const std::map<std::string, double>& courants() const { return courants_; }
    const std::vector<std::string>& erreurs() const { return erreurs_; }

private:
    struct Impl;
    Impl* impl_;

    std::map<std::string, double> tensions_;
    std::map<std::string, double> courants_;
    std::vector<std::string> erreurs_;
};

}  // namespace coeur
