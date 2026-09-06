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
%   rss, drss         - Modèles stables tirés au hasard
%   tf2ss, ss2tf      - Conversions entre les deux représentations
%   ssdata, tfdata, zpkdata - Extraction des données d'un modèle
%   c2d, d2c, d2d     - Passage continu / discret et rééchantillonnage
%
% Propriétés
%   pole, zero, pzmap - Pôles et zéros
%   pzplot, rlocusplot - Les mêmes, sous leur autre nom
%   stabsep           - Sépare partie stable et partie instable
%   hasdelay, totaldelay, pade - Retards et leur approximation
%   thiran            - Retard fractionnaire par un passe-tout
%   delayss           - Modèle d'état à retards internes
%   prescale          - Met le modèle à l'échelle pour le calcul
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
%   lsiminfo          - Les mêmes mesures, sur une réponse quelconque
%   covar             - Covariance de la réponse à un bruit blanc
%
% Réponses fréquentielles
%   bode, nyquist, nichols - Les trois diagrammes
%   bodemag           - Diagramme de Bode du seul module
%   freqresp, evalfr  - Réponse complexe, en pulsation ou en un point
%   sigma             - Valeurs singulières de la matrice de transfert
%   margin, allmargin - Marges de gain, de phase et de retard
%   sgrid, zgrid, ngrid - Grilles d'amortissement et abaque de Nichols
%   bandwidth         - Bande passante à -3 décibels
%
% Unités et options de tracé
%   chgTimeUnit       - Change l'unité de temps d'un modèle
%   chgFreqUnit       - Change l'unité de fréquence d'un modèle
%   bodeoptions       - Options d'un diagramme de Bode
%   stepDataOptions   - Niveaux de l'échelon d'une réponse indicielle
%
% Interconnexions
%   feedback, series, parallel - Boucle, cascade, somme
%   loopsens          - Les six sensibilités d'une boucle
%   augstate          - Ajoute l'état aux sorties
%   append            - Juxtaposition sans connexion
%   lft               - Produit étoile : rebouclage partiel
%   connect, sumblk   - Assemblage par les noms des signaux
%   getBlockValue     - Valeur d'un bloc réglable d'un assemblage
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
%   lyapchol          - Facteur de Cholesky de la solution de Lyapunov
%   lyap, dlyap       - Lyapunov continue et discrète, Sylvester
%   care, dare        - Riccati continue et discrète
%
% Synthèse
%   place, acker      - Placement de pôles
%   lqr, dlqr         - Commande linéaire quadratique
%   lqg, lqgreg       - Régulateur linéaire quadratique gaussien
%   lqry, lqi, lqrd   - Pondération sur la sortie, action intégrale,
%                       commande discrète d'un procédé continu
%   lqe, kalman       - Estimateur linéaire quadratique, filtre de Kalman
%   estim, reg        - Observateur seul, régulateur complet
%   pid, pidstd       - Correcteur PID, formes parallèle et standard
%   pidtune           - Réglage d'un PID par la marge de phase
%   rlocus            - Lieu des racines
%
% Vues d'ensemble
%   pidtool           - Règle un PID et montre la boucle obtenue
%   sisotool          - Lieu des racines, Bode et réponse indicielle
%
% Les applications interactives de MATLAB — PIDTOOL, SISOTOOL — sont ici
% des fonctions qui calculent et tracent une fois : il n'y a pas de
% curseur à déplacer.
```

## `acker`

```
ACKER Placement de pôles par la formule d'Ackermann.
  K = ACKER(A,B,P) rend le gain de retour d'état qui place les pôles de
  A - B*K aux valeurs P. Le système doit avoir une seule entrée et être
  commandable.

  Pour plusieurs entrées, le placement n'est plus unique : c'est PLACE
  qu'il faut, qui choisit alors le gain le mieux conditionné.

  Exemple :
     A = [0 1; 0 0]; B = [0; 1];
     K = acker(A, B, [-2 -3]);
     sort(eig(A - B*K))          % -3  -2

  Voir aussi PLACE, LQR, CTRB, POLE, EIG.
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

## `augstate`

```
AUGSTATE Ajoute l'état aux sorties d'un modèle.
  SYSA = AUGSTATE(SYS) rend le modèle dont les sorties sont celles de
  SYS suivies de son état tout entier. C'est ce qu'il faut pour observer
  la trajectoire de l'état dans une simulation, ou pour poser un critère
  qui porte sur lui.

  Les états ajoutés ne se voient qu'à travers la matrice C : le modèle
  garde exactement la même dynamique.

  Exemples :
     sys = ss([-1 0; 0 -2], [1; 1], [1 0], 0);
     a = augstate(sys);
     size(a)                          % 3 sorties, 1 entree
     isequal(a.A, sys.A)              % vrai : la dynamique ne bouge pas

  Voir aussi SS, LSIM, INITIAL, SSDATA.
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
BANDWIDTH Bande passante d'un modèle.
  W = BANDWIDTH(SYS) rend la première pulsation où le gain descend de
  trois décibels sous sa valeur en continu : la limite au-delà de
  laquelle le système ne suit plus.

  W = BANDWIDTH(SYS,CHUTE) choisit une autre chute, en décibels, donnée
  négative.

  Le gain statique doit être fini et non nul ; sinon la fonction rend
  NaN, faute de référence à laquelle comparer.

  Exemples :
     bandwidth(tf(1, [1 1]))          % 1 rad/s
     bandwidth(tf(1, [1 1]), -6)      % la pulsation a -6 dB

  Voir aussi DCGAIN, BODE, MARGIN, STEPINFO.
```

## `bode`

```
BODE Diagramme de Bode : module et phase de la réponse fréquentielle.
  BODE(SYS) trace le gain en décibels et la phase en degrés du modèle
  SYS en fonction de la pulsation, l'abscisse en échelle logarithmique.
  Le gain occupe la moitié haute de la case courante, la phase la
  moitié basse.

  BODE(SYS,W) impose la grille de pulsations, en radians par seconde :
  un vecteur, ou {WMIN,WMAX} pour n'en donner que les bornes.

  BODE(SYS1,SYS2,...) superpose plusieurs modèles. Une chaîne de style
  peut suivre chacun d'eux, comme dans PLOT :
  BODE(SYS1,'b',SYS2,'r--',W).

  [MODULE,PHASE] = BODE(SYS) ne trace rien et rend le module — linéaire,
  pas en décibels — et la phase en degrés. [MODULE,PHASE,W] = BODE(SYS)
  rend en plus la grille employée. Avec des sorties, un seul modèle est
  accepté, comme dans MATLAB.

  Pour un modèle échantillonné, la réponse est évaluée sur le cercle
  unité, en exp(j*W*Ts) ; pour un modèle continu, en j*W.

  BODE(...,OPTIONS) où OPTIONS vient de BODEOPTIONS règle le tracé :
  FreqUnits, MagUnits, PhaseUnits, Grid, XLim, YLim, Title, XLabel et
  YLabel sont suivis.

  Exemples :
     bode(tf(1, [1 2 1]))
     bode(tf(1, [1 1]), tf(1, [1 0.2 1]), logspace(-2, 2, 500))
     [m, p] = bode(tf(1, [1 1]), 1);   % m = 0.7071, p = -45

  Voir aussi BODEMAG, NICHOLS, NYQUIST, SIGMA, MARGIN, FREQRESP,
  BODEOPTIONS.
```

## `bodemag`

```
BODEMAG Diagramme de Bode du seul module.
  BODEMAG(SYS) trace le gain en décibels du modèle SYS en fonction de
  la pulsation, l'abscisse en échelle logarithmique. La phase n'est pas
  dessinée : c'est le seul point qui sépare BODEMAG de BODE, et il tient
  toute la case courante au lieu de la moitié.

  BODEMAG(SYS,W) impose la grille de pulsations, en radians par
  seconde : un vecteur, ou {WMIN,WMAX} pour n'en donner que les bornes.

  BODEMAG(SYS1,SYS2,...,W) superpose plusieurs modèles ; une chaîne de
  style peut suivre chacun d'eux, comme dans PLOT.

  [MODULE,W] = BODEMAG(SYS) ne trace rien et rend le module linéaire et
  la grille employée.

  BODEMAG(...,OPTIONS) où OPTIONS vient de BODEOPTIONS règle le tracé,
  comme pour BODE.

  Exemple :
     G = tf(1, [1 0.2 1]);
     bodemag(feedback(G, 1), 'b', G, 'r--')

  Voir aussi BODE, SIGMA, NICHOLS, FREQRESP, BODEOPTIONS.
```

## `bodeoptions`

```
BODEOPTIONS Options d'un diagramme de Bode.
  O = BODEOPTIONS rend une structure d'options de tracé, que BODE
  accepte comme dernier argument : unités, grille, plages, titres.
  O = BODEOPTIONS('cstprefs') part des préférences enregistrées ;
  MatLibre n'en garde pas, et rend les mêmes valeurs par défaut.

  Champs traités par MatLibre : FreqUnits, MagUnits, PhaseUnits, Grid,
  XLim, YLim, Title, XLabel, YLabel. Les autres sont acceptés et
  conservés, pour que le code écrit pour MATLAB s'exécute.

  Exemple :
     o = bodeoptions;
     o.FreqUnits = 'Hz';
     o.Grid = 'on';
     bode(tf(1, [1 1]), o);

  Voir aussi BODE, BODEMAG, NICHOLS, NYQUIST, STEPDATAOPTIONS.
```

## `c2d`

