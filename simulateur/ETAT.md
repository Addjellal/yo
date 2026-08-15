# État du projet — simulateur de circuits

Document de reprise. Il dit ce qui existe, ce qui est vérifié **et comment**,
ce qui est cassé, et ce qui reste. À tenir à jour : c'est lui qu'on relit
quand le fil de la conversation est perdu.

## Ce que c'est

Un simulateur de circuits façon Proteus : schéma, simulation analogique,
microcontrôleurs exécutés pour de vrai, circuit imprimé. C++17 + Qt6.

Branche de travail : **`main`**, et c'est la seule. Branche par défaut du
dépôt.

Il y en avait trois, toutes sur le même commit, aucune ne portant un nom qui
voulût dire quelque chose ici — elles étaient nommées d'après la tâche qui
les avait créées. Un nom de tâche vieillit en une session ; le dépôt, lui,
tient trois projets (`simulateur/`, `formation-embarque/`, `auto-emploi/`) et
n'en privilégie aucun. D'où `main`.

Les deux autres ont été supprimées après vérification que tout leur contenu
était dans `main` — pas seulement qu'elles « semblaient à jour ». Si le cas
se represente : `git log --oneline origin/<branche> ^origin/main` compte les
commits exclusifs, et un commit de FUSION en montre un sans rien apporter,
ce qu'il faut alors confirmer en comparant les arbres.

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

## Les deux moteurs de référence ne sont PAS installés par défaut

Trouvé à l'audit, et c'est le point le plus important de ce document.

`ngspice` et `simavr` sont **facultatifs**. Sans eux le projet compile,
tourne, et le banc passe au vert — mais les sections **[21]** (solveur maison
confronté à ngspice) et **[22]** (cœur AVR confronté à simavr) **se sautent
toutes seules**, en l'annonçant sur une ligne qu'on ne remarque pas au milieu
de quatre cents « ok ».

Autrement dit : **un banc vert ne veut pas dire la même chose selon la
machine.** Sans ces deux paquets, l'analogique et l'AVR ne sont plus vérifiés
que contre eux-mêmes et contre la théorie — ce qui contredit la règle que ce
document se donne plus bas : « vérifier un décodeur avec un assembleur qu'on
a écrit soi-même ne prouve rien ».

Les installer, toujours, avant de croire un banc vert :

```
apt-get install -y libngspice0-dev simavr libsimavr-dev libelf-dev
cmake -S . -B build          # doit afficher « Second moteur ngspice : ON »
```

Une fois installés, les deux confrontations passent : mêmes tensions que
ngspice à 20 mV près sur diode et transistor, même transitoire, même coupure
à 2 % ; et contre simavr, mêmes commutations, mêmes sens, **mêmes instants**
sur quatre millions de cycles. La garantie annoncée est donc réelle — elle
n'était simplement pas exercée.

## Bancs d'essai

Les chiffres dépendent des moteurs présents : **401** au cœur sans ngspice ni
simavr, **416** avec. Ces quinze assertions de différence *sont* la
vérification indépendante — c'est exactement ce qu'on perd sans les paquets.
Le banc schéma en compte **342**, indépendamment.

Ce document a porté pendant plusieurs sessions quatre comptes périmés, dont
un faux du simple au double (« 177 » pour un banc schéma qui en comptait plus
de trois cents). **Un chiffre écrit dans un document se périme ; la commande
qui le produit, non.** Préférer relancer :

```
./build/tests_coeur
QT_QPA_PLATFORM=offscreen ./build/tests_schema
```

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

- **ASan + UBSan** : zéro alerte (voir le point 4 plus bas pour la commande). C'est cette passe qui avait trouvé neuf décalages signés
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

**Déploiement Windows** :

