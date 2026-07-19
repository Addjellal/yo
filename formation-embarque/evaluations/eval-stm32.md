# Évaluation pratique — STM32 (3 h, Nucleo ou justification simulateur)

> STM32CubeIDE + Nucleo-F411 (ou équivalente). Sans carte : parties A et C
> intégralement faisables (calculs + code + debug en « simulation de
> raisonnement ») — la partie B se rend alors en code commenté avec les
> valeurs de registres attendues. Documents autorisés. Rendu : projet
> CubeIDE + `REPONSES.md` + captures du débogueur.
> Spécificité STM32 : on note la **maîtrise des registres et du débogueur**,
> pas l'assemblage de bibliothèques.

## Partie A — Calculs de configuration (30 min, /5)

SYSCLK = 84 MHz, APB1 timer clock = 84 MHz. Sans outil, calculatrice
autorisée :
1. PSC et ARR pour une interruption TIM3 toutes les **50 ms** (deux
   couples possibles — en donner un et vérifier). (/2)
2. Baudrate réel et erreur en % pour un UART réglé « 115200 » si le
   diviseur retenu donne 84 MHz / 729. (/2)
3. L'ADC 12 bits lit 2482 avec Vref = 3,3 V : tension ? Et en **point
   fixe** millivolts sans flottant (formule entière) ? (/1)

## Partie B — Réalisation (90 min, /10)

Sur Nucleo : un « chenillard de charge » — la LED LD2 clignote à une
fréquence proportionnelle à la valeur du potentiomètre (ou du capteur de
température interne si pas de potentiomètre) :

| Exigence | Points |
|---|---|
| Clignotement cadencé par **interruption TIM3** (pas de HAL_Delay), période recalculée depuis l'ADC | /3 |
| ADC lu par **DMA circulaire** — preuve au débogueur : tableau qui bouge CPU arrêté (capture Live Expressions) | /3 |
| Console UART : `status` renvoie période courante + valeur ADC + uptime ; réception par interruption, réarmée | /3 |
| `printf` redirigé, bannière avec `__DATE__`/`__TIME__` | /1 |

## Partie C — Diagnostic (60 min, /5)

Le correcteur fournit (ou tu écris toi-même) un projet contenant **trois
bugs classiques** : horloge RCC d'un GPIO non activée, variable partagée
ISR/main sans `volatile`, `HAL_UART_Receive_IT` non réarmé.

Pour chacun : symptôme observé, méthode de localisation (quel outil du
débogueur ?), correction, et **la règle générale** en une phrase. (/1,5
par bug + /0,5 pour la qualité de la démarche décrite.)

## Barème

A /5 · B /10 · C /5 — **seuil : 14/20**. La capture « DMA qui bouge CPU
arrêté » est le jalon central de B : sans elle, B plafonne à 5/10, car
c'est la preuve que le DMA est compris et pas recopié.
