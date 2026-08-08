#include "core/engines/CoeurAvr.h"

#include <algorithm>
#include <cstring>
#include <fstream>
#include <sstream>

namespace coeur {

namespace {

// --- espace données de l'ATmega328P ---------------------------------------
constexpr uint16_t kPinB = 0x23, kDdrB = 0x24, kPortB = 0x25;
constexpr uint16_t kPinC = 0x26, kDdrC = 0x27, kPortC = 0x28;
constexpr uint16_t kPinD = 0x29, kDdrD = 0x2A, kPortD = 0x2B;
constexpr uint16_t kTifr0 = 0x35, kTifr1 = 0x36, kTifr2 = 0x37;
constexpr uint16_t kSpl = 0x5D, kSph = 0x5E, kSreg = 0x5F;
constexpr uint16_t kTccr0A = 0x44, kTccr0B = 0x45, kTcnt0 = 0x46;
constexpr uint16_t kOcr0A = 0x47, kOcr0B = 0x48;
constexpr uint16_t kTimsk0 = 0x6E, kTimsk1 = 0x6F, kTimsk2 = 0x70;
constexpr uint16_t kAdcl = 0x78, kAdch = 0x79, kAdcsra = 0x7A, kAdmux = 0x7C;
constexpr uint16_t kTccr1A = 0x80, kTccr1B = 0x81;
constexpr uint16_t kTcnt1L = 0x84, kTcnt1H = 0x85;
constexpr uint16_t kIcr1L = 0x86, kIcr1H = 0x87;
constexpr uint16_t kOcr1AL = 0x88, kOcr1AH = 0x89;
constexpr uint16_t kOcr1BL = 0x8A, kOcr1BH = 0x8B;
constexpr uint16_t kTccr2A = 0xB0, kTccr2B = 0xB1, kTcnt2 = 0xB2;
constexpr uint16_t kOcr2A = 0xB3, kOcr2B = 0xB4;
constexpr uint16_t kUcsr0A = 0xC0, kUcsr0B = 0xC1, kUdr0 = 0xC6;

constexpr uint16_t kFinRam = 0x08FF;

// Numéros de vecteur d'interruption (l'adresse vaut le numéro × 2 mots).
constexpr int kVecteurT2CompA = 7, kVecteurT2CompB = 8, kVecteurT2Ovf = 9;
constexpr int kVecteurT1CompA = 11, kVecteurT1CompB = 12, kVecteurT1Ovf = 13;
constexpr int kVecteurT0CompA = 14, kVecteurT0CompB = 15, kVecteurT0Ovf = 16;
constexpr int kVecteurUsartRx = 18;

// Drapeaux du registre d'état.
enum { kC = 0, kZ = 1, kN = 2, kV = 3, kS = 4, kH = 5, kT = 6, kI = 7 };

int diviseur_de(uint8_t selection) {
    switch (selection & 7) {
        case 0: return 0;         // arrêté
        case 1: return 1;
        case 2: return 8;
        case 3: return 64;
        case 4: return 256;
        case 5: return 1024;
        default: return 1;        // horloge externe : traitée comme /1
    }
}

// Le compteur 2 n'a pas le même tableau de prédiviseurs que les deux autres.
int diviseur_t2(uint8_t selection) {
    switch (selection & 7) {
        case 0: return 0;
        case 1: return 1;
        case 2: return 8;
        case 3: return 32;
        case 4: return 64;
        case 5: return 128;
        case 6: return 256;
        default: return 1024;
    }
}

uint32_t lire32(const unsigned char* octets) {
    return static_cast<uint32_t>(octets[0]) | (static_cast<uint32_t>(octets[1]) << 8)
           | (static_cast<uint32_t>(octets[2]) << 16)
           | (static_cast<uint32_t>(octets[3]) << 24);
}

uint16_t lire16(const unsigned char* octets) {
    return static_cast<uint16_t>(octets[0])
           | (static_cast<uint16_t>(octets[1]) << 8);
}

}  // namespace

CoeurAvr::CoeurAvr() { donnees_.assign(kFinRam + 1, 0); }

// ---------------------------------------------------------------------------
// Chargement du firmware
// ---------------------------------------------------------------------------
bool CoeurAvr::charger(const std::string& chemin, std::string* erreur) {
    std::ifstream fichier(chemin, std::ios::binary);
    if (!fichier) {
        if (erreur) *erreur = "fichier introuvable : " + chemin;
        return false;
    }
    std::vector<unsigned char> contenu((std::istreambuf_iterator<char>(fichier)),
                                       std::istreambuf_iterator<char>());
    if (contenu.size() < 4) {
        if (erreur) *erreur = "firmware vide : " + chemin;
        return false;
    }

    std::vector<uint8_t> image(32768, 0xFF);
    size_t taille_utile = 0;

    auto deposer = [&image, &taille_utile](size_t adresse, const unsigned char* source,
                                           size_t longueur) {
        for (size_t k = 0; k < longueur && adresse + k < image.size(); ++k)
            image[adresse + k] = source[k];
        taille_utile = std::max(taille_utile, adresse + longueur);
    };

    if (contenu[0] == 0x7F && contenu[1] == 'E' && contenu[2] == 'L'
        && contenu[3] == 'F') {
        // ELF 32 bits petit-boutiste : on ne lit que la table des segments.
        if (contenu.size() < 52) {
            if (erreur) *erreur = "en-tête ELF tronqué";
            return false;
        }
        const uint32_t debut_segments = lire32(&contenu[28]);
        const uint16_t taille_segment = lire16(&contenu[42]);
        const uint16_t nombre_segments = lire16(&contenu[44]);
        for (int k = 0; k < nombre_segments; ++k) {
            const size_t base = debut_segments + static_cast<size_t>(k) * taille_segment;
            if (base + 32 > contenu.size()) break;
            const uint32_t type = lire32(&contenu[base]);
            if (type != 1) continue;                 // PT_LOAD seulement
            const uint32_t decalage = lire32(&contenu[base + 4]);
            const uint32_t adresse_physique = lire32(&contenu[base + 12]);
            const uint32_t longueur = lire32(&contenu[base + 16]);
            if (longueur == 0) continue;
            // Les segments destinés à la RAM portent une adresse physique en
            // flash : c'est là que le programme va chercher ses données
            // initialisées, et c'est donc bien en flash qu'il faut les poser.
            if (adresse_physique >= 0x800000) continue;
            if (decalage + longueur > contenu.size()) continue;
            deposer(adresse_physique, &contenu[decalage], longueur);
        }
    } else {
        // Intel HEX.
        std::istringstream flux(std::string(contenu.begin(), contenu.end()));
        std::string ligne;
        uint32_t base_etendue = 0;
        while (std::getline(flux, ligne)) {
            if (ligne.size() < 11 || ligne[0] != ':') continue;
            auto octet_a = [&ligne](size_t position) {
                return static_cast<unsigned char>(
                    std::stoul(ligne.substr(position, 2), nullptr, 16));
            };
            const unsigned char nombre = octet_a(1);
            const uint16_t adresse = static_cast<uint16_t>(
                std::stoul(ligne.substr(3, 4), nullptr, 16));
            const unsigned char type = octet_a(7);
            if (type == 0x01) break;
            if (type == 0x04) {
                base_etendue = static_cast<uint32_t>(
                                   std::stoul(ligne.substr(9, 4), nullptr, 16))
                               << 16;
                continue;
            }
            if (type != 0x00) continue;
            std::vector<unsigned char> donnees;
            for (int k = 0; k < nombre; ++k) donnees.push_back(octet_a(9 + 2 * k));
            deposer(base_etendue + adresse, donnees.data(), donnees.size());
        }
    }

    if (taille_utile == 0) {
        if (erreur) *erreur = "aucun code trouvé dans " + chemin;
        return false;
    }
    flash_.assign(16384, 0xFFFF);
    for (size_t k = 0; k + 1 < image.size(); k += 2)
        flash_[k / 2] = static_cast<uint16_t>(image[k])
                        | (static_cast<uint16_t>(image[k + 1]) << 8);
    reinitialiser();
    return true;
}

void CoeurAvr::reinitialiser() {
    std::fill(donnees_.begin(), donnees_.end(), 0);
    pc_ = 0;
    cycles_ = 0;
    endormi_ = false;
    adc_restant_ = 0;
    serie_disponible_ = false;
    t0_ = t1_ = t2_ = Compteur{};
    sortie_valide_ = false;
    for (int port = 0; port < 3; ++port) {
        sortie_connue_[port] = 0;
        direction_connue_[port] = 0;
    }
    poser_pile(kFinRam);
    // L'UART annonce son registre d'émission libre dès le départ, comme la
    // puce au sortir d'un reset.
    donnees_[kUcsr0A] = 0x20;              // UDRE0
}

// ---------------------------------------------------------------------------
// Mémoire et périphériques
// ---------------------------------------------------------------------------
uint16_t CoeurAvr::pile() const {
    return static_cast<uint16_t>(donnees_[kSpl])
           | (static_cast<uint16_t>(donnees_[kSph]) << 8);
}

void CoeurAvr::poser_pile(uint16_t valeur) {
    donnees_[kSpl] = static_cast<uint8_t>(valeur);
    donnees_[kSph] = static_cast<uint8_t>(valeur >> 8);
}

void CoeurAvr::empiler(uint8_t valeur) {
    const uint16_t sommet = pile();
    if (sommet <= kFinRam) donnees_[sommet] = valeur;
    poser_pile(static_cast<uint16_t>(sommet - 1));
}

uint8_t CoeurAvr::depiler() {
    const uint16_t sommet = static_cast<uint16_t>(pile() + 1);
    poser_pile(sommet);
    return sommet <= kFinRam ? donnees_[sommet] : 0;
}

void CoeurAvr::poser_drapeau(int bit, bool actif) {
    if (actif)
        donnees_[kSreg] |= static_cast<uint8_t>(1 << bit);
    else
        donnees_[kSreg] &= static_cast<uint8_t>(~(1 << bit));
}

uint8_t CoeurAvr::niveau_broches(int port) const {
    // Ce que lit PINx : le niveau imposé de l'extérieur pour les entrées, la
    // valeur du registre de sortie pour les broches pilotées.
    static const uint16_t ddr[3] = {kDdrB, kDdrC, kDdrD};
    static const uint16_t sortie[3] = {kPortB, kPortC, kPortD};
    const uint8_t direction = donnees_[ddr[port]];
    return static_cast<uint8_t>((donnees_[sortie[port]] & direction)
                                | (entree_[port] & ~direction));
}

uint8_t CoeurAvr::lire_donnee(uint16_t adresse) const {
    if (adresse > kFinRam) return 0;
    switch (adresse) {
        case kPinB: return niveau_broches(0);
        case kPinC: return niveau_broches(1);
        case kPinD: return niveau_broches(2);
        default: return donnees_[adresse];
    }
}

uint8_t CoeurAvr::lire(uint16_t adresse) {
    if (adresse > kFinRam) return 0;
    switch (adresse) {
        case kPinB: return niveau_broches(0);
        case kPinC: return niveau_broches(1);
        case kPinD: return niveau_broches(2);
        case kUdr0: {
            const uint8_t octet_recu = serie_recue_;
            serie_disponible_ = false;
            donnees_[kUcsr0A] &= static_cast<uint8_t>(~0x80);   // RXC0
            return octet_recu;
        }
        default: return donnees_[adresse];
    }
}

void CoeurAvr::ecrire(uint16_t adresse, uint8_t valeur) {
    if (adresse > kFinRam) return;
    switch (adresse) {
        // Écrire dans PINx bascule les bits correspondants de PORTx : c'est
        // le raccourci des AVR récents, et avr-gcc s'en sert.
        case kPinB: donnees_[kPortB] ^= valeur; rafraichir_sorties(); return;
        case kPinC: donnees_[kPortC] ^= valeur; rafraichir_sorties(); return;
        case kPinD: donnees_[kPortD] ^= valeur; rafraichir_sorties(); return;
        case kTifr0:
        case kTifr1:
        case kTifr2:
            // Un drapeau d'interruption s'efface en y écrivant un « 1 ».
            donnees_[adresse] &= static_cast<uint8_t>(~valeur);
            return;
        case kUdr0:
            donnees_[adresse] = valeur;
            if (sur_serie) sur_serie(valeur);
            donnees_[kUcsr0A] |= 0x60;      // UDRE0 et TXC0
            return;
        case kAdcsra:
            donnees_[adresse] = valeur;
            if ((valeur & 0x40) && (valeur & 0x80)) demarrer_conversion();
            return;
        default: break;
    }
    donnees_[adresse] = valeur;
    if (adresse == kPortB || adresse == kDdrB || adresse == kPortC
        || adresse == kDdrC || adresse == kPortD || adresse == kDdrD
        || adresse == kTccr0A || adresse == kTccr0B || adresse == kOcr0A
        || adresse == kOcr0B || adresse == kTccr1A || adresse == kTccr1B
        || adresse == kTccr2A || adresse == kTccr2B || adresse == kOcr2A
        || adresse == kOcr2B)
        rafraichir_sorties();
}

void CoeurAvr::demarrer_conversion() {
    const int canal = donnees_[kAdmux] & 0x0F;
    const uint16_t mesure = canal < 8 ? adc_[canal] : 0;
    donnees_[kAdcl] = static_cast<uint8_t>(mesure & 0xFF);
    donnees_[kAdch] = static_cast<uint8_t>(mesure >> 8);
    // Une conversion dure treize périodes du convertisseur ; le programme
    // attend que ADSC retombe, il faut donc que cela prenne du temps.
    const int diviseur = 1 << std::max<int>(1, donnees_[kAdcsra] & 7);
    adc_restant_ = 13 * diviseur;
}

void CoeurAvr::broche_externe(char port, int bit, bool haut) {
    const int rang = port == 'B' ? 0 : (port == 'C' ? 1 : 2);
    if (bit < 0 || bit > 7) return;
    if (haut)
        entree_[rang] |= static_cast<uint8_t>(1 << bit);
    else
        entree_[rang] &= static_cast<uint8_t>(~(1 << bit));
}

void CoeurAvr::tension_adc(int canal, double volts) {
    if (canal < 0 || canal > 7) return;
    volts = std::max(0.0, std::min(5.0, volts));
    adc_[canal] = static_cast<uint16_t>(volts / 5.0 * 1023.0 + 0.5);
}

void CoeurAvr::recevoir_serie(uint8_t octet) {
    serie_recue_ = octet;
    serie_disponible_ = true;
    donnees_[kUcsr0A] |= 0x80;             // RXC0
}

// ---------------------------------------------------------------------------
// Sorties : ce que le circuit voit
// ---------------------------------------------------------------------------
void CoeurAvr::rafraichir_sorties() {
    static const uint16_t ddr[3] = {kDdrB, kDdrC, kDdrD};
    static const uint16_t sortie[3] = {kPortB, kPortC, kPortD};

    uint8_t niveaux[3];
    for (int port = 0; port < 3; ++port)
        niveaux[port] = static_cast<uint8_t>(donnees_[sortie[port]]
                                             & donnees_[ddr[port]]);

    // Les sorties de comparaison prennent la main sur le registre de port
    // quand le mode PWM est armé : c'est ce que fait `analogWrite`.
    auto pwm = [&](int port, int bit, bool actif, bool niveau) {
        if (!actif) return;
        if (!(donnees_[ddr[port]] & (1 << bit))) return;
        if (niveau)
            niveaux[port] |= static_cast<uint8_t>(1 << bit);
        else
            niveaux[port] &= static_cast<uint8_t>(~(1 << bit));
    };
    const bool t0_pwm = (donnees_[kTccr0A] & 0x03) != 0;   // WGM00/WGM01
    const uint8_t compte0 = static_cast<uint8_t>(t0_.compte);
    pwm(2, 6, t0_pwm && (donnees_[kTccr0A] & 0x80),
        compte0 < donnees_[kOcr0A]);                       // OC0A -> PD6
    pwm(2, 5, t0_pwm && (donnees_[kTccr0A] & 0x20),
        compte0 < donnees_[kOcr0B]);                       // OC0B -> PD5
    const bool t1_pwm = (donnees_[kTccr1A] & 0x03) != 0;
    const uint8_t compte1 = static_cast<uint8_t>(t1_.compte);
    pwm(0, 1, t1_pwm && (donnees_[kTccr1A] & 0x80),
        compte1 < donnees_[kOcr1AL]);                      // OC1A -> PB1
    pwm(0, 2, t1_pwm && (donnees_[kTccr1A] & 0x20),
        compte1 < donnees_[kOcr1BL]);                      // OC1B -> PB2
    const bool t2_pwm = (donnees_[kTccr2A] & 0x03) != 0;
    const uint8_t compte2 = static_cast<uint8_t>(t2_.compte);
    pwm(0, 3, t2_pwm && (donnees_[kTccr2A] & 0x80),
        compte2 < donnees_[kOcr2A]);                       // OC2A -> PB3
    pwm(2, 3, t2_pwm && (donnees_[kTccr2A] & 0x20),
        compte2 < donnees_[kOcr2B]);                       // OC2B -> PD3

    for (int port = 0; port < 3; ++port) {
        // Une broche qui devient une sortie annonce son niveau, même s'il
        // n'a pas changé : jusque-là elle ne pilotait rien, et le circuit
        // doit l'apprendre.
        const uint8_t direction = donnees_[ddr[port]];
        const uint8_t change = static_cast<uint8_t>(
            sortie_valide_ ? ((niveaux[port] ^ sortie_connue_[port])
                              | (direction & ~direction_connue_[port]))
                           : 0xFF);
        sortie_connue_[port] = niveaux[port];
        direction_connue_[port] = direction;
        if (!sur_broche) continue;
        for (int bit = 0; bit < 8; ++bit) {
            if (!(change & (1 << bit))) continue;
            if (!(donnees_[ddr[port]] & (1 << bit))) continue;
            sur_broche(port == 0 ? 'B' : (port == 1 ? 'C' : 'D'), bit,
                       (niveaux[port] >> bit) & 1);
        }
    }
    sortie_valide_ = true;
}

// ---------------------------------------------------------------------------
// Compteurs
// ---------------------------------------------------------------------------
void CoeurAvr::avancer_compteur(Compteur& compteur, int cycles, int numero) {
    const uint16_t registre_controle = numero == 0 ? kTccr0B
                                                   : (numero == 1 ? kTccr1B : kTccr2B);
    const uint8_t selection = donnees_[registre_controle] & 0x07;
    const int diviseur = numero == 2 ? diviseur_t2(selection)
                                     : diviseur_de(selection);
    compteur.diviseur = diviseur;
    if (diviseur == 0) return;

    const uint16_t drapeaux = numero == 0 ? kTifr0 : (numero == 1 ? kTifr1 : kTifr2);
    const uint16_t masques = numero == 0 ? kTimsk0 : (numero == 1 ? kTimsk1 : kTimsk2);
    const uint16_t compare_a = numero == 0 ? kOcr0A
                                           : (numero == 1 ? kOcr1AL : kOcr2A);
    const uint16_t compare_b = numero == 0 ? kOcr0B
                                           : (numero == 1 ? kOcr1BL : kOcr2B);
    const uint16_t compte_bas = numero == 0 ? kTcnt0
                                            : (numero == 1 ? kTcnt1L : kTcnt2);
    // Mode de génération : WGM10/WGM01 disent si le sommet est 0xFF.
    const uint16_t controle_a = numero == 0 ? kTccr0A
                                            : (numero == 1 ? kTccr1A : kTccr2A);
    const bool ctc = numero == 1
                         ? ((donnees_[kTccr1B] & 0x08) && !(donnees_[kTccr1A] & 0x01))
                         : ((donnees_[controle_a] & 0x03) == 0x02);
    const uint16_t sommet = ctc ? donnees_[compare_a] : 0xFF;

    compteur.reste += cycles;
    while (compteur.reste >= diviseur) {
        compteur.reste -= diviseur;
        const uint16_t avant = compteur.compte;
        uint16_t apres = static_cast<uint16_t>(avant + 1);
        if (apres > sommet) {
            apres = 0;
            if (!ctc) donnees_[drapeaux] |= 0x01;         // TOV
        }
        compteur.compte = apres;
        if (avant == donnees_[compare_a]) donnees_[drapeaux] |= 0x02;   // OCFA
        if (avant == donnees_[compare_b]) donnees_[drapeaux] |= 0x04;   // OCFB
    }
    donnees_[compte_bas] = static_cast<uint8_t>(compteur.compte);
    if (numero == 1) donnees_[kTcnt1H] = static_cast<uint8_t>(compteur.compte >> 8);
    (void)masques;
}

void CoeurAvr::avancer_peripheriques(int cycles) {
    avancer_compteur(t0_, cycles, 0);
    avancer_compteur(t1_, cycles, 1);
    avancer_compteur(t2_, cycles, 2);
    if (adc_restant_ > 0) {
        adc_restant_ -= cycles;
        if (adc_restant_ <= 0) {
            adc_restant_ = 0;
            donnees_[kAdcsra] &= static_cast<uint8_t>(~0x40);   // ADSC retombe
            donnees_[kAdcsra] |= 0x10;                          // ADIF
        }
    }
    rafraichir_sorties();
}

// ---------------------------------------------------------------------------
// Interruptions
// ---------------------------------------------------------------------------
void CoeurAvr::declencher(int vecteur) {
    empiler(static_cast<uint8_t>(pc_ & 0xFF));
    empiler(static_cast<uint8_t>((pc_ >> 8) & 0xFF));
    poser_drapeau(kI, false);
    pc_ = static_cast<uint32_t>(vecteur) * 2;
    cycles_ += 4;
    endormi_ = false;
}

bool CoeurAvr::servir_interruption() {
    if (!drapeau(kI)) return false;
    struct Source {
        uint16_t drapeaux, masques;
        uint8_t bit;
        int vecteur;
    };
    // L'ordre est celui des priorités : le vecteur le plus bas d'abord.
    static const Source sources[] = {
        {kTifr2, kTimsk2, 0x02, kVecteurT2CompA},
        {kTifr2, kTimsk2, 0x04, kVecteurT2CompB},
        {kTifr2, kTimsk2, 0x01, kVecteurT2Ovf},
        {kTifr1, kTimsk1, 0x02, kVecteurT1CompA},
        {kTifr1, kTimsk1, 0x04, kVecteurT1CompB},
        {kTifr1, kTimsk1, 0x01, kVecteurT1Ovf},
        {kTifr0, kTimsk0, 0x02, kVecteurT0CompA},
        {kTifr0, kTimsk0, 0x04, kVecteurT0CompB},
        {kTifr0, kTimsk0, 0x01, kVecteurT0Ovf},
    };
    for (const Source& source : sources) {
        if (!(donnees_[source.drapeaux] & source.bit)) continue;
        if (!(donnees_[source.masques] & source.bit)) continue;
        donnees_[source.drapeaux] &= static_cast<uint8_t>(~source.bit);
        declencher(source.vecteur);
        return true;
    }
    // Réception série : le drapeau vit dans UCSR0A, l'autorisation dans B.
    if ((donnees_[kUcsr0A] & 0x80) && (donnees_[kUcsr0B] & 0x80)) {
        declencher(kVecteurUsartRx);
        return true;
    }
    return false;
}

// ---------------------------------------------------------------------------
// Exécution
// ---------------------------------------------------------------------------
uint64_t CoeurAvr::executer(uint64_t cycles) {
    if (flash_.empty()) return 0;
    const uint64_t depart = cycles_;
    const uint64_t but = depart + cycles;
    while (cycles_ < but) {
        servir_interruption();
        const uint64_t avant = cycles_;
        if (endormi_) {
            cycles_ += 1;
        } else {
            cycles_ += instruction();
        }
        avancer_peripheriques(static_cast<int>(cycles_ - avant));
    }
    return cycles_ - depart;
}

int CoeurAvr::instruction() {
    if (pc_ >= flash_.size()) {
        pc_ = 0;
        return 1;
    }
    const uint16_t code = flash_[pc_++];

    auto d5 = [code] { return (code >> 4) & 0x1F; };
    auto r5 = [code] { return ((code & 0x0F) | ((code >> 5) & 0x10)); };
    auto d4 = [code] { return 16 + ((code >> 4) & 0x0F); };
    auto k8 = [code] { return ((code >> 4) & 0xF0) | (code & 0x0F); };

    auto zero_negatif = [this](uint8_t resultat) {
        poser_drapeau(kZ, resultat == 0);
        poser_drapeau(kN, (resultat & 0x80) != 0);
    };
    auto signe = [this] {
        poser_drapeau(kS, drapeau(kN) != drapeau(kV));
    };

    // --- addition et soustraction, avec tous les drapeaux
    auto addition = [&](int rang_d, uint8_t valeur, bool avec_retenue) {
        const uint8_t a = reg(rang_d);
        const unsigned entree = avec_retenue && drapeau(kC) ? 1u : 0u;
        const unsigned somme = a + valeur + entree;
        const uint8_t resultat = static_cast<uint8_t>(somme);
        poser_drapeau(kH, ((a & 0xF) + (valeur & 0xF) + entree) > 0xF);
        poser_drapeau(kC, somme > 0xFF);
        poser_drapeau(kV, (~(a ^ valeur) & (a ^ resultat) & 0x80) != 0);
        zero_negatif(resultat);
        signe();
        poser_reg(rang_d, resultat);
    };
    auto soustraction = [&](uint8_t a, uint8_t valeur, bool avec_retenue,
                            bool garder_zero) {
        const unsigned sortie = avec_retenue && drapeau(kC) ? 1u : 0u;
        const unsigned difference = a - valeur - sortie;
        const uint8_t resultat = static_cast<uint8_t>(difference);
        poser_drapeau(kH, ((a & 0xF) - (valeur & 0xF) - sortie) & 0x10);
        poser_drapeau(kC, difference > 0xFF);
        poser_drapeau(kV, ((a ^ valeur) & (a ^ resultat) & 0x80) != 0);
        poser_drapeau(kN, (resultat & 0x80) != 0);
        // Pour SBC et CPC, le zéro ne s'allume que si les deux octets sont
        // nuls : c'est ainsi qu'une comparaison sur seize bits fonctionne.
        if (garder_zero)
            poser_drapeau(kZ, resultat == 0 && drapeau(kZ));
        else
            poser_drapeau(kZ, resultat == 0);
        signe();
        return resultat;
    };
    auto logique = [&](int rang_d, uint8_t resultat) {
        poser_drapeau(kV, false);
        zero_negatif(resultat);
        signe();
        poser_reg(rang_d, resultat);
    };

    switch (code & 0xF000) {
        case 0x0000:
            if (code == 0x0000) return 1;                       // NOP
            if ((code & 0xFF00) == 0x0100) {                    // MOVW
                const int destination = ((code >> 4) & 0x0F) * 2;
                const int source = (code & 0x0F) * 2;
                poser_reg(destination, reg(source));
                poser_reg(destination + 1, reg(source + 1));
                return 1;
            }
            if ((code & 0xFF00) == 0x0200) {                    // MULS
                const int16_t produit =
                    static_cast<int8_t>(reg(16 + ((code >> 4) & 0x0F)))
                    * static_cast<int8_t>(reg(16 + (code & 0x0F)));
                poser_paire(0, static_cast<uint16_t>(produit));
                poser_drapeau(kC, (produit & 0x8000) != 0);
                poser_drapeau(kZ, produit == 0);
                return 2;
            }
            if ((code & 0xFF88) == 0x0300) {                    // MULSU
                const int16_t produit =
                    static_cast<int8_t>(reg(16 + ((code >> 4) & 0x07)))
                    * static_cast<int>(reg(16 + (code & 0x07)));
                poser_paire(0, static_cast<uint16_t>(produit));
                poser_drapeau(kC, (produit & 0x8000) != 0);
                poser_drapeau(kZ, produit == 0);
                return 2;
            }
            if ((code & 0xFF88) == 0x0308 || (code & 0xFF88) == 0x0380
                || (code & 0xFF88) == 0x0388) {                 // FMUL(S)(U)
                const uint16_t produit = static_cast<uint16_t>(
                    reg(16 + ((code >> 4) & 0x07)) * reg(16 + (code & 0x07)));
                poser_paire(0, static_cast<uint16_t>(produit << 1));
                poser_drapeau(kC, (produit & 0x8000) != 0);
                poser_drapeau(kZ, (produit << 1) == 0);
                return 2;
            }
            if ((code & 0xFC00) == 0x0400) {                    // CPC
                soustraction(reg(d5()), reg(r5()), true, true);
                return 1;
            }
            if ((code & 0xFC00) == 0x0800) {                    // SBC
                poser_reg(d5(), soustraction(reg(d5()), reg(r5()), true, true));
                return 1;
            }
            if ((code & 0xFC00) == 0x0C00) {                    // ADD
                addition(d5(), reg(r5()), false);
                return 1;
            }
            break;

        case 0x1000:
            if ((code & 0xFC00) == 0x1000) {                    // CPSE
                if (reg(d5()) == reg(r5())) {
                    const uint16_t suivant = flash_[pc_];
                    const bool longue = (suivant & 0xFC0F) == 0x9000
                                        || (suivant & 0xFE0C) == 0x940C;
                    pc_ += longue ? 2 : 1;
                    return longue ? 3 : 2;
                }
                return 1;
            }
            if ((code & 0xFC00) == 0x1400) {                    // CP
                soustraction(reg(d5()), reg(r5()), false, false);
                return 1;
            }
            if ((code & 0xFC00) == 0x1800) {                    // SUB
                poser_reg(d5(), soustraction(reg(d5()), reg(r5()), false, false));
                return 1;
            }
            if ((code & 0xFC00) == 0x1C00) {                    // ADC
                addition(d5(), reg(r5()), true);
                return 1;
            }
            break;

        case 0x2000:
            if ((code & 0xFC00) == 0x2000) {                    // AND
                logique(d5(), reg(d5()) & reg(r5()));
                return 1;
            }
            if ((code & 0xFC00) == 0x2400) {                    // EOR
                logique(d5(), reg(d5()) ^ reg(r5()));
                return 1;
            }
            if ((code & 0xFC00) == 0x2800) {                    // OR
                logique(d5(), reg(d5()) | reg(r5()));
                return 1;
            }
            if ((code & 0xFC00) == 0x2C00) {                    // MOV
                poser_reg(d5(), reg(r5()));
                return 1;
            }
            break;

        case 0x3000:                                            // CPI
            soustraction(reg(d4()), static_cast<uint8_t>(k8()), false, false);
            return 1;
        case 0x4000:                                            // SBCI
            poser_reg(d4(), soustraction(reg(d4()), static_cast<uint8_t>(k8()),
                                         true, true));
            return 1;
        case 0x5000:                                            // SUBI
            poser_reg(d4(), soustraction(reg(d4()), static_cast<uint8_t>(k8()),
                                         false, false));
            return 1;
        case 0x6000:                                            // ORI
            logique(d4(), reg(d4()) | static_cast<uint8_t>(k8()));
            return 1;
        case 0x7000:                                            // ANDI
            logique(d4(), reg(d4()) & static_cast<uint8_t>(k8()));
            return 1;

        case 0x8000:
        case 0xA000: {                                          // LDD / STD
            const int deplacement = (code & 0x07) | ((code >> 7) & 0x18)
                                    | ((code >> 8) & 0x20);
            const int rang = d5();
            const bool avec_y = (code & 0x0008) != 0;
            const uint16_t base = lire_paire(avec_y ? 28 : 30);
            if (code & 0x0200) {                                // ST
                ecrire(static_cast<uint16_t>(base + deplacement), reg(rang));
            } else {                                            // LD
                poser_reg(rang, lire(static_cast<uint16_t>(base + deplacement)));
            }
            return 2;
        }

        case 0x9000: {
            if ((code & 0xFE0F) == 0x9000) {                    // LDS
                const uint16_t adresse = flash_[pc_++];
                poser_reg(d5(), lire(adresse));
                return 2;
            }
            if ((code & 0xFE0F) == 0x9200) {                    // STS
                const uint16_t adresse = flash_[pc_++];
                ecrire(adresse, reg(d5()));
                return 2;
            }
            if ((code & 0xFE00) == 0x9000) {                    // LD*/POP/LPM
                const int rang = d5();
                switch (code & 0x000F) {
                    case 0x1: {                                 // LD Rd, Z+
                        const uint16_t z = lire_paire(30);
                        poser_reg(rang, lire(z));
                        poser_paire(30, static_cast<uint16_t>(z + 1));
                        return 2;
                    }
                    case 0x2: {                                 // LD Rd, -Z
                        const uint16_t z = static_cast<uint16_t>(lire_paire(30) - 1);
                        poser_paire(30, z);
                        poser_reg(rang, lire(z));
                        return 2;
                    }
                    case 0x4:                                   // LPM Rd, Z
                    case 0x5: {                                 // LPM Rd, Z+
                        const uint16_t z = lire_paire(30);
                        const uint16_t mot = (z / 2) < flash_.size()
                                                 ? flash_[z / 2]
                                                 : 0xFFFF;
                        poser_reg(rang, static_cast<uint8_t>((z & 1) ? (mot >> 8)
                                                                    : mot));
                        if ((code & 0x000F) == 0x5)
                            poser_paire(30, static_cast<uint16_t>(z + 1));
                        return 3;
                    }
                    case 0x9: {                                 // LD Rd, Y+
                        const uint16_t y = lire_paire(28);
                        poser_reg(rang, lire(y));
                        poser_paire(28, static_cast<uint16_t>(y + 1));
                        return 2;
                    }
                    case 0xA: {                                 // LD Rd, -Y
                        const uint16_t y = static_cast<uint16_t>(lire_paire(28) - 1);
                        poser_paire(28, y);
                        poser_reg(rang, lire(y));
                        return 2;
                    }
                    case 0xC:                                   // LD Rd, X
                        poser_reg(rang, lire(lire_paire(26)));
                        return 2;
                    case 0xD: {                                 // LD Rd, X+
                        const uint16_t x = lire_paire(26);
                        poser_reg(rang, lire(x));
                        poser_paire(26, static_cast<uint16_t>(x + 1));
                        return 2;
                    }
                    case 0xE: {                                 // LD Rd, -X
                        const uint16_t x = static_cast<uint16_t>(lire_paire(26) - 1);
                        poser_paire(26, x);
                        poser_reg(rang, lire(x));
                        return 2;
                    }
                    case 0xF:                                   // POP
                        poser_reg(rang, depiler());
                        return 2;
                    default: return 1;
                }
            }
            if ((code & 0xFE00) == 0x9200) {                    // ST*/PUSH
                const int rang = d5();
                switch (code & 0x000F) {
                    case 0x1: {                                 // ST Z+, Rr
                        const uint16_t z = lire_paire(30);
                        ecrire(z, reg(rang));
                        poser_paire(30, static_cast<uint16_t>(z + 1));
                        return 2;
                    }
                    case 0x2: {                                 // ST -Z, Rr
                        const uint16_t z = static_cast<uint16_t>(lire_paire(30) - 1);
                        poser_paire(30, z);
                        ecrire(z, reg(rang));
                        return 2;
                    }
                    case 0x9: {                                 // ST Y+, Rr
                        const uint16_t y = lire_paire(28);
                        ecrire(y, reg(rang));
                        poser_paire(28, static_cast<uint16_t>(y + 1));
                        return 2;
                    }
                    case 0xA: {                                 // ST -Y, Rr
                        const uint16_t y = static_cast<uint16_t>(lire_paire(28) - 1);
                        poser_paire(28, y);
                        ecrire(y, reg(rang));
                        return 2;
                    }
                    case 0xC:                                   // ST X, Rr
                        ecrire(lire_paire(26), reg(rang));
                        return 2;
                    case 0xD: {                                 // ST X+, Rr
                        const uint16_t x = lire_paire(26);
                        ecrire(x, reg(rang));
                        poser_paire(26, static_cast<uint16_t>(x + 1));
                        return 2;
                    }
                    case 0xE: {                                 // ST -X, Rr
                        const uint16_t x = static_cast<uint16_t>(lire_paire(26) - 1);
                        poser_paire(26, x);
                        ecrire(x, reg(rang));
                        return 2;
                    }
                    case 0xF:                                   // PUSH
                        empiler(reg(rang));
                        return 2;
                    default: return 1;
                }
            }
            if ((code & 0xFE0F) == 0x9400 || (code & 0xFE0F) == 0x9401
                || (code & 0xFE0F) == 0x9402 || (code & 0xFE0F) == 0x9403
                || (code & 0xFE0F) == 0x9405 || (code & 0xFE0F) == 0x9406
                || (code & 0xFE0F) == 0x9407 || (code & 0xFE0F) == 0x940A) {
                const int rang = d5();
                const uint8_t valeur = reg(rang);
                switch (code & 0x000F) {
                    case 0x0: {                                 // COM
                        const uint8_t resultat = static_cast<uint8_t>(~valeur);
                        poser_drapeau(kC, true);
                        logique(rang, resultat);
                        return 1;
                    }
                    case 0x1: {                                 // NEG
                        const uint8_t resultat = static_cast<uint8_t>(0 - valeur);
                        poser_drapeau(kC, resultat != 0);
                        poser_drapeau(kV, resultat == 0x80);
                        poser_drapeau(kH, ((resultat | valeur) & 0x08) != 0);
                        zero_negatif(resultat);
                        signe();
                        poser_reg(rang, resultat);
                        return 1;
                    }
                    case 0x2:                                   // SWAP
                        poser_reg(rang, static_cast<uint8_t>((valeur >> 4)
                                                             | (valeur << 4)));
                        return 1;
                    case 0x3: {                                 // INC
                        const uint8_t resultat = static_cast<uint8_t>(valeur + 1);
                        poser_drapeau(kV, valeur == 0x7F);
                        zero_negatif(resultat);
                        signe();
                        poser_reg(rang, resultat);
                        return 1;
                    }
                    case 0x5: {                                 // ASR
                        const uint8_t resultat =
                            static_cast<uint8_t>((valeur >> 1) | (valeur & 0x80));
                        poser_drapeau(kC, valeur & 1);
                        zero_negatif(resultat);
                        poser_drapeau(kV, drapeau(kN) != drapeau(kC));
                        signe();
                        poser_reg(rang, resultat);
                        return 1;
                    }
                    case 0x6: {                                 // LSR
                        const uint8_t resultat = static_cast<uint8_t>(valeur >> 1);
                        poser_drapeau(kC, valeur & 1);
                        poser_drapeau(kN, false);
                        poser_drapeau(kZ, resultat == 0);
                        poser_drapeau(kV, drapeau(kC));
                        signe();
                        poser_reg(rang, resultat);
                        return 1;
                    }
                    case 0x7: {                                 // ROR
                        const uint8_t resultat = static_cast<uint8_t>(
                            (valeur >> 1) | (drapeau(kC) ? 0x80 : 0));
                        poser_drapeau(kC, valeur & 1);
                        zero_negatif(resultat);
                        poser_drapeau(kV, drapeau(kN) != drapeau(kC));
                        signe();
                        poser_reg(rang, resultat);
                        return 1;
                    }
                    case 0xA: {                                 // DEC
                        const uint8_t resultat = static_cast<uint8_t>(valeur - 1);
                        poser_drapeau(kV, valeur == 0x80);
                        zero_negatif(resultat);
                        signe();
                        poser_reg(rang, resultat);
                        return 1;
                    }
                    default: return 1;
                }
            }
            if ((code & 0xFF0F) == 0x9408) {                    // BSET / BCLR
                const int bit = (code >> 4) & 0x07;
                poser_drapeau(bit, ((code >> 7) & 1) == 0);
                return 1;
            }
            if (code == 0x9409 || code == 0x9419) {             // IJMP / EIJMP
                pc_ = lire_paire(30);
                return 2;
            }
            if (code == 0x9509 || code == 0x9519) {             // ICALL
                empiler(static_cast<uint8_t>(pc_ & 0xFF));
                empiler(static_cast<uint8_t>((pc_ >> 8) & 0xFF));
                pc_ = lire_paire(30);
                return 3;
            }
            if (code == 0x9508 || code == 0x9518) {             // RET / RETI
                const uint8_t haut = depiler();
                const uint8_t bas = depiler();
                pc_ = (static_cast<uint32_t>(haut) << 8) | bas;
                if (code == 0x9518) poser_drapeau(kI, true);
                return 4;
            }
            if (code == 0x9588) { endormi_ = true; return 1; }  // SLEEP
            if (code == 0x95A8) return 1;                       // WDR
            if (code == 0x95C8) {                               // LPM R0, Z
                const uint16_t z = lire_paire(30);
                const uint16_t mot = (z / 2) < flash_.size() ? flash_[z / 2] : 0xFFFF;
                poser_reg(0, static_cast<uint8_t>((z & 1) ? (mot >> 8) : mot));
                return 3;
            }
            if (code == 0x9598) return 1;                       // BREAK
            if ((code & 0xFE0E) == 0x940C) {                    // JMP
                const uint32_t haut = ((code >> 3) & 0x3E) | (code & 0x01);
                const uint16_t bas = flash_[pc_++];
                pc_ = (haut << 16) | bas;
                return 3;
            }
            if ((code & 0xFE0E) == 0x940E) {                    // CALL
                const uint32_t haut = ((code >> 3) & 0x3E) | (code & 0x01);
                const uint16_t bas = flash_[pc_++];
                empiler(static_cast<uint8_t>(pc_ & 0xFF));
                empiler(static_cast<uint8_t>((pc_ >> 8) & 0xFF));
                pc_ = (haut << 16) | bas;
                return 4;
            }
            if ((code & 0xFF00) == 0x9600) {                    // ADIW
                const int rang = 24 + ((code >> 3) & 0x06);
                const uint16_t valeur = lire_paire(rang);
                const uint16_t constante = static_cast<uint16_t>(
                    ((code >> 2) & 0x30) | (code & 0x0F));
                const uint32_t somme = valeur + constante;
                poser_paire(rang, static_cast<uint16_t>(somme));
                poser_drapeau(kC, somme > 0xFFFF);
                poser_drapeau(kZ, (somme & 0xFFFF) == 0);
                poser_drapeau(kN, (somme & 0x8000) != 0);
                poser_drapeau(kV, (~valeur & static_cast<uint16_t>(somme) & 0x8000) != 0);
                signe();
                return 2;
            }
            if ((code & 0xFF00) == 0x9700) {                    // SBIW
                const int rang = 24 + ((code >> 3) & 0x06);
                const uint16_t valeur = lire_paire(rang);
                const uint16_t constante = static_cast<uint16_t>(
                    ((code >> 2) & 0x30) | (code & 0x0F));
                const uint32_t difference = valeur - constante;
                poser_paire(rang, static_cast<uint16_t>(difference));
                poser_drapeau(kC, difference > 0xFFFF);
                poser_drapeau(kZ, (difference & 0xFFFF) == 0);
                poser_drapeau(kN, (difference & 0x8000) != 0);
                poser_drapeau(kV, (valeur & ~static_cast<uint16_t>(difference)
                                   & 0x8000) != 0);
                signe();
                return 2;
            }
            if ((code & 0xFF00) == 0x9800 || (code & 0xFF00) == 0x9A00) {
                // CBI / SBI
                const uint16_t adresse = 0x20 + ((code >> 3) & 0x1F);
                const uint8_t masque = static_cast<uint8_t>(1 << (code & 0x07));
                uint8_t valeur = lire(adresse);
                if ((code & 0xFF00) == 0x9A00)
                    valeur |= masque;
                else
                    valeur &= static_cast<uint8_t>(~masque);
                ecrire(adresse, valeur);
                return 2;
            }
            if ((code & 0xFF00) == 0x9900 || (code & 0xFF00) == 0x9B00) {
                // SBIC / SBIS
                const uint16_t adresse = 0x20 + ((code >> 3) & 0x1F);
                const bool bit = (lire(adresse) >> (code & 0x07)) & 1;
                const bool saute = ((code & 0xFF00) == 0x9B00) ? bit : !bit;
                if (!saute) return 1;
                const uint16_t suivant = flash_[pc_];
                const bool longue = (suivant & 0xFC0F) == 0x9000
                                    || (suivant & 0xFE0C) == 0x940C;
                pc_ += longue ? 2 : 1;
                return longue ? 3 : 2;
            }
            if ((code & 0xFC00) == 0x9C00) {                    // MUL
                const uint16_t produit = static_cast<uint16_t>(reg(d5()) * reg(r5()));
                poser_paire(0, produit);
                poser_drapeau(kC, (produit & 0x8000) != 0);
                poser_drapeau(kZ, produit == 0);
                return 2;
            }
            break;
        }

        case 0xB000: {
            const uint16_t adresse = 0x20 + (((code >> 5) & 0x30) | (code & 0x0F));
            if (code & 0x0800)                                  // OUT
                ecrire(adresse, reg(d5()));
            else                                                // IN
                poser_reg(d5(), lire(adresse));
            return 1;
        }

        case 0xC000: {                                          // RJMP
            int16_t decalage = static_cast<int16_t>(code << 4) >> 4;
            pc_ = static_cast<uint32_t>(pc_ + decalage);
            return 2;
        }
        case 0xD000: {                                          // RCALL
            int16_t decalage = static_cast<int16_t>(code << 4) >> 4;
            empiler(static_cast<uint8_t>(pc_ & 0xFF));
            empiler(static_cast<uint8_t>((pc_ >> 8) & 0xFF));
            pc_ = static_cast<uint32_t>(pc_ + decalage);
            return 3;
        }
        case 0xE000:                                            // LDI
            poser_reg(d4(), static_cast<uint8_t>(k8()));
            return 1;

        case 0xF000: {
            if ((code & 0xF800) == 0xF000) {                    // BRBS / BRBC
                const int bit = code & 0x07;
                const bool vise = (code & 0x0400) == 0;
                int8_t decalage = static_cast<int8_t>((code >> 3) & 0x7F);
                if (decalage & 0x40) decalage = static_cast<int8_t>(decalage | 0x80);
                if (drapeau(bit) == vise) {
                    pc_ = static_cast<uint32_t>(pc_ + decalage);
                    return 2;
                }
                return 1;
            }
            if ((code & 0xFE08) == 0xF800) {                    // BLD
                const uint8_t masque = static_cast<uint8_t>(1 << (code & 0x07));
                uint8_t valeur = reg(d5());
                if (drapeau(kT))
                    valeur |= masque;
                else
                    valeur &= static_cast<uint8_t>(~masque);
                poser_reg(d5(), valeur);
                return 1;
            }
            if ((code & 0xFE08) == 0xFA00) {                    // BST
                poser_drapeau(kT, (reg(d5()) >> (code & 0x07)) & 1);
                return 1;
            }
            if ((code & 0xFC08) == 0xFC00) {                    // SBRC / SBRS
                const bool bit = (reg(d5()) >> (code & 0x07)) & 1;
                const bool saute = (code & 0x0200) ? bit : !bit;
                if (!saute) return 1;
                const uint16_t suivant = flash_[pc_];
                const bool longue = (suivant & 0xFC0F) == 0x9000
                                    || (suivant & 0xFE0C) == 0x940C;
                pc_ += longue ? 2 : 1;
                return longue ? 3 : 2;
            }
            break;
        }
        default: break;
    }
    return 1;    // instruction non reconnue : traitée comme un NOP
}

}  // namespace coeur
