# Toolbox `automatique`

```
% Control System Toolbox — systèmes asservis linéaires.
%
% Les modèles sont des structures : « tf » porte num/den, « ss » porte
% A/B/C/D, et le champ Ts vaut 0 pour un modèle continu.
%
% Construction et conversion
%   tf, ss, zpk       - Construction de modèles
%   filt              - Modèle discret écrit en puissances de z^-1
%   tf2ss, ss2tf      - Conversions entre les deux représentations
%   ssdata, tfdata, zpkdata - Extraction des données d'un modèle
%   c2d, d2c, d2d     - Passage continu / discret et rééchantillonnage
%
% Propriétés
%   pole, zero, pzmap - Pôles et zéros
%   dcgain, damp      - Gain statique, pulsations et amortissements
%   order             - Nombre d'états
%   isstable, isproper, issiso, isct, isdt - Prédicats sur un modèle
%   dsort, esort      - Tri des pôles, discrets ou continus
%   minreal           - Réalisation minimale
%
% Réponses temporelles
%   step, impulse     - Réponses indicielle et impulsionnelle
%   initial           - Réponse libre à une condition initiale
%   lsim              - Réponse à une entrée quelconque
%   gensig            - Signaux d'essai périodiques
%   stepinfo          - Montée, établissement, dépassement
%   covar             - Covariance de la réponse à un bruit blanc
%
% Réponses fréquentielles
%   bode, nyquist, nichols - Les trois diagrammes
%   freqresp, evalfr  - Réponse complexe, en pulsation ou en un point
%   sigma             - Valeurs singulières de la matrice de transfert
%   margin, allmargin - Marges de gain, de phase et de retard
%   bandwidth         - Bande passante à -3 décibels
%
% Interconnexions
%   feedback, series, parallel - Boucle, cascade, somme
%   append            - Juxtaposition sans connexion
%
% Structure et changements de base
%   ctrb, obsv        - Matrices de commandabilité et d'observabilité
%   ctrbf, obsvf      - Formes échelonnées
%   canon             - Formes modale et compagne
%   ss2ss             - Changement de base quelconque
%   gram              - Grammiens de commandabilité et d'observabilité
%   tzero             - Zéros de transmission
%
% Réduction de modèle
%   hsvd              - Valeurs singulières de Hankel
%   balreal           - Réalisation équilibrée
%   modred, balred    - Élimination d'états, troncature équilibrée
%
% Équations matricielles
%   lyap, dlyap       - Lyapunov continue et discrète, Sylvester
%   care, dare        - Riccati continue et discrète
%
% Synthèse
%   place, acker      - Placement de pôles
%   lqr, dlqr         - Commande linéaire quadratique
%   lqry, lqi, lqrd   - Pondération sur la sortie, action intégrale,
%                       commande discrète d'un procédé continu
%   lqe, kalman       - Estimateur linéaire quadratique, filtre de Kalman
%   estim, reg        - Observateur seul, régulateur complet
%   pid, pidstd       - Correcteur PID, formes parallèle et standard
%   pidtune           - Réglage d'un PID par la marge de phase
%   rlocus            - Lieu des racines
```

## `acker`

```
ACKER Placement de pôles (identique à PLACE pour une entrée unique).
```

## `allmargin`

```
ALLMARGIN Toutes les marges de stabilité d'une boucle ouverte.
  M = ALLMARGIN(SYS) rend une structure aux champs
    GainMargin, GMFrequency    marges de gain et pulsations associées
    PhaseMargin, PMFrequency   marges de phase, en degrés
    DelayMargin, DMFrequency   retards purs supportables, en secondes
                               (en périodes d'échantillonnage si le
                               modèle est discret)
    Stable                     la boucle fermée est-elle stable

  À la différence de MARGIN, qui ne rend que la plus petite de chaque
  sorte, ALLMARGIN les rend toutes : une boucle peut traverser
  plusieurs fois le gain unité ou la phase -180 degrés.

  Exemple :
     m = allmargin(tf(1, [1 2 1 0]));
     m.GainMargin   % 2

  Voir aussi MARGIN, BODE, NYQUIST.
```

## `append`

