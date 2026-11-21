// Aleatoire.h — le générateur de MATLAB : Mersenne Twister et ziggurat.
//
// rng(0) puis rand doit rendre 0.8147, comme MATLAB, et randn 0.5377 :
// sans cela, un programme qui fixe sa graine pour être reproductible ne
// reproduit rien d'une plateforme à l'autre. MATLAB emploie le MT19937
// de Matsumoto et Nishimura (32 bits), initialisé par init_genrand — la
// graine 0 valant 5489, la graine de référence —, et forme ses doubles
// sur 53 bits comme genrand_res53. randn suit le ziggurat de Marsaglia et
// Tsang à 256 bandes : un double u, l'octet de poids fort du second mot
// pour la bande i, et x = (2u - 1) X(i) accepté s'il tombe dans le
// rectangle de la bande. Les dix premières valeurs de randn après rng(0)
// que donne la documentation de MATLAB sont retrouvées par ce chemin ; le
// rare rejet (un tirage sur cent) suit Marsaglia et Tsang, et peut
// différer de MATLAB, qui n'en publie pas le détail.
//
// La classe est aussi un générateur au sens de la bibliothèque standard :
// les lois de <random> s'en servent.
#pragma once

#include <array>
#include <cstdint>

namespace matlibre {

class GenerateurMatlab {
public:
    using result_type = std::uint32_t;
    static constexpr result_type min() { return 0; }
    static constexpr result_type max() { return 0xFFFFFFFFu; }

    explicit GenerateurMatlab(std::uint32_t graine = 0) { initialiser(graine); }

    // La graine de MATLAB : 0 vaut la graine de référence, 5489.
    void initialiser(std::uint32_t graine);
    result_type operator()();
    // Un double de (0,1), sur 53 bits : ce que rend rand.
    double uniforme();
    // Une valeur normale centrée réduite : ce que rend randn.
    double normale();

    // L'état, comme le champ State de rng : 624 mots puis l'indice.
    std::array<std::uint32_t, 625> etat() const;
    void restaurer(const std::array<std::uint32_t, 625>& etat);

private:
    std::array<std::uint32_t, 624> mt_{};
    int indice_ = 624;
};

}  // namespace matlibre
