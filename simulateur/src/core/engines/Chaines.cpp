#include "core/engines/Chaines.h"

#include <cstdlib>
#include <fstream>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#else
#include <limits.h>
#include <unistd.h>
#endif

namespace coeur {
namespace chaines {

namespace {

#ifdef _WIN32
constexpr const char* kSuffixe = ".exe";
constexpr char kSeparateur = '\\';
#else
constexpr const char* kSuffixe = "";
constexpr char kSeparateur = '/';
#endif

bool fichier_existe(const std::string& chemin) {
    std::ifstream essai(chemin, std::ios::binary);
    return essai.good();
}

bool dans_le_path(const std::string& nom) {
#ifdef _WIN32
    const std::string essai = "where " + nom + " > NUL 2>&1";
#else
    const std::string essai = "command -v " + nom + " > /dev/null 2>&1";
#endif
    return std::system(essai.c_str()) == 0;
}

// Les guillemets ne servent qu'aux chemins : un nom nu passé à l'interpréteur
// doit le rester, sinon « where » et « command -v » ne le trouveraient plus.
std::string proteger(const std::string& chemin) {
    if (chemin.find(' ') == std::string::npos) return chemin;
    return "\"" + chemin + "\"";
}

}  // namespace

std::string dossier_executable() {
    static const std::string dossier = [] {
        std::string chemin;
#ifdef _WIN32
        std::vector<char> tampon(4096);
        const DWORD taille =
            GetModuleFileNameA(nullptr, tampon.data(),
                               static_cast<DWORD>(tampon.size()));
        chemin.assign(tampon.data(), taille);
#else
        std::vector<char> tampon(PATH_MAX);
        const ssize_t taille =
            readlink("/proc/self/exe", tampon.data(), tampon.size());
        if (taille > 0) chemin.assign(tampon.data(), static_cast<size_t>(taille));
#endif
        const size_t coupe = chemin.find_last_of("/\\");
        return coupe == std::string::npos ? std::string(".")
                                          : chemin.substr(0, coupe);
    }();
    return dossier;
}

std::string outil(const std::string& famille, const std::string& nom) {
    // 1. La chaîne emportée par le paquet, à côté de l'exécutable.
    const std::string embarque = dossier_executable() + kSeparateur + "chaines"
                                 + kSeparateur + famille + kSeparateur + "bin"
                                 + kSeparateur + nom + kSuffixe;
    if (fichier_existe(embarque)) return proteger(embarque);

    // 2. Celle de la machine, si elle en a une.
    if (dans_le_path(nom)) return nom;
    return std::string();
}

std::string etat() {
    struct Attendu {
        const char* famille;
        const char* outil;
        const char* description;
    };
    static const Attendu attendus[] = {
        {"avr", "avr-g++", "AVR (Arduino, ATtiny)"},
        {"arm", "arm-none-eabi-gcc", "ARM (Pi Pico, STM32)"},
        {"xtensa", "xtensa-esp32-elf-gcc", "Xtensa (ESP32)"}};

    std::string compte_rendu;
    for (const Attendu& attendu : attendus) {
        const std::string chemin = outil(attendu.famille, attendu.outil);
        compte_rendu += std::string(attendu.description) + " : ";
        if (chemin.empty()) {
            compte_rendu += "absent — lancez outils/chaines pour l'installer";
        } else if (chemin == attendu.outil) {
            compte_rendu += "trouvé dans le PATH";
        } else {
            compte_rendu += "embarqué dans le paquet";
        }
        compte_rendu += "\n";
    }
    return compte_rendu;
}

}  // namespace chaines
}  // namespace coeur
