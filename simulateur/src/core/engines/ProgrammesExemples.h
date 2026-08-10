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

#include "core/engines/Microcontroleur.h"
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

// ESP32. Ce programme n'est pas compilable depuis l'application : aucune
// chaîne Xtensa n'est embarquée, et l'ESP-IDF ne se met pas dans une archive
// portable. Il est là pour montrer ce que la puce attend — et un .elf déjà
// compilé se charge sans rien installer.
inline const char* kProgrammeEsp32 = R"(/* ESP32 : clignotant sur GPIO2, la LED des cartes DevKit.
   Le bloc GPIO se pilote par trois registres : ENABLE met la broche en
   sortie, OUT porte son niveau, et l'on bascule par un ou exclusif.

   ATTENTION : cette carte n'est pas compilable depuis l'application. Le
   simulateur embarque son cœur Xtensa, pas la chaîne ESP-IDF. Chargez un
   fichier .elf déjà compilé (Fichier ▸ Charger un firmware). */
#define GPIO_OUT    (*(volatile unsigned*)0x3ff44004)
#define GPIO_ENABLE (*(volatile unsigned*)0x3ff44020)
#define LED         (1u << 2)

void app_main(void) {
    GPIO_ENABLE = LED;
    for (;;) {
        GPIO_OUT ^= LED;
        for (volatile int i = 0; i < 400000; i++) { }
    }
}
)";

// ---------------------------------------------------------------------------
// Analyseur d'impédance embarqué
//
// C'est le projet le plus ambitieux du lot, et le seul où la carte MESURE le
// circuit analogique au lieu de simplement l'allumer. Elle excite un RLC
// série, échantillonne sa réponse, et en tire un spectre — en tension et en
// courant.
//
// Le principe est celui d'un analyseur de réseau, réduit à ce qu'un
// microcontrôleur sait faire :
//
//   1. une broche produit un créneau à la fréquence voulue ;
//   2. le convertisseur échantillonne huit fois par période, EN PHASE avec
//      ce créneau — c'est la boucle elle-même qui produit les deux ;
//   3. une transformée de Fourier discrète à huit points, raie 1, extrait
//      l'amplitude ET la phase de la fondamentale.
//
// Le point 3 n'est pas un raffinement : c'est ce qui rend la mesure juste.
// Un créneau contient ses harmoniques impaires, et à 150 Hz l'harmonique 3
// tombe à 450 Hz, tout près de la résonance — le courant réel y est alors
// autant harmonique 3 que fondamental. Un détecteur de crête mesurerait ce
// mélange et rendrait n'importe quoi. La raie 1 d'une TFD à huit points, elle,
// est orthogonale aux harmoniques 3, 5 et 7 : elles s'annulent exactement.
//
// Avoir la PHASE permet de soustraire deux tensions comme des vecteurs, donc
// de remonter à l'impédance complexe du montage. Sans elle, on ne saurait
// rien faire de deux amplitudes.
// ---------------------------------------------------------------------------
// L'en-tête partagé par toutes les variantes de l'analyseur. C'est lui qui a
// motivé la compilation en plusieurs fichiers : la transformée est la même
// sur les six cartes, et la recopier six fois aurait garanti qu'une copie
// finisse par diverger.
//
// Il ne contient QUE de l'arithmétique — aucun registre, aucune broche. La
// couche matérielle (produire le créneau, lire le convertisseur, attendre
// l'instant) reste dans le programme de chaque puce, parce qu'elle n'a rien
// de commun d'une architecture à l'autre.
inline const char* kAnalyseurCommun = R"SRC(/* Transformee de Fourier discrete a huit points, raie 1.
   Partage par toutes les cartes : voir le programme principal. */
#ifndef ANALYSEUR_H
#define ANALYSEUR_H

/* Huit echantillons par periode, seize periodes moyennees. */
#define ANALYSEUR_N         8
#define ANALYSEUR_PERIODES  16

/* Poids de la raie 1, en virgule fixe sur 256. 181 vaut 256*racine(2)/2.
   Leur somme est nulle : la composante continue est rejetee sans qu'on ait a
   la retrancher, et le milieu d'alimentation des diviseurs de mesure
   disparait tout seul.

   Ces poids sont ORTHOGONAUX aux harmoniques 3, 5 et 7 du creneau
   d'excitation. C'est ce qui rend la mesure juste : a 150 Hz, l'harmonique 3
   tombe pres de la resonance et le courant reel y est autant harmonique 3
   que fondamental. Un detecteur de crete mesurerait ce melange. */
