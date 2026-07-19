# Mini-TP Siemens — hystérésis en SCL sous PLCSIM (30 min)

**Plateforme** : TIA Portal (essai 21 jours : https://www.siemens.com →
rechercher « TIA Portal trial download ») avec **PLCSIM** — aucun automate.
**Sans TIA Portal** : le même code tourne dans **CODESYS**
(https://www.codesys.com, gratuit, menu *En ligne → Simulation*) — la
syntaxe ST est identique au SCL à `#`/`"` près.
**Prérequis** : cours 07 §7 (SCL) lu ; TD 03 exercice 3 (l'hystérésis
côté Arduino — c'est exprès : même concept, autre plateforme).

## Mise en place (10 min)

1. Projet TIA → CPU 1214C → ajouter un **FB** `Regulation` en **SCL**.
2. Interface du FB :

| Section | Nom | Type | Rôle |
|---|---|---|---|
| Input | mesure | Real | température mesurée |
| Input | consigne | Real | température voulue |
| Output | chauffe | Bool | commande du chauffage |
| Static | (rien à ajouter) | | l'état est porté par `chauffe` |

3. Colle le corps depuis [`hysteresis_a_trous.scl`](hysteresis_a_trous.scl)
   et complète les 2 trous.
4. Appelle le FB dans OB1, compile, **démarre PLCSIM**, et pilote
   `mesure`/`consigne` depuis une **table de visualisation**.

## Recette de test (c'est elle qui est notée — méthode du TP 3)

Consigne fixée à 20.0. Force `mesure` dans cet ordre et coche :

| # | mesure | chauffe attendu | Pourquoi |
|---|---|---|---|
| 1 | 18.0 | **TRUE** | sous consigne − 0,5 |
| 2 | 19.8 | TRUE (inchangé) | dans la bande morte : on NE change PAS |
| 3 | 20.2 | TRUE (inchangé) | toujours dans la bande |
| 4 | 20.6 | **FALSE** | au-dessus de consigne + 0,5 |
| 5 | 20.2 | FALSE (inchangé) | bande morte, sens inverse |
| 6 | 19.4 | **TRUE** | repassé sous consigne − 0,5 |

**Le point du mini-TP** : les lignes 2-3-5 — dans la bande morte, la sortie
**garde son état**. Si ton FB bat (change d'avis ligne 2 ou 5), tu as écrit
un simple comparateur, pas une hystérésis : relis le trou (2).

**Spécificité automate à observer** : contrairement au C, ce FB est
rappelé **à chaque cycle** (~ms) sans que tu écrives de boucle — c'est le
cycle automate (cours 07 §1) qui boucle pour toi.
