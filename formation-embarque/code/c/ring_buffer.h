/* ring_buffer.h — tampon circulaire (corrigé TD 01, exercice 2)
 *
 * Un producteur / un consommateur, sans verrou : put() n'écrit que `tete`,
 * get() n'écrit que `queue`. Les index sont volatile car dans l'usage réel
 * put() est appelé depuis une ISR.
 */
#ifndef RING_BUFFER_H
#define RING_BUFFER_H

#include <stdint.h>
#include <stdbool.h>

#define RB_TAILLE 32u   /* puissance de 2 obligatoire (modulo par masque) */

typedef struct {
    uint8_t donnees[RB_TAILLE];
    volatile uint8_t tete;    /* index d'écriture (producteur) */
    volatile uint8_t queue;   /* index de lecture  (consommateur) */
} RingBuffer;

void rb_init(RingBuffer *rb);
bool rb_est_vide(const RingBuffer *rb);
bool rb_est_plein(const RingBuffer *rb);
bool rb_put(RingBuffer *rb, uint8_t octet);
bool rb_get(RingBuffer *rb, uint8_t *octet);

#endif /* RING_BUFFER_H */
