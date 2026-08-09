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

    {   // -------------------------------------------------- Arduino Mega 2560
        // Cinquante-quatre entrées-sorties et seize entrées analogiques : la
        // carte qu'on prend quand l'Uno n'a plus assez de broches. Sa puce,
        // l'ATmega2560, n'est pas une grosse ATmega328P — son programme
        // dépasse 128 Ko, donc ses adresses de retour occupent trois octets,
        // et son brochage n'a rien de régulier : D0 est sur le port E, D22
        // sur le port A, D42 sur le port L.
        Modele m;
        m.type = "arduino_mega";
        m.libelle = "Carte Arduino Mega 2560";
        m.categorie = "Cartes";
        m.prefixe = "U";
        m.carte = true;
        m.couleur_corps = "#1a7f8c";

        const double pas = 16;
        // Cinquante-quatre broches à droite, vingt à gauche : chaque colonne
        // est centrée sur elle-même.
        const double premier_d = -(54 - 1) * pas / 2;
        for (int d = 0; d <= 53; ++d) {
            const double y = premier_d + (53 - d) * pas;
            m.bornes.push_back({"D" + std::to_string(d), {90, y}, ""});
            m.symbole.push_back(ligne(70, y, 90, y));
            m.symbole.push_back(texte(26, y + 4, "D" + std::to_string(d), 10));
        }
        const char* gauche[] = {"5V", "3V3", "GND", "VIN"};
        const double premier_g = -(20 - 1) * pas / 2;
        for (int k = 0; k < 4; ++k) {
            const double y = premier_g + k * pas;
            m.bornes.push_back({gauche[k], {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-64, y + 4, gauche[k], 10));
        }
        for (int a = 0; a <= 15; ++a) {
            const double y = premier_g + (4 + a) * pas;
            m.bornes.push_back({"A" + std::to_string(a), {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-64, y + 4, "A" + std::to_string(a), 10));
        }
        const double demi = (54 - 1) * pas / 2 + 30;
        m.symbole.insert(m.symbole.begin(), rect(-70, -demi, 70, demi));
        m.symbole.push_back(texte(-46, premier_d - 16, "ARDUINO MEGA 2560", 11));
        m.empreinte = {"ARDUINO_MEGA", {}, 101.6, 53.3};
        m.mcu = "atmega2560";
        m.horloge = 16000000;
        m.programme_exemple = kSourceExemple;
        // La numérotation Arduino du Mega : D0..D53 valent 0..53, et A0
        // commence à 54 — ce n'est pas 14 comme sur un Uno.
        for (int a = 0; a <= 15; ++a)
            m.broches_mcu["A" + std::to_string(a)] = 54 + a;
        enregistrer(std::move(m));
    }

    {   // ------------------------------------------------- Raspberry Pi Pico
        // Un Cortex-M0+ à 125 MHz : ni le même jeu d'instructions, ni la même
        // façon de piloter ses broches qu'un AVR. Le simulateur l'exécute avec
        // son cœur ARM, et le brochage GP0..GP28 lui est propre.
        Modele m;
        m.type = "pi_pico";
        m.libelle = "Carte Raspberry Pi Pico";
        m.categorie = "Cartes";
        m.prefixe = "U";
        m.carte = true;
        m.couleur_corps = "#2f3a4a";

        const double pas = 20;
        // Vingt broches par côté, comme sur la carte : GP0 à GP15 d'un côté,
        // GP16 à GP28 et les alimentations de l'autre.
        const double premier = -(20 - 1) * pas / 2;
        for (int g = 0; g <= 15; ++g) {
            const double y = premier + g * pas;
            m.bornes.push_back({"GP" + std::to_string(g), {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-62, y + 4, "GP" + std::to_string(g), 11));
        }
        const char* alimentation[] = {"GND", "3V3", "VSYS", "VBUS"};
        for (int k = 0; k < 4; ++k) {
            const double y = premier + (16 + k) * pas;
            m.bornes.push_back({alimentation[k], {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-62, y + 4, alimentation[k], 11));
        }
        for (int g = 16; g <= 28; ++g) {
            const double y = premier + (g - 16) * pas;
            m.bornes.push_back({"GP" + std::to_string(g), {90, y}, ""});
            m.symbole.push_back(ligne(70, y, 90, y));
            m.symbole.push_back(texte(26, y + 4, "GP" + std::to_string(g), 11));
        }
        const double demi = (20 - 1) * pas / 2 + 30;
        m.symbole.insert(m.symbole.begin(), rect(-70, -demi, 70, demi));
        m.symbole.push_back(texte(-34, premier - 16, "PI PICO", 12));
        m.empreinte = {"PI_PICO", {}, 51.0, 21.0};
        m.mcu = "rp2040";
        m.horloge = 125000000;
        m.langage = "C (registres)";
        m.programme_exemple = kProgrammePico;
        // GP0 est la broche 0 : la numérotation du fabricant est déjà celle
        // du cœur, il n'y a rien à traduire.
        for (int g = 0; g <= 28; ++g)
            m.broches_mcu["GP" + std::to_string(g)] = g;
        enregistrer(std::move(m));
    }

    {   // ------------------------------------------- STM32F103 « Blue Pill »
        // Un Cortex-M3 : le même cœur que le Pico, avec les instructions de
        // trente-deux bits en plus. C'est pourquoi il vient après lui.
        Modele m;
        m.type = "stm32f103";
        m.libelle = "Carte STM32F103 (Blue Pill)";
        m.categorie = "Cartes";
        m.prefixe = "U";
        m.carte = true;
        m.couleur_corps = "#2a4a6a";

        const double pas = 20;
        const double premier = -(20 - 1) * pas / 2;
        // Port A à gauche, port B et port C à droite : le brochage de la
        // carte, où PC13 porte la LED.
        for (int a = 0; a <= 15; ++a) {
            const double y = premier + a * pas;
            m.bornes.push_back({"PA" + std::to_string(a), {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-62, y + 4, "PA" + std::to_string(a), 11));
        }
        const char* alimentation[] = {"GND", "3V3", "5V", "VBAT"};
        for (int k = 0; k < 4; ++k) {
            const double y = premier + (16 + k) * pas;
            m.bornes.push_back({alimentation[k], {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-62, y + 4, alimentation[k], 11));
        }
        for (int b = 0; b <= 15; ++b) {
            const double y = premier + b * pas;
            m.bornes.push_back({"PB" + std::to_string(b), {90, y}, ""});
            m.symbole.push_back(ligne(70, y, 90, y));
            m.symbole.push_back(texte(26, y + 4, "PB" + std::to_string(b), 11));
        }
        for (int c = 13; c <= 15; ++c) {
            const double y = premier + (16 + c - 13) * pas;
            m.bornes.push_back({"PC" + std::to_string(c), {90, y}, ""});
            m.symbole.push_back(ligne(70, y, 90, y));
            m.symbole.push_back(texte(26, y + 4, "PC" + std::to_string(c), 11));
        }
        const double demi = (20 - 1) * pas / 2 + 30;
        m.symbole.insert(m.symbole.begin(), rect(-70, -demi, 70, demi));
        m.symbole.push_back(texte(-40, premier - 16, "STM32F103", 12));
        m.empreinte = {"BLUE_PILL", {}, 53.0, 22.9};
        m.mcu = "stm32f103";
        m.horloge = 72000000;
        m.langage = "C (registres)";
        m.programme_exemple = kProgrammeStm32;
        // Numérotation interne : port A de 0 à 15, port B de 16 à 31, port C
        // de 32 à 47 — c'est ainsi que le cœur les range.
        for (int a = 0; a <= 15; ++a)
            m.broches_mcu["PA" + std::to_string(a)] = a;
        for (int b = 0; b <= 15; ++b)
            m.broches_mcu["PB" + std::to_string(b)] = 16 + b;
        for (int c = 0; c <= 15; ++c)
            m.broches_mcu["PC" + std::to_string(c)] = 32 + c;
        enregistrer(std::move(m));
    }

    {   // -------------------------------------------------- ESP32 DevKit
        // Un Xtensa LX6 : la troisième architecture, et la plus étrangère.
        // Instructions de trois octets, fenêtre de registres, constantes
        // rangées dans un bassin littéral. Le cœur l'exécute ; la chaîne de
        // compilation, elle, n'est pas embarquée — voir le programme.
        Modele m;
        m.type = "esp32";
        m.libelle = "Carte ESP32 DevKit";
        m.categorie = "Cartes";
        m.prefixe = "U";
        m.carte = true;
        m.couleur_corps = "#3a3f4a";

        const double pas = 20;
        const double premier = -(19 - 1) * pas / 2;
        // Les broches réellement utilisables en entrée-sortie de la carte.
        const int gauche[] = {36, 39, 34, 35, 32, 33, 25, 26, 27,
                              14, 12, 13, 9, 10, 11};
        const int droite[] = {23, 22, 1, 3, 21, 19, 18, 5, 17,
                              16, 4, 0, 2, 15, 8};
        for (int k = 0; k < 15; ++k) {
            const double y = premier + k * pas;
            m.bornes.push_back({"GPIO" + std::to_string(gauche[k]), {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(
                texte(-66, y + 4, "IO" + std::to_string(gauche[k]), 10));
            m.bornes.push_back({"GPIO" + std::to_string(droite[k]), {90, y}, ""});
            m.symbole.push_back(ligne(70, y, 90, y));
            m.symbole.push_back(
                texte(34, y + 4, "IO" + std::to_string(droite[k]), 10));
        }
        const char* alimentation[] = {"3V3", "GND", "VIN", "EN"};
        for (int k = 0; k < 4; ++k) {
            const double y = premier + (15 + k) * pas;
            m.bornes.push_back({alimentation[k], {-90, y}, ""});
            m.symbole.push_back(ligne(-90, y, -70, y));
            m.symbole.push_back(texte(-66, y + 4, alimentation[k], 10));
        }
        const double demi = (19 - 1) * pas / 2 + 30;
        m.symbole.insert(m.symbole.begin(), rect(-70, -demi, 70, demi));
        m.symbole.push_back(texte(-30, premier - 16, "ESP32", 12));
        m.empreinte = {"ESP32_DEVKIT", {}, 52.0, 28.0};
        m.mcu = "esp32";
        m.horloge = 240000000;
        m.langage = "C (registres)";
        m.programme_exemple = kProgrammeEsp32;
        // GPIOn est le bit n du bloc GPIO : rien à traduire.
        for (int g = 0; g <= 39; ++g)
            m.broches_mcu["GPIO" + std::to_string(g)] = g;
        enregistrer(std::move(m));
    }
}

}  // namespace coeur
