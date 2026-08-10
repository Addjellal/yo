# Simulateur embarqué

Une application de bureau — un exécutable, pas une page web — pour dessiner un
schéma électronique, y poser une carte Arduino, et **exécuter le vrai firmware
compilé** pendant que le circuit analogique est résolu autour de lui.

C'est le principe de Proteus VSM.

> **Sous Windows, suivez [INSTALLATION-WINDOWS.md](INSTALLATION-WINDOWS.md)** :
> de zéro jusqu'à une LED qui clignote, avec un point de vérification après
> chaque étape. Une seule étape s'ajoute à la construction — l'installation des
> compilateurs croisés, en une commande — et le document dit aussi ce qui
> fonctionne sans eux.


**Rien à télécharger pour simuler.** Le solveur analogique est écrit dans ce
projet : analyse nodale modifiée, méthode de Newton pour les composants non
linéaires, intégration par la règle des trapèzes avec arrêt sur chaque front
des sources. Il fait le point de repos, le transitoire, `.dc`, `.ac` et le
bruit, sur les mêmes fichiers de circuit que SPICE. Un compilateur C++17 et
Qt 6 suffisent donc à construire et à faire tourner l'ensemble.

| Moteur | Rôle | D'où il vient |
|---|---|---|
| **solveur analogique intégré** | diodes, transistors, MOSFET, amplificateurs, transitoire, Bode, bruit | écrit ici, `src/core/engines/SolveurIntegre.cpp` |
| **cœur ATmega328P intégré** | exécution cycle par cycle du vrai firmware | écrit ici, `src/core/engines/CoeurAvr.cpp` |
| [**ngspice**](https://ngspice.sourceforge.io/) | *facultatif* : moteur analogique de référence | KiCad — sert ici à contrôler le premier |
| [**simavr**](https://github.com/buserror/simavr) | *facultatif* : cœur AVR de référence | simulateurs AVR — même rôle de juge |

Quand ngspice et simavr sont présents, les tests font tourner **les deux
moteurs sur les mêmes circuits, les deux cœurs sur le même firmware, et
comparent** : mêmes tensions à 20 mV près sur un montage à diode et
transistor, même forme d'onde à 20 mV près sur un transitoire, même fréquence
de coupure à 2 % près, et les mêmes commutations de broche aux mêmes cycles
d'horloge. C'est ainsi que les moteurs intégrés se justifient — pas sur
parole.

Le firmware, lui, n'est **pas interprété** : il est compilé par `avr-gcc`,
chargé dans un cœur AVR émulé, et ses écritures sur les ports pilotent
réellement les tensions du circuit. Inversement, les tensions calculées
remontent dans le convertisseur analogique-numérique et sur les broches
d'entrée. Les deux sens sont testés (voir plus bas).

---

## Ce que ça fait aujourd'hui

- **Saisie de schéma** : palette par famille, glisser-déposer, fils en équerre,
  rotation, grille magnétique, zoom à la molette.
- **Catalogue de 57 composants** (51 simulables, 10 familles), tous vérifiés
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
- **Multimètres, comme dans Multisim et Proteus** : le voltmètre et
  l'ampèremètre ont une **position continu / alternatif**. En continu ils
  affichent la valeur moyenne, en alternatif la valeur efficace de la partie
  variable — pas la valeur instantanée, qui ne veut rien dire sur un signal.
  S'ajoute un **ohmmètre**, qui injecte un courant d'essai connu et lit la
  tension, comme le fait un vrai appareil en position Ω (et comme lui, il ne
  mesure juste que hors circuit). Les trois affichent leur mesure sous leur
  symbole, et **double-cliquer un appareil ouvre sa propre fenêtre** — valeur
  en grand, commutateur de position, minimum, moyenne, maximum, et un bouton
  pour suivre ce point à l'oscilloscope, et ils sont modélisés
  (10 MΩ, 0,01 Ω) — ils chargent donc le montage, très peu mais réellement.
  Une sonde de tension, elle, ne charge rien : c'est le seul instrument qu'on
  peut greffer n'importe où sans changer le circuit.
- **Nœuds nommés par ce qu'ils relient** : « R1_2 » plutôt que « N3 », comme
  dans KiCad, et chaque liste de signaux dit ce que désigne le nom.
- **Commande unique** façon atelier de calcul : le même bouton lance, met en
  pause et reprend (F9) ; un second arrête et remet les microcontrôleurs à
  zéro. La barre d'état dit en permanence où en est la simulation.
- **Oscilloscope quatre voies avec déclenchement et curseurs** : mode auto,
  normal ou sans, voie et front au choix, niveau réglable — ou automatique,
  calé sur le milieu du signal. Le front se place au cinquième de l'écran,
  laissant voir ce qui l'a précédé. Deux curseurs donnent Δt, ΔV et la
  fréquence correspondante. Formes d'onde réelles issues de l'analyse
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
- **Circuit imprimé, sur sa propre page** : comme Pcbnew est séparé
  d'Eeschema chez KiCad et ARES d'ISIS chez Proteus, la carte n'est pas un
  onglet du schéma. On y va par **« Transférer le schéma vers la carte »**
  (`F8`), qui apporte les composants et les nets, dit ce qui a changé
  (ajoutés, retirés, empreintes modifiées, pistes abandonnées) et **conserve
  le placement et le routage déjà faits**. Le câblage, lui, se refait
  entièrement : le schéma dit *qui* doit être relié à qui — le chevelu —, les
  pistes disent *comment*.
  Les empreintes viennent d'une bibliothèque aux cotes normalisées : DIP à
  deux rangées de 7,62 mm avec broche 1 carrée et détrompeur, résistance
  axiale à 10,16 mm, TO-92, TO-220, LED à méplat, boîtier CMS, bornier à vis
  pour ce qui ne se soude pas (moteur, haut-parleur, pile), et le contour
  réel de l'Arduino Uno avec ses quatre connecteurs et ses trous de fixation.
  Placement à la souris avec accrochage au quart de pas, rotation, routage
  deux couches, contrôle des règles de fabrication, et export **Gerber
  RS-274X** (cuivre, sérigraphie, contour) + **Excellon**.
- **Moteur numérique événementiel**, le troisième : un 74HC595 cadencé à
  plusieurs centaines de kilohertz réagit aux fronts datés du
  microcontrôleur, et ses sorties redeviennent des sources du circuit
  analogique. Ni l'un ni l'autre des deux mondes n'est dégradé au passage.
- **Six analyses paramétriques**, comme dans un atelier de simulation :
  *balayage continu* (`.dc` — caractéristique de transfert, d'une source ou
  d'une résistance), *réponse en fréquence* (`.ac` — diagramme de Bode, gain
  en décibels et phase, avec lecture automatique de la coupure à −3 dB), et
  *spectre* du dernier relevé (raies harmoniques et taux de distorsion),
  *bruit* (`.noise`, vérifié contre 4kTR), *balayage paramétrique* (`.step`,
  courbes superposées) et *Monte-Carlo* (tirage des valeurs dans leur
  tolérance, avec la dispersion obtenue). Les courbes s'affichent dans
  l'onglet **Analyses**, avec axes, légende et curseur de lecture.
- **Générateur de signaux** (sinus, carré, triangle, continu) : c'est lui qui
  rend ces analyses possibles, et il porte les trois descriptions que SPICE
  attend — valeur continue, amplitude alternative, forme d'onde.
- **Mesures d'oscilloscope** sur un signal : minimum, maximum, moyenne, valeur
  efficace, fréquence, rapport cyclique, temps de montée 10–90 %, dépassement.
- **Simulation purement analogique** : un montage sans aucune carte se simule
  quand même — un filtre, un redresseur, un générateur n'ont pas besoin de
  microcontrôleur.
- **Documents produits** : nomenclature (BOM) en CSV avec regroupement des
  composants identiques, **contrôle des règles électriques** (ERC) façon
  KiCad, netlist au **format KiCad** lisible par un logiciel de routage,
  relevés de courbes en CSV, et export du schéma en **PDF vectoriel** ou en
  PNG.
- **Enregistrement** du schéma et du programme dans un fichier `.schema.json`,
  **export** de la netlist SPICE.
- **Plusieurs cartes** sur le même schéma : chacune a son propre cœur AVR et
  son propre programme, choisi dans le sélecteur au-dessus de l'éditeur. Elles
  partagent le circuit et l'horloge, et peuvent donc se parler par leurs
  broches.
- **Neuf exemples** dans le menu *Exemples* : clignotant, bouton avec pull-up,
  potentiomètre sur l'ADC, moteur commandé par transistor, PWM matérielle à
  observer à l'oscilloscope, deux cartes qui communiquent, servomoteur balayé,
  moteur en PWM commandé par transistor, et filtre RC pour les analyses.

Ce que le projet couvre, comparé à Proteus, Multisim, LTspice et KiCad, est
détaillé — sans complaisance — dans [COMPARAISON.md](COMPARAISON.md).

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
- Pas d'**auto-routeur**, de plans de masse ni de vias : le tracé des pistes
  reste manuel, sur deux couches.
- Pas d'**annulation** (`Ctrl+Z`), pas de copier-coller, pas de schéma sur
  plusieurs feuilles, pas d'étiquettes de nœud ni de bus.
- Le **modèle de transistor bipolaire** du solveur intégré est un Ebers-Moll
  avec effet Early, plus simple que le Gummel-Poon de ngspice : l'écart
  mesuré est de vingt millivolts sur un montage à diode et transistor. Les
  capacités de jonction ne sont pas modélisées non plus — sans effet aux
  fréquences des montages traités ici, mais c'est une limite réelle.
- Un seul **type** de microcontrôleur pris en charge : ATmega328P (Arduino
  Uno). On peut en poser plusieurs, mais pas d'autre modèle.

---

## Construire et lancer

### De quoi a-t-on vraiment besoin ?

**Un compilateur C++17 et Qt 6.** C'est tout ce qu'il faut pour construire le
projet, simuler un circuit **et exécuter un firmware** : le solveur analogique
et le cœur ATmega328P font partie des sources. Aucune bibliothèque de
simulation à télécharger, aucune DLL à poser à côté de l'exécutable.

Le reste est facultatif et n'ajoute que ce qui est écrit en face :

| Ce qu'on installe | Ce que ça ajoute |
|---|---|
| **Qt 6 seul** | **tout** : tensions, courants, LED qui s'allument, oscilloscope, multimètres, Bode, spectre, bruit, Monte-Carlo, circuit imprimé, documents — et l'exécution d'un firmware `.elf` ou `.hex` sur l'ATmega328P. |
| **+ avr-gcc** | écrire et compiler le programme *dans* l'application (`F5`). Sans lui, on charge un `.elf` produit ailleurs (IDE Arduino). |
| *+ ngspice* | un **second moteur** analogique. N'apporte rien à l'usage : il sert à confronter le solveur intégré à la référence dans les tests. |
| *+ simavr* | un **second cœur** AVR, pour la même raison. |

La barre d'état indique en permanence quels moteurs tournent.

Une remarque honnête : **`avr-gcc` ne peut pas être embarqué** — c'est un
compilateur C complet, et c'est la seule chose qui reste à installer si l'on
veut écrire un programme AVR depuis l'application.

### Linux (Debian, Ubuntu)

```bash
# Le strict nécessaire :
sudo apt install build-essential cmake qt6-base-dev

# Pour compiler un programme AVR depuis l'application :
sudo apt install gcc-avr avr-libc

# Facultatif : les moteurs de référence, pour les tests de comparaison.
sudo apt install libngspice0-dev libsimavr-dev libelf-dev

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)

./build/tests_coeur                        # 250 tests, sans Qt
QT_QPA_PLATFORM=offscreen ./build/tests_schema   # 137 tests, sans fenêtre
./build/simulateur                         # l'application
```

### Windows 11

Il n'y a plus qu'une chose à trouver : **Qt 6**. Le plus court chemin est
**MSYS2**, qui le fournit en paquet — pas de zip à décompresser, pas de chemin
à donner à CMake. (Cette machine est
sous Linux : ces commandes viennent des paquets MSYS2 réellement publiés, mais
je n'ai pas pu exécuter la compilation moi-même. Si quelque chose accroche,
le message d'erreur exact est ce qui permettra de corriger cette page.)

Qt 6.11 convient : le projet ne demande que `Qt6::Widgets` et des interfaces
stables depuis Qt 6.3. Si Qt est déjà installé chez vous, sautez au paragraphe
« Si Qt est déjà installé » plus bas.

1. Installer [MSYS2](https://www.msys2.org/), puis ouvrir le raccourci
   **« MSYS2 UCRT64 »** — pas « MSYS2 MSYS », c'est l'erreur classique : les
   paquets `mingw-w64-ucrt-x86_64-…` n'y sont pas visibles.

2. Le nécessaire — et c'est tout (schéma + toute la simulation électrique) :

   ```bash
   pacman -Syu                       # puis rouvrir le terminal si demandé
   pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja mingw-w64-ucrt-x86_64-qt6-base
   ```

3. Compiler et lancer :

   ```bash
   cd /c/chemin/vers/simulateur
   cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
   cmake --build build
   ./build/simulateur.exe
   ```

   Sous Windows, les DLL de Qt sont déposées automatiquement à côté de
   l'exécutable à la fin de chaque compilation (`windeployqt`, livré avec
   Qt). L'exécutable produit démarre donc au double-clic, sans rien dans le
   `PATH`.

4. Pour vérifier que tout fonctionne : *Exemples → Filtre RC*, puis onglet
   *Analyses → Réponse en fréquence → Lancer*. La coupure annoncée sous la
   courbe doit tomber vers 1591 Hz.

5. **Au quotidien, ensuite.** Rien de tout cela n'est à refaire : le dossier
   `build` garde en mémoire le compilateur et les chemins donnés à CMake, et
   les DLL déposées à côté de l'exécutable y restent. Après chaque
   modification récupérée :

   ```powershell
   git pull
   cmake --build build
   .\build\simulateur.exe
   ```

   Ninja ne recompile que ce qui a changé, et relance CMake tout seul si la
   recette de compilation a été modifiée. Le script `.\outils\maj.ps1` fait
   les trois d'un coup — et `.\outils\maj.ps1 -Paquet` refait en plus
   l'archive portable.

   Une seule chose annule tout : **effacer le dossier `build`**. Ne le faites
   que pour changer de compilateur ou de chemin — il faut alors reprendre la
   commande `cmake` complète, puis `windeployqt`.

6. Pour la partie Arduino, en plus :

   ```bash
   pacman -S --needed mingw-w64-ucrt-x86_64-avr-gcc \
                      mingw-w64-ucrt-x86_64-avr-libc
   ```

   Et c'est tout : **simavr n'est plus nécessaire** (il n'existe d'ailleurs
   en paquet MSYS2 sous aucune forme — l'ancienne version de cette page
   l'affirmait, c'était faux). Le cœur ATmega328P est dans les sources du
   projet.

   **`avrtest` ne remplace pas simavr.** C'est le simulateur de la suite de
   tests d'avr-gcc : un exécutable autonome qui exécute un `.elf` et imprime
   un résultat. Il n'expose aucune bibliothèque, donc aucun moyen de dater les
   changements d'état des broches ni d'injecter une tension sur une entrée —
   c'est précisément ce dont le couplage avec le circuit a besoin.

#### Annexe : ajouter ngspice (facultatif)

Rien de ce qui suit n'est nécessaire. Le solveur intégré calcule tout. On
n'installe ngspice que pour disposer du **second moteur** et faire tourner les
tests de comparaison ; à l'usage, l'application se comporte de la même façon.

Sur SourceForge, deux archives se ressemblent et une seule convient — j'ai
ouvert les deux pour en avoir le cœur net :

| Archive | Contenu | Utilisable ici |
|---|---|---|
| `ngspice-46_64.7z` (10,7 Mo) | `bin/ngspice.exe`, l'application autonome | ❌ ni DLL ni en-tête : rien à quoi se lier |
| **`ngspice-46_dll_64.7z`** (4,4 Mo) | `include/ngspice/sharedspice.h`, `dll-vs/ngspice.dll`, `lib/lib-vs/ngspice.lib` | ✅ c'est celle-ci |

La description SourceForge de la bonne archive dit « shared ngspice dll,
64 bit (VS) ». Décompressée, elle donne un dossier `Spice64_dll` ; c'est ce
dossier qu'on désigne à CMake :

```powershell
cmake -S . -B build -DNGSPICE_ROOT="C:/Spice64_dll" -DCMAKE_PREFIX_PATH="C:/Qt/6.11.1/mingw_64"
```

Sur une seule ligne : dans PowerShell, la continuation de ligne est l'accent
grave `` ` ``, pas le `^` de l'invite de commandes. Un `^` en fin de ligne y
est pris pour un argument, et la ligne suivante pour une commande à part —
CMake se configure alors sans ce qu'on croyait lui donner.

Au lancement, `ngspice.dll` **et** `libomp140.x86_64.dll` (livrée à côté)
doivent être trouvables : le plus simple est de les copier près de
`simulateur.exe`.

#### Si Qt est déjà installé par l'installateur officiel (qt.io)

Inutile de le réinstaller. Deux cas, selon le compilateur choisi avec Qt.

**Qt MinGW** :

```powershell
cmake -S . -B build -DCMAKE_PREFIX_PATH="C:/Qt/6.11.1/mingw_64"
cmake --build build
```

Ajoutez `C:\Qt\6.11.1\mingw_64\bin` au `PATH` avant de lancer l'exécutable,
ou lancez `windeployqt` sur `simulateur.exe`. Il n'y a rien d'autre à copier.

**Le compilateur doit être celui de Qt.** Qt livre le sien dans
`C:\Qt\Tools\mingw*\bin` ; c'est celui avec lequel les bibliothèques Qt que
vous avez téléchargées ont été construites. Un autre MinGW (WinLibs,
w64devkit) compile bien tout le projet, mais **échoue à l'édition de liens** :

```
libQt6EntryPoint.a(qtentrypoint_win.cpp.obj): undefined reference to `__imp___argc'
```

`Qt6EntryPoint` est une bibliothèque **statique** livrée par Qt : elle contient
du code déjà compilé, qui réclame des symboles que les mingw-w64 récents ne
fournissent plus sous cette forme. Aucun réglage du projet ne peut la
convaincre ; il faut le compilateur d'origine :

```powershell
dir C:\Qt\Tools          # repérer le mingwXXXX_64 installé
Remove-Item -Recurse -Force build
cmake -S . -B build -G Ninja -DCMAKE_CXX_COMPILER="C:/Qt/Tools/mingw1310_64/bin/g++.exe" -DCMAKE_PREFIX_PATH="C:/Qt/6.11.1/mingw_64"
cmake --build build
```

(Ajustez `mingw1310_64` au dossier réellement présent. S'il n'y en a aucun,
ouvrez le *Qt Maintenance Tool* et cochez *Developer and Designer Tools →
MinGW 64-bit* : c'est un téléchargement, pas une réinstallation de Qt.)

**Dépannage, si vous voulez voir tourner l'application tout de suite** avec le
compilateur que vous avez déjà : `-DFENETRE_WIN32=OFF`. Qt6EntryPoint n'entre
alors plus dans l'édition de liens et tout se lie, au prix d'une fenêtre de
console qui reste ouverte derrière l'application.

```powershell
cmake -S . -B build -DFENETRE_WIN32=OFF -DCMAKE_PREFIX_PATH="C:/Qt/6.11.1/mingw_64"
```

**Qt MSVC** :

```powershell
cmake -S . -B build -DCMAKE_PREFIX_PATH="C:/Qt/6.11.1/msvc2022_64"
cmake --build build --config Release
```

C'est faisable, mais c'est trois fois plus de manipulations que MSYS2.

---

## Un paquet portable

Le projet sait produire une archive qui contient tout : l'exécutable, Qt, et
rien à installer sur la machine d'accueil. Elle se décompresse où l'on veut —
y compris sur une clé USB — et se lance par un double-clic.

```powershell
# Windows
.\outils\paquet.ps1                     # ou : .\outils\paquet.ps1 -Qt "C:\Qt\6.11.1\mingw_64"
```

```bash
# Linux
./outils/paquet.sh
```

Le résultat s'appelle `simulateur-embarque-<version>-windows-x64.zip` ou
`…-linux-x64.tar.gz`, dans `build-paquet/`. Il contient l'exécutable, les
bibliothèques de Qt, les greffons de plate-forme, la documentation et un
`LISEZ-MOI.txt`.

Deux détails qui font que ça marche :

* **`-DSIM_AUTONOME=ON`**, posé par les deux scripts, fait ignorer ngspice et
  simavr même s'ils sont installés sur la machine de compilation. Le paquet ne
  dépend alors que de Qt : les moteurs de simulation sont dans l'exécutable.
* Le déploiement de Qt est confié à **`windeployqt`** sous Windows (il sait
  exactement quelles DLL et quels greffons emporter, y compris la
  bibliothèque d'exécution de MinGW), et sous Linux à
  `file(GET_RUNTIME_DEPENDENCIES)` qui résout les bibliothèques partagées, en
  écartant celles qui doivent venir du système (la bibliothèque C, le
  chargeur, les pilotes graphiques). Un lanceur `simulateur.sh` désigne le
  dossier `lib`.

Ce que je peux affirmer et ce que je ne peux pas : **le paquet Linux est
vérifié ici** — 36 Mo compressés, décompressé dans un dossier neuf, lancé
avec un environnement vidé (`env -i`), il charge bien Qt depuis son propre
`lib/`, compile le croquis, exécute le firmware et simule le circuit (D13 à
49,8 % de rapport cyclique, 4,68 V de crête). **Le paquet Windows est écrit
mais n'a pas pu être exécuté d'ici** : cette machine est sous Linux. La
mécanique est celle que Qt documente pour ce cas ; si quelque chose accroche,
le message exact permettra de corriger.

Pour aller au bout, un **installateur** (NSIS via CPack) se rajoute sur la
même base — mais une archive portable, elle, ne demande aucun droit
d'administration.

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
│   │   ├── analysis/                  balayages, mesures, spectre, campagnes
│   │   ├── export/                    nomenclature, ERC, netlist KiCad
│   │   ├── pcb/
│   │   │   ├── Empreintes.{h,cpp}     bibliothèque de boîtiers aux cotes réelles
│   │   │   └── Pcb.{h,cpp}            placement, chevelu, DRC, Gerber, Excellon
│   │   └── engines/
│   │       ├── noyau_arduino.h        le noyau Arduino, embarqué en texte
│   │       ├── SolveurIntegre.{h,cpp} le solveur analogique du projet (MNA,
│   │       │                          Newton, trapèzes) — aucune dépendance
│   │       ├── ExpressionSpice.{h,cpp} expressions des sources « B »
│   │       ├── NgspiceEngine.{h,cpp}  façade : construit le circuit, choisit
│   │       │                          le solveur intégré ou ngspice
│   │       ├── MoteurNumerique.{h,cpp} fronts datés → événements → sources
│   │       └── AvrEngine.{h,cpp}      firmware → cycles → états de broches
│   └── app/                         ← tout ce qui dépend de Qt
│       ├── FenetrePrincipale.{h,cpp}  les deux pages : schéma et carte
│       ├── MoteurSimulation.{h,cpp}   couplage des moteurs
│       ├── Oscilloscope.{h,cpp}       quatre voies, tracé min/max
│       ├── panels/
│       │   ├── PanneauAnalyses.{h,cpp}  les six analyses
│       │   ├── PanneauPcb.{h,cpp}       la page circuit imprimé
│       │   └── FenetreInstrument.{h,cpp}
│       └── schematic/                 bibliothèque à part, donc testable
├── outils/
│   ├── generer_figures.cpp          schémas SVG pour les cours
│   ├── figures_liste.inc            les montages, décrits en données
│   ├── paquet.cmake                 déploiement du paquet portable
│   ├── paquet.ps1 / paquet.sh       « faites-moi une archive qui marche »
│   └── LISEZ-MOI.txt.in             mot d'accueil livré dans le paquet
└── tests/
    ├── test_coeur.cpp                250 tests, sans Qt
    └── test_schema.cpp               137 tests, saisie de schéma sans fenêtre
```

La séparation `core` / `app` n'est pas décorative : `core` ne connaît pas Qt
et se teste sans écran. Le module de circuit imprimé en est la démonstration —
placement, chevelu, règles de fabrication et fichiers Gerber sont calculés
dans `core/pcb`, sans une ligne d'interface, et vérifiés sans ouvrir de
fenêtre.

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
    m.empreinte = {"R_AXIAL_0207", {}, 12.0, 3.0};        // le nom du boîtier suffit
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

**250 tests du cœur**, sans Qt, en vingt-deux sections :

| Section | Ce qui est vérifié |
|---|---|
| 1 | netlist et catalogue |
| 2 | moteur analogique : LED, surintensité, potentiomètre, pull-up, transistor |
| 3 | simavr : compilation par `avr-gcc`, exécution, horloge au cycle près |
| 4 | **couplage firmware → circuit** : le programme allume la LED, 12,8 mA mesurés |
| 5 | **couplage circuit → firmware** : un niveau imposé est lu par le programme |
| 6 | conversion analogique-numérique |
| 7 | **tout le catalogue** passe dans le moteur analogique |
| 8 | physique des modèles : diode, CTN, LDR, NON-ET, ampli op, 7805, relais |
| 9 | **analyse transitoire** : charge d'un RC comparée à la théorie (3,16 V à une constante de temps), reprise d'état entre fenêtres, PWM à 25 % |
| 12 | **composants à mécanique** : servo à 1,5 ms → 90°, moteur à 63 % après une constante de temps, asynchrone à 1440 tr/min pour 4 % de glissement, courant d'induit qui suit la loi L/R, écho de 5,8 ms pour 1 m |
| 11 | **un croquis Arduino de TP**, compilé sans retouche : millis à la bonne cadence, anti-rebond, machine à états, PWM, Serial |
| 10 | **exemplaires multiples** : cinq de chaque modèle en série, aucun nom d'élément SPICE en double ; dix LED en parallèle qui font s'effondrer la sortie |
| 13 | **mesures et spectre**, confrontés à la théorie : une sinusoïde n'a pas d'harmoniques, un carré a un fondamental à 4A/π, une harmonique 3 au tiers, aucune harmonique paire, et 48,3 % de distorsion |
| 14 | **nomenclature, ERC et exports** : regroupement des composants identiques, LED sans résistance série, borne en l'air, sortie sur une alimentation, deux sources en parallèle, netlist KiCad aux parenthèses équilibrées |
| 22 | **cœur AVR intégré confronté à simavr** : même firmware, mêmes commutations de broche, aux mêmes cycles d'horloge |
| 21 | **solveur intégré confronté à ngspice** : mêmes tensions à 20 mV près sur un montage diode + transistor, même forme d'onde à 20 mV près sur un transitoire, même fréquence de coupure à 2 % près |
| 20 | **circuit imprimé** : placement depuis la netlist, chevelu, règles de fabrication (isolation, largeur, débordement), Gerber et Excellon conformes, cotes des empreintes (DIP à 7,62 mm, résistance à 10,16 mm, broche 1 carrée), brochage réel de l'Uno, transfert schéma → carte qui préserve placement et pistes |
| 19 | **moteur numérique** : un octet décalé à 1 MHz dans un 74HC595, verrouillé, et ses sorties devenues un circuit analogique valable |
| 18 | **campagnes** : trois coupures d'un RC confrontées à 1/(2·pi·R·C), et un pont diviseur à ±5 % dont la dispersion reste dans la tolérance |
| 17 | **température et bruit** : la tension de seuil d'une diode qui baisse avec la chaleur, et le bruit thermique d'une résistance de 10 kΩ confronté à 4kTR (12,9 nV/√Hz) |
| 16 | **multimètres** : position continu et alternatif confrontées à une sinusoïde connue (moyenne 2 V, efficace 3,54 V), et ohmmètre qui injecte réellement son courant d'essai |
| 15 | **balayages** : pont diviseur relevé point par point, filtre RC dont la coupure tombe à 1/(2·π·R·C), −20 dB par décade, −45° à la coupure, balayage d'une résistance, distorsion d'un carré réellement simulé |

Et **137 tests de la saisie de schéma**, sans ouvrir de fenêtre : attribution
des références sur vingt exemplaires, dix LED câblées en parallèle, symboles
d'alimentation répétés, deux cartes sur le même schéma, le panneau
d'analyses (Bode, spectre, exports CSV), le câblage à la souris, le
déclenchement de l'oscilloscope, les étiquettes de nœud, l'annulation, le
presse-papiers, et le transfert du schéma vers la carte — un second transfert
ne touche à rien, retirer un composant du schéma le retire de la carte et
abandonne les pistes de son net.

Une section vérifie qu'**aucun composant ne peint hors du cadre qu'il
déclare** : Qt n'efface que l'intérieur de ce cadre, et tout ce qui dépasse
reste imprimé à l'écran quand l'objet bouge — c'est la traînée d'étiquettes
qu'on voyait en déplaçant un composant. Le test est photographique : chaque
modèle du catalogue est peint seul sur fond blanc, dans les quatre
orientations, et l'on compte les pixels salis au-delà du cadre.

Une autre porte sur les **gestes d'un utilisateur ordinaire**, et
elle est née d'un audit qui a trouvé de quoi la remplir : effacer deux
composants reliés entre eux, effacer celui du milieu d'une chaîne, effacer
sous une vue ouverte, effacer pendant qu'un fil est en cours de tracé,
effacer **pendant que la simulation tourne**, déplacer, superposer, tourner,
câbler deux fois la même paire, annuler, rétablir. Après chaque geste, trois
invariants sont vérifiés : aucun fil ne désigne un composant disparu, la
scène ne contient rien d'autre que des composants et des fils, et le moteur
analogique accepte encore le circuit.

L'application se vérifie aussi sans intervention :

```bash
./build/simulateur --exemple 2 --diagnostic          # netlist, SPICE, tensions
./build/simulateur --capture image.png 2500          # compile, simule, capture
./build/simulateur --exemple 4 --onglet 3 --base 0.005 \
                   --capture pwm.png 6000            # la PWM à l'oscilloscope
./build/simulateur --exemple 5 --onglet 3 --base 2 \
                   --capture deux.png 9000           # les deux cartes
./build/simulateur --exemple 8 --analyse 1           # Bode du filtre RC
./build/simulateur --exemple 8 --analyse 2 2500      # spectre du signal simulé
./build/simulateur --exemple 8 --documents /tmp/doc  # BOM, ERC, KiCad, PDF, PNG
./build/simulateur --exemple 9 --pcb /tmp/carte      # carte, routage, Gerber
```

`--onglet` choisit le panneau du bas (0 programme, 1 journal, 2 série,
3 oscilloscope, 4 analyses), `--base` impose la base de temps en secondes.
`--analyse N` lance l'analyse *N* (0 balayage continu, 1 réponse en fréquence,
2 spectre) et imprime son résultat chiffré ; `--documents` produit tous les
documents du projet et donne la taille de chacun. `--gestes dossier` joue une
séance d'utilisateur — lancer, effacer un composant en pleine simulation,
arrêter, annuler, passer au circuit imprimé et revenir — en photographiant
chaque étape : c'est la vérification des artefacts, celle qu'aucun chiffre ne
montre. La capture
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
| clic gauche sur une borne | tirer un fil (glisser, ou cliquer puis cliquer) |
| clic gauche sur un composant | le sélectionner |
| double-clic sur un instrument | ouvrir sa fenêtre de mesure |
| clic droit | menu des options du composant |
| souris sur la courbe | curseur de lecture ; un clic pose le repère |
| `F9` | lancer, mettre en pause, reprendre |
| `Ctrl+1` / `Ctrl+2` | sortir l'oscilloscope ou les analyses dans leur fenêtre |
| `Alt+1` / `Alt+2` | page schéma / page circuit imprimé |
| `F8` | transférer le schéma vers la carte |
| `F5` | compiler le programme et le charger |
| `Ctrl+N` / `Ctrl+O` / `Ctrl+S` | nouveau, ouvrir, enregistrer |

Pour tirer un fil : outil **Fil**, puis cliquer d'une borne à l'autre.

Sur la page **circuit imprimé** : molette pour zoomer, clic milieu pour
déplacer la vue, `R` fait tourner l'empreinte sous le curseur, `Échap` annule
le tracé en cours, `Retour arrière` défait la dernière piste. Une piste ne se
tire qu'entre deux pastilles d'un même net — relier deux nets différents
serait un court-circuit, pas un oubli.
