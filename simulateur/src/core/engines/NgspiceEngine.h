// Moteur analogique : enveloppe autour de la bibliothèque partagée ngspice.
//
// ngspice est le moteur SPICE libre de référence — c'est celui qu'embarque
// KiCad. Il apporte la vraie simulation analogique : diodes, transistors,
// amplificateurs, condensateurs, régime transitoire.
//
// Contrainte de la bibliothèque : ngspice conserve un état global, il ne peut
// donc y avoir qu'un seul circuit chargé par processus. Cette classe encadre
// cette contrainte.
#pragma once

#include <map>
#include <string>
#include <vector>

#include "core/Netlist.h"

namespace coeur {

// Une broche de microcontrôleur vue par le circuit : source de tension avec
// sa résistance interne (25 Ω sur un AVR), ou entrée haute impédance.
struct BrocheElectrique {
    std::string noeud;         // "D13", "A0"…
    enum class Mode { Entree, Sortie, PullUp } mode = Mode::Entree;
    double tension = 0.0;      // en mode Sortie
    double resistance = 25.0;
};

// Un changement de niveau daté sur une broche. C'est ce que produit le
// microcontrôleur, à la précision du cycle d'horloge.
struct TransitionBroche {
    double instant = 0.0;      // secondes depuis le début de la fenêtre
    std::string noeud;
    double tension = 0.0;
};

// Résultat d'une analyse transitoire : le film, et non plus la photo.
struct Formes {
    std::vector<double> temps;                            // en secondes
    std::map<std::string, std::vector<double>> tensions;  // par nœud
    std::map<std::string, std::vector<double>> courants;  // par référence

    void vider() {
        temps.clear();
        tensions.clear();
        courants.clear();
    }
    bool vide() const { return temps.empty(); }
};

class NgspiceEngine {
public:
    NgspiceEngine();
    ~NgspiceEngine();

    static bool compile_avec_ngspice();
    bool disponible() const { return disponible_; }

    // Construit le fichier SPICE à partir de la netlist et des broches.
    // Renvoie le texte généré (utile pour l'afficher et pour les tests).
    std::string construire(const Netlist& netlist,
                           const std::vector<BrocheElectrique>& broches);

    // Même chose, en analyse transitoire : les broches deviennent des sources
    // linéaires par morceaux décrivant leurs commutations datées. C'est ce qui
    // permet d'observer une forme d'onde, condensateurs compris.
    std::string construire_transitoire(
        const Netlist& netlist, const std::vector<BrocheElectrique>& broches,
        const std::vector<TransitionBroche>& transitions, double duree,
        double pas);

    // Charge le circuit dans ngspice et lance une analyse au point de repos.
    bool resoudre();

    // Lance l'analyse transitoire préparée par `construire_transitoire`.
    bool resoudre_transitoire();
    const Formes& formes() const { return formes_; }

    // Tensions au dernier instant calculé : elles servent de conditions
    // initiales à la fenêtre suivante, sans quoi un condensateur se
    // redéchargerait à chaque trame.
    const std::map<std::string, double>& etat_final() const { return etat_final_; }
    void definir_etat_initial(std::map<std::string, double> etat) {
        etat_initial_ = std::move(etat);
    }
    void oublier_etat() {
        etat_initial_.clear();
        etat_final_.clear();
    }

    double tension(const std::string& noeud) const;
    double courant(const std::string& reference) const;   // "R1", "LED1"…

    // Relevés complets de la dernière résolution (clés en minuscules).
    const std::map<std::string, double>& toutes_tensions() const {
        return tensions_;
    }
    const std::map<std::string, double>& tous_courants() const {
        return courants_;
    }

    const std::vector<std::string>& erreurs() const { return erreurs_; }
    const std::string& source() const { return source_; }

private:
    bool disponible_ = false;
    std::string source_;
    std::vector<std::string> lignes_;
    std::vector<std::string> erreurs_;
    std::map<std::string, double> tensions_;
    std::map<std::string, double> courants_;
    Formes formes_;
    std::map<std::string, double> etat_initial_;
    std::map<std::string, double> etat_final_;

    // Partie commune aux deux analyses : composants, directives, fuites.
    // `sources_broches` décrit les broches, en continu ou par morceaux.
    // `duree_fenetre` vaut 0 au point de repos ; en transitoire, elle permet
    // aux composants à état d'émettre une source datée.
    void emettre_corps(const Netlist& netlist,
                       const std::vector<std::string>& sources_broches,
                       double duree_fenetre);
    // Charge `lignes_` dans ngspice et exécute. Renvoie le nom du tracé.
    std::string executer();
};

}  // namespace coeur