```
C2D Discrétisation d'un modèle continu.
  SYSD = C2D(SYS,TS) échantillonne le modèle à la période TS par
  bloqueur d'ordre zéro : l'entrée est supposée constante entre deux
  instants, ce qui est le cas derrière un convertisseur numérique.

  SYSD = C2D(SYS,TS,'tustin') emploie la transformation bilinéaire, qui
  conserve mieux la réponse fréquentielle près de la fréquence de
  Nyquist, au prix d'une légère distorsion.

  Exemples :
     d = c2d(tf(1, [1 1]), 0.1);
     d.Ts                             % 0.1
     abs(dcgain(d) - dcgain(tf(1, [1 1]))) < 1e-9    % le gain statique tient

  Voir aussi D2C, D2D, TUSTIN, SS, TF.
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
  X = CARE(A,B,Q,R) résout A'X + XA - XBR^{-1}B'X + Q = 0 et rend la
  solution stabilisante : celle qui rend A - B*R^{-1}B'X stable. C'est
  elle qui donne le gain optimal de la commande linéaire quadratique.

  [X,K,P] = CARE(...) rend en plus K = R^{-1}B'X et les pôles P de la
  boucle fermée.

  La solution vient du sous-espace propre stable de la matrice
  hamiltonienne associée.

  Exemples :
     care(0, 1, 1, 1)                 % 1
     [X, K] = care([0 1; 0 0], [0; 1], eye(2), 1);
     max(real(eig([0 1; 0 0] - [0; 1] * K))) < 0     % la boucle est stable

  Voir aussi DARE, LQR, LYAP, HINFSYN.
```

## `chgFreqUnit`

```
CHGFREQUNIT Change l'unité de fréquence d'un modèle.
  SYS = CHGFREQUNIT(SYS,UNITE) réécrit un modèle de réponse en
  fréquence dans une autre unité, sans changer ce qu'il décrit.
  UNITE vaut 'rad/TimeUnit', 'cycles/TimeUnit', 'rad/s', 'Hz', 'kHz',
  'MHz', 'GHz' ou 'rpm'.

  Exemple :
     reponse = frd([1 0.5], [1 10]);
     enHertz = chgFreqUnit(reponse, 'Hz');

  Voir aussi CHGTIMEUNIT, FRD, BODE.
```

## `chgTimeUnit`

```
CHGTIMEUNIT Change l'unité de temps d'un modèle.
  SYS = CHGTIMEUNIT(SYS,UNITE) réécrit le modèle dans une autre unité
  de temps, sans changer ce qu'il décrit : les constantes de temps sont
  converties, si bien qu'une réponse tracée dans la nouvelle unité a la
  même forme.

  UNITE vaut 'nanoseconds', 'microseconds', 'milliseconds', 'seconds',
  'minutes', 'hours', 'days', 'weeks', 'months' ou 'years'.

  Exemple :
     sys = tf(1, [1 1]);              % une constante de temps d'une seconde
     lent = chgTimeUnit(sys, 'minutes');

  Voir aussi CHGFREQUNIT, TF, SS, ZPK.
```

## `connect`

```
CONNECT Assemble un schéma-bloc en reliant les signaux par leur nom.
  SYS = CONNECT(BLOC1,BLOC2,...,ENTREES,SORTIES) relie les blocs : une
  entrée nommée « u » est branchée sur la sortie nommée « u », d'où
  qu'elle vienne. ENTREES et SORTIES nomment ce qui reste ouvert — les
  entrées et les sorties du modèle assemblé.

  Chaque bloc doit nommer ses voies, par ses propriétés InputName et
  OutputName ; SUMBLK fabrique les points de sommation. Un nom qui n'est
  ni une sortie de bloc ni une entrée du schéma est signalé : c'est
  presque toujours une faute de frappe.

  CONNECT est la façon moderne d'écrire ce que SYSIC écrivait avec des
  variables. Les deux mènent au même modèle.

  Exemples :
     G = ss(tf(2, [1 1]));  G.InputName = 'u';  G.OutputName = 'y';
     K = ss(tf(10, [1 0])); K.InputName = 'e';  K.OutputName = 'u';
     S = sumblk('e = r - y');
     T = connect(G, K, S, 'r', 'y');
     max(abs(pole(T) - pole(feedback(series(K, G), 1)))) < 1e-9
     % Plusieurs sorties d'un coup : la boucle fermée et la commande.
     TU = connect(G, K, S, 'r', {'y', 'u'});
     size(TU)                   % 2 sorties, 1 entree

  Voir aussi SUMBLK, SYSIC, APPEND, FEEDBACK, SERIES, LFT.
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
CTRB Matrice de commandabilité.
  M = CTRB(A,B) rend [B AB A^2B ... A^(n-1)B]. Le système est
  commandable — on peut mener l'état où l'on veut — si et seulement si
  cette matrice est de rang plein.

  M = CTRB(SYS) prend les matrices du modèle.

  Exemples :
     rank(ctrb([0 1; 0 0], [0; 1]))       % 2 : commandable
     rank(ctrb([1 0; 0 2], [1; 0]))       % 1 : le second etat ne bouge pas
     size(ctrb(ss(-1, 1, 1, 0)))          % 1  1

  Voir aussi OBSV, CTRBF, GRAM, MINREAL, RANK.
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
D2C Retour au continu d'un modèle échantillonné.
  SYSC = D2C(SYSD) rend le modèle continu dont la discrétisation par
  bloqueur d'ordre zéro redonne SYSD. C'est l'opération inverse de C2D,
  au bruit numérique près.

  SYSC = D2C(SYSD,'tustin') emploie la transformation bilinéaire, et
  inverse alors exactement ce que C2D(...,'tustin') a fait.

  La méthode doit être celle qui a servi à discrétiser : les deux
  transformations ne donnent pas le même modèle continu, et les mélanger
  ne rend rien de sensé.

  Le retour par bloqueur passe par le logarithme de matrice, qui n'est
  pas toujours réel : un système discret dont un pôle est réel négatif
  n'a pas d'équivalent continu réel. La partie imaginaire est alors
  écartée, et le modèle rendu n'est plus un inverse exact — c'est une
  limite de l'opération, non du calcul.

  Exemples :
     d = c2d(tf(1, [1 1]), 0.05);
     c = d2c(d);
     abs(dcgain(c) - 1) < 1e-6            % le gain statique est rendu

     d = c2d(tf(1, [1 2 1]), 0.05, 'tustin');
     pole(d2c(d, 'tustin'))               % -1 et -1, les poles d'origine

  Voir aussi C2D, D2D, SS, TF.
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
  [WN,ZETA] = DAMP(SYS) rend, pour chaque pôle, la pulsation propre WN
  en radians par seconde et le coefficient d'amortissement ZETA. Un
  ZETA sous 0.7 annonce un dépassement ; sous 0.3, des oscillations
  marquées ; négatif, l'instabilité.

  [WN,ZETA,P] = DAMP(SYS) rend aussi les pôles. Pour un modèle
  échantillonné, ils sont d'abord ramenés au continu par log(z)/Ts.

  Exemples :
     [wn, zeta] = damp(tf(1, [1 0.4 1]));
     wn(1)                                % 1 rad/s
     zeta(1)                              % 0.2, peu amorti

  Voir aussi POLE, PZMAP, STEPINFO, EIG.
```

## `dare`

```
DARE Équation de Riccati algébrique discrète.
  X = DARE(A,B,Q,R) résout A'XA - X - A'XB(B'XB+R)^{-1}B'XA + Q = 0 et
  rend la solution stabilisante. C'est l'équation de la commande
  linéaire quadratique à temps discret.

  [X,K,P] = DARE(...) rend en plus le gain K = (B'XB+R)^{-1}B'XA et les
  pôles de la boucle fermée.

  Exemples :
     X = dare(0.5, 1, 1, 1);
     abs(0.5^2*X - X - 0.5^2*X^2/(X+1) + 1) < 1e-9   % l'equation est verifiee
     [~, K] = dare(0.5, 1, 1, 1);
     abs(0.5 - K) < 1                     % la boucle fermee est dans le cercle

  Voir aussi CARE, DLQR, DLYAP, LQR.
```

## `dcgain`

```
DCGAIN Gain statique d'un modèle.
  K = DCGAIN(SYS) rend le gain que le modèle applique à une entrée
  constante : H(0) en temps continu, H(1) en discret. C'est le rapport
  entre la sortie et l'entrée une fois le régime établi.

  Un intégrateur donne un gain infini ; un dérivateur, un gain nul.

  Exemples :
     dcgain(tf(10, [1 2]))                % 5
     dcgain(tf(1, [1 0]))                 % Inf : un integrateur
     dcgain(ss(-1, 1, 1, 0))              % 1

     % Une matrice de transferts : le gain est une matrice
     G = [tf(1, [1 1]), tf(2, [1 2]); tf(3, [1 3]), tf(4, [1 4])];
     dcgain(G)                            % [1 1; 1 1]

  Voir aussi BANDWIDTH, STEPINFO, EVALFR, FREQRESP.
```

## `delayss`

