// Documents produits par le projet.
//
// Un atelier de CAO électronique ne sert pas qu'à regarder des courbes : il
// produit les pièces qui servent ensuite ailleurs. Ce fichier rassemble
// celles qui ont un format établi, en s'alignant sur ce qui existe :
//   * la NOMENCLATURE (BOM) — le tableau qu'on envoie au fournisseur ;
//   * le CONTRÔLE DES RÈGLES (ERC) — l'équivalent de « Electrical Rules
//     Check » de KiCad ou d'Altium, qui attrape les fautes de câblage avant
//     la simulation ;
//   * la NETLIST au format KiCad — celle que lit un logiciel de routage, donc
//     la porte de sortie vers le circuit imprimé ;
//   * les COURBES en CSV — ce que produit « Export data » de LTspice, pour
//     reprendre les relevés dans un tableur.
#pragma once

#include <string>
#include <vector>

#include "coeur/Netlist.h"
#include "coeur/moteurs/analogique/NgspiceEngine.h"

namespace coeur {

// --- nomenclature ---------------------------------------------------------
struct LigneNomenclature {
    std::string designation;              // "Résistance"
    std::string type;                     // "resistance"
    std::string valeur;                   // "220 Ω"
    std::string empreinte;                // "R_AXIAL_0207"
    std::vector<std::string> references;  // R1, R3, R7…

    int quantite() const { return static_cast<int>(references.size()); }
};

// Regroupe les composants identiques, comme le fait toute nomenclature :
// trois résistances de 220 Ω forment une ligne de quantité 3.
std::vector<LigneNomenclature> nomenclature(const Netlist& netlist);
std::string nomenclature_csv(const Netlist& netlist);

// Valeur d'une instance mise en forme avec son préfixe d'ingénieur
// (« 4.7 kΩ », « 100 nF »). Utilisée par la nomenclature et l'affichage.
std::string valeur_lisible(const Instance& instance);
std::string format_ingenieur(double valeur, const std::string& unite);

// --- contrôle des règles électriques (ERC) --------------------------------
struct Anomalie {
    enum class Gravite { Erreur, Avertissement, Information };
    Gravite gravite = Gravite::Avertissement;
    std::string reference;                // composant concerné, ou nœud
    std::string message;

    // Ce qu'il faut FAIRE, à l'impératif.
    //
    // Un diagnostic qui n'est pas actionnable ne vaut rien : les messages
    // disaient déjà très bien le quoi et le pourquoi — « source
    // court-circuitée : ses deux bornes sont sur le même nœud » — mais
    // laissaient l'élève devant sa propre ignorance du remède. Rust en a fait
    // une règle de conception, et le gain mesuré sur des débutants (Becker
    // 2016) porte sur le nombre d'erreurs, pas seulement sur le confort.
    //
    // Vide quand il n'y a rien d'utile à dire : mieux vaut se taire qu'écrire
    // une généralité.
    std::string remede;

    // La borne visée, quand l'anomalie en désigne une. Vide sinon.
    //
    // Le nom figure déjà dans le message — « borne « 2 » non connectée » —
    // mais l'y relire à l'expression régulière ferait dépendre le dessin du
    // schéma de la ponctuation d'une phrase française. Le jour où le message
    // change, le marqueur se poserait ailleurs, en silence.
    std::string borne;
};

std::vector<Anomalie> controler_regles(const Netlist& netlist);
std::string rapport_regles(const Netlist& netlist);

// --- exports --------------------------------------------------------------
// Netlist au format KiCad (« (export (version D) … »), lisible par pcbnew.
std::string netlist_kicad(const Netlist& netlist);

// Relevés d'une analyse transitoire, une colonne par signal.
std::string courbes_csv(const Formes& formes);

// Relevés d'un balayage (continu ou fréquentiel). En alternatif, chaque
// courbe donne deux colonnes : module et phase.
std::string balayage_csv(const Balayage& balayage);

}  // namespace coeur
