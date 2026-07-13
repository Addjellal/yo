# Formation complète — Systèmes embarqués & programmation bas niveau

Une formation structurée comme un enseignement universitaire/professionnel :
**cours magistraux** (les modules), **travaux dirigés corrigés** (`td/`),
**travaux pratiques guidés pas à pas** (`tp/`) et **évaluations** avec barème
(`evaluations/`). Du transistor jusqu'aux automates industriels Siemens et
Schneider.

## Organisation pédagogique

| Élément | Dossier | Rôle |
|---|---|---|
| **Cours** (11 modules) | `NN-*.md` (racine) | La théorie, les exemples commentés, les concepts |
| **TD — travaux dirigés** | [`td/`](td/) | Exercices d'application avec **corrigés détaillés et commentés** |
| **TP — travaux pratiques** | [`tp/`](tp/) | Séances guidées pas à pas sur projet réel (matériel ou simulateur) ; **chaque TP existe en fiches minutées séance par séance** (`tp/tpN-fiches/`) |
| **Code source des corrigés** | [`code/`](code/) | Les corrigés en **vrais projets compilables et testés** (`make test`) : C, C++, Java, VHDL (GHDL), Arduino, Python/Modbus, SCL/ST |
| **Évaluations** | [`evaluations/`](evaluations/) | QCM de validation (corrigé) + sujets de projets notés avec barème |

**Volume horaire indicatif** (rythme ~6 h/semaine) :

| Module | Cours | TD | TP | Total |
|---|---|---|---|---|
| 00 Fondamentaux | 6 h | 4 h | — | 10 h |
| 01 Langage C | 12 h | 10 h | — | 22 h |
| 02 C++ | 8 h | 6 h | — | 14 h |
| 03 Arduino | 6 h | 4 h | 12 h (TP1) | 22 h |
| 04 VHDL | 10 h | 8 h | 8 h (TP2) | 26 h |
| 05 Java | 8 h | 6 h | — | 14 h |
| 06 Autres langages | 6 h | 3 h | — | 9 h |
| 07 Siemens | 10 h | 6 h | 10 h (TP3) | 26 h |
| 08 Schneider | 8 h | 6 h | 8 h (TP4) | 22 h |
| 10 STM32 | 10 h | 6 h | 10 h (TP5) | 26 h |
| **Total** | | | | **≈ 190 h** (~8 mois à 6 h/sem.) |

**Méthode de travail conseillée pour chaque module** :
1. Lire le cours en entier une première fois (sans coder).
2. Relire en tapant et exécutant chaque exemple.
3. Faire les exercices du cours **sans regarder** le TD.
4. Confronter au corrigé du TD (`td/td-NN-*.md`) — comprendre chaque écart.
5. Faire le TP associé s'il existe.
6. Valider avec le QCM du module ([`evaluations/qcm.md`](evaluations/qcm.md)) :
   **≥ 80 % de bonnes réponses avant de passer au module suivant.**

## Les modules

