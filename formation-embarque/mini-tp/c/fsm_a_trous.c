/* Mini-TP C n°2 — machine d'etats d'une porte automatique (cours 01 §12)
 * Plateforme : https://www.onlinegdb.com — coller puis Run.
 * Le temps est SIMULE : la boucle du main fait avancer "maintenant".
 * Complete les 3 transitions marquees A COMPLETER.
 */
#include <stdio.h>
#include <stdint.h>
#include <string.h>

typedef enum { FERMEE, OUVERTURE, OUVERTE, FERMETURE } Etat;
static const char *NOMS[] = {"FERMEE", "OUVERTURE", "OUVERTE", "FERMETURE"};

/* Capteurs simules par le banc de test (ne pas modifier) */
static int bouton = 0, fdc_haut = 0, fdc_bas = 0;

static Etat etat = FERMEE;
static uint32_t t_entree = 0;          /* horodatage d'entree dans l'etat */

void fsm_tick(uint32_t maintenant) {
    switch (etat) {
    case FERMEE:
        /* A COMPLETER (1) : si bouton appuye -> OUVERTURE
         * (ne pas oublier de memoriser t_entree = maintenant)          */

        break;

    case OUVERTURE:
        if (fdc_haut) { etat = OUVERTE; t_entree = maintenant; }
        break;

    case OUVERTE:
        /* A COMPLETER (2) : apres 5000 ms dans l'etat -> FERMETURE
         * indice : maintenant - t_entree >= 5000                       */

        break;

    case FERMETURE:
        /* A COMPLETER (3) : si fin de course bas -> FERMEE             */

        break;
    }
}

/* ---- Banc de test (ne pas modifier) --------------------------------- */
int main(void) {
    Etat prec = (Etat)-1;
    for (uint32_t t = 0; t <= 9200; t += 100) {
        bouton   = (t == 100);
        fdc_haut = (t >= 2100 && t < 7100);
        fdc_bas  = (t >= 9100);
        fsm_tick(t);
        if (etat != prec) { printf("t=%5u ms  etat=%s\n", t, NOMS[etat]); prec = etat; }
    }
    if (etat == FERMEE && prec == FERMEE) printf("SEQUENCE CORRECTE\n");
    else printf("SEQUENCE INCORRECTE — etat final : %s\n", NOMS[etat]);
    return 0;
}