static const int ANALYSEUR_COS[8] = {256, 181, 0, -181, -256, -181, 0, 181};
static const int ANALYSEUR_SIN[8] = {0, 181, 256, 181, 0, -181, -256, -181};

/* Accumule un echantillon. `rang` est sa place dans la periode, 0 a 7. */
static void analyseur_accumuler(long* re, long* im, int rang, long mesure) {
    *re += mesure * (long)ANALYSEUR_COS[rang & 7];
    *im -= mesure * (long)ANALYSEUR_SIN[rang & 7];
}

/* Racine carree entiere, par la methode de Newton sur des entiers.
   Pourquoi pas sqrt() : sur un ATtiny85 la bibliotheque flottante prend
   davantage de place que le programme entier, et sur un Cortex-M compile
   sans bibliotheque standard elle n'existe pas du tout. */
static unsigned long analyseur_racine(unsigned long valeur) {
    unsigned long x, precedent;
    if (valeur == 0) return 0;
    x = valeur;
    if (x > 65535UL) x = 65535UL;
    for (;;) {
        precedent = x;
        x = (x + valeur / x) / 2;
        if (x >= precedent) return precedent;
    }
}

/* Module de la raie, ramene en points de conversion.
   Le facteur 2 fait passer d'une somme ponderee a une amplitude ; 256 defait
   la virgule fixe ; N*PERIODES defait le moyennage. */
static unsigned long analyseur_amplitude(long re, long im) {
    unsigned long a = (unsigned long)(re < 0 ? -re : re);
    unsigned long b = (unsigned long)(im < 0 ? -im : im);
    /* Les sommes tiennent sur 32 bits mais leurs carres non : on divise
       d'abord, on eleve ensuite. La division par 256 est un decalage. */
    a >>= 8;
    b >>= 8;
    return 2UL * analyseur_racine(a * a + b * b)
           / (ANALYSEUR_N * ANALYSEUR_PERIODES);
}

/* Les frequences balayees, en hertz.
   Aucune n'est multiple de 200 Hz : la fenetre de couplage du simulateur dure
   cinq millisecondes, et une excitation commensurable avec elle donne un biais
   systematique qui ne se moyenne pas. Corriger cela a divise l'erreur par
   deux. Aucune non plus ne place son harmonique 3 sur la resonance. */
#define ANALYSEUR_NB_FREQUENCES 9
static const int ANALYSEUR_FREQUENCES[ANALYSEUR_NB_FREQUENCES] =
    {150, 210, 260, 300, 339, 390, 455, 590, 810};

#endif
)SRC";

inline const char* kAnalyseurArduino = R"SRC(/* Analyseur d'impedance : la carte mesure le RLC qu'on lui branche.

   Montage (voir le schema charge avec cet exemple) :

     D8 --[ L1 1 H ]-- M --[ C1 220 nF ]-- S --[ R1 470 ]-- GND

   S est l'image du courant : R1 est un shunt, et la tension a ses bornes vaut
   470 fois le courant. Les deux points de mesure passent par un diviseur a
   trois resistances egales (vers le point, vers +5 V, vers la masse) qui
   ramene le signal au tiers autour du milieu de l'alimentation : sans lui les
   alternances negatives seraient ecretees, et la mesure fausse.

   ATTENTION au condensateur : a la resonance la tension a ses bornes vaut Q
   fois celle d'attaque, soit une quinzaine de volts pour cinq volts en
   entree. Aucune broche n'y touche, mais un condensateur reel doit tenir
   cette tension.

   Resonance attendue : 1/(2*pi*racine(L*C)) = 339 Hz.

   La transformee est dans analyseur.h, partage avec les autres cartes. */

#include "analyseur.h"

const int EXC = 8;              /* la broche qui excite le montage */
const int VOIE_EXC = A1;        /* image de cette meme broche */
const int VOIE_SHUNT = A0;      /* image de la tension aux bornes du shunt */
const long SHUNT = 470;         /* ohms */

/* Excite a la frequence f et releve une voie. Rend la raie 1 de la TFD.
   Le creneau est produit par cette boucle : l'echantillonnage lui est donc
   coherent par construction, sans horloge ni interruption. */
