# Mini-TP Arduino — feu piéton sur Wokwi (30 min)

**Plateforme** : https://wokwi.com → *New Project* → **Arduino Uno**.
Aucune installation, aucun compte requis pour tester.
**Prérequis** : cours 03 §5 (programmer sans `delay()`) lu.

## Montage à faire sur Wokwi (5 min)

Dans l'éditeur Wokwi, ajoute (bouton « + ») et câble :

| Composant | Broche Arduino |
|---|---|
| LED rouge (+ résistance 220 Ω) | D10 |
| LED verte (+ résistance 220 Ω) | D9 |
| Pushbutton | D2 → GND (l'autre patte) |

*(Astuce : dans Wokwi, clique une patte puis la broche pour tirer un fil.)*

## Exercice — `feu_pieton_a_trous.ino`

Colle [`feu_pieton_a_trous.ino`](feu_pieton_a_trous.ino) dans `sketch.ino`
et complète les 4 trous : configuration des broches, lecture du bouton en
pull-up, transition temporisée avec `millis()`, et remise de la demande à
zéro.

**Comportement attendu en simulation** (bouton ▶ pour lancer) :

1. Au départ : LED **rouge** allumée (piéton : attendre).
2. Appui sur le bouton → au bout d'1 s maxi, **vert** pendant 5 s.
3. Retour au rouge automatiquement.
4. Le moniteur série (115200) affiche chaque changement d'état.
5. **Test clé** : appuie 5 fois vite pendant le vert → le vert ne se
   prolonge PAS, et le feu ne repart pas en vert tout seul après le retour
   au rouge (ces appuis comptent comme déjà servis).

**Interdit** : `delay()` — le sketch en contient zéro, garde-le ainsi.
Solution de référence (après essai !) : la FSM du TD 01/03 — même logique.
