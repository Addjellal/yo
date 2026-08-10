# État du projet — simulateur de circuits

Document de reprise. Il dit ce qui existe, ce qui est vérifié **et comment**,
ce qui est cassé, et ce qui reste. À tenir à jour : c'est lui qu'on relit
quand le fil de la conversation est perdu.

## Ce que c'est

Un simulateur de circuits façon Proteus : schéma, simulation analogique,
microcontrôleurs exécutés pour de vrai, circuit imprimé. C++17 + Qt6.

Branche de travail : `claude/auto-job-application-system-3Q2iB`.
(L'en-tête de session mentionne une autre branche — elle est périmée, ignorée
depuis plusieurs sessions.)

Construction : `cmake -S . -B build && cmake --build build -j8`
Bancs d'essai : `./build/tests_coeur` et `QT_QPA_PLATFORM=offscreen ./build/tests_schema`

## Les trois moteurs

| Moteur | Fichiers | Exactitude |
|---|---|---|
| Analogique | `SolveurIntegre.{h,cpp}`, `NgspiceEngine.{h,cpp}` | confronté à ngspice |
| AVR | `CoeurAvr.{h,cpp}`, `AvrEngine.{h,cpp}` | exact au cycle, confronté à simavr |
| Cortex-M | `CoeurCortexM.{h,cpp}`, `CortexEngine.{h,cpp}` | exact au cycle (tables ARM) |
| Xtensa | `CoeurXtensa.{h,cpp}`, `XtensaEngine.{h,cpp}` | **pas** exact au cycle — voir plus bas |
| Numérique | `MoteurNumerique.{h,cpp}` | événementiel |

`Microcontroleur.h` est l'interface commune : c'est le seul endroit à
compléter pour ajouter une architecture.

## Les neuf cartes

`src/core/catalogue/cartes.cpp`. Chacune porte `mcu`, `horloge`,
`tension_logique`, `langage` et `note_langage` (les langages réels de la
carte, ce que le simulateur accepte, et les écarts).

arduino_uno · arduino_nano · arduino_pro_mini · atmega328p (nu) · attiny85 ·
arduino_mega · pi_pico · stm32f103 · esp32

Trois écarts d'horloge assumés, écrits dans `note_langage` et vérifiés par le
banc [40] : l'ATtiny85 sort d'usine à 1 MHz (fusible CKDIV8), le RP2040
démarre à ~6 MHz sur son oscillateur en anneau, le STM32F103 à 8 MHz sur son
oscillateur interne. Le simulateur part de la fréquence nominale dans les
trois cas.

## Chaînes de compilation

- **AVR** : `avr-g++`, présent (paquets `gcc-avr`, `avr-libc`).
- **ARM** : `arm-none-eabi-gcc` installé ; `clang` fait aussi l'affaire.
- **Xtensa** : **ABSENTE**. Le proxy renvoie 403 sur les publications GitHub
  d'Espressif et il n'y a pas de paquet Debian. L'ESP32 se vérifie via
  `llvm-mc` comme assembleur indépendant, et un `.elf` déjà compilé se charge.
  `outils/chaines.sh` dit où déposer la chaîne — **l'arbre entier**, pas
  seulement `bin/`, sinon GCC ne trouve pas ses fichiers de support.

`chaines::etat()` interroge les moteurs eux-mêmes, pas un nom d'exécutable :
annoncer « ARM absent » quand clang est là avait envoyé des gens installer
l'inutile.

## Programmes en plusieurs fichiers

`coeur::Programme` = liste de `Fichier{nom, contenu}`. Règles d'un projet
Arduino, et pas d'autres :

- le **premier** fichier est le principal ;
- un `.h` est déposé à côté, jamais compilé seul ;
- un `.c`/`.cpp` est une unité de compilation à part ;
- un `.ino` n'en est **pas** une : les onglets de croquis sont **fondus** en
  un seul fichier, comme le fait l'IDE Arduino ;
- le dossier de compilation est dans le chemin d'inclusion.

Différence assumée avec l'IDE : les onglets annexes passent **avant** le
principal, au lieu que l'IDE fabrique des prototypes par analyse syntaxique
approximative. Chaque morceau porte un `#line` : une faute est signalée dans
le bon onglet.

Interface : barre d'onglets au-dessus de l'éditeur, cachée tant qu'il n'y a
qu'un fichier. Format de projet : tableau `{nom, contenu}` par carte (l'ordre
compte). Les projets d'avant se relisent.

**Chaque carte compile dans SON dossier**, vidé avant chaque compilation :
sans cela U2 pouvait inclure le `mesure.h` de U1 sans un mot, et un fichier
retiré survivait sur le disque.

