# Mini-TP Schneider — télérupteur + compteur sur M221 simulé (30 min)

**Plateforme** : **EcoStruxure Machine Expert – Basic** (gratuit :
https://www.se.com → rechercher « EcoStruxure Machine Expert Basic ») —
son **simulateur M221 intégré** remplace l'automate (menu *Mise en
service → Simulateur*).
**Alternative texte** : la version ST du même exercice
([`telerupteur_a_trous.st`](telerupteur_a_trous.st)) tourne dans
**CODESYS** (https://www.codesys.com) ou un **DFB Control Expert**.
**Prérequis** : cours 08 §3 (LADDER M221, `%TM`, fronts) lu.

## L'exercice (spécifique automate : fronts et cycle scan)

Un **télérupteur** : chaque **appui** sur `%I0.0` inverse la lampe `%Q0.0`.
Un compteur `%MW10` compte les appuis. C'est l'exercice qui piège tous les
débutants automate, car le programme est rebalayé **toutes les ~2 ms** :
sans détection de **front**, un appui de 200 ms inverse la lampe ~100 fois.

### Version LADDER (Machine Expert Basic) — à construire

| Rung | Contenu à poser | Trou à résoudre |
|---|---|---|
| 1 | Contact **front montant** (`P`) sur `%I0.0` → bobine `%M0` | quel type de contact ? (c'est LE piège) |
| 2 | `%M0` → inverser `%Q0.0` | deux barreaux Set/Reset croisés avec `%Q0.0` en condition, OU un bloc opération `%Q0.0 := NOT %Q0.0` conditionné par `%M0` |
| 3 | `%M0` → bloc opération `%MW10 := %MW10 + 1` | pourquoi PAS un contact normal ici ? |

### Recette de test au simulateur

| # | Action (forçage `%I0.0`) | Attendu |
|---|---|---|
| 1 | impulsion courte | lampe s'allume, `%MW10` = 1 |
| 2 | impulsion courte | lampe s'éteint, `%MW10` = 2 |
| 3 | **appui MAINTENU 5 s** | lampe change UNE seule fois, `%MW10` = 3 |
| 4 | relâcher | rien ne bouge |

**Le test 3 est le juge de paix** : si `%MW10` explose pendant l'appui
maintenu, ton rung 1 utilise un contact à niveau au lieu d'un front —
relis cours 07 §5.2/08 §3.1.

**Bonus Modbus** (5 min, pont vers le TP 4) : `%MW10` est directement
lisible en Modbus TCP (holding register 10) — si tu as `mbpoll` ou
`pymodbus` sous la main, lis-le depuis le PC pendant que tu appuies.
