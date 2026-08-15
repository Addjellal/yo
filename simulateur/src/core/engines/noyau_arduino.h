// Noyau Arduino minimal, embarqué dans l'exécutable.
//
// Les travaux pratiques de la formation sont écrits en Arduino : pinMode,
// digitalWrite, millis, Serial. Sans ces fonctions, il faudrait tout
// réécrire au niveau des registres pour l'essayer dans le simulateur — ce
// qui n'est pas ce qu'on demande à l'étudiant.
//
// Ce fichier est écrit sur disque au moment de compiler, puis passé à
// avr-g++ avec le programme. L'application reste donc autonome : rien à
// installer, aucun chemin à configurer.
//
// Ce n'est pas le noyau Arduino officiel. C'est une réimplémentation des
// fonctions les plus utilisées, au comportement identique sur un
// ATmega328P. Ce qu'il ne couvre pas est signalé dans le README.
#pragma once

namespace coeur {

// En-tête vu par le programme de l'utilisateur.
inline const char* kArduinoEnTete = R"ARD(
#ifndef ARDUINO_H
#define ARDUINO_H
#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define HIGH 1
#define LOW  0
#define INPUT        0
#define OUTPUT       1
#define INPUT_PULLUP 2
/* A0 vaut 14 sur un Uno et 54 sur un Mega : ce n'est pas un décalage
   arbitraire, c'est que le Mega a cinquante-quatre broches numériques
   avant lui. */
#if defined(__AVR_ATmega2560__) || defined(__AVR_ATmega1280__)
#define kPremiereAnalogique 54
#else
#define kPremiereAnalogique 14
#endif
#define A0 (kPremiereAnalogique + 0)
#define A1 (kPremiereAnalogique + 1)
#define A2 (kPremiereAnalogique + 2)
#define A3 (kPremiereAnalogique + 3)
#define A4 (kPremiereAnalogique + 4)
#define A5 (kPremiereAnalogique + 5)
/* A6 et A7 existent sur le Nano et la Pro Mini comme entrées de
   convertisseur, et sur le Mega comme entrées ordinaires. */
#define A6 (kPremiereAnalogique + 6)
#define A7 (kPremiereAnalogique + 7)
#if defined(__AVR_ATmega2560__) || defined(__AVR_ATmega1280__)
#define A8  62
#define A9  63
#define A10 64
#define A11 65
#define A12 66
#define A13 67
#define A14 68
#define A15 69
#endif
#define PI 3.1415926535897932384626433832795
#define DEC 10
#define HEX 16
#define BIN 2

typedef bool boolean;
typedef uint8_t byte;

void pinMode(uint8_t broche, uint8_t mode);
void digitalWrite(uint8_t broche, uint8_t valeur);
int  digitalRead(uint8_t broche);
int  analogRead(uint8_t broche);
void analogWrite(uint8_t broche, int valeur);
unsigned long millis(void);
unsigned long micros(void);
void delay(unsigned long ms);
void delayMicroseconds(unsigned int us);
unsigned long pulseIn(uint8_t broche, uint8_t etat);
unsigned long pulseIn(uint8_t broche, uint8_t etat, unsigned long delai_max);

long map(long x, long e1, long e2, long s1, long s2);
long random(long maxi);
long random(long mini, long maxi);
void randomSeed(unsigned long graine);

#ifndef constrain
#define constrain(x, bas, haut) ((x)<(bas)?(bas):((x)>(haut)?(haut):(x)))
#endif
#ifndef min
#define min(a, b) ((a)<(b)?(a):(b))
#endif
#ifndef max
#define max(a, b) ((a)>(b)?(a):(b))
#endif
#ifndef abs
#define abs(x) ((x)>0?(x):-(x))
#endif
#define bitRead(v, b)   (((v) >> (b)) & 1)
#define bitSet(v, b)    ((v) |= (1UL << (b)))
#define bitClear(v, b)  ((v) &= ~(1UL << (b)))
#define bitWrite(v, b, x) ((x) ? bitSet(v, b) : bitClear(v, b))

class SerieArduino {
public:
    void begin(unsigned long bauds);
    void end(void);
    int  available(void);
    int  read(void);
    size_t write(uint8_t octet);
    size_t print(const char* texte);
    size_t print(char c);
    size_t print(int valeur, int base = DEC);
    size_t print(unsigned int valeur, int base = DEC);
    size_t print(long valeur, int base = DEC);
    size_t print(unsigned long valeur, int base = DEC);
    size_t print(double valeur, int decimales = 2);
    size_t println(void);
    size_t println(const char* texte);
    size_t println(char c);
    size_t println(int valeur, int base = DEC);
    size_t println(unsigned int valeur, int base = DEC);
    size_t println(long valeur, int base = DEC);
    size_t println(unsigned long valeur, int base = DEC);
    size_t println(double valeur, int decimales = 2);
    void flush(void);
    operator bool() { return true; }
};
extern SerieArduino Serial;

void setup(void);
void loop(void);
#endif
)ARD";

