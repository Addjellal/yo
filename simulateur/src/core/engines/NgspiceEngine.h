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

    // Charge le circuit dans ngspice et lance une analyse au point de repos.
    bool resoudre();

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
};

}  // namespace coeur
