// Les programmes d'exemple, un par montage.
//
// Ils vivent ici, du côté du firmware, et non dans la fenêtre : c'est ce qui
// permet à un test de tous les compiler avec avr-gcc. Un exemple qui ne
// compile pas est pire qu'une absence d'exemple — il fait douter l'élève de
// lui-même.
//
// Le style suit le contrôleur. Une carte Arduino reçoit un croquis :
// setup(), loop(), pinMode, digitalWrite, analogRead — ce que voit n'importe
// qui ouvrant l'IDE officiel. Le C sur registres est réservé aux puces nues,
// où il est la façon normale de programmer.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace coeur {

inline const char* kSourceExemple = R"(/* Clignotant : la LED sur D13 s'allume une
   demi-seconde sur deux. */

const int LED = 13;

void setup() {
    pinMode(LED, OUTPUT);
}

void loop() {
    digitalWrite(LED, HIGH);
    delay(500);
    digitalWrite(LED, LOW);
    delay(500);
}
)";

inline const char* kProgrammeBouton = R"(/* Bouton sur D2, LED sur D13.
   Le bouton relie D2 à la masse ; INPUT_PULLUP maintient D2 à 5 V quand il
   est relâché. La logique est donc inversée : appuyé = LOW. */

const int BOUTON = 2;
const int LED = 13;

void setup() {
    pinMode(BOUTON, INPUT_PULLUP);
    pinMode(LED, OUTPUT);
}

void loop() {
    digitalWrite(LED, digitalRead(BOUTON) == LOW ? HIGH : LOW);
}
)";

inline const char* kProgrammePotentiometre = R"(/* Potentiomètre sur A0, LED sur D13.
   La LED s'allume au-delà de la moitié de la course. Faites glisser le
   curseur du potentiomètre pendant la simulation : analogRead rend 0 à 1023,
   et la conversion est faite par le vrai convertisseur de l'ATmega328P. */

const int LED = 13;

void setup() {
    pinMode(LED, OUTPUT);
    Serial.begin(9600);
}

void loop() {
    const int mesure = analogRead(A0);
    digitalWrite(LED, mesure > 512 ? HIGH : LOW);
    Serial.print("A0 = ");
    Serial.println((long)mesure);
    delay(200);
}
)";

inline const char* kProgrammeTransistor = R"(/* Commande d'un moteur par transistor, sur D9.
   Une sortie de microcontrôleur ne fournit que quelques dizaines de
   milliampères : le transistor sert d'interrupteur commandé. Observez le
   courant réellement calculé dans le moteur. */

const int COMMANDE = 9;

void setup() {
    pinMode(COMMANDE, OUTPUT);
}

void loop() {
    digitalWrite(COMMANDE, HIGH);
    delay(800);
    digitalWrite(COMMANDE, LOW);
    delay(800);
}
)";

inline const char* kProgrammePwm = R"(/* PWM matérielle sur D9, à environ 490 Hz.
   Le rapport cyclique monte puis redescend : la LED respire. analogWrite
   règle la minuterie 1 de l'ATmega328P — ce n'est pas un créneau fabriqué à
   la main, c'est le matériel qui le produit. Ouvrez l'oscilloscope et réglez
   la base de temps sur 5 ms pour voir le créneau, puis sur 2 s pour voir
   l'enveloppe. */

const int SORTIE = 9;

void setup() {
    pinMode(SORTIE, OUTPUT);
}

void loop() {
    for (int rapport = 0; rapport < 255; rapport += 5) {
        analogWrite(SORTIE, rapport);
        delay(15);
    }
    for (int rapport = 255; rapport > 0; rapport -= 5) {
        analogWrite(SORTIE, rapport);
        delay(15);
    }
}
)";

inline const char* kProgrammeEmetteur = R"(/* Carte U1 — émettrice.
   Elle fait clignoter sa propre LED sur D13 et recopie le même signal sur
   D7, qui part vers la seconde carte. */

const int LED = 13;
const int VERS_U2 = 7;

void setup() {
    pinMode(LED, OUTPUT);
    pinMode(VERS_U2, OUTPUT);
}

void loop() {
    digitalWrite(LED, HIGH);
    digitalWrite(VERS_U2, HIGH);
    delay(300);
    digitalWrite(LED, LOW);
    digitalWrite(VERS_U2, LOW);
    delay(300);
}
)";