```
APPEND Mise en parallèle sans connexion : modèle bloc-diagonal.
  SYS = APPEND(SYS1,SYS2,...) empile les modèles sans les relier :
  les entrées et les sorties se juxtaposent, et les matrices d'état
  forment des blocs diagonaux. C'est le produit direct des systèmes,
  à ne pas confondre avec PARALLEL, qui somme les sorties.

  Un scalaire est accepté et vaut pour un gain statique.

  Exemple :
     s = append(tf(1, [1 1]), tf(2, [1 2]));
     size(ssdata(s))   % 2 états

  Voir aussi PARALLEL, SERIES, FEEDBACK.
```

## `balreal`

```
BALREAL Réalisation équilibrée.
  [SYSB,G,T,TI] = BALREAL(SYS) change de base pour que les deux
  grammiens deviennent égaux et diagonaux :

     Wc = Wo = diag(G)

  G porte les valeurs singulières de Hankel, décroissantes. Dans cette
  base, chaque état est aussi facile à atteindre qu'à observer, ce qui
  donne un critère net pour décider lesquels supprimer.

  La construction passe par les facteurs de Cholesky Wc = Lc Lc' et
  Wo = Lo Lo' : si Lo' Lc = U S V', alors T = S^{-1/2} U' Lo' équilibre,
  et son inverse vaut TI = Lc V S^{-1/2}.

  Exemple :
     [sb, g] = balreal(ss([-1 0; 0 -2], [1; 1], [1 1], 0));
     max(abs(gram(sb, 'c') - gram(sb, 'o')))   % nul

  Voir aussi HSVD, MODRED, BALRED, GRAM.
```

## `balred`

```
BALRED Réduction d'ordre par troncature équilibrée.
  SYSR = BALRED(SYS,N) équilibre le modèle puis élimine les états dont
  la valeur singulière de Hankel est la plus faible, jusqu'à n'en
  garder que N. Le gain statique est conservé.

  SYSR = BALRED(SYS,N,'del') tronque au lieu de résiduer.
  [SYSR,G] = BALRED(...) rend aussi les valeurs singulières de Hankel du
  modèle de départ : l'erreur de réduction est bornée par le double de
  leur somme au-delà du rang N.

  Exemple :
     g = ss([-1 0; 0 -100], [1; 1], [1 1], 0);
     r = balred(g, 1);
     abs(dcgain(r) - dcgain(g)) < 1e-10   % vrai

  Voir aussi BALREAL, MODRED, HSVD.
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

## `canon`

```
CANON Formes canoniques d'un modèle d'état.
  [CSYS,T] = CANON(SYS,'modal') diagonalise A : chaque mode réel occupe
  une case de la diagonale, chaque paire complexe un bloc 2x2 de la
  forme [sigma omega; -omega sigma]. La base reste réelle.

  [CSYS,T] = CANON(SYS,'companion') met A sous forme compagne : des uns
  sous la diagonale et, dans la dernière colonne, les coefficients du
  polynôme caractéristique changés de signe. La transformation se lit
  sur la matrice de commandabilité, ce qui suppose le modèle
  commandable depuis sa première entrée.

  T est le changement de base : xbar = T*x, donc Abar = T A T^-1.

  Exemple :
     [c, t] = canon(ss([0 1; -2 -3], [0; 1], [1 0], 0), 'modal');
     diag(c.A)'   % [-1 -2]

  Voir aussi SS2SS, BALREAL, CTRBF.
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

## `covar`

```
COVAR Covariance de la réponse à un bruit blanc.
  [P,Q] = COVAR(SYS,W) rend la covariance P de la sortie et la
  covariance Q de l'état, en régime permanent, lorsque l'entrée est un
  bruit blanc d'intensité W.

  En continu, Q résout l'équation de Lyapunov A Q + Q A' + B W B' = 0 et
  P vaut C Q C'. Un modèle continu dont la transmission directe D n'est
  pas nulle donne une sortie de variance infinie : P vaut alors Inf,
  puisque le bruit blanc continu n'a pas de variance finie.

  En discret, Q = A Q A' + B W B' et P = C Q C' + D W D', toutes deux
  finies.

  Exemple :
     covar(ss(-1, 1, 1, 0), 1)   % 0.5

  Voir aussi GRAM, LYAP, DLYAP.
```

## `ctrb`

```
CTRB Matrice de commandabilité [B AB A^2B ...].
```

## `ctrbf`

