# Toolbox `robotique`

```
% Robotics System Toolbox — cinématique et transformations.
%
%   rotx, roty, rotz    - Rotations élémentaires
%   eul2rotm, rotm2eul  - Angles d'Euler ZYX
%   eul2quat, quat2rotm, rotm2quat - Quaternions
%   quatmultiply, quatconj, quatnormalize
%   trvec2tform, tform2trvec, rotm2tform, tform2rotm
%   dhTransform         - Matrice de Denavit-Hartenberg
%   fkine2R, ikine2R    - Cinématique d'un bras plan à deux segments
%   jacobian2R          - Jacobienne du même bras
```

## `angdiff`

```
ANGDIFF Différence de deux angles, ramenée dans [-pi, pi].
  D = ANGDIFF(A,B) rend B - A ramené dans [-pi, pi].
  D = ANGDIFF(A) rend les différences successives des éléments de A.

  Soustraire deux angles sans précaution donne des résultats faux dès
  qu'on franchit pi : la différence entre 3.1 et -3.1 radians vaut 0.08
  radian, non 6.2. Le repliement est donc la seule opération correcte,
  et c'est tout ce que fait cette fonction.

  Exemple :
     angdiff(3.1, -3.1)              % 0.0832, non -6.2
     angdiff([0 pi/2 pi])            % [pi/2 pi/2]

  Voir aussi WRAPTOPI, MOD.
```

## `axang2quat`

```
AXANG2QUAT Axe et angle vers quaternion.
  Q = AXANG2QUAT([X Y Z THETA]) rend [W X Y Z] avec

     w = cos(theta/2),   [x y z] = sin(theta/2) * axe

  La demi-mesure n'est pas un choix : un quaternion agit sur un vecteur
  par q v q*, donc deux fois, et il faut la moitié de l'angle pour que
  le compte tombe juste. C'est aussi pourquoi q et -q décrivent la même
  rotation.

  Une matrice N sur 4 rend une matrice N sur 4 de quaternions.

  Exemple :
     axang2quat([0 0 1 pi])       % [0 0 0 1] au signe pres

  Voir aussi QUAT2AXANG, AXANG2ROTM, EUL2QUAT.
```

## `axang2rotm`

```
AXANG2ROTM Axe et angle vers matrice de rotation.
  R = AXANG2ROTM([X Y Z THETA]) rend la rotation d'angle THETA radians
  autour de l'axe [X Y Z], par la formule de Rodrigues :

     R = I + sin(theta) K + (1 - cos(theta)) K^2

  où K est la matrice antisymétrique du vecteur unitaire de l'axe.

  Une matrice N sur 4 rend un tableau 3x3xN.

  L'axe est normalisé : sa longueur ne porte aucune information, seule
  sa direction compte.

  Exemple :
     R = axang2rotm([0 0 1 pi / 2]);   % quart de tour autour de z
     R * [1; 0; 0]                     % [0; 1; 0]

  Voir aussi ROTM2AXANG, AXANG2QUAT, AXANG2TFORM, EUL2ROTM.
```

## `axang2tform`

```
AXANG2TFORM Axe et angle vers matrice homogène 4x4.
  T = AXANG2TFORM([X Y Z THETA]) rend la transformation de rotation
  pure : translation nulle, coin supérieur gauche égal à AXANG2ROTM.

  Une matrice N sur 4 rend un tableau 4x4xN.

  Exemple :
     T = axang2tform([0 0 1 pi / 2]);
     T(1:3, 4)                       % [0; 0; 0] : aucune translation

  Voir aussi TFORM2AXANG, AXANG2ROTM, ROTM2TFORM, TRVEC2TFORM.
```

## `bsplinepolytraj`

```
BSPLINEPOLYTRAJ Trajectoire par B-spline sur des points de contrôle.
  [Q,QD,QDD] = BSPLINEPOLYTRAJ(CONTROLE,INTERVALLE,ECHANTILLONS) rend
  la courbe B-spline cubique de points de contrôle CONTROLE — une ligne
  par degré de liberté — évaluée aux instants demandés.
  INTERVALLE = [T0 TF] donne les bornes du paramètre.

  La courbe ne passe pas par ses points de contrôle intérieurs : elle
  les longe. C'est ce qui la distingue d'une interpolation, et c'est
  voulu — la courbe reste dans l'enveloppe convexe de ses points, donc
  dans la zone qu'on a définie, quoi qu'il arrive. Un dépassement y est
  impossible par construction, alors qu'un polynôme interpolant en
  produit dès qu'on lui donne des points serrés.

  Les extrémités, elles, sont atteintes exactement : le vecteur de
  nœuds est serré aux deux bouts.

  [Q,QD,QDD,PP] = BSPLINEPOLYTRAJ(...) rend aussi la description de la
  courbe.

  Exemple :
     p = [0 1 3 4; 0 2 2 0];
     [q, qd] = bsplinepolytraj(p, [0 1], linspace(0, 1, 50));
     q(:, 1)                         % le premier point de controle
     max(q(2, :)) <= max(p(2, :))    % l'enveloppe convexe est respectee

  Voir aussi CUBICPOLYTRAJ, QUINTICPOLYTRAJ, TRAPVELTRAJ.
```