void mesurer(int voie, long f, long* re, long* im) {
    const unsigned long pas = 1000000UL / (f * ANALYSEUR_N);   /* microsecondes */
    unsigned long instant = micros();
    *re = 0;
    *im = 0;

    /* Chauffe : on excite sans rien compter pendant une quarantaine de
       millisecondes. Deux raisons, et les deux comptent.

       La premiere est physique : un circuit resonant met Q/(pi*f0) a
       s'etablir. Mesurer avant, c'est mesurer un transitoire.

       La seconde tient au simulateur : le convertisseur lit la forme d'onde
       de la fenetre de couplage precedente, soit cinq millisecondes plus tot.
       Sans chauffe, les premiers echantillons d'un balayage a 810 Hz
       porteraient encore la frequence precedente. */
    const int chauffe = (int)((f * 40L) / 1000L) + 2;
    for (int p = 0; p < chauffe; p++) {
        for (int k = 0; k < ANALYSEUR_N; k++) {
            while ((long)(micros() - instant) < 0) { }
            digitalWrite(EXC, k < ANALYSEUR_N / 2 ? HIGH : LOW);
            instant += pas;
        }
    }

    for (int p = 0; p < ANALYSEUR_PERIODES; p++) {
        for (int k = 0; k < ANALYSEUR_N; k++) {
            while ((long)(micros() - instant) < 0) { }
            digitalWrite(EXC, k < ANALYSEUR_N / 2 ? HIGH : LOW);
            analyseur_accumuler(re, im, k, analogRead(voie));
            instant += pas;
        }
    }
}

void setup() {
    pinMode(EXC, OUTPUT);
    Serial.begin(9600);
    Serial.println("f(Hz)  U(mV)  I(uA)  Z(ohm)");
}

void loop() {
    for (int rang = 0; rang < ANALYSEUR_NB_FREQUENCES; rang++) {
        const long f = ANALYSEUR_FREQUENCES[rang];

        /* Deux passes : une par voie. Le convertisseur ne sait convertir
           qu'une voie a la fois, et deux conversions ne tiendraient pas dans
           un intervalle d'echantillonnage a 810 Hz. Les deux passes partagent
           la meme reference de phase, puisque le creneau est refait a
           l'identique. */
        long re, im;
        mesurer(VOIE_EXC, f, &re, &im);
        const unsigned long brut_u = analyseur_amplitude(re, im);
        mesurer(VOIE_SHUNT, f, &re, &im);
        const unsigned long brut_i = analyseur_amplitude(re, im);
        digitalWrite(EXC, LOW);

        /* Des points de conversion aux millivolts. Le facteur 3 defait le
           diviseur de mesure ; 5000/1023 est le pas du convertisseur. */
        const unsigned long u_mv = brut_u * 3UL * 5000UL / 1023UL;
        const unsigned long i_mv = brut_i * 3UL * 5000UL / 1023UL;
        /* Le courant, par la loi d'Ohm dans le shunt, en microamperes. */
        const unsigned long i_ua = i_mv * 1000UL / SHUNT;

        Serial.print(f);
        Serial.print("  ");
        Serial.print((long)u_mv);
        Serial.print("  ");
        Serial.print((long)i_ua);
        Serial.print("  ");
        Serial.println(i_ua > 0 ? (long)(u_mv * 1000UL / i_ua) : 999999L);
    }
    Serial.println("--- balayage termine ---");
    delay(1000);
}
)SRC";



// Les deux cartes ARM. Le squelette est le même que celui du croquis Arduino
// — c'est la même mesure —, mais tout ce qui touche au matériel change : pas
// de noyau, pas de micros(), pas d'analogRead. La base de temps est le
// compteur SysTick, présent sur tout Cortex-M ; c'est d'ailleurs lui que le
// noyau Arduino emploie sur ces puces.
inline const char* kAnalyseurPico = R"SRC(/* Pi Pico : analyseur d'impedance, en C sur registres.

   Montage :
     GP2 --[ L1 1 H ]-- M --[ C1 220 nF ]-- S --[ R1 470 ]-- GND
   GP26 (ADC0) lit l'image du shunt, GP27 (ADC1) celle de l'excitation.
   Les deux passent par un diviseur a trois resistances vers 3,3 V et la
   masse, qui ramene le signal au tiers autour du milieu de l'alimentation.

   Attention : 3,3 V ici, pas 5. Le pas du convertisseur en depend, et la
   pleine echelle vaut 4095 points et non 1023.

   Resonance attendue : 339 Hz. */

