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

    {   // -------------------------------------------------------- Arduino Nano
        // Même puce que l'Uno, même horloge, même programme : ce qui change
        // est le format et deux entrées analogiques de plus. Le cœur qui
        // exécute le firmware ne voit aucune différence — et c'est vrai du
        // vrai matériel, pas seulement d'ici.
        Modele m;
        m.type = "arduino_nano";
        m.libelle = "Carte Arduino Nano";
        m.categorie = "Cartes";
        m.prefixe = "U";
        m.carte = true;
        m.couleur_corps = "#1a7f8c";

        const double pas = 20;
        const double premier = -130;
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
        // A0 à A7 : les deux dernières ne servent qu'au convertisseur.
        for (int a = 0; a <= 7; ++a) {
            const double y = premier + (4 + a) * pas + 10;
            m.bornes.push_back({"A" + std::to_string(a), {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-62, y + 4, "A" + std::to_string(a), 11));
        }
        const double demi_nano = 170;
        m.symbole.insert(m.symbole.begin(), rect(-70, -demi_nano, 70, demi_nano));
        m.symbole.push_back(texte(-42, premier - 18, "ARDUINO NANO", 12));
        m.empreinte = {"ARDUINO_NANO", {}, 43.2, 18.0};
        m.mcu = "atmega328p";
        m.horloge = 16000000;
        m.programme_exemple = kSourceExemple;
        enregistrer(std::move(m));
    }

    {   // ---------------------------------------------------- Arduino Pro Mini
        Modele m;
        m.type = "arduino_pro_mini";
        m.libelle = "Carte Arduino Pro Mini";
        m.categorie = "Cartes";
        m.prefixe = "U";
        m.carte = true;
        m.couleur_corps = "#20707f";

        const double pas = 20;
        const double premier = -130;
        for (int d = 0; d <= 13; ++d) {
            const double y = premier + (13 - d) * pas;
            m.bornes.push_back({"D" + std::to_string(d), {90, y}, ""});
            m.symbole.push_back(ligne(70, y, 90, y));
            m.symbole.push_back(texte(30, y + 4, "D" + std::to_string(d), 11));
        }
        // Pas de prise USB, donc pas de régulateur 5 V d'origine : la carte
        // reçoit sa tension par RAW, et VCC est déjà régulée.
        const char* gauche[] = {"VCC", "GND", "RAW"};
        for (int k = 0; k < 3; ++k) {
            const double y = premier + k * pas;
            m.bornes.push_back({gauche[k], {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-62, y + 4, gauche[k], 11));
        }
        for (int a = 0; a <= 7; ++a) {
            const double y = premier + (3 + a) * pas + 10;
            m.bornes.push_back({"A" + std::to_string(a), {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-62, y + 4, "A" + std::to_string(a), 11));
        }
        const double demi_mini = 170;
        m.symbole.insert(m.symbole.begin(), rect(-70, -demi_mini, 70, demi_mini));
        m.symbole.push_back(texte(-48, premier - 18, "ARDUINO PRO MINI", 11));
        m.empreinte = {"ARDUINO_PRO_MINI", {}, 33.0, 18.0};
        m.mcu = "atmega328p";
        m.horloge = 16000000;
        m.programme_exemple = kSourceExemple;
        enregistrer(std::move(m));
    }

    {   // -------------------------------------------- ATmega328P nu (DIP-28)
        // La puce seule, sans carte autour : c'est ce qu'on soude sur son
        // propre circuit imprimé quand le prototype est fini. Les broches
        // portent alors le nom du fabricant, PB5 et non D13, et le programme
        // s'écrit sur les registres — parce que c'est ainsi qu'on programme
        // une puce nue, et non par déférence pour la tradition.
        Modele m;
        m.type = "atmega328p";
        m.libelle = "ATmega328P nu (DIP-28)";
        m.categorie = "Cartes";
        m.prefixe = "U";
        m.carte = true;
        m.couleur_corps = "#3a3a3a";

        const double pas = 20;
        // Chaque colonne est centrée sur elle-même : dix broches à gauche,
        // douze à droite. Les compter depuis un même premier point mettrait
        // le boîtier de travers et ferait déborder le dessin de son cadre.
        const char* a_gauche[] = {"PD0", "PD1", "PD2", "PD3", "PD4",
                                  "PD5", "PD6", "PD7", "VCC", "GND"};
        const double premier_gauche = -(10 - 1) * pas / 2;
        for (int k = 0; k < 10; ++k) {
            const double y = premier_gauche + k * pas;
            m.bornes.push_back({a_gauche[k], {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-62, y + 4, a_gauche[k], 11));
        }
        // Colonne de droite : PB0..PB5 puis PC0..PC5.
        const char* a_droite[] = {"PB0", "PB1", "PB2", "PB3", "PB4", "PB5",
                                  "PC0", "PC1", "PC2", "PC3", "PC4", "PC5"};
        const double premier_droite = -(12 - 1) * pas / 2;
        for (int k = 0; k < 12; ++k) {
            const double y = premier_droite + k * pas;
            m.bornes.push_back({a_droite[k], {90, y}, ""});
            m.symbole.push_back(ligne(70, y, 90, y));
            m.symbole.push_back(texte(34, y + 4, a_droite[k], 11));
        }
        const double demi_puce = 150;
        m.symbole.insert(m.symbole.begin(), rect(-70, -demi_puce, 70, demi_puce));
        m.symbole.push_back(texte(-40, premier_droite - 18, "ATmega328P", 12));
        m.empreinte = {"DIP-28", {}, 35.6, 7.62};
        m.mcu = "atmega328p";
        m.horloge = 16000000;
        m.langage = "C (registres)";
        m.programme_exemple = kProgrammeRegistresNu;
        enregistrer(std::move(m));
    }

    {   // ------------------------------------------------------- ATtiny85
        // Huit broches, dont deux d'alimentation : six entrées-sorties, un
        // seul port. C'est la puce des montages minuscules — celle que
        // Tinkercad propose à côté de l'Arduino —, et son cœur est le même
        // AVR, en plus petit.
        Modele m;
        m.type = "attiny85";
        m.libelle = "ATtiny85 (DIP-8)";
        m.categorie = "Cartes";
        m.prefixe = "U";
        m.carte = true;
        m.couleur_corps = "#3a3a3a";

        const double pas = 24;
        // Brochage du boîtier : PB5 (reset) en haut à gauche, VCC en haut à
        // droite, comme sur la puce réelle.
        const char* a_gauche[] = {"PB5", "PB3", "PB4", "GND"};
        const char* a_droite[] = {"VCC", "PB2", "PB1", "PB0"};
        const double premier = -(4 - 1) * pas / 2;
        for (int k = 0; k < 4; ++k) {
            const double y = premier + k * pas;
            m.bornes.push_back({a_gauche[k], {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-62, y + 5, a_gauche[k], 12));
            m.bornes.push_back({a_droite[k], {90, y}, ""});
            m.symbole.push_back(ligne(70, y, 90, y));
            m.symbole.push_back(texte(34, y + 5, a_droite[k], 12));
        }
        const double demi = 70;
        m.symbole.insert(m.symbole.begin(), rect(-70, -demi, 70, demi));
        m.symbole.push_back(texte(-36, premier - 20, "ATtiny85", 12));
        m.empreinte = {"ATTINY_DIP8", {}, 9.8, 7.62};
        m.mcu = "attiny85";
        // Quartz interne : 8 MHz d'origine, et non 16 comme un Arduino.
        m.horloge = 8000000;
        m.langage = "C (registres)";
        m.programme_exemple = kProgrammeAttiny;
        // Sur cette puce, PB1 EST la broche 1. Sur un ATmega328P, PB1 est la
        // broche 9. Le même nom, deux puces, deux broches : seule la carte
        // peut trancher, et c'est ce que dit cette table.
        for (int bit = 0; bit <= 5; ++bit)
            m.broches_mcu["PB" + std::to_string(bit)] = bit;
        enregistrer(std::move(m));
    }
}

}  // namespace coeur
