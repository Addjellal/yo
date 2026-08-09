// Cœur Cortex-M intégré : les puces ARM 32 bits, exécutées instruction par
// instruction.
//
// Rien ici n'est repris du cœur AVR, et c'est le fait notable : ce n'est pas
// un gros AVR, c'est une autre machine. Seize registres au lieu de trente-deux,
// une mémoire plate au lieu de deux espaces séparés, des instructions de
// seize bits (Thumb) parfois prolongées par un second demi-mot, et un
// compteur d'instructions qui est lui-même un registre ordinaire — écrire
// dans r15 est un branchement.
//
// Deux jeux d'instructions sont reconnus :
//
//   * ARMv6-M (Thumb-1), celui du Cortex-M0+ — donc du RP2040 de la carte
//     Raspberry Pi Pico. C'est le plus petit jeu complet qui existe : une
//     soixantaine d'instructions, toutes de seize bits sauf BL.
//   * ARMv7-M (Thumb-2), celui des Cortex-M3 et M4 — donc des STM32. C'est un
//     sur-ensemble du précédent : les mêmes instructions, plus celles de
//     trente-deux bits. D'où l'ordre dans lequel ces deux familles ont été
//     écrites : la seconde ne fait qu'ajouter des formes à la première.
//
// Ce qui est modélisé du matériel autour : la mémoire (flash et SRAM), le
// compteur SysTick — celui dont se sert toute temporisation —, les ports
// d'entrée-sortie de la puce, et le vecteur d'interruptions. Les
// périphériques propres à chaque puce sont décrits en données, comme pour
// l'AVR, dans ProfilCortex.
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

namespace coeur {

// Une plage de mémoire de la puce.
struct PlageMemoire {
    uint32_t debut = 0;
    uint32_t taille = 0;
    bool inscriptible = true;
};

// Un port d'entrée-sortie, tel que le simulateur a besoin de le voir : un
// registre de direction, un registre de sortie, un registre d'entrée. Sur un
// RP2040 ce sont ceux du bloc SIO ; sur un STM32 ceux du bloc GPIO. Les
// adresses changent, la mécanique non.
struct ProfilPort {
    char nom = 'A';
    uint32_t base = 0;
    // Étendue du bloc. Elle compte : les ports d'un STM32 ne sont espacés que
    // de 0x400, et une fenêtre trop large ferait attribuer les registres du
    // port C au port A — le firmware piloterait alors la bonne broche d'un
    // port, et le simulateur en montrerait une autre.
    uint32_t taille = 0x1000;
    // Décalages, depuis `base`, des registres qu'on doit comprendre.
    uint32_t direction = 0;      // ce qui décide entrée ou sortie
    uint32_t sortie = 0;
    uint32_t entree = 0;
    // Registres « poser », « effacer » et « inverser » : les ARM en ont
    // presque tous, et un firmware ne pilote une broche qu'à travers eux.
    uint32_t sortie_poser = 0xFFFFFFFF;
    uint32_t sortie_effacer = 0xFFFFFFFF;
    uint32_t sortie_inverser = 0xFFFFFFFF;
    uint32_t direction_poser = 0xFFFFFFFF;
    uint32_t direction_effacer = 0xFFFFFFFF;
    // Certaines familles ne décrivent pas la direction par un bit mais par un
    // quartet : sur un STM32F1, chaque broche a quatre bits de configuration,
    // et elle est en sortie dès que ses deux bits de mode ne sont pas nuls.
    // Il faut alors deux registres pour seize broches.
    bool direction_par_quartets = false;
    uint32_t direction_haute = 0xFFFFFFFF;
    int premiere_broche = 0;     // numéro de la première broche de ce port
    int nb_broches = 32;
};

// Le bloc de contrôle des broches : c'est là que vivent les tirages internes.
// Sans eux, un bouton câblé à la masse laisse une entrée flottante, et le
// simulateur montre un niveau qui n'a aucun sens — le pire des deux mondes,
// puisqu'il a l'air de fonctionner.
struct ProfilTirages {
    uint32_t base = 0;              // 0 : bloc absent
    uint32_t premier = 0;           // décalage du registre de la broche 0
    uint32_t pas = 4;               // écart entre deux broches
    int bit_haut = 3;               // bit du tirage vers le haut
    int bit_bas = 2;
};

// Le convertisseur analogique-numérique, réduit à ce qu'un programme en fait :
// choisir une voie, lancer une conversion, lire le résultat.
struct ProfilAdc {
    uint32_t base = 0;              // 0 : convertisseur absent
    uint32_t controle = 0;          // décalage du registre de commande
    uint32_t resultat = 0;
    uint32_t selection = 0;         // registre du sélecteur de voie
    int bit_demarrer = 2;
    int bit_pret = 8;
    int decalage_voie = 12;         // position du sélecteur dans son registre
    uint32_t masque_voie = 0x7;
    int bits = 12;                  // résolution
    double reference = 3.3;         // pleine échelle, en volts
    int voies = 4;
};

struct ProfilCortex {
    const char* nom = "rp2040";
    // Jeu d'instructions : 6 pour ARMv6-M (Cortex-M0+), 7 pour ARMv7-M.
    int architecture = 6;
    std::vector<PlageMemoire> memoires;
    std::vector<ProfilPort> ports;
    // Adresse du bloc SysTick. 0 s'il n'y en a pas.
    uint32_t systick = 0xE000E010;
    // Où le processeur va chercher sa pile et son point d'entrée au réveil.
    uint32_t table_vecteurs = 0x00000000;
    uint32_t frequence = 125000000;
    ProfilTirages tirages;
    ProfilAdc adc;
};

const ProfilCortex& profil_rp2040();
const ProfilCortex& profil_stm32f103();
const ProfilCortex* profil_cortex_par_nom(const std::string& nom);

class CoeurCortexM {
public:
    CoeurCortexM();
    explicit CoeurCortexM(const ProfilCortex& profil);

