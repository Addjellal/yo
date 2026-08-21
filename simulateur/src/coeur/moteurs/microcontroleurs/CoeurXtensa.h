// Cœur Xtensa LX6 intégré : celui de l'ESP32.
//
// Troisième architecture, et la plus étrangère des trois. Ni l'AVR ni le
// Cortex-M ne lui ressemblent :
//
//   * les instructions font TROIS octets, pas deux ni quatre — et certaines
//     en font deux, quand l'option de densité est employée. Il faut donc lire
//     le premier octet pour savoir combien en lire ;
//   * les registres sont une fenêtre de seize glissant sur soixante-quatre.
//     Un appel de fonction fait tourner la fenêtre au lieu d'empiler ;
//   * les constantes de plus de douze bits ne s'écrivent pas dans
//     l'instruction : elles sont posées dans un bassin littéral, et lues par
//     L32R avec un décalage négatif. Un émulateur qui ignore cela ne charge
//     jamais la bonne adresse de périphérique.
//
// LE TEMPS, et ce qu'on peut honnêtement en dire.
//
// Contrairement à ARM, qui publie le coût de chaque instruction, le coût des
// instructions du LX6 n'est PAS publiquement documenté. Ce qui a été vérifié
// avant d'écrire ces lignes :
//
//   * la fiche technique de l'ESP32 (Espressif) décrit « a 7-stage pipeline
//     to support the clock frequency of up to 240 MHz » et ne donne aucun
//     nombre de cycles par instruction ;
//   * le manuel de l'architecture (Cadence/Tensilica) décrit les
//     verrouillages et les effets de pipeline de façon qualitative ; les
//     tables de temps vivent dans le Data Book du cœur, sous accord de
//     confidentialité.
//
// Ce qui est modélisé ici est donc la MÉCANIQUE, pas des chiffres relevés :
//
//   * une instruction ordinaire s'émet en un cycle ;
//   * un branchement pris recharge le pipeline. Le modèle facture deux
//     cycles de plus. ATTENTION : sur un pipeline de sept étages, la
//     pénalité réelle est vraisemblablement plus lourde — ce nombre est un
//     choix, pas une mesure ;
//   * un chargement met un cycle de plus à rendre son résultat : l'instruction
//     qui suit ATTEND si elle a besoin du registre chargé, et ne paie rien
//     sinon. C'est le verrouillage de charge, et l'ignorer rendrait une
//     boucle de recopie mémoire aussi rapide qu'une boucle de calcul.
//
// À la différence du cœur AVR (exact, confronté à simavr) et du cœur Cortex-M
// (exact, confronté aux tables publiées par ARM), CE CŒUR N'EST PAS EXACT AU
// CYCLE, et ne peut pas l'être à partir de sources publiques. Les durées
// qu'il rend sont du bon ordre de grandeur, et les rapports entre deux
// boucles sont respectés ; les valeurs absolues ne le sont pas.
//
// Pour l'obtenir, il faudrait chronométrer les séquences sur une vraie carte
// avec son compteur CCOUNT, et bâtir la table à partir des mesures.
//
// Ce qui est modélisé : le jeu d'instructions courant — celui que produit un
// compilateur pour du code qui pilote des registres —, la mémoire, et le
// bloc GPIO de l'ESP32.
//
// CE QUI NE L'EST PAS, et il faut le savoir avant de s'en servir : les deux
// cœurs (un seul est exécuté), la fenêtre de registres au-delà de CALL0, les
// coprocesseurs, la radio, et tout ce que FreeRTOS attend d'un ESP-IDF. Un
// programme qui pilote ses broches tourne ; un croquis Arduino-ESP32 complet
// ne tourne pas.
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

namespace coeur {

struct ProfilXtensa {
    const char* nom = "esp32";
    // Plages de mémoire : instruction, données, et la mémoire vive interne.
    struct Plage {
        uint32_t debut = 0;
        uint32_t taille = 0;
    };
    std::vector<Plage> memoires;
    // Le bloc GPIO, décrit par ses registres.
    uint32_t gpio_base = 0x3FF44000;
    uint32_t gpio_sortie = 0x004;
    uint32_t gpio_sortie_poser = 0x008;
    uint32_t gpio_sortie_effacer = 0x00C;
    uint32_t gpio_direction = 0x020;
    uint32_t gpio_direction_poser = 0x024;
    uint32_t gpio_direction_effacer = 0x028;
    uint32_t gpio_entree = 0x03C;
    uint32_t frequence = 240000000;
};

const ProfilXtensa& profil_esp32();
const ProfilXtensa* profil_xtensa_par_nom(const std::string& nom);

class CoeurXtensa {
public:
    CoeurXtensa();
    explicit CoeurXtensa(const ProfilXtensa& profil);

    void definir_profil(const ProfilXtensa& profil);
    bool charger(const std::string& chemin, std::string* erreur);
    // Charge un bloc d'instructions déjà assemblées, à l'adresse donnée.
    // C'est par là que passe la vérification quand aucune chaîne Xtensa n'est
    // installée : on écrit les octets, et l'on regarde ce que la machine en
    // fait.
    void charger_octets(uint32_t adresse, const std::vector<uint8_t>& octets);
    void reinitialiser();
    bool charge() const { return charge_; }

    uint64_t executer(uint64_t cycles);
    uint64_t cycles() const { return cycles_; }
    void definir_frequence(uint32_t hertz) { frequence_ = hertz; }
    uint32_t frequence() const { return frequence_; }
    void definir_point_entree(uint32_t adresse) { pc_ = adresse; }

    void broche_externe(int broche, bool haut);
    bool broche_en_sortie(int broche) const;
    bool broche_haute(int broche) const;

    std::function<void(int broche, bool haut)> sur_broche;

    uint32_t registre(int rang) const { return rang < 16 ? a_[rang] : 0; }

private:
    ProfilXtensa p_;
    struct Bloc {
        uint32_t debut = 0;
        std::vector<uint8_t> octets;
    };
    std::vector<Bloc> memoire_;

    uint32_t a_[16] = {};              // la fenêtre de registres courante
    uint32_t pc_ = 0;
    uint64_t cycles_ = 0;
    uint32_t frequence_ = 240000000;
    bool charge_ = false;
    bool arrete_ = false;
    // Verrouillage de charge : le registre qu'un chargement vient de viser,
    // et le nombre de cycles avant que sa valeur soit disponible.
    int registre_charge_ = -1;
    int attente_charge_ = 0;

    uint32_t gpio_sortie_ = 0, gpio_direction_ = 0, gpio_entree_ = 0;
    uint32_t gpio_connue_ = 0, gpio_connue_direction_ = 0;
    bool sorties_valides_ = false;

    uint8_t* trouver(uint32_t adresse, uint32_t longueur);
    const uint8_t* trouver(uint32_t adresse, uint32_t longueur) const;
    uint32_t lire32(uint32_t adresse) const;
    uint8_t lire8(uint32_t adresse) const;
    void ecrire32(uint32_t adresse, uint32_t valeur);
    void ecrire8(uint32_t adresse, uint8_t valeur);
    bool lire_peripherique(uint32_t adresse, uint32_t* valeur) const;
    bool ecrire_peripherique(uint32_t adresse, uint32_t valeur);
    void rafraichir_sorties();

    int instruction();
    // Le coût d'émission seul, sans le verrouillage de charge.
    int instruction_seule(uint32_t depart);
};

}  // namespace coeur
