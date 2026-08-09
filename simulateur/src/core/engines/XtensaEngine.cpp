#include "core/engines/XtensaEngine.h"

#include <cstdlib>
#include <fstream>
#include <sstream>

#include "core/engines/Chaines.h"

namespace coeur {

XtensaEngine::XtensaEngine()
    : coeur_(std::make_unique<CoeurXtensa>(profil_esp32())) {}

XtensaEngine::~XtensaEngine() = default;

bool XtensaEngine::reconnait(const std::string& mcu) const {
    return profil_xtensa_par_nom(mcu) != nullptr;
}

bool XtensaEngine::charger(const std::string& chemin, const std::string& mcu,
                           uint32_t frequence_hz) {
    erreur_.clear();
    const ProfilXtensa* profil = profil_xtensa_par_nom(mcu);
    if (!profil) {
        erreur_ = "puce inconnue du cœur Xtensa : " + mcu;
        return false;
    }
    frequence_ = frequence_hz ? frequence_hz : profil->frequence;
    coeur_->definir_profil(*profil);
    coeur_->definir_frequence(frequence_);
    coeur_->sur_broche = [this](int broche, bool haut) {
        if (rappel_broche_) rappel_broche_(broche, haut);
    };
    std::string message;
    if (!coeur_->charger(chemin, &message)) {
        erreur_ = message;
        return false;
    }
    return true;
}

void XtensaEngine::reinitialiser() { coeur_->reinitialiser(); }

uint64_t XtensaEngine::avancer(uint64_t cycles) {
    if (!coeur_->charge()) return cycles;
    return coeur_->executer(cycles);
}

uint64_t XtensaEngine::cycle() const { return coeur_->cycles(); }

double XtensaEngine::temps_ms() const {
    return frequence_ ? static_cast<double>(coeur_->cycles()) * 1000.0 / frequence_
                      : 0.0;
}

bool XtensaEngine::direction_sortie(int broche) const {
    return coeur_->broche_en_sortie(broche);
}

bool XtensaEngine::niveau_port(int broche) const {
    return coeur_->broche_haute(broche);
}

void XtensaEngine::definir_niveau_externe(int broche, bool haut) {
    coeur_->broche_externe(broche, haut);
}

bool XtensaEngine::chaine_disponible() {
    return !chaines::outil("xtensa", "xtensa-esp32-elf-gcc").empty();
}

bool XtensaEngine::compiler_source(const std::string& source,
                                   const std::string& chemin_elf,
                                   std::string* journal) {
    const std::string compilateur =
        chaines::outil("xtensa", "xtensa-esp32-elf-gcc");
    if (compilateur.empty()) {
        if (journal)
            *journal =
                "Aucun compilateur Xtensa trouvé.\n"
                "Lancez « outils/chaines.ps1 -Xtensa » (ou chaines.sh) pour "
                "l'installer à côté de l'exécutable — le paquet devient alors "
                "autosuffisant pour l'ESP32.\n"
                "Un fichier .elf déjà compilé se charge sans rien installer.";
        return false;
    }

    const std::string base = chemin_elf + ".c";
    {
        std::ofstream fichier(base);
        if (!fichier) {
            if (journal) *journal = "écriture impossible : " + base;
            return false;
        }
        // Le programme d'exemple nomme sa fonction app_main, comme l'ESP-IDF.
        // Sans l'IDF, c'est elle qui devient le point d'entrée.
        fichier << source << "\n"
                << "void _start(void) { app_main(); for (;;) { } }\n";
    }

    // Sans ESP-IDF ni FreeRTOS : du nu, lié là où l'ESP32 exécute sa mémoire
    // interne. C'est ce que le cœur sait faire tourner, et rien de plus.
    const std::string journal_fichier = chemin_elf + ".log";
    const std::string commande =
        compilateur
        + " -mlongcalls -nostdlib -ffreestanding -Os -Wl,-e,_start"
          " -Wl,-Ttext=0x400D0000 -o \"" + chemin_elf + "\" \"" + base
        + "\" > \"" + journal_fichier + "\" 2>&1";
    const int code = std::system(commande.c_str());
    if (journal) {
        std::ifstream lecture(journal_fichier);
        std::stringstream tampon;
        tampon << lecture.rdbuf();
        *journal = tampon.str();
    }
    return code == 0;
}

}  // namespace coeur
