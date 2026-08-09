#include "core/engines/AvrEngine.h"

#include "core/engines/CoeurAvr.h"
#include "core/engines/noyau_arduino.h"

#include <array>
#include <cstdio>
#include <cstdlib>
#include <fstream>

#ifdef AVEC_SIMAVR
#include <simavr/avr_adc.h>
#include <simavr/avr_ioport.h>
#include <simavr/avr_uart.h>
#include <simavr/sim_avr.h>
#include <simavr/sim_elf.h>
#include <simavr/sim_hex.h>
#endif

namespace coeur {

// Correspondance broche Arduino -> (port, bit) sur un ATmega328P
namespace {
struct BrocheAvr {
    char port;
    int bit;
};

BrocheAvr broche_avr(int broche) {
    if (broche <= 7) return {'D', broche};          // D0..D7  -> PORTD
    if (broche <= 13) return {'B', broche - 8};     // D8..D13 -> PORTB
    return {'C', broche - 14};                      // A0..A5  -> PORTC
}

// Adresses en espace données de l'ATmega328P (adresse E/S + 0x20).
uint16_t adresse_ddr(char port) {
    switch (port) {
        case 'B': return 0x24;
        case 'C': return 0x27;
        default:  return 0x2A;   // D
    }
}
uint16_t adresse_port(char port) { return adresse_ddr(port) + 1; }
}  // namespace

#ifdef AVEC_SIMAVR

// Contexte passé aux rappels C de simavr : le moteur et la broche concernée.
// On ne détourne surtout pas le champ `irq` de simavr, qui lui sert à
// identifier le bit du port en interne.
struct ContexteBroche {
    AvrEngine* moteur = nullptr;
    int broche = 0;
};

struct AvrEngine::Impl {
    CoeurAvr coeur;                       // le cœur écrit ici
    avr_t* avr = nullptr;                 // simavr, si on le préfère
    elf_firmware_t firmware = {};
    AvrEngine* proprietaire = nullptr;
    std::array<ContexteBroche, 20> contextes = {};
};

namespace {

void rappel_port(struct avr_irq_t*, uint32_t valeur, void* param) {
    auto* contexte = static_cast<ContexteBroche*>(param);
    contexte->moteur->_notifier_broche(contexte->broche, valeur != 0);
}

void rappel_uart(struct avr_irq_t*, uint32_t valeur, void* param) {
    static_cast<AvrEngine*>(param)->_notifier_serie(static_cast<char>(valeur));
}

}  // namespace

AvrEngine::AvrEngine() : impl_(new Impl) { impl_->proprietaire = this; }

AvrEngine::~AvrEngine() {
    if (impl_ && impl_->avr) avr_terminate(impl_->avr);
    delete impl_;
}

bool AvrEngine::compile_avec_simavr() { return true; }

bool AvrEngine::charger_simavr(const std::string& chemin,
                               const std::string& mcu, uint32_t frequence) {
    erreur_.clear();
    frequence_ = frequence;
    cycle_ = 0;
    etat_broches_.clear();
    sortie_broches_.clear();

    if (impl_->avr) {
        avr_terminate(impl_->avr);
        impl_->avr = nullptr;
    }

    elf_firmware_t firmware = {};
    if (elf_read_firmware(chemin.c_str(), &firmware) != 0) {
        erreur_ = "impossible de lire le firmware : " + chemin;
        return false;
    }
    if (firmware.frequency == 0) firmware.frequency = frequence;

    avr_t* avr = avr_make_mcu_by_name(mcu.c_str());
    if (!avr) {
        erreur_ = "microcontrôleur inconnu de simavr : " + mcu;
        return false;
    }
    avr_init(avr);
    avr->frequency = frequence;
    avr_load_firmware(avr, &firmware);
    impl_->avr = avr;
    impl_->firmware = firmware;

    // Écoute des 20 broches Arduino
    for (int broche = 0; broche <= 19; ++broche) {
        BrocheAvr cible = broche_avr(broche);
        avr_irq_t* irq = avr_io_getirq(
            avr, AVR_IOCTL_IOPORT_GETIRQ(cible.port), cible.bit);
        if (!irq) continue;
        impl_->contextes[broche] = {this, broche};
        avr_irq_register_notify(irq, rappel_port, &impl_->contextes[broche]);
    }
    // Écoute de l'UART (ce que le programme envoie sur Serial)
    if (avr_irq_t* uart = avr_io_getirq(avr, AVR_IOCTL_UART_GETIRQ('0'),
                                        UART_IRQ_OUTPUT))
        avr_irq_register_notify(uart, rappel_uart, this);
    // Débranche le contrôle de flux, sinon simavr suspend l'UART
    uint32_t drapeau = 0;
    avr_ioctl(avr, AVR_IOCTL_UART_GET_FLAGS('0'), &drapeau);
    drapeau &= ~AVR_UART_FLAG_STDIO;
    avr_ioctl(avr, AVR_IOCTL_UART_SET_FLAGS('0'), &drapeau);
    return true;
}

uint64_t AvrEngine::avancer_simavr(uint64_t cycles) {
    if (!impl_->avr) return 0;
    const uint64_t depart = impl_->avr->cycle;
    const uint64_t but = depart + cycles;
    while (impl_->avr->cycle < but) {
        int etat = avr_run(impl_->avr);
        if (etat == cpu_Done || etat == cpu_Crashed) break;
    }
    cycle_ = impl_->avr->cycle;
    return cycle_ - depart;
}

void AvrEngine::reinitialiser_simavr() {
    if (impl_->avr) {
        avr_reset(impl_->avr);
        cycle_ = 0;
    }
}

void AvrEngine::adc_simavr(int canal, double volts) {
    if (!impl_->avr) return;
    if (volts < 0) volts = 0;
    if (volts > 5) volts = 5;
    avr_irq_t* irq = avr_io_getirq(impl_->avr, AVR_IOCTL_ADC_GETIRQ,
                                   ADC_IRQ_ADC0 + canal);
    if (irq) avr_raise_irq(irq, static_cast<uint32_t>(volts * 1000.0));
}

void AvrEngine::serie_simavr(uint8_t octet) {
    if (!impl_->avr) return;
    if (avr_irq_t* irq = avr_io_getirq(impl_->avr, AVR_IOCTL_UART_GETIRQ('0'),
                                        UART_IRQ_INPUT))
        avr_raise_irq(irq, octet);
}

uint64_t AvrEngine::cycle_simavr() const {
    return impl_->avr ? impl_->avr->cycle : cycle_;
}

uint8_t AvrEngine::registre_simavr(uint16_t adresse) const {
    if (!impl_->avr || adresse >= impl_->avr->ramend) return 0;
    return impl_->avr->data[adresse];
}

void AvrEngine::niveau_simavr(int broche, bool haut) {
    if (!impl_->avr) return;
    const BrocheAvr cible = broche_avr(broche);
    avr_irq_t* irq = avr_io_getirq(impl_->avr,
                                   AVR_IOCTL_IOPORT_GETIRQ(cible.port),
                                   cible.bit);
    if (!irq) return;
    injection_ = true;                    // ne pas se notifier soi-même
    avr_raise_irq(irq, haut ? 1 : 0);
    injection_ = false;
}

#else   // ------------------------------------------------ sans simavr

struct AvrEngine::Impl {
    CoeurAvr coeur;
};

AvrEngine::AvrEngine() : impl_(new Impl) {}
AvrEngine::~AvrEngine() { delete impl_; }
bool AvrEngine::compile_avec_simavr() { return false; }

bool AvrEngine::charger_simavr(const std::string&, const std::string&, uint32_t) {
    return false;
}
uint64_t AvrEngine::avancer_simavr(uint64_t) { return 0; }
void AvrEngine::reinitialiser_simavr() {}
void AvrEngine::adc_simavr(int, double) {}
void AvrEngine::serie_simavr(uint8_t) {}
uint64_t AvrEngine::cycle_simavr() const { return cycle_; }
uint8_t AvrEngine::registre_simavr(uint16_t) const { return 0; }
void AvrEngine::niveau_simavr(int, bool) {}

#endif

// ---------------------------------------------------------------------------
// Façade : le cœur intégré par défaut, simavr sur demande
// ---------------------------------------------------------------------------
bool AvrEngine::disponible() const { return true; }
bool AvrEngine::utilise_simavr() const {
    return prefere_simavr_ && compile_avec_simavr();
}

bool AvrEngine::charger(const std::string& chemin, const std::string& mcu,
                        uint32_t frequence) {
    erreur_.clear();
    frequence_ = frequence;
    cycle_ = 0;
    etat_broches_.clear();
    sortie_broches_.clear();
    if (utilise_simavr()) return charger_simavr(chemin, mcu, frequence);

    impl_->coeur.definir_frequence(frequence);
    // Le cœur prévient à chaque changement de niveau ; on retraduit le port
    // et le bit en numéro de broche Arduino.
    impl_->coeur.sur_broche = [this](char port, int bit, bool haut) {
        int broche = -1;
        if (port == 'D' && bit <= 7) broche = bit;
        else if (port == 'B' && bit <= 5) broche = 8 + bit;
        else if (port == 'C' && bit <= 5) broche = 14 + bit;
        if (broche >= 0) _notifier_broche(broche, haut);
    };
    impl_->coeur.sur_serie = [this](uint8_t octet) {
        _notifier_serie(static_cast<char>(octet));
    };
    std::string message;
    if (!impl_->coeur.charger(chemin, &message)) {
        erreur_ = message;
        return false;
    }
    return true;
}

uint64_t AvrEngine::avancer(uint64_t cycles) {
    if (utilise_simavr()) return avancer_simavr(cycles);
    const uint64_t executes = impl_->coeur.executer(cycles);
    cycle_ = impl_->coeur.cycles();
    return executes;
}

void AvrEngine::reinitialiser() {
    if (utilise_simavr()) {
        reinitialiser_simavr();
        return;
    }
    impl_->coeur.reinitialiser();
    cycle_ = 0;
}

void AvrEngine::definir_tension_adc(int canal, double volts) {
    if (utilise_simavr()) {
        adc_simavr(canal, volts);
        return;
    }
    impl_->coeur.tension_adc(canal, volts);
}

void AvrEngine::envoyer_octet_serie(uint8_t octet) {
    if (utilise_simavr()) {
        serie_simavr(octet);
        return;
    }
    impl_->coeur.recevoir_serie(octet);
}

uint64_t AvrEngine::cycle() const {
    return utilise_simavr() ? cycle_simavr() : impl_->coeur.cycles();
}

uint8_t AvrEngine::registre(uint16_t adresse) const {
    return utilise_simavr() ? registre_simavr(adresse)
                            : impl_->coeur.lire_donnee(adresse);
}

void AvrEngine::definir_niveau_externe(int broche, bool haut) {
    if (utilise_simavr()) {
        niveau_simavr(broche, haut);
        return;
    }
    const BrocheAvr cible = broche_avr(broche);
    impl_->coeur.broche_externe(cible.port, cible.bit, haut);
}

bool AvrEngine::direction_sortie(int broche) const {
    // A6 et A7 (20, 21) n'existent que sur le Nano et la Pro Mini, et
    // seulement comme entrées de convertisseur : elles n'ont ni bit de
    // direction ni bascule de sortie. Toujours en entrée, donc.
    if (broche >= 20) return false;
    const BrocheAvr cible = broche_avr(broche);
    return (registre(adresse_ddr(cible.port)) >> cible.bit) & 1;
}

bool AvrEngine::niveau_port(int broche) const {
    if (broche >= 20) return false;
    const BrocheAvr cible = broche_avr(broche);
    return (registre(adresse_port(cible.port)) >> cible.bit) & 1;
}

bool AvrEngine::pullup_actif(int broche) const {
    return !direction_sortie(broche) && niveau_port(broche);
}

double AvrEngine::temps_ms() const {
    return frequence_ ? (cycle_ * 1000.0 / frequence_) : 0.0;
}

bool AvrEngine::broche_haute(int broche) const {
    auto it = etat_broches_.find(broche);
    return it != etat_broches_.end() && it->second;
}

bool AvrEngine::broche_en_sortie(int broche) const {
    auto it = sortie_broches_.find(broche);
    return it != sortie_broches_.end() && it->second;
}

void AvrEngine::_notifier_broche(int broche, bool haut) {
    if (injection_) return;           // c'est nous qui venons d'écrire
    etat_broches_[broche] = haut;
    sortie_broches_[broche] = true;   // une notification implique un pilotage
    if (rappel_broche_) rappel_broche_(broche, haut);
}

void AvrEngine::_notifier_serie(char octet) {
    if (rappel_serie_) rappel_serie_(octet);
}

// ---------------------------------------------------------------------------
// Compilation d'un sketch avec avr-gcc
// ---------------------------------------------------------------------------
bool AvrEngine::avr_gcc_disponible() {
    return std::system("avr-gcc --version > /dev/null 2>&1") == 0;
}

bool AvrEngine::compiler_source(const std::string& source,
                                const std::string& chemin_elf,
                                std::string* journal) {
    // Le programme est compilé en C++ avec le noyau Arduino à côté. Les deux
    // styles cohabitent : un croquis à setup()/loop() prend le main() faible
    // du noyau, un programme qui définit son propre main() l'emporte.
    const std::string dossier = chemin_elf.substr(0, chemin_elf.find_last_of('/'));
    const std::string base = chemin_elf + ".cpp";
    const std::string entete = dossier + "/Arduino.h";
    const std::string noyau = dossier + "/noyau_arduino.cpp";

    auto ecrire = [](const std::string& chemin, const std::string& contenu) {
        std::ofstream fichier(chemin);
        if (!fichier) return false;
        fichier << contenu;
        return true;
    };
    if (!ecrire(entete, kArduinoEnTete) || !ecrire(noyau, kArduinoCorps)) {
        if (journal) *journal = "écriture impossible dans " + dossier;
        return false;
    }
    // L'en-tête est inclus d'office : un croquis Arduino ne l'écrit jamais.
    if (!ecrire(base, "#include \"Arduino.h\"\n#line 1\n" + source)) {
        if (journal) *journal = "écriture impossible : " + base;
        return false;
    }

    const std::string journal_fichier = chemin_elf + ".log";
    const std::string commande =
        "avr-g++ -mmcu=atmega328p -DF_CPU=16000000UL -Os -std=gnu++17 "
        "-fno-exceptions -fno-threadsafe-statics -ffunction-sections "
        "-fdata-sections -Wl,--gc-sections -I \"" + dossier + "\" -o \"" +
        chemin_elf + "\" \"" + base + "\" \"" + noyau + "\" > \"" +
        journal_fichier + "\" 2>&1";
    const int code = std::system(commande.c_str());
    if (journal) {
        std::ifstream lecture(journal_fichier);
        std::string contenu((std::istreambuf_iterator<char>(lecture)),
                            std::istreambuf_iterator<char>());
        *journal = contenu;
    }
    return code == 0;
}

bool AvrEngine::avr_gpp_disponible() {
    return std::system("avr-g++ --version > /dev/null 2>&1") == 0;
}

}  // namespace coeur
