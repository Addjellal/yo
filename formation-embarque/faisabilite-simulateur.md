# Peut-on faire les TP et les projets dans le simulateur ?

Réponse courte : **non, pas tous — et ce n'était pas le but.** Le simulateur
maison couvre la partie Arduino/électronique. Les quatre autres TP portent sur
des technologies qui n'ont rien à voir avec un simulateur de circuit : un FPGA,
deux automates programmables, un microcontrôleur ARM.

Ce document dit précisément ce qui passe, ce qui ne passe pas, et pourquoi.
Chaque « oui » a été vérifié en exécutant réellement le montage — pas déduit
d'une liste de composants.

---

## Le tableau

| Travail | Dans le simulateur maison ? | Sinon, avec quoi |
|---|---|---|
| **Épreuve pratique Arduino** | ✅ **entièrement** | — |
| Mini-TP Arduino | ✅ entièrement | — |
| **TP 1** — Station météo, séance 1 | ✅ le socle non bloquant | — |
| TP 1 — séances 2 à 4 | ❌ DHT22, écran OLED, carte SD, ESP32 | [Wokwi](https://wokwi.com) |
| Montages à **servomoteur** | ✅ angle décodé de l'impulsion | — |
| Montages à **moteur** (CC, pas à pas, asynchrone) | ✅ avec inductance et inertie | — |
| Montages à **capteur analogique** (accéléromètre, gaz, sol, pH, courant) | ✅ | — |
| **Télémètre à ultrasons**, **codeur incrémental** | ✅ signal daté | — |
| **TP 2** — UART en VHDL | ❌ hors sujet | GHDL + GTKWave |
| **TP 3** — Remplissage Siemens | ❌ hors sujet | TIA Portal + PLCSIM |
| **TP 4** — Cuve Schneider | ❌ hors sujet | EcoStruxure + simulateur M221 |
| **TP 5** — STM32 + FreeRTOS | ❌ cœur ARM | Nucleo, ou Renode / QEMU |
| Projets finaux | ⚠️ partiellement | Wokwi pour I²C, SPI, RTC |

Soit, en volume : **une épreuve pratique sur sept**, **un mini-TP sur huit**, et
**une séance de TP sur dix-huit** se font intégralement dans le simulateur
maison. Le reste garde les outils que le cours recommandait déjà.

---

## Ce qui a été vérifié, et comment

Le point qui décidait de tout n'était pas le catalogue de composants : c'était
le **langage**. Les TP sont écrits en Arduino (`pinMode`, `millis()`,
`Serial`), alors que le simulateur ne compilait que du C nu au niveau des
registres. Un étudiant aurait dû tout réécrire — ce qui n'est pas ce qu'on lui
demande.

Un noyau Arduino minimal a donc été ajouté au simulateur. Il est embarqué dans
l'exécutable et écrit sur disque au moment de compiler : rien à installer.

Le sujet de l'**épreuve pratique Arduino** — minuterie d'éclairage, bouton
anti-rebondi, potentiomètre, PWM, machine à états, aucun `delay()` — a été
compilé **sans modification** et exécuté. Ce qui a été contrôlé :

- `setup()` et `loop()` s'exécutent, `Serial` émet ;
- `millis()` avance à la bonne cadence — le programme annonce `t=1` puis `t=2`
  au bon moment, une horloge fausse de 2 % se verrait ;
- `pinMode(INPUT_PULLUP)` arme réellement le pull-up interne ;
- l'anti-rebond de 20 ms laisse passer l'appui ;
- `analogWrite` produit une vraie PWM (plus de vingt fronts en 50 ms) ;
- la minuterie de 3 s expire toute seule et éteint le témoin.

C'est la section `[11]` de `simulateur/tests/test_coeur.cpp`.

### Ce que le catalogue couvre désormais

56 composants, dont sept à mécanique interne — servomoteur, moteur à courant
continu, moteur pas à pas, moteur asynchrone triphasé, télémètre à ultrasons,
codeur incrémental, capteur de courant. Ils ont un état qui avance dans le
temps, pas seulement une impédance, et leur grandeur s'affiche sous le symbole
pendant la simulation.

Les machines portent leur **inductance interne** : l'induit d'un moteur est R
en série avec L. C'est vérifié contre la théorie — le courant atteint 63 % de
sa valeur finale après une constante de temps L/R, et il est encore nul à
l'instant de la fermeture.

### Ce que les analyses apportent au cours

Le simulateur ne se contente plus d'afficher des formes d'onde : il trace une
**caractéristique de transfert** (balayage continu), un **diagramme de Bode**
(gain et phase en fonction de la fréquence, avec la coupure à −3 dB lue
automatiquement) et le **spectre** d'un signal avec son taux de distorsion.

C'est exactement ce que demandent les séances d'électronique analogique du
cours : vérifier qu'un filtre RC coupe bien à 1/(2·π·R·C), voir la pente de
−20 dB par décade, constater qu'un signal carré contient les harmoniques
impaires. Un montage sans carte Arduino se simule d'ailleurs très bien : un
filtre, un pont diviseur ou un redresseur n'ont pas besoin de microcontrôleur.

Il produit aussi les documents qu'on attend d'un projet : nomenclature,
rapport de contrôle des règles électriques, netlist au format KiCad, relevés
en CSV et schéma en PDF.

Ce qui reste hors de portée : tout ce qui passe par un **protocole numérique**
(DHT22 en une-fil, écrans I²C, cartes SD en SPI). Ce n'est pas une question de
composants mais de moteur : il faudrait une simulation numérique événementielle
en plus des deux existantes.

### Ce que le noyau Arduino couvre

`pinMode` · `digitalWrite` · `digitalRead` · `analogRead` · `analogWrite` ·
`millis` · `micros` · `delay` · `delayMicroseconds` · `map` · `constrain` ·
`min` · `max` · `random` · `bitRead`/`bitSet`/`bitWrite` ·
`Serial.begin/print/println/read/available/write`

Assez pour tout ce que la formation demande jusqu'aux protocoles.

### Ce qu'il ne couvre pas

`Wire` (I²C), `SPI`, `EEPROM`, `Servo`, `tone()`, `attachInterrupt`, et les
bibliothèques tierces (`DHT`, `Adafruit_SSD1306`, `PubSubClient`).

---

## Pourquoi les autres TP ne peuvent pas y passer

Ce ne sont pas des lacunes à combler : ce sont des outils différents.

**TP 2 — VHDL.** Un simulateur de circuit résout des équations électriques ;
un simulateur VHDL exécute une description matérielle événementielle et produit
des chronogrammes. Rien de commun. GHDL fait ça très bien, et le TP est écrit
pour lui.

**TP 3 et TP 4 — Siemens et Schneider.** Les automates se programment en
IEC 61131-3 (LADDER, SCL, GRAFCET) et s'exécutent sur un cycle automate, pas
sur un cœur AVR. PLCSIM et le simulateur M221 sont gratuits et font partie des
ateliers officiels — c'est ce que l'industrie utilise.

**TP 5 — STM32.** simavr émule des AVR. Un STM32 est un ARM Cortex-M :
autre jeu d'instructions, autres périphériques. Le supporter voudrait dire
intégrer un second émulateur (Renode ou QEMU) et refaire toute la couche
périphérique. C'est un projet en soi, pas un réglage.

**TP 1, séances 2 à 4.** Le DHT22 parle un protocole une-fil à contraintes de
temps de l'ordre de la microseconde ; l'écran SSD1306 est en I²C ; la carte SD
en SPI ; l'ESP32 fait du WiFi et du MQTT. Il faudrait un troisième moteur — une
simulation numérique événementielle avec des modèles de périphériques — en plus
de l'analogique et du cœur AVR. Wokwi le fait déjà et le TP est écrit pour lui.

---

## En pratique

Le simulateur maison est le bon outil pour **comprendre l'électronique** :
il montre le courant réel dans une LED, l'effondrement d'une sortie surchargée,
la charge d'un RC, une PWM à l'oscilloscope. C'est ce que Wokwi ne montre pas.

Wokwi reste le bon outil pour les **montages à périphériques** : capteurs,
écrans, réseau. Les deux sont complémentaires, et le cours indique lequel
utiliser à chaque séance.

| Tu veux… | Ouvre |
|---|---|
| voir une tension, un courant, une forme d'onde | le simulateur maison |
| vérifier un montage avant de le câbler | le simulateur maison |
| un écran, un capteur I²C, du WiFi | Wokwi |
| du VHDL | GHDL + GTKWave |
| un automate | PLCSIM ou EcoStruxure |
| du STM32 | une Nucleo, ou Renode |
