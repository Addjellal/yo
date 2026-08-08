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

class CoeurAvr {
public:
    CoeurAvr();

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
    // --- mémoire
    std::vector<uint16_t> flash_;          // en mots de 16 bits
    std::vector<uint8_t> donnees_;         // 0x0000..0x08FF
    uint32_t pc_ = 0;                      // en mots
    uint64_t cycles_ = 0;
    uint32_t frequence_ = 16000000;
    bool endormi_ = false;

    // --- état des ports vu de l'extérieur
    uint8_t entree_[3] = {0, 0, 0};        // niveaux imposés par le circuit
    uint8_t sortie_connue_[3] = {0, 0, 0}; // dernier niveau notifié
    uint8_t direction_connue_[3] = {0, 0, 0};
    bool sortie_valide_ = false;

    // --- convertisseur
    uint16_t adc_[8] = {0, 0, 0, 0, 0, 0, 0, 0};
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
    Compteur t0_, t1_, t2_;

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
    bool servir_interruption();
    void declencher(int vecteur);

    // --- entrées/sorties
    void rafraichir_sorties();
    uint8_t niveau_broches(int port) const;
    void demarrer_conversion();
};

}  // namespace coeur