```
DELAYSS Modèle d'état à retards internes.
  SYS = DELAYSS(A,B,C,D,DELTA) construit un modèle d'état dont
  certaines voies sont retardées. DELTA est une matrice dont chaque
  ligne décrit un retard : [SORTIE, ENTREE, TEMPS], le terme concerné
  étant retardé de TEMPS secondes.

  MatLibre n'a pas de modèle à retards internes : le retard est rendu
  par l'approximation de Padé d'ordre 3, ce qui donne un modèle
  rationnel du même comportement en basse fréquence. MATLAB, lui,
  garde le retard exact. Ce que le modèle rendu perd, c'est la
  justesse de la phase au-delà de quelques radians par seconde.

  Exemple :
     sys = delayss(-1, 1, 1, 0, [1 1 0.5]);   % retard d'une demi-seconde

  Voir aussi SS, PADE, THIRAN, TOTALDELAY, HASDELAY.
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
DLYAP Équation de Lyapunov discrète.
  X = DLYAP(A,Q) résout A*X*A' - X + Q = 0. La solution existe et est
  unique quand aucun produit de deux valeurs propres de A ne vaut 1 —
  en particulier quand A est stable au sens discret.

  Pour un système stable et Q = B*B', X est le grammien de
  commandabilité : l'énergie que l'entrée peut mettre dans chaque état.

  Exemples :
     X = dlyap(0.5, 1);
     abs(0.25*X - X + 1) < 1e-12          % l'equation est verifiee
     X                                    % 1.3333

  Voir aussi LYAP, DARE, GRAM.
```

## `drss`

```
DRSS Modèle d'état discret stable, tiré au hasard.
  SYS = DRSS(N) rend un modèle discret d'ordre N dont tous les pôles
  sont dans le cercle unité, à la période d'échantillonnage 1.

  SYS = DRSS(N,NY) et SYS = DRSS(N,NY,NU) donnent plusieurs voies.

  Exemples :
     sys = drss(3);
     max(abs(pole(sys))) < 1      % vrai : les poles sont dans le cercle
     drss(2).Ts                   % 1

  Voir aussi RSS, SS, C2D, POLE.
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
  SYS = FEEDBACK(G,H) ferme la boucle sur une contre-réaction négative :
  la sortie de G passe par H et se retranche de l'entrée. Pour un modèle
  monovariable, c'est G/(1+GH).

  SYS = FEEDBACK(G,H,+1) somme au lieu de retrancher : G/(1-GH).

  SYS = FEEDBACK(G,1) referme la boucle sur un retour unitaire ; c'est
  la forme la plus courante.

  Les modèles à plusieurs entrées et sorties sont acceptés : le calcul
  se fait alors dans l'espace d'état, avec la matrice I - S*D2*D1 qui
  doit être inversible — sans quoi la boucle est algébrique, et le
  message le dit.

  Exemples :
     T = feedback(tf(10, [1 1]), 1)          % 10/(s+11)
     T = feedback(ss(-1,1,1,0), eye(1))      % en modèle d'état

  Voir aussi SERIES, PARALLEL, LFT, APPEND, CONNECT.
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

## `frd`

```
FRD Modèle de réponse fréquentielle.
  SYS = FRD(REPONSE,FREQUENCES) crée un modèle qui ne porte que des
  mesures : la valeur de la réponse à chaque fréquence, et rien
  d'autre. C'est ce qu'on a quand on a mesuré un procédé au vibreur ou
  à l'analyseur de spectre, sans en avoir tiré d'équations.

  SYS = FRD(REPONSE,FREQUENCES,'Units','Hz') dit que les fréquences
  sont en hertz ; sans cela, elles sont en radians par seconde.
  SYS = FRD(SYS,FREQUENCES) échantillonne un modèle SS ou TF aux
  fréquences données.

  Les propriétés :
     ResponseData   la réponse, un nombre complexe par fréquence ;
     Frequency      les fréquences ;
     FrequencyUnit  'rad/TimeUnit' ou 'Hz' ;
     Ts             la période d'échantillonnage.

  Les opérations + - * et INV sont définies : elles s'appliquent point
  par point, les deux modèles devant porter les mêmes fréquences.
  BODE, NYQUIST, SIGMA et NORM acceptent un FRD.

  Un FRD ne se simule pas et n'a pas de pôles : il ne dit rien entre
  deux points mesurés. C'est sa force — il ne suppose aucune structure —
  et sa limite.

  Exemples :
     w = logspace(-1, 2, 50);
     G = frd(freqresp(tf(1, [1 1]), w), w);
     bode(G);
     abs(G.ResponseData(1))

     H = frd(tf(1, [1 0.2 1]), w);      % echantillonne un modele
     norm(H, Inf)                        % le pic mesure

  Voir aussi FREQRESP, BODE, NYQUIST, SIGMA, TF, SS, INTERP1.
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

## `getBlockValue`

```
GETBLOCKVALUE Valeur d'un bloc réglable d'un modèle.
  V = GETBLOCKVALUE(M,NOM) rend le bloc nommé d'un modèle assemblé par
  CONNECT ou par une structure de blocs : c'est ainsi qu'on récupère le
  correcteur d'une boucle une fois réglé.

  MATLAB range les blocs réglables dans un modèle « genss » ; MatLibre
  n'en a pas, et lit le nom dans une structure de blocs — celle qu'on
  se donne pour décrire une boucle — ou le nom d'un modèle.

  Exemple :
     blocs = struct('C', pid(1, 2), 'G', tf(1, [1 1]));
     C = getBlockValue(blocs, 'C');

  Voir aussi CONNECT, SUMBLK, PID, PIDTUNE, LOOPSENS.
```

## `gram`

```
GRAM Grammiens de commandabilité et d'observabilité.
  W = GRAM(SYS,'c') résout A*W + W*A' + B*B' = 0 : le grammien de
  commandabilité, qui mesure l'énergie qu'il faut pour atteindre chaque
  direction de l'état.

  W = GRAM(SYS,'o') résout A'*W + W*A + C'*C = 0 : le grammien
  d'observabilité, qui mesure l'énergie que chaque direction envoie
  dans la sortie.

  Les directions que les deux grammiens ignorent sont celles qu'on peut
  retirer du modèle : c'est le principe de la réduction équilibrée.

  Exemples :
     gram(ss(-1, 1, 1, 0), 'c')           % 0.5
     gram(ss(-1, 1, 1, 0), 'o')           % 0.5
     det(gram(ss([-1 0; 0 -2], eye(2), eye(2), zeros(2)), 'c')) > 0

  Voir aussi CTRB, OBSV, BALREAL, HSVD, LYAP.
```

## `hasdelay`

```
HASDELAY Vrai si le modèle porte un retard.
  HASDELAY(SYS) dit si le modèle a un retard, en entrée, en sortie ou
  dans la boucle.

  MatLibre ne représente pas les retards autrement que par leur
  approximation : la fonction rend donc toujours faux. Pour porter un
  retard dans un calcul, PADE en donne une fonction de transfert.

  Exemples :
     hasdelay(tf(1, [1 1]))           % faux
     hasdelay(ss(-1, 1, 1, 0))        % faux

  Voir aussi PADE, TOTALDELAY, C2D.
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
  IMPULSE(SYS) trace la réponse du modèle SYS à une impulsion de Dirac,
  obtenue en dérivant la réponse indicielle.

  IMPULSE(SYS,TFINAL) impose l'horizon, en secondes ; IMPULSE(SYS,T)
  impose la grille de temps.

  IMPULSE(SYS1,SYS2,...,T) superpose plusieurs modèles ; une chaîne de
  style peut suivre chacun d'eux, comme dans PLOT.

  [Y,T] = IMPULSE(SYS) ne trace rien et rend la réponse et les instants.

  Exemple :
     impulse(tf(1, [1 0.4 1]))

  Voir aussi STEP, LSIM, INITIAL.
```

## `initial`

```
INITIAL Réponse libre à une condition initiale.
  [Y,T,X] = INITIAL(SYS,X0) intègre xdot = A*x sans entrée, en partant
  de l'état X0, et rend la sortie, les instants et la trajectoire de
  l'état. Sans sortie demandée, la fonction trace la réponse.

  [Y,T,X] = INITIAL(SYS,X0,TFINAL) impose l'horizon.

  Exemples :
     s = ss(-1, 0, 1, 0);
     y = initial(s, 1, 5);
     abs(y(1) - 1) < 1e-9                 % on part bien de x0
     y(end) < 0.01                        % et l'on decroit en exp(-t)

  Voir aussi STEP, IMPULSE, LSIM, SS.
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
KALMAN Filtre de Kalman d'un modèle d'état.
  [KEST,L,P] = KALMAN(SYS,QN,RN) rend l'estimateur optimal de l'état,
  le gain L et la covariance P de l'erreur, pour un bruit d'état de
  covariance QN et un bruit de mesure de covariance RN.

  L'estimateur suit xchapeau' = A*xchapeau + B*u + L*(y - C*xchapeau) :
  il corrige sa prédiction proportionnellement à l'écart constaté.

  Exemples :
     [kest, L] = kalman(ss(-1, 1, 1, 0), 1, 1);
     L > 0                                % le gain corrige dans le bon sens
     max(real(eig(-1 - L))) < 0           % l'observateur converge

  Voir aussi LQE, LQR, LQG, CARE, ESTIM.
```

## `lft`

```
LFT Produit étoile de Redheffer : rebouclage partiel de deux modèles.
  SYS = LFT(SYS1,SYS2) relie les dernières sorties de SYS1 aux premières
  entrées de SYS2, et les premières sorties de SYS2 aux dernières
  entrées de SYS1. Ce qui reste — les premières voies de SYS1 et les
  dernières de SYS2 — devient l'entrée et la sortie du résultat.

  Le nombre de voies reliées est le plus grand possible. Quand SYS2 est
  le plus petit, tout SYS2 se referme et l'on obtient la boucle basse
  F_l(SYS1,SYS2) — celle qui referme un correcteur sur un modèle
  augmenté. Quand c'est SYS1, on obtient la boucle haute F_u(SYS2,SYS1)
  — celle de l'analyse de robustesse, où l'incertitude referme le haut
  du schéma.

  SYS = LFT(SYS1,SYS2,NU,NY) impose le nombre de voies : NU sorties de
  SYS1 vers SYS2, NY sorties de SYS2 vers SYS1.

  En partitionnant SYS1 en [S11 S12 ; S21 S22] et SYS2 en
  [T11 T12 ; T21 T22] selon ce découpage, et avec M = inv(I - T11*S22) :
     R11 = S11 + S12*M*T11*S21     R12 = S12*M*T12
     R21 = T21*(I + S22*M*T11)*S21 R22 = T22 + T21*S22*M*T12

  Exemple :
     P = augw(tf(1, [1 1]), 1, [], 1);
     K = ss(-1, 1, 1, 0);
     T = lft(P, K);            % la boucle fermée, pondérations comprises

  Voir aussi FEEDBACK, SERIES, APPEND, HINFSYN, AUGW.
```

