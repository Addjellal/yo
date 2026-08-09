// Moteur microcontrôleur.
//
// C'est ici que se joue le réalisme « Proteus » : on n'interprète pas le
// programme, on **exécute le vrai firmware** compilé par avr-gcc, cycle par
// cycle, sur un cœur ATmega328P émulé.
//
// Deux cœurs derrière la même façade, comme pour l'analogique : celui écrit
// dans ce projet (`CoeurAvr`), qui sert par défaut et ne demande rien à
// installer, et **simavr** quand il a été trouvé à la compilation. Les tests
// font tourner les deux sur le même firmware et comparent.
#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <string>
#include <vector>
#include "core/engines/Microcontroleur.h"

namespace coeur {


class AvrEngine : public Microcontroleur {
public:
    AvrEngine();
    ~AvrEngine();
    AvrEngine(const AvrEngine&) = delete;
    AvrEngine& operator=(const AvrEngine&) = delete;

    static bool compile_avec_simavr();
    // Toujours disponible : sans simavr, le cœur intégré prend le relais.
    bool disponible() const override;
    bool utilise_simavr() const;
    void preferer_simavr(bool oui) { prefere_simavr_ = oui; }
    const char* nom_du_coeur() const override {
        return utilise_simavr() ? "simavr" : "cœur intégré";
    }
    // Les puces AVR que ce moteur sait exécuter.
    bool reconnait(const std::string& mcu) const override;

    // Charge un firmware .elf (ou .hex) et prépare le cœur.
    bool charger(const std::string& chemin_firmware,
                 const std::string& mcu = "atmega328p",
                 uint32_t frequence_hz = 16000000) override;

    // Exécute au plus `cycles` cycles d'horloge. Renvoie le nombre exécuté.
    uint64_t avancer(uint64_t cycles) override;

    void reinitialiser() override;

    // Compteur de cycles, lu en direct dans le cœur émulé. C'est important :
    // les rappels de broche sont appelés *pendant* avancer(), et doivent
    // pouvoir dater leur commutation à l'instant où elle se produit — pas à
    // la fin de la tranche d'exécution.
    uint64_t cycle() const override;
    double temps_ms() const override;
    uint32_t frequence() const override { return frequence_; }

    // État d'une broche Arduino (0..13 = PORTD/PORTB, 14..19 = PORTC/analogique)
    bool broche_haute(int broche) const;
    bool broche_en_sortie(int broche) const;

    // Lecture directe des registres du microcontrôleur : c'est la vérité de
    // la puce, pas une déduction. DDRx donne le sens, PORTx le niveau.
    uint8_t registre(uint16_t adresse) const;
    bool direction_sortie(int broche) const override;   // DDRx
    bool niveau_port(int broche) const override;        // PORTx (ou pull-up si entrée)
    bool pullup_actif(int broche) const override;
    // La voie du convertisseur derrière une broche, ou -1 si elle n'en a pas.
    // C'est la puce qui décide : A0 est la broche 14 d'un Uno et la 54 d'un
    // Mega.
    int canal_adc(int broche) const override;
    // Nom du microcontrôleur chargé (« atmega328p », « attiny85 »…).
    const std::string& mcu() const { return mcu_; }       // entrée + PORTx à 1

    // Impose au microcontrôleur le niveau que le circuit applique sur une
    // broche configurée en entrée (c'est le retour du monde analogique).
    void definir_niveau_externe(int broche, bool haut) override;

    // Impose la tension lue par l'ADC sur une entrée analogique (0..5 V).
    void definir_tension_adc(int canal, double volts) override;
    void definir_source_adc(
        std::function<double(int canal, uint64_t cycle)> source) override;

    // Notifications
    void sur_changement_broche(std::function<void(int, bool)> rappel) override {
        rappel_broche_ = std::move(rappel);
    }
    void sur_octet_serie(std::function<void(char)> rappel) override {
        rappel_serie_ = std::move(rappel);
    }
    void envoyer_octet_serie(uint8_t octet) override;

    const std::string& erreur() const override { return erreur_; }

    // Compile un croquis en firmware .elf, pour la puce et l'horloge de la
    // carte. Sur un ATmega328P, le noyau Arduino minimal est écrit à côté et
    // compilé avec : pinMode, digitalWrite, analogRead, millis, Serial…
    // fonctionnent donc comme sur une vraie carte, sans rien à installer.
    //
    // Les autres puces n'ont pas de noyau : un ATtiny85 n'a ni UART ni la
    // même carte de registres, et le noyau ne s'y compilerait même pas. Son
    // programme s'écrit sur les registres, et c'est compilé tel quel.
    static bool compiler_source(const std::string& source,
                                const std::string& chemin_elf,
                                std::string* journal,
                                const std::string& mcu = "atmega328p",
                                uint32_t frequence = 16000000);
    // Programme en plusieurs fichiers : tous sont déposés côte à côte, ceux
    // qui portent du code sont compilés, et le dossier est dans le chemin
    // d'inclusion.
    static bool compiler_projet(const Programme& fichiers,
                                const std::string& chemin_elf,
                                std::string* journal,
                                const std::string& mcu = "atmega328p",
                                uint32_t frequence = 16000000);
    static bool avr_gcc_disponible();
    static bool avr_gpp_disponible();

    // --- usage interne (appelé depuis les callbacks C de simavr)
    void _notifier_broche(int broche, bool haut);
    void _notifier_serie(char octet);

private:
    // Chemin simavr, compilé seulement quand la bibliothèque est là.
    bool charger_simavr(const std::string& chemin, const std::string& mcu,
                        uint32_t frequence);
    uint64_t avancer_simavr(uint64_t cycles);
    void reinitialiser_simavr();
    void adc_simavr(int canal, double volts);
    void serie_simavr(uint8_t octet);
    uint64_t cycle_simavr() const;
    uint8_t registre_simavr(uint16_t adresse) const;
    void niveau_simavr(int broche, bool haut);

    struct Impl;
    Impl* impl_ = nullptr;
    bool prefere_simavr_ = false;
    uint64_t cycle_ = 0;
    uint32_t frequence_ = 16000000;
    // La puce chargée : elle décide de la traduction broche -> port.
    std::string mcu_ = "atmega328p";
    std::string erreur_;
    std::function<void(int, bool)> rappel_broche_;
    std::function<void(char)> rappel_serie_;
    std::map<int, bool> etat_broches_;
    std::map<int, bool> sortie_broches_;
    bool injection_ = false;   // évite le rebouclage sur nos propres écritures
};

}  // namespace coeur
