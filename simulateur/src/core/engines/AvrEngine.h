// Moteur microcontrôleur : enveloppe autour de simavr.
//
// C'est ici que se joue le réalisme « Proteus » : on n'interprète pas le
// programme, on **exécute le vrai firmware** compilé par avr-gcc, cycle par
// cycle, sur un cœur ATmega328P émulé. Les timers, l'UART, l'ADC et les
// interruptions sont ceux de la puce, pas une approximation.
#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <string>
#include <vector>

namespace coeur {

class AvrEngine {
public:
    AvrEngine();
    ~AvrEngine();
    AvrEngine(const AvrEngine&) = delete;
    AvrEngine& operator=(const AvrEngine&) = delete;

    static bool compile_avec_simavr();
    bool disponible() const;

    // Charge un firmware .elf (ou .hex) et prépare le cœur.
    bool charger(const std::string& chemin_firmware,
                 const std::string& mcu = "atmega328p",
                 uint32_t frequence_hz = 16000000);

    // Exécute au plus `cycles` cycles d'horloge. Renvoie le nombre exécuté.
    uint64_t avancer(uint64_t cycles);

    void reinitialiser();

    // Compteur de cycles, lu en direct dans le cœur émulé. C'est important :
    // les rappels de broche sont appelés *pendant* avancer(), et doivent
    // pouvoir dater leur commutation à l'instant où elle se produit — pas à
    // la fin de la tranche d'exécution.
    uint64_t cycle() const;
    double temps_ms() const;
    uint32_t frequence() const { return frequence_; }

    // État d'une broche Arduino (0..13 = PORTD/PORTB, 14..19 = PORTC/analogique)
    bool broche_haute(int broche) const;
    bool broche_en_sortie(int broche) const;

    // Lecture directe des registres du microcontrôleur : c'est la vérité de
    // la puce, pas une déduction. DDRx donne le sens, PORTx le niveau.
    uint8_t registre(uint16_t adresse) const;
    bool direction_sortie(int broche) const;   // DDRx
    bool niveau_port(int broche) const;        // PORTx (ou pull-up si entrée)
    bool pullup_actif(int broche) const;       // entrée + PORTx à 1

    // Impose au microcontrôleur le niveau que le circuit applique sur une
    // broche configurée en entrée (c'est le retour du monde analogique).
    void definir_niveau_externe(int broche, bool haut);

    // Impose la tension lue par l'ADC sur une entrée analogique (0..5 V).
    void definir_tension_adc(int canal, double volts);

    // Notifications
    void sur_changement_broche(std::function<void(int, bool)> rappel) {
        rappel_broche_ = std::move(rappel);
    }
    void sur_octet_serie(std::function<void(char)> rappel) {
        rappel_serie_ = std::move(rappel);
    }
    void envoyer_octet_serie(uint8_t octet);

    const std::string& erreur() const { return erreur_; }

    // Compile un croquis en firmware .elf. Le noyau Arduino minimal est
    // écrit à côté et compilé avec : pinMode, digitalWrite, analogRead,
    // millis, Serial… fonctionnent donc comme sur une vraie carte, sans que
    // l'utilisateur ait rien à installer.
    static bool compiler_source(const std::string& source,
                                const std::string& chemin_elf,
                                std::string* journal);
    static bool avr_gcc_disponible();
    static bool avr_gpp_disponible();

    // --- usage interne (appelé depuis les callbacks C de simavr)
    void _notifier_broche(int broche, bool haut);
    void _notifier_serie(char octet);

private:
    struct Impl;
    Impl* impl_ = nullptr;
    uint64_t cycle_ = 0;
    uint32_t frequence_ = 16000000;
    std::string erreur_;
    std::function<void(int, bool)> rappel_broche_;
    std::function<void(char)> rappel_serie_;
    std::map<int, bool> etat_broches_;
    std::map<int, bool> sortie_broches_;
    bool injection_ = false;   // évite le rebouclage sur nos propres écritures
};

}  // namespace coeur
