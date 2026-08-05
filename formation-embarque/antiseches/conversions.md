# Antisèche — Conversions & électronique

## Table binaire / hexa / décimal

| Déc | Bin | Hex | | Déc | Bin | Hex |
|---|---|---|---|---|---|---|
| 0 | 0000 | 0 | | 8 | 1000 | 8 |
| 1 | 0001 | 1 | | 9 | 1001 | 9 |
| 2 | 0010 | 2 | | 10 | 1010 | A |
| 3 | 0011 | 3 | | 11 | 1011 | B |
| 4 | 0100 | 4 | | 12 | 1100 | C |
| 5 | 0101 | 5 | | 13 | 1101 | D |
| 6 | 0110 | 6 | | 14 | 1110 | E |
| 7 | 0111 | 7 | | 15 | 1111 | F |

**Méthode** : grouper le binaire **par 4 en partant de la droite**, chaque
groupe = 1 chiffre hexa. `1011 0100` → `B4` → `0xB4` = 11×16+4 = **180**.

## Puissances de 2

| n | 2ⁿ | | n | 2ⁿ |
|---|---|---|---|---|
| 0 | 1 | | 8 | 256 |
| 1 | 2 | | 10 | 1 024 (1 Ki) |
| 2 | 4 | | 12 | 4 096 |
| 3 | 8 | | 16 | 65 536 |
| 4 | 16 | | 20 | 1 048 576 (1 Mi) |
| 5 | 32 | | 24 | 16 777 216 |
| 6 | 64 | | 31 | 2 147 483 648 |
| 7 | 128 | | 32 | 4 294 967 296 |

## Plages des types

| Bits | Non signé | Signé (complément à 2) |
|---|---|---|
| 8 | 0 … 255 | −128 … +127 |
| 12 (ADC) | 0 … 4 095 | — |
| 16 | 0 … 65 535 | −32 768 … +32 767 |
| 32 | 0 … 4 294 967 295 | −2 147 483 648 … +2 147 483 647 |

**Complément à deux** : inverser tous les bits, ajouter 1.
`+10 = 0000 1010` → `1111 0101` → **`1111 0110` = −10 = 0xF6**.
Vérif : lu en non signé, 0xF6 = 246 = 256 − 10. MSB à 1 ⇒ négatif.

## Conversions ADC / DAC

```
tension = brut × Vref / (2ⁿ − 1)
brut    = tension × (2ⁿ − 1) / Vref
résolution (1 LSB) = Vref / 2ⁿ
```

| Cible | n | Vref | 1 LSB |
|---|---|---|---|
| Arduino Uno | 10 bits (0-1023) | 5 V | ≈ 4,9 mV |
| ESP32 / STM32 | 12 bits (0-4095) | 3,3 V | ≈ 0,8 mV |

**Point fixe** (sans flottant) : `mV = (brut * 3300UL) / 4095;`

## Industriel

```
4-20 mA :  valeur = (I_mA − 4) / 16 × étendue
0-10 V  :  valeur = U / 10 × étendue
Siemens analogique : 0..27648 pour la pleine échelle
Convention du cours : entiers ×10 (253 = 25,3 °C) — jamais de Real en Modbus
```

## Temps, fréquence, débit

```
T = 1/f          f = 1/T
1 kHz = 1 ms · 1 MHz = 1 µs · 100 MHz = 10 ns par cycle
```

| UART 8N1 | 10 bits transmis par octet |
|---|---|
| 9 600 bauds | 1 bit ≈ 104 µs · 960 octets/s |
| 115 200 bauds | 1 bit ≈ 8,7 µs · 11 520 octets/s |

`débit utile (o/s) = baudrate / 10`

**Débordement des compteurs ms 32 bits** : 2³² ms ≈ **49,7 jours** → toujours
`maintenant - dernier >= période`.

## Loi d'Ohm & résistance de LED

```
U = R × I        P = U × I
R_LED = (V_alim − V_LED) / I_LED
```
Exemple : 5 V, LED rouge (≈2 V), 10 mA → R = (5−2)/0,01 = **300 Ω** → on
prend 330 Ω (valeur normalisée supérieure). **220 Ω** est le classique
(≈ 13 mA, plus lumineux, toujours dans les 20 mA/broche).

| Tension LED typique | rouge 1,8-2,2 V · vert/jaune 2,0-2,4 V · bleu/blanc 3,0-3,4 V |
|---|---|

## Niveaux logiques et bonnes pratiques

| Famille | 0 logique | 1 logique |
|---|---|---|
| TTL 5 V (Uno) | < 0,8 V | > 2,0 V |
| CMOS 3,3 V (STM32, ESP32, Pi) | < 0,8 V | > 2,0 V |

⚠️ **Ne jamais injecter 5 V sur une broche 3,3 V** (sauf « 5 V tolerant »
explicite) → pont diviseur ou convertisseur de niveau.
**Pull-up** typique : 10 kΩ (bouton), **4,7 kΩ** (I2C).
Une entrée non câblée **flotte** : toujours un pull-up/pull-down.
Découplage : **100 nF** au plus près de chaque alimentation de circuit.

## Code couleur des résistances (4 anneaux)

| Couleur | Chiffre | Multiplicateur |
|---|---|---|
| noir | 0 | ×1 |
| marron | 1 | ×10 |
| rouge | 2 | ×100 |
| orange | 3 | ×1 k |
| jaune | 4 | ×10 k |
| vert | 5 | ×100 k |
| bleu | 6 | ×1 M |
| violet | 7 | — |
| gris | 8 | — |
| blanc | 9 | — |
| *or* | — | tolérance ±5 % |

220 Ω = rouge-rouge-marron · 1 kΩ = marron-noir-rouge ·
4,7 kΩ = jaune-violet-rouge · 10 kΩ = marron-noir-orange.

## Préfixes

| p | n | µ | m | — | k | M | G |
|---|---|---|---|---|---|---|---|
| 10⁻¹² | 10⁻⁹ | 10⁻⁶ | 10⁻³ | 1 | 10³ | 10⁶ | 10⁹ |
