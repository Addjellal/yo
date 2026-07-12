/* fsm_feu.h — feu tricolore avec appel piéton (corrigé TD 01, exercice 3)
 *
 * FSM pilotée par horodatage : appeler feu_tick() très souvent avec le
 * temps courant en ms (millis() sur Arduino, HAL_GetTick() sur STM32,
 * temps simulé dans les tests).
 */
#ifndef FSM_FEU_H
#define FSM_FEU_H

#include <stdint.h>
#include <stdbool.h>

typedef enum { FEU_VERT, FEU_ORANGE, FEU_ROUGE } EtatFeu;

typedef struct {
    EtatFeu  etat;
    uint32_t t_entree_etat;
    bool     demande_pieton;
} Feu;

#define FEU_DUREE_VERT_MS        5000u
#define FEU_DUREE_ORANGE_MS      1000u
#define FEU_DUREE_ROUGE_MS       5000u
#define FEU_VERT_MINI_PIETON_MS  1000u

void feu_init(Feu *f, uint32_t maintenant);
void feu_appui_pieton(Feu *f);
void feu_tick(Feu *f, uint32_t maintenant);

#endif /* FSM_FEU_H */