9. **L'exécutable se fermait sans rien dire.** Construction réussie, lien
   réussi, `simulateur.exe` produit — et il rendait la main instantanément,
   sans fenêtre ni message. Cause : `windeployqt --compiler-runtime` dépose le
   runtime C++ **de Qt** (le MinGW qui a bâti Qt), alors que la construction
   se faisait avec un MinGW plus récent (WinLibs GCC 16). Le dossier de
   l'exécutable primant sur le PATH, le chargeur prenait la vieille
   `libstdc++-6.dll`, n'y trouvait pas les symboles attendus, et tuait le
   processus **avant `main()`** — d'où le silence total. Code de sortie
   `0xC0000139`. Corrigé en copiant le runtime du compilateur réellement
   utilisé (`SIM_DLL_RUNTIME`) et en passant `--no-compiler-runtime` à
   windeployqt sous MinGW.

   Leçon : sous Windows, un exécutable qui « ne se lance pas » sans le moindre
   message n'a en général pas démarré du tout ; le code de sortie
   (`$LASTEXITCODE`) est le seul témoin, et il suffit à trancher entre DLL
   absente (`0xC0000135`) et DLL incompatible (`0xC0000139`).

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

   - QEMU A des machines STM32, contrairement à ce que laisse croire la page
     générique de la documentation : `stm32vldiscovery` (STM32F100,
     Cortex-M3), `netduino2` (STM32F205), `netduinoplus2` et
     `olimex-stm32-h405` (Cortex-M4). Le F100 partage sa carte de registres
     avec le F103 que je modélise — USART1 à 0x40013800, GPIO à 0x40010800,
     SysTick. C'est donc un oracle qui couvre AUSSI les périphériques, et pas
     seulement le cœur. Pour le RP2040 il n'y a rien ; `microbit` donne un
     Cortex-M0 générique et `mps2-an385` un Cortex-M3 générique, ce qui suffit
     pour comparer le cœur.

     Premier essai d'un firmware STM32 réel sous `stm32vldiscovery` : aucune
     sortie série. NON DIAGNOSTIQUÉ. Pistes : le routage de `-serial`, la
     validation d'horloge dans RCC, ou une différence d'USART entre F100 et
     F103 ;
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
4. **Sanitizers : « Fait » n'était vrai qu'à MOITIÉ**, et la moitié manquante
   était la pire. Corrigé à l'audit.

   Le bloc `SANITISER` ne listait que `coeur` et `tests_coeur`. `tests_schema`
   **ne se liait même pas** : il tire `coeur`, compilé avec les assainisseurs,
   sans recevoir lui-même leur bibliothèque d'exécution — des dizaines
   d'`undefined reference to __asan_report_store_n`. Et l'échec passait
   inaperçu parce que **la commande documentée ici ne demandait que
   `--target tests_coeur`** : la documentation cachait le défaut qu'elle
   aurait dû montrer.

   Donc : **tout le code Qt du schéma n'a jamais tourné sous ASan** — la
   scène, les fils, les ancres, la découpe. C'est précisément là qu'un
   use-after-free a été trouvé à la main, faute d'outil. L'outil existait,
   il n'était pas branché.

   La première correction n'a pas suffi, et la raison mérite d'être retenue :
   le bloc vivait AVANT `add_library(schema)` et `add_executable(tests_schema)`.
   `target_compile_options` exige que la cible existe déjà, si bien qu'un
   garde `if(TARGET ...)` sautait en silence. **Le bloc est maintenant en fin
   de fichier ; toute cible nouvelle doit être déclarée avant lui.**

   ```
   cmake -S . -B build-san -DSANITISER=ON -DCMAKE_BUILD_TYPE=Debug
   cmake --build build-san -j8 --target tests_coeur tests_schema
   ctest --test-dir build-san -L sanitiseurs
   ```

   Cœur assaini : **401 tests, zéro alerte** ASan et UBSan. Schéma assaini :
   **jamais exécuté à ce jour** — c'est le premier chiffre à établir. La
   détection de fuites est éteinte : Qt et ngspice en laissent au dernier
   souffle.
5. **Trous de fixation Uno et Mega** : approximation sûre (aucun ne traverse
   une pastille), cotes exactes à prendre sur le plan mécanique officiel.
6. ~~`build-asan/` est dans l'historique git~~ — **faux, et vérifié faux.**
   `git rev-list --objects --all | grep -c build-asan` rend **0** : aucun
   objet du dépôt ne porte ce chemin. Il n'y a donc rien à réécrire, et
   l'accord qu'on croyait devoir demander n'a pas lieu d'être.

   Ce point a survécu plusieurs sessions comme une dette imaginaire. La leçon
   vaut mieux que le point lui-même : **une entrée « ce qui est cassé » doit
   se revérifier, pas se recopier.** Une dette qu'on traîne sans la mesurer
   coûte de l'attention à chaque relecture, et celle-ci en a coûté pour rien.
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

---

# Session du 14-15 août 2026 — interface, câblage, agents

Vingt-cinq commits. Ce qui suit remplace tout ce qui précède **sur ces
sujets-là** ; le reste du document (moteurs, cartes, chaînes) reste valable.

## L'équipe d'agents

Trois définitions dans `.claude/agents/`, disponibles nativement :

