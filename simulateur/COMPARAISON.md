# Ce que fait un logiciel complet, et où en est celui-ci

Ce document répond à une question simple : **par rapport à ce qui existe, que
sait faire ce simulateur, et que ne sait-il pas faire ?**

Les références retenues sont celles qu'on utilise vraiment : **Proteus** (VSM,
la simulation de microcontrôleur avec le circuit autour), **Multisim**
(l'atelier d'analyse avec ses instruments virtuels), **LTspice** (la référence
de la simulation analogique gratuite), **KiCad** (la chaîne schéma → ERC →
netlist → routage) et **Wokwi** (les cartes et périphériques dans le
navigateur).

Chaque ligne marquée ✅ est vérifiée par un test automatique ou par une
capture ; rien n'y est annoncé sur la foi d'un catalogue.

---

## 1. Saisie du schéma

| Fonction | Chez les autres | Ici |
|---|---|---|
| Palette, glisser-déposer, rotation, grille | tous | ✅ |
| Fils en équerre, nœuds automatiques | tous | ✅ |
| Symboles décrits en données (pas en code) | KiCad | ✅ |
| Propriétés éditables par composant | tous | ✅ |
| Sonde sur un fil vers l'oscilloscope | Proteus | ✅ |
| Annuler / rétablir, copier-coller, dupliquer | tous | ✅ 50 états, y compris les déplacements |
| Étiquettes de nœud | KiCad, Altium | ✅ |
| Bus, feuilles multiples | KiCad, Altium | ❌ |
| Alignement, duplication en série | tous | ❌ |
| Éditeur de symboles dans l'interface | KiCad | ❌ (le catalogue s'écrit en C++, un bloc par composant) |

## 2. Simulation

| Fonction | Chez les autres | Ici |
|---|---|---|
| Point de repos (`.op`) | tous | ✅ |
| Analyse transitoire (`.tran`) | tous | ✅ |
| **Balayage continu** (`.dc`, source ou résistance) | LTspice, Multisim | ✅ |
| **Réponse en fréquence** (`.ac`, Bode gain + phase) | LTspice, Multisim | ✅ |
| **Spectre et distorsion harmonique** | Multisim, LTspice (FFT) | ✅ calculé ici même, vérifié contre la théorie |
| Exécution du **vrai firmware** compilé | Proteus VSM, Wokwi | ✅ simavr, ATmega328P |
| Circuit **et** microcontrôleur couplés au cycle | Proteus VSM | ✅ |
| Plusieurs cartes sur le même schéma | Proteus | ✅ |
| Montage sans microcontrôleur | LTspice, Multisim | ✅ |
| Analyse de bruit | LTspice, Multisim | ✅ vérifiée contre 4kTR |
| Balayage en température | LTspice, Multisim | ✅ |
| Monte-Carlo (tolérances, dispersion) | Multisim | ✅ tirage reproductible |
| Analyse de sensibilité | Multisim | ❌ |
| Analyse paramétrique multi-passes (`.step`) | LTspice | ✅ courbes superposées |
| Circuits numériques pilotés par fronts (74HC595) | Proteus, Wokwi | ✅ troisième moteur, événementiel |
| Périphériques à protocole (I²C, SPI, LCD) | Proteus, Wokwi | ❌ le moteur existe, les modèles restent à écrire |
| Autre cœur que l'AVR (STM32, PIC) | Proteus | ❌ |

## 3. Instruments

| Instrument | Chez les autres | Ici |
|---|---|---|
| Oscilloscope multi-voies | tous | ✅ 4 voies, 5 s de mémoire, base 2 ms – 5 s |
| Générateur de signaux | Multisim, Proteus | ✅ sinus, carré, triangle, continu |
| Mesures automatiques (RMS, fréquence, rapport cyclique, temps de montée) | Multisim | ✅ |
| Analyseur de spectre | Multisim | ✅ raies + taux de distorsion |
| Traceur de Bode | Multisim | ✅ (onglet Analyses) |
| Voltmètre, ampèremètre posés sur le schéma | Proteus | ✅ |
| Multimètre à positions continu / alternatif (moyenne / valeur efficace) | Multisim, Proteus | ✅ |
| Ohmmètre à courant d'essai | Multisim | ✅ |
| Déclenchement de l'oscilloscope (front, niveau, auto/normal) | Multisim, Proteus | ✅ avec niveau automatique et pré-déclenchement |
| Curseurs de mesure sur la courbe (Δt, ΔV, fréquence) | Multisim | ✅ |
| Mode XY (Lissajous), décalage vertical par voie, couplage alternatif | Multisim | ✅ |
| Analyseur logique, terminal I²C/SPI | Proteus | ❌ |