## `loopsens`

```
LOOPSENS Toutes les fonctions de sensibilité d'une boucle.
  S = LOOPSENS(G,K) rend, dans une structure, les six transmittances
  d'une boucle à retour unitaire où G est le procédé et K le correcteur :

     S.Si   sensibilité en entrée,      inv(I + K*G)
     S.Ti   complémentaire en entrée,   I - Si
     S.So   sensibilité en sortie,      inv(I + G*K)
     S.To   complémentaire en sortie,   I - So
     S.PSi  procédé fois sensibilité,   G*Si
     S.CSo  correcteur fois sensibilité, K*So
     S.Lo   boucle ouverte en sortie,   G*K
     S.Li   boucle ouverte en entrée,   K*G
     S.Poles pôles de la boucle fermée
     S.Stable vrai si la boucle est stable

  Ces six-là sont les seules que l'on ait à regarder : elles disent le
  rejet des perturbations, le suivi de consigne, l'effort de commande et
  la robustesse. Les tracer toutes, c'est ce que fait un ingénieur avant
  de valider un correcteur.

  Exemples :
     L = loopsens(tf(2, [1 1]), tf(10, [1 0]));
     L.Stable                         % vrai
     abs(dcgain(L.So))  < 1e-9        % l'integrateur annule l'erreur
     abs(dcgain(L.To) - 1) < 1e-9     % et fait suivre la consigne

  Voir aussi FEEDBACK, SIGMA, MARGIN, HINFNORM, STABILITYMARGIN.
```

## `lqe`

```
LQE Gain d'un estimateur linéaire quadratique.
  [L,P,E] = LQE(A,G,C,Q,R) rend le gain L de l'observateur qui minimise
  la variance de l'erreur d'estimation, la solution P de l'équation de
  Riccati et les pôles E de l'observateur. Q est la covariance du bruit
  d'état, R celle du bruit de mesure.

  C'est le dual de LQR : plus le bruit de mesure est fort, plus le gain
  est faible et l'estimateur prudent.

  Exemples :
     L = lqe(-1, 1, 1, 1, 1);
     L > 0                                % vrai
     max(real(eig(-1 - L * 1))) < -1      % l'observateur va plus vite

  Voir aussi LQR, KALMAN, CARE, PLACE.
```

## `lqg`

```
LQG Régulateur linéaire quadratique gaussien.
  REG = LQG(SYS,QXU,QWV) assemble d'un coup le régulateur optimal d'un
  procédé bruité : QXU pondère l'état et la commande dans le critère,
  QWV décrit les covariances du bruit d'état et du bruit de mesure.

  Les deux matrices sont bloc-diagonales par morceaux :
     QXU = [Q  Nc ; Nc' R]  le coût, x'Qx + 2x'Nc*u + u'Ru
     QWV = [Qn Nf ; Nf' Rn] les bruits, d'état puis de mesure

  [REG,INFO] = LQG(...) rend en plus le gain de retour d'état, le gain
  de l'estimateur et les deux solutions de Riccati.

  C'est LQR et KALMAN réunis par LQGREG : le principe de séparation dit
  que le régulateur ainsi obtenu est optimal.

  Exemples :
     G = ss(-1, 1, 1, 0);
     C = lqg(G, eye(2), eye(2));
     max(real(pole(feedback(G, -C)))) < 0     % la boucle est stable

  Voir aussi LQR, KALMAN, LQGREG, CARE, H2SYN.
```

## `lqgreg`

```
LQGREG Assemble le régulateur LQG à partir de l'estimateur et du gain.
  REG = LQGREG(KEST,K) réunit l'estimateur de Kalman KEST — celui que
  rend KALMAN — et le gain de retour d'état K — celui que rend LQR — en
  un seul correcteur qui prend la mesure Y et rend la commande U :

     xchapeau' = (A - B*K - L*C) xchapeau + L y
     u         = -K xchapeau

  C'est le principe de séparation : on estime l'état comme si l'on
  commandait parfaitement, on le commande comme si on l'observait
  parfaitement, et la réunion est optimale.

  REG = LQGREG(KEST,K,'current') emploie l'estimateur courant en
  discret ; MatLibre ne fait pas la différence et rend le même
  régulateur.

  Le signe est celui de MATLAB : REG rend U, et se referme sur le
  procédé par une contre-réaction positive — feedback(G, REG, +1) — ou,
  ce qui revient au même, par -REG en contre-réaction négative.

  Exemples :
     G = ss(-1, 1, 1, 0);
     [kest, L] = kalman(G, 1, 1);
     K = lqr(G.A, G.B, 1, 1);
     C = lqgreg(kest, K);
     max(real(pole(feedback(G, -C)))) < 0     % la boucle est stable

  Voir aussi KALMAN, LQR, LQG, ESTIM, REG.
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
LSIM Réponse à une entrée quelconque.
  [Y,T,X] = LSIM(SYS,U,T) simule la réponse du modèle à l'entrée U
  échantillonnée aux instants T. L'entrée est interpolée linéairement
  entre deux instants ; le pas doit être assez fin devant les
  constantes de temps du modèle.

  [Y,T,X] = LSIM(SYS,U,T,X0) part d'une condition initiale.

  Exemples :
     t = linspace(0, 5, 200)';
     y = lsim(tf(1, [1 1]), ones(size(t)), t);
     abs(y(end) - 1) < 0.02               % la reponse indicielle converge vers 1
     y2 = lsim(tf(1, [1 1]), sin(t), t);
     max(abs(y2)) < 1                     % un premier ordre attenue

  Voir aussi STEP, IMPULSE, INITIAL, GENSIG.
```

## `lsiminfo`

```
LSIMINFO Caractéristiques d'une réponse quelconque.
  S = LSIMINFO(Y,T) décrit la réponse Y observée aux instants T :
  SettlingTime le temps au bout duquel elle reste à deux pour cent de sa
  valeur finale, Min et Max ses extrêmes, MinTime et MaxTime les
  instants où ils sont atteints.

  S = LSIMINFO(Y,T,YFINAL) impose la valeur finale au lieu de prendre la
  dernière.

  C'est STEPINFO pour une entrée qui n'est pas un échelon : ni temps de
  montée ni dépassement, qui n'auraient pas de sens, mais le reste.

  Exemples :
     t = linspace(0, 10, 500);
     y = 1 - exp(-t);
     s = lsiminfo(y, t);
     s.SettlingTime > 3 && s.SettlingTime < 5      % environ 4 constantes
     s.Max                                          % proche de 1

  Voir aussi STEPINFO, LSIM, STEP, IMPULSE.
```

## `lyap`

```
LYAP Équation de Lyapunov continue.
  X = LYAP(A,Q) résout A*X + X*A' + Q = 0. La solution existe et est
  unique quand aucune somme de deux valeurs propres de A n'est nulle —
  en particulier quand A est stable.

  X = LYAP(A,B,C) résout l'équation de Sylvester A*X + X*B + C = 0.

  Pour A stable et Q définie positive, X définie positive prouve la
  stabilité : c'est le théorème de Lyapunov, et la fonction V = x'Xx
  décroît le long des trajectoires.

  Exemples :
     X = lyap(-1, 2);
     abs(-X - X + 2) < 1e-12              % l'equation est verifiee
     X                                    % 1
     min(eig(lyap([-1 0; 0 -2], eye(2)))) > 0     % definie positive

  Voir aussi DLYAP, CARE, GRAM, EIG.
```

## `lyapchol`

```
LYAPCHOL Facteur de Cholesky de la solution de Lyapunov.
  R = LYAPCHOL(A,B) rend la matrice triangulaire supérieure R telle que
  X = R'*R résolve A*X + X*A' + B*B' = 0. Travailler sur R plutôt que
  sur X garde la positivité exacte et double la précision : c'est ce
  qu'emploient les réductions de modèle.

  A doit être stable.

  Exemples :
     R = lyapchol(-1, 1);
     abs(R' * R - 0.5) < 1e-12        % X = 0.5 pour ce cas
     X = lyapchol([-1 0; 0 -2], eye(2))' * lyapchol([-1 0; 0 -2], eye(2));
     max(max(abs([-1 0; 0 -2] * X + X * [-1 0; 0 -2]' + eye(2)))) < 1e-12

  Voir aussi LYAP, DLYAP, GRAM, BALREAL, CHOL.
```

## `margin`

```
MARGIN Marges de gain et de phase.
  [GM,PM,WCG,WCP] = MARGIN(SYS) rend la marge de gain — linéaire, non en
  décibels —, la marge de phase en degrés, et les deux pulsations où
  elles se lisent : WCG là où la phase traverse -180 degrés, WCP là où
  le gain traverse 0 dB.

  [GM,PM,WCG,WCP] = MARGIN(MAG,PHASE,W) part d'une réponse déjà
  calculée, telle que la rend BODE : MAG linéaire, PHASE en degrés.

  MARGIN(SYS) sans sortie trace le diagramme de Bode et marque les deux
  traversées, avec les marges en titre.

  Une marge infinie signale que la traversée n'a pas lieu sur la grille
  examinée : la phase ne descend jamais à -180 degrés, ou le gain ne
  passe jamais sous 0 dB.

  Exemple :
     [gm, pm] = margin(tf(1, [1 2 1 0]));   % gm = 2, pm = 21.4 degrés

  Voir aussi ALLMARGIN, BODE, NICHOLS, NYQUIST.
```