// Corps du noyau : compilé avec le programme de l'utilisateur.
inline const char* kArduinoCorps = R"ARD(
#include "Arduino.h"

// --- correspondance broche Arduino -> port et bit ---------------------------
//
// Sur un ATmega328P elle est presque régulière : trois ports d'affilée. Sur un
// Mega elle ne l'est pas du tout — D0 est sur le port E, D22 sur le port A,
// D42 sur le port L. C'est le fabricant de la carte qui en a décidé ainsi ;
// une table est la seule description honnête, et elle vit en flash pour ne
// pas manger les huit kilo-octets de mémoire vive.
#if defined(__AVR_ATmega2560__) || defined(__AVR_ATmega1280__)

#include <avr/pgmspace.h>

static const uint8_t kPortDeBroche[] PROGMEM = {
    'E','E','E','E','G','E','H','H', 'H','H','B','B','B','B',      /* D0..D13 */
    'J','J','H','H','D','D','D','D',                               /* D14..D21 */
    'A','A','A','A','A','A','A','A',                               /* D22..D29 */
    'C','C','C','C','C','C','C','C',                               /* D30..D37 */
    'D','G','G','G',                                               /* D38..D41 */
    'L','L','L','L','L','L','L','L',                               /* D42..D49 */
    'B','B','B','B',                                               /* D50..D53 */
    'F','F','F','F','F','F','F','F',                               /* A0..A7   */
    'K','K','K','K','K','K','K','K'};                              /* A8..A15  */
static const uint8_t kBitDeBroche[] PROGMEM = {
    0,1,4,5,5,3,3,4, 5,6,4,5,6,7,
    1,0,1,0,3,2,1,0,
    0,1,2,3,4,5,6,7,
    7,6,5,4,3,2,1,0,
    7,2,1,0,
    7,6,5,4,3,2,1,0,
    3,2,1,0,
    0,1,2,3,4,5,6,7,
    0,1,2,3,4,5,6,7};

static inline uint8_t lettre_de(uint8_t broche) {
    if (broche >= sizeof(kPortDeBroche)) return 'B';
    return pgm_read_byte(&kPortDeBroche[broche]);
}
static inline volatile uint8_t* registre_port(uint8_t broche) {
    switch (lettre_de(broche)) {
        case 'A': return &PORTA;
        case 'B': return &PORTB;
        case 'C': return &PORTC;
        case 'D': return &PORTD;
        case 'E': return &PORTE;
        case 'F': return &PORTF;
        case 'G': return &PORTG;
        case 'H': return &PORTH;
        case 'J': return &PORTJ;
        case 'K': return &PORTK;
        default:  return &PORTL;
    }
}
static inline volatile uint8_t* registre_ddr(uint8_t broche) {
    switch (lettre_de(broche)) {
        case 'A': return &DDRA;
        case 'B': return &DDRB;
        case 'C': return &DDRC;
        case 'D': return &DDRD;
        case 'E': return &DDRE;
        case 'F': return &DDRF;
        case 'G': return &DDRG;
        case 'H': return &DDRH;
        case 'J': return &DDRJ;
        case 'K': return &DDRK;
        default:  return &DDRL;
    }
}
static inline volatile uint8_t* registre_pin(uint8_t broche) {
    switch (lettre_de(broche)) {
        case 'A': return &PINA;
        case 'B': return &PINB;
        case 'C': return &PINC;
        case 'D': return &PIND;
        case 'E': return &PINE;
        case 'F': return &PINF;
        case 'G': return &PING;
        case 'H': return &PINH;
        case 'J': return &PINJ;
        case 'K': return &PINK;
        default:  return &PINL;
    }
}
static inline uint8_t bit_de(uint8_t broche) {
    if (broche >= sizeof(kBitDeBroche)) return 0;
    return pgm_read_byte(&kBitDeBroche[broche]);
}
/* La dernière broche de la carte : au-delà, il n'y a rien à piloter. */
#define kDerniereBroche 69

