#include "bits.h"

uint8_t inverse_bits(uint8_t x) {
    uint8_t resultat = 0;
    for (uint8_t i = 0; i < 8; i++) {
        resultat = (uint8_t)(resultat << 1);  /* faire de la place a droite */
        resultat |= (uint8_t)(x & 1u);        /* copier le LSB de x */
        x >>= 1;                              /* bit suivant */
    }
    return resultat;
}

uint8_t inverse_bits_rapide(uint8_t x) {
    x = (uint8_t)(((x & 0xF0u) >> 4) | ((x & 0x0Fu) << 4)); /* quartets */
    x = (uint8_t)(((x & 0xCCu) >> 2) | ((x & 0x33u) << 2)); /* paires   */
    x = (uint8_t)(((x & 0xAAu) >> 1) | ((x & 0x55u) << 1)); /* bits     */
    return x;
}