inline const char* kProgrammeRecepteur = R"(/* Carte U2 — réceptrice.
   Elle lit sur D2 le signal envoyé par U1 et le recopie sur sa LED. Les deux
   LED doivent clignoter ensemble : c'est la preuve que les deux cartes
   exécutent bien deux programmes différents, dans le même circuit. */

const int DEPUIS_U1 = 2;
const int LED = 13;

void setup() {
    pinMode(DEPUIS_U1, INPUT);   /* sans pull-up : U1 impose le niveau */
    pinMode(LED, OUTPUT);
}

void loop() {
    digitalWrite(LED, digitalRead(DEPUIS_U1));
}
)";

inline const char* kProgrammeServo = R"(/* Balayage d'un servomoteur sur D9.
   Le servo attend une impulsion toutes les 20 ms : 1 ms pour 0°, 2 ms pour
   180°. On la fabrique à la main, sans bibliothèque — c'est exactement ce
   que fait Servo.h, et le voir écrit une fois vaut mieux que l'ignorer. */
unsigned long dernier_top = 0, dernier_pas = 0;
int angle = 0, sens = 1;

void setup() {
    pinMode(9, OUTPUT);
    Serial.begin(9600);
}

void loop() {
    const unsigned long maintenant = millis();

    /* la trame de 20 ms */
    if (maintenant - dernier_top >= 20) {
        dernier_top = maintenant;
        digitalWrite(9, HIGH);
        delayMicroseconds(1000 + (unsigned int)(angle * 1000L / 180));
        digitalWrite(9, LOW);
    }

    /* balayage aller-retour */
    if (maintenant - dernier_pas >= 40) {
        dernier_pas = maintenant;
        angle += sens * 5;
        if (angle >= 180) { angle = 180; sens = -1; }
        if (angle <= 0)   { angle = 0;   sens =  1; }
        Serial.print("angle ");
        Serial.println((long)angle);
    }
}
)";

inline const char* kProgrammeMoteur = R"(/* Moteur commandé en PWM, vitesse réglée par le potentiomètre sur A0.
   Le transistor encaisse le courant, la diode de roue libre encaisse la
   surtension à la coupure — c'est l'inductance de l'induit qui la produit. */
void setup() {
    pinMode(9, OUTPUT);
    Serial.begin(9600);
}

void loop() {
    const int consigne = analogRead(A0) / 4;      /* 0 à 255 */
    analogWrite(9, consigne);
    delay(200);
    Serial.print("consigne ");
    Serial.println((long)consigne);
}
)";

inline const char* kProgrammeRegistre = R"(/* Chenillard sur un 74HC595 : trois broches pour huit LED.
   Le registre décale un bit à chaque coup d'horloge, et ne
   recopie sur ses sorties qu'au front de verrouillage. */
const int DONNEE = 11;      /* SER   */
const int HORLOGE = 13;     /* SRCLK */
const int VERROU = 10;      /* RCLK  */

void setup() {
    pinMode(DONNEE, OUTPUT);
    pinMode(HORLOGE, OUTPUT);
    pinMode(VERROU, OUTPUT);
}

/* Un octet, bit de poids fort en tête — c'est ce que fait shiftOut(). */
void envoyer(unsigned char valeur) {
    digitalWrite(VERROU, LOW);
    for (int bit = 7; bit >= 0; bit--) {
        digitalWrite(HORLOGE, LOW);
        digitalWrite(DONNEE, (valeur >> bit) & 1);
        digitalWrite(HORLOGE, HIGH);
    }
    digitalWrite(VERROU, HIGH);   /* les huit sorties basculent ici */
}

void loop() {
    static unsigned char motif = 1;
    envoyer(motif);
    motif = motif << 1;
    if (motif == 0) motif = 1;
    delay(150);
}
)";

// Une puce nue se programme sur ses registres : il n'y a pas de carte pour
// fournir un noyau, pas de numérotation Arduino, et la broche s'appelle PB5.
// Le style suit le matériel — ce croquis-là n'aurait aucun sens ici.
inline const char* kProgrammeRegistresNu = R"(/* ATmega328P nu : clignotant sur PB5.
   Pas de carte autour, donc pas de setup() ni de loop() : on écrit
   directement dans les registres, comme sur n'importe quel microcontrôleur
   posé sur son propre circuit. */
#include <avr/io.h>
#include <util/delay.h>

int main(void) {
    DDRB |= (1 << PB5);              /* PB5 en sortie */
    while (1) {
        PORTB |= (1 << PB5);         /* allumée */
        _delay_ms(500);
        PORTB &= ~(1 << PB5);        /* éteinte */
        _delay_ms(500);
    }
}
)";

