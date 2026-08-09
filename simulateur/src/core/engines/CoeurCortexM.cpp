#include "core/engines/CoeurCortexM.h"

#include <algorithm>
#include <cstring>
#include <fstream>
#include <iterator>

namespace coeur {

namespace {

uint32_t mot32(const unsigned char* p) {
    return static_cast<uint32_t>(p[0]) | (static_cast<uint32_t>(p[1]) << 8)
           | (static_cast<uint32_t>(p[2]) << 16)
           | (static_cast<uint32_t>(p[3]) << 24);
}
uint16_t mot16(const unsigned char* p) {
    return static_cast<uint16_t>(p[0] | (p[1] << 8));
}

// Rotation à droite : ROR est la seule des quatre à ne pas être un décalage.
uint32_t rotation_droite(uint32_t valeur, int rang) {
    rang &= 31;
    if (rang == 0) return valeur;
    return (valeur >> rang) | (valeur << (32 - rang));
}

}  // namespace

// ---------------------------------------------------------------------------
// Les puces
// ---------------------------------------------------------------------------
const ProfilCortex& profil_rp2040() {
    static const ProfilCortex profil = [] {
        ProfilCortex p;
        p.nom = "rp2040";
        p.architecture = 6;                // Cortex-M0+, Thumb-1 seulement
        p.frequence = 125000000;
        // La flash est vue par la fenêtre XIP à 0x10000000 ; la mémoire vive
        // fait 264 Ko à partir de 0x20000000. On accepte aussi 0x00000000,
        // où atterrit un firmware lié sans script de l'éditeur de liens.
        p.memoires = {{0x00000000, 0x00040000, true},
                      {0x10000000, 0x00200000, false},
                      {0x20000000, 0x00042000, true}};
        // Le bloc SIO : c'est par lui qu'un RP2040 pilote ses broches, et
        // c'est pour cela qu'il est si rapide — un accès en un cycle, sans
        // passer par le bus des périphériques.
        ProfilPort sio;
        sio.nom = 'A';
        sio.base = 0xD0000000;
        sio.entree = 0x004;
        sio.sortie = 0x010;
        sio.sortie_poser = 0x014;
        sio.sortie_effacer = 0x018;
        sio.sortie_inverser = 0x01C;
        sio.direction = 0x020;
        sio.direction_poser = 0x024;
        sio.direction_effacer = 0x028;
        sio.premiere_broche = 0;
        sio.nb_broches = 30;
        p.ports = {sio};
        p.systick = 0xE000E010;
        p.table_vecteurs = 0x10000000;
        return p;
    }();
    return profil;
}

const ProfilCortex& profil_stm32f103() {
    static const ProfilCortex profil = [] {
        ProfilCortex p;
        p.nom = "stm32f103";
        p.architecture = 7;                // Cortex-M3, Thumb-2
        p.frequence = 72000000;
        // Flash à 0x08000000, mémoire vive à 0x20000000. Un STM32 démarre en
        // 0x00000000, où la flash est recopiée par l'aliasing du boîtier.
        p.memoires = {{0x00000000, 0x00020000, false},
                      {0x08000000, 0x00020000, false},
                      {0x20000000, 0x00005000, true}};
        // Les ports A, B et C. Sur cette famille, la direction se règle par
        // deux registres de configuration ; le simulateur retient l'essentiel :
        // ce qui est en sortie, et à quel niveau.
        for (int rang = 0; rang < 3; ++rang) {
            ProfilPort port;
            port.nom = static_cast<char>('A' + rang);
            port.base = 0x40010800 + rang * 0x400;
            port.taille = 0x400;
            port.direction = 0x000;        // CRL : broches 0 à 7
            port.direction_haute = 0x004;  // CRH : broches 8 à 15
            port.direction_par_quartets = true;
            port.entree = 0x008;           // IDR
            port.sortie = 0x00C;           // ODR
            port.sortie_poser = 0x010;     // BSRR, moitié basse
            port.sortie_effacer = 0x014;   // BRR
            port.premiere_broche = rang * 16;
            port.nb_broches = 16;
            p.ports.push_back(port);
        }
        p.systick = 0xE000E010;
        p.table_vecteurs = 0x08000000;
        return p;
    }();
    return profil;
}

const ProfilCortex* profil_cortex_par_nom(const std::string& nom) {
    if (nom == "rp2040") return &profil_rp2040();
    if (nom == "stm32f103") return &profil_stm32f103();
    return nullptr;
}

// ---------------------------------------------------------------------------
CoeurCortexM::CoeurCortexM() : CoeurCortexM(profil_rp2040()) {}

CoeurCortexM::CoeurCortexM(const ProfilCortex& profil) { definir_profil(profil); }

void CoeurCortexM::definir_profil(const ProfilCortex& profil) {
    p_ = profil;
    frequence_ = profil.frequence;
    memoire_.clear();
    for (const PlageMemoire& plage : p_.memoires) {
        Bloc bloc;
        bloc.debut = plage.debut;
        bloc.inscriptible = plage.inscriptible;
        bloc.octets.assign(plage.taille, 0);
        memoire_.push_back(std::move(bloc));
    }
    ports_.assign(p_.ports.size(), EtatPort{});
    reinitialiser();
}

// ---------------------------------------------------------------------------
// Mémoire
// ---------------------------------------------------------------------------
uint8_t* CoeurCortexM::trouver(uint32_t adresse, uint32_t longueur) {
    for (Bloc& bloc : memoire_) {
        if (adresse < bloc.debut) continue;
        const uint32_t decalage = adresse - bloc.debut;
        if (decalage + longueur > bloc.octets.size()) continue;
        return &bloc.octets[decalage];
    }
    return nullptr;
}

const uint8_t* CoeurCortexM::trouver(uint32_t adresse, uint32_t longueur) const {
    return const_cast<CoeurCortexM*>(this)->trouver(adresse, longueur);
}

uint32_t CoeurCortexM::lire32(uint32_t adresse) const {
    uint32_t valeur = 0;
    if (const_cast<CoeurCortexM*>(this)->lire_peripherique(adresse, &valeur))
        return valeur;
    const uint8_t* p = trouver(adresse, 4);
    if (!p) return 0;
    return static_cast<uint32_t>(p[0]) | (static_cast<uint32_t>(p[1]) << 8)
           | (static_cast<uint32_t>(p[2]) << 16)
           | (static_cast<uint32_t>(p[3]) << 24);
}

uint16_t CoeurCortexM::lire16(uint32_t adresse) const {
    uint32_t valeur = 0;
    if (const_cast<CoeurCortexM*>(this)->lire_peripherique(adresse & ~3u,
                                                           &valeur))
        return static_cast<uint16_t>((adresse & 2) ? (valeur >> 16) : valeur);
    const uint8_t* p = trouver(adresse, 2);
    if (!p) return 0;
    return static_cast<uint16_t>(p[0] | (p[1] << 8));
}

uint8_t CoeurCortexM::lire8(uint32_t adresse) const {
    uint32_t valeur = 0;
    if (const_cast<CoeurCortexM*>(this)->lire_peripherique(adresse & ~3u,
                                                           &valeur))
        return static_cast<uint8_t>(valeur >> (8 * (adresse & 3)));
    const uint8_t* p = trouver(adresse, 1);
    return p ? *p : 0;
}

void CoeurCortexM::ecrire32(uint32_t adresse, uint32_t valeur) {
    if (ecrire_peripherique(adresse, valeur)) return;
    uint8_t* p = trouver(adresse, 4);
    if (!p) return;
    p[0] = static_cast<uint8_t>(valeur);
    p[1] = static_cast<uint8_t>(valeur >> 8);
    p[2] = static_cast<uint8_t>(valeur >> 16);
    p[3] = static_cast<uint8_t>(valeur >> 24);
}

void CoeurCortexM::ecrire16(uint32_t adresse, uint16_t valeur) {
    uint8_t* p = trouver(adresse, 2);
    if (!p) {
        ecrire_peripherique(adresse, valeur);
        return;
    }
    p[0] = static_cast<uint8_t>(valeur);
    p[1] = static_cast<uint8_t>(valeur >> 8);
}

void CoeurCortexM::ecrire8(uint32_t adresse, uint8_t valeur) {
    uint8_t* p = trouver(adresse, 1);
    if (p) *p = valeur;
}

uint32_t CoeurCortexM::lire_mot(uint32_t adresse) const { return lire32(adresse); }

// ---------------------------------------------------------------------------
// Périphériques : les ports et SysTick
// ---------------------------------------------------------------------------
bool CoeurCortexM::lire_peripherique(uint32_t adresse, uint32_t* valeur) const {
    for (size_t rang = 0; rang < p_.ports.size(); ++rang) {
        const ProfilPort& port = p_.ports[rang];
        const EtatPort& etat = ports_[rang];
        if (adresse < port.base || adresse >= port.base + port.taille)
            continue;
        const uint32_t decalage = adresse - port.base;
        if (decalage == port.entree) {
            // Ce que lit le firmware : le niveau imposé de l'extérieur pour
            // les entrées, la valeur du registre de sortie pour le reste.
            *valeur = (etat.sortie & etat.direction)
                      | (etat.entree & ~etat.direction);
            return true;
        }
        if (decalage == port.sortie) { *valeur = etat.sortie; return true; }
        if (decalage == port.direction) { *valeur = etat.direction; return true; }
        *valeur = 0;
        return true;
    }
    if (p_.systick && adresse >= p_.systick && adresse < p_.systick + 0x10) {
        switch (adresse - p_.systick) {
            case 0x0: *valeur = systick_controle_; return true;
            case 0x4: *valeur = systick_charge_; return true;
            case 0x8: *valeur = systick_valeur_; return true;
            default: *valeur = 0; return true;
        }
    }
    return false;
}

bool CoeurCortexM::ecrire_peripherique(uint32_t adresse, uint32_t valeur) {
    for (size_t rang = 0; rang < p_.ports.size(); ++rang) {
        const ProfilPort& port = p_.ports[rang];
        EtatPort& etat = ports_[rang];
        if (adresse < port.base || adresse >= port.base + port.taille)
            continue;
        const uint32_t decalage = adresse - port.base;
        // Configuration par quartets : on relit les deux registres et l'on
        // recompose la direction, une broche étant en sortie dès que ses deux
        // bits de mode ne sont pas nuls.
        if (port.direction_par_quartets
            && (decalage == port.direction || decalage == port.direction_haute)) {
            if (decalage == port.direction) etat.config_basse = valeur;
            else etat.config_haute = valeur;
            uint32_t direction = 0;
            for (int bit = 0; bit < 8; ++bit) {
                if ((etat.config_basse >> (bit * 4)) & 0x3) direction |= 1u << bit;
                if ((etat.config_haute >> (bit * 4)) & 0x3)
                    direction |= 1u << (bit + 8);
            }
            etat.direction = direction;
            rafraichir_sorties();
            return true;
        }
        if (decalage == port.sortie) etat.sortie = valeur;
        else if (decalage == port.sortie_poser) etat.sortie |= valeur;
        else if (decalage == port.sortie_effacer) etat.sortie &= ~valeur;
        else if (decalage == port.sortie_inverser) etat.sortie ^= valeur;
        else if (decalage == port.direction) etat.direction = valeur;
        else if (decalage == port.direction_poser) etat.direction |= valeur;
        else if (decalage == port.direction_effacer) etat.direction &= ~valeur;
        else return true;                  // registre non modélisé : sans effet
        rafraichir_sorties();
        return true;
    }
    if (p_.systick && adresse >= p_.systick && adresse < p_.systick + 0x10) {
        switch (adresse - p_.systick) {
            case 0x0: systick_controle_ = valeur; return true;
            case 0x4: systick_charge_ = valeur & 0x00FFFFFF; return true;
            case 0x8: systick_valeur_ = 0; return true;   // toute écriture efface
            default: return true;
        }
    }
    return false;
}

void CoeurCortexM::rafraichir_sorties() {
    if (!sur_broche) {
        for (EtatPort& etat : ports_) {
            etat.connue_sortie = etat.sortie;
            etat.connue_direction = etat.direction;
        }
        sorties_valides_ = true;
        return;
    }
    for (size_t rang = 0; rang < p_.ports.size(); ++rang) {
        const ProfilPort& port = p_.ports[rang];
        EtatPort& etat = ports_[rang];
        // Une broche qui devient une sortie annonce son niveau même s'il n'a
        // pas changé : jusque-là elle ne pilotait rien.
        const uint32_t change =
            sorties_valides_ ? ((etat.sortie ^ etat.connue_sortie)
                                | (etat.direction & ~etat.connue_direction))
                             : 0xFFFFFFFFu;
        etat.connue_sortie = etat.sortie;
        etat.connue_direction = etat.direction;
        for (int bit = 0; bit < port.nb_broches; ++bit) {
            const uint32_t masque = 1u << bit;
            if (!(change & masque)) continue;
            if (!(etat.direction & masque)) continue;
            sur_broche(port.premiere_broche + bit, (etat.sortie & masque) != 0);
        }
    }
    sorties_valides_ = true;
}

void CoeurCortexM::broche_externe(int broche, bool haut) {
    for (size_t rang = 0; rang < p_.ports.size(); ++rang) {
        const ProfilPort& port = p_.ports[rang];
        if (broche < port.premiere_broche
            || broche >= port.premiere_broche + port.nb_broches)
            continue;
        const uint32_t masque = 1u << (broche - port.premiere_broche);
        if (haut) ports_[rang].entree |= masque;
        else ports_[rang].entree &= ~masque;
        return;
    }
}

bool CoeurCortexM::broche_en_sortie(int broche) const {
    for (size_t rang = 0; rang < p_.ports.size(); ++rang) {
        const ProfilPort& port = p_.ports[rang];
        if (broche < port.premiere_broche
            || broche >= port.premiere_broche + port.nb_broches)
            continue;
        return (ports_[rang].direction >> (broche - port.premiere_broche)) & 1;
    }
    return false;
}

bool CoeurCortexM::broche_haute(int broche) const {
    for (size_t rang = 0; rang < p_.ports.size(); ++rang) {
        const ProfilPort& port = p_.ports[rang];
        if (broche < port.premiere_broche
            || broche >= port.premiere_broche + port.nb_broches)
            continue;
        return (ports_[rang].sortie >> (broche - port.premiere_broche)) & 1;
    }
    return false;
}

void CoeurCortexM::avancer_peripheriques(int cycles) {
    if (!(systick_controle_ & 1) || systick_charge_ == 0) return;
    // Compteur décroissant : il repart du haut à chaque passage par zéro, et
    // lève son drapeau. C'est sur lui que reposent toutes les temporisations.
    uint32_t restant = static_cast<uint32_t>(cycles);
    while (restant > systick_valeur_) {
        restant -= systick_valeur_ + 1;
        systick_valeur_ = systick_charge_;
        systick_controle_ |= 0x10000;      // COUNTFLAG
    }
    systick_valeur_ -= restant;
}

// ---------------------------------------------------------------------------
// Chargement d'un firmware
// ---------------------------------------------------------------------------
bool CoeurCortexM::charger(const std::string& chemin, std::string* erreur) {
    std::ifstream fichier(chemin, std::ios::binary);
    if (!fichier) {
        if (erreur) *erreur = "fichier introuvable : " + chemin;
        return false;
    }
    std::vector<unsigned char> contenu((std::istreambuf_iterator<char>(fichier)),
                                       std::istreambuf_iterator<char>());
    if (contenu.size() < 52 || contenu[0] != 0x7F || contenu[1] != 'E'
        || contenu[2] != 'L' || contenu[3] != 'F') {
        if (erreur) *erreur = "ce n'est pas un fichier ELF : " + chemin;
        return false;
    }

    definir_profil(p_);                    // mémoire remise à zéro
    const uint32_t debut_segments = mot32(&contenu[28]);
    const uint16_t taille_segment = mot16(&contenu[42]);
    const uint16_t nombre_segments = mot16(&contenu[44]);
    uint32_t premier_code = 0xFFFFFFFF;
    bool quelque_chose = false;

    for (int k = 0; k < nombre_segments; ++k) {
        const size_t base = debut_segments + static_cast<size_t>(k) * taille_segment;
        if (base + 32 > contenu.size()) break;
        if (mot32(&contenu[base]) != 1) continue;          // PT_LOAD seulement
        const uint32_t decalage = mot32(&contenu[base + 4]);
        const uint32_t adresse = mot32(&contenu[base + 8]);   // p_vaddr
        const uint32_t longueur = mot32(&contenu[base + 16]); // p_filesz
        if (longueur == 0 || decalage + longueur > contenu.size()) continue;
        // Les blocs de flash sont déclarés non inscriptibles pour le
        // programme ; le chargement, lui, y écrit — c'est le rôle du
        // programmateur, pas du firmware.
        for (Bloc& bloc : memoire_) {
            if (adresse < bloc.debut) continue;
            const uint32_t dans = adresse - bloc.debut;
            if (dans + longueur > bloc.octets.size()) continue;
            std::memcpy(&bloc.octets[dans], &contenu[decalage], longueur);
            quelque_chose = true;
            premier_code = std::min(premier_code, adresse);
            break;
        }
    }
    if (!quelque_chose) {
        if (erreur) *erreur = "aucun segment chargeable dans " + chemin;
        return false;
    }

    // Point d'entrée : celui que déclare l'ELF. Un vrai Cortex-M le prend
    // dans sa table de vecteurs ; un firmware lié sans table nous donne le
    // sien directement, et les deux cas se rencontrent.
    const uint32_t entree = mot32(&contenu[24]);
    reinitialiser();
    if (entree != 0) {
        r_[15] = entree & ~1u;
    } else {
        r_[13] = lire32(premier_code);
        r_[15] = lire32(premier_code + 4) & ~1u;
    }
    return true;
}

void CoeurCortexM::reinitialiser() {
    for (uint32_t& registre : r_) registre = 0;
    n_ = z_ = c_ = v_ = false;
    cycles_ = 0;
    endormi_ = false;
    systick_charge_ = systick_valeur_ = systick_controle_ = 0;
    for (EtatPort& etat : ports_) {
        etat.direction = etat.sortie = 0;
        etat.connue_sortie = etat.connue_direction = 0;
        etat.config_basse = etat.config_haute = 0;
    }
    sorties_valides_ = false;
    // La pile démarre en haut de la mémoire vive : c'est ce que fait la table
    // de vecteurs d'un vrai Cortex-M, et un firmware lié sans elle compte
    // dessus tout autant.
    for (const Bloc& bloc : memoire_)
        if (bloc.inscriptible && bloc.debut >= 0x20000000)
            r_[13] = bloc.debut + static_cast<uint32_t>(bloc.octets.size());
    if (r_[13] == 0 && !memoire_.empty())
        r_[13] = memoire_.front().debut
                 + static_cast<uint32_t>(memoire_.front().octets.size());
}

// ---------------------------------------------------------------------------
// Drapeaux
// ---------------------------------------------------------------------------
void CoeurCortexM::poser_drapeaux_logiques(uint32_t resultat) {
    n_ = (resultat & 0x80000000u) != 0;
    z_ = resultat == 0;
}

void CoeurCortexM::poser_drapeaux_addition(uint32_t a, uint32_t b,
                                           uint32_t retenue) {
    const uint64_t somme = static_cast<uint64_t>(a) + b + retenue;
    const uint32_t resultat = static_cast<uint32_t>(somme);
    poser_drapeaux_logiques(resultat);
    c_ = somme > 0xFFFFFFFFull;
    v_ = (~(a ^ b) & (a ^ resultat) & 0x80000000u) != 0;
}

void CoeurCortexM::poser_drapeaux_soustraction(uint32_t a, uint32_t b) {
    // Une soustraction est une addition du complément : la retenue sortante
    // devient l'absence d'emprunt, ce qui est exactement ce que teste BCS.
    poser_drapeaux_addition(a, ~b, 1);
}

bool CoeurCortexM::condition(int code) const {
    switch (code & 0x0F) {
        case 0x0: return z_;                       // EQ
        case 0x1: return !z_;                      // NE
        case 0x2: return c_;                       // CS
        case 0x3: return !c_;                      // CC
        case 0x4: return n_;                       // MI
        case 0x5: return !n_;                      // PL
        case 0x6: return v_;                       // VS
        case 0x7: return !v_;                      // VC
        case 0x8: return c_ && !z_;                // HI
        case 0x9: return !c_ || z_;                // LS
        case 0xA: return n_ == v_;                 // GE
        case 0xB: return n_ != v_;                 // LT
        case 0xC: return !z_ && n_ == v_;          // GT
        case 0xD: return z_ || n_ != v_;           // LE
        default: return true;                      // AL
    }
}

void CoeurCortexM::brancher(uint32_t adresse) { r_[15] = adresse & ~1u; }

// ---------------------------------------------------------------------------
// Exécution
// ---------------------------------------------------------------------------
uint64_t CoeurCortexM::executer(uint64_t cycles) {
    const uint64_t debut = cycles_;
    while (cycles_ - debut < cycles) {
        if (endormi_) {
            cycles_ += 1;
            avancer_peripheriques(1);
            continue;
        }
        const int passes = instruction();
        cycles_ += passes;
        avancer_peripheriques(passes);
    }
    rafraichir_sorties();
    return cycles_ - debut;
}

int CoeurCortexM::instruction() {
    const uint32_t adresse = r_[15];
    const uint16_t code = lire16(adresse);
    r_[15] = adresse + 2;
    // La valeur lue dans r15 est l'adresse de l'instruction plus quatre :
    // héritage du pipeline des premiers ARM, et toute adresse calculée
    // relativement au programme en dépend.
    const uint32_t pc_lu = (adresse + 4) & ~3u;

    const int haut5 = code >> 11;

    // --- 000xx : décalages immédiats, et add/sub registre
    if (haut5 <= 0x03) {
        const int rd = code & 7, rm = (code >> 3) & 7;
        const int rang = (code >> 6) & 0x1F;
        if (haut5 == 0x03) {                          // ADD/SUB
            const bool immediat = (code >> 10) & 1;
            const bool soustraction = (code >> 9) & 1;
            const uint32_t operande =
                immediat ? static_cast<uint32_t>((code >> 6) & 7) : r_[(code >> 6) & 7];
            if (soustraction) {
                poser_drapeaux_soustraction(r_[rm], operande);
                r_[rd] = r_[rm] - operande;
            } else {
                poser_drapeaux_addition(r_[rm], operande, 0);
                r_[rd] = r_[rm] + operande;
            }
            return 1;
        }
        const uint32_t valeur = r_[rm];
        uint32_t resultat = valeur;
        if (haut5 == 0x00) {                          // LSL
            if (rang) {
                c_ = (valeur >> (32 - rang)) & 1;
                resultat = valeur << rang;
            }
        } else if (haut5 == 0x01) {                   // LSR
            const int decalage = rang ? rang : 32;
            c_ = decalage < 32 ? ((valeur >> (decalage - 1)) & 1)
                               : ((valeur >> 31) & 1);
            resultat = decalage < 32 ? (valeur >> decalage) : 0;
        } else {                                      // ASR
            const int decalage = rang ? rang : 32;
            const int32_t signe = static_cast<int32_t>(valeur);
            c_ = decalage < 32 ? ((valeur >> (decalage - 1)) & 1)
                               : ((valeur >> 31) & 1);
            resultat = decalage < 32 ? static_cast<uint32_t>(signe >> decalage)
                                     : static_cast<uint32_t>(signe >> 31);
        }
        r_[rd] = resultat;
        poser_drapeaux_logiques(resultat);
        return 1;
    }

    // --- 001xx : mov/cmp/add/sub immédiats sur huit bits
    if (haut5 <= 0x07) {
        const int rd = (code >> 8) & 7;
        const uint32_t immediat = code & 0xFF;
        switch (haut5 & 3) {
            case 0: r_[rd] = immediat; poser_drapeaux_logiques(immediat); break;
            case 1: poser_drapeaux_soustraction(r_[rd], immediat); break;
            case 2:
                poser_drapeaux_addition(r_[rd], immediat, 0);
                r_[rd] += immediat;
                break;
            default:
                poser_drapeaux_soustraction(r_[rd], immediat);
                r_[rd] -= immediat;
                break;
        }
        return 1;
    }

    // --- 010000 : les seize opérations entre registres bas
    if ((code & 0xFC00) == 0x4000) {
        const int rd = code & 7, rm = (code >> 3) & 7;
        const int operation = (code >> 6) & 0x0F;
        uint32_t resultat = 0;
        switch (operation) {
            case 0x0: resultat = r_[rd] & r_[rm]; r_[rd] = resultat; break;   // AND
            case 0x1: resultat = r_[rd] ^ r_[rm]; r_[rd] = resultat; break;   // EOR
            case 0x2: {                                                       // LSL
                const uint32_t rang = r_[rm] & 0xFF;
                resultat = rang >= 32 ? 0 : (r_[rd] << rang);
                if (rang && rang <= 32)
                    c_ = rang == 32 ? (r_[rd] & 1)
                                    : ((r_[rd] >> (32 - rang)) & 1);
                else if (rang > 32) c_ = false;
                r_[rd] = resultat;
                break;
            }
            case 0x3: {                                                       // LSR
                const uint32_t rang = r_[rm] & 0xFF;
                resultat = rang >= 32 ? 0 : (r_[rd] >> rang);
                if (rang && rang <= 32)
                    c_ = rang == 32 ? ((r_[rd] >> 31) & 1)
                                    : ((r_[rd] >> (rang - 1)) & 1);
                else if (rang > 32) c_ = false;
                r_[rd] = resultat;
                break;
            }
            case 0x4: {                                                       // ASR
                const uint32_t rang = r_[rm] & 0xFF;
                const int32_t signe = static_cast<int32_t>(r_[rd]);
                resultat = rang >= 32 ? static_cast<uint32_t>(signe >> 31)
                                      : static_cast<uint32_t>(signe >> rang);
                if (rang)
                    c_ = rang >= 32 ? ((r_[rd] >> 31) & 1)
                                    : ((r_[rd] >> (rang - 1)) & 1);
                r_[rd] = resultat;
                break;
            }
            case 0x5:                                                         // ADC
                poser_drapeaux_addition(r_[rd], r_[rm], c_ ? 1 : 0);
                r_[rd] = r_[rd] + r_[rm] + (c_ ? 1 : 0);
                return 1;
            case 0x6:                                                         // SBC
                poser_drapeaux_addition(r_[rd], ~r_[rm], c_ ? 1 : 0);
                r_[rd] = r_[rd] + ~r_[rm] + (c_ ? 1 : 0);
                return 1;
            case 0x7:                                                         // ROR
                resultat = rotation_droite(r_[rd], r_[rm] & 0xFF);
                if (r_[rm] & 0xFF) c_ = (resultat >> 31) & 1;
                r_[rd] = resultat;
                break;
            case 0x8: resultat = r_[rd] & r_[rm]; break;                      // TST
            case 0x9:                                                         // NEG
                poser_drapeaux_soustraction(0, r_[rm]);
                r_[rd] = 0u - r_[rm];
                return 1;
            case 0xA: poser_drapeaux_soustraction(r_[rd], r_[rm]); return 1;  // CMP
            case 0xB: poser_drapeaux_addition(r_[rd], r_[rm], 0); return 1;   // CMN
            case 0xC: resultat = r_[rd] | r_[rm]; r_[rd] = resultat; break;   // ORR
            case 0xD: resultat = r_[rd] * r_[rm]; r_[rd] = resultat; break;   // MUL
            case 0xE: resultat = r_[rd] & ~r_[rm]; r_[rd] = resultat; break;  // BIC
            default: resultat = ~r_[rm]; r_[rd] = resultat; break;            // MVN
        }
        poser_drapeaux_logiques(resultat);
        return operation == 0xD ? 2 : 1;
    }

    // --- 010001 : opérations sur registres hauts, et branchement indirect
    if ((code & 0xFC00) == 0x4400) {
        const int operation = (code >> 8) & 3;
        const int rd = (code & 7) | ((code >> 4) & 8);
        const int rm = (code >> 3) & 0x0F;
        const uint32_t valeur = rm == 15 ? pc_lu : r_[rm];
        switch (operation) {
            case 0:                                          // ADD (sans drapeau)
                if (rd == 15) { brancher(r_[15] + valeur); return 2; }
                r_[rd] += valeur;
                return 1;
            case 1:                                          // CMP
                poser_drapeaux_soustraction(rd == 15 ? pc_lu : r_[rd], valeur);
                return 1;
            case 2:                                          // MOV
                if (rd == 15) { brancher(valeur); return 2; }
                r_[rd] = valeur;
                return 1;
            default: {                                       // BX / BLX
                const bool avec_lien = (code >> 7) & 1;
                if (avec_lien) r_[14] = r_[15] | 1;
                brancher(valeur);
                return 2;
            }
        }
    }

    // --- 01001 : chargement relatif au programme
    if (haut5 == 0x09) {
        const int rd = (code >> 8) & 7;
        r_[rd] = lire32(pc_lu + ((code & 0xFF) << 2));
        return 2;
    }

    // --- 0101 : chargements et rangements indexés par registre
    if ((code & 0xF000) == 0x5000) {
        const int rd = code & 7, rn = (code >> 3) & 7, rm = (code >> 6) & 7;
        const uint32_t cible = r_[rn] + r_[rm];
        switch ((code >> 9) & 7) {
            case 0: ecrire32(cible, r_[rd]); break;                        // STR
            case 1: ecrire16(cible, static_cast<uint16_t>(r_[rd])); break; // STRH
            case 2: ecrire8(cible, static_cast<uint8_t>(r_[rd])); break;   // STRB
            case 3:                                                        // LDRSB
                r_[rd] = static_cast<uint32_t>(
                    static_cast<int32_t>(static_cast<int8_t>(lire8(cible))));
                break;
            case 4: r_[rd] = lire32(cible); break;                         // LDR
            case 5: r_[rd] = lire16(cible); break;                         // LDRH
            case 6: r_[rd] = lire8(cible); break;                          // LDRB
            default:                                                       // LDRSH
                r_[rd] = static_cast<uint32_t>(
                    static_cast<int32_t>(static_cast<int16_t>(lire16(cible))));
                break;
        }
        return 2;
    }

    // --- 011 : chargements et rangements à décalage immédiat
    if ((code & 0xE000) == 0x6000) {
        const int rd = code & 7, rn = (code >> 3) & 7;
        const uint32_t rang = (code >> 6) & 0x1F;
        const bool octet = (code >> 12) & 1;
        const bool lecture = (code >> 11) & 1;
        const uint32_t cible = r_[rn] + (octet ? rang : rang * 4);
        if (lecture) r_[rd] = octet ? lire8(cible) : lire32(cible);
        else if (octet) ecrire8(cible, static_cast<uint8_t>(r_[rd]));
        else ecrire32(cible, r_[rd]);
        return 2;
    }

    // --- 1000 : demi-mots à décalage immédiat
    if ((code & 0xF000) == 0x8000) {
        const int rd = code & 7, rn = (code >> 3) & 7;
        const uint32_t cible = r_[rn] + (((code >> 6) & 0x1F) * 2);
        if ((code >> 11) & 1) r_[rd] = lire16(cible);
        else ecrire16(cible, static_cast<uint16_t>(r_[rd]));
        return 2;
    }

    // --- 1001 : chargements et rangements relatifs à la pile
    if ((code & 0xF000) == 0x9000) {
        const int rd = (code >> 8) & 7;
        const uint32_t cible = r_[13] + ((code & 0xFF) * 4);
        if ((code >> 11) & 1) r_[rd] = lire32(cible);
        else ecrire32(cible, r_[rd]);
        return 2;
    }

    // --- 1010 : calcul d'adresse (ADR / ADD Rd, SP)
    if ((code & 0xF000) == 0xA000) {
        const int rd = (code >> 8) & 7;
        const uint32_t decalage = (code & 0xFF) * 4;
        r_[rd] = ((code >> 11) & 1) ? r_[13] + decalage : pc_lu + decalage;
        return 1;
    }

    // --- 1011 : divers (pile, extensions, hints)
    if ((code & 0xF000) == 0xB000) {
        if ((code & 0xFF00) == 0xB000) {                 // ADD/SUB SP, #imm
            const uint32_t decalage = (code & 0x7F) * 4;
            if ((code >> 7) & 1) r_[13] -= decalage;
            else r_[13] += decalage;
            return 1;
        }
        if ((code & 0xFE00) == 0xB400) {                 // PUSH
            const bool avec_lien = (code >> 8) & 1;
            int nombre = avec_lien ? 1 : 0;
            for (int bit = 0; bit < 8; ++bit)
                if (code & (1 << bit)) ++nombre;
            uint32_t sommet = r_[13] - 4u * nombre;
            r_[13] = sommet;
            for (int bit = 0; bit < 8; ++bit) {
                if (!(code & (1 << bit))) continue;
                ecrire32(sommet, r_[bit]);
                sommet += 4;
            }
            if (avec_lien) ecrire32(sommet, r_[14]);
            return 1 + nombre;
        }
        if ((code & 0xFE00) == 0xBC00) {                 // POP
            const bool avec_pc = (code >> 8) & 1;
            uint32_t sommet = r_[13];
            int nombre = 0;
            for (int bit = 0; bit < 8; ++bit) {
                if (!(code & (1 << bit))) continue;
                r_[bit] = lire32(sommet);
                sommet += 4;
                ++nombre;
            }
            if (avec_pc) {
                const uint32_t retour = lire32(sommet);
                sommet += 4;
                ++nombre;
                r_[13] = sommet;
                brancher(retour);
                return 3 + nombre;
            }
            r_[13] = sommet;
            return 1 + nombre;
        }
        if ((code & 0xFF00) == 0xB200) {                 // SXTH/SXTB/UXTH/UXTB
            const int rd = code & 7, rm = (code >> 3) & 7;
            switch ((code >> 6) & 3) {
                case 0: r_[rd] = static_cast<uint32_t>(static_cast<int32_t>(
                            static_cast<int16_t>(r_[rm]))); break;
                case 1: r_[rd] = static_cast<uint32_t>(static_cast<int32_t>(
                            static_cast<int8_t>(r_[rm]))); break;
                case 2: r_[rd] = r_[rm] & 0xFFFF; break;
                default: r_[rd] = r_[rm] & 0xFF; break;
            }
            return 1;
        }
        if ((code & 0xFF00) == 0xBA00) {                 // REV / REV16 / REVSH
            const int rd = code & 7, rm = (code >> 3) & 7;
            const uint32_t v = r_[rm];
            switch ((code >> 6) & 3) {
                case 0:
                    r_[rd] = (v >> 24) | ((v >> 8) & 0xFF00)
                             | ((v << 8) & 0xFF0000) | (v << 24);
                    break;
                case 1:
                    r_[rd] = ((v >> 8) & 0x00FF00FF) | ((v << 8) & 0xFF00FF00);
                    break;
                default:
                    r_[rd] = static_cast<uint32_t>(static_cast<int32_t>(
                        static_cast<int16_t>(((v >> 8) & 0xFF) | (v << 8))));
                    break;
            }
            return 1;
        }
        // CPS, BKPT et les hints : rien à simuler, mais il faut les traverser.
        return 1;
    }

    // --- 1100 : chargements et rangements multiples
    if ((code & 0xF000) == 0xC000) {
        const int rn = (code >> 8) & 7;
        const bool lecture = (code >> 11) & 1;
        uint32_t curseur = r_[rn];
        int nombre = 0;
        for (int bit = 0; bit < 8; ++bit) {
            if (!(code & (1 << bit))) continue;
            if (lecture) r_[bit] = lire32(curseur);
            else ecrire32(curseur, r_[bit]);
            curseur += 4;
            ++nombre;
        }
        // Le registre d'adresse n'est remis à jour que s'il n'a pas été
        // rechargé au passage.
        if (!lecture || !(code & (1 << rn))) r_[rn] = curseur;
        return 1 + nombre;
    }

    // --- 1101 : branchements conditionnels et appel système
    if ((code & 0xF000) == 0xD000) {
        const int cond = (code >> 8) & 0x0F;
        if (cond == 0x0F) return 1;                      // SVC : sans effet ici
        if (cond == 0x0E) return 1;                      // instruction indéfinie
        if (!condition(cond)) return 1;
        const int32_t decalage = static_cast<int8_t>(code & 0xFF);
        brancher(static_cast<uint32_t>(r_[15] + 2 + decalage * 2));
        return 3;
    }

    // --- 11100 : branchement inconditionnel
    if ((code & 0xF800) == 0xE000) {
        int32_t decalage = static_cast<int32_t>(code << 21) >> 21;   // 11 bits
        brancher(static_cast<uint32_t>(r_[15] + 2 + decalage * 2));
        return 3;
    }

    // --- 111xx : instructions de trente-deux bits
    if ((code & 0xE000) == 0xE000) {
        const uint16_t second = lire16(r_[15]);
        r_[15] += 2;
        return instruction32(code, second);
    }

    return 1;
}

namespace {

// L'immédiat « modifié » de l'ARMv7-M : douze bits qui décrivent soit un
// octet répété selon un motif, soit une valeur de huit bits tournée. C'est ce
// qui permet de charger 0x00FF00FF ou 0x3F800000 en une instruction, et se
// tromper ici donne des constantes fausses sans le moindre signe extérieur.
uint32_t immediat_etendu(uint32_t douze_bits, bool* retenue) {
    const uint32_t haut = (douze_bits >> 10) & 3;
    const uint32_t octet = douze_bits & 0xFF;
    if (haut == 0) {
        switch ((douze_bits >> 8) & 3) {
            case 0: return octet;
            case 1: return (octet << 16) | octet;
            case 2: return (octet << 24) | (octet << 8);
            default: return (octet << 24) | (octet << 16) | (octet << 8) | octet;
        }
    }
    const uint32_t rang = (douze_bits >> 7) & 0x1F;
    const uint32_t valeur = 0x80u | (douze_bits & 0x7F);
    const uint32_t resultat = (valeur >> rang) | (valeur << (32 - rang));
    if (retenue) *retenue = (resultat >> 31) & 1;
    return resultat;
}

uint32_t decaler(uint32_t valeur, int type, int rang) {
    switch (type) {
        case 0: return rang ? (valeur << rang) : valeur;                  // LSL
        case 1: return rang ? (valeur >> rang) : 0;                       // LSR
        case 2: {                                                         // ASR
            const int32_t signe = static_cast<int32_t>(valeur);
            return static_cast<uint32_t>(signe >> (rang ? rang : 31));
        }
        default:                                                          // ROR
            if (!rang) return valeur;
            return (valeur >> rang) | (valeur << (32 - rang));
    }
}

}  // namespace

int CoeurCortexM::instruction32(uint16_t premier, uint16_t second) {
    // --- BL : le seul appel long qu'un Cortex-M0+ connaisse
    if ((premier & 0xF800) == 0xF000 && (second & 0xD000) == 0xD000) {
        const uint32_t s = (premier >> 10) & 1;
        const uint32_t haut = premier & 0x3FF;
        const uint32_t j1 = (second >> 13) & 1;
        const uint32_t j2 = (second >> 11) & 1;
        const uint32_t bas = second & 0x7FF;
        const uint32_t i1 = (~(j1 ^ s)) & 1;
        const uint32_t i2 = (~(j2 ^ s)) & 1;
        int32_t decalage = static_cast<int32_t>(
            (s << 24) | (i1 << 23) | (i2 << 22) | (haut << 12) | (bas << 1));
        decalage = (decalage << 7) >> 7;                 // extension du signe
        r_[14] = r_[15] | 1;
        brancher(static_cast<uint32_t>(r_[15] + decalage));
        return 4;
    }
    // Au-delà, c'est de l'ARMv7-M : un Cortex-M0+ ne les rencontre jamais.
    if (p_.architecture < 7) return 2;

    const int rd2 = (second >> 8) & 0x0F;
    const int rn1 = premier & 0x0F;
    const uint32_t i = (premier >> 10) & 1;
    const uint32_t imm3 = (second >> 12) & 7;
    const uint32_t douze = (i << 11) | (imm3 << 8) | (second & 0xFF);

    // --- MOVW et MOVT : charger seize bits d'un coup
    if ((premier & 0xFBF0) == 0xF240) {                  // MOVW
        const uint32_t imm16 = (static_cast<uint32_t>(rn1) << 12)
                               | (i << 11) | (imm3 << 8) | (second & 0xFF);
        r_[rd2] = imm16;
        return 1;
    }
    if ((premier & 0xFBF0) == 0xF2C0) {                  // MOVT
        const uint32_t imm16 = (static_cast<uint32_t>(rn1) << 12)
                               | (i << 11) | (imm3 << 8) | (second & 0xFF);
        r_[rd2] = (r_[rd2] & 0xFFFF) | (imm16 << 16);
        return 1;
    }
    // --- ADDW et SUBW : douze bits sans motif, et sans toucher aux drapeaux
    if ((premier & 0xFBF0) == 0xF200) {
        r_[rd2] = (rn1 == 15 ? ((r_[15] + 2) & ~3u) : r_[rn1]) + douze;
        return 1;
    }
    if ((premier & 0xFBF0) == 0xF2A0) {
        r_[rd2] = (rn1 == 15 ? ((r_[15] + 2) & ~3u) : r_[rn1]) - douze;
        return 1;
    }

    // --- opérations sur immédiat modifié
    if ((premier & 0xFA00) == 0xF000 && (second & 0x8000) == 0) {
        const int operation = (premier >> 5) & 0x0F;
        const bool drapeaux = (premier >> 4) & 1;
        const uint32_t valeur = immediat_etendu(douze, nullptr);
        const uint32_t a = r_[rn1];
        uint32_t resultat = 0;
        bool ecrire_resultat = true;
        switch (operation) {
            case 0x0: resultat = a & valeur; break;                    // AND/TST
            case 0x1: resultat = a & ~valeur; break;                   // BIC
            case 0x2: resultat = rn1 == 15 ? valeur : (a | valeur); break;  // ORR/MOV
            case 0x3: resultat = rn1 == 15 ? ~valeur : (a & ~valeur); break; // ORN/MVN
            case 0x4: resultat = a ^ valeur; break;                    // EOR/TEQ
            case 0x8:                                                  // ADD/CMN
                if (drapeaux) poser_drapeaux_addition(a, valeur, 0);
                resultat = a + valeur;
                break;
            case 0xA:                                                  // ADC
                if (drapeaux) poser_drapeaux_addition(a, valeur, c_ ? 1 : 0);
                resultat = a + valeur + (c_ ? 1 : 0);
                break;
            case 0xB:                                                  // SBC
                if (drapeaux) poser_drapeaux_addition(a, ~valeur, c_ ? 1 : 0);
                resultat = a + ~valeur + (c_ ? 1 : 0);
                break;
            case 0xD:                                                  // SUB/CMP
                if (drapeaux) poser_drapeaux_soustraction(a, valeur);
                resultat = a - valeur;
                break;
            case 0xE:                                                  // RSB
                if (drapeaux) poser_drapeaux_soustraction(valeur, a);
                resultat = valeur - a;
                break;
            default: return 1;
        }
        // Rd = 15 avec drapeaux, c'est une comparaison : rien n'est rangé.
        if (rd2 == 15 && drapeaux) ecrire_resultat = false;
        if (drapeaux && operation <= 0x4) poser_drapeaux_logiques(resultat);
        if (ecrire_resultat) r_[rd2] = resultat;
        return 1;
    }

    // --- branchements longs et conditionnels
    if ((premier & 0xF800) == 0xF000 && (second & 0x5000) == 0x1000) {
        // B.W inconditionnel : vingt-quatre bits de portée.
        const uint32_t s = (premier >> 10) & 1;
        const uint32_t j1 = (second >> 13) & 1;
        const uint32_t j2 = (second >> 11) & 1;
        const uint32_t i1 = (~(j1 ^ s)) & 1;
        const uint32_t i2 = (~(j2 ^ s)) & 1;
        int32_t decalage = static_cast<int32_t>(
            (s << 24) | (i1 << 23) | (i2 << 22) | ((premier & 0x3FF) << 12)
            | ((second & 0x7FF) << 1));
        decalage = (decalage << 7) >> 7;
        brancher(static_cast<uint32_t>(r_[15] + decalage));
        return 4;
    }
    if ((premier & 0xF800) == 0xF000 && (second & 0xD000) == 0x8000) {
        const int cond = (premier >> 6) & 0x0F;
        if (cond >= 0x0E) return 2;                      // MSR/MRS, sans effet
        if (!condition(cond)) return 1;
        const uint32_t s = (premier >> 10) & 1;
        int32_t decalage = static_cast<int32_t>(
            (s << 20) | (((second >> 11) & 1) << 19) | (((second >> 13) & 1) << 18)
            | ((premier & 0x3F) << 12) | ((second & 0x7FF) << 1));
        decalage = (decalage << 11) >> 11;
        brancher(static_cast<uint32_t>(r_[15] + decalage));
        return 4;
    }

    // --- chargements et rangements multiples, dont PUSH.W et POP.W
    if ((premier & 0xFE40) == 0xE800) {
        const bool lecture = (premier >> 4) & 1;
        const bool decroissant = (premier >> 8) & 1;     // DB plutôt que IA
        const bool ecriture_arriere = (premier >> 5) & 1;
        const uint16_t liste = second;
        int nombre = 0;
        for (int bit = 0; bit < 16; ++bit)
            if (liste & (1 << bit)) ++nombre;
        uint32_t curseur = decroissant ? r_[rn1] - 4u * nombre : r_[rn1];
        const uint32_t depart = curseur;
        for (int bit = 0; bit < 16; ++bit) {
            if (!(liste & (1 << bit))) continue;
            if (lecture) {
                const uint32_t lu = lire32(curseur);
                if (bit == 15) brancher(lu);
                else r_[bit] = lu;
            } else {
                ecrire32(curseur, r_[bit]);
            }
            curseur += 4;
        }
        if (ecriture_arriere)
            r_[rn1] = decroissant ? depart : curseur;
        return 1 + nombre;
    }

    // --- décalages et extensions sur registre
    if ((premier & 0xFF80) == 0xFA00 || (premier & 0xFF80) == 0xFA20
        || (premier & 0xFF80) == 0xFA40 || (premier & 0xFF80) == 0xFA60) {
        const int type = (premier >> 5) & 3;
        const int rm = second & 0x0F;
        r_[rd2] = decaler(r_[rn1], type, r_[rm] & 0xFF);
        if ((premier >> 4) & 1) poser_drapeaux_logiques(r_[rd2]);
        return 1;
    }
    if ((premier & 0xFF80) == 0xFA80 || (premier & 0xFF80) == 0xFA00) {
        // UXTB.W, SXTB.W, UXTH.W, SXTH.W : Rn vaut 15 dans ces formes.
        if (rn1 == 15) {
            const int rm = second & 0x0F;
            const uint32_t v = rotation_droite(r_[rm], ((second >> 4) & 3) * 8);
            switch ((premier >> 4) & 0x0F) {
                case 0x0: r_[rd2] = static_cast<uint32_t>(
                              static_cast<int32_t>(static_cast<int16_t>(v)));
                    break;
                case 0x4: r_[rd2] = static_cast<uint32_t>(
                              static_cast<int32_t>(static_cast<int8_t>(v)));
                    break;
                case 0x1: r_[rd2] = v & 0xFFFF; break;
                default: r_[rd2] = v & 0xFF; break;
            }
            return 1;
        }
    }

    // --- multiplication et division
    if ((premier & 0xFFF0) == 0xFB00) {
        const int rm = second & 0x0F;
        const int ra = (second >> 12) & 0x0F;
        if (((second >> 4) & 0x0F) == 0) {
            r_[rd2] = ra == 15 ? r_[rn1] * r_[rm]         // MUL
                               : r_[ra] + r_[rn1] * r_[rm];  // MLA
        } else {
            r_[rd2] = r_[ra] - r_[rn1] * r_[rm];          // MLS
        }
        return 2;
    }
    if ((premier & 0xFFF0) == 0xFB90 || (premier & 0xFFF0) == 0xFBB0) {
        const int rm = second & 0x0F;
        const bool signee = (premier & 0x0020) == 0;
        if (r_[rm] == 0) {
            r_[rd2] = 0;                                  // division par zéro
        } else if (signee) {
            r_[rd2] = static_cast<uint32_t>(static_cast<int32_t>(r_[rn1])
                                            / static_cast<int32_t>(r_[rm]));
        } else {
            r_[rd2] = r_[rn1] / r_[rm];
        }
        return 12;
    }

    // --- chargements et rangements simples
    if ((premier & 0xFE00) == 0xF800) {
        const int rt = (second >> 12) & 0x0F;
        const int taille = (premier >> 5) & 3;           // 0 octet, 1 demi, 2 mot
        const bool lecture = (premier >> 4) & 1;
        const bool signee = (premier >> 8) & 1;
        uint32_t adresse = 0;
        int cycles = 2;

        if ((premier & 0x0080) != 0) {                   // forme à douze bits
            adresse = r_[rn1] + (second & 0x0FFF);
        } else if ((second & 0x0F00) == 0) {             // indexé par registre
            const int rm = second & 0x0F;
            adresse = r_[rn1] + (r_[rm] << ((second >> 4) & 3));
        } else {                                         // huit bits, indexé
            const bool avant = (second >> 10) & 1;
            const bool ajouter = (second >> 9) & 1;
            const bool arriere = (second >> 8) & 1;
            const uint32_t decalage = second & 0xFF;
            const uint32_t base = r_[rn1];
            const uint32_t decale = ajouter ? base + decalage : base - decalage;
            adresse = avant ? decale : base;
            if (arriere || !avant) r_[rn1] = decale;
        }
        if (rn1 == 15) adresse = ((r_[15] + 2) & ~3u) + (second & 0x0FFF);

        if (lecture) {
            uint32_t lu = 0;
            if (taille == 2) lu = lire32(adresse);
            else if (taille == 1)
                lu = signee ? static_cast<uint32_t>(static_cast<int32_t>(
                         static_cast<int16_t>(lire16(adresse))))
                            : lire16(adresse);
            else
                lu = signee ? static_cast<uint32_t>(static_cast<int32_t>(
                         static_cast<int8_t>(lire8(adresse))))
                            : lire8(adresse);
            r_[rt] = lu;
        } else {
            if (taille == 2) ecrire32(adresse, r_[rt]);
            else if (taille == 1) ecrire16(adresse, static_cast<uint16_t>(r_[rt]));
            else ecrire8(adresse, static_cast<uint8_t>(r_[rt]));
        }
        return cycles;
    }

    // --- opérations entre registres, avec décalage constant
    if ((premier & 0xFE00) == 0xEA00) {
        const int operation = (premier >> 5) & 0x0F;
        const bool drapeaux = (premier >> 4) & 1;
        const int rm = second & 0x0F;
        const int type = (second >> 4) & 3;
        const int rang = (((second >> 12) & 7) << 2) | ((second >> 6) & 3);
        const uint32_t b = decaler(r_[rm], type, rang);
        const uint32_t a = r_[rn1];
        uint32_t resultat = 0;
        switch (operation) {
            case 0x0: resultat = a & b; break;
            case 0x1: resultat = a & ~b; break;
            case 0x2: resultat = rn1 == 15 ? b : (a | b); break;
            case 0x3: resultat = rn1 == 15 ? ~b : (a | ~b); break;
            case 0x4: resultat = a ^ b; break;
            case 0x8:
                if (drapeaux) poser_drapeaux_addition(a, b, 0);
                resultat = a + b;
                break;
            case 0xD:
                if (drapeaux) poser_drapeaux_soustraction(a, b);
                resultat = a - b;
                break;
            case 0xE:
                if (drapeaux) poser_drapeaux_soustraction(b, a);
                resultat = b - a;
                break;
            default: return 1;
        }
        if (drapeaux && operation <= 0x4) poser_drapeaux_logiques(resultat);
        if (!(rd2 == 15 && drapeaux)) r_[rd2] = resultat;
        return 1;
    }

    // MSR, MRS, DMB, DSB, ISB et les rares formes non modélisées.
    return 2;
}

}  // namespace coeur