## `cubicpolytraj`

```
CUBICPOLYTRAJ Trajectoire polynomiale cubique passant par des points.
  [Q,QD,QDD] = CUBICPOLYTRAJ(POINTS,INSTANTS,ECHANTILLONS) fait passer
  une cubique par chaque segment entre points successifs, et l'évalue
  aux instants demandés. POINTS a une ligne par degré de liberté et une
  colonne par point de passage.

  [...] = CUBICPOLYTRAJ(...,'VelocityBoundaryCondition',V) impose les
  vitesses aux points de passage ; elles sont nulles par défaut.

  [Q,QD,QDD,PP] = CUBICPOLYTRAJ(...) rend aussi la forme par morceaux.

  Une cubique est le polynôme de plus bas degré qui satisfasse quatre
  conditions : position et vitesse à chaque bout. C'est exactement ce
  qu'il faut pour raccorder deux points sans saut de vitesse — mais
  l'accélération, elle, saute encore aux points de passage. Quand cela
  gêne, QUINTICPOLYTRAJ ajoute les deux conditions qui manquent.

  Exemple :
     [q, qd] = cubicpolytraj([0 1 2; 0 2 0], [0 1 2], linspace(0, 2, 50));
     qd(:, 1)                        % nulle au depart

  Voir aussi QUINTICPOLYTRAJ, TRAPVELTRAJ, BSPLINEPOLYTRAJ.
```

## `dhTransform`

```
DHTRANSFORM Matrice de passage de Denavit-Hartenberg.
  T = DHTRANSFORM(A,ALPHA,D,THETA) avec la convention standard :
  rotation THETA autour de z, translation D selon z, translation A selon
  x, rotation ALPHA autour de x.
```

## `eul2quat`

```
EUL2QUAT Angles d'Euler ZYX vers quaternion.
```

## `eul2rotm`

```
EUL2ROTM Angles d'Euler ZYX (radians) vers matrice de rotation.
```

## `eul2tform`

```
EUL2TFORM Angles d'Euler ZYX vers matrice homogène 4x4.
  T = EUL2TFORM([Z Y X]) rend la transformation de rotation pure
  correspondant aux trois angles, en radians.

  Une matrice N sur 3 rend un tableau 4x4xN.

  Exemple :
     T = eul2tform([pi / 2 0 0]);
     T(1:3, 1:3)                     % la rotation seule

  Voir aussi TFORM2EUL, EUL2ROTM, EUL2QUAT, ROTM2TFORM.
```

## `fkine2R`

```
FKINE2R Cinématique directe d'un bras plan à deux segments.
  [X,Y] = FKINE2R([Q1 Q2],L1,L2) rend la position de l'effecteur.
```

## `ikine2R`

```
IKINE2R Cinématique inverse d'un bras plan à deux segments.
  Q = IKINE2R(X,Y,L1,L2) rend les deux angles articulaires.
```

## `jacobian2R`

```
JACOBIAN2R Jacobienne d'un bras plan à deux segments.
```

## `matlibre_rob_choisir`

```
MATLIBRE_ROB_CHOISIR Valeur commune ou valeur par degré de liberté.
  Une consigne scalaire vaut pour tous les axes ; un vecteur en donne
  une par axe.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rob_lignes`

```
MATLIBRE_ROB_LIGNES Normalise une entrée en matrice de N lignes.
  [M,UNIQUE] = MATLIBRE_ROB_LIGNES(A,LARGEUR,NOM) rend A sous forme
  d'une matrice à LARGEUR colonnes, une ligne par élément, et dit si
  l'entrée n'en comptait qu'une — auquel cas les fonctions rendent un
  résultat simple plutôt qu'une pile.

  Les fonctions de conversion de MATLAB acceptent toutes une pile :
  EUL2ROTM d'une matrice N sur 3 rend un tableau 3x3xN. Passer par ici
  évite de réécrire ce contrôle dans chacune.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rob_polytraj`