#include "analyseur.h"

#define SIO           0xd0000000u
#define GPIO_OUT_SET  (*(volatile unsigned*)(SIO + 0x014))
#define GPIO_OUT_CLR  (*(volatile unsigned*)(SIO + 0x018))
#define GPIO_OE_SET   (*(volatile unsigned*)(SIO + 0x024))
#define EXC           (1u << 2)

#define ADC_BASE      0x4004c000u
#define ADC_CS        (*(volatile unsigned*)(ADC_BASE + 0x00))
#define ADC_RESULT    (*(volatile unsigned*)(ADC_BASE + 0x04))

#define UART_DR       (*(volatile unsigned*)0x40034000u)
#define UART_FR       (*(volatile unsigned*)0x40034018u)

#define SYST_CSR      (*(volatile unsigned*)0xe000e010u)
#define SYST_RVR      (*(volatile unsigned*)0xe000e014u)
#define SYST_CVR      (*(volatile unsigned*)0xe000e018u)

#define HORLOGE       125000000u
#define SHUNT         470u

/* Le temps. SysTick est un compteur DECROISSANT sur vingt-quatre bits : on le
   charge au maximum et on lit son complement, ce qui donne un chronometre qui
   monte. Il repasse par zero toutes les 0,134 seconde a 125 MHz ; les
   intervalles mesures ici sont mille fois plus courts. */
static void horloge_demarrer(void) {
    SYST_RVR = 0x00ffffffu;
    SYST_CVR = 0;
    SYST_CSR = 5;                 /* actif, horloge du processeur */
}
static unsigned maintenant(void) { return (0x00ffffffu - SYST_CVR) & 0x00ffffffu; }
/* SysTick ne compte que sur VINGT-QUATRE bits : au-dela il repasse par zero.
   Comparer deux instants comme des entiers de trente-deux bits marche jusqu'au
   premier repassage, puis bloque la boucle d'attente pour toujours. On ramene
   donc l'ecart sur vingt-quatre bits signes avant de le comparer. */
static void attendre_jusque(unsigned cible) {
    for (;;) {
        const int ecart = (int)((maintenant() - cible) << 8) >> 8;
        if (ecart >= 0) return;
    }
}

static void emettre(const char* t) {
    while (*t) { while (UART_FR & (1u << 5)) { } UART_DR = (unsigned)*t++; }
}
static void emettre_nombre(unsigned long v) {
    char tampon[12];
    int rang = 0;
    if (v == 0) { emettre("0"); return; }
    while (v) { tampon[rang++] = (char)('0' + (v % 10)); v /= 10; }
    while (rang) { char c[2]; c[0] = tampon[--rang]; c[1] = 0; emettre(c); }
}

static unsigned lire_voie(unsigned voie) {
    ADC_CS = (1u << 0) | (voie << 12);      /* convertisseur en marche */
    ADC_CS = (1u << 0) | (voie << 12) | (1u << 2);   /* START_ONCE */
    while (!(ADC_CS & (1u << 8))) { }        /* READY */
    return ADC_RESULT & 0x0fff;
}

static void mesurer(unsigned voie, long f, long* re, long* im) {
    /* Ticks d'horloge entre deux echantillons. */
    const unsigned pas = HORLOGE / ((unsigned)f * ANALYSEUR_N);
    unsigned instant = maintenant();
    int p, k;
    const int chauffe = (int)((f * 40L) / 1000L) + 2;
    *re = 0;
    *im = 0;
    for (p = 0; p < chauffe; p++) {
        for (k = 0; k < ANALYSEUR_N; k++) {
            attendre_jusque(instant);
            if (k < ANALYSEUR_N / 2) GPIO_OUT_SET = EXC; else GPIO_OUT_CLR = EXC;
            instant = (instant + pas) & 0x00ffffffu;
        }
    }
    for (p = 0; p < ANALYSEUR_PERIODES; p++) {
        for (k = 0; k < ANALYSEUR_N; k++) {
            attendre_jusque(instant);
            if (k < ANALYSEUR_N / 2) GPIO_OUT_SET = EXC; else GPIO_OUT_CLR = EXC;
            analyseur_accumuler(re, im, k, (long)lire_voie(voie));
            instant = (instant + pas) & 0x00ffffffu;
        }
    }
}

