// Mini-TP C++ — RAII (cours 02 §3). Plateforme : onlinegdb.com, C++17.
// Complete la classe SelectionSPI (3 trous). Le banc de test s'auto-verifie.
#include <cstdio>

// Fausse broche : enregistre les transitions (ne pas modifier)
struct Broche {
    int nb_bas = 0, nb_haut = 0;
    void bas()  { nb_bas++;  std::puts("CS: BAS"); }
    void haut() { nb_haut++; std::puts("CS: HAUT"); }
};

class SelectionSPI {
public:
    explicit SelectionSPI(Broche& b) : broche_(b) {
        // A COMPLETER (1) : selectionner le peripherique (CS actif bas)

    }

    ~SelectionSPI() {
        // A COMPLETER (2) : relacher le peripherique — c'est LA garantie RAII

    }

    // A COMPLETER (3) : interdire la copie (deux lignes avec  = delete)


private:
    Broche& broche_;
};

// ---- Banc de test (ne pas modifier) ----------------------------------
static Broche cs_pin;

bool transfert(bool declencher_erreur) {
    SelectionSPI cs(cs_pin);          // CS doit descendre ICI
    if (declencher_erreur)
        return false;                 // sortie anticipee : CS doit REMONTER quand meme
    return true;
}                                     // sortie normale : CS remonte ici

int main() {
    std::puts("-- transfert normal --");
    transfert(false);
    std::puts("-- transfert avec erreur (return anticipe) --");
    transfert(true);

    // SelectionSPI copie = ???;  // bonus : la copie doit etre REFUSEE a la compilation

    if (cs_pin.nb_bas == 2 && cs_pin.nb_haut == 2)
        std::puts("VERIF : 2 descentes, 2 remontees -> RAII OK");
    else
        std::printf("VERIF ECHOUEE : %d descentes, %d remontees (attendu 2/2)\n",
                    cs_pin.nb_bas, cs_pin.nb_haut);
    return 0;
}