| # | Cours | Contenu | TD (corrigé) | TP |
|---|--------|---------|---|---|
| 00 | [Fondamentaux](00-fondamentaux.md) | Binaire, électronique numérique, architecture CPU, mémoire, GPIO, UART/I2C/SPI/CAN, interruptions, toolchain | [TD 00](td/td-00-fondamentaux.md) | — |
| 01 | [Langage C](01-langage-c.md) | Le langage roi de l'embarqué : pointeurs, mémoire, opérations bit à bit, `volatile`, accès registres, bare-metal | [TD 01](td/td-01-langage-c.md) | — |
| 02 | [C++](02-cpp.md) | POO, RAII, templates, C++ moderne appliqué à l'embarqué | [TD 02](td/td-02-cpp.md) | — |
| 03 | [Arduino](03-arduino.md) | Matériel, IDE, GPIO, PWM, ADC, capteurs, projets progressifs | [TD 03](td/td-03-arduino.md) | [TP 1 — Station météo](tp/tp1-arduino-station-meteo.md) |
| 04 | [VHDL & FPGA](04-vhdl.md) | Logique programmable, entités, process, machines d'états, testbenchs, Vivado/Quartus/GHDL | [TD 04](td/td-04-vhdl.md) | [TP 2 — UART VHDL](tp/tp2-vhdl-uart.md) |
| 05 | [Java](05-java.md) | POO complète, où Java sert dans l'industrie (supervision, Android, serveurs) | [TD 05](td/td-05-java.md) | — |
| 06 | [Autres langages utiles](06-autres-langages.md) | Assembleur ARM, MicroPython, Rust embarqué, Make/CMake, FreeRTOS, Linux embarqué | [TD 06](td/td-06-autres-langages.md) | — |
| 07 | [Suite Siemens](07-siemens.md) | TIA Portal, S7-1200/1500, LADDER, FBD, SCL, GRAFCET, WinCC, PROFINET | [TD 07](td/td-07-siemens.md) | [TP 3 — Remplissage](tp/tp3-siemens-remplissage.md) |
| 08 | [Suite Schneider](08-schneider.md) | EcoStruxure Control Expert & Machine Expert, M221/M241/M580, IEC 61131-3, HMI Harmony | [TD 08](td/td-08-schneider.md) | [TP 4 — Cuve + Modbus](tp/tp4-schneider-cuve.md) |
| 09 | [Parcours & ressources](09-parcours-et-ressources.md) | Plan d'apprentissage sur 12 mois, projets, matériel à acheter, ressources gratuites | — | — |
| 10 | [STM32](10-stm32.md) | Le micro professionnel : STM32CubeIDE, HAL, clock tree, timers, DMA, NVIC, accès registres, debug SWD, FreeRTOS | [TD 10](td/td-10-stm32.md) | [TP 5 — Météo FreeRTOS](tp/tp5-stm32-freertos.md) |

**Évaluations** : [QCM par module (56 questions, corrigé)](evaluations/qcm.md)
· [Projets finaux notés avec barème /100](evaluations/projets-notes.md)

## Comment utiliser ce cours

1. **Commence par le module 00** même si tu es pressé : tout le reste s'appuie
   dessus (binaire, registres, protocoles).
2. **Le C avant tout le reste.** C'est la langue maternelle de l'embarqué :
   Arduino est du C++, les drivers Linux sont en C, le SCL de Siemens ressemble
   au Pascal/C. Maîtriser le C te donne 70 % du chemin.
3. **Pratique chaque module.** Chaque chapitre contient des exercices. Lire ne
   suffit jamais : tape le code, casse-le, répare-le.
4. **Matériel minimal recommandé** (~50–80 €) :
   - Un Arduino Uno ou Nano (clone à ~5 €)
   - Une breadboard + kit de composants (LED, résistances, boutons, capteurs)
   - Plus tard : une carte FPGA d'entrée de gamme (Tang Nano 9K ~15 €, ou
     Basys 3 si budget) et/ou un STM32 « Blue Pill » (~3 €)
5. **Pour les automates** (Siemens/Schneider), pas besoin d'acheter un
   automate : les deux éditeurs proposent des simulateurs (PLCSIM pour
   Siemens, le simulateur intégré de Control Expert / Machine Expert pour
   Schneider).

## Vue d'ensemble : qui fait quoi ?

```
                        ┌─────────────────────────────────────────┐
   NIVEAU               │  LANGAGE / OUTIL                        │
─────────────────────── ┼──────────────────────────────────────────┤
 Supervision / SCADA    │  Java, Python, C#, WinCC, EcoStruxure   │
 Automates (PLC)        │  LADDER, FBD, SCL, ST  (IEC 61131-3)    │
 Applications embarquées│  C++, Rust, MicroPython                 │
 Firmware / drivers     │  C, un peu d'assembleur                 │
 Logique matérielle     │  VHDL, Verilog  (FPGA / ASIC)           │
 Silicium               │  Électronique numérique (portes, FF)    │
```

Plus on descend, plus on est proche du matériel, et plus le code décrit
*ce que fait physiquement le circuit* plutôt que des instructions exécutées
l'une après l'autre. Le VHDL, tout en bas, **ne s'exécute pas** : il *décrit*
un circuit. C'est le changement de paradigme le plus important de ce cours.