```
CTRBF Forme échelonnée de commandabilité.
  [ABAR,BBAR,CBAR,T,K] = CTRBF(A,B,C) rend une base orthonormée dans
  laquelle la partie non commandable se sépare :

     Abar = T A T' = [ Anc   0  ]      Bbar = T B = [ 0  ]
                     [ A21   Ac ]                   [ Bc ]

  La paire (Ac,Bc) est commandable. K donne, échelon par échelon, le
  nombre d'états que chaque puissance de A ajoute à l'espace atteignable
  depuis B ; SUM(K) est la dimension de la partie commandable.

  Les échelons sont construits par orthonormalisation successive de
  B, AB, A^2B... : à chaque tour on ne garde que ce que le tour ajoute
  vraiment, ce qui rend la décomposition numériquement stable.

  Exemple :
     [ab, bb, cb, t, k] = ctrbf([1 0; 0 2], [1; 0], [1 1]);
     sum(k)   % 1 : un seul mode est commandable

  Voir aussi OBSVF, CTRB, MINREAL.
```

## `d2c`

```
D2C Repasse un modèle discret en continu (logarithme matriciel).
```

## `d2d`

```
D2D Rééchantillonnage d'un modèle discret.
  SYSD = D2D(SYS,TS) change la période d'échantillonnage : le modèle
  repasse en continu puis est rediscrétisé, ce qui préserve la réponse
  indicielle aux nouveaux instants d'échantillonnage.
  SYSD = D2D(SYS,TS,METHODE) choisit la méthode, 'zoh' par défaut ou
  'tustin'.

  Exemple :
     g = c2d(tf(1, [1 1]), 0.1);
     h = d2d(g, 0.2);
     abs(dcgain(h) - dcgain(g)) < 1e-10   % le gain statique se conserve

  Voir aussi C2D, D2C.
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
  [X,K,P] = DARE(...) rend en plus les pôles de la boucle fermée.

  La solution stabilisante est lue sur le sous-espace invariant stable
  de la matrice symplectique

     Z = [ A + B R^{-1} B' A^{-T} Q   -B R^{-1} B' A^{-T}
          -A^{-T} Q                    A^{-T}            ]

  dont les valeurs propres vont par paires (lambda, 1/lambda) : les n
  qui sont dans le cercle unité engendrent [X1; X2], et X = X2/X1.
  Quand A est singulière, cette construction n'existe pas et on retombe
  sur l'itération de Riccati, qui converge linéairement.

  Exemple :
     dare(1, 1, 1, 1)   % (1 + sqrt(5)) / 2, le nombre d'or
```

## `dcgain`

```
DCGAIN Gain statique d'un modèle.
  Pour un modèle continu, c'est H(0) ; en discret, H(1).
```

## `dlqr`

```
DLQR Commande linéaire quadratique en temps discret.
  [K,S,P] = DLQR(A,B,Q,R) minimise la somme de x'Qx + u'Ru sous
  x(k+1) = Ax(k) + Bu(k), et rend le gain K du retour u = -Kx, la
  solution S de l'équation de Riccati discrète et les pôles P de la
  boucle fermée.

  [K,S,P] = DLQR(A,B,Q,R,N) ajoute le terme croisé 2x'Nu.

  Exemple :
     dlqr(1, 1, 1, 1)   % 0.6180 : l'inverse du nombre d'or

  Voir aussi DARE, LQR, LQRD.
```

## `dlyap`

```
DLYAP Équation de Lyapunov discrète : A*X*A' - X + Q = 0.
  Exemple :
     dlyap(0.5, 1)   % 1/(1-0.25) = 1.3333
```

## `dsort`

```
DSORT Tri des pôles discrets par module décroissant.
  [S,I] = DSORT(P) range les pôles du plus rapide au plus lent au sens
  du temps discret : le module le plus grand vient en premier, puisque
  c'est lui qui domine la réponse.

  Exemple :
     dsort([0.5; 0.9; 0.1])   % [0.9; 0.5; 0.1]

  Voir aussi ESORT, POLE, DAMP.
```

## `esort`

```
ESORT Tri des pôles continus par partie réelle décroissante.
  [S,I] = ESORT(P) range les pôles du moins stable au plus stable : la
  partie réelle la plus grande vient en premier.

  Exemple :
     esort([-3; -1; -2])   % [-1; -2; -3]

  Voir aussi DSORT, POLE, DAMP.
```

## `estim`

