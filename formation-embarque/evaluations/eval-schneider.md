# Évaluation pratique — Schneider EcoStruxure (2 h 30, simulateur M221)

> Machine Expert Basic (gratuit) + simulateur intégré ; client Modbus au
> choix (`mbpoll`, `pymodbus`, QModMaster). Documents autorisés.
> Rendu : projet `.smbp` + **document de table Modbus** + journal du client
> PC. Spécificité Schneider de cette épreuve : l'ouverture **Modbus** vers
> la supervision fait partie du sujet — c'est la marque de fabrique de
> l'écosystème (cours 08 §5).

## Sujet — Ventilation de parking

Deux ventilateurs V1/V2 (`%Q0.0`, `%Q0.1`) pilotés par un capteur de CO
analogique (`%IW0.0`, 0..1000 = 0..300 ppm) :

- CO > 100 ppm → **un** ventilateur (alternance à chaque démarrage selon
  les heures de marche — reprise du TD 08) ;
- CO > 200 ppm → **les deux** ;
- hystérésis de 20 ppm sur chaque seuil (pas de battement) ;
- capteur figé 60 s pendant qu'un ventilateur tourne → défaut capteur →
  **les deux ventilateurs en marche** (repli sécuritaire : on ventile en
  aveugle) + voyant `%Q0.2`.

## Travail demandé et barème

| # | Livrable | Points |
|---|---|---|
| 1 | Mise à l'échelle + symboles complets AVANT le code | /2 |
| 2 | Double hystérésis correcte (recette : monter/descendre le CO au simulateur et cocher les 8 points de bascule attendus) | /5 |
| 3 | Alternance par compteurs d'heures (`%MW`), choix figé au front | /4 |
| 4 | Chien de garde capteur + repli « tout ventiler » justifié en commentaire | /3 |
| 5 | **Table Modbus documentée** (≥ 6 mots : état bits, CO, heures V1/V2, mot de vie, commande) + zones disjointes + bornage des écritures PC | /4 |
| 6 | Preuve client PC : lecture cyclique + détection du mot de vie figé quand on stoppe le simulateur (capture/journal) | /2 |

**Seuil : 14/20.** Éliminatoire : une écriture Modbus du PC qui pilote
directement une `%Q` (le PC écrit des demandes, l'automate décide).

## Question orale (ajuste ±2)

« Pourquoi le repli capteur est-il *tout ventiler* ici, alors que le
thermostat du TD 03 coupait le chauffage en panne capteur ? » —
*(attendu : l'état sûr dépend du procédé — sur-ventiler un parking est
sans danger, sous-ventiler tue ; sur-chauffer une pièce est dangereux,
sous-chauffer non. L'état de repli se déduit du risque, pas d'une règle
mécanique.)*