| Agent | Rôle | La règle qui le tient |
|---|---|---|
| `critique-interface` | juge des propositions d'ergonomie | « un lot où tout est adopté est un lot mal critiqué » |
| `suggestion` | cherche ce qui **manque**, va voir ailleurs | « ne propose jamais ce qui existe déjà — lis le code d'abord » |
| `critique-code` | relit du C++/Qt, compile, prouve | « un défaut sans scénario déclencheur est une opinion » |

**Le rendement observé est sans appel : les agents lâchés sur le code
existant rapportent bien plus que les propositions inventées.** Cent
propositions d'interface ont donné vingt-six retenues ; une seule relecture
de code a donné quatre défauts graves, prouvés à l'ASan et à valgrind, dans
du code écrit le jour même et couvert par deux cents tests verts.

`critique-code` doit tourner **derrière chaque chantier**, pas en fin de
parcours. En C++, c'est le filet qui remplace le compilateur qu'on n'a pas.

## Le câblage : décision et mise en œuvre

`DECISION-FILS.md` tranche la question, sources à l'appui (Proteus,
Simulink, Altium, KiCad, LibrePCB lu dans le source). L'essentiel :

- **Sans mode.** Ce qui est sous le curseur décide. L'outil « Fil » a été
  retiré de la barre et des menus : il ne faisait que *restreindre*, et sa
  présence enseignait le contraire de ce que fait le logiciel.
- **`Ancre`** est la base commune de la broche et du point de fil. Un fil
  relie deux ancres. C'est ce qui rend « partir d'un fil » possible.
- **`ItemJonction`** sert à la fois de dérivation et de coude. À deux fils il
  ne dessine aucune pastille — un point marque une connexion, pas un
  changement de direction.
- **`viser()`** est la table de priorités : broche 0, jonction 10, fil 20,
  composant 70. Rayon de capture **constant à l'écran**, pas en unités de
  scène.
- **Coudes au clic** dans le vide, aperçu en équerre, tolérance d'alignement
  d'une demi-maille.

## Défauts corrigés, et ce qu'ils enseignent

Les plus instructifs de la session — tous trouvés en regardant tourner
l'application ou en la faisant relire :

1. **Le rectangle de sélection venait de la VUE, pas de la scène.**
   `QGraphicsView` le démarre quand la scène n'a pas *accepté* l'événement.
   Trois tentatives avant de le voir : je cherchais dans la mauvaise classe.
2. **Un clic annulé sur un fil détruisait ce fil.** On découpait avant de
   savoir si le geste aboutirait.
3. **`vers_json()` jetait tout fil touchant une jonction** — et comme
   `memoriser()` passe par là, un `Ctrl+Z` sans rapport effaçait une
   dérivation.
4. **`ngspice.dll` n'était pas déployée** alors que le lien était activé par
   défaut. Règle : *une dépendance activée par défaut doit être déployée par
   défaut.*
5. **Le runtime MinGW de Qt écrasait celui du compilateur** — l'exécutable
   mourait avant `main()`, sans message.
6. **`temps_ms()` rendait zéro sans carte**, pendant que l'oscilloscope
   affichait soixante-six secondes.

## Ce qui reste — par ordre de valeur

### Interface — chantier 5 : **FAIT**

Les six points sont livrés, chacun avec son banc. Ce qu'ils ont appris :

- **Survol qui allume tout le nœud.** `calculer_noeuds()` ne suffisait pas :
  il rend les NOMS par composant, pas l'appartenance des fils ni des coudes.
  L'union-find est donc extrait dans `tisser()` et partagé par le nommage et
  le survol — les calculer séparément aurait fini par les faire diverger, et
  le survol aurait montré un nœud que la netlist ne connaît pas.

  Deux décisions à ne pas défaire : la surbrillance est un **drapeau porté
  par chaque objet**, jamais une liste de pointeurs gardée dans la scène (un
  objet supprimé emporte le sien) ; et elle est **reposée à chaque survol**
  au lieu d'être court-circuitée quand le nom n'a pas changé — après
  suppression d'un fil, le nom est identique et le contenu non. Le banc
  attrape ce raccourci : le remettre fait tomber un test, et lui seul.

  Le nom part en barre d'état, comme LTspice — le seul précédent vérifié.

- **Marqueur ERC à côté du symbole.** `Anomalie` porte désormais un champ
  `borne` : le nom figurait déjà dans la phrase du message, mais l'y relire
  à l'expression régulière aurait fait dépendre le dessin du schéma de la
  ponctuation d'une phrase française. Le report traite les **trois formes**
  de `reference` (référence, nœud, liste jointe par virgules).

- **Bornes non connectées** : même mécanisme — la règle existait déjà, il
  lui manquait de dire *laquelle*.

