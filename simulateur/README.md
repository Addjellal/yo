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
- **Catalogue de 52 composants** (48 simulables, 9 familles), tous vérifiés
  par les tests : passifs, diodes et Zener, transistors NPN/PNP, MOSFET,
  optocoupleur, afficheur 7 segments, relais, portes logiques, amplificateur
  opérationnel, régulateur 7805, instruments de mesure.
- **Sept composants à mécanique interne**, qui ont une position et une vitesse
  et pas seulement une impédance : servomoteur (décode la largeur
  d'impulsion), moteur à courant continu, moteur pas à pas, moteur asynchrone
  triphasé, télémètre à ultrasons, codeur incrémental, capteur de courant.
  Leur grandeur s'affiche sous le symbole pendant la simulation — l'angle du
  servo, les tours par minute du moteur.
- **Machines avec leur inductance interne** : l'induit d'un moteur est R en
  série avec L, chaque phase d'un pas à pas ou d'un asynchrone aussi. C'est
  cette inductance qui empêche le courant de s'établir d'un coup, produit la
  surtension à la coupure et rend la diode de roue libre nécessaire.
- **Capteurs analogiques** : accéléromètre 3 axes ADXL335, LDR, thermistance
  CTN, LM35, gaz MQ-2, humidité du sol, pression, pH, capteur de courant
  ACS712.
- **Simulation couplée** : la LED s'allume avec l'éclat correspondant au
  courant réellement calculé, chaque fil affiche sa tension moyenne.
- **Oscilloscope quatre voies** : formes d'onde réelles issues de l'analyse
  transitoire — tension d'un nœud ou courant d'un composant, base de temps de
  2 ms à 5 s, mesures moyenne et crête, gel de l'écran. Les voies se règlent
  seules au premier lancement.
- **Croquis Arduino directement** : `pinMode`, `digitalWrite`, `analogRead`,
  `analogWrite`, `millis`, `Serial`… Un noyau Arduino minimal est embarqué
  dans l'exécutable et compilé avec le programme — rien à installer. Le code
  au niveau des registres reste accepté tel quel.
- **Compilation intégrée** : on écrit le programme dans l'application,
  `F5` compile avec `avr-g++` et charge le résultat.
- **Moniteur série** : ce que le programme envoie sur l'UART s'affiche.
- **Enregistrement** du schéma et du programme dans un fichier `.schema.json`,
  **export** de la netlist SPICE.
- **Plusieurs cartes** sur le même schéma : chacune a son propre cœur AVR et
  son propre programme, choisi dans le sélecteur au-dessus de l'éditeur. Elles
  partagent le circuit et l'horloge, et peuvent donc se parler par leurs
  broches.
- **Huit exemples** dans le menu *Exemples* : clignotant, bouton avec pull-up,
  potentiomètre sur l'ADC, moteur commandé par transistor, PWM matérielle à
  observer à l'oscilloscope, deux cartes qui communiquent, servomoteur balayé,
  et moteur en PWM commandé par transistor.

## Ce que ça ne fait pas encore

Autant le dire tout de suite, pour ne pas donner le change :

- L'état électrique se transmet d'une fenêtre à la suivante par les **tensions
  de nœud** (`.ic`). Les courants d'inductance, eux, repartent de zéro à chaque
  trame : un circuit dont le comportement dépend de l'énergie stockée dans une
  bobine sur plus de 25 ms sera donc approximé.
- Ce que le circuit renvoie au microcontrôleur sur une **entrée** est la valeur
  de fin de pas de couplage : jusqu'à 5 ms de retard sur ce chemin-là. Le
  chemin inverse — le programme qui pilote le circuit — est daté au cycle
  près. C'est assez fin pour un bouton, un capteur ou un signal échangé entre
  deux cartes ; ce ne l'est pas pour un protocole série entre cartes.
- Les composants à mécanique avancent **une fois par pas de couplage** (5 à
  25 ms). C'est largement assez pour un servomoteur ou un moteur, dont les
  constantes de temps sont bien plus longues ; ce ne le serait pas pour une
  mécanique rapide.
- Pas de composants **numériques complexes** (74HC595, écran LCD, I²C, SPI vers
  périphériques) : il faudrait un moteur de simulation numérique événementiel
  en plus des deux existants. Le noyau Arduino n'a donc ni `Wire`, ni `SPI`,
  ni `Servo`, ni `tone()`, ni bibliothèque tierce.
- Pas de **routage de circuit imprimé**. L'architecture le prépare — chaque
  composant porte déjà son empreinte et la netlist est un objet de première
  classe — mais le module n'existe pas.
- Un seul **type** de microcontrôleur pris en charge : ATmega328P (Arduino
  Uno). On peut en poser plusieurs, mais pas d'autre modèle.

---

## Construire et lancer

### Linux (Debian, Ubuntu)

```bash
sudo apt install build-essential cmake qt6-base-dev \
                 libngspice0-dev libsimavr-dev libelf-dev \
                 gcc-avr avr-libc

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)

./build/tests_coeur                        # 105 tests, sans Qt
QT_QPA_PLATFORM=offscreen ./build/tests_schema   # 19 tests, sans fenêtre
./build/simulateur                         # l'application
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
│   │   │   ├── instruments.cpp      voltmètre, ampèremètre
│   │   │   ├── actionneurs_dynamiques.cpp  servo, moteurs, triphasé
│   │   │   └── capteurs_avances.cpp        accéléromètre, télémètre, codeur
│   │   └── engines/
│   │       ├── noyau_arduino.h        le noyau Arduino, embarqué en texte
│   │       ├── NgspiceEngine.{h,cpp}  netlist → SPICE → tensions et courants
│   │       └── AvrEngine.{h,cpp}      firmware → cycles → états de broches
│   └── app/                         ← tout ce qui dépend de Qt
│       ├── FenetrePrincipale.{h,cpp}
│       ├── MoteurSimulation.{h,cpp}   couplage des deux moteurs
│       ├── Oscilloscope.{h,cpp}       quatre voies, tracé min/max
│       └── schematic/                 bibliothèque à part, donc testable
├── outils/
│   ├── generer_figures.cpp          schémas SVG pour les cours
│   └── figures_liste.inc            les montages, décrits en données
└── tests/
    ├── test_coeur.cpp                105 tests, sans Qt
    └── test_schema.cpp               25 tests, saisie de schéma sans fenêtre
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

## Les figures du cours viennent d'ici

Les schémas électriques de `formation-embarque/` ne sont pas dessinés à la
main : ils sont produits à partir du **même catalogue de composants** que
l'atelier.

```bash
./build/generer_figures ../formation-embarque/figures
```

Un montage se décrit en données dans `outils/figures_liste.inc` — des
placements, des fils, des annotations — et le symbole vient du catalogue.
Conséquence : ajouter un composant le rend dessinable dans le cours comme dans
l'application, et il est impossible que les deux divergent.

---

## Un composant peut avoir une mécanique

Une résistance se décrit par une équation. Un servomoteur, non : il a un angle,
et cet angle dépend de ce que le circuit lui a envoyé *pendant un certain
temps*. Le catalogue prévoit donc un second crochet, à côté de `vers_spice` :

```cpp
m.evoluer = [](Instance& i, const Evolution& evolution) {
    const double largeur = evolution.largeur_impulsion("SIG");   // en secondes
    ...
    i.valeurs["angle"] = ...;
};
m.lecture = [](const Instance& i) { return arrondi(i.valeur("angle"), 0) + " °"; };
```

Après chaque fenêtre de calcul, le composant reçoit **les formes d'onde de ses
propres bornes** — celles que ngspice vient de produire — et met à jour son
état. Cet état sert ensuite à construire le circuit de la fenêtre suivante,
où le composant redevient une source ou une charge. La boucle est fermée.

Trois raccourcis couvrent l'essentiel : `largeur_impulsion` (ce que décode un
servo), `moyenne` (ce que voit un moteur), `rapport_cyclique`.

Et pour les capteurs qui *répondent* par un signal daté — l'écho d'un
télémètre, les voies d'un codeur — `vers_spice_transitoire` reçoit la durée de
la fenêtre et émet une source linéaire par morceaux.

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

**Le pas de couplage.** Le retour du circuit vers le microcontrôleur ne se
fait pas en continu : il a lieu à la fin de chaque pas de couplage. Ce pas
vaut 25 ms quand toutes les broches sont en sortie — le programme n'a alors
rien à relire, et traiter la trame d'un bloc est bien plus rapide. Dès qu'une
broche est lue (bouton, capteur, autre carte), il passe à 5 ms. On paie donc
la finesse seulement là où elle sert. Mesuré sur l'exemple à deux cartes, la
concordance entre les LED des deux cartes passe de 92,2 % à 98,1 %.

**Coût.** Mesuré sur cette machine, avec le pas de calcul par défaut (50 µs,
soit un échantillon toutes les 50 µs) : environ **3,9× le temps réel** sur le
clignotant, **1,2×** sur la PWM matérielle, **1,5×** sur les deux cartes,
oscilloscope affiché. Deux décisions y sont pour beaucoup :

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

**105 tests du cœur**, sans Qt, en douze sections :

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
| 12 | **composants à mécanique** : servo à 1,5 ms → 90°, moteur à 63 % après une constante de temps, asynchrone à 1440 tr/min pour 4 % de glissement, courant d'induit qui suit la loi L/R, écho de 5,8 ms pour 1 m |
| 11 | **un croquis Arduino de TP**, compilé sans retouche : millis à la bonne cadence, anti-rebond, machine à états, PWM, Serial |
| 10 | **exemplaires multiples** : cinq de chaque modèle en série, aucun nom d'élément SPICE en double ; dix LED en parallèle qui font s'effondrer la sortie |

Et **19 tests de la saisie de schéma**, sans ouvrir de fenêtre : attribution
des références sur vingt exemplaires, dix LED câblées en parallèle, symboles
d'alimentation répétés, et deux cartes sur le même schéma.

L'application se vérifie aussi sans intervention :

```bash
./build/simulateur --exemple 2 --diagnostic          # netlist, SPICE, tensions
./build/simulateur --capture image.png 2500          # compile, simule, capture
./build/simulateur --exemple 4 --onglet 3 --base 0.005 \
                   --capture pwm.png 6000            # la PWM à l'oscilloscope
./build/simulateur --exemple 5 --onglet 3 --base 2 \
                   --capture deux.png 9000           # les deux cartes
```

`--onglet` choisit le panneau du bas (0 programme, 1 journal, 2 série,
3 oscilloscope), `--base` impose la base de temps en secondes. La capture
imprime la vitesse atteinte, puis pour chaque voie la moyenne, la crête, le
rapport cyclique mesuré, et la concordance entre les deux premières voies —
de quoi vérifier qu'un signal en suit un autre sans se fier à l'œil.

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
