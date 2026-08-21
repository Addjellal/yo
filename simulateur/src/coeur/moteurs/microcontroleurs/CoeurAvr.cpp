#include "coeur/moteurs/microcontroleurs/CoeurAvr.h"

#include <algorithm>
#include <cstring>
#include <fstream>
#include <sstream>

namespace coeur {

namespace {

// Extension de signe sûre : décaler dans un type signé jusqu'au débordement
// est un comportement indéfini, et le compilateur a le droit d'en faire ce
// qu'il veut.
inline int32_t etendre_signe_avr(uint32_t valeur, int bits) {
    const uint32_t masque = 1u << (bits - 1);
    valeur &= (1u << bits) - 1u;
    return static_cast<int32_t>((valeur ^ masque) - masque);
}

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


// ---------------------------------------------------------------------------
// Les puces
// ---------------------------------------------------------------------------
const ProfilAvr& profil_atmega328p() {
    static const ProfilAvr profil = [] {
        ProfilAvr p;
        p.nom = "atmega328p";
        p.fin_ram = 0x08FF;                // 2 Ko de SRAM
        p.flash_mots = 16384;              // 32 Ko de programme
        p.mots_par_vecteur = 2;            // vecteurs en JMP
        p.nb_ports = 3;
        p.pin[0] = 0x23; p.ddr[0] = 0x24; p.port[0] = 0x25;   // B
        p.pin[1] = 0x26; p.ddr[1] = 0x27; p.port[1] = 0x28;   // C
        p.pin[2] = 0x29; p.ddr[2] = 0x2A; p.port[2] = 0x2B;   // D
        p.spl = 0x5D; p.sph = 0x5E; p.sreg = 0x5F;
        p.adcl = 0x78; p.adch = 0x79; p.adcsra = 0x7A; p.admux = 0x7C;
        p.canaux_adc = 8;
        p.ucsra = 0xC0; p.ucsrb = 0xC1; p.udr = 0xC6;
        p.vecteur_usart_rx = 18;

        ProfilAvr::ProfilCompteur& t0 = p.compteurs[0];
        t0.present = true;
        t0.controle_a = 0x44; t0.controle_b = 0x45; t0.compte = 0x46;
        t0.compare_a = 0x47; t0.compare_b = 0x48;
        t0.drapeaux = 0x35; t0.masques = 0x6E;
        t0.vecteur_compa = 14; t0.vecteur_compb = 15; t0.vecteur_ovf = 16;
        t0.port_a = 2; t0.bit_a = 6;        // OC0A -> PD6
        t0.port_b = 2; t0.bit_b = 5;        // OC0B -> PD5

        ProfilAvr::ProfilCompteur& t1 = p.compteurs[1];
        t1.present = true;
        t1.controle_a = 0x80; t1.controle_b = 0x81;
        t1.compte = 0x84; t1.compte_haut = 0x85;
        t1.compare_a = 0x88; t1.compare_b = 0x8A;
        t1.drapeaux = 0x36; t1.masques = 0x6F;
        t1.vecteur_compa = 11; t1.vecteur_compb = 12; t1.vecteur_ovf = 13;
        t1.port_a = 0; t1.bit_a = 1;        // OC1A -> PB1
        t1.port_b = 0; t1.bit_b = 2;        // OC1B -> PB2

        ProfilAvr::ProfilCompteur& t2 = p.compteurs[2];
        t2.present = true;
        t2.controle_a = 0xB0; t2.controle_b = 0xB1; t2.compte = 0xB2;
        t2.compare_a = 0xB3; t2.compare_b = 0xB4;
        t2.drapeaux = 0x37; t2.masques = 0x70;
        t2.vecteur_compa = 7; t2.vecteur_compb = 8; t2.vecteur_ovf = 9;
        t2.prediviseur = 1;                // son tableau à lui
        t2.port_a = 0; t2.bit_a = 3;        // OC2A -> PB3
        t2.port_b = 2; t2.bit_b = 3;        // OC2B -> PD3
        return p;
    }();
    return profil;
}

const ProfilAvr& profil_attiny85() {
    static const ProfilAvr profil = [] {
        ProfilAvr p;
        p.nom = "attiny85";
        p.fin_ram = 0x025F;                // 512 octets de SRAM
        p.flash_mots = 4096;               // 8 Ko de programme
        // Huit kilo-octets de programme : le tableau de vecteurs tient en
        // RJMP, un mot par vecteur. Se tromper là-dessus enverrait chaque
        // interruption au milieu du code voisin.
        p.mots_par_vecteur = 1;
        p.nb_ports = 1;                    // un seul port, B
        p.pin[0] = 0x36; p.ddr[0] = 0x37; p.port[0] = 0x38;
        p.pin[1] = p.ddr[1] = p.port[1] = ProfilAvr::kAbsent;
        p.pin[2] = p.ddr[2] = p.port[2] = ProfilAvr::kAbsent;
        p.spl = 0x5D; p.sph = 0x5E; p.sreg = 0x5F;
        p.adcl = 0x24; p.adch = 0x25; p.adcsra = 0x26; p.admux = 0x27;
        p.canaux_adc = 4;                  // ADC0..ADC3
        // Pas d'UART : cette puce n'en a pas. Serial.print n'y compile même
        // pas — il ne faut donc surtout pas faire semblant.
        p.ucsra = p.ucsrb = p.udr = ProfilAvr::kAbsent;
        p.vecteur_usart_rx = -1;

        // TIMSK et TIFR sont uniques et partagés par les deux compteurs ;
        // seules les positions des bits les distinguent.
        ProfilAvr::ProfilCompteur& t0 = p.compteurs[0];
        t0.present = true;
        t0.controle_a = 0x4A; t0.controle_b = 0x53; t0.compte = 0x52;
        t0.compare_a = 0x49; t0.compare_b = 0x48;
        t0.drapeaux = 0x58; t0.masques = 0x59;
        t0.bit_tov = 0x02; t0.bit_ocfa = 0x10; t0.bit_ocfb = 0x08;
        t0.vecteur_ovf = 5; t0.vecteur_compa = 10; t0.vecteur_compb = 11;
        t0.port_a = 0; t0.bit_a = 0;        // OC0A -> PB0
        t0.port_b = 0; t0.bit_b = 1;        // OC0B -> PB1

        ProfilAvr::ProfilCompteur& t1 = p.compteurs[1];
        t1.present = true;
        // Le compteur 1 de l'ATtiny n'a qu'un registre de commande, un
        // prédiviseur sur quatre bits, et son sommet dans OCR1C.
        t1.controle_a = 0x50; t1.controle_b = 0x50; t1.compte = 0x4F;
        t1.compare_a = 0x4E; t1.compare_b = 0x4C; t1.sommet = 0x4D;
        t1.drapeaux = 0x58; t1.masques = 0x59;
        t1.bit_tov = 0x04; t1.bit_ocfa = 0x40; t1.bit_ocfb = 0x20;
        t1.vecteur_compa = 3; t1.vecteur_ovf = 4; t1.vecteur_compb = 9;
        t1.prediviseur = 2;
        t1.port_a = 0; t1.bit_a = 1;        // OC1A -> PB1
        t1.port_b = 0; t1.bit_b = 4;        // OC1B -> PB4

        p.compteurs[2].present = false;     // il n'y a pas de compteur 2
        p.nb_compteurs = 2;
        return p;
    }();
    return profil;
}

const ProfilAvr& profil_atmega2560() {
    static const ProfilAvr profil = [] {
        ProfilAvr p;
        p.nom = "atmega2560";
        p.fin_ram = 0x21FF;                // 8 Ko de SRAM
        p.flash_mots = 131072;             // 256 Ko de programme
        p.mots_par_vecteur = 2;            // vecteurs en JMP
        // 256 Ko de programme : le compteur d'instructions dépasse seize bits,
        // et les adresses de retour occupent trois octets sur la pile. C'est
        // la différence de fond avec un ATmega328P — en dépiler deux ferait
        // revenir n'importe où au premier retour de fonction.
        p.octets_adresse_retour = 3;
        p.rampz = 0x5B;
        p.eind = 0x5C;

        // Onze ports. A, B, C, D, E, F, G sont dans l'espace d'E/S ordinaire ;
        // H, J, K, L sont dans l'espace étendu, au-delà de 0x100.
        const struct { char lettre; uint16_t pin; } ports[] = {
            {'A', 0x20}, {'B', 0x23}, {'C', 0x26}, {'D', 0x29}, {'E', 0x2C},
            {'F', 0x2F}, {'G', 0x32}, {'H', 0x100}, {'J', 0x103},
            {'K', 0x106}, {'L', 0x109}};
        p.nb_ports = 11;
        for (int rang = 0; rang < 11; ++rang) {
            p.lettre[rang] = ports[rang].lettre;
            p.pin[rang] = ports[rang].pin;
            p.ddr[rang] = static_cast<uint16_t>(ports[rang].pin + 1);
            p.port[rang] = static_cast<uint16_t>(ports[rang].pin + 2);
        }

        p.spl = 0x5D; p.sph = 0x5E; p.sreg = 0x5F;
        p.adcl = 0x78; p.adch = 0x79; p.adcsra = 0x7A; p.admux = 0x7C;
        // Seize voies : les huit dernières demandent MUX5, qui vit dans
        // ADCSRB. Sans ce bit, A8 rendrait la tension de A0 sans rien dire.
        p.adcsrb = 0x7B;
        p.mux5 = true;
        p.canaux_adc = 16;
        p.ucsra = 0xC0; p.ucsrb = 0xC1; p.udr = 0xC6;   // UART 0
        p.vecteur_usart_rx = 25;

        p.nb_compteurs = 6;
        // Compteur 0 : huit bits, OC0A sur PB7, OC0B sur PG5.
        ProfilAvr::ProfilCompteur& t0 = p.compteurs[0];
        t0.present = true;
        t0.controle_a = 0x44; t0.controle_b = 0x45; t0.compte = 0x46;
        t0.compare_a = 0x47; t0.compare_b = 0x48;
        t0.drapeaux = 0x35; t0.masques = 0x6E;
        t0.vecteur_compa = 21; t0.vecteur_compb = 22; t0.vecteur_ovf = 23;
        t0.port_a = 1; t0.bit_a = 7;        // PB7 = D13
        t0.port_b = 6; t0.bit_b = 5;        // PG5 = D4

        // Compteur 1 : seize bits, OC1A/B/C sur PB5, PB6, PB7.
        ProfilAvr::ProfilCompteur& t1 = p.compteurs[1];
        t1.present = true;
        t1.controle_a = 0x80; t1.controle_b = 0x81;
        t1.compte = 0x84; t1.compte_haut = 0x85;
        t1.compare_a = 0x88; t1.compare_b = 0x8A;
        t1.drapeaux = 0x36; t1.masques = 0x6F;
        t1.vecteur_compa = 17; t1.vecteur_compb = 18; t1.vecteur_ovf = 20;
        t1.port_a = 1; t1.bit_a = 5;        // PB5 = D11
        t1.port_b = 1; t1.bit_b = 6;        // PB6 = D12

        // Compteur 2 : huit bits, OC2A sur PB4, OC2B sur PH6.
        ProfilAvr::ProfilCompteur& t2 = p.compteurs[2];
        t2.present = true;
        t2.controle_a = 0xB0; t2.controle_b = 0xB1; t2.compte = 0xB2;
        t2.compare_a = 0xB3; t2.compare_b = 0xB4;
        t2.drapeaux = 0x37; t2.masques = 0x70;
        t2.vecteur_compa = 14; t2.vecteur_compb = 15; t2.vecteur_ovf = 16;
        t2.prediviseur = 1;
        t2.port_a = 1; t2.bit_a = 4;        // PB4 = D10
        t2.port_b = 7; t2.bit_b = 6;        // PH6 = D9

        // Compteurs 3, 4 et 5 : seize bits, dans l'espace étendu.
        const struct {
            uint16_t base, drapeaux, masques;
            int compa, compb, ovf;
            int port_a, bit_a, port_b, bit_b;
        } grands[] = {
            {0x90, 0x38, 0x71, 32, 33, 35, 4, 3, 4, 4},   // T3 : OC3A PE3 (D5)
            {0xA0, 0x39, 0x72, 45, 46, 48, 7, 3, 7, 4},   // T4 : OC4A PH3 (D6)
            {0x120, 0x3A, 0x73, 49, 50, 52, 9, 0, 9, 1}}; // T5 : OC5A PL3…
        for (int k = 0; k < 3; ++k) {
            ProfilAvr::ProfilCompteur& grand = p.compteurs[3 + k];
            grand.present = true;
            grand.controle_a = grands[k].base;
            grand.controle_b = static_cast<uint16_t>(grands[k].base + 1);
            grand.compte = static_cast<uint16_t>(grands[k].base + 4);
            grand.compte_haut = static_cast<uint16_t>(grands[k].base + 5);
            grand.compare_a = static_cast<uint16_t>(grands[k].base + 8);
            grand.compare_b = static_cast<uint16_t>(grands[k].base + 10);
            grand.drapeaux = grands[k].drapeaux;
            grand.masques = grands[k].masques;
            grand.vecteur_compa = grands[k].compa;
            grand.vecteur_compb = grands[k].compb;
            grand.vecteur_ovf = grands[k].ovf;
            grand.port_a = grands[k].port_a; grand.bit_a = grands[k].bit_a;
            grand.port_b = grands[k].port_b; grand.bit_b = grands[k].bit_b;
        }
        return p;
    }();
    return profil;
}

const ProfilAvr* profil_par_nom(const std::string& nom) {
    if (nom == "atmega328p" || nom.empty()) return &profil_atmega328p();
    if (nom == "attiny85") return &profil_attiny85();
    if (nom == "atmega2560") return &profil_atmega2560();
    return nullptr;
}

CoeurAvr::CoeurAvr() : CoeurAvr(profil_atmega328p()) {}

CoeurAvr::CoeurAvr(const ProfilAvr& profil) { definir_profil(profil); }

void CoeurAvr::definir_profil(const ProfilAvr& profil) {
    p_ = profil;
    donnees_.assign(p_.fin_ram + 1, 0);
    flash_.clear();
    ranger_interruptions();
    reinitialiser();
}

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

