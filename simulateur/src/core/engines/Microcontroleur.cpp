// La fabrique : à quel moteur confier telle puce.
//
// C'est le seul endroit du projet qui connaisse la liste des architectures.
// Ajouter une famille consiste à écrire son moteur, puis à l'inscrire ici :
// le catalogue, le couplage électrique, la compilation et l'interface n'ont
// pas à changer.
#include "core/engines/Microcontroleur.h"

#include "core/engines/AvrEngine.h"

namespace coeur {

namespace {

// Les moteurs, dans l'ordre où on les interroge. Chacun dit lui-même s'il
// reconnaît la puce demandée : la liste des noms reste ainsi dans le moteur
// qui les exécute, et non recopiée ici où elle se démoderait.
std::unique_ptr<Microcontroleur> fabriquer(int rang) {
    switch (rang) {
        case 0: return std::make_unique<AvrEngine>();
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

std::string puces_connues() {
    // Les noms sont ceux qu'attend le compilateur : c'est ainsi que
    // l'utilisateur les rencontrera dans un message d'erreur.
    static const char* noms[] = {"atmega328p", "atmega2560", "attiny85"};
    std::string liste;
    for (const char* nom : noms) {
        if (!liste.empty()) liste += ", ";
        liste += nom;
    }
    return liste;
}

}  // namespace coeur
