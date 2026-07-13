// feu_tricolore.hpp — corrigé TD 02, exercice 4
// FSM encapsulée : l'état et son horodatage sont privés, transition()
// centralise tout changement d'état. Plusieurs feux indépendants possibles.
#ifndef FEU_TRICOLORE_HPP
#define FEU_TRICOLORE_HPP

#include <cstdint>

class FeuTricolore {
public:
    enum class Etat : std::uint8_t { Vert, Orange, Rouge };

    explicit FeuTricolore(std::uint32_t maintenant)
        : etat_(Etat::Rouge), t_entree_(maintenant) {}

    void appuiPieton() { demande_pieton_ = true; }
    Etat etat() const { return etat_; }

    void tick(std::uint32_t maintenant) {
        const std::uint32_t ecoule = maintenant - t_entree_;
        switch (etat_) {
        case Etat::Vert:
            if (ecoule >= DUREE_VERT ||
                (demande_pieton_ && ecoule >= VERT_MINI))
                transition(Etat::Orange, maintenant);
            break;
        case Etat::Orange:
            if (ecoule >= DUREE_ORANGE) {
                demande_pieton_ = false;          // demande servie
                transition(Etat::Rouge, maintenant);
            }
            break;
        case Etat::Rouge:
            if (ecoule >= DUREE_ROUGE)
                transition(Etat::Vert, maintenant);
            break;
        }
    }

private:
    void transition(Etat suivant, std::uint32_t maintenant) {
        etat_ = suivant;
        t_entree_ = maintenant;   // UN SEUL endroit où l'état change
    }

    static constexpr std::uint32_t DUREE_VERT   = 5000;
    static constexpr std::uint32_t DUREE_ORANGE = 1000;
    static constexpr std::uint32_t DUREE_ROUGE  = 5000;
    static constexpr std::uint32_t VERT_MINI    = 1000;

    Etat          etat_;
    std::uint32_t t_entree_;
    bool          demande_pieton_ = false;
};

#endif // FEU_TRICOLORE_HPP