_Pas de bloc d'aide._

## `matlibre_rob_rampe`

```
MATLIBRE_ROB_RAMPE Durée de la rampe d'un profil trapézoïdal.
  Sur un segment de durée T et de distance D, un profil trapézoïdal de
  temps de rampe ta a pour aire v(T - ta), avec v la vitesse de palier.
  Imposer l'une des trois grandeurs fixe donc les deux autres :

     v = D / (T - ta)        ta = T - D / v
     a = v / ta              ta = (T - sqrt(T^2 - 4 D / a)) / 2

  Sans consigne, la rampe occupe le tiers de la durée.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rob_replier`

```
MATLIBRE_ROB_REPLIER Angles ramenés dans [-pi, pi].
  La formule mod(d + pi, 2 pi) - pi replie tout angle dans
  l'intervalle, et le cas exact de pi est rendu à pi plutôt qu'à -pi :
  c'est la convention de MATLAB.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rob_tform`

```
MATLIBRE_ROB_TFORM Matrices homogènes à partir de rotations.
  T = MATLIBRE_ROB_TFORM(R) place chaque rotation 3x3 dans le coin
  supérieur gauche d'une matrice 4x4, la translation restant nulle.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rob_trapeze`

```
MATLIBRE_ROB_TRAPEZE Profil trapézoïdal évalué aux instants T.
  La vitesse monte linéairement pendant TA, tient le palier, puis
  redescend pendant TA. Son aire vaut la distance, par construction :
  c'est ce qui fixe la vitesse de palier.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `quat2axang`

```
QUAT2AXANG Quaternion vers axe et angle.
  AXANG = QUAT2AXANG([W X Y Z]) rend [X Y Z THETA].

  L'angle est deux fois l'arc cosinus de la partie réelle ; l'axe est
  la partie imaginaire, normalisée. Un quaternion de partie imaginaire
  nulle est l'identité : son axe est indéterminé, on rend z.

  Exemple :
     quat2axang(axang2quat([1 0 0 0.4]))    % [1 0 0 0.4]

  Voir aussi AXANG2QUAT, QUAT2ROTM, QUAT2EUL.
```

## `quat2eul`

```
QUAT2EUL Quaternion vers angles d'Euler ZYX.
  EUL = QUAT2EUL([W X Y Z]) rend [Z Y X] en radians.

  Une matrice N sur 4 rend une matrice N sur 3.

  Le passage se fait par la matrice de rotation : les angles d'Euler
  n'ont pas d'expression plus directe qui évite les cas particuliers,
  et celui du blocage de cardan — quand l'angle de tangage atteint un
  quart de tour — se traite au même endroit pour les deux chemins.

  Exemple :
     quat2eul(eul2quat([0.3 0.2 0.1]))       % [0.3 0.2 0.1]

  Voir aussi EUL2QUAT, QUAT2ROTM, ROTM2EUL.
```

## `quat2rotm`

```
QUAT2ROTM Quaternion [w x y z] vers matrice de rotation.
```

## `quat2tform`

```
QUAT2TFORM Quaternion vers matrice homogène 4x4.
  T = QUAT2TFORM([W X Y Z]) rend la transformation de rotation pure.

  Une matrice N sur 4 rend un tableau 4x4xN.

  Exemple :
     quat2tform([1 0 0 0])           % l'identite

  Voir aussi TFORM2QUAT, QUAT2ROTM, ROTM2TFORM.
```

## `quatconj`

```
QUATCONJ Conjugué d'un quaternion.
```

## `quatdivide`

```
QUATDIVIDE Division de quaternions.
  R = QUATDIVIDE(Q,P) rend Q * inv(P).

  La multiplication des quaternions n'est pas commutative : diviser à
  droite et diviser à gauche ne donnent pas le même résultat. C'est la
  division à droite qui est rendue ici, comme dans MATLAB.

  Exemple :
     q = eul2quat([0.3 0.2 0.1]);
     quatdivide(q, q)                % [1 0 0 0]

  Voir aussi QUATMULTIPLY, QUATINV, QUATCONJ.
```

## `quatinv`

```
QUATINV Inverse d'un quaternion.
  R = QUATINV(Q) rend le quaternion qui, multiplié par Q, donne
  l'identité [1 0 0 0] :

     inv(q) = conj(q) / |q|^2

  Pour un quaternion unitaire — le seul cas qui décrive une rotation —
  l'inverse est donc le conjugué, et inverser une rotation revient à
  changer le signe de sa partie imaginaire.

  Exemple :
     q = eul2quat([0.3 0.2 0.1]);
     quatmultiply(q, quatinv(q))     % [1 0 0 0]

  Voir aussi QUATCONJ, QUATMULTIPLY, QUATDIVIDE, QUATNORMALIZE.