```
ESTIM Estimateur d'état à partir d'un gain d'observation.
  EST = ESTIM(SYS,L) construit l'observateur

     dxe/dt = A xe + L (y - C xe)

  dont les sorties sont [ye; xe] : la sortie reconstruite puis l'état
  estimé. L'entrée est la mesure y.

  EST = ESTIM(SYS,L,CAPTEURS) précise quelles sorties de SYS sont
  mesurées ; EST = ESTIM(SYS,L,CAPTEURS,CONNUES) précise en plus
  quelles entrées sont connues de l'estimateur, qui prend alors
  [u connues; y mesurées].

  Exemple :
     e = estim(ss(-1, 1, 1, 0), 2);
     pole(e)   % -3 : l'observateur est plus rapide que le procédé

  Voir aussi REG, KALMAN, LQE, PLACE.
```

## `evalfr`

```
EVALFR Valeur de la transmittance en un point du plan complexe.
  H = EVALFR(SYS,X) rend H(X). C'est la fonction de transfert évaluée
  telle quelle : à la différence de FREQRESP, X n'est pas interprété
  comme une pulsation, mais comme la variable de Laplace ou de la
  transformée en Z.

  Exemple :
     evalfr(tf(1, [1 1]), 0)    % 1 : le gain statique
     evalfr(tf(1, [1 1]), 1i)   % 0.5 - 0.5i

  Voir aussi FREQRESP, DCGAIN.
```

## `feedback`

```
FEEDBACK Boucle fermée.
  SYS = FEEDBACK(G,H) rend G/(1+GH) : contre-réaction négative.
  SYS = FEEDBACK(G,H,+1) rend G/(1-GH).
```

## `filt`

```
FILT Modèle discret écrit en puissances de z^-1.
  SYS = FILT(NUM,DEN) construit le modèle

     H(z) = (num(1) + num(2) z^-1 + ...) / (den(1) + den(2) z^-1 + ...)

  C'est la convention du traitement du signal, où les coefficients
  suivent les retards. FILT(NUM,DEN,TS) fixe la période
  d'échantillonnage ; sans elle, la période vaut -1, ce qui désigne un
  modèle discret de période non précisée.

  Exemple :
     g = filt([1 0.5], [1 -0.3]);
     tfdata(g)   % [1 0.5] : les deux écritures coïncident ici

  Voir aussi TF, C2D.
```

## `freqresp`

```
FREQRESP Réponse fréquentielle complexe.
  H = FREQRESP(SYS,W) évalue la transmittance à chaque pulsation de W :
  H(jW) en continu, H(exp(jW*TS)) en discret.

  Pour un modèle monovariable, H est un vecteur de la taille de W ; pour
  un modèle d'état à plusieurs entrées ou sorties, c'est un tableau
  NY x NU x NUMEL(W).

  [H,W] = FREQRESP(SYS) choisit lui-même la grille de pulsations.

  Exemple :
     abs(freqresp(tf(1, [1 1]), 1))   % 1/sqrt(2)

  Voir aussi BODE, EVALFR, SIGMA, NICHOLS.
```

## `gensig`

```
GENSIG Signaux d'essai périodiques.
  [U,T] = GENSIG(TYPE,TAU) engendre un signal de période TAU :
    'sin'      sinusoïde
    'square'   créneau, un pendant la première demi-période, zéro ensuite
    'pulse'    impulsion d'un échantillon au début de chaque période

  [U,T] = GENSIG(TYPE,TAU,TF) fixe la durée totale, cinq périodes par
  défaut ; [U,T] = GENSIG(TYPE,TAU,TF,TS) fixe le pas d'échantillonnage,
  TAU/64 par défaut.

  Le signal se donne directement à LSIM.

  Exemple :
     [u, t] = gensig('square', 4, 12, 0.1);
     y = lsim(tf(1, [1 1]), u, t);

  Voir aussi LSIM, STEP, IMPULSE.
```

## `gram`

```
GRAM Grammiens de commandabilité et d'observabilité.
  W = GRAM(SYS,'c') résout A*W + W*A' + B*B' = 0 ;
  W = GRAM(SYS,'o') résout A'*W + W*A + C'*C = 0.

  Exemple :
     gram(ss(-1, 1, 1, 0), 'c')   % 0.5
```

## `hsvd`

