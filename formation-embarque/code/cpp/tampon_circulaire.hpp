// tampon_circulaire.hpp — corrigé TD 02, exercice 1
// Tampon circulaire générique, stockage statique, dimension vérifiée à la
// compilation. Abstraction "zero-cost" : chaque instanciation génère un
// code spécialisé, sans indirection.
#ifndef TAMPON_CIRCULAIRE_HPP
#define TAMPON_CIRCULAIRE_HPP

#include <cstddef>

template <typename T, std::size_t N>
class TamponCirculaire {
    static_assert(N >= 2, "taille minimale : 2");
    static_assert((N & (N - 1)) == 0, "N doit etre une puissance de 2");

public:
    bool put(const T& valeur) {
        if (plein()) return false;
        donnees_[tete_] = valeur;
        tete_ = (tete_ + 1) & MASQUE;
        return true;
    }

    bool get(T& valeur) {
        if (vide()) return false;
        valeur = donnees_[queue_];
        queue_ = (queue_ + 1) & MASQUE;
        return true;
    }

    bool vide()  const { return tete_ == queue_; }
    bool plein() const { return ((tete_ + 1) & MASQUE) == queue_; }

    std::size_t taille() const {          // éléments présents
        return (tete_ - queue_) & MASQUE;
    }

private:
    static constexpr std::size_t MASQUE = N - 1;
    T donnees_[N] {};                     // stockage statique : zéro allocation
    volatile std::size_t tete_  = 0;      // volatile : usage ISR/main visé
    volatile std::size_t queue_ = 0;
};

#endif // TAMPON_CIRCULAIRE_HPP
