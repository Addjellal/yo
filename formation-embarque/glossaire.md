# Glossaire — tous les sigles et termes du domaine

> Le jargon est le premier mur de l'embarqué. Ce glossaire couvre **tous**
> les sigles employés dans la formation. Cherche avec `Ctrl+F`.

## A — C

| Terme | Signification |
|---|---|
| **ADC** | *Analog to Digital Converter* — convertit une tension en nombre (10 bits sur Uno, 12 sur STM32). |
| **AHB / APB** | Bus internes d'un STM32 (rapide / périphériques). Chaque périphérique est cadencé par le sien. |
| **API** (automatisme) | **A**utomate **P**rogrammable **I**ndustriel = PLC en anglais. À ne pas confondre avec API logicielle. |
| **ARR** | *Auto-Reload Register* — valeur maximale d'un compteur de timer STM32 ; fixe la période. |
| **ASIC** | Circuit intégré gravé pour une seule application (contraire du FPGA, reprogrammable). |
| **AU** | **A**rrêt d'**U**rgence. Toujours câblé en **NF** (sécurité positive). |
| **Bare-metal** | Programmation sans système d'exploitation : ton code est seul sur la puce. |
| **Baudrate** | Nombre de symboles/s d'une liaison série (9600, 115200…). Débit utile ≈ baudrate/10 en 8N1. |
| **BCD** | *Binary Coded Decimal* — un chiffre décimal (0-9) par groupe de 4 bits. |
| **Bootloader** | Petit programme qui démarre en premier et permet de charger le firmware (USB/DFU/UART). |
| **Bounce (rebond)** | Micro-oscillations parasites d'un contact mécanique pendant quelques ms. À filtrer. |
| **CAN** | *Controller Area Network* — bus différentiel 2 fils, multi-maître, robuste (automobile, industrie). |
| **CCR** | *Capture/Compare Register* — seuil de comparaison d'un timer ; fixe le rapport cyclique PWM. |
| **CMSIS** | Couche standard ARM (définitions de registres, DSP) commune à tous les fabricants. |
| **CODESYS** | Environnement IEC 61131-3 multi-marques (base de Schneider Machine Expert, Wago, Festo…). |
| **CS** *(Chip Select)* | Ligne SPI qui sélectionne l'esclave à qui l'on parle (une par esclave, active bas). |
| **Cross-compilation** | Compiler sur PC (x86) un programme destiné à une autre architecture (ARM, AVR). |

## D — H