```
HSVD Valeurs singulières de Hankel d'un modèle stable.
  G = HSVD(SYS) rend, par ordre décroissant, les racines carrées des
  valeurs propres du produit des deux grammiens :

     g = sqrt(eig(Wc * Wo))

  Chaque valeur mesure ce qu'un état apporte à la relation entrée-sortie :
  celles qui sont petites désignent les états qu'on peut retirer sans
  changer sensiblement la réponse. C'est sur elles que reposent BALRED
  et MODRED.

  Exemple :
     hsvd(ss(-1, 1, 1, 0))   % 0.5

  Voir aussi BALREAL, BALRED, MODRED, GRAM.
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

## `isct`

```
ISCT Le modèle est-il à temps continu ?
  Vrai quand la période d'échantillonnage est nulle.

  Exemple :
     isct(tf(1, [1 1]))       % vrai
     isct(tf(1, [1 -0.5], 0.1))   % faux

  Voir aussi ISDT, C2D, D2C.
```

## `isdt`

```
ISDT Le modèle est-il à temps discret ?
  Vrai quand la période d'échantillonnage n'est pas nulle. Une période
  de -1 désigne, comme dans MATLAB, un modèle discret dont la période
  n'est pas précisée.

  Exemple :
     isdt(tf(1, [1 -0.5], 0.1))   % vrai

  Voir aussi ISCT, C2D, D2C.
```

## `isproper`

```
ISPROPER Le modèle est-il propre ?
  ISPROPER(SYS) est vrai quand le degré du numérateur ne dépasse pas
  celui du dénominateur : le modèle est alors réalisable par un système
  d'état. Un modèle donné sous forme d'état l'est toujours.

  Exemple :
     isproper(tf(1, [1 1]))     % vrai
     isproper(tf([1 0], 1))     % faux : un dérivateur pur

  Voir aussi ISSTABLE, ORDER.
```

## `issiso`

```
ISSISO Le modèle a-t-il une entrée et une sortie ?
  Les fonctions de transfert le sont toujours ; un modèle d'état ne
  l'est que si B a une colonne et C une ligne.

  Exemple :
     issiso(ss([0 1; 0 0], [0; 1], [1 0], 0))   % vrai

  Voir aussi ORDER, SSDATA.
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

## `lqi`

```
LQI Commande linéaire quadratique avec action intégrale.
  [K,S,P] = LQI(SYS,Q,R) ajoute au modèle un état intégrateur par
  sortie, dont la dérivée est l'écart de consigne :

     dxi/dt = r - y = r - Cx - Du

  puis résout le problème quadratique sur l'état augmenté [x; xi]. Le
  retour u = -K [x; xi] annule l'erreur statique.

  Q doit être carrée de taille NX+NY, R de taille NU.

  Exemple :
     k = lqi(ss(-1, 1, 1, 0), eye(2), 1);
     numel(k)   % 2 : un gain d'état et un gain d'intégrateur

  Voir aussi LQR, LQRY, LQE.
```

## `lqr`

```
LQR Commande linéaire quadratique en temps continu.
  [K,S,P] = LQR(A,B,Q,R) minimise l'intégrale de x'Qx + u'Ru sous
  dx/dt = Ax + Bu, et rend le gain K du retour u = -Kx, la solution S
  de l'équation de Riccati et les pôles P de la boucle fermée.

  [K,S,P] = LQR(A,B,Q,R,N) ajoute le terme croisé 2x'Nu au coût. Il se
  ramène au cas sans terme croisé en posant
     Atilde = A - B R^{-1} N',   Qtilde = Q - N R^{-1} N',
  puis K = R^{-1} (B'S + N').

  LQR(SYS,Q,R,N) accepte aussi un modèle d'état.

  Exemple :
     lqr(0, 1, 1, 1)   % 1 : le gain qui place le pôle en -1

  Voir aussi CARE, DLQR, LQRY, LQI.
```

## `lqrd`

```
LQRD Commande discrète d'un procédé continu.
  [K,S,P] = LQRD(A,B,Q,R,TS) rend le gain du retour d'état discret qui
  minimise le coût continu

     integrale de x'Qx + u'Ru

  lorsque la commande est maintenue constante entre deux instants
  d'échantillonnage. Ce n'est pas la même chose que discrétiser le
  procédé puis appliquer DLQR au coût discret naïf : il faut intégrer le
  coût sur chaque intervalle, ce qui fait apparaître un terme croisé.

  L'intégration est exacte. En augmentant l'état de la commande, qui
  est constante par morceaux, le problème se ramène à une seule
  exponentielle de matrice (méthode de Van Loan) :

     expm([-Aa'  Qa ; 0  Aa] * TS)

  dont les blocs donnent d'un coup Ad, Bd, Qd, Nd et Rd.

  Exemple :
     k = lqrd(0, 1, 1, 1, 0.01);   % voisin de lqr(0,1,1,1) = 1

  Voir aussi DLQR, LQR, C2D.
```

