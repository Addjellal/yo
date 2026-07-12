// thermostat.ino — corrigé TD 03, exercice 3
// Thermostat à hystérésis en machine d'états, avec état DÉFAUT (capteur HS).
// Câblage : DHT22 sur D2, relais (ou LED) sur D7, potentiomètre consigne A0.
// Bibliothèque requise : "DHT sensor library" (Adafruit).
// Testable sur Wokwi (le DHT22 y est simulable).

#include <DHT.h>

DHT dht(2, DHT22);
const uint8_t RELAIS = 7, POT_CONSIGNE = A0;
const float HYSTERESIS = 0.5f;

enum class Etat : uint8_t { Repos, Chauffe, Defaut };
Etat etat = Etat::Repos;

float    consigne = 20.0f, temperature = NAN;
uint8_t  echecs_lecture = 0;
uint32_t derniere_lecture = 0;

void setup() {
    pinMode(RELAIS, OUTPUT);
    digitalWrite(RELAIS, LOW);          // état SÛR au démarrage
    dht.begin();
    Serial.begin(115200);
}

void loop() {
    uint32_t maintenant = millis();

    // Consigne : 10..30 °C selon le potentiomètre
    consigne = 10.0f + analogRead(POT_CONSIGNE) * (20.0f / 1023.0f);

    // Le DHT22 se lit au plus toutes les 2 s
    if (maintenant - derniere_lecture >= 2000) {
        derniere_lecture = maintenant;
        float t = dht.readTemperature();
        if (isnan(t)) {
            if (++echecs_lecture >= 3) etat = Etat::Defaut;   // 3 échecs = panne
        } else {
            echecs_lecture = 0;
            temperature = t;
        }
        Serial.print(F("T="));       Serial.print(temperature);
        Serial.print(F(" consigne=")); Serial.print(consigne);
        Serial.print(F(" etat="));   Serial.println((uint8_t)etat);
    }

    switch (etat) {
    case Etat::Repos:
        digitalWrite(RELAIS, LOW);
        // On enclenche SOUS consigne - hystérésis (bande morte)
        if (!isnan(temperature) && temperature < consigne - HYSTERESIS)
            etat = Etat::Chauffe;
        break;

    case Etat::Chauffe:
        digitalWrite(RELAIS, HIGH);
        // On coupe AU-DESSUS de consigne + hystérésis
        if (isnan(temperature) || temperature > consigne + HYSTERESIS)
            etat = Etat::Repos;
        break;

    case Etat::Defaut:
        digitalWrite(RELAIS, LOW);      // panne capteur -> chauffage COUPÉ
        if (echecs_lecture == 0 && !isnan(temperature)) etat = Etat::Repos;
        break;
    }
}
