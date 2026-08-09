// Catalogue — Cartes programmables.
//
// Un composant = un bloc. Décrire le symbole, l'empreinte, les propriétés
// réglables et la traduction SPICE suffit : ni l'interface graphique ni les
// moteurs n'ont à être modifiés.
#include "core/catalogue/Traits.h"
#include "core/Netlist.h"
#include "core/engines/ProgrammesExemples.h"

namespace coeur {

void enregistrer_cartes(Catalogue& catalogue) {
    using namespace traits;
    auto enregistrer = [&catalogue](Modele m) {
        catalogue.enregistrer(std::move(m));
    };

    {   // ------------------------------------------------------- carte Arduino
        Modele m;
        m.type = "arduino_uno";
        m.libelle = "Carte Arduino Uno";
        m.categorie = "Cartes";
        m.prefixe = "U";
        m.carte = true;
        m.couleur_corps = "#1a7f8c";

        // Brochage réel de la carte : numérique à droite, analogique et
        // alimentation à gauche. Le nom de la borne EST le nom du nœud.
        const double pas = 20;
        const double demi = 170;          // demi-hauteur du contour
        const double premier = -130;      // ordonnée de D13, la plus haute
        for (int d = 0; d <= 13; ++d) {
            const double y = premier + (13 - d) * pas;
            m.bornes.push_back({"D" + std::to_string(d), {90, y}, ""});
            m.symbole.push_back(ligne(70, y, 90, y));
            m.symbole.push_back(texte(30, y + 4, "D" + std::to_string(d), 11));
        }
        const char* gauche[] = {"5V", "3V3", "GND", "VIN"};
        for (int k = 0; k < 4; ++k) {
            const double y = premier + k * pas;
            m.bornes.push_back({gauche[k], {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-62, y + 4, gauche[k], 11));
        }
        for (int a = 0; a <= 5; ++a) {
            const double y = premier + (4 + a) * pas + 10;
            m.bornes.push_back({"A" + std::to_string(a), {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-62, y + 4, "A" + std::to_string(a), 11));
        }
        m.symbole.insert(m.symbole.begin(), rect(-70, -demi, 70, demi));
        m.symbole.push_back(texte(-40, premier - 18, "ARDUINO UNO", 12));
        m.empreinte = {"ARDUINO_UNO", {}, 68.6, 53.4};
        m.mcu = "atmega328p";
        m.horloge = 16000000;
        // Une carte Arduino se programme en croquis : c'est ce que voit
        // n'importe qui ouvrant l'IDE officiel, et c'est ce que doit trouver
        // celui qui double-clique dessus ici.
        // Le croquis vient du recueil commun : un seul endroit à corriger,
        // et le test qui compile tous les exemples le couvre déjà.
        m.programme_exemple = kSourceExemple;
        enregistrer(std::move(m));
    }
}

}  // namespace coeur