void _start(void) {
    int rang;
    GPIO_OE_SET = EXC;
    horloge_demarrer();
    emettre("f(Hz)  U(mV)  I(uA)  Z(ohm)\n");
    for (;;) {
        for (rang = 0; rang < ANALYSEUR_NB_FREQUENCES; rang++) {
            const long f = ANALYSEUR_FREQUENCES[rang];
            long re, im;
            unsigned long u_mv, i_mv, i_ua;
            mesurer(1, f, &re, &im);              /* ADC1 = GP27, excitation */
            u_mv = analyseur_amplitude(re, im) * 3UL * 3300UL / 4095UL;
            mesurer(0, f, &re, &im);              /* ADC0 = GP26, shunt */
            i_mv = analyseur_amplitude(re, im) * 3UL * 3300UL / 4095UL;
            GPIO_OUT_CLR = EXC;
            i_ua = i_mv * 1000UL / SHUNT;
            emettre_nombre((unsigned long)f); emettre("  ");
            emettre_nombre(u_mv); emettre("  ");
            emettre_nombre(i_ua); emettre("  ");
            emettre_nombre(i_ua ? u_mv * 1000UL / i_ua : 999999UL);
            emettre("\n");
        }
        emettre("--- balayage termine ---\n");
    }
}
)SRC";

inline const char* kAnalyseurStm32 = R"SRC(/* STM32F103 : analyseur d'impedance, en C sur registres.

   Montage :
     PB0 --[ L1 1 H ]-- M --[ C1 220 nF ]-- S --[ R1 470 ]-- GND
   PA0 (ADC voie 0) lit l'image du shunt, PA1 (voie 1) celle de l'excitation.
   Diviseur a trois resistances sur chacun, vers 3,3 V et la masse.

   Sur cette famille la direction d'une broche ne tient pas dans un bit mais
   dans un QUARTET : quatre bits de configuration par broche, dans CRL pour
   les broches 0 a 7. C'est la difference la plus deroutante avec un AVR.

   Resonance attendue : 339 Hz. */

#include "analyseur.h"

#define GPIOB_CRL     (*(volatile unsigned*)0x40010c00u)
#define GPIOB_BSRR    (*(volatile unsigned*)0x40010c10u)
#define ADC1_CR2      (*(volatile unsigned*)0x40012408u)
#define ADC1_SQR3     (*(volatile unsigned*)0x40012434u)
#define ADC1_DR       (*(volatile unsigned*)0x4001244cu)
#define USART1_SR     (*(volatile unsigned*)0x40013800u)
#define USART1_DR     (*(volatile unsigned*)0x40013804u)
#define SYST_CSR      (*(volatile unsigned*)0xe000e010u)
#define SYST_RVR      (*(volatile unsigned*)0xe000e014u)
#define SYST_CVR      (*(volatile unsigned*)0xe000e018u)

#define EXC           (1u << 0)          /* PB0 */
#define HORLOGE       72000000u
#define SHUNT         470u

static void horloge_demarrer(void) {
    SYST_RVR = 0x00ffffffu;
    SYST_CVR = 0;
    SYST_CSR = 5;
}
static unsigned maintenant(void) { return (0x00ffffffu - SYST_CVR) & 0x00ffffffu; }
/* SysTick ne compte que sur VINGT-QUATRE bits : au-dela il repasse par zero.
   Comparer deux instants comme des entiers de trente-deux bits marche jusqu'au
   premier repassage, puis bloque la boucle d'attente pour toujours. On ramene
   donc l'ecart sur vingt-quatre bits signes avant de le comparer. */
static void attendre_jusque(unsigned cible) {
    for (;;) {
        const int ecart = (int)((maintenant() - cible) << 8) >> 8;
        if (ecart >= 0) return;
    }
}

static void emettre(const char* t) {
    while (*t) { while (!(USART1_SR & (1u << 7))) { } USART1_DR = (unsigned)*t++; }
}
static void emettre_nombre(unsigned long v) {
    char tampon[12];
    int rang = 0;
    if (v == 0) { emettre("0"); return; }
    while (v) { tampon[rang++] = (char)('0' + (v % 10)); v /= 10; }
    while (rang) { char c[2]; c[0] = tampon[--rang]; c[1] = 0; emettre(c); }
}

