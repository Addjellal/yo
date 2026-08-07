# Simulateur embarqué

Une application de bureau — un exécutable, pas une page web — pour dessiner un
schéma électronique, y poser une carte Arduino, et **exécuter le vrai firmware
compilé** pendant que le circuit analogique est résolu autour de lui.

C'est le principe de Proteus VSM, construit sur deux moteurs libres éprouvés :

| Moteur | Rôle | Utilisé aussi par |
|---|---|---|
| [**ngspice**](https://ngspice.sourceforge.io/) | simulation analogique : diodes, transistors, MOSFET, amplificateurs | KiCad |
| [**simavr**](https://github.com/buserror/simavr) | exécution cycle par cycle d'un ATmega328P réel | simulateurs AVR, tests d'intégration |

Le firmware n'est **pas interprété** : il est compilé par `avr-gcc`, chargé
dans un cœur AVR émulé, et ses écritures sur les ports pilotent réellement les
tensions du circuit. Inversement, les tensions calculées par ngspice
remontent dans le convertisseur analogique-numérique et sur les broches
d'entrée. Les deux sens sont testés (voir plus bas).

---

## Ce que ça fait aujourd'hui

- **Saisie de schéma** : palette par famille, glisser-déposer, fils en équerre,
  rotation, grille magnétique, zoom à la molette.
- **Catalogue de 38 composants** (34 simulables, 9 familles), tous vérifiés
  par les tests :
  passifs, diodes et Zener, transistors NPN/PNP, MOSFET, optocoupleur,
  afficheur 7 segments, relais, moteur, portes logiques, amplificateur
  opérationnel, régulateur 7805, capteurs (LDR, thermistance CTN, LM35),
  instruments de mesure.
- **Simulation couplée** : la LED s'allume avec l'éclat correspondant au
  courant réellement calculé, chaque fil affiche sa tension moyenne.
- **Oscilloscope quatre voies** : formes d'onde réelles issues de l'analyse
  transitoire — tension d'un nœud ou courant d'un composant, base de temps de
  2 ms à 5 s, mesures moyenne et crête, gel de l'écran. Les voies se règlent
  seules au premier lancement.
- **Compilation intégrée** : on écrit le programme C dans l'application,
  `F5` compile avec `avr-gcc` et charge le résultat.
- **Moniteur série** : ce que le programme envoie sur l'UART s'affiche.
- **Enregistrement** du schéma et du programme dans un fichier `.schema.json`,
  **export** de la netlist SPICE.
- **Cinq exemples** dans le menu *Exemples* : clignotant, bouton avec pull-up,
  potentiomètre sur l'ADC, moteur commandé par transistor, et PWM matérielle
  à observer à l'oscilloscope.

## Ce que ça ne fait pas encore

Autant le dire tout de suite, pour ne pas donner le change :

- L'état électrique se transmet d'une fenêtre à la suivante par les **tensions
  de nœud** (`.ic`). Les courants d'inductance, eux, repartent de zéro à chaque
  trame : un circuit dont le comportement dépend de l'énergie stockée dans une
  bobine sur plus de 25 ms sera donc approximé.
- Ce que le circuit renvoie au microcontrôleur sur une **entrée** est la valeur
  de fin de trame : il y a jusqu'à 25 ms de retard sur ce chemin-là. Le chemin
  inverse — le programme qui pilote le circuit — est daté au cycle près.
- Pas de composants **numériques complexes** (74HC595, écran LCD, I²C, SPI vers
  périphériques) : il faudrait un moteur de simulation numérique événementiel
  en plus des deux existants.
- Pas de **routage de circuit imprimé**. L'architecture le prépare — chaque
  composant porte déjà son empreinte et la netlist est un objet de première
  classe — mais le module n'existe pas.
- Un seul microcontrôleur pris en charge : **ATmega328P** (Arduino Uno).

---

## Construire et lancer

### Linux (Debian, Ubuntu)

```bash
sudo apt install build-essential cmake qt6-base-dev \
                 libngspice0-dev libsimavr-dev libelf-dev \
                 gcc-avr avr-libc

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)

./build/tests_coeur      # 58 tests, sans écran
./build/simulateur       # l'application
```

Les dépendances sont **facultatives** et détectées à la configuration :
sans `libngspice`, sans `libsimavr` ou sans Qt, ce qui reste se compile
quand même. La barre d'état indique en permanence quels moteurs sont actifs.

### Windows

Je n'ai pas pu produire ni tester un `.exe` Windows : cette machine est sous
Linux et il n'y a pas de Qt Windows disponible pour une compilation croisée.
La marche à suivre est celle-ci, mais **elle n'est pas vérifiée** :

1. Installer [Qt 6](https://www.qt.io/download-qt-installer) (composant
   *MSVC 2019 64-bit* ou *MinGW*), CMake et Visual Studio Build Tools.
2. Récupérer ngspice en bibliothèque partagée
   (`ngspice-XX_dll_64.zip` sur [SourceForge](https://sourceforge.net/projects/ngspice/files/))
   et placer `ngspice.dll` à côté de l'exécutable.
3. Pour simavr, compiler depuis les sources ou utiliser MSYS2
   (`pacman -S mingw-w64-x86_64-simavr`).
4. Pour `avr-gcc`, installer [WinAVR](https://winavr.sourceforge.net/) ou la
   chaîne d'Arduino IDE, et l'ajouter au `PATH`.

```powershell
cmake -S . -B build -DCMAKE_PREFIX_PATH="C:/Qt/6.6.0/msvc2019_64"
cmake --build build --config Release
```

Sans `avr-gcc`, l'application reste utilisable : elle charge directement un
`.elf` ou un `.hex` produit par l'IDE Arduino
(*Croquis → Exporter les binaires compilés*).

---

## Organisation du code

```
simulateur/
├── CMakeLists.txt
├── src/
│   ├── main.cpp                     point d'entrée + modes de vérification
│   ├── core/                        ← aucune dépendance à l'interface
│   │   ├── Netlist.{h,cpp}          le modèle central, partagé par tout
│   │   ├── Device.{h,cpp}           structure d'un composant + catalogue
│   │   ├── catalogue/               un fichier par famille de composants
│   │   │   ├── Traits.h             raccourcis de tracé
│   │   │   ├── base.cpp             passifs, alimentations
│   │   │   ├── cartes.cpp           carte Arduino Uno
│   │   │   ├── semiconducteurs.cpp  diodes, transistors, afficheurs
│   │   │   ├── capteurs.cpp         boutons, potentiomètres, LDR, CTN…
│   │   │   ├── electromecanique.cpp relais, moteur, buzzer, haut-parleur
│   │   │   ├── logique.cpp          portes, ampli op, régulateur
│   │   │   └── instruments.cpp      voltmètre, ampèremètre
│   │   └── engines/
│   │       ├── NgspiceEngine.{h,cpp}  netlist → SPICE → tensions et courants
│   │       └── AvrEngine.{h,cpp}      firmware → cycles → états de broches
│   └── app/                         ← tout ce qui dépend de Qt
│       ├── FenetrePrincipale.{h,cpp}
│       ├── MoteurSimulation.{h,cpp}   couplage des deux moteurs
│       ├── Oscilloscope.{h,cpp}       quatre voies, tracé min/max
│       └── schematic/                 scène, vue, composants, fils
└── tests/test_coeur.cpp             58 tests, sans écran
```

La séparation `core` / `app` n'est pas décorative : `core` ne connaît pas Qt,
se teste sans écran, et c'est lui que réutilisera le futur module de circuit
imprimé.

### Ajouter un composant

Un composant = **un bloc** dans le fichier de sa famille. Rien d'autre à
toucher : ni l'interface, ni les moteurs, ni la palette.

```cpp
{   // ------------------------------------------------------------ résistance
    Modele m;
    m.type = "resistance";
    m.libelle = "Résistance";
    m.categorie = "Passifs";           // regroupement dans la palette
    m.prefixe = "R";                   // références R1, R2…
    m.bornes = {{"1", {-30, 0}, ""}, {"2", {30, 0}, ""}};
    m.proprietes = {{"ohms", "Valeur", G::Nombre, 220, 0, 0, "", {}, "Ω"}};
    m.symbole = {ligne(-30, 0, -18, 0), rect(-18, -7, 18, 7),
                 ligne(18, 0, 30, 0)};                    // le dessin, en données
    m.empreinte = {"R_AXIAL_0207", {...}, 12.0, 3.0};     // pour le futur PCB
    m.vers_spice = [](const Instance& i, const auto& noeud) {
        return std::vector<std::string>{
            "R" + i.reference + " " + noeud("1") + " " + noeud("2") + " "
            + nombre(i.valeur("ohms", 220))};
    };
    enregistrer(std::move(m));
}
```

Le test `[7]` monte automatiquement **chaque** composant du catalogue dans un
circuit et vérifie que ngspice l'accepte : un modèle mal écrit est détecté
avant d'atteindre l'utilisateur.

---

## Comment le temps est géré

C'est le point qui décide de la justesse d'un simulateur mixte — et c'est lui
qui rend l'oscilloscope possible.

Le microcontrôleur change d'état des milliers de fois par seconde ; une PWM à
490 Hz commute presque mille fois. On ne peut pas lancer une analyse
transitoire de 25 ms d'un seul bloc, puisque le programme modifie le circuit
pendant ce temps-là.

La sortie tient dans une observation : **simavr date chaque commutation au
cycle d'horloge près**. À chaque image, on transcrit donc cette histoire en
sources SPICE linéaires par morceaux (`PWL`), et ngspice calcule le
transitoire complet de la fenêtre. Le circuit n'est jamais figé : les
condensateurs se chargent, les fronts existent, et la courbe qui en sort est
celle du circuit réel. L'état se transmet d'une fenêtre à la suivante par les
conditions initiales (`.ic`).

Ce détail compte : moyenner les *tensions* d'une PWM à 25 % donnerait 1,25 V
sur une LED, donc une LED éteinte — alors qu'en réalité elle reçoit le plein
courant un quart du temps. Le code est dans
`MoteurSimulation::resoudre_trame` et
`NgspiceEngine::construire_transitoire`.

**Coût.** Mesuré sur cette machine, avec le pas de calcul par défaut (50 µs,
soit un échantillon toutes les 50 µs) : environ **4× le temps réel** sur le
clignotant, **1,25×** sur la PWM matérielle, oscilloscope affiché. Deux
décisions y sont pour beaucoup :

- les broches de carte qui ne sont reliées à rien ne sont pas mises dans le
  circuit — sur une carte à vingt broches dont une seule est câblée, c'était
  l'essentiel du coût ;
- l'oscilloscope trace par colonne de pixels, en relevant le minimum et le
  maximum de chacune. Un créneau garde ses fronts même quand la fenêtre
  contient cent fois plus de points que l'écran n'a de pixels.

Affiner la base de temps affine automatiquement le pas de calcul, jusqu'à
5 µs.

---

## Vérification

```bash
./build/tests_coeur
```

58 tests, sans écran, répartis en neuf sections :

| Section | Ce qui est vérifié |
|---|---|
| 1 | netlist et catalogue |
| 2 | ngspice : LED, surintensité, potentiomètre, pull-up, transistor |
| 3 | simavr : compilation par `avr-gcc`, exécution, horloge au cycle près |
| 4 | **couplage firmware → circuit** : le programme allume la LED, 12,8 mA mesurés |
| 5 | **couplage circuit → firmware** : un niveau imposé est lu par le programme |
| 6 | conversion analogique-numérique |
| 7 | **tout le catalogue** passe dans ngspice |
| 8 | physique des modèles : diode, CTN, LDR, NON-ET, ampli op, 7805, relais |
| 9 | **analyse transitoire** : charge d'un RC comparée à la théorie (3,16 V à une constante de temps), reprise d'état entre fenêtres, PWM à 25 % |

L'application se vérifie aussi sans intervention :

```bash
./build/simulateur --exemple 2 --diagnostic          # netlist, SPICE, tensions
./build/simulateur --capture image.png 2500          # compile, simule, capture
./build/simulateur --exemple 4 --onglet 3 --base 0.005 \
                   --capture pwm.png 6000            # la PWM à l'oscilloscope
```

`--onglet` choisit le panneau du bas (0 programme, 1 journal, 2 série,
3 oscilloscope), `--base` impose la base de temps en secondes. La capture
imprime aussi la vitesse de simulation atteinte.

---

## Raccourcis

| Touche | Effet |
|---|---|
| `R` | pivoter la sélection de 90° |
| `Suppr` | supprimer la sélection |
| molette | zoomer |
| `F5` | compiler le programme et le charger |
| `Ctrl+N` / `Ctrl+O` / `Ctrl+S` | nouveau, ouvrir, enregistrer |

Pour tirer un fil : outil **Fil**, puis cliquer d'une borne à l'autre.
