#include "coeur/moteurs/microcontroleurs/CortexEngine.h"

#include "coeur/compilation/Chaines.h"

#include <cstdlib>
#include <fstream>
#include <sstream>

namespace coeur {

namespace {

// La chaîne de compilation pour ARM. Rien n'est embarqué ici — un compilateur
// C ne se met pas dans une archive de trente mégaoctets —, et le simulateur
// se contente de reconnaître ce qui est installé.
struct Chaine {
    std::string commande;      // le compilateur
    bool clang = false;
};

Chaine chaine() {
    static const Chaine trouvee = [] {
        Chaine resultat;
        // D'abord celle du paquet, ensuite celle de la machine : c'est ce que
        // fait `chaines::outil`.
        const std::string arm = chaines::outil("arm", "arm-none-eabi-gcc");
        if (!arm.empty()) {
            resultat.commande = arm;
            return resultat;
        }
        // clang sait produire du Thumb sans chaîne croisée séparée, à
        // condition de ne demander aucune bibliothèque standard.
        const std::string clang = chaines::outil("arm", "clang");
        if (!clang.empty()) {
            resultat.commande = clang;
            resultat.clang = true;
        }
        return resultat;
    }();
    return trouvee;
}

}  // namespace

CortexEngine::CortexEngine()
    : coeur_(std::make_unique<CoeurCortexM>(profil_rp2040())) {}

CortexEngine::~CortexEngine() = default;

bool CortexEngine::reconnait(const std::string& mcu) const {
    return profil_cortex_par_nom(mcu) != nullptr;
}

bool CortexEngine::charger(const std::string& chemin, const std::string& mcu,
                           uint32_t frequence_hz) {
    erreur_.clear();
    const ProfilCortex* profil = profil_cortex_par_nom(mcu);
    if (!profil) {
        erreur_ = "puce inconnue du cœur Cortex-M : " + mcu;
        return false;
    }
    mcu_ = mcu;
    frequence_ = frequence_hz ? frequence_hz : profil->frequence;
    coeur_->definir_profil(*profil);
    coeur_->definir_frequence(frequence_);
    coeur_->sur_broche = [this](int broche, bool haut) {
        if (rappel_broche_) rappel_broche_(broche, haut);
    };
    coeur_->sur_serie = [this](uint8_t octet) {
        if (rappel_serie_) rappel_serie_(static_cast<char>(octet));
    };
    std::string message;
    if (!coeur_->charger(chemin, &message)) {
        erreur_ = message;
        return false;
    }
    return true;
}

void CortexEngine::reinitialiser() { coeur_->reinitialiser(); }

uint64_t CortexEngine::avancer(uint64_t cycles) {
    if (!coeur_->charge()) return cycles;
    return coeur_->executer(cycles);
}

uint64_t CortexEngine::cycle() const { return coeur_->cycles(); }

double CortexEngine::temps_ms() const {
    return frequence_ ? static_cast<double>(coeur_->cycles()) * 1000.0 / frequence_
                      : 0.0;
}

bool CortexEngine::direction_sortie(int broche) const {
    return coeur_->broche_en_sortie(broche);
}

bool CortexEngine::niveau_port(int broche) const {
    return coeur_->broche_haute(broche);
}

bool CortexEngine::pullup_actif(int broche) const {
    // Le tirage interne est armé par le firmware : sur un RP2040 dans le bloc
    // des broches, sur un STM32 dans les quartets de configuration. Sans lui,
    // un bouton câblé à la masse laisserait une entrée flottante.
    return !coeur_->broche_en_sortie(broche)
           && coeur_->broche_tiree_haut(broche);
}

int CortexEngine::canal_adc(int broche) const {
    // RP2040 : les entrées analogiques sont GP26 à GP29.
    if (mcu_ == "rp2040") return broche >= 26 && broche <= 29 ? broche - 26 : -1;
    // STM32F103 : ADC1 lit PA0 à PA7 sur ses voies 0 à 7, puis PB0 et PB1.
    if (mcu_ == "stm32f103") {
        if (broche >= 0 && broche <= 7) return broche;          // PA0..PA7
        if (broche >= 16 && broche <= 17) return broche - 16 + 8;  // PB0, PB1
    }
    return -1;
}

void CortexEngine::definir_niveau_externe(int broche, bool haut) {
    coeur_->broche_externe(broche, haut);
}

void CortexEngine::definir_tension_adc(int voie, double volts) {
    coeur_->tension_adc(voie, volts);
}

void CortexEngine::definir_source_adc(
    std::function<double(int canal, uint64_t cycle)> source) {
    coeur_->source_adc = std::move(source);
}

void CortexEngine::envoyer_octet_serie(uint8_t) {}

bool CortexEngine::chaine_disponible() { return !chaine().commande.empty(); }

std::string CortexEngine::chaine_trouvee() { return chaine().commande; }

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

bool CortexEngine::compiler_source(const std::string& source,
                                   const std::string& chemin_elf,
                                   std::string* journal,
                                   const std::string& mcu) {
    return compiler_projet(Programme{{nom_principal(mcu), source}}, chemin_elf,
                           journal, mcu);
}

bool CortexEngine::compiler_projet(const Programme& fichiers,
                                   const std::string& chemin_elf,
                                   std::string* journal,
                                   const std::string& mcu) {
    const Chaine outil = chaine();
    if (outil.commande.empty()) {
        if (journal)
            *journal =
                "Aucun compilateur ARM trouvé.\n"
                "Le simulateur embarque son cœur Cortex-M, mais pas de "
                "compilateur C pour ARM — cela ne se met pas dans une "
                "archive portable.\n"
                "Installez « arm-none-eabi-gcc » (paquet gcc-arm-none-eabi) "
                "ou « clang », puis relancez. Un fichier .elf déjà compilé "
                "peut être chargé sans rien installer.";
        return false;
    }

    const std::string dossier = chemin_elf.substr(0, chemin_elf.find_last_of('/'));
    std::string a_compiler;
    if (!deposer_fichiers(fichiers, dossier, &a_compiler, journal)) return false;

    // Le programme est lié à l'adresse où la puce va le chercher, et sans
    // bibliothèque standard : c'est du nu, et c'est ce qui permet de s'en
    // tenir à un compilateur sans chaîne croisée complète.
    const bool pico = mcu == "rp2040";
    const std::string adresse = pico ? "0x10000000" : "0x08000000";
    const std::string cible = pico ? "thumbv6m-none-eabi" : "thumbv7m-none-eabi";
    const std::string cpu = pico ? "cortex-m0plus" : "cortex-m3";

    const std::string journal_fichier = chemin_elf + ".log";
    std::string commande = outil.commande;
    if (outil.clang) {
        commande += " --target=" + cible;
    } else {
        commande += " -mcpu=" + cpu + " -mthumb";
        // Syntaxe unifiée pour l'assembleur en ligne. Sans cela, GCC laisse
        // l'assembleur en syntaxe « divisée », héritée de l'ARM 32 bits, et
        // refuse des instructions Thumb parfaitement légales :
        //
        //     Error: instruction not supported in Thumb16 mode -- `subs r0,#1'
        //
        // C'est la forme que tout le monde écrit, celle des manuels ARM
        // depuis quinze ans. clang, lui, est déjà unifié et ne connaît même
        // pas l'option — d'où le fait que le défaut soit resté invisible tant
        // que seul clang était installé sur la machine d'essai.
        commande += " -masm-syntax-unified";
    }
    // Mêmes avertissements et même borne que côté AVR, pour la même raison :
    // « if (x = 0) » doit parler, et un mur d'erreurs en cascade doit être
    // coupé à sa source. Voir AvrEngine.cpp pour le détail.
    commande += " -Wall -Wextra -fmax-errors=5";
    commande += " -nostdlib -ffreestanding -Os -I \"" + dossier
                + "\" -Wl,-e,_start -Wl,-Ttext=" + adresse + " -o \""
                + chemin_elf + "\"" + a_compiler;
    // libgcc, et elle seule. « -nostdlib » écarte la bibliothèque C, ce qui
    // est voulu — il n'y a ni système ni tas ici. Mais il écarte aussi les
    // routines que le COMPILATEUR appelle de lui-même : un Cortex-M0+ n'a pas
    // de diviseur matériel, et le moindre « a / b » devient un appel à
    // __aeabi_uidiv. Sans libgcc, un programme parfaitement banal ne se lie
    // pas, avec un message qui ne désigne rien d'écrit par l'utilisateur.
    commande += " -lgcc";
    commande += " > \"" + journal_fichier + "\" 2>&1";

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