## `lqry`

```
LQRY Commande linéaire quadratique pondérée sur la sortie.
  [K,S,P] = LQRY(SYS,Q,R) minimise l'intégrale de y'Qy + u'Ru, où y est
  la sortie du modèle. Comme y = Cx + Du, cela revient à un problème
  pondéré sur l'état avec

     Qx = C'QC,   Rx = R + D'QD,   Nx = C'QD

  [K,S,P] = LQRY(SYS,Q,R,N) ajoute le terme croisé 2y'Nu.

  Exemple :
     lqry(ss(0, 1, 1, 0), 1, 1)   % 1

  Voir aussi LQR, LQI, DLQR.
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

## `modred`

```
MODRED Élimination d'états d'un modèle.
  SYSR = MODRED(SYS,ELIM) retire les états dont les indices figurent
  dans ELIM, en conservant le gain statique : les états éliminés sont
  supposés à l'équilibre, ce qui donne la résiduation

     Ar = A11 - A12 A22^-1 A21,   Br = B1 - A12 A22^-1 B2
     Cr = C1  - C2  A22^-1 A21,   Dr = D  - C2  A22^-1 B2

  SYSR = MODRED(SYS,ELIM,'del') tronque au lieu de résiduer : les états
  éliminés sont simplement supprimés, ce qui préserve la réponse en
  haute fréquence mais fausse le gain statique.

  ELIM peut être un vecteur d'indices ou un vecteur logique.

  Exemple :
     [sb, g] = balreal(ss([-1 0; 0 -100], [1; 1], [1 1], 0));
     r = modred(sb, 2);
     abs(dcgain(r) - dcgain(sb)) < 1e-10   % vrai : le gain se conserve

  Voir aussi BALREAL, BALRED, HSVD.
```

## `nichols`

```
NICHOLS Diagramme de Nichols : gain en décibels contre phase.
  [MAG,PHASE,W] = NICHOLS(SYS) rend le module (linéaire) et la phase en
  degrés, comme BODE. La différence est dans le tracé : sans sortie, la
  fonction porte le gain en ordonnée et la phase en abscisse, ce qui
  fait apparaître d'un coup les deux marges.

  Exemple :
     [m, p] = nichols(tf(1, [1 1 1]));

  Voir aussi BODE, NYQUIST, MARGIN.