#else

static inline volatile uint8_t* registre_port(uint8_t broche) {
    if (broche < 8)  return &PORTD;
    if (broche < 14) return &PORTB;
    return &PORTC;
}
static inline volatile uint8_t* registre_ddr(uint8_t broche) {
    if (broche < 8)  return &DDRD;
    if (broche < 14) return &DDRB;
    return &DDRC;
}
static inline volatile uint8_t* registre_pin(uint8_t broche) {
    if (broche < 8)  return &PIND;
    if (broche < 14) return &PINB;
    return &PINC;
}
static inline uint8_t bit_de(uint8_t broche) {
    if (broche < 8)  return broche;
    if (broche < 14) return broche - 8;
    return broche - 14;
}
/* Vingt-deux broches sur un Uno : D0..D13 puis A0..A7. */
#define kDerniereBroche 21

#endif

// --- horloge : Timer0 en débordement, comme le vrai noyau Arduino ---------
//
// Prescaler 64 : un débordement tous les 256 x 64 = 16384 cycles, soit
// 1,024 ms à 16 MHz. Les 0,024 ms de trop sont accumulés en fractions, sinon
// millis() dériverait de 2,4 % — visible dès la première minute.
#define CYCLES_PAR_DEBORDEMENT (64 * 256)
#define MICROS_PAR_DEBORDEMENT ((CYCLES_PAR_DEBORDEMENT * 1000L) / (F_CPU / 1000L))
#define MILLIS_ENTIERS (MICROS_PAR_DEBORDEMENT / 1000)
#define FRACTION_PAR_DEBORDEMENT ((MICROS_PAR_DEBORDEMENT % 1000) >> 3)
#define FRACTION_MAX (1000 >> 3)

static volatile unsigned long g_millis = 0;
static volatile unsigned long g_debordements = 0;
static volatile unsigned char g_fraction = 0;
static bool g_horloge_prete = false;

ISR(TIMER0_OVF_vect) {
    unsigned long m = g_millis;
    unsigned char f = g_fraction;
    m += MILLIS_ENTIERS;
    f += FRACTION_PAR_DEBORDEMENT;
    if (f >= FRACTION_MAX) { f -= FRACTION_MAX; m += 1; }
    g_fraction = f;
    g_millis = m;
    g_debordements++;
}

static void demarrer_horloge(void) {
    if (g_horloge_prete) return;
    g_horloge_prete = true;
    // PWM rapide sur Timer0 : c'est ce que fait Arduino, et cela permet
    // analogWrite sur D5 et D6 sans changer la base de temps.
    TCCR0A = (1 << WGM01) | (1 << WGM00);
    TCCR0B = (1 << CS01) | (1 << CS00);          // prescaler 64
    TIMSK0 |= (1 << TOIE0);
    sei();
}

unsigned long millis(void) {
    unsigned long m;
    uint8_t sreg = SREG;
    cli();
    m = g_millis;
    SREG = sreg;
    return m;
}

unsigned long micros(void) {
    unsigned long m;
    uint8_t compte;
    uint8_t sreg = SREG;
    cli();
    m = g_debordements;
    compte = TCNT0;
    if ((TIFR0 & (1 << TOV0)) && compte < 255) m++;
    SREG = sreg;
    return ((m << 8) + compte) * (64 / (F_CPU / 1000000L));
}

void delay(unsigned long ms) {
    const unsigned long depart = millis();
    while (millis() - depart < ms) { }
}

void delayMicroseconds(unsigned int us) {
    const unsigned long depart = micros();
    while (micros() - depart < us) { }
}