    // L'image reçoit la flash de la puce. Elle grandit si un segment se pose
    // plus loin : un code placé haut — ce que fait un Mega dès qu'il dépasse
    // 128 Ko — était jusqu'ici silencieusement tronqué, et le programme
    // sautait dans le vide au premier appel qui s'y rendait.
    std::vector<uint8_t> image(static_cast<size_t>(p_.flash_mots) * 2, 0xFF);
    size_t taille_utile = 0;

    auto deposer = [&image, &taille_utile](size_t adresse,
                                           const unsigned char* source,
                                           size_t longueur) {
        if (adresse + longueur > image.size())
            image.resize(adresse + longueur, 0xFF);
        for (size_t k = 0; k < longueur; ++k) image[adresse + k] = source[k];
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
    // La flash de la puce, et jamais moins que ce que le fichier contient :
    // un firmware plus gros que la puce est une erreur du programmeur, pas
    // une raison de l'exécuter à moitié.
    const size_t mots_image = (image.size() + 1) / 2;
    flash_.assign(std::max<size_t>(p_.flash_mots, mots_image), 0xFFFF);
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
    for (Compteur& compteur : compteurs_) compteur = Compteur{};
    sortie_valide_ = false;
    for (int port = 0; port < ProfilAvr::kMaxPorts; ++port) {
        sortie_connue_[port] = 0;
        direction_connue_[port] = 0;
    }
    poser_pile(p_.fin_ram);
    // L'UART annonce son registre d'émission libre dès le départ, comme la
    // puce au sortir d'un reset. Les puces qui n'en ont pas s'en passent.
    if (p_.ucsra != ProfilAvr::kAbsent) donnees_[p_.ucsra] = 0x20;   // UDRE0
}

// ---------------------------------------------------------------------------
// Mémoire et périphériques
// ---------------------------------------------------------------------------
uint16_t CoeurAvr::pile() const {
    return static_cast<uint16_t>(donnees_[p_.spl])
           | (static_cast<uint16_t>(donnees_[p_.sph]) << 8);
}

void CoeurAvr::poser_pile(uint16_t valeur) {
    donnees_[p_.spl] = static_cast<uint8_t>(valeur);
    donnees_[p_.sph] = static_cast<uint8_t>(valeur >> 8);
}

void CoeurAvr::empiler(uint8_t valeur) {
    const uint16_t sommet = pile();
    if (sommet <= p_.fin_ram) donnees_[sommet] = valeur;
    poser_pile(static_cast<uint16_t>(sommet - 1));
}

// Une adresse de retour : deux octets sur la plupart des AVR, trois sur les
// puces de plus de 128 Ko de programme. L'ordre est celui du matériel —
// l'octet de poids fort est empilé en dernier, donc dépilé en premier.
void CoeurAvr::empiler_retour(uint32_t adresse) {
    empiler(static_cast<uint8_t>(adresse & 0xFF));
    empiler(static_cast<uint8_t>((adresse >> 8) & 0xFF));
    if (p_.octets_adresse_retour >= 3)
        empiler(static_cast<uint8_t>((adresse >> 16) & 0xFF));
}

uint32_t CoeurAvr::depiler_retour() {
    uint32_t adresse = 0;
    if (p_.octets_adresse_retour >= 3)
        adresse = static_cast<uint32_t>(depiler()) << 16;
    adresse |= static_cast<uint32_t>(depiler()) << 8;
    adresse |= depiler();
    return adresse;
}

uint8_t CoeurAvr::depiler() {
    const uint16_t sommet = static_cast<uint16_t>(pile() + 1);
    poser_pile(sommet);
    return sommet <= p_.fin_ram ? donnees_[sommet] : 0;
}

void CoeurAvr::poser_drapeau(int bit, bool actif) {
    if (actif)
        donnees_[p_.sreg] |= static_cast<uint8_t>(1 << bit);
    else
        donnees_[p_.sreg] &= static_cast<uint8_t>(~(1 << bit));
}

uint8_t CoeurAvr::niveau_broches(int port) const {
    // Ce que lit PINx : le niveau imposé de l'extérieur pour les entrées, la
    // valeur du registre de sortie pour les broches pilotées.
    if (port < 0 || port >= p_.nb_ports) return 0;
    const uint8_t direction = donnees_[p_.ddr[port]];
    return static_cast<uint8_t>((donnees_[p_.port[port]] & direction)
                                | (entree_[port] & ~direction));
}

// Le port dont voici le registre PINx, ou -1.
int CoeurAvr::port_de_pin(uint16_t adresse) const {
    for (int rang = 0; rang < p_.nb_ports; ++rang)
        if (p_.pin[rang] == adresse) return rang;
    return -1;
}

uint8_t CoeurAvr::lire_donnee(uint16_t adresse) const {
    if (adresse > p_.fin_ram) return 0;
    const int port = port_de_pin(adresse);
    if (port >= 0) return niveau_broches(port);
    return donnees_[adresse];
}

uint8_t CoeurAvr::lire(uint16_t adresse) {
    if (adresse > p_.fin_ram) return 0;
    const int port = port_de_pin(adresse);
    if (port >= 0) return niveau_broches(port);
    if (adresse == p_.udr) {
        const uint8_t octet_recu = serie_recue_;
        serie_disponible_ = false;
        donnees_[p_.ucsra] &= static_cast<uint8_t>(~0x80);   // RXC0
        return octet_recu;
    }
    return donnees_[adresse];
}

void CoeurAvr::ecrire(uint16_t adresse, uint8_t valeur) {
    if (adresse > p_.fin_ram) return;

    // Écrire dans PINx bascule les bits correspondants de PORTx : c'est le
    // raccourci des AVR récents, et avr-gcc s'en sert.
    const int port = port_de_pin(adresse);
    if (port >= 0) {
        donnees_[p_.port[port]] ^= valeur;
        rafraichir_sorties();
        return;
    }
    // Un drapeau d'interruption s'efface en y écrivant un « 1 ». Sur les
    // petites puces, les deux compteurs partagent le même registre.
    for (int numero = 0; numero < p_.nb_compteurs; ++numero) {
        const ProfilAvr::ProfilCompteur& compteur = p_.compteurs[numero];
        if (!compteur.present || compteur.drapeaux != adresse) continue;
        donnees_[adresse] &= static_cast<uint8_t>(~valeur);
        return;
    }
    if (adresse == p_.udr) {
        donnees_[adresse] = valeur;
        if (sur_serie) sur_serie(valeur);
        donnees_[p_.ucsra] |= 0x60;          // UDRE0 et TXC0
        return;
    }
    if (adresse == p_.adcsra) {
        donnees_[adresse] = valeur;
        if ((valeur & 0x40) && (valeur & 0x80)) demarrer_conversion();
        return;
    }

    donnees_[adresse] = valeur;
    if (touche_les_sorties(adresse)) rafraichir_sorties();
}

// Une écriture qui peut changer ce que le circuit voit : registre de port, de
// direction, ou l'un des registres qui commandent une sortie de comparaison.
bool CoeurAvr::touche_les_sorties(uint16_t adresse) const {
    for (int rang = 0; rang < p_.nb_ports; ++rang)
        if (adresse == p_.port[rang] || adresse == p_.ddr[rang]) return true;
    for (int numero = 0; numero < p_.nb_compteurs; ++numero) {
        const ProfilAvr::ProfilCompteur& compteur = p_.compteurs[numero];
        if (!compteur.present) continue;
        if (adresse == compteur.controle_a || adresse == compteur.controle_b
            || adresse == compteur.compare_a || adresse == compteur.compare_b
            || adresse == compteur.sommet)
            return true;
    }
    return false;
}

void CoeurAvr::demarrer_conversion() {
    int canal = donnees_[p_.admux] & 0x0F;
    if (p_.mux5 && p_.adcsrb != ProfilAvr::kAbsent
        && (donnees_[p_.adcsrb] & 0x08))
        canal |= 0x08;
    // La tension est demandée MAINTENANT, pas au bord de la fenêtre de
    // couplage : c'est ce qui permet à un programme d'échantillonner un
    // signal alternatif et d'en tirer quelque chose.
    if (source_adc && canal < p_.canaux_adc && canal < 16) {
        const double volts = source_adc(canal, cycles_);
        if (volts >= 0.0) tension_adc(canal, volts);
    }
    const uint16_t mesure = canal < p_.canaux_adc ? adc_[canal] : 0;
    donnees_[p_.adcl] = static_cast<uint8_t>(mesure & 0xFF);
    donnees_[p_.adch] = static_cast<uint8_t>(mesure >> 8);
    // Une conversion dure treize périodes du convertisseur ; le programme
    // attend que ADSC retombe, il faut donc que cela prenne du temps.
    const int diviseur = 1 << std::max<int>(1, donnees_[p_.adcsra] & 7);
    adc_restant_ = 13 * diviseur;
}

int CoeurAvr::rang_du_port(char lettre) const {
    for (int rang = 0; rang < p_.nb_ports; ++rang)
        if (p_.lettre[rang] == lettre) return rang;
    return -1;
}

void CoeurAvr::broche_externe(char port, int bit, bool haut) {
    const int rang = rang_du_port(port);
    if (bit < 0 || bit > 7 || rang < 0) return;
    if (haut)
        entree_[rang] |= static_cast<uint8_t>(1 << bit);
    else
        entree_[rang] &= static_cast<uint8_t>(~(1 << bit));
}

void CoeurAvr::tension_adc(int canal, double volts) {
    if (canal < 0 || canal >= p_.canaux_adc || canal >= 16) return;
    volts = std::max(0.0, std::min(5.0, volts));
    adc_[canal] = static_cast<uint16_t>(volts / 5.0 * 1023.0 + 0.5);
}

void CoeurAvr::recevoir_serie(uint8_t octet) {
    if (p_.ucsra == ProfilAvr::kAbsent) return;   // pas d'UART sur cette puce
    serie_recue_ = octet;
    serie_disponible_ = true;
    donnees_[p_.ucsra] |= 0x80;             // RXC0
}

// ---------------------------------------------------------------------------
// Sorties : ce que le circuit voit
// ---------------------------------------------------------------------------
void CoeurAvr::rafraichir_sorties() {
    // Borné explicitement : le compilateur ne peut pas déduire seul que le
    // profil ne décrit jamais plus de trois ports.
    const int ports = std::min(p_.nb_ports, ProfilAvr::kMaxPorts);
    uint8_t niveaux[ProfilAvr::kMaxPorts] = {};
    for (int rang = 0; rang < ports; ++rang)
        niveaux[rang] = static_cast<uint8_t>(donnees_[p_.port[rang]]
                                             & donnees_[p_.ddr[rang]]);

    // Les sorties de comparaison prennent la main sur le registre de port
    // quand le mode PWM est armé : c'est ce que fait `analogWrite`.
    auto pwm = [&](int port, int bit, bool actif, bool niveau) {
        if (!actif || port < 0 || port >= p_.nb_ports) return;
        if (!(donnees_[p_.ddr[port]] & (1 << bit))) return;
        if (niveau)
            niveaux[port] |= static_cast<uint8_t>(1 << bit);
        else
            niveaux[port] &= static_cast<uint8_t>(~(1 << bit));
    };
    for (int numero = 0; numero < p_.nb_compteurs; ++numero) {
        const ProfilAvr::ProfilCompteur& profil = p_.compteurs[numero];
        if (!profil.present) continue;
        const uint8_t compte = static_cast<uint8_t>(compteurs_[numero].compte);
        // Le compteur 1 de l'ATtiny arme sa PWM par un bit à lui (PWM1A et
        // PWM1B dans TCCR1 et GTCCR), pas par les bits WGM des autres.
        const bool arme = profil.prediviseur == 2
                              ? true
                              : (donnees_[profil.controle_a] & 0x03) != 0;
        pwm(profil.port_a, profil.bit_a,
            arme && (donnees_[profil.controle_a] & 0x80),
            compte < donnees_[profil.compare_a]);
        pwm(profil.port_b, profil.bit_b,
            arme && (donnees_[profil.controle_a] & 0x20),
            compte < donnees_[profil.compare_b]);
    }

    for (int rang = 0; rang < ports; ++rang) {
        // Une broche qui devient une sortie annonce son niveau, même s'il
        // n'a pas changé : jusque-là elle ne pilotait rien, et le circuit
        // doit l'apprendre.
        const uint8_t direction = donnees_[p_.ddr[rang]];
        const uint8_t change = static_cast<uint8_t>(
            sortie_valide_ ? ((niveaux[rang] ^ sortie_connue_[rang])
                              | (direction & ~direction_connue_[rang]))
                           : 0xFF);
        sortie_connue_[rang] = niveaux[rang];
        direction_connue_[rang] = direction;
        if (!sur_broche) continue;
        for (int bit = 0; bit < 8; ++bit) {
            if (!(change & (1 << bit))) continue;
            if (!(direction & (1 << bit))) continue;
            sur_broche(p_.lettre[rang], bit, (niveaux[rang] >> bit) & 1);
        }
    }
    sortie_valide_ = true;
}

// ---------------------------------------------------------------------------
// Compteurs
// ---------------------------------------------------------------------------
void CoeurAvr::avancer_compteur(Compteur& compteur, int cycles, int numero) {
    const ProfilAvr::ProfilCompteur& profil = p_.compteurs[numero];
    if (!profil.present) return;

    // Le prédiviseur : trois tableaux différents selon la puce et le
    // compteur, et c'est le profil qui dit lequel.
    int diviseur = 0;
    if (profil.prediviseur == 2) {
        // Compteur 1 de l'ATtiny : quatre bits, de /1 à /16384.
        const uint8_t selection = donnees_[profil.controle_b] & 0x0F;
        diviseur = selection == 0 ? 0 : (1 << (selection - 1));
    } else {
        const uint8_t selection = donnees_[profil.controle_b] & 0x07;
        diviseur = profil.prediviseur == 1 ? diviseur_t2(selection)
                                           : diviseur_de(selection);
    }
    compteur.diviseur = diviseur;
    if (diviseur == 0) return;

    // Le sommet du comptage : un registre à part sur l'ATtiny, la valeur de
    // comparaison en mode CTC ailleurs, 0xFF sinon.
    bool ctc = false;
    if (profil.sommet == ProfilAvr::kAbsent) {
        ctc = numero == 1 && profil.prediviseur == 0
                  ? ((donnees_[profil.controle_b] & 0x08)
                     && !(donnees_[profil.controle_a] & 0x01))
                  : ((donnees_[profil.controle_a] & 0x03) == 0x02);
    }
    const uint16_t sommet =
        profil.sommet != ProfilAvr::kAbsent
            ? donnees_[profil.sommet]
            : (ctc ? donnees_[profil.compare_a] : 0xFF);

    compteur.reste += cycles;
    while (compteur.reste >= diviseur) {
        compteur.reste -= diviseur;
        const uint16_t avant = compteur.compte;
        uint16_t apres = static_cast<uint16_t>(avant + 1);
        if (apres > sommet) {
            apres = 0;
            if (!ctc) donnees_[profil.drapeaux] |= profil.bit_tov;
        }
        compteur.compte = apres;
        if (avant == donnees_[profil.compare_a])
            donnees_[profil.drapeaux] |= profil.bit_ocfa;
        if (avant == donnees_[profil.compare_b])
            donnees_[profil.drapeaux] |= profil.bit_ocfb;
    }
    donnees_[profil.compte] = static_cast<uint8_t>(compteur.compte);
    if (profil.compte_haut != ProfilAvr::kAbsent)
        donnees_[profil.compte_haut] = static_cast<uint8_t>(compteur.compte >> 8);
}

void CoeurAvr::avancer_peripheriques(int cycles) {
    for (int numero = 0; numero < p_.nb_compteurs; ++numero)
        avancer_compteur(compteurs_[numero], cycles, numero);
    if (adc_restant_ > 0) {
        adc_restant_ -= cycles;
        if (adc_restant_ <= 0) {
            adc_restant_ = 0;
            donnees_[p_.adcsra] &= static_cast<uint8_t>(~0x40);   // ADSC retombe
            donnees_[p_.adcsra] |= 0x10;                          // ADIF
        }
    }
    rafraichir_sorties();
}

// ---------------------------------------------------------------------------
// Interruptions
// ---------------------------------------------------------------------------
void CoeurAvr::declencher(int vecteur) {
    empiler_retour(pc_);
    poser_drapeau(kI, false);
    pc_ = static_cast<uint32_t>(vecteur) * p_.mots_par_vecteur;
    cycles_ += 4;
    endormi_ = false;
}

// Les sources d'interruption d'une puce, rangées par priorité — le vecteur
// le plus bas d'abord. L'ordre n'est pas le même d'une puce à l'autre : sur
// l'ATtiny le compteur 1 passe avant le compteur 0, sur l'ATmega c'est
// l'inverse. On les trie donc par numéro de vecteur, une fois pour toutes,
// au lieu de les écrire à la main dans un ordre qui ne vaudrait que pour une
// puce.
void CoeurAvr::ranger_interruptions() {
    sources_.clear();
    for (int numero = 0; numero < p_.nb_compteurs; ++numero) {
        const ProfilAvr::ProfilCompteur& profil = p_.compteurs[numero];
        if (!profil.present) continue;
        sources_.push_back({profil.drapeaux, profil.masques, profil.bit_ocfa,
                            profil.vecteur_compa});
        sources_.push_back({profil.drapeaux, profil.masques, profil.bit_ocfb,
                            profil.vecteur_compb});
        sources_.push_back({profil.drapeaux, profil.masques, profil.bit_tov,
                            profil.vecteur_ovf});
    }
    std::sort(sources_.begin(), sources_.end(),
              [](const Source& a, const Source& b) {
                  return a.vecteur < b.vecteur;
              });
}

bool CoeurAvr::servir_interruption() {
    if (!drapeau(kI)) return false;

    for (const Source& source : sources_) {
        if (source.vecteur <= 0) continue;
        if (!(donnees_[source.drapeaux] & source.bit)) continue;
        if (!(donnees_[source.masques] & source.bit)) continue;
        donnees_[source.drapeaux] &= static_cast<uint8_t>(~source.bit);
        declencher(source.vecteur);
        return true;
    }
    // Réception série : le drapeau vit dans UCSR0A, l'autorisation dans B.
    // Les puces sans UART n'ont ni l'un ni l'autre.
    if (p_.udr != ProfilAvr::kAbsent && (donnees_[p_.ucsra] & 0x80)
        && (donnees_[p_.ucsrb] & 0x80)) {
        declencher(p_.vecteur_usart_rx);
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
                    case 0x5:                                   // LPM Rd, Z+
                    case 0x6:                                   // ELPM Rd, Z
                    case 0x7: {                                 // ELPM Rd, Z+
                        // ELPM prolonge l'adresse par RAMPZ : c'est ainsi
                        // qu'on lit la moitié haute de la flash d'une grosse
                        // puce, et avr-gcc s'en sert dès que les données
                        // constantes dépassent 64 Ko.
                        const int forme = code & 0x000F;
                        const bool etendu = forme >= 0x6;
                        const uint16_t z = lire_paire(30);
                        uint32_t adresse = z;
                        if (etendu && p_.rampz != ProfilAvr::kAbsent)
                            adresse |= static_cast<uint32_t>(donnees_[p_.rampz])
                                       << 16;
                        const uint32_t mot_rang = adresse / 2;
                        const uint16_t mot =
                            mot_rang < flash_.size() ? flash_[mot_rang] : 0xFFFF;
                        poser_reg(rang, static_cast<uint8_t>(
                                            (adresse & 1) ? (mot >> 8) : mot));
                        if (forme == 0x5 || forme == 0x7) {
                            const uint32_t suivante = adresse + 1;
                            poser_paire(30, static_cast<uint16_t>(suivante));
                            if (etendu && p_.rampz != ProfilAvr::kAbsent)
                                donnees_[p_.rampz] =
                                    static_cast<uint8_t>(suivante >> 16);
                        }
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
                if (code == 0x9419 && p_.eind != ProfilAvr::kAbsent)
                    pc_ |= static_cast<uint32_t>(donnees_[p_.eind]) << 16;
                return 2;
            }
            if (code == 0x9509 || code == 0x9519) {             // ICALL/EICALL
                empiler_retour(pc_);
                pc_ = lire_paire(30);
                // EICALL ajoute les bits hauts que porte EIND : sans eux, un
                // appel indirect vers la moitié haute de la flash reviendrait
                // dans la moitié basse.
                if (code == 0x9519 && p_.eind != ProfilAvr::kAbsent)
                    pc_ |= static_cast<uint32_t>(donnees_[p_.eind]) << 16;
                return 3;
            }
            if (code == 0x9508 || code == 0x9518) {             // RET / RETI
                pc_ = depiler_retour();
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
                empiler_retour(pc_);
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
            const int16_t decalage =
                static_cast<int16_t>(etendre_signe_avr(code, 12));
            pc_ = static_cast<uint32_t>(pc_ + decalage);
            return 2;
        }
        case 0xD000: {                                          // RCALL
            const int16_t decalage =
                static_cast<int16_t>(etendre_signe_avr(code, 12));
            empiler_retour(pc_);
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