| Terme | Signification |
|---|---|
| **DB** (Siemens) | *Data Block* — bloc de données. Un **DB d'instance** est la mémoire d'un FB. |
| **DFB** (Schneider) | *Derived Function Block* — bloc fonction utilisateur (équivalent du FB Siemens). |
| **DMA** | *Direct Memory Access* — transfère des données mémoire↔périphérique **sans le CPU**. |
| **Duty cycle** | Rapport cyclique : part du temps où un signal PWM est à l'état haut. |
| **Endianness** | Ordre des octets en mémoire : *little-endian* (poids faible d'abord, x86/ARM) ou *big-endian* (réseau). |
| **EXTI** | *External Interrupt* — interruption STM32 déclenchée par un changement d'état de broche. |
| **FB / FC** (Siemens) | *Function Block* (**avec** mémoire) / *Function* (**sans** mémoire). |
| **FBD** | *Function Block Diagram* — langage automate en blocs logiques (norme IEC 61131-3). |
| **Firmware** | Le logiciel embarqué dans la puce (par opposition au logiciel PC). |
| **FIFO** | *First In First Out* — file d'attente ; cf. tampon circulaire. |
| **FPGA** | *Field-Programmable Gate Array* — matrice logique reconfigurable, décrite en VHDL/Verilog. |
| **FPU** | *Floating Point Unit* — unité de calcul flottant matérielle. Sans elle, les `float` sont très lents. |
| **Front** (montant/descendant) | Instant de transition 0→1 / 1→0. **Le** concept clé en automatisme et en VHDL. |
| **FSM** | *Finite State Machine* — machine à états finis. Le patron de conception n°1 de l'embarqué. |
| **GPIO** | *General Purpose Input/Output* — broche numérique configurable en entrée ou sortie. |
| **GRAFCET** | Méthode graphique française de description séquentielle (IEC 60848). Devient **SFC** en programmation. |
| **HAL** | *Hardware Abstraction Layer* — bibliothèque qui masque les registres (ex. STM32 HAL). |
| **HardFault** | Exception ARM déclenchée par une faute grave (pointeur invalide, accès interdit). |
| **HMI / IHM** | *Human-Machine Interface* — pupitre opérateur (WinCC chez Siemens, Harmony chez Schneider). |
| **HSE / HSI** | *High Speed External/Internal* — sources d'horloge STM32 (quartz externe / oscillateur interne). |
| **Hystérésis** | Bande morte entre deux seuils, qui empêche une sortie de « battre » autour d'un point de consigne. |

## I — O

| Terme | Signification |
|---|---|
| **I2C** | Bus 2 fils (SDA + SCL) avec pull-ups, adressage 7 bits, multi-esclaves. Capteurs, OLED, RTC. |
| **IEC 61131-3** | Norme des 5 langages automate : LD (LADDER), FBD, ST, IL, SFC. |
| **IL** | *Instruction List* — langage automate type assembleur, obsolète. |
| **Input Capture** | Mode timer qui horodate un front matériellement (mesure de largeur/fréquence sans jitter). |
| **IRQ / ISR** | *Interrupt Request* / *Interrupt Service Routine* — demande d'interruption / fonction qui la traite. |
| **JTAG / SWD** | Interfaces de débogage matériel (points d'arrêt, inspection). SWD = version 2 fils d'ARM. |
| **LADDER (LD)** | Langage automate en schéma à contacts, hérité des schémas à relais. |
| **Latch** | Mémoire non désirée créée en VHDL quand une sortie n'est pas affectée dans tous les chemins. |
| **LSB / MSB** | *Least/Most Significant Bit* — bit de poids faible / fort. L'UART transmet le **LSB d'abord**. |
| **Mémoire image** | Copie des entrées figée par l'automate pendant tout un cycle. |
| **Métastabilité** | État instable d'une bascule échantillonnant un signal asynchrone → d'où le **synchroniseur 2 bascules**. |
| **MISRA C** | Référentiel de règles de codage C pour le logiciel critique (auto, aéro, médical). |
| **Modbus** | Protocole industriel ouvert (RTU sur RS-485, TCP sur port 502). Créé par Modicon/Schneider. |
| **Mot de vie** *(heartbeat)* | Compteur incrémenté par l'automate ; s'il se fige, le superviseur sait que le programme est mort. |
| **Mutex** | Verrou d'exclusion mutuelle protégeant une ressource partagée entre tâches. |
| **NF / NO** | Contact **N**ormalement **F**ermé / **N**ormalement **O**uvert. Un AU est toujours NF. |
| **NVIC** | *Nested Vectored Interrupt Controller* — gestionnaire d'interruptions ARM (priorités, imbrication). |
| **OB** (Siemens) | *Organization Block* — bloc appelé par le système (`OB1` = cycle principal). |
| **OPC UA** | Protocole d'échange normalisé entre automates et informatique/IIoT. |
| **Oversampling** | Sur-échantillonnage : lire un signal plusieurs fois par bit pour se recaler (récepteur UART). |

## P — S

| Terme | Signification |
|---|---|
| **Padding** | Octets de bourrage insérés par le compilateur pour aligner les champs d'une structure. |
| **PLC** | *Programmable Logic Controller* — automate programmable (= API en français). |
| **PLCSIM** | Simulateur d'automate Siemens : teste un programme sans matériel. |
| **PLL** | *Phase-Locked Loop* — multiplieur d'horloge (ex. 16 MHz → 100 MHz sur STM32). |
| **Point fixe** | Représenter des décimaux avec des entiers (253 = 25,3 °C) pour éviter le flottant. |
| **Polling** | Scruter en boucle l'état d'un périphérique (contraire : interruption). |
| **PROFINET / PROFIBUS** | Réseaux industriels Siemens (Ethernet temps réel / bus de terrain historique). |
| **PSC** | *Prescaler* — diviseur d'horloge d'un timer STM32. |
| **Pull-up / pull-down** | Résistance qui impose un niveau connu quand rien ne pilote la ligne. |
| **PWM** | *Pulse Width Modulation* — modulation de largeur d'impulsion ; règle une puissance moyenne. |
| **RAII** | *Resource Acquisition Is Initialization* — libération automatique par le destructeur (C++). |
| **RCC** | *Reset and Clock Control* — le bloc STM32 qui active l'horloge de chaque périphérique. **L'oubli n°1.** |
| **Ring buffer** | Tampon circulaire : file de taille fixe, indispensable aux drivers UART. |
| **RS-232 / RS-485** | Normes électriques série : point à point ±12 V / différentiel multipoint (base du Modbus RTU). |
| **RTC** | *Real Time Clock* — horloge temps réel (date/heure), souvent sauvegardée par pile. |
| **RTOS** | *Real-Time Operating System* — ordonnanceur temps réel (FreeRTOS, Zephyr). |
| **SCADA** | *Supervisory Control And Data Acquisition* — supervision d'installation. |
| **SCL** (Siemens) | *Structured Control Language* — le texte structuré (ST) de Siemens, proche du Pascal. |
| **SFC** | *Sequential Function Chart* — le GRAFCET en version programmable. |
| **SPI** | Bus série 4 fils (MOSI/MISO/SCK/CS), full duplex, très rapide. Écrans, cartes SD, flash. |
| **ST** | *Structured Text* — langage automate textuel (IEC 61131-3). |
| **Stack / Heap** | Pile (variables locales, retours) / tas (allocation dynamique — évité en embarqué). |
| **std_logic** | Type VHDL à 9 états ('0','1','Z','U','X'…) modélisant un fil réel. |
| **SysTick** | Timer système ARM cadençant `HAL_GetTick()` — approprié par le RTOS quand il y en a un. |

## T — Z

| Terme | Signification |
|---|---|
| **Temps réel** | **Garantie de délai**, pas « rapide ». Un système temps réel respecte toujours son échéance. |
| **Testbench** | Module VHDL qui stimule et vérifie automatiquement un design en simulation. |
| **TIA Portal** | Environnement unique Siemens (programmation + matériel + IHM + réseau). |
| **Timer** | Compteur matériel : base de temps, PWM, mesure d'impulsion, comptage externe. |
| **TON / TOF / TP** | Temporisations IEC : retard à l'enclenchement / au déclenchement / impulsion calibrée. |
| **TOR** | **T**out **O**u **R**ien — signal binaire (0/1) en vocabulaire automaticien. |
| **Toolchain** | Chaîne d'outils : préprocesseur → compilateur → assembleur → éditeur de liens → programmateur. |
| **UART / USART** | Émetteur-récepteur série asynchrone (le « Serial » d'Arduino). |
| **Variateur (VFD)** | Convertisseur qui règle la vitesse d'un moteur (ATV chez Schneider, SINAMICS chez Siemens). |
| **Verilog** | Langage de description matérielle concurrent du VHDL (dominant aux USA). |
| **VHDL** | *VHSIC Hardware Description Language* — décrit un **circuit**, ne s'exécute pas. |
| **volatile** | Mot-clé C : « relis cette variable à chaque accès » (registres, ISR). **N'assure pas l'atomicité.** |
| **Vref** | Tension de référence d'un ADC : fixe la pleine échelle. |
| **Watchdog** | Compteur qui redémarre la puce si le programme cesse de le « caresser ». |
| **WinCC** | Logiciel IHM/SCADA de Siemens, intégré à TIA Portal. |
| **Wokwi** | Simulateur en ligne d'Arduino/ESP32/Pico avec breadboard et instruments. |
| **Word swap** | Inversion de l'ordre des deux mots 16 bits d'une valeur 32 bits — piège Modbus classique. |

---

## Faux amis fréquents

| Piège | Réalité |
|---|---|
| « temps réel » = rapide | non : **délai garanti** |
| `volatile` = atomique | non : il empêche la mise en cache, pas les accès concurrents |
| API | en automatisme = l'automate lui-même |
| Le VHDL « s'exécute » | non : il **décrit** un circuit qui fonctionne en parallèle |
| `byte` en Java | **signé** (−128..127) → toujours `& 0xFF` en binaire |
| `int` | 16 bits sur AVR, 32 sur ARM → utiliser `stdint.h` |
