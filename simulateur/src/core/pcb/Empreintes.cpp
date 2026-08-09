#include "core/pcb/Empreintes.h"

#include <algorithm>
#include <cctype>

namespace coeur {
namespace empreintes {

namespace {

constexpr double kPas = 2.54;          // le pas de tout ce qui se soude
constexpr double kRangeeDip = 7.62;    // écart des rangées d'un DIP

Pastille trou(int numero, double x, double y, double diametre = 1.7,
              double percage = 1.0) {
    Pastille pastille;
    pastille.numero = numero;
    pastille.x = x;
    pastille.y = y;
    pastille.diametre = diametre;
    pastille.percage = percage;
    // La broche 1 est carrée : c'est le repère qu'on cherche des yeux au
    // moment de souder, et tous les fabricants le dessinent ainsi.
    pastille.forme =
        numero == 1 ? Pastille::Forme::Rectangulaire : Pastille::Forme::Ronde;
    return pastille;
}

Pastille fixation(double x, double y) {
    Pastille pastille;
    pastille.numero = 0;               // 0 : ce n'est pas une broche
    pastille.x = x;
    pastille.y = y;
    pastille.diametre = 6.0;
    pastille.percage = 3.2;
    return pastille;
}

TraitEmpreinte ligne(double x1, double y1, double x2, double y2) {
    return {TraitEmpreinte::Genre::Ligne, x1, y1, x2, y2};
}

TraitEmpreinte rectangle(double x1, double y1, double x2, double y2) {
    return {TraitEmpreinte::Genre::Rect, x1, y1, x2, y2};
}

TraitEmpreinte cercle(double x, double y, double rayon) {
    return {TraitEmpreinte::Genre::Cercle, x, y, rayon, 0};
}

// Boîtier à deux rangées : le DIP et l'afficheur à sept segments ne diffèrent
// que par l'écart des rangées et la hauteur du corps.
Empreinte boitier_double(const std::string& nom, int broches, double ecart,
                         double corps_hauteur) {
    if (broches < 4) broches = 4;
    if (broches % 2) ++broches;
    const int par_rangee = broches / 2;
    const double corps = (par_rangee - 1) * kPas + 3.81;

    Empreinte empreinte;
    empreinte.nom = nom;
    // Numérotation réelle : broche 1 en bas à gauche, on tourne dans le sens
    // inverse des aiguilles d'une montre, détrompeur à gauche.
    for (int k = 0; k < par_rangee; ++k) {
        const double x = (k - (par_rangee - 1) / 2.0) * kPas;
        empreinte.pastilles.push_back(trou(k + 1, x, ecart / 2));
    }
    for (int k = 0; k < par_rangee; ++k) {
        const double x = ((par_rangee - 1 - k) - (par_rangee - 1) / 2.0) * kPas;
        empreinte.pastilles.push_back(trou(par_rangee + k + 1, x, -ecart / 2));
    }

    empreinte.serigraphie.push_back(rectangle(-corps / 2, -corps_hauteur / 2,
                                              corps / 2, corps_hauteur / 2));
    // Le détrompeur : la demi-lune fraisée sur le petit côté.
    empreinte.serigraphie.push_back(cercle(-corps / 2, 0, 1.3));
    empreinte.largeur = corps;
    empreinte.hauteur = std::max(ecart + 2.2, corps_hauteur);
    return empreinte;
}

// Boîtier monté en surface, deux rangées de pastilles rectangulaires.
Empreinte boitier_cms(const std::string& nom, int broches, double pas,
                      double ecart, double corps_l, double corps_h) {
    if (broches < 2) broches = 2;
    if (broches % 2) ++broches;
    const int par_rangee = broches / 2;

    Empreinte empreinte;
    empreinte.nom = nom;
    for (int rangee = 0; rangee < 2; ++rangee) {
        for (int k = 0; k < par_rangee; ++k) {
            const int position = rangee == 0 ? k : par_rangee - 1 - k;
            const double x = (position - (par_rangee - 1) / 2.0) * pas;
            Pastille pastille =
                trou(rangee * par_rangee + k + 1, x,
                     rangee == 0 ? ecart / 2 : -ecart / 2, 0.65, 0.0);
            pastille.forme = Pastille::Forme::Rectangulaire;
            pastille.hauteur = 1.55;
            empreinte.pastilles.push_back(pastille);
        }
    }
    empreinte.serigraphie.push_back(
        rectangle(-corps_l / 2, -corps_h / 2, corps_l / 2, corps_h / 2));
    // Le point de la broche 1, sérigraphié à côté du boîtier.
    empreinte.serigraphie.push_back(
        cercle(-corps_l / 2 - 0.6, corps_h / 2 + 0.6, 0.3));
    empreinte.largeur = corps_l;
    empreinte.hauteur = ecart + 1.6;
    return empreinte;
}

int nombre_dans(const std::string& texte) {
    int valeur = 0;
    bool trouve = false;
    for (char caractere : texte) {
        if (std::isdigit(static_cast<unsigned char>(caractere))) {
            valeur = valeur * 10 + (caractere - '0');
            trouve = true;
        } else if (trouve) {
            break;    // on ne garde que le premier nombre : « DIP-14 » → 14
        }
    }
    return trouve ? valeur : 0;
}

bool commence_par(const std::string& texte, const char* debut) {
    return texte.rfind(debut, 0) == 0;
}

int pair_au_moins(size_t bornes) {
    int nombre = static_cast<int>(bornes);
    if (nombre < 4) nombre = 4;
    if (nombre % 2) ++nombre;
    return nombre;
}

}  // namespace

// ---------------------------------------------------------------------------
// Générateurs
// ---------------------------------------------------------------------------
Empreinte dip(int broches) {
    return boitier_double("DIP-" + std::to_string(std::max(4, broches)),
                          broches, kRangeeDip, 6.35);
}

Empreinte barrette(int colonnes, int rangees) {
    colonnes = std::max(1, colonnes);
    rangees = std::max(1, rangees);

    Empreinte empreinte;
    empreinte.nom = "BARRETTE_" + std::to_string(colonnes) + "x"
                    + std::to_string(rangees);
    int numero = 1;
    for (int colonne = 0; colonne < colonnes; ++colonne)
        for (int rangee = 0; rangee < rangees; ++rangee) {
            const double x = (colonne - (colonnes - 1) / 2.0) * kPas;
            const double y = (rangee - (rangees - 1) / 2.0) * kPas;
            empreinte.pastilles.push_back(trou(numero++, x, y, 1.7, 1.0));
        }
    const double largeur = colonnes * kPas, hauteur = rangees * kPas;
    empreinte.serigraphie.push_back(
        rectangle(-largeur / 2, -hauteur / 2, largeur / 2, hauteur / 2));
    empreinte.largeur = largeur;
    empreinte.hauteur = hauteur;
    return empreinte;
}

Empreinte bornier(int bornes) {
    bornes = std::max(1, bornes);
    constexpr double kPasBornier = 5.08;

    Empreinte empreinte;
    empreinte.nom = "BORNIER_" + std::to_string(bornes) + "P";
    for (int k = 0; k < bornes; ++k) {
        Pastille pastille =
            trou(k + 1, (k - (bornes - 1) / 2.0) * kPasBornier, 0, 2.4, 1.3);
        empreinte.pastilles.push_back(pastille);
    }
    const double largeur = bornes * kPasBornier;
    empreinte.serigraphie.push_back(rectangle(-largeur / 2, -4.0,
                                              largeur / 2, 4.0));
    // Les têtes de vis, côté fil.
    for (int k = 0; k < bornes; ++k) {
        const double x = (k - (bornes - 1) / 2.0) * kPasBornier;
        empreinte.serigraphie.push_back(cercle(x, -2.0, 1.4));
    }
    empreinte.largeur = largeur;
    empreinte.hauteur = 8.0;
    return empreinte;
}

Empreinte axial(const std::string& nom, double pas, double corps,
                double diametre_corps, bool polarise) {
    Empreinte empreinte;
    empreinte.nom = nom;
    empreinte.pastilles.push_back(trou(1, -pas / 2, 0, 1.6, 0.8));
    empreinte.pastilles.push_back(trou(2, pas / 2, 0, 1.6, 0.8));

    const double demi = corps / 2, rayon = diametre_corps / 2;
    empreinte.serigraphie.push_back(rectangle(-demi, -rayon, demi, rayon));
    // Les deux fils sortants, dessinés jusqu'aux pastilles.
    empreinte.serigraphie.push_back(ligne(-pas / 2, 0, -demi, 0));
    empreinte.serigraphie.push_back(ligne(demi, 0, pas / 2, 0));
    if (polarise)     // la bague de cathode, côté broche 2
        empreinte.serigraphie.push_back(
            ligne(demi - 0.9, -rayon, demi - 0.9, rayon));
    empreinte.largeur = pas + 1.6;
    empreinte.hauteur = std::max(diametre_corps, 1.6);
    return empreinte;
}

Empreinte radial(const std::string& nom, double pas, double diametre,
                 bool polarise) {
    Empreinte empreinte;
    empreinte.nom = nom;
    empreinte.pastilles.push_back(trou(1, -pas / 2, 0, 1.6, 0.8));
    empreinte.pastilles.push_back(trou(2, pas / 2, 0, 1.6, 0.8));
    empreinte.serigraphie.push_back(cercle(0, 0, diametre / 2));
    if (polarise) {
        // Le méplat des chimiques : la moitié marquée est celle du moins.
        const double bord = diametre / 2;
        empreinte.serigraphie.push_back(ligne(bord * 0.55, -bord * 0.83,
                                              bord * 0.55, bord * 0.83));
        empreinte.serigraphie.push_back(ligne(-pas / 2 - 0.9, -diametre / 2 - 0.6,
                                              -pas / 2 + 0.9, -diametre / 2 - 0.6));
        empreinte.serigraphie.push_back(ligne(-pas / 2, -diametre / 2 - 1.5,
                                              -pas / 2, -diametre / 2 + 0.3));
    }
    empreinte.largeur = std::max(diametre, pas + 1.6);
    empreinte.hauteur = diametre;
    return empreinte;
}

Empreinte to92() {
    Empreinte empreinte;
    empreinte.nom = "TO-92";
    for (int k = 0; k < 3; ++k)
        empreinte.pastilles.push_back(trou(k + 1, (k - 1) * kPas, 0, 1.8, 0.9));
    // Le corps : un demi-cylindre, un côté rond, un côté plat.
    empreinte.serigraphie.push_back(cercle(0, -0.6, 2.35));
    empreinte.serigraphie.push_back(ligne(-2.3, 0.9, 2.3, 0.9));
    empreinte.largeur = 5.2;
    empreinte.hauteur = 5.0;
    return empreinte;
}

Empreinte to220() {
    Empreinte empreinte;
    empreinte.nom = "TO-220";
    for (int k = 0; k < 3; ++k)
        empreinte.pastilles.push_back(trou(k + 1, (k - 1) * kPas, 0, 2.0, 1.1));
    empreinte.serigraphie.push_back(rectangle(-5.1, -4.7, 5.1, -0.5));
    // La semelle métallique et son trou de fixation.
    empreinte.serigraphie.push_back(ligne(-5.1, -3.2, 5.1, -3.2));
    empreinte.serigraphie.push_back(cercle(0, -3.9, 1.8));
    empreinte.largeur = 10.2;
    empreinte.hauteur = 6.5;
    return empreinte;
}

Empreinte led(double diametre) {
    Empreinte empreinte;
    empreinte.nom = "LED_" + std::to_string(static_cast<int>(diametre)) + "MM";
    empreinte.pastilles.push_back(trou(1, -kPas / 2, 0, 1.8, 0.9));
    empreinte.pastilles.push_back(trou(2, kPas / 2, 0, 1.8, 0.9));
    const double rayon = diametre / 2;
    empreinte.serigraphie.push_back(cercle(0, 0, rayon));
    // Le méplat du boîtier, côté cathode.
    empreinte.serigraphie.push_back(
        ligne(rayon * 0.82, -rayon * 0.57, rayon * 0.82, rayon * 0.57));
    empreinte.largeur = diametre;
    empreinte.hauteur = diametre;
    return empreinte;
}

Empreinte module(const std::string& nom, double largeur, double hauteur,
                 int broches) {
    broches = std::max(1, broches);
    const double barre = (broches - 1) * kPas;
    largeur = std::max(largeur, barre + 4.0);
    hauteur = std::max(hauteur, 6.0);

    Empreinte empreinte;
    empreinte.nom = nom;
    // Le module se raccorde par une barrette sur un bord : c'est ainsi que se
    // câble tout ce qui n'est pas soudé à plat — servo, capteur, moteur.
    const double y = hauteur / 2 - 2.0;
    for (int k = 0; k < broches; ++k)
        empreinte.pastilles.push_back(
            trou(k + 1, (k - (broches - 1) / 2.0) * kPas, y, 1.8, 1.0));

    empreinte.serigraphie.push_back(
        rectangle(-largeur / 2, -hauteur / 2, largeur / 2, hauteur / 2));
    empreinte.serigraphie.push_back(
        rectangle(-barre / 2 - 1.3, y - 1.3, barre / 2 + 1.3, y + 1.3));
    empreinte.largeur = largeur;
    empreinte.hauteur = hauteur;
    return empreinte;
}

// Carte double rangée sur barrettes : Nano et Pro Mini se dessinent de la
// même façon — un contour, deux rangées de broches au pas de 2,54 mm, la
// broche 1 carrée. Seules changent les cotes et la liste des noms.
static Empreinte carte_barrettes(const std::string& nom, double largeur,
                                 double hauteur, double ecart_rangees,
                                 const std::vector<std::string>& gauche,
                                 const std::vector<std::string>& droite) {
    Empreinte empreinte;
    empreinte.nom = nom;
    empreinte.largeur = largeur;
    empreinte.hauteur = hauteur;

    int numero = 1;
    // Les broches courent le long des deux grands bords, centrées.
    auto rangee = [&](const std::vector<std::string>& noms, double y) {
        const double debut = -(static_cast<int>(noms.size()) - 1) * kPas / 2;
        for (size_t k = 0; k < noms.size(); ++k) {
            Pastille pastille = trou(numero++, debut + k * kPas, y, 1.8, 1.0);
            pastille.nom = noms[k];
            empreinte.pastilles.push_back(pastille);
        }
    };
    rangee(gauche, -ecart_rangees / 2);
    rangee(droite, ecart_rangees / 2);

    empreinte.serigraphie.push_back(
        rectangle(-largeur / 2, -hauteur / 2, largeur / 2, hauteur / 2));
    // La prise USB dépasse d'un bout : c'est ce qui donne son sens au montage.
    empreinte.serigraphie.push_back(rectangle(-largeur / 2 - 1.0, -3.5,
                                              -largeur / 2 + 6.0, 3.5));
    return empreinte;
}

// Arduino Nano : 43,2 × 18,0 mm, deux rangées de 15 broches écartées de
// 15,24 mm (0,6 pouce) — il enjambe donc le sillon d'une plaque d'essai,
// ce que l'Uno ne sait pas faire.
Empreinte arduino_nano() {
    return carte_barrettes(
        "ARDUINO_NANO", 43.2, 18.0, 15.24,
        {"D12", "D11", "D10", "D9", "D8", "D7", "D6", "D5", "D4", "D3", "D2",
         "GND", "RESET", "D0", "D1"},
        {"D13", "3V3", "AREF", "A0", "A1", "A2", "A3", "A4", "A5", "A6", "A7",
         "5V", "RESET", "GND", "VIN"});
}

// Arduino Pro Mini : 33,0 × 18,0 mm, mêmes deux rangées de 12 broches, plus
// les six broches de programmation sur un bout. Pas de prise USB : c'est ce
// qui la rend si petite, et ce qui oblige à un convertisseur pour la charger.
Empreinte arduino_pro_mini() {
    // Deux rangées de douze le long des grands bords — le brochage réel, TX
    // et RX en tête —, puis quatre pastilles à l'intérieur de la carte : A4 et
    // A5 au milieu, A6 et A7 près du bout. C'est ce qui distingue la Pro Mini
    // d'une simple barrette : quatre de ses entrées ne sont pas sur le bord,
    // et il faut le savoir avant de router.
    Empreinte empreinte = carte_barrettes(
        "ARDUINO_PRO_MINI", 33.0, 18.0, 15.24,
        {"D1", "D0", "RST", "GND", "D2", "D3", "D4", "D5", "D6", "D7", "D8",
         "D9"},
        {"RAW", "GND", "RST2", "VCC", "A3", "A2", "A1", "A0", "D13", "D12",
         "D11", "D10"});

    int numero = static_cast<int>(empreinte.pastilles.size()) + 1;
    const struct { const char* nom; double x, y; } interieures[] = {
        {"A4", -1.27, -2.54}, {"A5", -1.27, 2.54},
        {"A6", 12.7, -2.54},  {"A7", 12.7, 2.54}};
    for (const auto& point : interieures) {
        Pastille pastille = trou(numero++, point.x, point.y, 1.8, 1.0);
        pastille.nom = point.nom;
        empreinte.pastilles.push_back(pastille);
    }

    // Le connecteur de programmation, en bout de carte : six broches, et sans
    // lui la Pro Mini ne peut pas être chargée du tout.
    empreinte.serigraphie.push_back(rectangle(-16.5, -8.0, -11.5, 8.0));
    return empreinte;
}

// Carte Arduino Mega 2560 : 101,6 × 53,3 mm. Les connecteurs du bas et du
// haut sont ceux de l'Uno, aux mêmes cotes — c'est ce qui permet d'y poser un
// shield —, prolongés par les entrées analogiques supplémentaires ; la double
// rangée de trente-six broches du bout est propre au Mega.
Empreinte arduino_mega() {
    constexpr double kLargeur = 101.6, kHauteur = 53.3;
    Empreinte empreinte;
    empreinte.nom = "ARDUINO_MEGA";
    empreinte.largeur = kLargeur;
    empreinte.hauteur = kHauteur;

    int numero = 1;
    auto poser = [&](const std::string& nom, double x, double y) {
        Pastille pastille = trou(numero++, x - kLargeur / 2, kHauteur / 2 - y,
                                 1.9, 1.0);
        pastille.nom = nom;
        empreinte.pastilles.push_back(pastille);
    };

    const double bas = 2.54, haut = 50.8;
    // Bord du bas : alimentation, puis A0..A7 — les positions de l'Uno.
    const char* alimentation[] = {"NC", "IOREF", "RESET", "3V3",
                                  "5V", "GND", "GND", "VIN"};
    for (int k = 0; k < 8; ++k)
        poser(alimentation[k], 17.78 + k * kPas, bas);
    for (int k = 0; k <= 7; ++k)
        poser("A" + std::to_string(k), 43.18 + k * kPas, bas);
    // A8..A15 : le prolongement propre au Mega.
    for (int k = 8; k <= 15; ++k)
        poser("A" + std::to_string(k), 43.18 + k * kPas, bas);

    // Bord du haut : D8..D13 puis D0..D7, comme sur l'Uno, avec son décalage.
    const char* numeriques[] = {"SCL", "SDA", "AREF", "GND", "D13",
                                "D12", "D11", "D10", "D9", "D8"};
    for (int k = 0; k < 10; ++k)
        poser(numeriques[k], 15.24 + k * kPas, haut);
    for (int k = 0; k < 8; ++k)
        poser("D" + std::to_string(7 - k), 42.16 + k * kPas, haut);
    // D14..D21, à la suite.
    for (int k = 0; k < 8; ++k)
        poser("D" + std::to_string(14 + k), 66.04 + k * kPas, haut);

    // La double rangée du bout : D22 à D53, deux par deux.
    for (int paire = 0; paire < 16; ++paire) {
        const double x = 88.9 - paire * kPas;
        poser("D" + std::to_string(22 + paire * 2), x, haut - 2.54);
        poser("D" + std::to_string(23 + paire * 2), x, haut - 5.08);
    }

    const double fixations[4][2] = {
        {13.97, 2.54}, {15.24, 50.8}, {96.52, 2.54}, {96.52, 50.8}};
    for (const auto& point : fixations)
        empreinte.pastilles.push_back(
            fixation(point[0] - kLargeur / 2, kHauteur / 2 - point[1]));

    empreinte.serigraphie.push_back(rectangle(-kLargeur / 2, -kHauteur / 2,
                                              kLargeur / 2, kHauteur / 2));
    empreinte.serigraphie.push_back(
        rectangle(-kLargeur / 2 - 1.5, -kHauteur / 2 + 4.0,
                  -kLargeur / 2 + 10.0, -kHauteur / 2 + 15.0));
    return empreinte;
}

Empreinte arduino_uno() {
    // Contour et connecteurs de la carte Uno : 68,6 × 53,4 mm, quatre
    // barrettes au pas de 2,54 mm — avec, entre D7 et D8, le décalage de
    // 0,16 pouce qui empêche depuis toujours de poser un shield sur une
    // plaque d'essai.
    constexpr double kLargeur = 68.6, kHauteur = 53.4;
    Empreinte empreinte;
    empreinte.nom = "ARDUINO_UNO";
    empreinte.largeur = kLargeur;
    empreinte.hauteur = kHauteur;

    // Repère de la carte : origine en bas à gauche, y vers le haut. Les
    // pastilles, elles, se comptent depuis le centre avec y vers le bas.
    auto poser = [&empreinte](const std::string& nom, int numero, double x,
                              double y) {
        Pastille pastille = trou(numero, x - kLargeur / 2, kHauteur / 2 - y,
                                 1.9, 1.0);
        pastille.nom = nom;
        empreinte.pastilles.push_back(pastille);
    };

    int numero = 1;
    const double bas = 2.54, haut = 50.8;
    // Connecteur d'alimentation, puis analogique, sur le bord du bas.
    const char* alimentation[] = {"NC", "IOREF", "RESET", "3V3",
                                  "5V", "GND", "GND", "VIN"};
    for (int k = 0; k < 8; ++k)
        poser(alimentation[k], numero++, 17.78 + k * kPas, bas);
    for (int k = 0; k < 6; ++k)
        poser("A" + std::to_string(k), numero++, 43.18 + k * kPas, bas);
    // Connecteurs numériques sur le bord du haut, le grand d'abord.
    const char* numeriques[] = {"SCL", "SDA", "AREF", "GND", "D13",
                                "D12", "D11", "D10", "D9", "D8"};
    for (int k = 0; k < 10; ++k)
        poser(numeriques[k], numero++, 15.24 + k * kPas, haut);
    for (int k = 0; k < 8; ++k)
        poser("D" + std::to_string(7 - k), numero++, 42.16 + k * kPas, haut);

    // Les quatre trous de fixation, aux cotes du shield.
    const double fixations[4][2] = {
        {13.97, 2.54}, {15.24, 50.8}, {66.04, 35.56}, {66.04, 7.62}};
    for (const auto& point : fixations)
        empreinte.pastilles.push_back(
            fixation(point[0] - kLargeur / 2, kHauteur / 2 - point[1]));

    empreinte.serigraphie.push_back(rectangle(-kLargeur / 2, -kHauteur / 2,
                                              kLargeur / 2, kHauteur / 2));
    // La prise USB et le connecteur d'alimentation qui dépassent à gauche.
    empreinte.serigraphie.push_back(
        rectangle(-kLargeur / 2 - 1.5, -kHauteur / 2 + 4.0,
                  -kLargeur / 2 + 10.0, -kHauteur / 2 + 15.0));
    empreinte.serigraphie.push_back(
        rectangle(-kLargeur / 2 - 1.5, kHauteur / 2 - 15.0,
                  -kLargeur / 2 + 9.0, kHauteur / 2 - 6.0));
    return empreinte;
}

// ---------------------------------------------------------------------------
// Attribution
// ---------------------------------------------------------------------------
bool physique(const Modele& modele) {
    if (!modele.noeud_impose.empty()) return false;    // masse, +5 V…
    const Empreinte& declaree = modele.empreinte;
    return !(declaree.nom.empty() && declaree.pastilles.empty()
             && declaree.largeur <= 0 && declaree.hauteur <= 0);
}

namespace {

// Gabarit reconnu par le nom d'empreinte déclaré au catalogue. C'est le même
// principe que la bibliothèque d'empreintes de KiCad : le modèle nomme son
// boîtier, la bibliothèque le dessine.
Empreinte gabarit(const Modele& modele) {
    const std::string& nom = modele.empreinte.nom;
    const size_t bornes = modele.bornes.size();

    if (nom == "ARDUINO_UNO") return arduino_uno();
    if (nom == "ARDUINO_MEGA") return arduino_mega();
    if (nom == "ARDUINO_NANO") return arduino_nano();
    // Pi Pico : 51 x 21 mm, deux rangées de vingt au pas de 2,54 mm.
    if (nom == "ESP32_DEVKIT")
        return carte_barrettes("ESP32_DEVKIT", 52.0, 28.0, 25.4, {}, {});
    if (nom == "PI_PICO")
        return carte_barrettes("PI_PICO", 51.0, 21.0, 17.78, {}, {});
    // Blue Pill : 53 x 22,9 mm, deux rangées de vingt.
    if (nom == "BLUE_PILL")
        return carte_barrettes("BLUE_PILL", 53.0, 22.9, 17.78, {}, {});
    if (nom == "ATTINY_DIP8") return dip(8);
    if (nom == "ARDUINO_PRO_MINI") return arduino_pro_mini();
    if (commence_par(nom, "SOIC")) {
        const int broches = std::max(nombre_dans(nom), pair_au_moins(bornes));
        return boitier_cms("SOIC-" + std::to_string(broches), broches, 1.27,
                           5.2, broches * 0.635 + 1.4, 3.9);
    }
    if (commence_par(nom, "DIP")) {
        const int demande = nombre_dans(nom);
        return dip(std::max(demande, pair_au_moins(bornes)));
    }
    if (commence_par(nom, "7SEG"))
        return boitier_double("7SEG_0.56", std::max(10, pair_au_moins(bornes)),
                              15.24, 12.7);
    if (commence_par(nom, "R_AXIAL"))
        return axial("R_AXIAL_0207", 10.16, 6.5, 2.5, false);
    if (commence_par(nom, "D_AXIAL"))
        return axial("D_DO-41", 7.62, 4.5, 2.4, true);
    if (commence_par(nom, "L_AXIAL"))
        return axial("L_AXIAL", 10.16, 7.0, 3.4, false);
    if (commence_par(nom, "C_DISC"))
        return radial("C_DISC_5MM", 5.08, 5.0, false);
    if (commence_par(nom, "C_ELEC") || commence_par(nom, "C_POL"))
        return radial("C_ELEC_6.3MM", 2.54, 6.3, true);
    if (commence_par(nom, "LED"))
        return led(nombre_dans(nom) > 0 ? nombre_dans(nom) : 5.0);
    if (commence_par(nom, "TO-92")) return to92();
    if (commence_par(nom, "TO-220")) return to220();
    if (commence_par(nom, "BUZZER"))
        return radial("BUZZER_12MM", 7.62, 12.0, true);
    // Ce qui ne se soude pas sur la carte s'y raccorde : un moteur, un
    // haut-parleur, une pile n'ont pas d'empreinte — leur bornier en a une.
    if (commence_par(nom, "MOTEUR") || commence_par(nom, "NEMA")
        || commence_par(nom, "HP_") || commence_par(nom, "PILE")
        || commence_par(nom, "ALIM"))
        return bornier(static_cast<int>(bornes));
    if (!nom.empty() && bornes > 0)
        return module(nom, modele.empreinte.largeur, modele.empreinte.hauteur,
                      static_cast<int>(bornes));

    // Rien de reconnu : on déduit du nombre de bornes, ce qui vaut toujours
    // mieux qu'un composant absent de la carte.
    if (bornes <= 2) return axial("GENERIQUE_AXIAL", 10.16, 6.0, 2.5, false);
    if (bornes == 3) return to92();
    return dip(pair_au_moins(bornes));
}

}  // namespace

Empreinte resoudre(const Modele& modele) {
    Empreinte empreinte = gabarit(modele);

    // Attribution des bornes aux broches : celles que le gabarit nomme déjà
    // (la carte Arduino et son brochage) sont respectées ; les autres suivent
    // l'ordre de déclaration du modèle.
    std::vector<Pastille*> libres;
    for (Pastille& pastille : empreinte.pastilles)
        if (pastille.numero > 0 && pastille.nom.empty())
            libres.push_back(&pastille);
    std::sort(libres.begin(), libres.end(),
              [](const Pastille* a, const Pastille* b) {
                  return a->numero < b->numero;
              });

    size_t rang = 0;
    for (const BorneSymbole& borne : modele.bornes) {
        // Une borne déjà nommée par le gabarit garde sa broche.
        bool nommee = false;
        for (const Pastille& pastille : empreinte.pastilles)
            if (pastille.nom == borne.nom) nommee = true;
        if (nommee) continue;
        if (rang < libres.size()) libres[rang++]->nom = borne.nom;
    }
    return empreinte;
}

}  // namespace empreintes
}  // namespace coeur
