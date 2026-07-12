# `code/` — les corrigés en fichiers sources réels

Tous les corrigés des TD sous forme de projets **compilables et testés**.
Chaque dossier a son `Makefile` (quand l'outil s'y prête) : `make test`
compile puis exécute les tests — c'est la façon dont ce code a été validé.

| Dossier | Contenu | Comment vérifier |
|---|---|---|
| [`c/`](c/) | TD 01 : `bits`, `ring_buffer`, `fsm_feu`, `trame` + tests unitaires | `make test` (gcc, `-Wall -Wextra -Werror`) |
| [`cpp/`](cpp/) | TD 02 : `TamponCirculaire<T,N>`, `IAfficheur` + mock LCD, `ChipSelect` RAII, `FeuTricolore` + tests | `make test` (g++ C++17) |
| [`java/`](java/) | TD 05 : hiérarchie `Capteur`/`Station`, `DecodeurTrame` (piège du byte signé), `ProdCons` | `make test` puis `make prodcons` (JDK ≥ 17) |
| [`vhdl/`](vhdl/) | TD 04 + TP 2 : `mux4`, `compteur_bcd`, `debounce`, `uart_tx`, **`uart_rx` complet**, testbenchs dont la boucle exhaustive 256/256 | `make test` (GHDL) ; `make ondes` pour GTKWave |
| [`arduino/`](arduino/) | TD 03 : `chenillard/` et `thermostat/` (sketches complets) | ouvrir dans l'IDE Arduino ou sur wokwi.com |
| [`python/`](python/) | TP 4 : `supervision.py`, client Modbus TCP complet (mot de vie, journal CSV, commandes) | `pip install pymodbus` puis `python3 supervision.py <ip>` |
| [`st/`](st/) | TD 07/08 : `moyenne_glissante.scl`, `porte_garage.scl`, `alternance_pompes.st` | à coller dans un FB TIA Portal / Control Expert |

## Comment travailler avec ces corrigés

1. **Fais d'abord l'exercice toi-même** à partir de l'énoncé du TD.
2. Compare ensuite avec le fichier source ici : lis les commentaires, ils
   expliquent les choix (et les pièges) autant que le TD.
3. **Casse les tests** : modifie une ligne du corrigé (enlève un `volatile`,
   inverse une condition) et regarde quel test échoue — c'est le meilleur
   moyen de comprendre à quoi chaque ligne sert.
4. Réutilise : `ring_buffer` et `TamponCirculaire` resservent tels quels
   dans les TP 5 (console STM32) ; `uart_tx/rx` sont le cœur du TP 2.

## État de validation

- `c/`, `cpp/`, `java/` : compilés et tests exécutés (zéro warning avec
  `-Werror`).
- `vhdl/` : les trois testbenchs passent sous GHDL, dont
  `tb_uart_boucle` — **256/256 octets** transmis/reçus sans erreur.
- `python/` : nécessite un automate (ou simulateur) Modbus pour tourner ;
  la syntaxe est vérifiée.
- `arduino/`, `st/` : à compiler dans leurs IDE respectifs (IDE Arduino /
  Wokwi, TIA Portal / Control Expert).