## 4. Documents produits

| Document | Chez les autres | Ici |
|---|---|---|
| Netlist SPICE | LTspice, Multisim | ✅ |
| **Nomenclature (BOM)** groupée, en CSV | KiCad, Altium | ✅ |
| **Contrôle des règles électriques (ERC)** | KiCad, Altium | ✅ 10 règles |
| **Netlist au format KiCad** (vers le routage) | KiCad | ✅ |
| Relevés de courbes en CSV | LTspice | ✅ |
| Schéma en PDF vectoriel / PNG | tous | ✅ |
| Fichiers Gerber, perçage, placement | KiCad | ❌ (pas de module PCB) |

Les règles vérifiées par l'ERC : absence de masse, référence en double, borne
non connectée, nœud ne reliant qu'une borne, source court-circuitée, deux
sources en parallèle, résistance nulle, composant lumineux sans résistance
série, broche de microcontrôleur reliée directement à une alimentation.

## 5. Circuit imprimé

| Fonction | Chez les autres | Ici |
|---|---|---|
| Empreinte attachée à chaque composant | KiCad | ✅ le champ existe et est rempli |
| Netlist exportable vers un routeur | KiCad | ✅ |
| Placement des empreintes à la souris | KiCad, Altium | ✅ |
| Chevelu (liaisons restant à router) | KiCad, Altium | ✅ |
| Routage manuel, deux couches | KiCad, Altium | ✅ |
| Contrôle des règles de fabrication (DRC) | KiCad, Altium | ✅ isolation, largeur, débordement |
| **Fichiers Gerber et Excellon** | KiCad | ✅ RS-274X et Excellon métrique |
| Auto-routeur, plans de masse, vias, vue 3D | KiCad, Altium | ❌ |

La brique existe désormais. Ce qui manque encore est du confort de routage —
auto-routeur, plans de masse, vias — pas la chaîne elle-même : d'un schéma on
tire aujourd'hui des fichiers qu'un fabricant accepte.

---

## Ce que ce simulateur fait mieux que les outils en ligne

Ce n'est pas qu'une liste de manques. Sur un point précis, il fait ce que
Wokwi et Tinkercad ne font pas : il **montre l'électricité**. Le courant réel
dans une LED, l'effondrement d'une sortie surchargée par dix LED en parallèle,
la constante de temps d'un RC, la montée du courant dans l'induit d'un moteur
freinée par son inductance, la distorsion d'un signal — tout cela sort d'un
solveur SPICE, pas d'une animation.

C'est aussi un projet dont **chaque affirmation est vérifiée** : 224 tests du
cœur et 81 tests de saisie, dont beaucoup comparent le résultat à une valeur
que la théorie donne à l'avance — 3,16 V après une constante de temps, 1591 Hz
de coupure pour 1 kΩ et 100 nF, −20 dB par décade, 48,3 % de distorsion pour
un signal carré.

---

## Ordre de priorité si le projet continue

1. **Modèles de périphériques à protocole** — écran I²C, carte SD en SPI,
   DHT22 en une-fil. Le moteur événementiel qui leur manquait existe
   maintenant ; ce sont les modèles qui restent à écrire, un par composant.
2. **Confort de routage** : auto-routeur, plans de masse, vias, empreintes
   dessinées pour chaque composant du catalogue plutôt que déduites.
3. **Bus et feuilles multiples**, pour les schémas qui ne tiennent plus sur
   une page.
4. **Autre cœur que l'AVR** (STM32) : un second émulateur et toute la couche
   périphérique. C'est un projet en soi.