```

## `quatmultiply`

```
QUATMULTIPLY Produit de deux quaternions [w x y z].
```

## `quatnormalize`

```
QUATNORMALIZE Quaternion unitaire.
```

## `quatrotate`

```
QUATROTATE Rotation d'un vecteur par un quaternion.
  V = QUATROTATE(Q,R) applique au vecteur ligne R la rotation décrite
  par Q.

  Attention à la convention : comme dans MATLAB, la rotation appliquée
  est celle du quaternion conjugué — c'est-à-dire que QUATROTATE fait
  passer du repère de départ à celui qui a tourné, non l'inverse. Un
  vecteur tourné dans le sens direct s'obtient donc par
  QUATROTATE(QUATCONJ(Q),R), ou par QUAT2ROTM(Q) * R'.

  Une matrice N sur 3 rend une matrice N sur 3.

  Exemple :
     quatrotate([cos(pi/4) 0 0 sin(pi/4)], [1 0 0])   % [0 -1 0]
     (quat2rotm([cos(pi/4) 0 0 sin(pi/4)]) * [1;0;0]).'  % [0 1 0]

  Voir aussi QUAT2ROTM, QUATMULTIPLY, QUATCONJ.
```

## `quinticpolytraj`

```
QUINTICPOLYTRAJ Trajectoire polynomiale de degré cinq.
  [Q,QD,QDD] = QUINTICPOLYTRAJ(POINTS,INSTANTS,ECHANTILLONS) fait
  passer une quintique par chaque segment, en imposant position,
  vitesse et accélération à chaque bout.

  [...] = QUINTICPOLYTRAJ(...,'VelocityBoundaryCondition',V) et
  'AccelerationBoundaryCondition',A imposent ces conditions ; elles
  sont nulles par défaut.

  Six conditions par segment demandent six coefficients, donc le degré
  cinq. Ce que cela achète sur la cubique : une accélération continue
  d'un segment à l'autre, donc un effort continu sur les actionneurs.

  Exemple :
     [q, qd, qdd] = quinticpolytraj([0 1; 0 1], [0 1], linspace(0, 1, 30));
     qdd(:, 1)                       % nulle au depart, contrairement a la cubique

  Voir aussi CUBICPOLYTRAJ, TRAPVELTRAJ, BSPLINEPOLYTRAJ.
```

## `rotm2axang`

```
ROTM2AXANG Matrice de rotation vers axe et angle.
  AXANG = ROTM2AXANG(R) rend [X Y Z THETA]. Un tableau 3x3xN rend une
  matrice N sur 4.

  L'angle se lit sur la trace : celle d'une rotation vaut
  1 + 2 cos(theta), quelle que soit la direction de l'axe. L'axe, lui,
  est le vecteur propre associé à la valeur propre un — la seule
  direction que la rotation ne déplace pas.

  Deux cas demandent un traitement à part. À l'angle nul, l'axe est
  indéterminé : on rend l'axe z par convention. À pi, la partie
  antisymétrique s'annule et l'axe se lit sur la diagonale de R + I.

  Exemple :
     rotm2axang(axang2rotm([0 0 1 pi / 3]))    % [0 0 1 pi/3]

  Voir aussi AXANG2ROTM, ROTM2QUAT, ROTM2EUL.
```

## `rotm2eul`

```
ROTM2EUL Matrice de rotation vers angles d'Euler ZYX (radians).
```

## `rotm2quat`

```
ROTM2QUAT Matrice de rotation vers quaternion [w x y z].
```

## `rotm2tform`

```
ROTM2TFORM Rotation vers matrice homogène.
```

## `rottraj`

```
ROTTRAJ Interpolation entre deux rotations.
  [R,OMEGA,ALPHA] = ROTTRAJ(R0,RF,INTERVALLE,ECHANTILLONS) interpole
  entre deux orientations, données en quaternions [W X Y Z] ou en
  matrices 3x3. Le résultat est du même type que l'entrée.

  L'interpolation est sphérique : elle suit le plus court chemin sur la
  sphère des rotations, à vitesse angulaire constante. Interpoler
  linéairement les coefficients d'une matrice de rotation ne donnerait
  pas une rotation ; interpoler les angles d'Euler donnerait un chemin
  qui dépend de la convention choisie. Ni l'un ni l'autre n'est le plus
  court.

  Exemple :
     q0 = eul2quat([0 0 0]);
     q1 = eul2quat([pi / 2 0 0]);
     [r, w] = rottraj(q0, q1, [0 1], linspace(0, 1, 20));
     w(:, 1)                         % vitesse angulaire, constante

  Voir aussi TRANSFORMTRAJ, QUAT2ROTM, SLERP.