- **`F11` présentation.** Ce qui bloquait : la scène consommait `Échap`
  **même sans fil à abandonner**, l'événement mourait là. Sortie par deux
  `Échap` rapprochés.

- **Mémoire de la disposition**, avec « Réinitialiser ». La disposition de
  référence est relevée **après construction**, jamais écrite en dur : une
  disposition en dur se désynchronise du constructeur au premier panneau
  ajouté. La portée `QSettings` suit l'identité de l'application — sans quoi
  le banc, qui construit de vraies `FenetrePrincipale`, relirait la
  disposition de l'utilisateur sur sa machine.

- **Cartouche à l'impression seulement.** Champ « Nom » tracé même vide, en
  pointillé : une ligne à remplir à la main vaut mieux qu'une feuille
  anonyme.

Bancs : relancer plutôt que citer un chiffre — voir « Bancs d'essai ».

### Diagnostic (chantier 4) : **FAIT**

Panneau « Contrôle » à côté du journal, jamais modal, chaque ligne menant à
son coupable. `SceneSchema::designer_anomalie()` traite les **trois formes**
de `Anomalie.reference` par trois gestes différents :

| forme | geste |
|---|---|
| `R1` | sélectionne ce composant |
| `R1, V1` | les sélectionne tous |
| `GND` (un nœud) | sélectionne les **fils** du nœud |

La troisième est celle qu'on oublie, et l'oublier fait un **clic mort** —
pire qu'une ligne non cliquable, puisqu'il se laisse essayer. Un nœud n'a
pas de symbole : ce sont ses fils qui le matérialisent.

Le cadrage ne change pas l'échelle : un zoom qui saute à chaque clic ferait
perdre le repère qu'on vient de se construire.

**Les deux boîtes modales ont disparu** — celle de l'ERC (elle recouvrait le
schéma qu'elle décrivait) et celle du compilateur (défaut 4).

### Cliquer une erreur de compilation : **FAIT**

Double-clic dans le journal → l'onglet et la ligne. Lu au format **texte**
`fichier:ligne:colonne: erreur:` — avr-g++ 7.3, celui des paquets Debian, ne
connaît pas `-fdiagnostics-format=json` (apparu avec GCC 9).

Deux pièges, tous deux dans le banc :
- **la locale.** Le compilateur suit la langue du système : le motif accepte
  `error:` et `erreur:`. Un analyseur qui ne lirait que l'anglais marcherait
  sur le conteneur d'essai et nulle part en salle.
- **les lignes de contexte.** `principal.ino: In function 'void setup()':`
  n'a pas de numéro et ne doit rien déclencher.

Le motif est vérifié contre la sortie **réelle** d'avr-g++ 7.3.0, recopiée
verbatim dans le banc après compilation d'un croquis fautif.

### Exemples rangés par carte : **FAIT**

Neuf branches, plus « Sans carte ». La justification n'est pas le rangement :
**neuf des dix exemples posaient un `arduino_uno` en dur**. Sur un poste
réglé pour un TP ESP32 ou STM32, huit entrées chargeaient donc silencieusement
un Uno à la place de la carte du jour — une erreur d'élève fabriquée, qu'il
n'a aucun moyen de diagnostiquer.

Cinq cartes portaient **déjà** leur clignotant dans `Modele::programme_exemple`,
écrit et compilé par le banc, atteignable seulement en posant la carte à la
main puis en devinant le double-clic. Le travail était fait ; il manquait le
branchement. `charger_clignotant_carte(type, broche)` fait les huit — ce qui
change d'une carte à l'autre tient à un nom de broche (D13, PB5, PB1, GP25,
PC13, GPIO2).

Deux règles à ne pas défaire :

- **la limite est écrite DANS le menu**, en entrée grisée, pas en info-bulle :
  « chaîne Xtensa absente », « ni HAL ni CubeMX », « pas d'UART matériel ». Un
  élève qui cherche pourquoi son exemple ESP32 ne compile pas ne pensera pas à
  survoler une entrée ;
- **la résistance suit la tension** : 220 Ω sous 5 V, 100 Ω sous 3,3 V. Livrer
  220 Ω sur un Pico enseignerait une erreur.

Ce qui a été écarté, et pourquoi : importer les catalogues officiels. Pico
(pico-sdk), STM32 (HAL) et ESP32 (ESP-IDF) donnent **0 exemple compilable
ici** — le simulateur n'accepte que du C nu sur registres. Côté Arduino, 33
des 68 exemples officiels tournent ; les blocages tiennent surtout à la classe
`String` (14) et à l'USB HID (7).

