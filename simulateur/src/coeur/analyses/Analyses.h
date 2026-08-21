// Analyses — ce qu'un atelier de simulation complet sait produire au-delà de
// la simple observation d'une forme d'onde.
//
// Trois familles, comme dans LTspice, Multisim ou Proteus :
//   * le BALAYAGE      : on fait varier une grandeur (une source, une
//                        résistance, la température) et on relève le circuit
//                        à chaque pas — c'est la caractéristique de transfert ;
//   * le FRÉQUENTIEL   : on relève le gain et la phase en fonction de la
//                        fréquence — c'est le diagramme de Bode ;
//   * le SPECTRE       : on décompose un signal en harmoniques et on en tire
//                        le taux de distorsion — c'est l'analyseur de spectre.
//
// Les deux premières viennent de ngspice (.dc et .ac). La troisième est
// calculée ici, à partir des points de l'analyse transitoire : elle est donc
// vérifiable sans ngspice, et l'est effectivement contre des signaux dont on
// connaît le spectre par la théorie.
#pragma once

#include <string>
#include <vector>

namespace coeur {

// --- résultat d'un balayage (continu ou fréquentiel) ----------------------
struct Courbe {
    std::string nom;                  // "out", "I(R1)"
    std::vector<double> valeurs;      // valeur relevée, ou module en alternatif
    std::vector<double> phases;       // en degrés ; vide en continu

    bool complexe() const { return !phases.empty(); }
};

struct Balayage {
    std::string grandeur;             // "V(V1)", "Fréquence"…
    std::string unite;                // "V", "Hz", "Ω", "°C"
    std::vector<double> abscisse;
    std::vector<Courbe> courbes;
    bool logarithmique = false;       // abscisse en décades (analyse .ac)

    bool vide() const { return abscisse.empty(); }
    const Courbe* courbe(const std::string& nom) const;
    void vider() {
        grandeur.clear();
        unite.clear();
        abscisse.clear();
        courbes.clear();
        logarithmique = false;
    }
};

// --- lecture d'un diagramme de Bode ---------------------------------------
// Gain en décibels d'une courbe complexe, rapporté à une entrée. Si `entree`
// est nul, le module est pris tel quel (l'entrée vaut alors 1 par convention
// de l'analyse alternative).
std::vector<double> gain_decibels(const Courbe& sortie,
                                  const Courbe* entree = nullptr);

// Fréquence de coupure à −3 dB par rapport au gain maximal, par interpolation
// entre deux points. Renvoie 0 si la courbe ne redescend jamais de 3 dB.
double frequence_coupure(const Balayage& balayage, const Courbe& sortie,
                         const Courbe* entree = nullptr);

// Gain maximal en décibels, et la fréquence à laquelle il est atteint.
double gain_maximal(const Courbe& sortie, const Courbe* entree = nullptr);

// --- mesures sur une forme d'onde -----------------------------------------
// Ce que donne le bandeau de mesures d'un oscilloscope de laboratoire.
struct Mesures {
    bool valide = false;
    double minimum = 0, maximum = 0;
    double moyenne = 0;               // composante continue
    double efficace = 0;              // valeur efficace (RMS) totale
    double crete_a_crete = 0;
    double frequence = 0;             // 0 si le signal n'est pas périodique
    double rapport_cyclique = 0;      // en %, sur le niveau médian
    double temps_montee = 0;          // 10 % → 90 %, en secondes
    double depassement = 0;           // en % du palier haut
};

Mesures mesurer(const std::vector<double>& temps,
                const std::vector<double>& valeurs);

// --- spectre et distorsion -------------------------------------------------
struct RaieSpectre {
    int rang = 1;                     // 1 = fondamentale
    double frequence = 0;
    double amplitude = 0;             // amplitude crête de l'harmonique
    double amplitude_relative = 0;    // en % de la fondamentale
};

struct Spectre {
    bool valide = false;
    double continu = 0;               // composante continue
    double fondamentale = 0;          // fréquence, en hertz
    double efficace = 0;              // valeur efficace de la partie variable
    double thd = 0;                   // taux de distorsion harmonique, en %
    std::vector<RaieSpectre> raies;
};

// Décompose un signal échantillonné (pas forcément régulier : les points
// d'une analyse transitoire ne le sont jamais tout à fait) en harmoniques.
// `frequence_imposee` court-circuite la détection automatique quand on connaît
// déjà la fondamentale.
Spectre analyser_spectre(const std::vector<double>& temps,
                         const std::vector<double>& valeurs,
                         int harmoniques = 9,
                         double frequence_imposee = 0.0);

}  // namespace coeur
