#include "core/engines/CoeurXtensa.h"

#include <algorithm>
#include <cstring>
#include <fstream>
#include <iterator>

namespace coeur {

namespace {
// Extension de signe d'un champ de `bits` bits.
//
// Écrire « (x << 21) >> 21 » est le raccourci habituel, et c'est un
// comportement INDÉFINI dès que le décalage déborde du type signé : le
// compilateur a le droit d'en faire ce qu'il veut. On décale donc dans un
// type non signé, où le débordement est défini, et l'on convertit ensuite.
inline int32_t etendre_signe(uint32_t valeur, int bits) {
    const uint32_t masque = 1u << (bits - 1);
    valeur &= (bits >= 32) ? 0xFFFFFFFFu : ((1u << bits) - 1u);
    return static_cast<int32_t>((valeur ^ masque) - masque);
}
}  // namespace

// Adresses confrontées à l'en-tête officiel d'Espressif
// (esp-idf, components/soc/esp32/register/soc/gpio_reg.h) et à soc.h :
//   DR_REG_GPIO_BASE  0x3FF4 4000
//   OUT 0x04, OUT_W1TS 0x08, OUT_W1TC 0x0C
//   ENABLE 0x20, ENABLE_W1TS 0x24, ENABLE_W1TC 0x28, IN 0x3C
const ProfilXtensa& profil_esp32() {
    static const ProfilXtensa profil = [] {
        ProfilXtensa p;
        p.nom = "esp32";
        p.frequence = 240000000;
        // Mémoire interne : la fenêtre d'instructions à 0x400 80000, les
        // données à 0x3FFB0000, et la mémoire vive interne. On accepte aussi
        // une plage basse, où atterrit un programme assemblé à la main.
        p.memoires = {{0x00000000, 0x00010000},
                      {0x3FFB0000, 0x00050000},
                      {0x40080000, 0x00020000},
                      {0x400D0000, 0x00100000}};
        return p;
    }();
    return profil;
}

const ProfilXtensa* profil_xtensa_par_nom(const std::string& nom) {
    if (nom == "esp32") return &profil_esp32();
    return nullptr;
}

CoeurXtensa::CoeurXtensa() : CoeurXtensa(profil_esp32()) {}

CoeurXtensa::CoeurXtensa(const ProfilXtensa& profil) { definir_profil(profil); }

void CoeurXtensa::definir_profil(const ProfilXtensa& profil) {
    p_ = profil;
    frequence_ = profil.frequence;
    memoire_.clear();
    for (const ProfilXtensa::Plage& plage : p_.memoires) {
        Bloc bloc;
        bloc.debut = plage.debut;
        bloc.octets.assign(plage.taille, 0);
        memoire_.push_back(std::move(bloc));
    }
    charge_ = false;
    reinitialiser();
}

void CoeurXtensa::reinitialiser() {
    for (uint32_t& registre : a_) registre = 0;
    cycles_ = 0;
    arrete_ = false;
    gpio_sortie_ = gpio_direction_ = gpio_entree_ = 0;
    gpio_connue_ = gpio_connue_direction_ = 0;
    sorties_valides_ = false;
    // La pile en haut de la mémoire de données : c'est ce que pose le
    // démarrage d'un vrai ESP32.
    a_[1] = 0x3FFB0000 + 0x00050000 - 16;
}

// ---------------------------------------------------------------------------
// Mémoire
// ---------------------------------------------------------------------------
uint8_t* CoeurXtensa::trouver(uint32_t adresse, uint32_t longueur) {
    for (Bloc& bloc : memoire_) {
        if (adresse < bloc.debut) continue;
        const uint32_t decalage = adresse - bloc.debut;
        if (decalage + longueur > bloc.octets.size()) continue;
        return &bloc.octets[decalage];
    }
    return nullptr;
}

const uint8_t* CoeurXtensa::trouver(uint32_t adresse, uint32_t longueur) const {
    return const_cast<CoeurXtensa*>(this)->trouver(adresse, longueur);
}

uint32_t CoeurXtensa::lire32(uint32_t adresse) const {
    uint32_t valeur = 0;
    if (const_cast<CoeurXtensa*>(this)->lire_peripherique(adresse, &valeur))
        return valeur;
    const uint8_t* p = trouver(adresse, 4);
    if (!p) return 0;
    return static_cast<uint32_t>(p[0]) | (static_cast<uint32_t>(p[1]) << 8)
           | (static_cast<uint32_t>(p[2]) << 16)
           | (static_cast<uint32_t>(p[3]) << 24);
}

uint8_t CoeurXtensa::lire8(uint32_t adresse) const {
    const uint8_t* p = trouver(adresse, 1);
    return p ? *p : 0;
}

void CoeurXtensa::ecrire32(uint32_t adresse, uint32_t valeur) {
    if (ecrire_peripherique(adresse, valeur)) return;
    uint8_t* p = trouver(adresse, 4);
    if (!p) return;
    p[0] = static_cast<uint8_t>(valeur);
    p[1] = static_cast<uint8_t>(valeur >> 8);
    p[2] = static_cast<uint8_t>(valeur >> 16);
    p[3] = static_cast<uint8_t>(valeur >> 24);
}

void CoeurXtensa::ecrire8(uint32_t adresse, uint8_t valeur) {
    uint8_t* p = trouver(adresse, 1);
    if (p) *p = valeur;
}

// ---------------------------------------------------------------------------
// Le bloc GPIO
// ---------------------------------------------------------------------------
bool CoeurXtensa::lire_peripherique(uint32_t adresse, uint32_t* valeur) const {
    if (adresse < p_.gpio_base || adresse >= p_.gpio_base + 0x100) return false;
    const uint32_t decalage = adresse - p_.gpio_base;
    if (decalage == p_.gpio_sortie) *valeur = gpio_sortie_;
    else if (decalage == p_.gpio_direction) *valeur = gpio_direction_;
    else if (decalage == p_.gpio_entree)
        *valeur = (gpio_sortie_ & gpio_direction_)
                  | (gpio_entree_ & ~gpio_direction_);
    else *valeur = 0;
    return true;
}

bool CoeurXtensa::ecrire_peripherique(uint32_t adresse, uint32_t valeur) {
    if (adresse < p_.gpio_base || adresse >= p_.gpio_base + 0x100) return false;
    const uint32_t decalage = adresse - p_.gpio_base;
    if (decalage == p_.gpio_sortie) gpio_sortie_ = valeur;
    else if (decalage == p_.gpio_sortie_poser) gpio_sortie_ |= valeur;
    else if (decalage == p_.gpio_sortie_effacer) gpio_sortie_ &= ~valeur;
    else if (decalage == p_.gpio_direction) gpio_direction_ = valeur;
    else if (decalage == p_.gpio_direction_poser) gpio_direction_ |= valeur;
    else if (decalage == p_.gpio_direction_effacer) gpio_direction_ &= ~valeur;
    else return true;
    rafraichir_sorties();
    return true;
}

void CoeurXtensa::rafraichir_sorties() {
    const uint32_t change =
        sorties_valides_ ? ((gpio_sortie_ ^ gpio_connue_)
                            | (gpio_direction_ & ~gpio_connue_direction_))
                         : 0xFFFFFFFFu;
    gpio_connue_ = gpio_sortie_;
    gpio_connue_direction_ = gpio_direction_;
    sorties_valides_ = true;
    if (!sur_broche) return;
    for (int bit = 0; bit < 32; ++bit) {
        const uint32_t masque = 1u << bit;
        if (!(change & masque) || !(gpio_direction_ & masque)) continue;
        sur_broche(bit, (gpio_sortie_ & masque) != 0);
    }
}

void CoeurXtensa::broche_externe(int broche, bool haut) {
    if (broche < 0 || broche > 31) return;
    if (haut) gpio_entree_ |= 1u << broche;
    else gpio_entree_ &= ~(1u << broche);
}

bool CoeurXtensa::broche_en_sortie(int broche) const {
    return broche >= 0 && broche < 32 && ((gpio_direction_ >> broche) & 1);
}

bool CoeurXtensa::broche_haute(int broche) const {
    return broche >= 0 && broche < 32 && ((gpio_sortie_ >> broche) & 1);
}

// ---------------------------------------------------------------------------
// Chargement
// ---------------------------------------------------------------------------
void CoeurXtensa::charger_octets(uint32_t adresse,
                                 const std::vector<uint8_t>& octets) {
    uint8_t* p = trouver(adresse, static_cast<uint32_t>(octets.size()));
    if (!p) return;
    std::memcpy(p, octets.data(), octets.size());
    charge_ = true;
    pc_ = adresse;
}

bool CoeurXtensa::charger(const std::string& chemin, std::string* erreur) {
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
    auto mot = [&contenu](size_t k) {
        return static_cast<uint32_t>(contenu[k]) | (contenu[k + 1] << 8)
               | (contenu[k + 2] << 16) | (contenu[k + 3] << 24);
    };
    const uint32_t debut_segments = mot(28);
    const uint16_t taille_segment =
        static_cast<uint16_t>(contenu[42] | (contenu[43] << 8));
    const uint16_t nombre_segments =
        static_cast<uint16_t>(contenu[44] | (contenu[45] << 8));

    definir_profil(p_);
    bool quelque_chose = false;
    for (int k = 0; k < nombre_segments; ++k) {
        const size_t base = debut_segments + static_cast<size_t>(k) * taille_segment;
        if (base + 32 > contenu.size()) break;
        if (mot(base) != 1) continue;
        const uint32_t decalage = mot(base + 4);
        const uint32_t adresse = mot(base + 8);
        const uint32_t longueur = mot(base + 16);
        if (longueur == 0 || decalage + longueur > contenu.size()) continue;
        uint8_t* p = trouver(adresse, longueur);
        if (!p) continue;
        std::memcpy(p, &contenu[decalage], longueur);
        quelque_chose = true;
    }
    if (!quelque_chose) {
        if (erreur) *erreur = "aucun segment chargeable dans " + chemin;
        return false;
    }
    reinitialiser();
    pc_ = mot(24);                         // point d'entrée déclaré par l'ELF
    charge_ = true;
    return true;
}

// ---------------------------------------------------------------------------
// Exécution
// ---------------------------------------------------------------------------
uint64_t CoeurXtensa::executer(uint64_t cycles) {
    const uint64_t debut = cycles_;
    while (cycles_ - debut < cycles) {
        // Une machine arrêtée ne consomme plus rien : continuer à compter
        // rendrait toute mesure de durée impossible, puisque le compteur
        // finirait toujours par atteindre le budget demandé.
        if (arrete_) break;
        cycles_ += instruction();
    }
    rafraichir_sorties();
    return cycles_ - debut;
}

int CoeurXtensa::instruction() {
    const uint32_t depart = pc_;
    // Le verrouillage de charge : si l'instruction qui vient lit le registre
    // qu'un chargement n'a pas fini de remplir, le processeur l'attend. C'est
    // ce qui distingue une boucle de recopie mémoire d'une boucle de calcul,
    // et l'ignorer les rend indiscernables.
    int attente = 0;
    if (attente_charge_ > 0 && registre_charge_ >= 0) {
        const uint8_t suivant0 = lire8(depart);
        const uint8_t suivant1 = lire8(depart + 1);
        const int lit_s = suivant1 & 0x0F;
        const int lit_t = (suivant0 >> 4) & 0x0F;
        if (lit_s == registre_charge_ || lit_t == registre_charge_)
            attente = attente_charge_;
    }
    attente_charge_ = 0;
    registre_charge_ = -1;
    const int cout = instruction_seule(depart);
    return cout + attente;
}

int CoeurXtensa::instruction_seule(const uint32_t depart) {
    const uint8_t b0 = lire8(depart);
    const int op0 = b0 & 0x0F;

    // Une instruction fait deux octets si son op0 la range dans le jeu dense,
    // trois sinon. Se tromper ici décale tout ce qui suit — et rien ne le
    // signale, l'exécution continue sur des instructions inventées.
    const bool courte = op0 == 0x08 || op0 == 0x09 || op0 == 0x0C || op0 == 0x0D;
    const uint8_t b1 = lire8(depart + 1);
    const uint8_t b2 = courte ? 0 : lire8(depart + 2);
    pc_ = depart + (courte ? 2 : 3);

    const int t = (b0 >> 4) & 0x0F;
    const int s = b1 & 0x0F;
    const int r = (b1 >> 4) & 0x0F;

    if (courte) {
        // Formes denses. Attention : elles n'ont PAS pu être vérifiées contre
        // un assembleur — celui de LLVM ne les produit pas —, à la différence
        // de tout ce qui suit. Elles sont écrites d'après la documentation, et
        // devront être confrontées le jour où une chaîne Xtensa sera là.
        switch (op0) {
            case 0x08: a_[t] = lire32(a_[s] + (r << 2)); return 2;   // L32I.N
            case 0x09: ecrire32(a_[s] + (r << 2), a_[t]); return 2;  // S32I.N
            case 0x0C:
                if ((b1 & 0x80) == 0) {                              // MOVI.N
                    int32_t valeur = ((b1 & 0x70) << 0) | s;
                    valeur = static_cast<int32_t>(((b1 & 0x70) >> 4) << 4) | s;
                    if (valeur > 95) valeur -= 128;
                    a_[t] = static_cast<uint32_t>(valeur);
                    return 1;
                }
                a_[r] = a_[s] + a_[t];                               // ADD.N
                return 1;
            default:                                                 // 0x0D
                if (r == 0x00) { a_[t] = a_[s]; return 1; }          // MOV.N
                if (b0 == 0xF0 && b1 == 0x0D) { arrete_ = true; return 1; }
                return 1;
        }
    }

    switch (op0) {
        case 0x00: {
            // Format RRR : l'opération est dans le troisième octet, quartet
            // bas puis quartet haut. C'est l'assembleur qui l'a dit —
            // « add a6, a2, a3 » vaut 30 62 80.
            const int op1 = b2 & 0x0F;
            const int op2 = (b2 >> 4) & 0x0F;
            if (b0 == 0x80 && b1 == 0x00 && b2 == 0x00) {            // RET
                arrete_ = true;
                return 2;
            }
            if (op1 == 0x00) {
                switch (op2) {
                    case 0x00: return 1;                             // groupe
                    case 0x01: a_[r] = a_[s] & a_[t]; return 1;      // AND
                    case 0x02: a_[r] = a_[s] | a_[t]; return 1;      // OR
                    case 0x03: a_[r] = a_[s] ^ a_[t]; return 1;      // XOR
                    case 0x08: a_[r] = a_[s] + a_[t]; return 1;      // ADD
                    case 0x0C: a_[r] = a_[s] - a_[t]; return 1;      // SUB
                    default: return 1;
                }
            }
            if (op1 == 0x01) {
                // SLLI : le décalage est rangé complémenté à trente-deux, sur
                // cinq bits dont le plus haut vit dans op1.
                const int sa = ((op1 & 1) << 4) | t;
                a_[r] = a_[s] << (32 - sa);
                return 1;
            }
            if (op1 == 0x04 || op1 == 0x05) {                        // SRLI
                a_[r] = a_[t] >> s;
                return 1;
            }
            return 1;
        }
        case 0x01: {                                                 // L32R
            // La constante vit AVANT le programme, dans le bassin littéral.
            // Le décalage est négatif : c'est ce qui rend cette instruction
            // si déroutante, et c'est par elle que passe toute adresse de
            // périphérique.
            const uint32_t brut = (static_cast<uint32_t>(b2) << 8) | b1;
            const uint32_t source = ((depart + 3) & ~3u)
                                    - ((0x10000u - brut) << 2);
            a_[t] = lire32(source);
            registre_charge_ = t;
            attente_charge_ = 1;
            return 1;
        }
        case 0x02: {
            // Format RRI8 : `r` choisit l'opération, `b2` porte huit bits.
            const int32_t signe = static_cast<int8_t>(b2);
            switch (r) {
                case 0x00:                                           // L8UI
                    a_[t] = lire8(a_[s] + b2);
                    registre_charge_ = t;
                    attente_charge_ = 1;
                    return 1;
                case 0x02:                                           // L32I
                    a_[t] = lire32(a_[s] + (b2 << 2));
                    registre_charge_ = t;
                    attente_charge_ = 1;
                    return 1;
                case 0x04: ecrire8(a_[s] + b2, static_cast<uint8_t>(a_[t]));
                    return 1;                                        // S8I
                case 0x06: ecrire32(a_[s] + (b2 << 2), a_[t]); return 1;  // S32I
                case 0x0A: {                                         // MOVI
                    const int32_t valeur =
                        etendre_signe((s << 8) | b2, 12);
                    a_[t] = static_cast<uint32_t>(valeur);
                    return 1;
                }
                case 0x0C: a_[t] = a_[s] + static_cast<uint32_t>(signe);
                    return 1;                                        // ADDI
                case 0x0D: a_[t] = a_[s] + (static_cast<uint32_t>(signe) << 8);
                    return 1;                                        // ADDMI
                default: return 1;
            }
        }
        case 0x06: {
            const int sous = t & 0x03;
            if (sous == 0x00) {                                      // J
                const int32_t decalage = etendre_signe(
                    (static_cast<uint32_t>(b2) << 10)
                        | (static_cast<uint32_t>(b1) << 2) | ((t >> 2) & 3),
                    18);
                pc_ = static_cast<uint32_t>(depart + 4 + decalage);
                return 3;      // saut pris : le pipeline se recharge
            }
            if (sous == 0x01) {                                      // BEQZ…
                const int32_t decalage = etendre_signe(
                    (static_cast<uint32_t>(b2) << 4) | ((b1 >> 4) & 0x0F), 12);
                const int genre = (t >> 2) & 3;
                bool prendre = false;
                switch (genre) {
                    case 0: prendre = a_[s] == 0; break;             // BEQZ
                    case 1: prendre = a_[s] != 0; break;             // BNEZ
                    case 2: prendre = static_cast<int32_t>(a_[s]) < 0; break;
                    default: prendre = static_cast<int32_t>(a_[s]) >= 0; break;
                }
                if (prendre) pc_ = static_cast<uint32_t>(depart + 4 + decalage);
                return prendre ? 3 : 1;
            }
            return 1;
        }
        case 0x07: {                                                 // BEQ, BNE…
            const int32_t decalage = static_cast<int8_t>(b2);
            bool prendre = false;
            switch (r) {
                case 0x01: prendre = a_[s] == a_[t]; break;          // BEQ
                case 0x09: prendre = a_[s] != a_[t]; break;          // BNE
                case 0x02: prendre = static_cast<int32_t>(a_[s])
                                     < static_cast<int32_t>(a_[t]); break;
                case 0x0A: prendre = static_cast<int32_t>(a_[s])
                                     >= static_cast<int32_t>(a_[t]); break;
                case 0x03: prendre = a_[s] < a_[t]; break;           // BLTU
                case 0x0B: prendre = a_[s] >= a_[t]; break;          // BGEU
                default: break;
            }
            if (prendre) pc_ = static_cast<uint32_t>(depart + 4 + decalage);
            return prendre ? 3 : 1;
        }
        default: return 1;
    }
}

}  // namespace coeur