/* Largeur d'une impulsion, en microsecondes. 0 si elle n'arrive pas.
 *
 * C'est la fonction du télémètre à ultrasons, et le cours l'écrit telle
 * quelle : « long duree = pulseIn(ECHO, HIGH); ». Elle manquait au noyau,
 * si bien que le code du cours ne compilait pas — alors que le composant
 * `telemetre_ultrason` produit son écho daté et qu'il est vérifié à ±0,3 ms.
 *
 * Trois attentes, comme dans l'implémentation d'Arduino : la fin d'une
 * impulsion déjà commencée (sans quoi on mesurerait un reste), le front qui
 * ouvre la nôtre, puis le front qui la ferme. Chacune est bornée par le même
 * délai : une broche muette ne doit pas bloquer le programme pour toujours.
 *
 * Écart assumé avec l'AVR réel : Arduino compte des passages de boucle
 * calibrés, ici on lit `micros()`. La résolution est donc celle du timer 0,
 * soit 4 µs à 16 MHz — largement suffisante pour un écho de 5 800 µs, et
 * l'erreur qui en résulte (0,07 %) est bien inférieure à celle du couplage
 * analogique. */
unsigned long pulseIn(uint8_t broche, uint8_t etat, unsigned long delai_max) {
    const unsigned long debut = micros();
    /* Attendre la fin d'une impulsion en cours. */
    while (digitalRead(broche) == etat)
        if (micros() - debut > delai_max) return 0;
    /* Attendre le front qui commence la nôtre. */
    while (digitalRead(broche) != etat)
        if (micros() - debut > delai_max) return 0;
    const unsigned long montee = micros();
    /* Et celui qui la termine. */
    while (digitalRead(broche) == etat)
        if (micros() - debut > delai_max) return 0;
    return micros() - montee;
}

unsigned long pulseIn(uint8_t broche, uint8_t etat) {
    return pulseIn(broche, etat, 1000000UL);   /* une seconde, comme Arduino */
}

// --- entrées et sorties tout ou rien -------------------------------------
void pinMode(uint8_t broche, uint8_t mode) {
    if (broche > kDerniereBroche) return;
    volatile uint8_t* ddr = registre_ddr(broche);
    volatile uint8_t* port = registre_port(broche);
    const uint8_t masque = 1 << bit_de(broche);
    if (mode == OUTPUT) {
        *ddr |= masque;
    } else {
        *ddr &= ~masque;
        if (mode == INPUT_PULLUP) *port |= masque;
        else *port &= ~masque;
    }
}

void digitalWrite(uint8_t broche, uint8_t valeur) {
    if (broche > kDerniereBroche) return;
    volatile uint8_t* port = registre_port(broche);
    const uint8_t masque = 1 << bit_de(broche);
    if (valeur) *port |= masque;
    else *port &= ~masque;
}

int digitalRead(uint8_t broche) {
    if (broche > kDerniereBroche) return LOW;
    return (*registre_pin(broche) & (1 << bit_de(broche))) ? HIGH : LOW;
}

// --- conversion analogique ------------------------------------------------
int analogRead(uint8_t broche) {
    const uint8_t canal = (broche >= kPremiereAnalogique)
                              ? (broche - kPremiereAnalogique)
                              : broche;
#if defined(__AVR_ATmega2560__) || defined(__AVR_ATmega1280__)
    if (canal > 15) return 0;
    /* Les voies 8 à 15 se choisissent avec MUX5, qui vit dans ADCSRB : sans
       lui, A8 rendrait la tension de A0 sans le dire. */
    if (canal >= 8) ADCSRB |= (1 << MUX5);
    else            ADCSRB &= ~(1 << MUX5);
#else
    if (canal > 7) return 0;
#endif
    ADMUX = (1 << REFS0) | (canal & 0x07);            // référence AVcc
    ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
    ADCSRA |= (1 << ADSC);
    while (ADCSRA & (1 << ADSC)) { }
    return ADC;
}

// --- PWM ------------------------------------------------------------------
void analogWrite(uint8_t broche, int valeur) {
    pinMode(broche, OUTPUT);
    if (valeur <= 0)   { digitalWrite(broche, LOW);  return; }
    if (valeur >= 255) { digitalWrite(broche, HIGH); return; }

    switch (broche) {
        case 6:  TCCR0A |= (1 << COM0A1); OCR0A = valeur; break;
        case 5:  TCCR0A |= (1 << COM0B1); OCR0B = valeur; break;
        case 9:  TCCR1A |= (1 << COM1A1) | (1 << WGM10);
                 TCCR1B = (1 << WGM12) | (1 << CS11) | (1 << CS10);
                 OCR1A = valeur; break;
        case 10: TCCR1A |= (1 << COM1B1) | (1 << WGM10);
                 TCCR1B = (1 << WGM12) | (1 << CS11) | (1 << CS10);
                 OCR1B = valeur; break;
        case 11: TCCR2A |= (1 << COM2A1) | (1 << WGM21) | (1 << WGM20);
                 TCCR2B = (1 << CS22);
                 OCR2A = valeur; break;
        case 3:  TCCR2A |= (1 << COM2B1) | (1 << WGM21) | (1 << WGM20);
                 TCCR2B = (1 << CS22);
                 OCR2B = valeur; break;
        default: digitalWrite(broche, valeur > 127 ? HIGH : LOW); break;
    }
}

