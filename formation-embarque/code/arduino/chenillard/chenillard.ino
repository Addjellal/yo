// chenillard.ino — corrigé TD 03, exercice 1
// 4 LED qui défilent, vitesse réglée par potentiomètre, SANS delay().
// Câblage : LED (+ résistances 220R) sur D8..D11, potentiomètre sur A0.
// Testable sans matériel sur https://wokwi.com (carte Arduino Uno).

const uint8_t LEDS[] = {8, 9, 10, 11};
const uint8_t NB_LEDS = sizeof LEDS / sizeof LEDS[0];
const uint8_t POT = A0;

uint8_t  index_led = 0;
uint32_t derniere_avance = 0;     // uint32_t : millis() est un 32 bits !

void setup() {
    for (uint8_t i = 0; i < NB_LEDS; i++) pinMode(LEDS[i], OUTPUT);
    digitalWrite(LEDS[0], HIGH);
}

void loop() {
    // Période recalculée à chaque tour : la vitesse réagit immédiatement.
    uint16_t periode = map(analogRead(POT), 0, 1023, 50, 500);

    uint32_t maintenant = millis();
    // Soustraction non signée : robuste au débordement de millis() (49 j).
    if (maintenant - derniere_avance >= periode) {
        derniere_avance = maintenant;

        digitalWrite(LEDS[index_led], LOW);        // éteindre l'actuelle
        index_led = (index_led + 1) % NB_LEDS;     // avancer
        digitalWrite(LEDS[index_led], HIGH);       // allumer la suivante
    }

    // ...la boucle reste libre : on pourrait lire un bouton ici sans rien casser
}
