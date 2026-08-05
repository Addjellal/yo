# FAQ & dépannage — débloquer les 30 premières heures

> La première cause d'abandon n'est pas la difficulté du sujet : c'est un
> outil qui ne s'installe pas, une carte que le PC ne voit pas, un message
> d'erreur incompréhensible. Cette page rassemble les blocages réels, par
> ordre d'apparition.

## Questions de départ

**Faut-il acheter du matériel pour commencer ?**
Non. Les modules 00 à 02, tous les mini-TP sauf un, le TP 2 (VHDL) entier et
les TP 3-4 (automates) se font **100 % en simulation**. Le premier achat
utile (Arduino ~25 € avec kit) n'est nécessaire qu'au TP 1, vers la
semaine 7 — et Wokwi permet même de le faire sans.

**Quel ordinateur faut-il ?**
N'importe quel PC pour les modules 00-06. Pour **TIA Portal** (module 07) :
Windows, 8 Go de RAM minimum (16 conseillés), 25 Go de disque — c'est le
seul outil réellement lourd. Sur Mac/Linux : machine virtuelle Windows, ou
remplacer par **CODESYS**/Machine Expert Basic pour les concepts.

**Combien de temps par semaine ?**
6 h est le rythme de référence (~8 mois). En dessous de 3 h/semaine, la
mémorisation ne suit pas ; mieux vaut une session longue qu'un grignotage.

**Je viens de l'informatique / de l'électrotechnique, par où commencer ?**
- *Informatique* : ne saute pas le module 00 (électricité, protocoles) — c'est
  là qu'est ton angle mort. Le C te semblera facile, l'automate et le VHDL non.
- *Électrotechnique* : les modules 07-08 te seront familiers ; investis le
  temps gagné sur les modules 01 (pointeurs) et 04.

---

## Compilation C / C++

| Message | Cause | Solution |
|---|---|---|
| `gcc: command not found` | pas de compilateur | Linux : `sudo apt install build-essential` · Windows : WSL ou MinGW · Mac : `xcode-select --install` · ou **onlinegdb.com** |
| `undefined reference to 'fonction'` | fichier `.c` non compilé/lié | ajouter le `.c` à la commande ou au Makefile |
| `implicit declaration of function` | `#include` manquant | inclure le `.h` correspondant |
| `expected ';' before ...` | oubli à la **ligne précédente** | regarder au-dessus de la ligne signalée |
| `warning: unused variable` avec `-Werror` | variable inutilisée | la supprimer (ou `(void)x;` si volontaire) |
| Le programme « ne fait rien » | `main` renvoie sans exécuter | vérifier les conditions ; ajouter des `printf` de trace |
| `Makefile:5: *** missing separator` | **espaces au lieu d'une tabulation** | les commandes d'un Makefile exigent une vraie tabulation |

**Segfault ?** Recompiler avec `-g -fsanitize=address` et relancer : l'outil
indique la ligne et le type d'erreur mémoire. C'est le réflexe n°1 sur PC.

---

## Arduino & Wokwi

| Symptôme | Cause probable | Solution |
|---|---|---|
| La carte n'apparaît pas dans *Port* | pilote / câble | câble **de données** (pas seulement charge) ; pilote CH340 ou CP2102 pour les clones |
| `avrdude: not in sync` | port occupé, mauvaise carte | fermer le moniteur série, vérifier *Carte* et *Port*, débrancher D0/D1 |
| Permission denied `/dev/ttyACM0` (Linux) | droits | `sudo usermod -aG dialout $USER` puis **se déconnecter/reconnecter** |
| Caractères illisibles au moniteur | vitesse ≠ | même baudrate des deux côtés (115200) |
| La carte redémarre en boucle | pic de courant (servo/moteur) | alimentation séparée, **masses communes**, condensateur 470 µF |
| `nan` du DHT en permanence | pull-up absente, lectures trop rapprochées | 10 kΩ sur DATA, ≥ 2 s entre lectures |
| Écran I2C noir | adresse ou câblage | lancer le **scanner I2C** (0x3C/0x27), vérifier SDA/SCL |
| Plus assez de RAM (Uno) | chaînes en RAM, `String` | `Serial.println(F("..."))`, tableaux de `char` |
| Wokwi : rien ne démarre | simulation non lancée | bouton ▶ ; ouvrir le moniteur série en bas |
| Wokwi : pas de Wi-Fi | SSID | SSID `Wokwi-GUEST`, mot de passe vide |

---

## VHDL / GHDL / EDA Playground

| Message | Cause | Solution |
|---|---|---|
| `cannot find entity` | ordre d'analyse | analyser **les sources avant** le testbench |
| `unit ... not found` / std | norme | ajouter `--std=08` à **toutes** les commandes (`-a`, `-e`, `-r`) |
| `no declaration for "unsigned"` | bibliothèque | `use ieee.numeric_std.all;` |
| `can't match type` | conversion implicite interdite | `std_logic_vector(u)` / `unsigned(v)` — toujours explicite |
| `multiple drivers` | signal piloté dans 2 process | un signal = **un seul** process |
| Simulation infinie / se fige | pas de fin | `--stop-time=10ms`, et un `wait;` final dans le process de stimuli |
| Chronogramme vide | pas d'ondes demandées | `--wave=out.ghw` puis `gtkwave out.ghw` |
| EDA Playground ne lance rien | config | *Tools & Simulators* → **GHDL**, langage **VHDL**, cocher *Open EPWave after run*, **Top entity** = nom du testbench |
| Latch inattendu à la synthèse | sortie non affectée partout | valeur par défaut en tête de process combinatoire |

