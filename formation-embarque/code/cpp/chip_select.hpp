// chip_select.hpp — corrigé TD 02, exercice 3 (RAII)
// La broche CS est abaissée dans le constructeur et relâchée dans le
// destructeur : la désélection est garantie sur TOUS les chemins de sortie.
//
// Le type de broche est un paramètre de template : sur cible réelle on
// passe une classe qui pilote le GPIO ; en test, une classe qui enregistre
// les appels. Polymorphisme statique : zéro coût.
#ifndef CHIP_SELECT_HPP
#define CHIP_SELECT_HPP

template <typename Broche>
class ChipSelect {
public:
    explicit ChipSelect(Broche& broche) : broche_(broche) {
        broche_.bas();            // CS actif à l'état bas : sélection
    }
    ~ChipSelect() {
        broche_.haut();           // désélection GARANTIE
    }

    // Un objet RAII ne se copie pas : deux copies relâcheraient CS deux fois.
    ChipSelect(const ChipSelect&) = delete;
    ChipSelect& operator=(const ChipSelect&) = delete;

private:
    Broche& broche_;
};

#endif // CHIP_SELECT_HPP
