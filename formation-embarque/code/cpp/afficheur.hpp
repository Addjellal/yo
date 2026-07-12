// afficheur.hpp — corrigé TD 02, exercice 2
// Interface abstraite + deux implémentations : le code applicatif ne
// connaît que IAfficheur, donc il se développe et se teste SANS matériel.
#ifndef AFFICHEUR_HPP
#define AFFICHEUR_HPP

#include <cstdint>
#include <cstdio>
#include <cstring>

class IAfficheur {
public:
    virtual ~IAfficheur() = default;      // destructeur virtuel : obligatoire
    virtual void effacer() = 0;
    virtual void texte(std::uint8_t x, std::uint8_t y, const char* s) = 0;
};

// Implémentation 1 : la console du PC (le "mock" de développement)
class AfficheurConsole : public IAfficheur {
public:
    void effacer() override { std::puts("--- efface ---"); }
    void texte(std::uint8_t x, std::uint8_t y, const char* s) override {
        std::printf("[%2u,%2u] %s\n", x, y, s);
    }
};

// Implémentation 2 : un "LCD" 16x2 simulé en mémoire — inspectable en test
class AfficheurLcd16x2 : public IAfficheur {
public:
    AfficheurLcd16x2() { effacer(); }

    void effacer() override { std::memset(ecran_, ' ', sizeof ecran_); }

    void texte(std::uint8_t x, std::uint8_t y, const char* s) override {
        if (y >= 2) return;                            // toujours borner
        for (std::uint8_t i = 0; s[i] != '\0' && (x + i) < 16; i++)
            ecran_[y][x + i] = s[i];
    }

    // Accès de test : contenu d'une ligne, terminé par '\0'
    void ligne(std::uint8_t y, char (&sortie)[17]) const {
        std::memcpy(sortie, ecran_[y < 2 ? y : 0], 16);
        sortie[16] = '\0';
    }

private:
    char ecran_[2][16];
};

// ---- Code applicatif : ne dépend QUE de l'interface ----
inline void afficher_mesure(IAfficheur& aff, float temperature) {
    char l[17];
    std::snprintf(l, sizeof l, "T=%.1f C", static_cast<double>(temperature));
    aff.effacer();
    aff.texte(0, 0, "Station meteo");
    aff.texte(0, 1, l);
}

#endif // AFFICHEUR_HPP
