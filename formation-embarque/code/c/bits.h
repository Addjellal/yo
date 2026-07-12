/* bits.h — manipulations de bits (corrigé TD 01, exercice 1) */
#ifndef BITS_H
#define BITS_H

#include <stdint.h>

/* Renverse l'ordre des bits : 0b10110000 -> 0b00001101 */
uint8_t inverse_bits(uint8_t x);

/* Variante sans boucle, par échanges de blocs */
uint8_t inverse_bits_rapide(uint8_t x);

#endif /* BITS_H */
