# Toolbox `automatique`

```
% Control System Toolbox — systèmes asservis linéaires.
%
% Les modèles sont des structures : « tf » porte num/den, « ss » porte
% A/B/C/D, et le champ Ts vaut 0 pour un modèle continu.
%
%   tf, ss, zpk       - Construction de modèles
%   tf2ss, ss2tf      - Conversions
%   step, impulse     - Réponses temporelles
%   lsim              - Réponse à une entrée quelconque
%   bode, nyquist     - Réponses fréquentielles
%   margin            - Marges de gain et de phase
%   feedback, series, parallel - Interconnexions
%   pole, zero, dcgain, damp   - Caractéristiques
%   c2d, d2c          - Passage continu / discret
%   ctrb, obsv        - Commandabilité, observabilité
%   place             - Placement de pôles (Ackermann)
%   lqr, dlqr         - Commande linéaire quadratique
%   rlocus            - Lieu des racines
```

## `acker`

```
ACKER Placement de pôles (identique à PLACE pour une entrée unique).
```

## `bode`

```
BODE Réponse fréquentielle : module et phase.
  [MODULE,PHASE,W] = BODE(SYS) rend le module (linéaire) et la phase en
  degrés. Sans sortie, la fonction trace les deux diagrammes.
```

## `c2d`

```
C2D Discrétisation d'un modèle continu.
  SYSD = C2D(SYS,TS) utilise le bloqueur d'ordre zéro.
  SYSD = C2D(SYS,TS,'tustin') utilise la transformation bilinéaire.
```

## `ctrb`

```
CTRB Matrice de commandabilité [B AB A^2B ...].
```

## `d2c`

```
D2C Repasse un modèle discret en continu (logarithme matriciel).
```

## `damp`

```
DAMP Pulsations propres et amortissements.
  [WN,ZETA] = DAMP(SYS) rend, pour chaque pôle, la pulsation propre et
  le coefficient d'amortissement.
```

## `dcgain`

```
DCGAIN Gain statique d'un modèle.
  Pour un modèle continu, c'est H(0) ; en discret, H(1).
```

## `dlqr`

```
DLQR Commande linéaire quadratique en temps discret.
```

## `feedback`

```
FEEDBACK Boucle fermée.
  SYS = FEEDBACK(G,H) rend G/(1+GH) : contre-réaction négative.
  SYS = FEEDBACK(G,H,+1) rend G/(1-GH).
```

## `impulse`

```
IMPULSE Réponse impulsionnelle.
```

## `lqr`

```
LQR Commande linéaire quadratique en temps continu.
  [K,S] = LQR(A,B,Q,R) minimise l'intégrale de x'Qx + u'Ru. S est la
  solution de l'équation de Riccati, résolue par itération sur la
  version discrétisée.
```

## `lsim`

```
LSIM Réponse d'un modèle à une entrée quelconque.
  [Y,T] = LSIM(SYS,U,T) simule la réponse à l'entrée U aux instants T.
  La discrétisation se fait par bloqueur d'ordre zéro sur le pas moyen.
```

## `margin`

```
MARGIN Marges de gain et de phase.
  [GM,PM,WGM,WPM] = MARGIN(SYS) rend la marge de gain (linéaire), la
  marge de phase (degrés) et les pulsations correspondantes.
```

## `nyquist`

```
NYQUIST Lieu de Nyquist.
```

## `obsv`

```
OBSV Matrice d'observabilité [C; CA; CA^2; ...].
```

## `parallel`

```
PARALLEL Mise en parallèle de deux modèles (somme des sorties).
```

## `place`

```
PLACE Placement de pôles par la formule d'Ackermann.
  K = PLACE(A,B,POLES) rend le retour d'état u = -Kx qui place les
  valeurs propres de A-BK aux valeurs demandées (entrée unique).
```

## `pole`

```
POLE Pôles d'un modèle linéaire.
```

## `rlocus`

```
RLOCUS Lieu des racines de la boucle fermée.
  [R,K] = RLOCUS(SYS) rend, pour une série de gains K, les pôles de
  1 + K*SYS.
```

## `series`

```
SERIES Mise en série de deux modèles.
  SYS = SERIES(SYS1,SYS2) équivaut à SYS2 * SYS1.
```

## `ss`

```
SS Modèle d'état.
  SYS = SS(A,B,C,D) crée un modèle continu dx/dt = Ax + Bu, y = Cx + Du.
  SYS = SS(A,B,C,D,TS) crée un modèle échantillonné.
  SYS = SS(SYSTF) convertit une fonction de transfert en modèle d'état.
```

## `ss2tf`

```
SS2TF Fonction de transfert d'un modèle d'état.
  [NUM,DEN] = SS2TF(A,B,C,D) applique la formule
  H(s) = C (sI - A)^-1 B + D, calculée par l'algorithme de
  Leverrier-Faddeev.
```

## `step`

```
STEP Réponse indicielle.
  [Y,T] = STEP(SYS) simule la réponse à un échelon unité.
  [Y,T] = STEP(SYS,TFINAL) impose l'horizon de simulation.
```

## `tf`

```
TF Modèle sous forme de fonction de transfert.
  SYS = TF(NUM,DEN) crée un modèle continu dont la transmittance est le
  quotient des polynômes NUM et DEN, écrits en puissances décroissantes.
  SYS = TF(NUM,DEN,TS) crée un modèle échantillonné de période TS.

  Exemple :
     G = tf([1], [1 2 1]);   % 1/(s+1)^2
```

## `tf2ss`

```
TF2SS Forme compagne de commande d'une fonction de transfert.
  [A,B,C,D] = TF2SS(NUM,DEN) rend la réalisation d'état canonique.
```

## `zero`

```
ZERO Zéros d'un modèle linéaire.
```

## `zpk`

```
ZPK Modèle par zéros, pôles et gain.
  SYS = ZPK(Z,P,K) construit la fonction de transfert correspondante.
```

