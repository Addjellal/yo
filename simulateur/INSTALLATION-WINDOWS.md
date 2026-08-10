# Installation sur Windows — pas à pas

Ce document part de zéro et va jusqu'à un simulateur qui compile et exécute
un programme. Suivez-le dans l'ordre ; chaque étape dit **comment vérifier**
qu'elle a marché avant de passer à la suivante.

Comptez vingt minutes, dont la moitié en téléchargement.

---

## Ce qu'il faut savoir d'abord

Le simulateur a besoin de **compilateurs croisés** pour transformer votre
programme en firmware — un par famille de puce. Ils ne sont pas dans le dépôt,
et ne peuvent pas l'être : ils pèsent des centaines de mégaoctets.

Un script les installe pour vous, en une commande. **C'est la seule étape
supplémentaire après la construction**, et elle ne se fait qu'une fois.

Si vous ne voulez rien installer du tout, sautez à la
[section « Sans aucun compilateur »](#sans-aucun-compilateur) : le simulateur
reste utilisable, avec des limites clairement énoncées.

---

## Étape 1 — Les outils de construction

Il faut trois choses : un compilateur C++, CMake, et Qt 6.

### La façon la plus simple : Qt Online Installer

1. Téléchargez l'installeur sur <https://www.qt.io/download-qt-installer>
   (un compte gratuit est demandé).
2. À l'écran des composants, cochez :
   - **Qt 6.5** ou plus récent → **MSVC 2019 64-bit** *ou* **MinGW 64-bit** ;
   - sous **Developer and Designer Tools** : **CMake** et **Ninja**, et
     **MinGW** si vous n'avez pas Visual Studio.
3. Laissez le reste par défaut.

### Vous vérifiez que ça a marché

Ouvrez **« Qt 6.x (MinGW) command prompt »** dans le menu Démarrer — ou
« x64 Native Tools Command Prompt » si vous êtes passé par Visual Studio — et
tapez :

```
cmake --version
```

Un numéro de version s'affiche : c'est bon. « n'est pas reconnu » : CMake
n'est pas dans le PATH, reprenez l'étape 1.

> **Important** : toutes les commandes de ce document doivent être tapées dans
> cette invite-là, pas dans une invite Windows ordinaire. C'est elle qui
> connaît Qt et le compilateur.

---

## Étape 2 — Construire le simulateur

Placez-vous dans le dossier `simulateur` du dépôt, puis :

```
cmake -S . -B build
cmake --build build --config Release -j 8
```

La première commande prépare, la seconde compile. Comptez quelques minutes.

### Vous vérifiez que ça a marché

```
build\simulateur.exe
```

La fenêtre s'ouvre, avec un schéma d'exemple : une carte Arduino Uno, une LED
et une résistance. **À ce stade tout fonctionne sauf la compilation de
programmes** — c'est l'étape 3.

### Si CMake ne trouve pas Qt

Indiquez-lui où il est, en adaptant le chemin à votre installation :

```
cmake -S . -B build -DCMAKE_PREFIX_PATH="C:/Qt/6.5.3/mingw_64"
```

---

## Étape 3 — Les compilateurs croisés

Une seule commande, depuis le dossier `simulateur` :

```
powershell -ExecutionPolicy Bypass -File outils\chaines.ps1
```

Elle télécharge et installe **AVR** (Arduino, ATtiny, ATmega) et **ARM**
(Raspberry Pi Pico, STM32), soit environ 370 Mo décompressés, dans
`build\chaines\`.

Autres possibilités :

| Commande | Ce qu'elle installe |
|---|---|
| `...\chaines.ps1` | AVR et ARM — les deux qui servent le plus |
| `...\chaines.ps1 -Tout` | ajoute Xtensa (ESP32), ~400 Mo de plus |
| `...\chaines.ps1 -Avr` | AVR seulement, si vous ne faites que de l'Arduino |

Le simulateur cherche ces compilateurs **à côté de lui** avant de regarder
dans le PATH : le dossier `build` devient autosuffisant et peut être copié
tel quel sur une autre machine.

### Vous vérifiez que ça a marché

Relancez `build\simulateur.exe` et regardez l'onglet **Journal** en bas. Les
trois premières lignes doivent dire :

```
AVR (Arduino, ATtiny) : embarqué dans le paquet (...)
ARM (Pi Pico, STM32) : embarqué dans le paquet (...)
```

Si vous lisez encore « absent », le script n'a pas abouti — voir
[« Quand ça ne marche pas »](#quand-ça-ne-marche-pas).

---

## Étape 4 — L'essai complet

Dans le simulateur :

1. **Exemples ▸ Clignotant sur D13** — le schéma se met en place.
2. **F5** (ou Simulation ▸ Compiler et charger).
   Le journal doit afficher **« Compilation réussie. »**
3. **F9** (ou ▶ Lancer).
   La LED du schéma clignote, une demi-seconde allumée, une demi-seconde
   éteinte.

Si vous voyez la LED clignoter, **tout fonctionne**.

---

## Sans aucun compilateur

Le simulateur reste utile sans l'étape 3, mais il faut savoir ce qui marche
et ce qui ne marche pas.

**Ce qui marche :**

- dessiner un schéma, poser des composants, les câbler ;
- **lancer la simulation analogique** : alimentations, résistances, diodes,
  transistors, filtres. Voltmètres, ampèremètres et oscilloscope affichent
  leurs mesures ;
- toutes les analyses : point de repos, balayage continu, réponse en
  fréquence, spectre, bruit, Monte-Carlo ;
- le circuit imprimé : empreintes, routage automatique, export Gerber ;
- **charger un firmware déjà compilé** par Simulation ▸ Charger un
  firmware (.elf) — venant par exemple de l'IDE Arduino.

**Ce qui ne marche pas :** compiler un programme depuis l'application.

Quand aucun firmware n'est chargé, la carte reste **inerte** — ses broches en
entrée haute impédance, ce qui est l'état physique d'un microcontrôleur non
programmé. La simulation démarre quand même et le reste du circuit est
calculé normalement.

---

## Quand ça ne marche pas

### « chaines.ps1 : l'exécution de scripts est désactivée »

Windows bloque les scripts PowerShell par défaut. Le `-ExecutionPolicy Bypass`
de la commande donnée plus haut contourne cela pour cette exécution seulement,
sans rien changer aux réglages de la machine. Vérifiez que vous l'avez bien
tapé.

### Le téléchargement échoue, ou l'entreprise filtre le réseau

Les archives peuvent être posées à la main. Téléchargez celle qu'il vous faut,
décompressez-la, et placez **l'arbre entier** de sorte que le chemin soit :

```
build\chaines\avr\bin\avr-g++.exe
build\chaines\arm\bin\arm-none-eabi-gcc.exe
build\chaines\xtensa\bin\xtensa-esp32-elf-gcc.exe
```

> **Ne copiez pas seulement `bin\`.** GCC cherche ses fichiers de support
> (`device-specs`, `lib`, `include`) par un chemin relatif à son propre
> binaire. Un `bin\` isolé échoue avec un message aussi obscur que
> `device-specs/specs-atmega328p: No such file or directory`.

Sources officielles :

- AVR — <https://github.com/ZakKemble/avr-gcc-build/releases>
- ARM — <https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads>
- Xtensa — <https://github.com/espressif/crosstool-NG/releases>

### « Aucun compilateur trouvé pour atmega328p »

L'étape 3 n'a pas abouti, ou l'arbre a été copié au mauvais endroit. Vérifiez
que le fichier `build\chaines\avr\bin\avr-g++.exe` existe vraiment.

### J'appuie sur Lancer et la LED ne clignote pas

Regardez le journal. S'il dit **« Aucun firmware »**, c'est qu'aucun programme
n'a été compilé ni chargé : faites F5 d'abord. La simulation tourne quand même,
mais la carte n'exécute rien.

### La fenêtre ne s'ouvre pas, ou se ferme aussitôt

Il manque les DLL de Qt à côté de l'exécutable. Depuis l'invite Qt :

```
windeployqt build\simulateur.exe
```

---

## Ce que vous pouvez emporter

Une fois l'étape 3 faite, le dossier `build` contient tout : l'exécutable, les
DLL de Qt et les compilateurs. Copiez-le sur une clé, il fonctionne sur une
autre machine Windows sans rien installer.

Pour en faire une archive propre :

```
cmake --build build --target package
```