## `matlibre_arguments_lti`

```
MATLIBRE_ARGUMENTS_LTI Découpe la liste d'arguments d'un tracé LTI.
  [MODELES,STYLES,W] = MATLIBRE_ARGUMENTS_LTI(ENTREES) sépare la liste
  (SYS1,'STYLE1',SYS2,'STYLE2',...,W) que partagent BODE, BODEMAG,
  SIGMA, STEP et les autres tracés de l'automatique.

  ENTREES est le tableau de cellules des arguments reçus — VARARGIN.
  MODELES rend les modèles dans l'ordre, STYLES la chaîne de style de
  chacun — vide là où l'appelant n'en a pas donné —, et W le dernier
  argument lorsqu'il vient après un modèle : la grille de pulsations
  d'un tracé fréquentiel, l'horizon ou la grille de temps d'un tracé
  temporel. Les bornes {WMIN,WMAX} sont acceptées et développées en
  deux cents points logarithmiquement espacés, comme dans MATLAB.

  [MODELES,STYLES,W,OPTIONS] rend en outre la structure d'options
  passée en dernier — celle que rendent BODEOPTIONS ou
  STEPDATAOPTIONS —, vide s'il n'y en a pas. Un modèle est un objet
  (« tf », « ss », « zpk », « frd ») ; une structure nue en dernière
  place est donc sans ambiguïté un jeu d'options.

  Cette fonction est un utilitaire interne de la boîte à outils
  Automatique : elle n'existe pas dans MATLAB.

  Voir aussi BODE, BODEMAG, SIGMA, STEP, BODEOPTIONS, STEPDATAOPTIONS.
```

## `matlibre_cases_bode`

```
MATLIBRE_CASES_BODE Coupe la case courante en deux, pour un Bode.
  [HAUT,BAS] = MATLIBRE_CASES_BODE() remplace l'axe courant par deux
  axes qui se partagent sa place : le gain en haut, la phase en bas.
  C'est ainsi que MATLAB dessine un diagramme de Bode dans une case de
  SUBPLOT sans déranger les autres.

  Cette fonction est un utilitaire interne de la boîte à outils
  Automatique : elle n'existe pas dans MATLAB.

  Voir aussi BODE, MARGIN, SUBPLOT, AXES.
```

## `matlibre_equilibrer`

```
MATLIBRE_EQUILIBRER Équilibrage diagonal d'une matrice.
  [B,D] = MATLIBRE_EQUILIBRER(A) rend B = diag(1./D) * A * diag(D), où D
  ne porte que des puissances de deux : la transformation est donc
  exacte en virgule flottante. B a des lignes et des colonnes de normes
  voisines, ce qui améliore beaucoup le conditionnement des calculs de
  valeurs propres et de sous-espaces invariants.

  C'est l'algorithme de Parlett et Reinsch, celui qu'emploie tout
  solveur de valeurs propres avant de travailler. Il sert ici aux
  matrices hamiltoniennes des équations de Riccati : un modèle dont les
  pôles vont de 10^-5 à 20 est autrement hors d'atteinte.

  Cette fonction est un utilitaire interne de la boîte à outils
  Automatique : elle n'existe pas dans MATLAB, où BALANCE fait le même
  travail.

  Voir aussi BALANCE, EIG, MATLIBRE_RICCATI.
```

## `matlibre_est_siso_tf`

```
MATLIBRE_EST_SISO_TF Vrai si l'objet se met en polynômes sans perte.
  Les interconnexions gardent la forme polynomiale tant que tout est
  monovariable : le résultat s'écrit alors comme dans un cours, en
  numérateur sur dénominateur. Dès qu'un modèle d'état à plusieurs
  voies entre en jeu, le calcul passe dans l'espace d'état.

  Cette fonction est un utilitaire interne de la boîte à outils
  Automatique : elle n'existe pas dans MATLAB.

  Voir aussi FEEDBACK, SERIES, PARALLEL.
```

## `matlibre_grille_temps`

```
MATLIBRE_GRILLE_TEMPS Grille de temps d'une simulation.
  T = MATLIBRE_GRILLE_TEMPS(SYS,TEMPS) rend la grille sur laquelle
  simuler le modèle SYS. TEMPS vide la fait choisir d'après les pôles :
  huit fois la constante de temps la plus lente, bornée entre une
  seconde et mille, en quatre cents points. Un scalaire donne l'horizon,
  un vecteur donne la grille elle-même.

  Cette fonction est un utilitaire interne de la boîte à outils
  Automatique : elle n'existe pas dans MATLAB.

  Voir aussi STEP, IMPULSE, LSIM.
```

## `matlibre_liste_noms`

```
MATLIBRE_LISTE_NOMS Une liste de noms de signaux, quelle qu'en soit l'écriture.
  NOMS = MATLIBRE_LISTE_NOMS(V) rend un tableau de cellules de chaînes,
  que V soit une chaîne, un tableau de chaînes ou déjà un tableau de
  cellules. C'est ce que CONNECT accepte pour ses listes d'entrées et de
  sorties.

  Cette fonction est un utilitaire interne de la boîte à outils
  Automatique : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_liste_noms('u')            % {'u'}
     matlibre_liste_noms({'a', 'b'})     % {'a', 'b'}

  Voir aussi CONNECT, SUMBLK.
```

## `matlibre_noms_voies`

```
MATLIBRE_NOMS_VOIES Les noms d'un signal à plusieurs voies.
  NOMS = MATLIBRE_NOMS_VOIES('u',3) rend {'u(1)';'u(2)';'u(3)'}, la
  façon dont MATLAB nomme les voies d'un signal vectoriel. Pour une
  seule voie, le nom reste tel quel.

  Cette fonction est un utilitaire interne de la boîte à outils
  Automatique : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_noms_voies('u', 2)      % {'u(1)'; 'u(2)'}
     matlibre_noms_voies('e', 1)      % {'e'}

  Voir aussi SUMBLK, CONNECT.
```

## `matlibre_pulsations`

```
MATLIBRE_PULSATIONS Grille de pulsations automatique d'un modèle.
  W = MATLIBRE_PULSATIONS(SYS) rend deux cents pulsations
  logarithmiquement espacées, centrées sur la moyenne géométrique des
  pôles et des zéros non nuls du modèle et couvrant deux décades de
  part et d'autre. C'est la grille que choisissent BODE, SIGMA et
  NYQUIST quand l'appelant n'en donne pas.

  W = MATLIBRE_PULSATIONS(SYS,N) en rend N.

  Cette fonction est un utilitaire interne de la boîte à outils
  Automatique : elle n'existe pas dans MATLAB.

  Voir aussi BODE, LOGSPACE.
```

## `matlibre_racine_carree`

```
MATLIBRE_RACINE_CARREE Racine carrée d'une matrice symétrique positive.
  R = MATLIBRE_RACINE_CARREE(M) rend la matrice symétrique R telle que
  R*R = M, pour M symétrique définie positive. Elle passe par la
  décomposition en valeurs propres : M = V*D*V', donc R = V*sqrt(D)*V'.

  C'est ce dont le décalage de boucle de la synthèse H-infini a besoin,
  là où SQRTM, qui traite le cas général, coûterait davantage.

  Cette fonction est un utilitaire interne de la boîte à outils
  Automatique : elle n'existe pas dans MATLAB.

  Voir aussi SQRTM, CHOL, EIG.
```

## `matlibre_reglages_bode`

```
MATLIBRE_REGLAGES_BODE Ce qu'un tracé retient d'une structure d'options.
  R = MATLIBRE_REGLAGES_BODE(OPTIONS) lit la structure que rend
  BODEOPTIONS et en tire ce dont BODE et BODEMAG ont besoin : le
  diviseur qui porte la pulsation dans l'unité demandée, le choix des
  décibels, le facteur de phase, la grille, les bornes et les libellés.
  OPTIONS vide rend les valeurs par défaut.

  Cette fonction est un utilitaire interne de la boîte à outils
  Automatique : elle n'existe pas dans MATLAB.

  Voir aussi BODE, BODEMAG, BODEOPTIONS.
```

## `matlibre_riccati`

```
MATLIBRE_RICCATI Solution stabilisante d'une équation de Riccati.
  [X,OK] = MATLIBRE_RICCATI(A,S,Q) résout

     A'*X + X*A + X*S*X + Q = 0

  et rend la solution stabilisante : celle qui rend A + S*X stable. OK
  est faux quand elle n'existe pas — c'est ainsi que la synthèse
  H-infini apprend qu'un GAMMA est trop petit.

  La solution vient du sous-espace invariant stable de la matrice
  hamiltonienne

     H = [ A   S ; -Q  -A' ]

  dont une base [U1; U2] donne X = U2/U1. Ce sous-espace est cherché de
  deux façons, parce qu'aucune ne suffit seule :

    - par les vecteurs propres, exacte quand les valeurs propres sont
      distinctes, mise en défaut dès que deux pôles se confondent — un
      modèle avec un pôle double en donne aussitôt ;
    - par la fonction signe, dont l'itération de Newton
      Z <- (Z + inv(Z))/2 converge vers une matrice dont (I - Z)/2
      projette sur le sous-espace stable, pôles doubles ou non, mais qui
      perd en précision sur une matrice mal conditionnée.

  On garde celle des deux qui laisse le plus petit résidu, et l'on
  vérifie qu'elle stabilise vraiment. Une solution qui ne passe ni l'un
  ni l'autre contrôle est refusée : c'est le cas sans solution.

  Cette fonction est un utilitaire interne de la boîte à outils
  Automatique : elle n'existe pas dans MATLAB.

  Voir aussi CARE, DARE, HINFSYN.
```

