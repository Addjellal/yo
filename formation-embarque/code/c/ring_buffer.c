#include "ring_buffer.h"

/* Vérification à la compilation que RB_TAILLE est une puissance de 2 */
_Static_assert((RB_TAILLE & (RB_TAILLE - 1u)) == 0u,
               "RB_TAILLE doit etre une puissance de 2");

void rb_init(RingBuffer *rb) {
    rb->tete = 0;
    rb->queue = 0;
}

bool rb_est_vide(const RingBuffer *rb) {
    return rb->tete == rb->queue;
}

/* Convention "une case sacrifiée" : plein quand tete+1 rattrape queue.
 * Évite un compteur d'occupation partagé entre ISR et main. */
bool rb_est_plein(const RingBuffer *rb) {
    return ((rb->tete + 1u) & (RB_TAILLE - 1u)) == rb->queue;
}

bool rb_put(RingBuffer *rb, uint8_t octet) {
    if (rb_est_plein(rb))
        return false;                 /* politique : refuser, pas écraser */
    rb->donnees[rb->tete] = octet;
    rb->tete = (rb->tete + 1u) & (RB_TAILLE - 1u);
    return true;
}

bool rb_get(RingBuffer *rb, uint8_t *octet) {
    if (rb_est_vide(rb))
        return false;
    *octet = rb->donnees[rb->queue];
    rb->queue = (rb->queue + 1u) & (RB_TAILLE - 1u);
    return true;
}
