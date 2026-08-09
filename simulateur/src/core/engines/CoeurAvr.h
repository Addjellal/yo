// Cœur ATmega328P intégré : le firmware s'exécute sans simavr.
//
// Même raison que pour le solveur analogique : simavr n'existe en paquet
// nulle part sous Windows, et un projet qui demande de compiler soi-même une
// bibliothèque C avant de pouvoir cliquer sur « Lancer » ne se construit pas.
//
// Ce n'est pas un interpréteur de croquis : c'est bien le VRAI firmware
// compilé par avr-gcc qui est exécuté, instruction par instruction, sur un
// cœur AVR5 avec sa mémoire, sa pile, ses drapeaux, ses interruptions et ses
// périphériques. Un `.elf` produit par l'IDE Arduino s'y charge tel quel.
//
// Ce qui est modélisé : le jeu d'instructions AVR5 complet, les trois
// compteurs (débordement, comparaison, PWM rapide 8 bits — les modes dont
// `analogWrite` se sert), le convertisseur analogique-numérique, l'UART en
// émission et en réception, les ports B, C et D, et le vecteur
// d'interruptions.
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

namespace coeur {


// Description d'une puce.
//
// Le cœur exécute le même jeu d'instructions pour toute la famille AVR 8
// bits ; ce qui change d'une puce à l'autre est la carte de ses registres,
// la taille de sa mémoire, et la façon dont son tableau de vecteurs est
// disposé. Tout cela est décrit ici, en données, plutôt que gravé dans le
// code — c'est ce qui permet d'ajouter une puce sans toucher à l'exécution.
struct ProfilAvr {
    // Un registre absent de la puce porte cette adresse : toute lecture ou
    // écriture le concernant est alors sans effet.
    static constexpr uint16_t kAbsent = 0xFFFF;

    const char* nom = "atmega328p";
    uint16_t fin_ram = 0x08FF;
    // Taille de la mémoire de programme, en mots de seize bits. La fixer trop
    // court ne provoque aucune erreur : le code qui dépasse est simplement
    // absent, et le programme saute dans le vide au premier appel qui s'y
    // rendait.
    uint32_t flash_mots = 16384;           // 32 Ko
    // Les vecteurs d'interruption occupent deux mots sur les grosses puces
    // (JMP) et un seul sur les petites (RJMP).
    int mots_par_vecteur = 2;

    // Les ports, dans l'ordre où la puce les nomme. La lettre compte : sur un
    // ATmega328P le premier port est B, sur un ATmega2560 c'est A. Un rang
    // sans lettre serait un piège — c'est par la lettre que le circuit et le
    // firmware se désignent la même broche.
    static constexpr int kMaxPorts = 11;
    int nb_ports = 3;
    char lettre[kMaxPorts] = {'B', 'C', 'D'};
    uint16_t pin[kMaxPorts] = {0x23, 0x26, 0x29};
    uint16_t ddr[kMaxPorts] = {0x24, 0x27, 0x2A};
    uint16_t port[kMaxPorts] = {0x25, 0x28, 0x2B};

    uint16_t spl = 0x5D, sph = 0x5E, sreg = 0x5F;
    // Les puces de plus de 128 Ko de programme empilent leurs adresses de
    // retour sur trois octets et non deux, et se servent de EIND et de RAMPZ
    // pour atteindre la moitié haute de leur flash. En dépiler deux là où la
    // puce en a empilé trois fait revenir n'importe où : c'est la panne la
    // plus déroutante qui soit, car elle ne se manifeste qu'au premier
    // retour de fonction.
    int octets_adresse_retour = 2;
    uint16_t rampz = kAbsent, eind = kAbsent;

    uint16_t adcl = 0x78, adch = 0x79, adcsra = 0x7A, admux = 0x7C;
    // Les puces à plus de huit voies logent le bit de poids fort du sélecteur
    // dans un autre registre : sans lui, A8 lirait la tension de A0.
    uint16_t adcsrb = kAbsent;
    bool mux5 = false;
    int canaux_adc = 8;

    // Liaison série : absente sur les puces qui n'en ont pas.
    uint16_t ucsra = 0xC0, ucsrb = 0xC1, udr = 0xC6;
    int vecteur_usart_rx = 18;

    // Un compteur, avec ses registres, ses drapeaux et sa sortie de
    // comparaison. `present` distingue un compteur absent d'un compteur à
    // l'arrêt.
    struct ProfilCompteur {
        bool present = false;
        uint16_t controle_a = kAbsent, controle_b = kAbsent;
        uint16_t compte = kAbsent, compte_haut = kAbsent;
        uint16_t compare_a = kAbsent, compare_b = kAbsent, sommet = kAbsent;
        uint16_t drapeaux = kAbsent, masques = kAbsent;
        // Positions des drapeaux dans TIFR — et, aux mêmes places, des
        // autorisations dans TIMSK.
        uint8_t bit_tov = 0x01, bit_ocfa = 0x02, bit_ocfb = 0x04;
        int vecteur_ovf = 0, vecteur_compa = 0, vecteur_compb = 0;
        // Prédiviseur : 0 le tableau ordinaire, 1 celui du compteur 2 de
        // l'ATmega, 2 celui sur quatre bits du compteur 1 de l'ATtiny.
        int prediviseur = 0;
        // Sorties de comparaison : où aboutissent OCxA et OCxB.
        int port_a = -1, bit_a = 0, port_b = -1, bit_b = 0;
    };
    static constexpr int kMaxCompteurs = 6;
    int nb_compteurs = 3;
    ProfilCompteur compteurs[kMaxCompteurs];
};

// Les puces connues. `profil_par_nom` rend nullptr pour une puce inconnue.
const ProfilAvr& profil_atmega328p();
const ProfilAvr& profil_attiny85();
const ProfilAvr& profil_atmega2560();
const ProfilAvr* profil_par_nom(const std::string& nom);

class CoeurAvr {
public:
    CoeurAvr();
    explicit CoeurAvr(const ProfilAvr& profil);