## `minreal`

```
MINREAL Réalisation minimale d'un modèle.
  SYSR = MINREAL(SYS) retire les états que la commande n'atteint pas et
  ceux que la sortie ne voit pas : le modèle rendu a la même
  transmittance, avec le moins d'états possible.

  SYSR = MINREAL(SYS,TOL) choisit la tolérance sous laquelle un mode
  est jugé non commandable ou non observable.

  C'est ce qu'il faut après un assemblage par produits et boucles, qui
  empile des états sans s'occuper des redondances.

  Exemples :
     g = tf(conv([1 1], [1 2]), conv([1 1], [1 3]));
     order(ss(minreal(g)))                % 1 : le pole en -1 s'est simplifie
     abs(dcgain(minreal(g)) - dcgain(g)) < 1e-9

  Voir aussi SSDATA, CTRB, OBSV, BALREAL, ZERO.
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

## `ngrid`

```
NGRID Abaque de Nichols : les courbes de gain en boucle fermée.
  NGRID trace, sur un diagramme de Nichols, les courbes le long
  desquelles le gain en boucle fermée est constant. Là où la courbe de
  la boucle ouverte frôle celle de +3 dB, la boucle fermée résonne ;
  celle de 0 dB passe par le point critique.

  Les courbes viennent de l'équation |L/(1+L)| = M : à phase donnée, le
  module |L| est racine d'un trinôme, et l'on trace la solution.

  Exemples :
     figure
     nichols(tf(1, [1 1 1]));
     ngrid
     close

  Voir aussi NICHOLS, SGRID, ZGRID, MARGIN.
```

## `nichols`

```
NICHOLS Diagramme de Nichols : gain en décibels contre phase.
  NICHOLS(SYS) porte le gain en ordonnée et la phase en abscisse : les
  deux marges se lisent d'un coup sur la même courbe, autour du point
  critique (-180 degrés, 0 dB).

  NICHOLS(SYS,W) impose la grille de pulsations, en radians par seconde.

  NICHOLS(SYS1,SYS2,...,W) superpose plusieurs modèles ; une chaîne de
  style peut suivre chacun d'eux, comme dans PLOT.

  [MAG,PHASE,W] = NICHOLS(SYS) ne trace rien et rend le module —
  linéaire, pas en décibels —, la phase en degrés et la grille, comme
  BODE.

  Exemple :
     nichols(tf(1, [1 1 1]))

  Voir aussi BODE, NYQUIST, MARGIN.
```

## `nyquist`

```
NYQUIST Lieu de Nyquist.
  NYQUIST(SYS) trace, dans le plan complexe, la réponse fréquentielle du
  modèle SYS quand la pulsation parcourt tout l'axe imaginaire : la
  partie positive, puis son image par symétrie. Le point -1 dit la
  stabilité de la boucle fermée — c'est le critère de Nyquist.

  NYQUIST(SYS,W) impose la grille de pulsations, en radians par seconde.

  NYQUIST(SYS1,SYS2,...,W) superpose plusieurs modèles ; une chaîne de
  style peut suivre chacun d'eux, comme dans PLOT.

  [RE,IM] = NYQUIST(SYS) ne trace rien et rend les parties réelle et
  imaginaire ; [RE,IM,W] = NYQUIST(SYS) rend en plus la grille.

  Exemple :
     nyquist(tf(1, [1 1 1]))

  Voir aussi BODE, NICHOLS, MARGIN.
```

## `obsv`

```
OBSV Matrice d'observabilité.
  M = OBSV(A,C) rend [C; CA; CA^2; ... ; CA^(n-1)]. Le système est
  observable — l'état se reconstruit à partir de la sortie — si et
  seulement si cette matrice est de rang plein.

  M = OBSV(SYS) prend les matrices du modèle.

  Exemples :
     rank(obsv([0 1; 0 0], [1 0]))        % 2 : observable
     rank(obsv([1 0; 0 2], [1 0]))        % 1 : le second etat reste cache
     size(obsv(ss(-1, 1, 1, 0)))          % 1  1

  Voir aussi CTRB, OBSVF, GRAM, KALMAN, RANK.
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

## `pade`

```
PADE Approximation d'un retard pur par une fonction de transfert.
  [NUM,DEN] = PADE(T,N) rend l'approximation de Padé d'ordre N du retard
  exp(-T*s) : le quotient de deux polynômes de degré N dont le
  développement en série coïncide avec celui de l'exponentielle jusqu'à
  l'ordre 2N.

  SYS = PADE(T,N) rend directement le modèle. Sans sortie, la fonction
  trace la réponse indicielle et compare à un retard exact.

  Un retard est ce qui déstabilise une boucle sans qu'on le voie venir :
  il ne change pas le gain, seulement la phase, et l'approximer permet
  de le porter dans un calcul de marges ou une synthèse.

  L'ordre 1 suffit rarement au-delà de la bande passante ; l'ordre 3 ou
  4 tient jusqu'à environ deux radians de déphasage.

  Exemples :
     [num, den] = pade(0.1, 1);
     num                          % [-1 20] : le zero instable du retard
     G = pade(0.5, 3);
     abs(dcgain(G) - 1) < 1e-9    % un retard ne change pas le gain statique

  Voir aussi C2D, MARGIN, TF, EXP.
```

## `parallel`

```
PARALLEL Mise en parallèle de deux modèles.
  SYS = PARALLEL(SYS1,SYS2) fait entrer le même signal dans les deux
  modèles et somme leurs sorties : c'est SYS1 + SYS2. À ne pas
  confondre avec APPEND, qui les juxtapose sans rien relier.

  Exemple :
     parallel(tf(1, [1 1]), tf(1, [1 2]))

  Voir aussi SERIES, FEEDBACK, APPEND.
```

## `pid`

```
PID Correcteur proportionnel, intégral et dérivé.
  C = PID(KP,KI,KD) rend le correcteur KP + KI/s + KD*s, sous forme de
  fonction de transfert.

  C = PID(KP,KI,KD,TF) filtre l'action dérivée par 1/(TF*s+1), ce qu'il
  faut toujours faire en pratique : un dérivateur pur amplifie le bruit
  sans limite.

  Exemples :
     c = pid(2, 1, 0);
     dcgain(c)                            % Inf : l'integrateur annule l'erreur
     c2 = pid(1, 0, 0.1, 0.01);
     isfinite(evalfr(c2, 1e6))            % vrai : la derivee est filtree

  Voir aussi PIDSTD, PIDTUNE, TF, FEEDBACK, MARGIN.
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

## `pidtool`

```
PIDTOOL Réglage d'un correcteur PID.
  PIDTOOL(SYS) règle un PID sur le procédé SYS et trace la réponse
  indicielle de la boucle fermée, avec celle du procédé seul.
  PIDTOOL(SYS,TYPE) choisit la forme : 'p', 'pi', 'pd', 'pid' ou un
  correcteur de départ.

  [C,INFO] = PIDTOOL(...) rend le correcteur et les marges obtenues,
  sans rien tracer.

  MATLAB ouvre une application où l'on déplace deux curseurs — rapidité
  et robustesse — et voit la réponse changer. MatLibre n'a pas
  d'application interactive : il règle le correcteur comme le fait
  PIDTUNE et montre le résultat.

  Exemple :
     C = pidtool(tf(1, [1 3 3 1]), 'pid');

  Voir aussi PIDTUNE, PID, PIDSTD, MARGIN, STEP.
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
PLACE Placement de pôles par retour d'état.
  K = PLACE(A,B,P) rend le gain tel que les valeurs propres de A - B*K
  soient celles de P. Pour plusieurs entrées, le gain n'est pas unique :
  la fonction choisit celui qui rend les vecteurs propres les mieux
  conditionnés, ce qui limite la sensibilité du placement.

  Les pôles complexes doivent aller par paires conjuguées, et le
  système être commandable.

  Exemples :
     A = [0 1; 0 0]; B = [0; 1];
     K = place(A, B, [-1 -2]);
     sort(eig(A - B*K))                   % -2  -1
     K2 = place(A, B, [-1+1i, -1-1i]);
     max(real(eig(A - B*K2))) < 0         % vrai

  Voir aussi ACKER, LQR, EIG, CTRB.
```

## `pole`

```
POLE Pôles d'un modèle.
  P = POLE(SYS) rend les pôles : les racines du dénominateur d'une
  fonction de transfert, les valeurs propres de A pour un modèle
  d'état. Ils disent la stabilité — partie réelle négative en temps
  continu, module inférieur à un en discret — et la vitesse.

  Exemples :
     pole(tf(1, [1 3 2]))                 % -2  -1
     max(real(pole(feedback(tf(1, [1 1]), 1)))) < 0   % boucle stable
     abs(pole(ss(-3, 1, 1, 0)) + 3) < 1e-12

  Voir aussi ZERO, PZMAP, DAMP, EIG, ROOTS.
