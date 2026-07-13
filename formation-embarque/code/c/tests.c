/* tests.c — tests des corrigés du TD 01.  `make test` doit afficher 4 OK. */
#include <assert.h>
#include <stdio.h>

#include "bits.h"
#include "ring_buffer.h"
#include "fsm_feu.h"
#include "trame.h"

static void test_bits(void) {
    assert(inverse_bits(0xB0) == 0x0D);
    assert(inverse_bits(0x00) == 0x00);
    assert(inverse_bits(0xFF) == 0xFF);
    assert(inverse_bits(0x01) == 0x80);
    /* involutif, et les deux versions coincident sur les 256 valeurs */
    for (int i = 0; i < 256; i++) {
        uint8_t v = (uint8_t)i;
        assert(inverse_bits(inverse_bits(v)) == v);
        assert(inverse_bits(v) == inverse_bits_rapide(v));
    }
    puts("OK  bits");
}

static void test_ring_buffer(void) {
    RingBuffer rb;
    uint8_t v;
    rb_init(&rb);
    assert(rb_est_vide(&rb) && !rb_est_plein(&rb));
    assert(!rb_get(&rb, &v));                       /* vide : refus */

    for (uint8_t i = 0; i < RB_TAILLE - 1u; i++)    /* N-1 cases utiles */
        assert(rb_put(&rb, i));
    assert(rb_est_plein(&rb));
    assert(!rb_put(&rb, 99));                       /* plein : refus */

    for (uint8_t i = 0; i < RB_TAILLE - 1u; i++) {
        assert(rb_get(&rb, &v));
        assert(v == i);                             /* ordre FIFO */
    }
    assert(rb_est_vide(&rb));

    /* enroulement : ecrire/lire par-dessus la frontiere du tableau */
    for (int tour = 0; tour < 100; tour++) {
        assert(rb_put(&rb, (uint8_t)tour));
        assert(rb_get(&rb, &v));
        assert(v == (uint8_t)tour);
    }
    puts("OK  ring_buffer");
}

static void test_fsm_feu(void) {
    Feu f;
    feu_init(&f, 0);
    assert(f.etat == FEU_ROUGE);

    feu_tick(&f, 4999); assert(f.etat == FEU_ROUGE);
    feu_tick(&f, 5000); assert(f.etat == FEU_VERT);   /* rouge 5 s */
    feu_tick(&f, 9999); assert(f.etat == FEU_VERT);
    feu_tick(&f, 10000); assert(f.etat == FEU_ORANGE); /* vert 5 s */
    feu_tick(&f, 11000); assert(f.etat == FEU_ROUGE);  /* orange 1 s */

    /* Appel pieton : ecourte le vert, mais pas avant le minimum de 1 s */
    feu_tick(&f, 16000); assert(f.etat == FEU_VERT);
    feu_appui_pieton(&f);
    feu_tick(&f, 16500); assert(f.etat == FEU_VERT);   /* < 1 s de vert */
    feu_tick(&f, 17000); assert(f.etat == FEU_ORANGE); /* >= 1 s : servi */
    feu_tick(&f, 18000); assert(f.etat == FEU_ROUGE);
    assert(!f.demande_pieton);                          /* demande effacee */
    puts("OK  fsm_feu");
}

static void test_trame(void) {
    Mesure m;
    const uint8_t ok[]        = {0xA5, 0x07, 0x01, 0xF4};  /* valeur 500 */
    const uint8_t mauv_tete[] = {0x55, 0x07, 0x01, 0xF4};

    assert(trame_decoder(ok, 4, &m));
    assert(m.id == 7 && m.valeur == 500);

    assert(!trame_decoder(mauv_tete, 4, &m));   /* mauvaise tete */
    assert(!trame_decoder(ok, 3, &m));          /* trop courte */
    assert(!trame_decoder(NULL, 4, &m));        /* pointeur nul */
    assert(!trame_decoder(ok, 4, NULL));
    puts("OK  trame");
}

int main(void) {
    test_bits();
    test_ring_buffer();
    test_fsm_feu();
    test_trame();
    puts("---- tous les tests C passent ----");
    return 0;
}
