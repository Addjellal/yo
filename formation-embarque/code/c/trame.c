#include "trame.h"

bool trame_decoder(const uint8_t *trame, size_t longueur, Mesure *sortie) {
    if (trame == NULL || sortie == NULL)   /* 1. pointeurs valides */
        return false;
    if (longueur != TRAME_LONGUEUR)        /* 2. longueur exacte */
        return false;
    if (trame[0] != TRAME_TETE)            /* 3. octet de synchronisation */
        return false;

    sortie->id = trame[1];
    /* Assemblage big-endian, cast AVANT le decalage (promotions) */
    sortie->valeur = (uint16_t)(((uint16_t)trame[2] << 8) | trame[3]);
    return true;
}
