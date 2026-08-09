// La fabrique : à quel moteur confier telle puce.
//
// C'est le seul endroit du projet qui connaisse la liste des architectures.
// Ajouter une famille consiste à écrire son moteur, puis à l'inscrire ici :
// le catalogue, le couplage électrique, la compilation et l'interface n'ont
// pas à changer.
#include "core/engines/Microcontroleur.h"

#include "core/engines/AvrEngine.h"
#include "core/engines/CortexEngine.h"

namespace coeur {

namespace {

// Les moteurs, dans l'ordre où on les interroge. Chacun dit lui-même s'il
// reconnaît la puce demandée : la liste des noms reste ainsi dans le moteur
// qui les exécute, et non recopiée ici où elle se démoderait.
std::unique_ptr<Microcontroleur> fabriquer(int rang) {
    switch (rang) {
        case 0: return std::make_unique<AvrEngine>();
        case 1: return std::make_unique<CortexEngine>();
        default: return nullptr;
    }
}

}  // namespace

std::unique_ptr<Microcontroleur> creer_microcontroleur(const std::string& mcu) {
    for (int rang = 0;; ++rang) {
        std::unique_ptr<Microcontroleur> moteur = fabriquer(rang);
        if (!moteur) return nullptr;
        if (moteur->reconnait(mcu)) return moteur;
    }
}

namespace {
// Une puce ARM se reconnaît à ce que le moteur Cortex-M la revendique. On ne
// tient pas une seconde liste de noms ici : elle finirait par diverger.
bool est_arm(const std::string& mcu) {
    CortexEngine cortex;
    return cortex.reconnait(mcu);
}
}  // namespace

bool compiler_pour(const std::string& mcu, const std::string& source,
                   const std::string& chemin_elf, uint32_t horloge,
                   std::string* journal) {
    if (est_arm(mcu))
        return CortexEngine::compiler_source(source, chemin_elf, journal, mcu);
    return AvrEngine::compiler_source(source, chemin_elf, journal, mcu, horloge);
}

bool chaine_disponible_pour(const std::string& mcu) {
    if (est_arm(mcu)) return CortexEngine::chaine_disponible();
    return AvrEngine::avr_gpp_disponible();
}

std::string puces_connues() {
    // Les noms sont ceux qu'attend le compilateur : c'est ainsi que
    // l'utilisateur les rencontrera dans un message d'erreur.
    static const char* noms[] = {"atmega328p", "atmega2560", "attiny85",
                                 "rp2040", "stm32f103"};
    std::string liste;
    for (const char* nom : noms) {
        if (!liste.empty()) liste += ", ";
        liste += nom;
    }
    return liste;
}

}  // namespace coeur
