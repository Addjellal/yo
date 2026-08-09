// Un microcontrôleur, vu par le reste du simulateur.
//
// Jusqu'ici le couplage électrique parlait directement à un AvrEngine. Six
// cartes plus tard, cela tenait encore — elles portaient toutes un AVR. Il
// n'en va plus de même dès qu'on veut exécuter un Cortex-M ou un Xtensa : ce
// ne sont pas de gros AVR, ce sont d'autres machines, avec un autre jeu
// d'instructions et d'autres périphériques.
//
// D'où cette interface. Elle dit exactement ce que le simulateur attend d'une
// puce, et rien de plus :
//
//   * charger un firmware et le remettre à zéro ;
//   * avancer d'un nombre de cycles, et dire où en est son horloge ;
//   * dire, pour chaque broche, si elle est en sortie, à quel niveau, et si
//     son tirage interne est actif — c'est ce que le circuit a besoin de
//     savoir pour être résolu ;
//   * recevoir en retour le niveau imposé par le circuit et, pour les entrées
//     analogiques, la tension ;
//   * prévenir quand une sortie change, et quand un octet part sur la liaison
//     série.
//
// Tout le reste — la carte des registres, les compteurs, les vecteurs — est
// l'affaire de chaque implémentation, et n'a aucune raison de remonter
// jusqu'ici. C'est ce qui permet d'ajouter une architecture sans toucher au
// couplage électrique, et surtout sans risquer de casser celle qui marche.
#pragma once

#include <cstdint>
#include <memory>
#include <functional>
#include <string>

namespace coeur {

class Microcontroleur {
public:
    virtual ~Microcontroleur() = default;

    // --- identité
    // Le cœur qui exécute, tel qu'on l'affiche : « AVR (intégré) ».
    virtual const char* nom_du_coeur() const = 0;
    // La famille de puces que ce moteur sait exécuter reconnaît-elle ce nom ?
    virtual bool reconnait(const std::string& mcu) const = 0;
    virtual bool disponible() const { return true; }

    // --- firmware
    virtual bool charger(const std::string& chemin, const std::string& mcu,
                         uint32_t frequence_hz) = 0;
    virtual void reinitialiser() = 0;
    virtual const std::string& erreur() const = 0;

    // --- temps
    virtual uint64_t avancer(uint64_t cycles) = 0;
    virtual uint64_t cycle() const = 0;
    virtual double temps_ms() const = 0;
    virtual uint32_t frequence() const = 0;

    // --- ce que le circuit lit de la puce
    virtual bool direction_sortie(int broche) const = 0;
    virtual bool niveau_port(int broche) const = 0;
    virtual bool pullup_actif(int broche) const = 0;
    // La voie de conversion derrière une broche, ou -1 si elle n'en a pas.
    virtual int canal_adc(int broche) const = 0;

    // --- ce que le circuit impose à la puce
    virtual void definir_niveau_externe(int broche, bool haut) = 0;
    virtual void definir_tension_adc(int canal, double volts) = 0;
    virtual void envoyer_octet_serie(uint8_t octet) = 0;

    // --- notifications
    virtual void sur_changement_broche(std::function<void(int, bool)> rappel) = 0;
    virtual void sur_octet_serie(std::function<void(char)> rappel) = 0;
};

// Fabrique le moteur capable d'exécuter cette puce, ou nullptr si aucune
// architecture connue ne la reconnaît. C'est le seul endroit à compléter pour
// qu'une nouvelle famille devienne exécutable partout dans l'application.
std::unique_ptr<Microcontroleur> creer_microcontroleur(const std::string& mcu);

// La liste des puces exécutables, pour les messages d'erreur et les tests.
std::string puces_connues();

}  // namespace coeur
