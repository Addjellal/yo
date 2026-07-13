/* trame.h — décodeur de trame {0xA5, id, hi, lo} (corrigé TD 01, ex. 4) */
#ifndef TRAME_H
#define TRAME_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#define TRAME_TETE     0xA5u
#define TRAME_LONGUEUR 4u

typedef struct {
    uint8_t  id;
    uint16_t valeur;
} Mesure;

/* true si la trame est valide (pointeurs, longueur, tete) et remplit *sortie */
bool trame_decoder(const uint8_t *trame, size_t longueur, Mesure *sortie);

#endif /* TRAME_H */
