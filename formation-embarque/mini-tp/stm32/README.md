# Mini-TP STM32 — calculs de timer + PWM à compléter (30 min)

**Plateforme** : **STM32CubeIDE** (gratuit : https://www.st.com/stm32cubeide)
avec une Nucleo… ou sans : la **partie 1 est un exercice papier/calculette**
et la partie 2 se vérifie aussi en simulation :
- **Wokwi** propose des cartes ST Nucleo (support partiel, série et GPIO :
  https://wokwi.com) ;
- **Renode** (https://renode.io, open source) émule des STM32 complets ;
- à défaut, compiler dans CubeIDE et lire le code généré suffit pour
  valider les registres calculés.

**Prérequis** : cours 10 §3 (clock tree) et §4.3 (timers/PWM).

## Partie 1 — Les calculs (10 min, papier ; réponses en bas)

Le timer est cadencé à **f_tim = 100 MHz**. Rappel :
`f_PWM = f_tim / ((PSC+1) × (ARR+1))`, rapport cyclique = `CCR / (ARR+1)`.

1. Je veux un PWM à **20 kHz** (variateur silencieux) avec ARR = 999.
   PSC = ?
2. Je veux une **interruption toutes les 1 ms** avec PSC = 99. ARR = ?
3. Avec ARR = 999, quelle valeur de CCR pour un rapport cyclique de
   **30 %** ?
4. PSC = 65535, ARR = 65535 : quelle est la **période maximale** atteignable
   (en secondes) ? Pourquoi est-ce la limite d'un timer 16 bits ?

## Partie 2 — `pwm_a_trous.c` (20 min)

Projet CubeIDE pour ta carte (TIM2 CH1 en PWM, un potentiomètre sur ADC1
IN0 si tu as le matériel). Colle les blocs de
[`pwm_a_trous.c`](pwm_a_trous.c) entre les balises `USER CODE`
correspondantes et complète les 3 trous : valeurs PSC/ARR (tes calculs de
la partie 1 !), démarrage du PWM, et mise à jour du rapport cyclique.

**Validation** :
- avec matériel : LED (via résistance) sur PA0 → luminosité qui suit le
  potentiomètre ; ou oscilloscope/analyseur logique → 20 kHz mesurés ;
- sans matériel : point d'arrêt dans la boucle, vue **SFRs** → vérifier
  `TIM2->PSC`, `TIM2->ARR`, et `TIM2->CCR1` qui bouge quand tu modifies
  la variable `pot` au débogueur (Live Expressions).

---

<details>
<summary>Réponses de la partie 1 (vérifie APRÈS avoir calculé)</summary>

1. 100 MHz / (PSC+1) / 1000 = 20 kHz → PSC+1 = 5 → **PSC = 4**
2. 100 MHz / 100 = 1 MHz ; 1 ms = 1000 ticks → **ARR = 999**
3. 30 % de (999+1) → **CCR = 300**
4. 100e6 / 65536 / 65536 ≈ 0,0233 Hz → **≈ 43 s**. Les deux registres
   sont sur 16 bits : au-delà, il faut chaîner deux timers ou compter les
   débordements en logiciel.
</details>