```

## `prescale`

```
PRESCALE Met un modèle à l'échelle pour le calcul.
  SYSP = PRESCALE(SYS) rend un modèle équivalent dont les états sont
  remis à l'échelle : cela améliore le conditionnement des calculs de
  pôles, de zéros et de réponses fréquentielles, sans changer ce que le
  modèle représente.

  La mise à l'échelle est diagonale, par puissances de deux : elle est
  donc exacte en virgule flottante.

  Exemples :
     sys = ss([-1 1e6; 0 -2], [1; 1e6], [1 1e-6], 0);
     p = prescale(sys);
     max(abs(sort(pole(p)) - sort(pole(sys)))) < 1e-6      % memes poles
     abs(dcgain(p) - dcgain(sys)) < 1e-9                   % meme gain

  Voir aussi SS, BALREAL, POLE, MATLIBRE_EQUILIBRER.
```

## `pzmap`

```
PZMAP Pôles et zéros d'un modèle.
  PZMAP(SYS) place les pôles et les zéros du modèle dans le plan
  complexe : les pôles par des croix, les zéros par des ronds. La
  stabilité se lit à la position des croix — à gauche de l'axe
  imaginaire en temps continu, dans le cercle unité en discret.

  PZMAP(SYS1,SYS2,...) superpose plusieurs modèles.

  [P,Z] = PZMAP(SYS) ne trace rien et rend les pôles et les zéros en
  colonnes.

  Exemple :
     [p, z] = pzmap(tf([1 1], [1 3 2]));   % p = [-2;-1], z = -1

  Voir aussi POLE, ZERO, DAMP, RLOCUS.