```

## `nyquist`

```
NYQUIST Lieu de Nyquist.
```

## `obsv`

```
OBSV Matrice d'observabilité [C; CA; CA^2; ...].
```

## `obsvf`

```
OBSVF Forme échelonnée d'observabilité.
  [ABAR,BBAR,CBAR,T,K] = OBSVF(A,B,C) rend une base orthonormée dans
  laquelle la partie non observable se sépare :

     Abar = T A T' = [ Ano  A12 ]      Cbar = C T' = [ 0  Co ]
                     [  0   Ao  ]

  C'est le dual exact de CTRBF : la forme s'obtient en appliquant
  CTRBF au triplet transposé (A', C', B') puis en retransposant.

  Exemple :
     [ab, bb, cb, t, k] = obsvf([1 0; 0 2], [1; 1], [1 0]);
     sum(k)   % 1 : un seul mode est observable

  Voir aussi CTRBF, OBSV, MINREAL.
```

## `order`

```
ORDER Nombre d'états du modèle.
  Pour un modèle d'état, c'est la dimension de A ; pour une fonction de
  transfert, le degré du dénominateur une fois les zéros de tête
  retirés.

  Exemple :
     order(tf(1, [1 2 1]))   % 2

  Voir aussi MINREAL, SSDATA.
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

## `pidstd`

```
PIDSTD Correcteur PID sous forme standard.
  C = PIDSTD(KP,TI,TD,N) rend

     C(s) = KP * ( 1 + 1/(TI s) + TD s / ((TD/N) s + 1) )

  C'est l'écriture des automaticiens : un gain global, un temps
  d'intégration et un temps de dérivation, plutôt que trois gains
  indépendants. N est le rapport de filtrage du terme dérivé, infini
  par défaut, ce qui donne une dérivée pure.

  C = PIDSTD(...,TS) rend un correcteur échantillonné.

  La forme parallèle de PID s'en déduit par KI = KP/TI et KD = KP*TD.

  Exemple :
     c = pidstd(2, 1, 0);
     tfdata(c)   % [2 2] / [1 0] : 2 + 2/s

  Voir aussi PID, PIDTUNE.
```

## `pidtune`

```
PIDTUNE Réglage d'un correcteur PID par la marge de phase.
  C = PIDTUNE(SYS,TYPE) règle un correcteur de type 'p', 'pi', 'pd',
  'pid', 'pdf' ou 'pidf' pour que la boucle ouverte C*SYS traverse le
  gain unité avec une marge de phase de soixante degrés.

  La méthode est celle du façonnage de boucle : on choisit la pulsation
  de coupure là où la phase du procédé vaut ce que le correcteur peut
  compenser — -100 degrés pour un PI, qui retarde d'une vingtaine de
  degrés, -165 pour un PID, qui avance d'une quarantaine — puis on
  impose au correcteur, en cette pulsation, le module et l'argument qui
  donnent exactement la marge voulue :

     |C(jwc)| = 1 / |G(jwc)|
     arg C(jwc) = -180 + PM - arg G(jwc)

  Pour un PID, ces deux équations ne suffisent pas à fixer les trois
  gains : on ajoute la relation classique TI = 4 TD.

  C = PIDTUNE(SYS,TYPE,WC) impose la pulsation de coupure.

  [C,INFO] = PIDTUNE(...) rend une structure aux champs Stable,
  CrossoverFrequency et PhaseMargin.

  Exemple :
     c = pidtune(tf(1, [1 3 3 1]), 'pi');
     [gm, pm] = margin(series(c, tf(1, [1 3 3 1])));
     pm    % 60 degrés, par construction

  Voir aussi PID, PIDSTD, MARGIN.
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

## `pzmap`

```
PZMAP Pôles et zéros d'un modèle.
  [P,Z] = PZMAP(SYS) rend les pôles et les zéros en colonnes. Sans
  sortie, la fonction les place dans le plan complexe : les pôles par
  des croix, les zéros par des ronds.

  Exemple :
     [p, z] = pzmap(tf([1 1], [1 3 2]));   % p = [-2;-1], z = -1

  Voir aussi POLE, ZERO, DAMP, RLOCUS.
```

## `reg`

```
REG Régulateur par retour d'état estimé.
  RSYS = REG(SYS,K,L) assemble l'observateur de gain L et le retour
  d'état u = -K xe en un seul correcteur, qui prend la mesure y et rend
  la commande u :

     dxe/dt = (A - BK - LC + LDK) xe + L y
     u      = -K xe

  Le signe moins du retour est déjà dans le correcteur : la boucle se
  referme donc en contre-réaction positive, FEEDBACK(SERIES(C,G),1,+1).

  Les pôles du correcteur ne sont ni ceux de A-BK ni ceux de A-LC :
  c'est la boucle fermée complète, d'ordre 2n, qui a pour pôles la
  réunion des deux, en vertu du principe de séparation.

  Exemple :
     g = ss([0 1; -2 -3], [0; 1], [1 0], 0);
     k = place(g.A, g.B, [-3 -4]);
     l = place(g.A', g.C', [-10 -12])';
     c = reg(g, k, l);
     sort(pole(feedback(series(c, g), 1, +1)))   % -12 -10 -4 -3

  Voir aussi ESTIM, PLACE, LQR, KALMAN.
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

## `sigma`

```
SIGMA Valeurs singulières de la réponse fréquentielle.
  SV = SIGMA(SYS,W) rend, pour chaque pulsation, les valeurs
  singulières de la matrice de transfert, rangées par ligne et
  décroissantes. Pour un modèle monovariable, il n'y en a qu'une, égale
  au module de la réponse : c'est le diagramme de gain.

  [SV,W] = SIGMA(SYS) choisit lui-même la grille de pulsations.

  Sans sortie, la fonction trace les valeurs singulières en décibels.

  Exemple :
     max(sigma(tf(1, [1 1])))   % 1 : le gain le plus fort est en zéro

  Voir aussi FREQRESP, BODE, HINFNORM.
```

## `ss`

```
SS Modèle d'état.
  SYS = SS(A,B,C,D) crée un modèle continu dx/dt = Ax + Bu, y = Cx + Du.
  SYS = SS(A,B,C,D,TS) crée un modèle échantillonné.
  SYS = SS(SYS) convertit n'importe quel modèle en modèle d'état : une
  fonction de transfert passe par TF2SS, forme compagne de commande.
  SYS = SS(K) crée un gain statique, sans état.

  Exemple :
     s = ss(tf(1, [1 1]));   % A = -1, B = 1, C = 1, D = 0

  Voir aussi TF, ZPK, SSDATA, TF2SS.
```

## `ss2ss`

```
SS2SS Changement de base d'un modèle d'état.
  SYST = SS2SS(SYS,T) applique le changement de variable xbar = T*x :

     Abar = T A T^-1,  Bbar = T B,  Cbar = C T^-1,  Dbar = D

  La fonction de transfert ne change pas ; seule la réalisation change.

  Exemple :
     s = ss([0 1; -2 -3], [0; 1], [1 0], 0);
     t = ss2ss(s, [1 0; 1 1]);
     max(abs(pole(t) - pole(s)))   % nul

  Voir aussi CANON, BALREAL, CTRBF, OBSVF.
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

## `ssdata`

```
SSDATA Matrices d'état d'un modèle.
  [A,B,C,D] = SSDATA(SYS) rend les quatre matrices, quelle que soit la
  forme sous laquelle le modèle a été construit : une fonction de
  transfert est d'abord réalisée sous forme compagne de commande.
  [A,B,C,D,TS] = SSDATA(SYS) rend en plus la période d'échantillonnage.

  Exemple :
     [a, b, c, d] = ssdata(tf(1, [1 1]));   % a = -1, b = 1, c = 1, d = 0

  Voir aussi TFDATA, ZPKDATA, SS.
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
  SYS = TF(K) crée un gain statique.
  SYS = TF(SYS) convertit n'importe quel modèle en fonction de
  transfert : un modèle d'état passe par SS2TF.

  Exemple :
     G = tf([1], [1 2 1]);   % 1/(s+1)^2
     tf(ss(-1, 1, 1, 0))     % 1/(s+1)

  Voir aussi SS, ZPK, TFDATA, SS2TF.
```

## `tf2ss`

```
TF2SS Forme compagne de commande d'une fonction de transfert.
  [A,B,C,D] = TF2SS(NUM,DEN) rend la réalisation d'état canonique.
```

## `tfdata`

```
TFDATA Numérateur et dénominateur d'un modèle.
  [NUM,DEN] = TFDATA(SYS) rend les deux polynômes, par puissances
  décroissantes. Comme les modèles sont monovariables, NUM et DEN sont
  des vecteurs ; TFDATA(SYS,'v') est accepté et rend la même chose.
  [NUM,DEN,TS] = TFDATA(SYS) rend en plus la période d'échantillonnage.

  Exemple :
     [n, d] = tfdata(ss(-1, 1, 1, 0));   % n = [0 1], d = [1 1]

  Voir aussi SSDATA, ZPKDATA, TF.
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
  SYS = ZPK(Z,P,K) construit la fonction de transfert

     K * prod(s - Z) / prod(s - P)

  SYS = ZPK(Z,P,K,TS) construit un modèle échantillonné.
  SYS = ZPK(K) construit un gain statique.
  SYS = ZPK(SYS) convertit un modèle quelconque : les zéros et les
  pôles sont recalculés, puis le produit reformé.

  Le modèle rendu porte le type 'tf' : la représentation interne reste
  celle des polynômes, ZPKDATA rendant les zéros et les pôles à la
  demande.

  Exemple :
     g = zpk(-1, [-2 -3], 6);
     dcgain(g)   % 1

  Voir aussi TF, SS, ZPKDATA, ZP2TF.
```

## `zpkdata`

```
ZPKDATA Zéros, pôles et gain d'un modèle.
  [Z,P,K] = ZPKDATA(SYS) rend les zéros et les pôles en colonnes, et le
  gain. ZPKDATA(SYS,'v') est accepté et rend la même chose.
  [Z,P,K,TS] = ZPKDATA(SYS) rend en plus la période d'échantillonnage.

  Exemple :
     [z, p, k] = zpkdata(tf([2 2], [1 3 2]));   % z = -1, p = [-2;-1], k = 2

  Voir aussi SSDATA, TFDATA, ZPK.
```

