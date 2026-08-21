// Le moteur Cortex-M, vu par le simulateur.
//
// Même rôle qu'AvrEngine pour la famille AVR : il tient le cœur, traduit les
// broches, et présente à tout le reste l'interface commune. Il n'y a pas de
// second moteur de référence ici — il n'existe pas d'équivalent de simavr
// qu'on puisse embarquer —, et la vérification se fait donc contre du vrai
// code compilé, ce que fait le banc d'essai.
#pragma once

#include <memory>

#include "coeur/moteurs/microcontroleurs/CoeurCortexM.h"
#include "coeur/moteurs/microcontroleurs/Microcontroleur.h"

namespace coeur {

class CortexEngine : public Microcontroleur {
public:
    CortexEngine();
    ~CortexEngine() override;

    const char* nom_du_coeur() const override { return "Cortex-M intégré"; }
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
    bool pullup_actif(int broche) const override;
    int canal_adc(int broche) const override;

    void definir_niveau_externe(int broche, bool haut) override;
    void definir_tension_adc(int canal, double volts) override;
    void definir_source_adc(
        std::function<double(int canal, uint64_t cycle)> source) override;
    void envoyer_octet_serie(uint8_t octet) override;

    void sur_changement_broche(std::function<void(int, bool)> rappel) override {
        rappel_broche_ = std::move(rappel);
    }
    void sur_octet_serie(std::function<void(char)> rappel) override {
        rappel_serie_ = std::move(rappel);
    }

    // Compile un programme C pour cette puce. Contrairement à l'AVR, aucune
    // chaîne n'est embarquée : il faut « arm-none-eabi-gcc » ou « clang »
    // dans le PATH. Renvoie false et l'explique dans le journal sinon.
    static bool compiler_source(const std::string& source,
                                const std::string& chemin_elf,
                                std::string* journal, const std::string& mcu);
    static bool compiler_projet(const Programme& fichiers,
                                const std::string& chemin_elf,
                                std::string* journal,
                                const std::string& mcu = "rp2040");
    // Y a-t-il de quoi compiler pour ARM sur cette machine ?
    static bool chaine_disponible();
    // Le nom de la chaîne trouvée, pour le dire à l'utilisateur.
    static std::string chaine_trouvee();

private:
    std::unique_ptr<CoeurCortexM> coeur_;
    std::string mcu_ = "rp2040";
    std::string erreur_;
    uint32_t frequence_ = 125000000;
    std::function<void(int, bool)> rappel_broche_;
    std::function<void(char)> rappel_serie_;
};

}  // namespace coeur