## Convertisseur analogique daté

`Microcontroleur::definir_source_adc` : la puce demande la tension **au
moment où elle convertit**, en donnant son compteur de cycles. Le couplage
relit la forme d'onde déjà calculée — retard d'une fenêtre, sans effet sur un
spectre d'amplitude puisque chaque échantillon subit le même retard.

Avant cela, le couplage ne rafraîchissait les entrées que toutes les 5 ms :
**tout firmware échantillonnant plus vite que 200 Hz était mal simulé**.

`MoteurSimulation::avancer_simule(secondes)` fait avancer sans minuteur —
sans elle aucun banc ne peut vérifier le couplage.

## Analyseur d'impédance embarqué

Le projet qui a motivé tout ce qui précède. La carte excite un RLC série
(1 H, 220 nF, shunt 470 Ω), échantillonne 8 fois par période **en phase avec
son propre créneau**, et extrait la raie 1 par une TFD (transformée de Fourier
discrète) à 8 points en virgule fixe.

`analyseur.h` (= `kAnalyseurCommun`) porte la TFD, partagé. Racine carrée
**entière** par Newton : sur un ATtiny85 la bibliothèque flottante prend plus
de place que le programme entier.

Pourquoi la TFD et pas un détecteur de crête : un créneau contient ses
harmoniques impaires, et à 150 Hz l'harmonique 3 tombe près de la résonance.
Un détecteur de crête mesure ce mélange. **Attention** : avec 8 points, la
raie 1 rejette exactement les harmoniques 3 et 5, mais les **7 et 9 se
replient dessus** — un commentaire du code affirmait le contraire, c'est faux
et corrigé.

Deux précautions trouvées à la mesure : chauffer ~40 ms avant de compter, et
éviter les fréquences multiples de 200 Hz (commensurables avec la fenêtre de
couplage de 5 ms) — les corriger a divisé l'erreur par deux.

Relevé obtenu (Uno), contre |R + j(ωL − 1/ωC)| avec R = 495 Ω :

```
150 Hz 3259 (3913)   300 Hz  628 (724)   455 Hz 1844 (1362)
210 Hz 2351 (2182)   339 Hz  630 (495)   590 Hz 2885 (2531)
260 Hz 1091 (1251)   390 Hz 1435 (774)   810 Hz 2397 (4225)
```

Le minimum tombe sur la résonance, l'ordre de grandeur est bon, **390 et
810 Hz s'écartent nettement** et la cause n'est pas cherchée.

## Bancs d'essai — 386 (cœur) + 177 (schéma)

Sections notables :

- **[38]** bobines RL et RLC confrontées aux formules fermées, module et
  phase, point par point. Piège : la surtension aux bornes de C ne vaut pas Q
  mais `Q/√(1−1/4Q²)` et ne tombe pas sur f0.
- **[35]** cycles ARM, mesure **différentielle** (même séquence, deux nombres
  de tours) : le cadre du compilateur s'annule. Sans cela on mesurait aussi
  le compilateur.
- **[39]** programmes multi-fichiers, les trois formes.
- **[41]** liaison série ARM et Thumb-2 conditionnel.
- **[42]/[43]** les montages du cours (voir plus bas).

## Ce qui est propre, et par quel moyen

- **ASan + UBSan** : 386 tests, zéro alerte (voir le point 4 plus bas pour la
  commande). C'est cette passe qui avait trouvé neuf décalages signés
  débordants dans les trois cœurs.
- **Construction ordinaire** : zéro avertissement.
- **ngspice** comme référence analogique indépendante, **simavr** pour l'AVR,
  **llvm-mc** pour le Xtensa, les tables publiées par ARM pour le Cortex-M.

## Défauts trouvés et corrigés (les instructifs)

**Cœur ARM**, trouvés en installant le vrai `arm-none-eabi-gcc` — clang les
masquait tous :

1. `-masm-syntax-unified` manquait : GCC refusait `subs r0, #1`, la forme des
   manuels ARM.
2. **`CBZ`/`CBNZ` non décodées.**
3. **Le bloc `IT` non décodé** — le plus grave. GCC en émet à chaque
   expression conditionnelle : **toute condition d'un firmware STM32 était
   fausse**, en silence. Une somme rendait 210 au lieu de 147. Deux pièges :
   une instruction sautée doit être enjambée (2 ou 4 octets), et une
   instruction dans un bloc IT **ne met pas à jour les drapeaux**.
4. `-nostdlib` écartait aussi **libgcc** : un Cortex-M0+ n'a pas de diviseur,
   le moindre `a / b` ne se liait pas.
