// Le moteur Xtensa, vu par le simulateur : l'ESP32.
//
// Limites, dites ici plutôt que découvertes à l'usage : un seul des deux
// cœurs est exécuté, la fenêtre de registres n'est pas tournée, et rien de
// ce que FreeRTOS ou l'ESP-IDF attendent n'est modélisé. Un programme qui
// pilote ses broches par leurs registres tourne ; un croquis Arduino-ESP32
// complet ne tourne pas. Aucune chaîne de compilation Xtensa n'est ici :
// seul un fichier déjà compilé peut être chargé.
#pragma once

#include <memory>

#include "core/engines/CoeurXtensa.h"
#include "core/engines/Microcontroleur.h"

namespace coeur {

class XtensaEngine : public Microcontroleur {
public:
    XtensaEngine();
    ~XtensaEngine() override;

    const char* nom_du_coeur() const override { return "Xtensa intégré"; }
    bool reconnait(const std::string& mcu) const override;

    bool charger(const std::string& chemin, const std::string& mcu,
                 uint32_t frequence_hz) override;
    void reinitialiser() override;
    const std::string& erreur() const override { return erreur_; }

    uint64_t avancer(uint64_t cycles) override;
    uint64_t cycle() const override;
    double temps_ms() const override;
    uint32_t frequence() const override { return frequence_; }

    bool direction_sortie(int broche) const override;
    bool niveau_port(int broche) const override;
    bool pullup_actif(int) const override { return false; }
    int canal_adc(int) const override { return -1; }

    void definir_niveau_externe(int broche, bool haut) override;
    void definir_tension_adc(int, double) override {}
    void envoyer_octet_serie(uint8_t) override {}

    void sur_changement_broche(std::function<void(int, bool)> rappel) override {
        rappel_broche_ = std::move(rappel);
    }
    void sur_octet_serie(std::function<void(char)> rappel) override {
        rappel_serie_ = std::move(rappel);
    }

private:
    std::unique_ptr<CoeurXtensa> coeur_;
    std::string erreur_;
    uint32_t frequence_ = 240000000;
    std::function<void(int, bool)> rappel_broche_;
    std::function<void(char)> rappel_serie_;
};

}  // namespace coeur
