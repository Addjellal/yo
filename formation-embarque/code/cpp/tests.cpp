// tests.cpp — tests des corrigés du TD 02.  `make test` doit afficher 4 OK.
#include <cassert>
#include <cstdio>
#include <cstring>
#include <cstdint>

#include "tampon_circulaire.hpp"
#include "afficheur.hpp"
#include "chip_select.hpp"
#include "feu_tricolore.hpp"

static void test_tampon() {
    TamponCirculaire<std::uint8_t, 8> tc;    // 8 cases -> 7 utilisables
    assert(tc.vide() && !tc.plein() && tc.taille() == 0);

    for (std::uint8_t i = 0; i < 7; i++) assert(tc.put(i));
    assert(tc.plein() && tc.taille() == 7);
    assert(!tc.put(99));                     // refus quand plein

    std::uint8_t v;
    for (std::uint8_t i = 0; i < 7; i++) { assert(tc.get(v)); assert(v == i); }
    assert(tc.vide() && !tc.get(v));

    TamponCirculaire<float, 4> tf;           // le même code, autre type
    assert(tf.put(3.14f));
    float f; assert(tf.get(f) && f > 3.13f && f < 3.15f);
    std::puts("OK  tampon_circulaire");
}

static void test_afficheur() {
    AfficheurLcd16x2 lcd;
    afficher_mesure(lcd, 21.5f);             // le code applicatif, tel quel

    char l0[17], l1[17];
    lcd.ligne(0, l0);
    lcd.ligne(1, l1);
    assert(std::strncmp(l0, "Station meteo", 13) == 0);
    assert(std::strncmp(l1, "T=21.5 C", 8) == 0);

    lcd.texte(14, 1, "XYZ");                 // dépasse : doit être tronqué
    lcd.ligne(1, l1);
    assert(l1[14] == 'X' && l1[15] == 'Y');  // 'Z' hors écran, pas de débordement
    std::puts("OK  afficheur");
}

// Broche factice qui ENREGISTRE les transitions : le "mock" du RAII
struct BrocheEspion {
    int nb_bas = 0, nb_haut = 0;
    bool basse = false;
    void bas()  { nb_bas++;  basse = true; }
    void haut() { nb_haut++; basse = false; }
};

static bool transfert_simule(BrocheEspion& cs_pin, bool declencher_erreur) {
    ChipSelect<BrocheEspion> cs(cs_pin);     // CS descend ici
    if (declencher_erreur)
        return false;                        // sortie anticipée...
    return true;
}                                            // ...CS remonte dans les 2 cas

static void test_chip_select() {
    BrocheEspion pin;
    assert(transfert_simule(pin, false));
    assert(pin.nb_bas == 1 && pin.nb_haut == 1 && !pin.basse);

    assert(!transfert_simule(pin, true));    // même sur le chemin d'erreur :
    assert(pin.nb_bas == 2 && pin.nb_haut == 2 && !pin.basse);
    std::puts("OK  chip_select (RAII verifie sur sortie anticipee)");
}

static void test_feu() {
    FeuTricolore feu(0);
    using E = FeuTricolore::Etat;
    assert(feu.etat() == E::Rouge);
    feu.tick(5000);  assert(feu.etat() == E::Vert);
    feu.tick(10000); assert(feu.etat() == E::Orange);
    feu.tick(11000); assert(feu.etat() == E::Rouge);

    // deux instances indépendantes (impossible avec des globales C)
    FeuTricolore autre(0);
    assert(autre.etat() == E::Rouge && feu.etat() == E::Rouge);
    feu.tick(16000); assert(feu.etat() == E::Vert);
    assert(autre.etat() == E::Rouge);        // l'autre n'a pas bougé

    feu.appuiPieton();
    feu.tick(16500); assert(feu.etat() == E::Vert);    // < vert minimal
    feu.tick(17100); assert(feu.etat() == E::Orange);  // servi
    std::puts("OK  feu_tricolore");
}

int main() {
    test_tampon();
    test_afficheur();
    test_chip_select();
    test_feu();
    std::puts("---- tous les tests C++ passent ----");
    return 0;
}