// L'ATtiny85 n'a ni carte ni noyau Arduino embarqué ici : son programme est
// du C sur registres, et son quartz interne tourne à 8 MHz — deux fois moins
// vite qu'un Arduino. Une temporisation écrite pour l'un serait deux fois
// trop longue sur l'autre : c'est F_CPU qui fait la différence, et c'est la
// carte qui le dit.
inline const char* kProgrammeAttiny = R"(/* ATtiny85 : clignotant sur PB1 (broche 6 du boîtier).
   Huit broches en tout, dont deux pour l'alimentation : c'est la puce des
   montages qui n'ont besoin de rien d'autre. */
#include <avr/io.h>
#include <util/delay.h>

int main(void) {
    DDRB |= (1 << PB1);              /* PB1 en sortie */
    while (1) {
        PORTB |= (1 << PB1);
        _delay_ms(500);
        PORTB &= ~(1 << PB1);
        _delay_ms(500);
    }
}
)";

// Raspberry Pi Pico. Pas de croquis Arduino ici : la carte se programme en C
// sur ses registres, et son bloc SIO est ce qui la rend si particulière —
// une écriture, un cycle, sans passer par le bus des périphériques.
inline const char* kProgrammePico = R"(/* Pi Pico : clignotant sur GP25, la LED de la carte.
   Le bloc SIO pilote les broches directement. GPIO_OE_SET met la broche en
   sortie, GPIO_OUT_XOR l'inverse — écrire dans ces registres n'agit que sur
   les bits à 1, ce qui évite de relire la valeur précédente. */
#define SIO_BASE     0xd0000000u
#define GPIO_OUT_XOR (*(volatile unsigned*)(SIO_BASE + 0x01c))
#define GPIO_OE_SET  (*(volatile unsigned*)(SIO_BASE + 0x024))
#define LED          (1u << 25)

void _start(void) {
    GPIO_OE_SET = LED;
    for (;;) {
        GPIO_OUT_XOR = LED;
        for (volatile int i = 0; i < 400000; i++) { }
    }
}
)";

// STM32F103. Les registres ne se pilotent pas de la même façon : la direction
// se règle par nibbles dans CRL, et BSRR pose ou efface sans lecture.
inline const char* kProgrammeStm32 = R"(/* STM32F103 : clignotant sur PC13, la LED des cartes « Blue Pill ».
   CRH décrit la configuration des broches 8 à 15, quatre bits chacune ;
   BSRR pose un bit par sa moitié basse et l'efface par sa moitié haute. */
#define GPIOC    0x40011000u
#define GPIOC_CRH (*(volatile unsigned*)(GPIOC + 0x04))
#define GPIOC_ODR (*(volatile unsigned*)(GPIOC + 0x0c))

void _start(void) {
    GPIOC_CRH = 0x00300000u;      /* PC13 en sortie, 50 MHz */
    for (;;) {
        GPIOC_ODR ^= (1u << 13);
        for (volatile int i = 0; i < 200000; i++) { }
    }
}
)";

// Tous les exemples, pour les bancs d'essai : ce que le test compile.
struct ProgrammeExemple {
    const char* nom;
    const char* source;
    // La puce pour laquelle ce programme est écrit : c'est elle qui décide de
    // la chaîne de compilation. Un programme ARM passé à avr-g++ échoue, et
    // l'inverse aussi.
    const char* mcu = "atmega328p";
    uint32_t horloge = 16000000;
};

inline std::vector<ProgrammeExemple> tous_les_programmes() {
    return {
        {"kSourceExemple", kSourceExemple},
        {"kProgrammeBouton", kProgrammeBouton},
        {"kProgrammePotentiometre", kProgrammePotentiometre},
        {"kProgrammeTransistor", kProgrammeTransistor},
        {"kProgrammePwm", kProgrammePwm},
        {"kProgrammeEmetteur", kProgrammeEmetteur},
        {"kProgrammeRecepteur", kProgrammeRecepteur},
        {"kProgrammeServo", kProgrammeServo},
        {"kProgrammeMoteur", kProgrammeMoteur},
        {"kProgrammeRegistre", kProgrammeRegistre},
        {"kProgrammeRegistresNu", kProgrammeRegistresNu},
        {"kProgrammeAttiny", kProgrammeAttiny, "attiny85", 8000000},
        {"kProgrammePico", kProgrammePico, "rp2040", 125000000},
        {"kProgrammeStm32", kProgrammeStm32, "stm32f103", 72000000},
    };
}

}  // namespace coeur
