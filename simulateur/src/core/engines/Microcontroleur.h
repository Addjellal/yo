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
#include <vector>

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
    // Source de tension DATÉE pour le convertisseur.
    //
    // `definir_tension_adc` fige une valeur pour toute une fenêtre de
    // couplage — cinq millisecondes. Un programme qui échantillonne plus vite
    // que deux cents fois par seconde relit alors treize fois la même mesure,
    // et toute analyse embarquée d'un signal alternatif est fausse sans que
    // rien ne le signale.
    //
    // Avec cette source, la puce demande la tension AU MOMENT où elle
    // convertit, en donnant son propre compteur de cycles. Le couplage y
    // répond en relisant la forme d'onde déjà calculée, ce qui introduit un
    // retard d'une fenêtre : sur un régime périodique établi, un retard pur
    // ne change pas le spectre d'amplitude, seulement la phase.
    //
    // Rendre une valeur négative veut dire « je n'ai rien pour cet instant » :
    // la puce garde alors ce que `definir_tension_adc` lui a laissé.
    virtual void definir_source_adc(
        std::function<double(int canal, uint64_t cycle)> source) = 0;
    virtual void envoyer_octet_serie(uint8_t octet) = 0;

    // --- notifications
    virtual void sur_changement_broche(std::function<void(int, bool)> rappel) = 0;
    virtual void sur_octet_serie(std::function<void(char)> rappel) = 0;
};

// ---------------------------------------------------------------------------
// Un programme tel qu'on l'écrit : plusieurs fichiers.
//
// Un croquis qui tient en une page se passe de tout cela. Dès qu'il grossit,
// non : on veut sortir les fonctions communes, et les partager entre
// plusieurs programmes. C'est ce que fait tout le monde dans l'IDE Arduino
// avec un « .h » posé à côté du croquis.
//
// Les règles sont celles d'un projet Arduino, et pas d'autres :
//
//   * le PREMIER fichier est le principal. C'est lui qui reçoit l'en-tête du
//     noyau, c'est lui qui porte setup() et loop() ;
//   * un fichier d'en-tête (« .h », « .hpp ») est déposé à côté mais n'est
//     pas compilé pour lui-même : il n'existe qu'à travers ceux qui
//     l'incluent ;
//   * un fichier de code (« .c », « .cpp », « .ino ») est compilé et lié ;
//   * tous vivent dans le même dossier, qui est dans le chemin d'inclusion :
//     « #include "mesure.h" » trouve donc « mesure.h » sans rien régler.
struct Fichier {
    std::string nom;          // « principal.ino », « mesure.h »
    std::string contenu;
};
using Programme = std::vector<Fichier>;

// Le fichier est-il une unité de compilation à part (« .c », « .cpp ») ?
// Un « .ino » n'en est PAS une : voir `fusionner_croquis`.
bool fichier_a_compiler(const std::string& nom);
// Le fichier est-il un onglet de croquis (« .ino ») ?
bool fichier_croquis(const std::string& nom);

// Fusionne les onglets de croquis en une seule unité de compilation, comme le
// fait l'IDE Arduino — et pour la même raison : un « .ino » n'est pas du C++
// autonome. Il n'a ni inclusion ni prototype, et ses fonctions sont censées
// se voir les unes les autres sans qu'on ait rien déclaré.
//
// UNE DIFFÉRENCE avec l'IDE, et elle est délibérée. L'IDE met le croquis
// principal en tête puis fabrique les prototypes des fonctions qui suivent,
// par une analyse syntaxique approximative qui se trompe sur les modèles, les
// références et les types composés. Ici les onglets annexes passent AVANT le
// principal : tout ce qu'ils définissent est visible du principal sans qu'on
// ait à deviner quoi que ce soit. Le cas qui cesse de marcher — un onglet
// annexe appelant une fonction du principal — produit une erreur claire du
// compilateur, et non un prototype faux.
//
// Chaque morceau est précédé d'un « #line » qui porte son nom : une erreur
// désigne donc le bon onglet et la bonne ligne.
std::string fusionner_croquis(const Programme& fichiers);
// Nom du fichier principal selon la puce : un croquis pour une carte
// Arduino, du C sur registres pour une puce nue.
std::string nom_principal(const std::string& mcu);

// Fabrique le moteur capable d'exécuter cette puce, ou nullptr si aucune
// architecture connue ne la reconnaît. C'est le seul endroit à compléter pour
// qu'une nouvelle famille devienne exécutable partout dans l'application.
std::unique_ptr<Microcontroleur> creer_microcontroleur(const std::string& mcu);

// La liste des puces exécutables, pour les messages d'erreur et les tests.
std::string puces_connues();

// Compile un programme pour cette puce, avec la chaîne qui lui convient : le
// compilateur AVR pour un ATmega, le compilateur ARM pour un Cortex-M. C'est
// le pendant de `creer_microcontroleur` : exécuter et compiler doivent suivre
// la même architecture, sans quoi l'un des deux se trompe de machine.
bool compiler_pour(const std::string& mcu, const std::string& source,
                   const std::string& chemin_elf, uint32_t horloge,
                   std::string* journal);
// Même chose pour un programme en plusieurs fichiers.
bool compiler_pour(const std::string& mcu, const Programme& fichiers,
                   const std::string& chemin_elf, uint32_t horloge,
                   std::string* journal);
// Y a-t-il de quoi compiler pour cette puce sur cette machine ?
bool chaine_disponible_pour(const std::string& mcu);

}  // namespace coeur
