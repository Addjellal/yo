# Évaluation pratique — Arduino (2 h, sur Wokwi)

> Épreuve **entièrement sur simulateur** : https://wokwi.com (Arduino Uno).
> Documents autorisés. Rendu : le lien de partage du projet Wokwi (bouton
> *Share*) — l'examinateur DOIT pouvoir cliquer ▶ et dérouler la recette.

## Sujet — Minuterie d'escalier améliorée

Monter dans Wokwi : 1 bouton (D2), 1 LED « éclairage » (D9, PWM), 1 LED
témoin rouge (D8), 1 potentiomètre (A0).

Comportement exigé :
1. Appui court → éclairage **plein feu** pendant une durée réglée par le
   potentiomètre (5 à 60 s, relue à chaque appui). (/4)
2. Les **10 dernières secondes**, l'éclairage « prévient » : luminosité
   réduite à 30 % (PWM), témoin rouge clignotant à 2 Hz. (/4)
3. Un appui pendant la marche **relance** la durée complète (sans à-coup
   visible). (/2)
4. **Appui long (≥ 2 s)** → éclairage permanent ; nouvel appui long →
   retour au mode minuterie. (/4)
5. Moniteur série 115200 : une ligne par changement d'état
   (`MARCHE 42s`, `PREAVIS`, `ARRET`, `PERMANENT`). (/2)

## Contraintes de plateforme (éliminatoires si violées)

- **Aucun `delay()`** dans `loop()` — tout au `millis()`. Le correcteur met
  un appui pendant le préavis : le clignotant ne doit pas « geler ».
- Anti-rebond logiciel du bouton (20 ms) — Wokwi simule des rebonds si on
  active *bounce* dans les propriétés du bouton : **l'activer**.
- Architecture : une FSM explicite (`enum` + `switch`) — le correcteur lit
  le code : des `if` imbriqués sans états nommés = −4.

## Recette déroulée par le correcteur (10 min)

| # | Action | Attendu |
|---|---|---|
| 1 | ▶ puis appui court, pot à fond | plein feu, série `MARCHE 60s` |
| 2 | attendre le préavis | 30 % + témoin 2 Hz + `PREAVIS` |
| 3 | appui pendant le préavis | retour plein feu, durée relancée |
| 4 | appui long | `PERMANENT`, plus de minuterie |
| 5 | appui long à nouveau | retour minuterie, `ARRET` |

## Barème

Fonctionnel (ci-dessus) /16 · qualité (FSM lisible, pas de globales
inutiles, noms clairs) /2 · robustesse (rebonds activés, pas de gel) /2.
**Seuil : 14/20.** Bonus +1 : la durée restante affichée chaque seconde
sans spammer (une ligne/s exactement).
