#include "core/engines/CortexEngine.h"

#include "core/engines/Chaines.h"

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

bool CortexEngine::pullup_actif(int) const {
    // Les tirages internes d'un Cortex-M se règlent dans le bloc de contrôle
    // des broches, que ce cœur ne modélise pas encore. Les annoncer inactifs
    // est le seul choix honnête : mieux vaut une entrée flottante qu'un
    // tirage imaginaire qui fausserait le circuit.
    return false;
}

int CortexEngine::canal_adc(int broche) const {
    // RP2040 : les entrées analogiques sont GP26 à GP29.
    if (mcu_ == "rp2040") return broche >= 26 && broche <= 29 ? broche - 26 : -1;
    return -1;
}

void CortexEngine::definir_niveau_externe(int broche, bool haut) {
    coeur_->broche_externe(broche, haut);
}

void CortexEngine::definir_tension_adc(int, double) {
    // Le convertisseur du RP2040 n'est pas encore modélisé : ne rien faire
    // vaut mieux que rendre une valeur inventée.
}

void CortexEngine::envoyer_octet_serie(uint8_t) {}

bool CortexEngine::chaine_disponible() { return !chaine().commande.empty(); }

std::string CortexEngine::chaine_trouvee() { return chaine().commande; }

bool CortexEngine::compiler_source(const std::string& source,
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

    const std::string base = chemin_elf + ".c";
    {
        std::ofstream fichier(base);
        if (!fichier) {
            if (journal) *journal = "écriture impossible : " + base;
            return false;
        }
        fichier << source;
    }

    // Le programme est lié à l'adresse où la puce va le chercher, et sans
    // bibliothèque standard : c'est du nu, et c'est ce qui permet de s'en
    // tenir à un compilateur sans chaîne croisée complète.
    const bool pico = mcu == "rp2040";
    const std::string adresse = pico ? "0x10000000" : "0x08000000";
    const std::string cible = pico ? "thumbv6m-none-eabi" : "thumbv7m-none-eabi";
    const std::string cpu = pico ? "cortex-m0plus" : "cortex-m3";

    const std::string journal_fichier = chemin_elf + ".log";
    std::string commande = outil.commande;
    if (outil.clang) commande += " --target=" + cible;
    else commande += " -mcpu=" + cpu + " -mthumb";
    commande += " -nostdlib -ffreestanding -Os -Wl,-e,_start -Wl,-Ttext="
                + adresse + " -o \"" + chemin_elf + "\" \"" + base + "\" > \""
                + journal_fichier + "\" 2>&1";

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
