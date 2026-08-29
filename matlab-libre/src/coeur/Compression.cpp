// Compression.cpp — DEFLATE (RFC 1951) et son enveloppe zlib (RFC 1950).
//
// Le décodeur suit la norme telle qu'elle est écrite : un lecteur de bits
// à poids faible d'abord, deux arbres de Huffman canoniques par bloc, et
// la fenêtre de recopie de trente-deux kilooctets qu'on tient dans la
// sortie elle-même. Rien n'est repris d'une implémentation existante.
#include "matlibre/Compression.h"

#include <cstdint>
#include <cstring>
#include <vector>

#include "matlibre/Erreur.h"

namespace matlibre {

namespace {

// Lecture bit à bit, poids faible d'abord : c'est l'ordre de DEFLATE.
class LecteurBits {
public:
    LecteurBits(const unsigned char* d, std::size_t n) : d_(d), n_(n) {}

    unsigned lire(int combien) {
        while (bits_ < combien) {
            if (position_ >= n_)
                erreur("MATLAB:load:fluxTronque", "Compressed stream ends too early.");
            tampon_ |= (std::uint32_t)d_[position_++] << bits_;
            bits_ += 8;
        }
        unsigned v = tampon_ & ((1u << combien) - 1u);
        tampon_ >>= combien;
        bits_ -= combien;
        return v;
    }

    void alignerOctet() {
        tampon_ = 0;
        bits_ = 0;
    }

    // Après alignement : les octets bruts d'un bloc « stocké ».
    const unsigned char* octets(std::size_t combien) {
        if (position_ + combien > n_)
            erreur("MATLAB:load:fluxTronque", "Compressed stream ends too early.");
        const unsigned char* p = d_ + position_;
        position_ += combien;
        return p;
    }

    std::size_t position() const { return position_; }

private:
    const unsigned char* d_;
    std::size_t n_;
    std::size_t position_ = 0;
    std::uint32_t tampon_ = 0;
    int bits_ = 0;
};

// Un arbre de Huffman canonique, décrit par la seule longueur de chaque
// code — c'est tout ce que le flux transmet. On décode en descendant
// longueur par longueur, ce qui suffit largement ici : le premier code de
// chaque longueur et le rang du symbole donnent l'indice directement.
class Huffman {
public:
    void construire(const unsigned char* longueurs, std::size_t nombre) {
        compte_.assign(16, 0);
        symboles_.assign(nombre, 0);
        for (std::size_t k = 0; k < nombre; ++k) compte_[longueurs[k]]++;
        compte_[0] = 0;
        std::vector<int> decalages(16, 0);
        for (int l = 1; l < 16; ++l) decalages[l] = decalages[l - 1] + compte_[l - 1];
        for (std::size_t k = 0; k < nombre; ++k)
            if (longueurs[k]) symboles_[(std::size_t)decalages[longueurs[k]]++] = (int)k;
    }

