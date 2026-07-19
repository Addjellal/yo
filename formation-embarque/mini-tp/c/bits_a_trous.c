/* Mini-TP C n°1 — opérations de bits (cours 01 §3.2)
 * Plateforme : https://www.onlinegdb.com (langage C) — coller puis Run.
 * Complète les 4 zones "A COMPLETER". Le programme s'auto-vérifie.
 */
#include <stdio.h>
#include <stdint.h>

int main(void) {
    int erreurs = 0;
    uint8_t r = 0x00;

    /* --- 1) Mettre le bit 3 a 1 (SET) ------------------------------ */
    /* A COMPLETER (1) : une seule ligne, avec |= et un decalage       */

    printf("1) apres SET bit 3    : 0x%02X\n", r);
    if (r != 0x08) { printf("   ATTENDU 0x08\n"); erreurs++; }

    /* --- 2) Remettre le bit 3 a 0 (CLEAR) -------------------------- */
    /* A COMPLETER (2) : une seule ligne, avec &= et ~                 */

    printf("2) apres CLEAR bit 3  : 0x%02X\n", r);
    if (r != 0x00) { printf("   ATTENDU 0x00\n"); erreurs++; }

    /* --- 3) Inverser le bit 6 deux fois (TOGGLE) ------------------- */
    /* A COMPLETER (3) : deux lignes identiques, avec ^=               */
    uint8_t apres_1er = 0;

    /* ligne toggle n°1 ici, puis :  apres_1er = r;  puis toggle n°2   */

    printf("3) apres TOGGLE x2    : 0x%02X puis 0x%02X\n", apres_1er, r);
    if (apres_1er != 0x40 || r != 0x00) { printf("   ATTENDU 0x40 puis 0x00\n"); erreurs++; }

    /* --- 4) Extraire un champ de bits ------------------------------ */
    /* Le registre STATUS contient MODE sur les bits 3..2.
     * STATUS = 0b1000 1101 -> MODE = bits 3..2 = 0b11 = 3            */
    uint8_t STATUS = 0x8D;
    uint8_t mode = 0;
    /* A COMPLETER (4) : decalage a droite PUIS masque 0x3             */

    printf("4) champ MODE         : %u\n", mode);
    if (mode != 3) { printf("   ATTENDU 3\n"); erreurs++; }

    if (erreurs == 0) printf("TOUS LES TESTS PASSENT\n");
    else              printf("%d test(s) en echec — relire cours 01 §3.2\n", erreurs);
    return 0;
}
