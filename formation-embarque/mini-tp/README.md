# Mini-TP — tests rapides sur simulateur, par thème

> Des exercices de **15 à 30 minutes**, sous forme de **programmes à
> compléter** (les trous sont marqués `À COMPLÉTER`), à faire **sans aucun
> matériel** sur des plateformes de simulation gratuites. Chaque mini-TP se
> place **entre le cours et le TD** : il valide qu'un concept est compris
> avant d'attaquer les exercices complets.

## Les plateformes de simulation (toutes gratuites, liens directs)

| Thème | Plateforme | Lien | Installation ? |
|---|---|---|---|
| **C / C++** | OnlineGDB (compilateur en ligne) | https://www.onlinegdb.com | non |
| C / C++ (voir l'assembleur) | Compiler Explorer | https://godbolt.org | non |
| **Arduino / ESP32 / Pico** | **Wokwi** (le meilleur : breadboard, capteurs, série) | https://wokwi.com | non |
| Arduino (alternative) | Tinkercad Circuits (Autodesk) | https://www.tinkercad.com/circuits | non (compte gratuit) |
| **VHDL** | **EDA Playground** (GHDL + ondes EPWave) | https://www.edaplayground.com | non (compte gratuit) |
| VHDL (local, illimité) | GHDL + GTKWave | `sudo apt install ghdl gtkwave` | oui |
| **Java** | OnlineGDB (Java) ou JDoodle | https://www.onlinegdb.com · https://www.jdoodle.com | non |
| **Électronique** (circuits, portes) | Falstad CircuitJS | https://www.falstad.com/circuit/ | non |
| **Siemens** | TIA Portal (essai 21 j) + **PLCSIM** | https://www.siemens.com → « TIA Portal trial download » | oui (lourd) |
| **IEC 61131-3 générique** | **CODESYS** (mode simulation intégré, sans automate) | https://www.codesys.com | oui |
| IEC 61131-3 (open source) | OpenPLC Editor | https://autonomylogic.com | oui (léger) |
| **Schneider** | **Machine Expert Basic** (simulateur M221 intégré, gratuit) | https://www.se.com → rechercher « EcoStruxure Machine Expert Basic » | oui |
| **STM32** | STM32CubeIDE (compilation + débogueur) | https://www.st.com/stm32cubeide | oui |
| STM32 (simulation) | Wokwi (cartes ST Nucleo — support partiel) · Renode (émulateur open source) | https://wokwi.com · https://renode.io | non / oui |
| MicroPython (Pico/ESP32) | Wokwi | https://wokwi.com | non |

**Conseil** : mets ces liens en favoris dès maintenant. Wokwi, OnlineGDB et
EDA Playground couvrent 80 % des besoins de la formation sans rien installer.

## Les mini-TP par thème

| Thème | Dossier | Plateforme | Durée |
|---|---|---|---|
| C | [`c/`](c/) | OnlineGDB | 2 × 20 min |
| C++ | [`cpp/`](cpp/) | OnlineGDB | 20 min |
| Arduino | [`arduino/`](arduino/) | Wokwi | 30 min |
| VHDL | [`vhdl/`](vhdl/) | EDA Playground | 30 min |
| Java | [`java/`](java/) | OnlineGDB / JDoodle | 20 min |
| Siemens (SCL) | [`siemens/`](siemens/) | PLCSIM (ou CODESYS) | 30 min |
| Schneider (ST/LADDER) | [`schneider/`](schneider/) | Machine Expert Basic / CODESYS | 30 min |
| STM32 | [`stm32/`](stm32/) | CubeIDE (+ carte ou Wokwi/Renode) | 30 min |

## La méthode (identique pour tous)

1. Ouvre la plateforme indiquée, colle le fichier « à trous » du dossier.
2. Lis les commentaires `À COMPLÉTER (n)` : chacun cible UN concept du cours.
3. Complète, exécute, compare avec le **résultat attendu** donné dans
   l'énoncé. Tout écart = retour à la section de cours indiquée.
4. Quand tout passe : tu es prêt pour le TD du module. Les solutions
   complètes sont dans [`../code/`](../code/) — ne les ouvre qu'après.