static unsigned lire_voie(unsigned voie) {
    ADC1_SQR3 = voie;                    /* la voie de la premiere mesure */
    ADC1_CR2 = 1u;                       /* ADON */
    ADC1_CR2 = 1u | (1u << 22);          /* SWSTART */
    return ADC1_DR & 0x0fff;
}

static void mesurer(unsigned voie, long f, long* re, long* im) {
    const unsigned pas = HORLOGE / ((unsigned)f * ANALYSEUR_N);
    unsigned instant = maintenant();
    int p, k;
    const int chauffe = (int)((f * 40L) / 1000L) + 2;
    *re = 0;
    *im = 0;
    for (p = 0; p < chauffe; p++) {
        for (k = 0; k < ANALYSEUR_N; k++) {
            attendre_jusque(instant);
            GPIOB_BSRR = (k < ANALYSEUR_N / 2) ? EXC : (EXC << 16);
            instant = (instant + pas) & 0x00ffffffu;
        }
    }
    for (p = 0; p < ANALYSEUR_PERIODES; p++) {
        for (k = 0; k < ANALYSEUR_N; k++) {
            attendre_jusque(instant);
            GPIOB_BSRR = (k < ANALYSEUR_N / 2) ? EXC : (EXC << 16);
            analyseur_accumuler(re, im, k, (long)lire_voie(voie));
            instant = (instant + pas) & 0x00ffffffu;
        }
    }
}

void _start(void) {
    int rang;
    GPIOB_CRL = 0x00000003u;          /* PB0 en sortie, 50 MHz */
    horloge_demarrer();
    emettre("f(Hz)  U(mV)  I(uA)  Z(ohm)\n");
    for (;;) {
        for (rang = 0; rang < ANALYSEUR_NB_FREQUENCES; rang++) {
            const long f = ANALYSEUR_FREQUENCES[rang];
            long re, im;
            unsigned long u_mv, i_mv, i_ua;
            mesurer(1, f, &re, &im);
            u_mv = analyseur_amplitude(re, im) * 3UL * 3300UL / 4095UL;
            mesurer(0, f, &re, &im);
            i_mv = analyseur_amplitude(re, im) * 3UL * 3300UL / 4095UL;
            GPIOB_BSRR = EXC << 16;
            i_ua = i_mv * 1000UL / SHUNT;
            emettre_nombre((unsigned long)f); emettre("  ");
            emettre_nombre(u_mv); emettre("  ");
            emettre_nombre(i_ua); emettre("  ");
            emettre_nombre(i_ua ? u_mv * 1000UL / i_ua : 999999UL);
            emettre("\n");
        }
        emettre("--- balayage termine ---\n");
    }
}
)SRC";

// Le programme de l'analyseur pour une puce donnée, en DEUX fichiers : le
// principal, et l'en-tête partagé. C'est le premier exemple du simulateur qui
// s'écrive ainsi, et c'est ce pour quoi la compilation multi-fichiers existe.
//
// Rend un programme vide pour une puce dont l'analyseur n'existe pas :
// l'appelant sait alors qu'il n'y a rien à proposer.
inline Programme programme_analyseur(const std::string& mcu) {
    const char* principal = nullptr;
    if (mcu == "atmega328p" || mcu == "atmega2560")
        principal = kAnalyseurArduino;
    else if (mcu == "rp2040")
        principal = kAnalyseurPico;
    // STM32 : le programme existe plus bas et se compile, mais il se BLOQUE
    // dans sa première mesure. Le Pico, lui, achève son balayage depuis que
    // la retenue d'ADC/SBC est corrigée — le STM32 a donc autre chose, non
    // identifié. Le proposer dans cet état ferait perdre plus de temps qu'une
    // absence.
    if (!principal) return {};
    return Programme{{nom_principal(mcu), principal},
                     {"analyseur.h", kAnalyseurCommun}};
}

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
        {"kAnalyseurArduino", kAnalyseurArduino},
        {"kProgrammeRegistre", kProgrammeRegistre},
        {"kProgrammeRegistresNu", kProgrammeRegistresNu},
        {"kProgrammeAttiny", kProgrammeAttiny, "attiny85", 8000000},
        {"kProgrammePico", kProgrammePico, "rp2040", 125000000},
        {"kProgrammeStm32", kProgrammeStm32, "stm32f103", 72000000},
    };
}

}  // namespace coeur
