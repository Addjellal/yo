#include "coeur/moteurs/microcontroleurs/XtensaEngine.h"

#include <cstdlib>
#include <fstream>
#include <sstream>

#include "coeur/compilation/Chaines.h"

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

std::string XtensaEngine::chaine_trouvee() {
    return chaines::outil("xtensa", "xtensa-esp32-elf-gcc");
}

namespace {

// Dépose chaque fichier du programme à côté du .elf et rend, dans `a_compiler`,
// la liste de ceux que le compilateur doit voir. Rend false — et dit pourquoi —
// si un nom est refusé ou si rien ne porte de code.
bool deposer_fichiers(const Programme& fichiers, const std::string& dossier,
                      std::string* a_compiler, std::string* journal) {
    a_compiler->clear();
    for (const Fichier& fichier : fichiers) {
        if (fichier.nom.empty() || fichier.nom.find('/') != std::string::npos
            || fichier.nom.find('\\') != std::string::npos) {
            if (journal)
                *journal = "nom de fichier refusé : « " + fichier.nom
                           + " » — un nom simple, sans dossier, est attendu";
            return false;
        }
        const std::string chemin = dossier + "/" + fichier.nom;
        std::ofstream sortie(chemin);
        if (!sortie) {
            if (journal) *journal = "écriture impossible : " + chemin;
            return false;
        }
        sortie << fichier.contenu;
        sortie.close();
        if (fichier_a_compiler(fichier.nom)) *a_compiler += " \"" + chemin + "\"";
    }
    // Les onglets de croquis sont fondus en une seule unité, comme du côté
    // AVR : la règle du « .ino » ne change pas avec l'architecture.
    const std::string croquis = fusionner_croquis(fichiers);
    if (!croquis.empty()) {
        const std::string fondu = dossier + "/croquis_fondu.c";
        std::ofstream sortie(fondu);
        if (!sortie) {
            if (journal) *journal = "écriture impossible : " + fondu;
            return false;
        }
        sortie << croquis;
        sortie.close();
        *a_compiler += " \"" + fondu + "\"";
    }
    if (a_compiler->empty()) {
        if (journal)
            *journal = "aucun fichier de code dans ce programme : un « .h » "
                       "seul ne se compile pas";
        return false;
    }
    return true;
}

}  // namespace

bool XtensaEngine::compiler_source(const std::string& source,
                                   const std::string& chemin_elf,
                                   std::string* journal) {
    return compiler_projet(Programme{{"principal.c", source}}, chemin_elf,
                           journal);
}

bool XtensaEngine::compiler_projet(const Programme& fichiers,
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

    const std::string dossier = chemin_elf.substr(0, chemin_elf.find_last_of('/'));
    std::string a_compiler;
    if (!deposer_fichiers(fichiers, dossier, &a_compiler, journal)) return false;

    // Le programme d'exemple nomme sa fonction app_main, comme l'ESP-IDF.
    // Sans l'IDF, c'est elle qui devient le point d'entrée : on ajoute le
    // démarrage dans un fichier à part, pour ne pas retoucher celui que
    // l'utilisateur a écrit.
    const std::string amorce = dossier + "/demarrage_esp32.c";
    {
        std::ofstream fichier(amorce);
        if (!fichier) {
            if (journal) *journal = "écriture impossible : " + amorce;
            return false;
        }
        fichier << "void app_main(void);\n"
                << "void _start(void) { app_main(); for (;;) { } }\n";
    }

    // Sans ESP-IDF ni FreeRTOS : du nu, lié là où l'ESP32 exécute sa mémoire
    // interne. C'est ce que le cœur sait faire tourner, et rien de plus.
    const std::string journal_fichier = chemin_elf + ".log";
    const std::string commande =
        compilateur
        + " -mlongcalls -nostdlib -ffreestanding -Os -I \"" + dossier
        + "\" -Wl,-e,_start -Wl,-Ttext=0x400D0000 -o \"" + chemin_elf + "\""
        + a_compiler + " \"" + amorce + "\" > \"" + journal_fichier
        + "\" 2>&1";
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