```

## `pzplot`

```
PZPLOT Carte des pôles et des zéros.
  PZPLOT(SYS) trace les pôles et les zéros dans le plan complexe. C'est
  PZMAP, sous le nom que MATLAB donne à la version qui rend une poignée
  de tracé ; les deux dessinent la même chose.

  PZPLOT(SYS1,SYS2,...) superpose plusieurs modèles.

  Exemples :
     figure
     pzplot(tf([1 1], [1 3 2]));
     close

  Voir aussi PZMAP, POLE, ZERO, RLOCUS, SGRID.
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
  RLOCUS(SYS) trace, dans le plan complexe, le chemin que suivent les
  pôles de la boucle 1 + K*SYS quand le gain K va de 0.01 à 1000. Les
  branches partent des pôles de SYS et vont vers ses zéros.

  RLOCUS(SYS,K) impose les gains à essayer.

  RLOCUS(SYS1,SYS2,...,K) superpose plusieurs modèles ; une chaîne de
  style peut suivre chacun d'eux, comme dans PLOT.

  [R,K] = RLOCUS(SYS) ne trace rien et rend les racines et les gains
  employés. R porte une ligne par pôle et une colonne par gain, comme
  dans MATLAB : R(i,j) est le i-ème pôle de la boucle fermée au gain
  K(j), si bien que PLOT(R.') dessine les branches.

  Exemple :
     rlocus(tf(1, [1 2 0]))

  Voir aussi PZMAP, POLE, FEEDBACK, PLACE.
```

## `rlocusplot`

```
RLOCUSPLOT Lieu des racines.
  RLOCUSPLOT(SYS) trace le lieu des racines. C'est RLOCUS, sous le nom
  que MATLAB donne à la version qui rend une poignée de tracé.

  Exemples :
     figure
     rlocusplot(tf(1, [1 2 0]));
     close

  Voir aussi RLOCUS, PZMAP, SGRID, POLE.
```

## `rss`

```
RSS Modèle d'état continu stable, tiré au hasard.
  SYS = RSS(N) rend un modèle d'ordre N, à une entrée et une sortie,
  dont tous les pôles sont dans le demi-plan gauche. C'est ce qu'on
  emploie pour éprouver un algorithme sur des modèles quelconques.

  SYS = RSS(N,NY) donne NY sorties ; SYS = RSS(N,NY,NU) donne aussi NU
  entrées.

  Les pôles sont tirés sur une loi normale et leur partie réelle est
  rendue négative : le modèle est stable par construction.

  Exemples :
     sys = rss(3);
     max(real(pole(sys))) < 0     % vrai : le modele est stable
     isequal(size(rss(2, 3, 4)), [3 4])

  Voir aussi DRSS, SS, POLE, RAND.
```

## `series`

```
SERIES Mise en série de deux modèles.
  SYS = SERIES(SYS1,SYS2) met SYS1 devant SYS2 : la sortie du premier
  entre dans le second. C'est SYS2*SYS1, l'ordre des facteurs suivant
  celui du produit matriciel et non celui du schéma.

  Les modèles à plusieurs voies sont acceptés : SYS1 doit avoir autant
  de sorties que SYS2 a d'entrées.

  Exemple :
     L = series(tf(1, [1 1]), tf(10, [1 0]))   % 10/(s^2+s)

  Voir aussi FEEDBACK, PARALLEL, APPEND, LFT.
```

## `sgrid`

```
SGRID Grille d'amortissement et de pulsation propre, plan continu.
  SGRID trace, sur la figure courante, les droites d'amortissement
  constant et les arcs de pulsation propre constante du plan de Laplace.
  C'est la grille que l'on lit sur un lieu des racines ou une carte des
  pôles : un pôle sur la droite à 0.7 donne un dépassement de cinq pour
  cent, un pôle sur l'arc à 10 rad/s une réponse de l'ordre de la demi-
  seconde.

  SGRID(ZETA,WN) ne trace que les valeurs demandées.

  Les bornes de l'axe ne bougent pas : la grille s'y adapte.

  Exemples :
     figure
     rlocus(tf(1, [1 2 0]));
     sgrid
     close
     figure
     pzmap(tf(1, [1 0.4 1]));
     sgrid(0.2, 1);
     close

  Voir aussi ZGRID, NGRID, RLOCUS, PZMAP, DAMP.
```

## `sigma`

```
SIGMA Valeurs singulières de la réponse fréquentielle.
  SIGMA(SYS) trace, en décibels et en échelle logarithmique de
  pulsation, les valeurs singulières de la matrice de transfert. Pour un
  modèle monovariable il n'y en a qu'une, égale au module de la réponse :
  le tracé est alors celui de BODEMAG.

  SIGMA(SYS,W) impose la grille de pulsations, en radians par seconde :
  un vecteur, ou {WMIN,WMAX} pour n'en donner que les bornes.

  SIGMA(SYS1,SYS2,...,W) superpose plusieurs modèles ; une chaîne de
  style peut suivre chacun d'eux, comme dans PLOT :
  SIGMA(S,'b',T,'r--',W).

  SV = SIGMA(SYS,W) ne trace rien et rend les valeurs singulières,
  rangées par ligne et décroissantes, une colonne par pulsation.
  [SV,W] = SIGMA(SYS) rend en plus la grille employée.

  La plus grande valeur singulière est le gain que le modèle peut donner
  à cette pulsation ; son maximum sur toutes les pulsations est la norme
  H-infini, que rend HINFNORM.

  Exemple :
     max(sigma(tf(1, [1 1])))   % 1 : le gain le plus fort est en zéro

  Voir aussi FREQRESP, BODE, BODEMAG, HINFNORM.
```

## `sisotool`

```
SISOTOOL Analyse d'une boucle à une entrée et une sortie.
  SISOTOOL(SYS) trace ensemble le lieu des racines, le diagramme de
  Bode et la réponse indicielle en boucle fermée : les trois vues qui
  servent à régler un correcteur.
  SISOTOOL(SYS,C) place le correcteur C dans la boucle.

  MATLAB ouvre une application où l'on déplace les pôles et les zéros
  du correcteur à la souris. MatLibre n'a pas d'application
  interactive : il montre les mêmes vues, calculées une fois.

  Exemple :
     sisotool(tf(1, [1 3 3 1]));

  Voir aussi RLOCUS, BODE, STEP, MARGIN, PIDTOOL.
```

## `ss`

```
SS Modèle d'état.
  SYS = SS(A,B,C,D) crée un modèle continu dx/dt = Ax + Bu, y = Cx + Du.
  SYS = SS(A,B,C,D,TS) crée un modèle échantillonné.
  SYS = SS(SYS) convertit n'importe quel modèle en modèle d'état : une
  fonction de transfert passe par TF2SS, forme compagne de commande.
  SYS = SS(K) crée un gain statique, sans état.

  Les opérateurs + - * / ^ sont définis, comme sur les fonctions de
  transfert : le calcul passe par TF, et le résultat revient en modèle
  d'état dès qu'un des opérandes en est un.

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
SS2TF Modèle d'état vers fonction de transfert.
  [NUM,DEN] = SS2TF(A,B,C,D) rend les coefficients de la transmittance
  C(sI-A)^{-1}B + D, du degré le plus haut au plus bas. Le dénominateur
  est le polynôme caractéristique de A.

  [NUM,DEN] = SS2TF(A,B,C,D,IU) choisit l'entrée IU d'un modèle qui en
  a plusieurs.

  Exemples :
     [num, den] = ss2tf(-1, 1, 1, 0);
     num                                  % 0  1
     den                                  % 1  1, soit 1/(s+1)
     [n2, d2] = ss2tf([0 1; -2 -3], [0; 1], [1 0], 0);
     max(abs(d2 - [1 3 2])) < 1e-12

  Voir aussi TF2SS, SSDATA, TFDATA, TF, SS.
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

## `stabsep`

```
STABSEP Sépare la partie stable de la partie instable d'un modèle.
  [GS,GNS] = STABSEP(SYS) découpe le modèle en deux : GS ne garde que
  les modes stables, GNS que les autres, et leur somme redonne SYS.

  C'est ce qu'il faut avant une réduction de modèle — on ne réduit que
  ce qui est stable — et pour mesurer une norme H2 ou H-infini d'un
  modèle qui ne l'est pas tout entier.

  Le découpage passe par la forme diagonale : chaque mode va d'un côté
  ou de l'autre selon le signe de sa partie réelle, ou son module en
  discret.

  Exemples :
     [gs, gns] = stabsep(ss([-1 0; 0 2], [1; 1], [1 1], 0));
     order(gs)                        % 1 : le mode en -1
     order(gns)                       % 1 : le mode en +2
     abs(dcgain(gs) + dcgain(gns) - dcgain(ss([-1 0; 0 2], [1;1], [1 1], 0))) < 1e-9

  Voir aussi BALRED, MODRED, POLE, HSVD, EIG.
```

## `step`

```
STEP Réponse indicielle.
  STEP(SYS) trace la réponse du modèle SYS à un échelon unité, sur un
  horizon choisi d'après ses pôles : huit fois la constante de temps la
  plus lente, bornée entre une seconde et mille.

  STEP(SYS,TFINAL) impose l'horizon, en secondes. STEP(SYS,T) où T est
  un vecteur impose la grille de temps.

  STEP(SYS1,SYS2,...,T) superpose plusieurs modèles ; une chaîne de
  style peut suivre chacun d'eux, comme dans PLOT :
  STEP(SYS,'b',SYSCORRIGE,'r--').

  [Y,T] = STEP(SYS) ne trace rien et rend la réponse et les instants.

  STEP(...,OPTIONS) où OPTIONS vient de STEPDATAOPTIONS part du niveau
  InputOffset et monte de StepAmplitude, au lieu de l'échelon unité.

  Exemple :
     G = tf(1, [1 0.4 1]);
     step(G, feedback(G, 1), 30)

  Voir aussi IMPULSE, LSIM, INITIAL, STEPINFO, STEPDATAOPTIONS.
```

## `stepDataOptions`

```
STEPDATAOPTIONS Options d'une réponse indicielle.
  O = STEPDATAOPTIONS rend une structure d'options que STEP accepte :
  elle sert surtout à donner les niveaux de l'échelon.

  O = STEPDATAOPTIONS('InputOffset',U0,'StepAmplitude',A) part du
  niveau U0 et monte de A : la réponse rendue est alors celle du saut
  de U0 à U0+A, et non celle du saut unité.

  Exemple :
     o = stepDataOptions('StepAmplitude', 5);
     y = step(tf(1, [1 1]), 0:0.1:5, o);

  Voir aussi STEP, STEPINFO, BODEOPTIONS, GENSIG.
```

## `stepinfo`

```
STEPINFO Caractéristiques d'une réponse indicielle.
  S = STEPINFO(SYS) rend une structure décrivant la réponse à un
  échelon : RiseTime le temps de montée de 10 à 90 pour cent,
  SettlingTime le temps d'établissement à 2 pour cent, Overshoot le
  dépassement en pourcentage, Peak la valeur maximale et PeakTime
  l'instant où elle est atteinte.

  S = STEPINFO(Y,T) part d'une réponse déjà simulée, et
  S = STEPINFO(Y,T,YFINAL) impose la valeur finale au lieu de la lire
  sur le dernier point — utile quand la simulation s'arrête avant que
  la réponse ne se soit établie.

  Exemples :
     s = stepinfo(tf(1, [1 1]));
     s.Overshoot < 1                      % un premier ordre ne depasse pas
     s2 = stepinfo(tf(1, [1 0.4 1]));
     s2.Overshoot > 50                    % un second ordre peu amorti, si

  Voir aussi STEP, LSIM, DAMP, BANDWIDTH.
```

## `sumblk`

```
SUMBLK Point de sommation, décrit par une équation.
  S = SUMBLK('e = r - y') rend un modèle statique dont la sortie
  s'appelle « e » et les entrées « r » et « y », avec les signes de
  l'équation. C'est le bloc qu'on met dans un CONNECT pour faire une
  différence ou une somme, sans écrire de matrice.

  S = SUMBLK('e = r - y',N) répète le point de sommation sur N voies :
  les signaux s'appellent alors e(1), e(2), et ainsi de suite.

  Les termes peuvent porter un gain : 'e = r - 2*y'.

  Exemple :
     S = sumblk('e = r - y');
     S.InputName'        % {'r', 'y'}
     S.D                 % [1 -1]

  Voir aussi CONNECT, SS, APPEND, FEEDBACK.
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

  S = TF('s') rend la variable de Laplace, Z = TF('z',TS) la variable
  d'avance échantillonnée. On écrit alors les modèles comme on les
  écrit à la main :

     s = tf('s');
     G = 1 / (s^2 + 2*s + 1)
     z = tf('z', 0.1);
     C = 0.5*(z - 0.9) / (z - 1)

  Les opérateurs + - * / ^ sont définis entre modèles et avec les
  nombres : SERIES, PARALLEL et FEEDBACK ne servent plus qu'à nommer
  l'intention.

  Exemple :
     G = tf([1], [1 2 1]);   % 1/(s+1)^2
     tf(ss(-1, 1, 1, 0))     % 1/(s+1)

  Voir aussi SS, ZPK, TFDATA, SS2TF.
```

## `tf2ss`

```
TF2SS Fonction de transfert vers modèle d'état.
  [A,B,C,D] = TF2SS(NUM,DEN) rend la forme compagne de commande : la
  réalisation dont la matrice A porte les coefficients du dénominateur
  sur sa première ligne. Le modèle obtenu est commandable par
  construction ; il n'est observable que si la transmittance n'a pas de
  simplification pôle-zéro.

  Exemples :
     [A, B, C, D] = tf2ss(1, [1 3 2]);
     sort(eig(A))                         % -2  -1, les poles
     D                                    % 0 : la transmittance est stricte
     rank(ctrb(A, B))                     % 2 : commandable par construction

  Voir aussi SS2TF, SS, TF, SSDATA, CANON.
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

## `thiran`

```
THIRAN Filtre passe-tout à retard fractionnaire.
  SYS = THIRAN(RETARD,TS) approche un retard de RETARD secondes par un
  filtre numérique passe-tout de période d'échantillonnage TS. Le
  retard n'a pas à être un multiple de TS : la partie fractionnaire est
  rendue par un passe-tout dont le retard de groupe est maximalement
  plat en zéro, ce qui est la construction de Thiran.

  Un passe-tout ne change aucun module : seule la phase bouge, comme
  pour un vrai retard. C'est ce qui le distingue d'une approximation
  par troncature, qui déforme la réponse.

  Les coefficients viennent de la formule de Thiran :

     a(k) = (-1)^k C(N,k) prod_{i=0..N} (D - N + i) / (D - N + k + i)

  où D est le retard en périodes et N l'ordre du filtre.

  Exemple :
     sys = thiran(0.25, 0.1);         % 2,5 périodes
     [~, ~, ~] = zpkdata(sys);

  Voir aussi PADE, C2D, D2D, DELAYSS, ABSORBDELAY.
```

## `totaldelay`

```
TOTALDELAY Retard total de chaque voie d'un modèle.
  D = TOTALDELAY(SYS) rend la matrice des retards, une valeur par couple
  entrée-sortie.

  MatLibre ne représente pas les retards : la matrice est nulle. PADE
  donne l'approximation d'un retard sous forme de transmittance.

  Exemples :
     totaldelay(tf(1, [1 1]))         % 0
     isequal(size(totaldelay(ss(zeros(2), zeros(2), zeros(2), zeros(2)))), [2 2])

  Voir aussi HASDELAY, PADE.
```

## `tzero`

```
TZERO Zéros de transmission d'un modèle.
  Z = TZERO(SYS) rend les zéros de transmission : les valeurs de s pour
  lesquelles le modèle ne transmet rien, quelle que soit l'entrée. Un
  zéro à partie réelle positive — un zéro instable — limite ce qu'un
  correcteur peut faire, quel qu'il soit.

  Ils s'obtiennent comme les valeurs propres généralisées du faisceau
  de Rosenbrock.

  Exemples :
     tzero(tf([1 -1], [1 3 2]))           % 1 : un zero instable
     isempty(tzero(tf(1, [1 1])))         % vrai : aucun zero
     abs(tzero(ss(-1, 1, -1, 1)) - 0) < 1e-9

  Voir aussi ZERO, POLE, PZMAP, MINREAL.
```

## `zero`

```
ZERO Zéros d'un modèle.
  Z = ZERO(SYS) rend les zéros : les racines du numérateur d'une
  fonction de transfert, les zéros de transmission d'un modèle d'état.
  [Z,K] = ZERO(SYS) rend en plus le gain.

  Un zéro dans le demi-plan droit fait partir la réponse indicielle du
  mauvais côté avant de revenir : c'est le comportement à non-minimum
  de phase, qu'aucun correcteur ne supprime.

  Exemples :
     zero(tf([1 2], [1 3 2]))             % -2
     isempty(zero(tf(1, [1 1])))          % vrai
     zero(tf([1 -1], [1 1]))              % 1 : a non-minimum de phase

  Voir aussi POLE, TZERO, PZMAP, ROOTS.
```

## `zgrid`

```
ZGRID Grille d'amortissement et de pulsation propre, plan discret.
  ZGRID trace, dans le plan des z, le cercle unité, les spirales
  d'amortissement constant et les courbes de pulsation propre constante.
  C'est la grille du lieu des racines d'un système échantillonné.

  ZGRID(ZETA,WN) ne trace que les valeurs demandées ; WN est normalisée
  par la fréquence d'échantillonnage, entre 0 et 1.

  Un pôle discret se lit par son image continue : z = exp(s*Ts), d'où
  les spirales.

  Exemples :
     figure
     pzmap(c2d(tf(1, [1 0.4 1]), 0.1));
     zgrid
     close

  Voir aussi SGRID, NGRID, RLOCUS, PZMAP, C2D.
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
  demande. Il s'affiche en facteurs, comme sous MATLAB.

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

