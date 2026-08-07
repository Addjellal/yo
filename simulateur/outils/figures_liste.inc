// Les schémas électriques du cours, décrits en données.
//
// Chaque figure est un montage qu'un débutant doit savoir lire puis câbler.
// L'ordre suit celui du module Arduino : commander une sortie, lire une
// entrée, mesurer une grandeur, commander une charge de puissance.
namespace {

std::vector<Figure> catalogue_figures() {
    std::vector<Figure> figures;

    // -----------------------------------------------------------------------
    {   // Commander une LED : le montage de base, et le calcul de la résistance
        Figure f;
        f.fichier = "schema-led-resistance.svg";
        f.titre = "Commander une LED — la résistance n'est pas facultative";
        f.marge_droite = 210;
        f.composants = {
            {"U1", "arduino_uno", 120, 90, 0, "", {}, {"D13"}},
            {"LED1", "led", 340, 70, 0, "rouge", {{"couleur", "rouge"}}},
            {"R1", "resistance", 470, 70, 0, "220 Ω", {}},
            {"GND1", "masse", 580, 170, 0, "", {}},
        };
        f.fils = {
            {"U1", "D13", "LED1", "A"},
            {"LED1", "K", "R1", "1"},
            {"R1", "2", "GND1", "1"},
        };
        f.notes = {
            {620, 60, "R = (5 − 2) / 0,012", false},
            {620, 80, "  ≈ 250 Ω → 220 Ω", false},
            {620, 118, "Sans R1 : ~180 mA,", false},
            {620, 138, "la LED et la broche", false},
            {620, 158, "sont détruites.", false},
        };
        figures.push_back(f);
    }

    // -----------------------------------------------------------------------
    {   // Lire un bouton : pull-up interne, et la logique inversée qui va avec
        Figure f;
        f.fichier = "schema-bouton-pullup.svg";
        f.titre = "Lire un bouton — le pull-up interne évite l'entrée flottante";
        f.marge_droite = 250;
        f.composants = {
            {"U1", "arduino_uno", 120, 120, 0, "", {}, {"D2"}},
            {"BP1", "bouton", 350, 120, 0, "au repos : ouvert", {}},
            {"GND1", "masse", 470, 190, 0, "", {}},
        };
        f.fils = {
            {"U1", "D2", "BP1", "1"},
            {"BP1", "2", "GND1", "1"},
        };
        f.notes = {
            {520, 60, "pinMode(2, INPUT_PULLUP);", false},
            {520, 96, "Relâché → D2 lu à 5 V → HIGH", false},
            {520, 116, "Appuyé  → D2 tiré à 0 V → LOW", false},
            {520, 152, "La logique est inversée :", false},
            {520, 172, "if (digitalRead(2) == LOW)", false},
            {520, 192, "  /* le bouton est appuyé */", false},
        };
        figures.push_back(f);
    }

    // -----------------------------------------------------------------------
    {   // Mesurer une tension : le pont diviseur, base de toute entrée analogique
        Figure f;
        f.fichier = "schema-pont-diviseur.svg";
        f.titre = "Pont diviseur — mesurer une grandeur, adapter une tension";
        f.marge_droite = 240;
        f.composants = {
            {"V1", "alim5v", 220, 40, 0, "", {}},
            {"R1", "resistance", 220, 130, 90, "10 kΩ", {}},
            {"R2", "resistance", 220, 250, 90, "10 kΩ", {}},
            {"GND1", "masse", 220, 350, 0, "", {}},
            {"U1", "arduino_uno", 470, 190, 0, "", {}, {"A0"}},
        };
        f.fils = {
            {"V1", "1", "R1", "1"},
            {"R1", "2", "R2", "1"},
            {"R2", "2", "GND1", "1"},
            {"R1", "2", "U1", "A0"},
        };
        f.notes = {
            {320, 186, "Vs", false},
            {620, 90, "Vs = Ve × R2 / (R1 + R2)", false},
            {620, 126, "Ici : 5 × 10 / 20 = 2,5 V", false},
            {620, 162, "Remplacez R1 par une LDR", false},
            {620, 182, "ou une thermistance : la", false},
            {620, 202, "tension devient une mesure.", false},
            {620, 238, "analogRead(A0) → 0 à 1023", false},
        };
        figures.push_back(f);
    }

    // -----------------------------------------------------------------------
    {   // Le potentiomètre : le pont diviseur réglable
        Figure f;
        f.fichier = "schema-potentiometre.svg";
        f.titre = "Potentiomètre sur une entrée analogique";
        f.marge_droite = 250;
        f.composants = {
            {"V1", "alim5v", 200, 130, 0, "", {}},
            {"POT1", "potentiometre", 200, 250, 0, "10 kΩ", {}},
            {"GND1", "masse", 200, 350, 0, "", {}},
            {"U1", "arduino_uno", 480, 180, 0, "", {}, {"A0"}},
        };
        f.fils = {
            {"V1", "1", "POT1", "A"},
            {"POT1", "B", "GND1", "1"},
            {"POT1", "W", "U1", "A0"},
        };
        f.notes = {
            {600, 96, "Le curseur partage la piste", false},
            {600, 116, "en deux résistances : c'est", false},
            {600, 136, "un pont diviseur réglable.", false},
            {600, 176, "Butée basse → 0 V → 0", false},
            {600, 196, "Milieu → 2,5 V → 512", false},
            {600, 216, "Butée haute → 5 V → 1023", false},
        };
        figures.push_back(f);
    }

    // -----------------------------------------------------------------------
    {   // Commander une charge : le transistor en commutation
        Figure f;
        f.fichier = "schema-transistor-moteur.svg";
        f.titre = "Commander un moteur — une sortie ne fournit que 20 mA";
        f.marge_droite = 240;
        f.composants = {
            {"V1", "alim5v", 430, 30, 0, "", {}},
            {"M1", "moteur_cc", 430, 120, 90, "", {}},
            {"D1", "diode", 560, 120, 90, "roue libre", {{"reference", "1N4007"}}},
            {"U1", "arduino_uno", 120, 250, 0, "", {}, {"D9"}},
            {"R1", "resistance", 300, 230, 0, "1 kΩ", {}},
            {"Q1", "transistor_npn", 430, 250, 0, "2N2222", {}},
            {"GND1", "masse", 430, 370, 0, "", {}},
        };
        f.fils = {
            {"V1", "1", "M1", "+"},
            {"M1", "-", "Q1", "C"},
            {"V1", "1", "D1", "K"},
            {"D1", "A", "Q1", "C"},
            {"U1", "D9", "R1", "1"},
            {"R1", "2", "Q1", "B"},
            {"Q1", "E", "GND1", "1"},
        };
        f.notes = {
            {640, 66, "D1 : diode de roue libre.", false},
            {640, 86, "Sans elle, la coupure du", false},
            {640, 106, "moteur produit une", false},
            {640, 126, "surtension qui détruit Q1.", false},
            {640, 176, "R1 limite le courant de", false},
            {640, 196, "base : (5 − 0,7) / 1000", false},
            {640, 216, "≈ 4,3 mA, largement dans", false},
            {640, 236, "les limites de la sortie.", false},
        };
        figures.push_back(f);
    }

    // -----------------------------------------------------------------------
    {   // Isoler : l'optocoupleur, quand les deux mondes ne partagent pas la masse
        Figure f;
        f.fichier = "schema-optocoupleur.svg";
        f.titre = "Optocoupleur — commander sans relier les masses";
        f.marge_droite = 230;
        f.composants = {
            {"U1", "arduino_uno", 100, 160, 0, "", {}, {"D5"}},
            {"R1", "resistance", 280, 130, 0, "330 Ω", {}},
            {"OK1", "optocoupleur", 420, 150, 0, "4N25", {}},
            {"GND1", "masse", 340, 240, 0, "", {}},
            {"R2", "resistance", 570, 90, 90, "4,7 kΩ", {}},
            {"V2", "pile", 570, -10, 0, "", {}},
        };
        f.fils = {
            {"U1", "D5", "R1", "1"},
            {"R1", "2", "OK1", "A"},
            {"OK1", "K", "GND1", "1"},
            {"V2", "+", "R2", "1"},
            {"R2", "2", "OK1", "C"},
        };
        f.notes = {
            {600, -14, "24 V", false},
            {650, 96, "Deux circuits, deux masses.", false},
            {650, 116, "Seule la lumière passe.", false},
            {650, 152, "Indispensable dès qu'on", false},
            {650, 172, "touche au secteur ou à une", false},
            {650, 192, "machine : une erreur de", false},
            {650, 212, "câblage ne remonte pas", false},
            {650, 232, "jusqu'à la carte.", false},
        };
        figures.push_back(f);
    }

    // -----------------------------------------------------------------------
    {   // Lisser une PWM : le filtre RC, et pourquoi il faut le dimensionner
        Figure f;
        f.fichier = "schema-filtre-rc.svg";
        f.titre = "Filtre RC — transformer une PWM en tension continue";
        f.marge_droite = 250;
        f.composants = {
            {"U1", "arduino_uno", 120, 150, 0, "", {}, {"D9"}},
            {"R1", "resistance", 340, 120, 0, "10 kΩ", {}},
            {"C1", "condensateur", 460, 200, 90, "100 nF", {}},
            {"GND1", "masse", 460, 290, 0, "", {}},
        };
        f.fils = {
            {"U1", "D9", "R1", "1"},
            {"R1", "2", "C1", "1"},
            {"C1", "2", "GND1", "1"},
        };
        f.notes = {
            {560, 118, "Vs", false},
            {620, 90, "τ = R × C = 1 ms", false},
            {620, 126, "La PWM de l'Arduino bat à", false},
            {620, 146, "490 Hz, soit 2 ms de période.", false},
            {620, 182, "τ du même ordre que la", false},
            {620, 202, "période : il reste de", false},
            {620, 222, "l'ondulation. Pour lisser", false},
            {620, 242, "vraiment, prenez τ ≥ 10 T.", false},
        };
        figures.push_back(f);
    }

    // -----------------------------------------------------------------------
    {   // Alimenter : régulateur et condensateurs de découplage
        Figure f;
        f.fichier = "schema-alimentation-5v.svg";
        f.titre = "Alimentation régulée — le montage minimal d'un 7805";
        f.marge_droite = 240;
        f.composants = {
            {"V1", "pile", 120, 150, 0, "9 V", {}},
            {"C1", "condensateur", 260, 180, 90, "330 nF", {}},
            {"REG1", "regulateur_5v", 420, 120, 0, "", {}},
            {"C2", "condensateur", 580, 180, 90, "100 µF", {}},
            {"GND1", "masse", 120, 260, 0, "", {}},
            {"GND2", "masse", 260, 260, 0, "", {}},
            {"GND3", "masse", 420, 260, 0, "", {}},
            {"GND4", "masse", 580, 260, 0, "", {}},
        };
        f.fils = {
            {"V1", "+", "REG1", "IN"},
            {"V1", "+", "C1", "1"},
            {"V1", "-", "GND1", "1"},
            {"C1", "2", "GND2", "1"},
            {"REG1", "GND", "GND3", "1"},
            {"REG1", "OUT", "C2", "1"},
            {"C2", "2", "GND4", "1"},
        };
        f.notes = {
            {632, 152, "→ 5 V régulés", false},
            {660, 66, "C1 à l'entrée : stabilise le", false},
            {660, 86, "régulateur, qui oscille sans lui.", false},
            {660, 126, "C2 à la sortie : encaisse les", false},
            {660, 146, "appels de courant brefs.", false},
            {660, 186, "Il faut au moins 2 V d'écart", false},
            {660, 206, "entre l'entrée et la sortie :", false},
            {660, 226, "7 V minimum pour sortir 5 V.", false},
        };
        figures.push_back(f);
    }

    // -----------------------------------------------------------------------
    {   // Adapter les niveaux : 5 V vers 3,3 V, le piège classique du STM32
        Figure f;
        f.fichier = "schema-adaptation-3v3.svg";
        f.titre = "Adapter 5 V vers 3,3 V — une entrée STM32 ne tolère pas 5 V";
        f.marge_droite = 250;
        f.composants = {
            {"U1", "arduino_uno", 120, 150, 0, "", {}, {"D3"}},
            {"R1", "resistance", 330, 120, 0, "1,8 kΩ", {}},
            {"R2", "resistance", 450, 220, 90, "3,3 kΩ", {}},
            {"GND1", "masse", 450, 330, 0, "", {}},
        };
        f.fils = {
            {"U1", "D3", "R1", "1"},
            {"R1", "2", "R2", "1"},
            {"R2", "2", "GND1", "1"},
        };
        f.notes = {
            {520, 118, "vers l'entrée 3,3 V", false},
            {620, 160, "5 × 3,3 / (1,8 + 3,3) = 3,2 V", false},
            {620, 196, "Ce pont ne marche que dans", false},
            {620, 216, "ce sens. Pour une liaison", false},
            {620, 236, "bidirectionnelle (I²C), il", false},
            {620, 256, "faut un vrai adaptateur.", false},
        };
        figures.push_back(f);
    }

    // -----------------------------------------------------------------------
    {   // Afficher : le 7 segments et ses huit résistances
        Figure f;
        f.fichier = "schema-afficheur-7segments.svg";
        f.titre = "Afficheur 7 segments — une résistance par segment";
        f.marge_droite = 240;
        f.composants = {
            {"U1", "arduino_uno", 120, 170, 0, "", {}, {"D2", "D3", "D4"}},
            {"R1", "resistance", 330, 100, 0, "220 Ω", {}},
            {"R2", "resistance", 330, 170, 0, "220 Ω", {}},
            {"R3", "resistance", 330, 240, 0, "220 Ω", {}},
            {"AF1", "afficheur_7seg", 500, 180, 0, "cathode commune", {}},
            {"GND1", "masse", 620, 300, 0, "", {}},
        };
        f.fils = {
            {"U1", "D2", "R1", "1"},
            {"U1", "D3", "R2", "1"},
            {"U1", "D4", "R3", "1"},
            {"R1", "2", "AF1", "a"},
            {"R2", "2", "AF1", "b"},
            {"R3", "2", "AF1", "c"},
            {"AF1", "COM", "GND1", "1"},
        };
        f.notes = {
            {660, 96, "Sept segments, sept", false},
            {660, 116, "résistances : chacun est", false},
            {660, 136, "une LED indépendante.", false},
            {660, 172, "Une seule résistance sur le", false},
            {660, 192, "commun ne marcherait pas :", false},
            {660, 212, "la luminosité changerait", false},
            {660, 232, "selon le chiffre affiché.", false},
            {660, 268, "(3 segments dessinés sur 7)", false},
        };
        figures.push_back(f);
    }

    return figures;
}

}  // namespace
