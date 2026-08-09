// La fabrique : à quel moteur confier telle puce.
//
// C'est le seul endroit du projet qui connaisse la liste des architectures.
// Ajouter une famille consiste à écrire son moteur, puis à l'inscrire ici :
// le catalogue, le couplage électrique, la compilation et l'interface n'ont
// pas à changer.
#include <cctype>
#include "core/engines/Microcontroleur.h"

#include "core/engines/AvrEngine.h"
#include "core/engines/CortexEngine.h"
#include "core/engines/XtensaEngine.h"

namespace coeur {

namespace {

// Les moteurs, dans l'ordre où on les interroge. Chacun dit lui-même s'il
// reconnaît la puce demandée : la liste des noms reste ainsi dans le moteur
// qui les exécute, et non recopiée ici où elle se démoderait.
std::unique_ptr<Microcontroleur> fabriquer(int rang) {
    switch (rang) {
        case 0: return std::make_unique<AvrEngine>();
        case 1: return std::make_unique<CortexEngine>();
        case 2: return std::make_unique<XtensaEngine>();
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
bool est_xtensa(const std::string& mcu) {
    XtensaEngine xtensa;
    return xtensa.reconnait(mcu);
}
}  // namespace

namespace {
std::string extension_de(const std::string& nom) {
    const size_t point = nom.find_last_of('.');
    if (point == std::string::npos) return {};
    std::string extension = nom.substr(point);
    for (char& c : extension)
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return extension;
}
}  // namespace

bool fichier_a_compiler(const std::string& nom) {
    const std::string extension = extension_de(nom);
    return extension == ".c" || extension == ".cpp" || extension == ".cc";
}

bool fichier_croquis(const std::string& nom) {
    return extension_de(nom) == ".ino";
}

std::string fusionner_croquis(const Programme& fichiers) {
    // Les annexes d'abord, le principal en dernier : c'est ce qui rend les
    // fonctions des annexes visibles sans prototype.
    std::string fusion;
    auto ajouter = [&fusion](const Fichier& fichier) {
        fusion += "#line 1 \"" + fichier.nom + "\"\n";
        fusion += fichier.contenu;
        if (!fusion.empty() && fusion.back() != '\n') fusion += '\n';
    };
    for (size_t rang = 1; rang < fichiers.size(); ++rang)
        if (fichier_croquis(fichiers[rang].nom)) ajouter(fichiers[rang]);
    if (!fichiers.empty() && fichier_croquis(fichiers.front().nom))
        ajouter(fichiers.front());
    return fusion;
}

std::string nom_principal(const std::string& mcu) {
    // Une carte qui reçoit le noyau Arduino porte un croquis ; une puce nue
    // porte du C. L'extension n'est pas cosmétique : c'est elle qui dit à
    // l'utilisateur dans quel style ce fichier est écrit.
    return (mcu == "atmega328p" || mcu == "atmega2560") ? "principal.ino"
                                                        : "principal.c";
}

bool compiler_pour(const std::string& mcu, const Programme& fichiers,
                   const std::string& chemin_elf, uint32_t horloge,
                   std::string* journal) {
    if (fichiers.empty()) {
        if (journal) *journal = "programme vide : rien à compiler";
        return false;
    }
    if (est_arm(mcu))
        return CortexEngine::compiler_projet(fichiers, chemin_elf, journal, mcu);
    if (est_xtensa(mcu))
        return XtensaEngine::compiler_projet(fichiers, chemin_elf, journal);
    return AvrEngine::compiler_projet(fichiers, chemin_elf, journal, mcu,
                                      horloge);
}

bool compiler_pour(const std::string& mcu, const std::string& source,
                   const std::string& chemin_elf, uint32_t horloge,
                   std::string* journal) {
    return compiler_pour(mcu, Programme{{nom_principal(mcu), source}},
                         chemin_elf, horloge, journal);
}

bool chaine_disponible_pour(const std::string& mcu) {
    if (est_arm(mcu)) return CortexEngine::chaine_disponible();
    if (est_xtensa(mcu)) return XtensaEngine::chaine_disponible();
    return AvrEngine::avr_gpp_disponible();
}

std::string puces_connues() {
    // Les noms sont ceux qu'attend le compilateur : c'est ainsi que
    // l'utilisateur les rencontrera dans un message d'erreur.
    static const char* noms[] = {"atmega328p", "atmega2560", "attiny85",
                                 "rp2040", "stm32f103", "esp32"};
    std::string liste;
    for (const char* nom : noms) {
        if (!liste.empty()) liste += ", ";
        liste += nom;
    }
    return liste;
}

}  // namespace coeur