### `pulseIn()` : **FAIT**

Le cours §4 écrit `long duree = pulseIn(ECHO, HIGH);` pour le HC-SR04. La
fonction n'existait pas : **le code du cours ne compilait pas**, alors que le
composant `telemetre_ultrason` est vérifié à ±0,3 ms. Un modèle exact que
rien ne pouvait interroger.

Écart assumé : Arduino compte des passages de boucle calibrés, ici on lit
`micros()`. La résolution est celle du timer 0 — 4 µs à 16 MHz, soit 0,07 %
sur un écho de 5 800 µs, bien en deçà de l'erreur du couplage analogique.

Vérifié en **exécution réelle** : le banc fabrique une impulsion de 5 ms
depuis l'extérieur pendant que la puce tourne dans sa boucle d'attente, et la
puce publie la bonne durée à mieux que 10 %.

**Ce qui n'est PAS couvert, et c'est un fil à reprendre.** Le délai de garde
— une broche muette doit rendre 0 plutôt que figer le programme — n'est pas
vérifié. Une première version du test appelait `pulseIn(ECHO, HIGH, 2000)`
sur une broche immobile, et **le banc entier se bloquait à cet endroit**,
alors que `avancer(cycles)` est borné. La cause n'a pas été trouvée, et je
n'ai pas voulu livrer un banc qui fige. La garde est écrite dans le noyau et
suit le contrat d'Arduino, mais elle n'est pas prouvée : c'est le premier
endroit à regarder si un montage se bloque dans une lecture de télémètre.

### Les trois manques lourds

1. **Cliquer une erreur de compilation pour atteindre la ligne fautive.**
   Les `#line` de `fusionner_croquis` propagent déjà le bon nom d'onglet et
   le bon numéro — il n'y a qu'à lire la sortie, au format texte
   `fichier:ligne:colonne:` (avr-g++ 7.3 ne connaît pas le JSON).
2. **Les messages du solveur sans coupable ni remède.**
3. **L'éditeur sans recherche, sans `Ctrl+S`, sans numéros de ligne** — alors
   qu'on lui prend `Ctrl+F` et `Ctrl+D`.

### PCB — placement : **FAIT**

`depuis_netlist()` posait les composants dans l'ordre de la **netlist**, sans
jamais regarder ce qui était relié à quoi. Mesuré avant correction, sur une
chaîne R1→R3→R4→R2 saisie dans l'ordre R1,R2,R3,R4 : **215,6 mm** de cuivre.
Après : **115,6 mm**, et les composants suivent la chaîne.

Méthode : croissance de grappe, comme les placeurs constructifs. On part du
composant le plus relié, puis on ajoute à chaque tour celui qui a le plus de
liens avec ce qui est déjà posé. Ce n'est pas un optimum — le placement
optimal est NP-difficile — mais cela suffit à transformer une rangée
arbitraire en un chemin qui suit le circuit.

Deux points à ne pas défaire :

- **les nets d'alimentation ne comptent pas comme liens.** La masse touche
  presque tout : la retenir ferait de chaque composant le voisin de tous les
  autres, et le classement n'apprendrait plus rien. C'est aussi pourquoi une
  masse se route en plan de cuivre plutôt qu'en piste.
- **les égalités se tranchent par l'ordre de la netlist**, sinon deux
  exécutions sur le même schéma rendraient deux cartes différentes.

Honnêteté sur la portée : le montage à trois composants du cours ne gagne
rien (59,6 mm avant comme après) — son ordre de saisie était déjà le bon. Le
gain apparaît dès que la saisie ne suit pas la topologie, ce qui est le cas
ordinaire d'un schéma qu'on a fait évoluer.

**Reste** : le placement ne fait qu'ordonner une rangée. Il ne tourne aucun
composant, ne tasse rien en deux dimensions, et ne cherche pas à raccourcir
après coup. Un recuit ou une descente de gradient sur les positions serait
l'étape suivante, si le besoin s'en fait sentir.

### Si le projet grandit

Trois écarts avec Simulink, par ordre de profondeur : **la hiérarchie**
(absente, et structurelle — à faire tôt ou jamais), **le pas de temps fixe**
(le seul qui rende les résultats *faux* sur un front raide), et **la
comparaison de deux essais**.

## Environnement — deux pièges vécus

- **`build/chaines/` contient les compilateurs croisés (~370 Mo).** Effacer
  `build` les perd. Les déplacer avant, les remettre après.
- Le conteneur de développement peut perdre Qt6 et les chaînes en cours de
  session. `apt-get update` puis réinstaller ; ce n'est pas une régression du
  code.
