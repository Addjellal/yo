#include "fsm_feu.h"

void feu_init(Feu *f, uint32_t maintenant) {
    f->etat = FEU_ROUGE;
    f->t_entree_etat = maintenant;
    f->demande_pieton = false;
}

/* L'événement ne change PAS l'état : il pose un drapeau que la FSM
 * consommera au bon moment (séparation événements / transitions). */
void feu_appui_pieton(Feu *f) {
    f->demande_pieton = true;
}

void feu_tick(Feu *f, uint32_t maintenant) {
    /* Soustraction non signée : robuste au débordement du compteur ms */
    uint32_t ecoule = maintenant - f->t_entree_etat;

    switch (f->etat) {
    case FEU_VERT:
        /* Fin normale, OU piéton après le minimum de sécurité */
        if (ecoule >= FEU_DUREE_VERT_MS ||
            (f->demande_pieton && ecoule >= FEU_VERT_MINI_PIETON_MS)) {
            f->etat = FEU_ORANGE;
            f->t_entree_etat = maintenant;
        }
        break;

    case FEU_ORANGE:
        if (ecoule >= FEU_DUREE_ORANGE_MS) {
            f->etat = FEU_ROUGE;
            f->t_entree_etat = maintenant;
            f->demande_pieton = false;   /* demande servie */
        }
        break;

    case FEU_ROUGE:
        if (ecoule >= FEU_DUREE_ROUGE_MS) {
            f->etat = FEU_VERT;
            f->t_entree_etat = maintenant;
        }
        break;
    }
}
