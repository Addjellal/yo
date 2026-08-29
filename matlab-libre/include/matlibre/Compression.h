// Compression.h — DEFLATE, juste ce qu'il en faut pour les fichiers MAT.
//
// Un fichier MAT de niveau 5 écrit par MATLAB depuis la version 7 range
// chaque variable dans un flux zlib. Le lire demande donc de savoir
// décompresser. On implémente RFC 1951 (DEFLATE) et RFC 1950 (l'enveloppe
// zlib) plutôt que de dépendre d'une bibliothèque : le décodeur tient en
// deux cents lignes, il n'a rien à installer, et il rend MatLibre capable
// de relire les fichiers de MATLAB partout.
//
// À l'écriture, on n'a pas besoin de compresser : le format autorise les
// blocs « stockés », et un fichier non compressé est exactement ce que
// MATLAB écrit avec « -v6 ». C'est ce que « save » produit.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>

namespace matlibre {

// Décompresse un flux DEFLATE brut (RFC 1951). Lève une ErreurMatlab si
// le flux est mal formé. « tailleAttendue » n'est qu'une indication pour
// réserver la mémoire ; zéro quand on ne sait pas.
std::string inflater(const unsigned char* donnees, std::size_t taille,
                     std::size_t tailleAttendue = 0);

// Décompresse un flux zlib (RFC 1950) : deux octets d'en-tête, le flux
// DEFLATE, puis l'Adler-32 — vérifié.
std::string inflaterZlib(const unsigned char* donnees, std::size_t taille,
                         std::size_t tailleAttendue = 0);

// Enveloppe des données dans un flux zlib valide, en blocs « stockés » :
// rien n'est compressé, mais le résultat se relit avec n'importe quel
// décodeur zlib, MATLAB compris.
std::string emballerZlib(const std::string& donnees);

std::uint32_t adler32(const unsigned char* donnees, std::size_t taille);

}  // namespace matlibre
