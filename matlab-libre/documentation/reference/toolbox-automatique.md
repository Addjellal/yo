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
%
% Équations matricielles
%   lyap        - Lyapunov continue, et Sylvester
%   dlyap       - Lyapunov discrète
%   care        - Riccati continue, par la matrice hamiltonienne
%   dare        - Riccati discrète
%   gram        - Grammiens de commandabilité et d'observabilité
%
% Analyse
%   tzero       - Zéros de transmission
%   initial     - Réponse libre à une condition initiale
%   stepinfo    - Montée, établissement, dépassement
%   bandwidth   - Bande passante à -3 décibels
%   minreal     - Réalisation minimale
%
% Synthèse
%   pid         - Correcteur proportionnel intégral dérivé
%   lqe         - Gain de l'estimateur linéaire quadratique
%   kalman      - Filtre de Kalman en régime permanent
```

## `acker`

```
ACKER Placement de pôles (identique à PLACE pour une entrée unique).
```

## `bandwidth`

```
BANDWIDTH Bande passante d'un système.
  W = BANDWIDTH(SYS) rend la première pulsation où le gain descend de
  3 décibels sous sa valeur en continu. BANDWIDTH(SYS,CHUTE) choisit
  une autre chute, en décibels (négative).

  Exemple :
     bandwidth(tf(1, [1 1]))   % 1 rad/s
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

## `care`