---

## TIA Portal / PLCSIM (Siemens)

| Symptôme | Solution |
|---|---|
| Installation qui échoue / redémarre en boucle | désactiver l'antivirus pendant l'installation, chemin **sans accents ni espaces**, redémarrer quand demandé |
| PLCSIM ne se connecte pas | choisir l'interface **PLCSIM** dans la liaison, CPU compatible avec la version de TIA |
| « Le programme n'est pas cohérent » | recompiler **tout** (clic droit projet → Compiler → Logiciel (compilation complète)) |
| La CPU passe en STOP | tampon de diagnostic (*En ligne et diagnostic*) : il donne la cause exacte (division par zéro, accès hors zone…) |
| Une variable ne change pas dans la table | mauvais bloc/DB, ou écrasée par un autre réseau — chercher **toutes** les écritures de ce symbole |
| Les sorties restent à 0 | AU (NF) forcé à 0 dans le simulateur : le mettre à **1** |
| Licence d'essai expirée | 21 jours ; sinon licence éducation SCE, ou basculer sur **CODESYS** pour les concepts |

---

## Machine Expert Basic / M221 (Schneider)

| Symptôme | Solution |
|---|---|
| Simulateur muet | *Mise en service → Simulateur* ; vérifier que le programme est transféré |
| Modbus : `Connection refused` | activer le **serveur Modbus TCP** dans la config Ethernet du M221 |
| `pymodbus` ne lit rien | tester d'abord avec `mbpoll`/QModMaster : isole le problème (script vs automate) |
| Valeurs incohérentes côté PC | adressage décalé (« 40001 ») ou **word swap** sur les 32 bits |
| Une pompe reste collée | plusieurs sections écrivent la même `%Q` → centraliser les sorties |

---

## STM32CubeIDE

| Symptôme | Cause | Solution |
|---|---|---|
| ST-Link non détecté | pilote / câble | STM32CubeProgrammer, mettre à jour le firmware du ST-Link |
| `Error: Failed to connect to target` | mode veille, BOOT0 | maintenir RESET pendant la connexion, ou effacement complet via CubeProgrammer |
| Mon code a disparu | régénération CubeMX | écrire **uniquement entre** `/* USER CODE BEGIN */` et `END` |
| Périphérique inerte | horloge | activer **RCC** (CubeMX le fait ; en registres c'est ton premier geste) |
| Un seul octet reçu en UART | IT non réarmée | rappeler `HAL_UART_Receive_IT()` dans le callback |
| `printf` n'affiche rien | redirection | implémenter `__io_putchar`, cocher l'option float si `%f` |
| HardFault | pointeur/pile | fenêtre **Fault Analyzer** : `CFSR` (type) et `BFAR` (adresse fautive) |
| Plantage dès FreeRTOS | base de temps | HAL sur **TIM10** (pas SysTick) ; priorité NVIC ≥ `configMAX_SYSCALL...` |

---

## Java

| Message | Solution |
|---|---|
| `class X is public, should be in a file named X.java` | renommer le fichier (sur OnlineGDB, la classe doit s'appeler `Main`) |
| Toutes mes trames sont rejetées | `byte` **signé** : comparer avec `(octet & 0xFF)` |
| Le programme ne se termine pas | threads non arrêtés : `interrupt()` + `join()`, et pas de `catch` vide |

---

## Git

| Message | Solution |
|---|---|
| `fatal: not a git repository` | `git init`, ou tu n'es pas dans le bon dossier (`pwd`) |
| `Please tell me who you are` | `git config --global user.name "..."` et `user.email "..."` |
| `Updates were rejected` | `git pull --rebase` puis `git push` |
| `Authentication failed` (GitHub) | mot de passe refusé depuis 2021 : utiliser un **token d'accès personnel** ou SSH |
| J'ai commité un fichier énorme/secret | `git rm --cached fichier`, l'ajouter au `.gitignore`, recommiter |

---

## Régénérer les PDF de la formation

```bash
cd formation-embarque
make pdf          # ou : python3 _build/build_pdf.py
```
Prérequis : `pip install markdown pygments` et un Chromium (le script le
cherche dans `/opt/pw-browsers`). Les recueils fusionnés nécessitent
`poppler-utils` (`pdfunite`).

---

## Toujours bloqué ?

1. **Isole** : une seule inconnue à la fois (tester le capteur seul, le bus
   seul, le programme minimal).
2. **Lis le message en entier**, surtout la **première** erreur : les
   suivantes en découlent souvent.
3. **Cherche le message exact** entre guillemets sur le web — quelqu'un l'a
   déjà eu.
4. **Explique ton problème à voix haute** (méthode du canard en plastique) :
   la moitié des bugs se résolvent en formulant.
5. Communautés : forum.arduino.cc · community.st.com · r/embedded ·
   electronics.stackexchange.com · PLCtalk (automatismes).