```

## `rotx`

```
ROTX Rotation autour de l'axe x, angle en degrés.
```

## `roty`

```
ROTY Rotation autour de l'axe y, angle en degrés.
```

## `rotz`

```
ROTZ Rotation autour de l'axe z, angle en degrés.
```

## `tform2axang`

```
TFORM2AXANG Matrice homogène vers axe et angle.
  AXANG = TFORM2AXANG(T) ne lit que la partie rotation ; la translation
  est ignorée.

  Exemple :
     tform2axang(axang2tform([0 1 0 0.7]))    % [0 1 0 0.7]

  Voir aussi AXANG2TFORM, TFORM2ROTM, TFORM2QUAT, TFORM2TRVEC.
```

## `tform2eul`

```
TFORM2EUL Matrice homogène vers angles d'Euler ZYX.
  EUL = TFORM2EUL(T) ne lit que la partie rotation.

  Exemple :
     tform2eul(eul2tform([0.3 0.2 0.1]))     % [0.3 0.2 0.1]

  Voir aussi EUL2TFORM, TFORM2ROTM, ROTM2EUL.
```

## `tform2quat`

```
TFORM2QUAT Matrice homogène vers quaternion.
  Q = TFORM2QUAT(T) ne lit que la partie rotation.

  Exemple :
     tform2quat(quat2tform([0.5 0.5 0.5 0.5]))

  Voir aussi QUAT2TFORM, TFORM2ROTM, ROTM2QUAT.
```

## `tform2rotm`

```
TFORM2ROTM Rotation contenue dans une matrice homogène.
```

## `tform2trvec`

```
TFORM2TRVEC Translation contenue dans une matrice homogène.
```

## `transformtraj`

```
TRANSFORMTRAJ Interpolation entre deux transformations homogènes.
  [T,V,A] = TRANSFORMTRAJ(T0,TF,INTERVALLE,ECHANTILLONS) interpole
  entre deux matrices 4x4 et rend un tableau 4x4xN.

  La rotation est interpolée sphériquement, la translation
  linéairement : ce sont deux quantités de natures différentes, et les
  traiter ensemble — en interpolant les seize coefficients — ne
  donnerait même pas des matrices de transformation valides.

  V rend les six composantes de la vitesse : les trois de la vitesse
  angulaire d'abord, les trois de la vitesse linéaire ensuite.

  Exemple :
     T0 = trvec2tform([0 0 0]);
     TF = trvec2tform([1 2 3]) * eul2tform([pi / 2 0 0]);
     T = transformtraj(T0, TF, [0 1], linspace(0, 1, 10));
     tform2trvec(T(:, :, end))       % [1 2 3]

  Voir aussi ROTTRAJ, TFORM2TRVEC, TRVEC2TFORM.
```

## `trapveltraj`

```
TRAPVELTRAJ Trajectoire à profil de vitesse trapézoïdal.
  [Q,QD,QDD,T] = TRAPVELTRAJ(POINTS,N) relie les points de passage par
  des segments à vitesse trapézoïdale, et rend N échantillons.

  Options :
     'EndTime'       durée de chaque segment, un par défaut
     'PeakVelocity'  vitesse du palier
     'Acceleration'  accélération des rampes
     'AccelTime'     durée de chaque rampe

  Le profil monte en rampe, tient un palier, puis redescend. C'est le
  profil des commandes d'axe les plus répandues : il atteint la
  distance voulue dans le temps voulu sans jamais dépasser une vitesse
  ni une accélération données — ce qu'aucun polynôme ne garantit.

  Une seule des trois grandeurs vitesse, accélération et temps de rampe
  suffit à fixer le profil : les deux autres s'en déduisent, la
  distance et la durée étant imposées. Par défaut la rampe occupe un
  tiers du temps de chaque côté.

  Exemple :
     [q, qd] = trapveltraj([0 2], 100);
     max(qd)                         % la vitesse de palier
     trapz(linspace(0, 1, 100), qd)  % 2 : l'aire vaut la distance

  Voir aussi CUBICPOLYTRAJ, QUINTICPOLYTRAJ, BSPLINEPOLYTRAJ.
```

## `trvec2tform`

```
TRVEC2TFORM Vecteur de translation vers matrice homogène 4x4.
```