5. SysTick ne compte que sur **24 bits** : comparer deux instants sur 32 bits
   bloque la boucle d'attente au premier repassage par zéro.
6. Aucune **liaison série** n'était modélisée côté ARM. `ProfilSerie` la
   décrit. RP2040 : UART0 PL011 à `0x40034000`, données `0x000`, drapeaux
   `0x018`, bit 5 = « file PLEINE », attendu à **zéro**. STM32F1 : USART1 à
   `0x40013800` (confirmé par l'en-tête CMSIS de ST), état `0x00`, données
   `0x04`, bit 7 = TXE, attendu à **un**. Conventions opposées.

**Solveur analogique** :

7. **Zener en régulation** : ne convergeait pas sous 10 V d'entrée. Cause :
   le modèle basculait d'une branche à l'autre à V = −BV et le courant y
   **sautait de 0 à IBV**. Newton ne traverse pas une discontinuité.
   Formulation reprise de `diotemp.c` de ngspice :
   `I = −IS × (exp(−(V+vb)/vt) − 1 + vb/vt)`, où **vb ≠ BV** mais est ajusté
   par itération de point fixe pour que le courant vaille IBV à V = BV.
   Écart à ngspice : < 5 mV sur l'essentiel, 25 mV au pire.
8. **Pas sur les sources** ajouté (seconde méthode de secours de SPICE). La
   rampe de gmin rend le circuit résistif ; elle n'aide pas quand le problème
   est le *chemin* vers la solution.

**Analyse alternative** : le solveur ne relevait **aucun courant** en `.ac`.
`courants_alternatifs()` les déduit. Le panneau les affiche en dBA.

## Ce qui est cassé ou inachevé

1. **Analyseur Pi Pico** : ~~bloqué~~ **réparé**. Il achève son balayage
   complet et publie ses neuf points. Deux défauts du cœur ARM le bloquaient,
   tous deux silencieux (voir plus bas) : la retenue d'ADC/SBC, et le
   décalage par registre de rang nul.

   **Analyseur STM32 : toujours bloqué**, et c'est le fil à reprendre. État
   précis de la traque, pour ne pas la refaire :

   - il publie son en-tête, puis se bloque dans sa PREMIÈRE `mesurer` ;
   - le jalon posé au début de la boucle de chauffe n'est **jamais atteint** :
     le blocage est donc entre l'entrée de `mesurer` et sa première itération ;
   - `attendre_jusque` a été isolée et testée sur les DEUX puces : elle marche
     (vingt attentes successives, jalon à chaque fois) ;
   - les deux calculs d'en-tête de `mesurer` ont été isolés et testés sur le
     STM32 : `72000000u / (f * 8u)` rend bien 60000, et `(f*40L)/1000L + 2`
     rend bien 8 ;
   - restent donc, entre les deux : `instant = maintenant()` et les deux
     écritures `*re = 0; *im = 0;`. Ou bien le jalon lui-même est mal posé et
     il faut le vérifier avant de conclure.

   Méthode qui a marché sur le Pico et qu'il faut reprendre : instrumenter le
   programme avec des jalons émis sur la liaison série, resserrer jusqu'à
   l'instruction, puis isoler celle-ci dans un programme de trois lignes.

   **MAIS il y a bien mieux à faire, et c'est la vraie piste.** Les trois
   défauts du cœur ARM (bloc IT, retenue d'ADC/SBC, décalage par registre) ont
   tous été trouvés à la main, un par un. C'est parce que l'ARM est la SEULE
   architecture pour laquelle il n'existe pas de référence indépendante ici :
   l'AVR a simavr, le Xtensa a llvm-mc, l'analogique a ngspice. L'ARM n'a rien.

   `qemu-system-arm` est disponible en paquet (`apt`, version 8.2). Il émule
   le Cortex-M et sait charger un .elf nu. Renode s'appuie d'ailleurs sur
   `tlib`, dérivé du même moteur QEMU — c'est la même référence par un autre
   chemin.

   Ce qu'il faut bâtir : faire tourner le MÊME firmware des deux côtés et
   comparer registre par registre à chaque instruction, comme la section [22]
   le fait déjà pour l'AVR contre simavr. Cela transformerait la chasse aux
   défauts ARM — de « instrumenter et deviner » à « la divergence est à
   l'instruction n ». C'est ce qui a rendu le cœur AVR fiable.

   **QEMU EST INSTALLÉ ET LA FAISABILITÉ EST PROUVÉE** (`qemu-system-arm`
   8.2.2, paquet `qemu-system-arm`). Voici ce qu'il a fallu trouver, pour ne
   pas le rechercher :

   - QEMU n'a pas de machine STM32 ni RP2040, mais ce n'est pas nécessaire :
     `mps2-an385` donne un Cortex-M3 générique et `microbit` un Cortex-M0.
     C'est le CŒUR qu'on compare, pas les périphériques ;
   - il faut une TABLE DE VECTEURS, sans quoi la machine part en HardFault
     immédiat (« Lockup: can't escalate 3 to HardFault »). Un Cortex-M lit sa
     pile initiale à l'adresse 0 et son point d'entrée à 4 :

     ```c
     __attribute__((section(".vectors"), used))
     void* const table[2] = { (void*)0x20008000u, (void*)_start };
     ```
     ```
     arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -masm-syntax-unified \
       -nostdlib -ffreestanding -Os -Wl,-e,_start \
       -Wl,--section-start=.vectors=0x00000000 -Wl,-Ttext=0x00000100 \
       -o firmware.elf source.c -lgcc
     ```

   - la trace s'obtient ainsi, un bloc de registres par instruction :

     ```
     qemu-system-arm -M mps2-an385 -cpu cortex-m3 -nographic \
       -kernel firmware.elf -d cpu -singlestep -D trace.log
     ```

     Format : `R00=…` à `R15=…` puis `XPSR=…`. Vérifié sur une division
     logicielle : 3,26 millions d'instructions tracées, R07 = 0x0f pour
     150/10. C'est exactement la forme qu'il faut pour comparer.

   Reste à écrire : le producteur de trace équivalent côté `CoeurCortexM`, et
   le comparateur qui s'arrête à la première divergence.
2. **Analyseur ATmega328P nu, ATtiny85, ESP32** : pas écrits. L'ATtiny n'a
   pas d'UART matériel (sortie à inventer) ; l'ESP32 n'a **pas d'ADC
   modélisé** dans le cœur Xtensa.
3. **Entrée de menu** « Exemples ▸ Analyseur d'impédance » : n'existe pas. Le
   montage n'est accessible que depuis le banc d'essai.
4. ~~Sanitizers non automatisés.~~ **Fait.** Option `SANITISER`, étiquette
   ctest `sanitiseurs`, construction séparée (on n'assainit pas un binaire
   déjà compilé) :

   ```
   cmake -S . -B build-san -DSANITISER=ON -DCMAKE_BUILD_TYPE=Debug
   cmake --build build-san -j8 --target tests_coeur
   ctest --test-dir build-san -L sanitiseurs
   ```

   Dernière passe : **386 tests, zéro alerte** ASan et UBSan. La détection de
   fuites est éteinte — Qt et ngspice en laissent au dernier souffle.
5. **Trous de fixation Uno et Mega** : approximation sûre (aucun ne traverse
   une pastille), cotes exactes à prendre sur le plan mécanique officiel.
6. **`build-asan/` est dans l'historique git** — 267 fichiers, 76 833 lignes,
   commis par erreur. Les fichiers sont détraqués du suivi et `.gitignore`
   ferme la porte ; réécrire l'historique demande l'accord de l'utilisateur.
7. **Cœur Xtensa non exact au cycle**, et il ne peut pas l'être : Espressif ne
   publie pas de table de temps, celles du LX6 sont sous accord de
   confidentialité chez Cadence. Le pipeline est à **7 étages** (fiche
   technique ESP32), pas 5.

## Méthode

Ce qui a marché, et qu'il faut continuer :

- **mesurer plutôt que supposer.** Presque tous les défauts ci-dessus ont été
  trouvés en faisant tourner quelque chose, pas en relisant du code.
- **chercher la source primaire.** Le modèle de Zener écrit de mémoire
  convergeait mais avait le coude 29 mV trop bas et la mauvaise pente ; c'est
  `diotemp.c` de ngspice qui l'a corrigé. Les forums servent à trouver la
  source, pas à la remplacer.
- **une référence indépendante.** ngspice pour l'analogique, simavr pour
  l'AVR, `llvm-mc` pour le Xtensa, les tables ARM pour le Cortex-M. Vérifier
  un décodeur avec un assembleur qu'on a écrit soi-même ne prouve rien.
- **installer les vrais outils.** Trois défauts du cœur ARM ne se voyaient
  pas avec clang seul.
- **ne pas livrer à moitié.** Un exemple qui se bloque fait perdre plus de
  temps qu'une absence — d'où le point 1 ci-dessus, écrit plutôt que caché.
- **enregistrer les limites là où on les verra**, plutôt que dans un test qui
  les figerait.
