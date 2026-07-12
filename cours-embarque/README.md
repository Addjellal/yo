# Cours complet — Systèmes embarqués & programmation bas niveau

Un cours structuré, progressif et pratique pour apprendre à programmer les
systèmes embarqués : du transistor jusqu'aux automates industriels Siemens et
Schneider.

## Les modules

| # | Module | Contenu | Prérequis |
|---|--------|---------|-----------|
| 00 | [Fondamentaux](00-fondamentaux.md) | Binaire, électronique numérique, architecture CPU, mémoire, GPIO, UART/I2C/SPI/CAN, interruptions, toolchain | Aucun |
| 01 | [Langage C](01-langage-c.md) | Le langage roi de l'embarqué : pointeurs, mémoire, opérations bit à bit, `volatile`, accès registres, bare-metal | Module 00 |
| 02 | [C++](02-cpp.md) | POO, RAII, templates, C++ moderne appliqué à l'embarqué | Module 01 |
| 03 | [Arduino](03-arduino.md) | Matériel, IDE, GPIO, PWM, ADC, capteurs, projets progressifs | Module 01 (bases) |
| 04 | [VHDL & FPGA](04-vhdl.md) | Logique programmable, entités, process, machines d'états, testbenchs, Vivado/Quartus/GHDL | Module 00 |
| 05 | [Java](05-java.md) | POO complète, où Java sert dans l'industrie (supervision, Android, serveurs) | Aucun |
| 06 | [Autres langages utiles](06-autres-langages.md) | Assembleur ARM, MicroPython, Rust embarqué, Make/CMake, FreeRTOS, Linux embarqué | Modules 00–01 |
| 07 | [Suite Siemens](07-siemens.md) | TIA Portal, S7-1200/1500, LADDER, FBD, SCL, GRAFCET, WinCC, PROFINET | Module 00 |
| 08 | [Suite Schneider](08-schneider.md) | EcoStruxure Control Expert & Machine Expert, M221/M241/M580, IEC 61131-3, HMI Harmony | Module 00 |
| 09 | [Parcours & ressources](09-parcours-et-ressources.md) | Plan d'apprentissage sur 12 mois, projets, matériel à acheter, ressources gratuites | — |

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
