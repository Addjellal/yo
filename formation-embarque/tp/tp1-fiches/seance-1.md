# TP 1 — Fiche de séance 1 : le socle non bloquant (2 h)

## En-tête pédagogique

| | |
|---|---|
| **Objectifs** | À la fin de la séance tu sais : câbler DHT22/LED/potentiomètre ; écrire des tâches périodiques avec `millis()` ; gérer une panne de capteur ; appliquer une hystérésis |
| **Prérequis** | Module 03 §1-5 lus ; TD 03 exercice 3 fait |
| **Matériel** | Uno/Nano, DHT22, LED + 220 Ω, potentiomètre 10 kΩ, breadboard, 6 fils — ou projet Wokwi « Arduino Uno » |
| **Livrable** | Un sketch qui mesure/affiche/alerte, robuste au débranchement du capteur, commité sur Git |

## Déroulé minuté

### 0:00-0:15 — Câblage et vérification

| Composant | Broche composant | Broche Arduino |
|---|---|---|
| DHT22 | VCC / DATA / GND | 5V / D2 / GND (pull-up 10 kΩ entre DATA et VCC si capteur nu) |
| LED rouge | anode (patte longue) via 220 Ω | D8 ; cathode → GND |
| Potentiomètre | extrémités / curseur | 5V et GND / A0 |

Vérifie AVANT d'alimenter : aucune LED sans résistance, pas de fil 5V↔GND
direct. Puis téléverse le sketch vide (`setup`/`loop` vides) pour valider la
liaison carte↔PC.

### 0:15-0:30 — Premier contact avec chaque périphérique, séparément

Trois micro-tests de 5 min chacun (c'est une méthode, pas une perte de
temps : **on ne débogue jamais deux inconnues à la fois**) :

1. `Serial.println(analogRead(A0));` + `delay(200)` → tourne le
   potentiomètre : la valeur balaie ~0..1023 ?
2. LED : `digitalWrite(8, HIGH)` → elle s'allume ?
3. DHT : exemple `DHTtester` de la bibliothèque → valeurs plausibles ?

### 0:30-1:15 — Le squelette à tâches périodiques

Écris (sans copier-coller — tape-le) :

```cpp
#include <DHT.h>
DHT dht(2, DHT22);

uint32_t t_mesure = 0, t_affiche = 0;
float temperature = NAN, humidite = NAN;

void setup() {
    Serial.begin(115200);
    dht.begin();
    pinMode(8, OUTPUT);
}

void loop() {
    uint32_t now = millis();

    if (now - t_mesure >= 2000) {          // tâche 1 : mesurer (2 s)
        t_mesure = now;
        float t = dht.readTemperature(), h = dht.readHumidity();
        if (!isnan(t)) temperature = t;    // on ne garde QUE les lectures valides
        if (!isnan(h)) humidite = h;
    }

    if (now - t_affiche >= 1000) {         // tâche 2 : afficher (1 s)
        t_affiche = now;
        Serial.print(F("T=")); Serial.print(temperature);
        Serial.print(F("C H=")); Serial.print(humidite); Serial.println(F("%"));
    }
}
```

Questions à te poser (réponds par écrit dans ton journal) :
- Pourquoi `uint32_t` et pas `int` pour `t_mesure` ? *(int = 16 bits sur Uno)*
- Pourquoi `now - t_mesure >= 2000` et pas `now >= t_mesure + 2000` ?
  *(débordement de millis() à 49 j : la soustraction reste juste)*
- Pourquoi `F("T=")` ? *(chaîne en flash : les 2 Ko de RAM sont précieux)*

**✅ Point de contrôle 1 (à 1:15)** : débranche la broche DATA du DHT **en
cours de fonctionnement**. Attendu : l'affichage continue avec les
dernières valeurs valides, pas de gel ni de `nan` en boucle. C'est la
conséquence directe du `if (!isnan(t))`.

### 1:15-1:50 — Consigne et hystérésis

Ajoute :

```cpp
const float HYST = 0.5f;
bool alerte = false;

// dans loop(), dans la tâche d'affichage par exemple :
float consigne = 10.0f + analogRead(A0) * (30.0f / 1023.0f);   // 10..40 °C

if (!alerte && temperature > consigne + HYST) alerte = true;   // bande morte
if (alerte  && temperature < consigne - HYST) alerte = false;
digitalWrite(8, alerte);
```

Test : règle la consigne juste au-dessus de la température ambiante, souffle
sur le capteur. **✅ Point de contrôle 2** : la LED bascule franchement,
sans clignoter autour du seuil. Puis mets `HYST = 0.0f` et re-observe :
tu VOIS maintenant à quoi sert l'hystérésis — remets 0,5.

### 1:50-2:00 — Commit et journal

```bash
git add . && git commit -m "TP1 seance 1 : socle non bloquant + hysteresis"
```

Journal de bord (3 lignes minimum) : ce qui a marché du premier coup, ce
qui a résisté, ce que tu as compris.

## Erreurs fréquentes de cette séance

| Symptôme | Cause probable | Remède |
|---|---|---|
| `nan` en permanence | DATA sur le mauvais pin, pull-up absente, lecture < 2 s d'intervalle | vérifier câblage, espacer les lectures |
| Valeurs A0 qui « flottent » | curseur du potentiomètre non branché sur A0 | relire le brochage |
| LED toujours éteinte | LED à l'envers (polarité) ou résistance vers le mauvais rail | inverser la LED |
| L'affichage se fige | un `delay()` s'est glissé quelque part | interdit hors setup ! |
| Caractères illisibles au moniteur | vitesse ≠ 115200 dans le moniteur série | aligner les deux |

## Travail à la maison (30 min)

Ajoute une **troisième tâche périodique** (500 ms) qui fait clignoter la
LED intégrée (D13) — un « battement de cœur » qui prouve que la boucle
n'est jamais bloquée. Il te faudra une deuxième variable d'horodatage :
constate que les trois périodes cohabitent sans s'influencer.

➡️ Fiche suivante : **[Séance 2 — OLED et architecture](seance-2.md)**
