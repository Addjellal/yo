// Moteur analogique.
//
// Deux solveurs derrière la même façade, et le même fichier de circuit pour
// les deux :
//   * le SOLVEUR INTÉGRÉ, écrit dans ce projet — c'est celui qui sert par
//     défaut, et il ne demande rien à installer ;
//   * ngspice, le moteur SPICE libre de référence (celui qu'embarque KiCad),
//     utilisé s'il a été trouvé à la compilation ET réclamé explicitement.
//
// Avoir les deux n'est pas un luxe : c'est ce qui permet de confronter le
// solveur intégré à une référence sur les mêmes circuits, dans les tests.
//
// Contrainte de la bibliothèque : ngspice conserve un état global, il ne peut
// donc y avoir qu'un seul circuit chargé par processus. Cette classe encadre
// cette contrainte.
#pragma once

#include <map>
#include <string>
#include <vector>

#include "coeur/Netlist.h"
#include "coeur/analyses/Analyses.h"

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
    // Grandeurs INTERNES des composants à état : « SRV1.angle », « M1.tr_min ».
    //
    // Elles ne sortent pas du solveur électrique mais de `Modele::evoluer`,
    // qui tourne après chaque fenêtre. Une valeur par fenêtre, tenue jusqu'à
    // la suivante : c'est un échantillonnage bloqué, comme un signal discret
    // chez Simulink, et non une interpolation qu'on inventerait.
    std::map<std::string, std::vector<double>> grandeurs;

    void vider() {
        temps.clear();
        tensions.clear();
        courants.clear();
        grandeurs.clear();
    }
    bool vide() const { return temps.empty(); }
};

class NgspiceEngine {
public:
    NgspiceEngine();
    ~NgspiceEngine();

    static bool compile_avec_ngspice();
    // Le moteur est toujours disponible : sans ngspice, le solveur intégré
    // prend le relais.
    bool disponible() const { return true; }
    // Vrai si c'est ngspice qui calcule.
    bool utilise_ngspice() const { return disponible_ && prefere_ngspice_; }
    // Choisit le solveur. Sert aux tests, qui font tourner les deux sur le
    // même circuit et comparent.
    void preferer_ngspice(bool oui) { prefere_ngspice_ = oui; }

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

    // Analyse paramétrique : le circuit est celui du point de repos, seule la
    // directive change. « .dc V1 0 5 0.1 » trace une caractéristique de
    // transfert, « .ac dec 20 10 1meg » un diagramme de Bode. C'est ce que
    // font les commandes du même nom dans LTspice ou Multisim.
    std::string construire_analyse(const Netlist& netlist,
                                   const std::vector<BrocheElectrique>& broches,
                                   const std::string& directive);

    // Charge le circuit dans ngspice et lance une analyse au point de repos.
    bool resoudre();

    // Exécute l'analyse préparée par `construire_analyse` et range le résultat
    // dans `balayage()`. L'abscisse est reconnue au nom que ngspice lui donne
    // (« v-sweep », « res-sweep », « temp-sweep », « frequency »).
    bool resoudre_analyse();
    const Balayage& balayage() const { return balayage_; }

    // Lance l'analyse transitoire préparée par `construire_transitoire`.
    bool resoudre_transitoire();
    const Formes& formes() const { return formes_; }
    // Le même relevé, ouvert à l'écriture.
    //
    // Il ne sert qu'à une chose, et c'est assumé : y déposer les grandeurs
    // INTERNES des composants à état — angle d'un servomoteur, vitesse d'un
    // moteur —, calculées après le solveur par `Modele::evoluer`. Elles
    // appartiennent à la même fenêtre de temps que les tensions ; les porter
    // dans une structure séparée obligerait tout ce qui consomme un relevé à
    // en recevoir deux, et à les garder en phase.
    Formes& formes_modifiables() { return formes_; }

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
    bool disponible_ = false;      // ngspice présent à l'exécution
    bool prefere_ngspice_ = false;
    std::string source_;
    std::vector<std::string> lignes_;
    std::vector<std::string> erreurs_;
    std::map<std::string, double> tensions_;
    std::map<std::string, double> courants_;
    Formes formes_;
    Balayage balayage_;
    std::map<std::string, double> etat_initial_;
    std::map<std::string, double> etat_final_;

    // Broches vues comme des sources continues (point de repos, balayage).
    std::vector<std::string> sources_continues(
        const std::vector<BrocheElectrique>& broches) const;

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