    void definir_profil(const ProfilCortex& profil);
    const ProfilCortex& profil() const { return p_; }

    bool charger(const std::string& chemin, std::string* erreur);
    void reinitialiser();
    bool charge() const { return !memoire_.empty(); }

    uint64_t executer(uint64_t cycles);
    uint64_t cycles() const { return cycles_; }
    void definir_frequence(uint32_t hertz) { frequence_ = hertz; }
    uint32_t frequence() const { return frequence_; }

    // Niveau imposé de l'extérieur sur une broche configurée en entrée.
    void broche_externe(int broche, bool haut);
    // Le firmware a-t-il armé le tirage interne de cette broche ? Le circuit
    // en a besoin : c'est une résistance de plusieurs dizaines de kilohms
    // vers l'alimentation, et elle change le point de fonctionnement.
    bool broche_tiree_haut(int broche) const;
    // Tension présentée à une voie du convertisseur.
    void tension_adc(int voie, double volts);
    // État d'une broche, vu du circuit.
    bool broche_en_sortie(int broche) const;
    bool broche_haute(int broche) const;

    std::function<void(int broche, bool haut)> sur_broche;
    // Ce que le firmware écrit sur sa liaison série, quand elle est modélisée.
    std::function<void(uint8_t)> sur_serie;

    // Lecture d'un mot, pour les tests et le diagnostic.
    uint32_t lire_mot(uint32_t adresse) const;

private:
    ProfilCortex p_;

    // La mémoire est découpée en plages, chacune un bloc contigu. Une
    // adresse hors de toute plage est un accès à un périphérique.
    struct Bloc {
        uint32_t debut = 0;
        bool inscriptible = true;
        std::vector<uint8_t> octets;
    };
    std::vector<Bloc> memoire_;

    uint32_t r_[16] = {};              // r13 = pile, r14 = lien, r15 = pc
    bool n_ = false, z_ = false, c_ = false, v_ = false;
    uint64_t cycles_ = 0;
    uint32_t frequence_ = 125000000;
    bool endormi_ = false;

    // État des ports, tel que le circuit le voit.
    struct EtatPort {
        uint32_t direction = 0;
        uint32_t sortie = 0;
        uint32_t entree = 0;
        uint32_t connue_sortie = 0;
        uint32_t connue_direction = 0;
        uint32_t config_basse = 0;
        uint32_t config_haute = 0;
    };
    std::vector<EtatPort> ports_;
    bool sorties_valides_ = false;

    // SysTick : le compteur décroissant que toute temporisation emploie.
    uint32_t systick_charge_ = 0, systick_valeur_ = 0, systick_controle_ = 0;

    // Le bloc de contrôle des broches, tel que le firmware l'a écrit.
    std::vector<uint32_t> tirages_;
    // Le convertisseur : ce qu'on lui présente, et où il en est.
    std::vector<uint16_t> adc_;
    uint32_t adc_controle_ = 0;
    uint32_t adc_selection_ = 0;

    uint32_t lire32(uint32_t adresse) const;
    uint16_t lire16(uint32_t adresse) const;
    uint8_t lire8(uint32_t adresse) const;
    void ecrire32(uint32_t adresse, uint32_t valeur);
    void ecrire16(uint32_t adresse, uint16_t valeur);
    void ecrire8(uint32_t adresse, uint8_t valeur);
    // Accès aux périphériques : rend true si l'adresse en relève.
    bool lire_peripherique(uint32_t adresse, uint32_t* valeur) const;
    bool ecrire_peripherique(uint32_t adresse, uint32_t valeur);

    uint8_t* trouver(uint32_t adresse, uint32_t longueur);
    const uint8_t* trouver(uint32_t adresse, uint32_t longueur) const;

    int instruction();
    // Les instructions de trente-deux bits, propres à l'ARMv7-M. Un
    // Cortex-M0+ n'en connaît qu'une, BL ; un Cortex-M3 en emploie
    // constamment, et les ignorer ne fait pas échouer le programme : il part
    // à la dérive en silence, avec des registres restés à zéro.
    int instruction32(uint16_t premier, uint16_t second);
    void poser_drapeaux_logiques(uint32_t resultat);
    void poser_drapeaux_addition(uint32_t a, uint32_t b, uint32_t retenue);
    void poser_drapeaux_soustraction(uint32_t a, uint32_t b);
    bool condition(int code) const;
    void brancher(uint32_t adresse);
    void rafraichir_sorties();
    void avancer_peripheriques(int cycles);
};

}  // namespace coeur
