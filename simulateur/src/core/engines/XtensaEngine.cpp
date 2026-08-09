#include "core/engines/XtensaEngine.h"

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

}  // namespace coeur