    int decoder(LecteurBits& bits) const {
        int code = 0, premier = 0, indice = 0;
        for (int longueur = 1; longueur < 16; ++longueur) {
            code |= (int)bits.lire(1);
            int combien = compte_[longueur];
            if (code - premier < combien) return symboles_[(std::size_t)(indice + code - premier)];
            indice += combien;
            premier = (premier + combien) << 1;
            code <<= 1;
        }
        erreur("MATLAB:load:codeInvalide", "Invalid Huffman code in compressed stream.");
    }

private:
    std::vector<int> compte_;
    std::vector<int> symboles_;
};

// Les tables fixes de la norme : longueurs et distances des blocs de
// type 1, qui ne transmettent aucun arbre.
void arbresFixes(Huffman& litteraux, Huffman& distances) {
    unsigned char l[288];
    for (int k = 0; k < 144; ++k) l[k] = 8;
    for (int k = 144; k < 256; ++k) l[k] = 9;
    for (int k = 256; k < 280; ++k) l[k] = 7;
    for (int k = 280; k < 288; ++k) l[k] = 8;
    litteraux.construire(l, 288);
    unsigned char d[30];
    for (int k = 0; k < 30; ++k) d[k] = 5;
    distances.construire(d, 30);
}

const int LONGUEUR_BASE[29] = {3,  4,  5,  6,  7,  8,  9,  10, 11,  13,  15,  17,  19, 23, 27,
                               31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258};
const int LONGUEUR_BITS[29] = {0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2,
                               2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0};
const int DISTANCE_BASE[30] = {1,    2,    3,    4,    5,    7,     9,     13,   17,  25,
                               33,   49,   65,   97,   129,  193,   257,   385,  513, 769,
                               1025, 1537, 2049, 3073, 4097, 6145,  8193,  12289, 16385, 24577};
const int DISTANCE_BITS[30] = {0, 0, 0, 0, 1, 1, 2, 2,  3,  3,  4,  4,  5,  5,  6,
                               6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13};

void decoderBloc(LecteurBits& bits, const Huffman& litteraux, const Huffman& distances,
                 std::string& sortie) {
    for (;;) {
        int symbole = litteraux.decoder(bits);
        if (symbole < 256) {
            sortie.push_back((char)(unsigned char)symbole);
            continue;
        }
        if (symbole == 256) return;
        symbole -= 257;
        if (symbole >= 29)
            erreur("MATLAB:load:codeInvalide", "Invalid length code in compressed stream.");
        int longueur = LONGUEUR_BASE[symbole] + (int)bits.lire(LONGUEUR_BITS[symbole]);
        int code = distances.decoder(bits);
        if (code >= 30)
            erreur("MATLAB:load:codeInvalide", "Invalid distance code in compressed stream.");
        std::size_t distance =
            (std::size_t)(DISTANCE_BASE[code] + (int)bits.lire(DISTANCE_BITS[code]));
        if (distance > sortie.size())
            erreur("MATLAB:load:codeInvalide", "Distance points before the start of the data.");
        // La recopie peut chevaucher la source : elle se fait octet par
        // octet, c'est ce que la norme décrit.
        std::size_t depart = sortie.size() - distance;
        for (int k = 0; k < longueur; ++k) sortie.push_back(sortie[depart + (std::size_t)k]);
    }
}

}  // namespace

std::string inflater(const unsigned char* donnees, std::size_t taille,
                     std::size_t tailleAttendue) {
    std::string sortie;
    if (tailleAttendue) sortie.reserve(tailleAttendue);
    LecteurBits bits(donnees, taille);
    for (;;) {
        int dernier = (int)bits.lire(1);
        int type = (int)bits.lire(2);
        if (type == 0) {
            bits.alignerOctet();
            const unsigned char* entete = bits.octets(4);
            std::size_t n = (std::size_t)entete[0] | ((std::size_t)entete[1] << 8);
            std::size_t complement = (std::size_t)entete[2] | ((std::size_t)entete[3] << 8);
            if ((n ^ 0xFFFFu) != complement)
                erreur("MATLAB:load:blocInvalide", "Stored block length is inconsistent.");
            const unsigned char* p = bits.octets(n);
            sortie.append((const char*)p, n);
        } else if (type == 1) {
            Huffman litteraux, distances;
            arbresFixes(litteraux, distances);
            decoderBloc(bits, litteraux, distances, sortie);
        } else if (type == 2) {
            int nLitteraux = (int)bits.lire(5) + 257;
            int nDistances = (int)bits.lire(5) + 1;
            int nCodes = (int)bits.lire(4) + 4;
            // L'ordre dans lequel les longueurs de l'arbre des longueurs
            // sont transmises : il n'a rien d'évident, la norme le donne.
            static const int ORDRE[19] = {16, 17, 18, 0, 8,  7, 9,  6, 10, 5,
                                          11, 4,  12, 3, 13, 2, 14, 1, 15};
            unsigned char longueursCodes[19] = {0};
            for (int k = 0; k < nCodes; ++k)
                longueursCodes[ORDRE[k]] = (unsigned char)bits.lire(3);
            Huffman arbreCodes;
            arbreCodes.construire(longueursCodes, 19);
            std::vector<unsigned char> longueurs((std::size_t)(nLitteraux + nDistances), 0);
            int pose = 0;
            while (pose < nLitteraux + nDistances) {
                int symbole = arbreCodes.decoder(bits);
                if (symbole < 16) {
                    longueurs[(std::size_t)pose++] = (unsigned char)symbole;
                } else if (symbole == 16) {
                    if (pose == 0)
                        erreur("MATLAB:load:codeInvalide", "Repeat code with nothing to repeat.");
                    unsigned char precedent = longueurs[(std::size_t)pose - 1];
                    int combien = 3 + (int)bits.lire(2);
                    while (combien-- && pose < nLitteraux + nDistances)
                        longueurs[(std::size_t)pose++] = precedent;
                } else if (symbole == 17) {
                    int combien = 3 + (int)bits.lire(3);
                    while (combien-- && pose < nLitteraux + nDistances)
                        longueurs[(std::size_t)pose++] = 0;
                } else {
                    int combien = 11 + (int)bits.lire(7);
                    while (combien-- && pose < nLitteraux + nDistances)
                        longueurs[(std::size_t)pose++] = 0;
                }
            }
            Huffman litteraux, distances;
            litteraux.construire(longueurs.data(), (std::size_t)nLitteraux);
            distances.construire(longueurs.data() + nLitteraux, (std::size_t)nDistances);
            decoderBloc(bits, litteraux, distances, sortie);
        } else {
            erreur("MATLAB:load:blocInvalide", "Reserved block type in compressed stream.");
        }
        if (dernier) break;
    }
    return sortie;
}

std::uint32_t adler32(const unsigned char* donnees, std::size_t taille) {
    std::uint32_t a = 1, b = 0;
    for (std::size_t k = 0; k < taille; ++k) {
        a = (a + donnees[k]) % 65521u;
        b = (b + a) % 65521u;
    }
    return (b << 16) | a;
}

std::string inflaterZlib(const unsigned char* donnees, std::size_t taille,
                         std::size_t tailleAttendue) {
    if (taille < 6)
        erreur("MATLAB:load:fluxTronque", "Compressed stream is too short to be zlib.");
    unsigned cmf = donnees[0], flg = donnees[1];
    if ((cmf & 0x0F) != 8)
        erreur("MATLAB:load:fluxInvalide", "Compressed stream is not DEFLATE.");
    if (((cmf << 8) | flg) % 31u != 0)
        erreur("MATLAB:load:fluxInvalide", "zlib header check failed.");
    if (flg & 0x20)
        erreur("MATLAB:load:fluxInvalide", "Preset dictionaries are not supported.");
    std::string sortie = inflater(donnees + 2, taille - 2, tailleAttendue);
    // L'Adler-32 est les quatre derniers octets, en gros-boutien.
    const unsigned char* fin = donnees + taille - 4;
    std::uint32_t attendu = ((std::uint32_t)fin[0] << 24) | ((std::uint32_t)fin[1] << 16) |
                            ((std::uint32_t)fin[2] << 8) | (std::uint32_t)fin[3];
    std::uint32_t obtenu = adler32((const unsigned char*)sortie.data(), sortie.size());
    if (attendu != obtenu)
        erreur("MATLAB:load:sommeInvalide", "Checksum of the compressed stream does not match.");
    return sortie;
}

std::string emballerZlib(const std::string& donnees) {
    std::string sortie;
    sortie.reserve(donnees.size() + donnees.size() / 65535 * 5 + 16);
    sortie.push_back((char)0x78);   // CM = 8, CINFO = 7 (fenêtre de 32 Ko)
    sortie.push_back((char)0x01);   // niveau le plus bas, contrôle valide
    std::size_t position = 0;
    do {
        std::size_t n = donnees.size() - position;
        if (n > 65535) n = 65535;
        bool dernier = position + n >= donnees.size();
        sortie.push_back((char)(dernier ? 1 : 0));
        sortie.push_back((char)(n & 0xFF));
        sortie.push_back((char)((n >> 8) & 0xFF));
        sortie.push_back((char)(~n & 0xFF));
        sortie.push_back((char)((~n >> 8) & 0xFF));
        sortie.append(donnees, position, n);
        position += n;
    } while (position < donnees.size());
    std::uint32_t somme = adler32((const unsigned char*)donnees.data(), donnees.size());
    sortie.push_back((char)((somme >> 24) & 0xFF));
    sortie.push_back((char)((somme >> 16) & 0xFF));
    sortie.push_back((char)((somme >> 8) & 0xFF));
    sortie.push_back((char)(somme & 0xFF));
    return sortie;
}

}  // namespace matlibre