```
CARE Équation de Riccati algébrique continue.
  X = CARE(A,B,Q,R) résout A'X + XA - XBR^{-1}B'X + Q = 0.
  [X,K,P] = CARE(...) rend aussi le gain K = R^{-1}B'X et les pôles de
  la boucle fermée.

  La solution stabilisante s'obtient par la matrice hamiltonienne
     H = [ A      -B R^{-1} B'
          -Q      -A'        ]
  dont le sous-espace propre stable, engendré par les colonnes
  [X1; X2], donne X = X2 / X1. C'est la construction de Potter, exacte
  dès que le problème admet une solution stabilisante.

  Exemple :
     care(0, 1, 1, 1)     % 1
     care([0 1; 0 0], [0; 1], eye(2), 1)
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

## `dare`

```
DARE Équation de Riccati algébrique discrète.
  X = DARE(A,B,Q,R) résout A'XA - X - A'XB(B'XB+R)^{-1}B'XA + Q = 0.
  [X,K] = DARE(...) rend le gain K = (B'XB+R)^{-1}B'XA.

  L'itération part de X = Q et applique l'équation jusqu'au point fixe.
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

## `dlyap`

```
DLYAP Équation de Lyapunov discrète : A*X*A' - X + Q = 0.
  Exemple :
     dlyap(0.5, 1)   % 1/(1-0.25) = 1.3333
```

## `feedback`

```
FEEDBACK Boucle fermée.
  SYS = FEEDBACK(G,H) rend G/(1+GH) : contre-réaction négative.
  SYS = FEEDBACK(G,H,+1) rend G/(1-GH).
```

## `gram`

```
GRAM Grammiens de commandabilité et d'observabilité.
  W = GRAM(SYS,'c') résout A*W + W*A' + B*B' = 0 ;
  W = GRAM(SYS,'o') résout A'*W + W*A + C'*C = 0.

  Exemple :
     gram(ss(-1, 1, 1, 0), 'c')   % 0.5
```

## `impulse`

```
IMPULSE Réponse impulsionnelle.
```

## `initial`

```
INITIAL Réponse libre d'un système d'état à une condition initiale.
  [Y,T,X] = INITIAL(SYS,X0,TFINAL) intègre xdot = A x sans entrée.

  Exemple :
     s = ss(-1, 0, 1, 0);
     y = initial(s, 1, 5);   % y(1) == 1, décroissance en exp(-t)
```

## `kalman`

```
KALMAN Filtre de Kalman en régime permanent.
  [EST,L,P] = KALMAN(SYS,Q,R) rend le gain L, la covariance P et le
  système estimateur dont l'état suit celui de SYS.

  Le modèle est dx/dt = Ax + Bu + w, y = Cx + Du + v, avec w de
  covariance Q et v de covariance R.
```

## `lqe`

```
LQE Estimateur linéaire quadratique : le gain du filtre de Kalman.
  [L,P] = LQE(A,G,C,Q,R) résout l'équation de Riccati duale et rend le
  gain L = P*C'/R, où P est la covariance d'estimation en régime
  permanent.

  Exemple :
     L = lqe(0, 1, 1, 1, 1);   % 1
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

## `lyap`

```
LYAP Équation de Lyapunov continue.
  X = LYAP(A,Q) résout A*X + X*A' + Q = 0.
  X = LYAP(A,B,C) résout A*X + X*B + C = 0 (Sylvester).

  La résolution passe par la forme vectorisée : le produit de
  Kronecker transforme l'équation matricielle en système linéaire.

  Exemple :
     lyap(-1, 1)   % 0.5
```

## `margin`

```
MARGIN Marges de gain et de phase.
  [GM,PM,WGM,WPM] = MARGIN(SYS) rend la marge de gain (linéaire), la
  marge de phase (degrés) et les pulsations correspondantes.
```

## `minreal`

```
MINREAL Réalisation minimale : supprime les pôles et zéros qui s'annulent.
  SYS = MINREAL(SYS,TOL) compare les racines du numérateur et du
  dénominateur, et retire les paires plus proches que TOL.

  Exemple :
     s = minreal(tf(conv([1 2], [1 1]), conv([1 2], [1 3])));
     s.den   % [1 3] : le pôle en -2 a disparu
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

## `pid`

```
PID Correcteur proportionnel intégral dérivé.
  C = PID(KP,KI,KD,TF) rend la fonction de transfert
  KP + KI/s + KD*s/(TF*s+1). Avec TF nul, le terme dérivé est pur.
  C = PID(...,TS) donne un correcteur échantillonné.

  Exemple :
     c = pid(2, 1, 0);          % (2s + 1)/s
     dcgain(pid(1, 0, 0))       % 1
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
  [NUM,DEN] = SS2TF(A,B,C,D) applique H(s) = C (sI - A)^-1 B + D par
  l'algorithme de Leverrier-Faddeev : les matrices M_k de l'adjointe
  se calculent par récurrence, en même temps que les coefficients du
  dénominateur.

  Avec den(s) = s^n + a1 s^(n-1) + ... + an, l'adjointe vaut
  M_0 s^(n-1) + ... + M_(n-1) avec M_0 = I et M_k = A*M_(k-1) + a_k I.
  Le numérateur est donc de degré n, et son terme de tête vaut D.

  Exemple :
     [n, d] = ss2tf(-1, 1, -1, 1);   % n = [1 0], d = [1 1] : s/(s+1)

  SS2TF(A,B,C,D,IU) choisit l'entrée IU d'un modèle à plusieurs
  entrées : seule la colonne IU de B et de D est retenue.
```

## `step`

```
STEP Réponse indicielle.
  [Y,T] = STEP(SYS) simule la réponse à un échelon unité.
  [Y,T] = STEP(SYS,TFINAL) impose l'horizon de simulation.
```

## `stepinfo`

```
STEPINFO Caractéristiques de la réponse indicielle.
  S = STEPINFO(SYS) rend RiseTime, SettlingTime, Overshoot, Undershoot,
  Peak et PeakTime, définis comme dans la documentation MathWorks :
  temps de montée de 10 % à 90 %, temps d'établissement à 2 %,
  dépassement en pourcentage de la valeur finale.

  Exemple :
     s = stepinfo(tf(1, [1 1]));   % premier ordre : pas de dépassement
     s.Overshoot                   % 0
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

## `tzero`

```
TZERO Zéros de transmission d'un système d'état.
  Z = TZERO(A,B,C,D) ou TZERO(SYS). Ce sont les valeurs de s pour
  lesquelles la matrice de Rosenbrock [A-sI B; C D] perd son rang :
  le transfert s'y annule, quelle que soit la direction d'entrée.

  Quand D est inversible, ces valeurs sont exactement les valeurs
  propres de A - B*inv(D)*C : c'est le résultat classique, et c'est ce
  qui est calculé ici. Sinon, on passe par la fonction de transfert.

  Exemple :
     tzero(-1, 1, -1, 1)   % 0 : le transfert vaut s/(s+1)
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