// --- utilitaires ----------------------------------------------------------
long map(long x, long e1, long e2, long s1, long s2) {
    if (e2 == e1) return s1;
    return (x - e1) * (s2 - s1) / (e2 - e1) + s1;
}

static unsigned long g_graine = 1;
void randomSeed(unsigned long graine) { if (graine) g_graine = graine; }
static long tirage(void) {
    g_graine = g_graine * 1103515245UL + 12345UL;
    return (long)((g_graine >> 16) & 0x7FFF);
}
long random(long maxi) { return maxi <= 0 ? 0 : tirage() % maxi; }
long random(long mini, long maxi) {
    return maxi <= mini ? mini : mini + tirage() % (maxi - mini);
}

// --- liaison série --------------------------------------------------------
SerieArduino Serial;

void SerieArduino::begin(unsigned long bauds) {
    const uint16_t diviseur = (F_CPU / 8 / bauds - 1) / 2;
    UBRR0H = (uint8_t)(diviseur >> 8);
    UBRR0L = (uint8_t)diviseur;
    UCSR0B = (1 << RXEN0) | (1 << TXEN0);
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);          // 8 bits, 1 stop
}
void SerieArduino::end(void) { UCSR0B = 0; }
void SerieArduino::flush(void) { while (!(UCSR0A & (1 << UDRE0))) { } }
int SerieArduino::available(void) { return (UCSR0A & (1 << RXC0)) ? 1 : 0; }
int SerieArduino::read(void) {
    if (!(UCSR0A & (1 << RXC0))) return -1;
    return UDR0;
}
size_t SerieArduino::write(uint8_t octet) {
    while (!(UCSR0A & (1 << UDRE0))) { }
    UDR0 = octet;
    return 1;
}
size_t SerieArduino::print(const char* texte) {
    size_t n = 0;
    while (texte && *texte) n += write((uint8_t)*texte++);
    return n;
}
size_t SerieArduino::print(char c) { return write((uint8_t)c); }
size_t SerieArduino::print(long valeur, int base) {
    char tampon[34];
    ltoa(valeur, tampon, base < 2 ? 10 : base);
    return print(tampon);
}
size_t SerieArduino::print(unsigned long valeur, int base) {
    char tampon[34];
    ultoa(valeur, tampon, base < 2 ? 10 : base);
    return print(tampon);
}
size_t SerieArduino::print(int valeur, int base) { return print((long)valeur, base); }
size_t SerieArduino::print(unsigned int valeur, int base) {
    return print((unsigned long)valeur, base);
}
size_t SerieArduino::print(double valeur, int decimales) {
    char tampon[24];
    dtostrf(valeur, 1, decimales, tampon);
    return print(tampon);
}
size_t SerieArduino::println(void) { return print("\r\n"); }
size_t SerieArduino::println(const char* texte) { return print(texte) + println(); }
size_t SerieArduino::println(char c) { return print(c) + println(); }
size_t SerieArduino::println(int v, int b) { return print(v, b) + println(); }
size_t SerieArduino::println(unsigned int v, int b) { return print(v, b) + println(); }
size_t SerieArduino::println(long v, int b) { return print(v, b) + println(); }
size_t SerieArduino::println(unsigned long v, int b) { return print(v, b) + println(); }
size_t SerieArduino::println(double v, int d) { return print(v, d) + println(); }

// Point d'entrée « faible » : un programme qui définit son propre main()
// — comme les exemples écrits au niveau des registres — l'emporte sur
// celui-ci sans conflit à l'édition de liens.
__attribute__((weak)) int main(void) {
    demarrer_horloge();
    setup();
    for (;;) loop();
    return 0;
}

// De même pour setup() et loop() : un programme qui n'en a pas reste
// compilable, ce qui évite un message d'erreur incompréhensible.
__attribute__((weak)) void setup(void) { }
__attribute__((weak)) void loop(void) { }
)ARD";

}  // namespace coeur