    // Change de puce. Remet tout à zéro : la mémoire n'a pas la même taille
    // et les registres ne sont pas aux mêmes adresses.
    void definir_profil(const ProfilAvr& profil);
    const ProfilAvr& profil() const { return p_; }

    // Charge un firmware ELF ou Intel HEX. `erreur` est renseigné en cas
    // d'échec.
    bool charger(const std::string& chemin, std::string* erreur);
    void reinitialiser();
    void definir_frequence(uint32_t hertz) { frequence_ = hertz; }
    uint32_t frequence() const { return frequence_; }

    // Exécute au plus `cycles` cycles d'horloge ; renvoie le nombre exécuté.
    uint64_t executer(uint64_t cycles);
    uint64_t cycles() const { return cycles_; }

    // Lecture de l'espace données (registres, E/S, SRAM).
    uint8_t lire_donnee(uint16_t adresse) const;

    // Niveau imposé de l'extérieur sur une broche configurée en entrée.
    void broche_externe(char port, int bit, bool haut);
    // Tension présentée au convertisseur, en volts.
    void tension_adc(int canal, double volts);
    // Octet reçu sur la liaison série.
    void recevoir_serie(uint8_t octet);

    // Notifications : niveau de sortie d'une broche, octet émis sur l'UART.
    std::function<void(char port, int bit, bool haut)> sur_broche;
    std::function<void(uint8_t)> sur_serie;

    bool charge() const { return !flash_.empty(); }

private:
    ProfilAvr p_;

    // --- mémoire
    std::vector<uint16_t> flash_;          // en mots de 16 bits
    std::vector<uint8_t> donnees_;         // 0x0000..0x08FF
    uint32_t pc_ = 0;                      // en mots
    uint64_t cycles_ = 0;
    uint32_t frequence_ = 16000000;
    bool endormi_ = false;

    // --- état des ports vu de l'extérieur
    uint8_t entree_[ProfilAvr::kMaxPorts] = {};   // niveaux imposés par le circuit
    uint8_t sortie_connue_[ProfilAvr::kMaxPorts] = {};  // dernier niveau notifié
    uint8_t direction_connue_[ProfilAvr::kMaxPorts] = {};
    bool sortie_valide_ = false;

    // --- convertisseur
    uint16_t adc_[16] = {};
    int adc_restant_ = 0;                  // cycles avant fin de conversion

    // --- liaison série
    uint8_t serie_recue_ = 0;
    bool serie_disponible_ = false;

    // --- compteurs
    struct Compteur {
        uint16_t compte = 0;
        int diviseur = 0;                  // cycles par pas ; 0 = arrêté
        int reste = 0;
    };
    Compteur compteurs_[ProfilAvr::kMaxCompteurs];

    // --- accès mémoire
    uint8_t lire(uint16_t adresse);
    void ecrire(uint16_t adresse, uint8_t valeur);
    uint8_t& octet(uint16_t adresse) { return donnees_[adresse]; }
    uint8_t reg(int rang) const { return donnees_[rang]; }
    void poser_reg(int rang, uint8_t valeur) { donnees_[rang] = valeur; }
    uint16_t lire_paire(int rang) const {
        return static_cast<uint16_t>(donnees_[rang])
               | (static_cast<uint16_t>(donnees_[rang + 1]) << 8);
    }
    void poser_paire(int rang, uint16_t valeur) {
        donnees_[rang] = static_cast<uint8_t>(valeur);
        donnees_[rang + 1] = static_cast<uint8_t>(valeur >> 8);
    }

    // Empile ou dépile une adresse de retour, sur deux ou trois octets selon
    // la puce.
    void empiler_retour(uint32_t adresse);
    uint32_t depiler_retour();
    // Rang du port portant cette lettre, ou -1.
    int rang_du_port(char lettre) const;

    uint16_t pile() const;
    void poser_pile(uint16_t valeur);
    void empiler(uint8_t valeur);
    uint8_t depiler();

    // --- drapeaux
    uint8_t& sreg() { return donnees_[0x5F]; }
    bool drapeau(int bit) const { return (donnees_[0x5F] >> bit) & 1; }
    void poser_drapeau(int bit, bool actif);

    // --- exécution
    int instruction();                     // exécute une instruction, rend ses cycles
    void avancer_peripheriques(int cycles);
    void avancer_compteur(Compteur& compteur, int cycles, int numero);
    // Une source d'interruption : son drapeau, son autorisation, son vecteur.
    struct Source {
        uint16_t drapeaux, masques;
        uint8_t bit;
        int vecteur;
    };
    std::vector<Source> sources_;          // rangées par priorité
    void ranger_interruptions();
    bool servir_interruption();
    void declencher(int vecteur);

    // --- entrées/sorties
    void rafraichir_sorties();
    uint8_t niveau_broches(int port) const;
    int port_de_pin(uint16_t adresse) const;
    bool touche_les_sorties(uint16_t adresse) const;
    void demarrer_conversion();
};

}  // namespace coeur
