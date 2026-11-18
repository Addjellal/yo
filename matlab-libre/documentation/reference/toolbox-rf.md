# Toolbox `rf`

```
% RF Toolbox — grandeurs de radiofréquence.
%
% Puissances
%   dbm2w, w2dbm     - Watts et dBm, dans les deux sens
%
% Adaptation
%   z2gamma, gamma2z - Impédance et coefficient de réflexion
%   vswr             - Taux d'ondes stationnaires
%
% Quadripôles
%   sparam2zparam    - Paramètres S vers paramètres Z
%
% Bruit
%   friisNoise       - Facteur de bruit d'une chaîne d'étages
```

## `abcd2s`

```
ABCD2S Paramètres ABCD d'un quadripôle vers paramètres S.
  S = ABCD2S(ABCD) pour 50 ohms, ABCD2S(ABCD,Z0) sinon (Pozar, tableau
  4.2) : avec Q = A + B/z0 + C z0 + D,
     S11 = (A + B/z0 - C z0 - D)/Q    S12 = 2 (AD - BC)/Q
     S21 = 2/Q                        S22 = (-A + B/z0 - C z0 + D)/Q

  Exemple :
     abcd2s([1 100; 0 1])          % impédance série de 100 ohms : S11 = 0.5

  Voir aussi S2ABCD.
```

## `dbm2w`

```
DBM2W Conversion dBm vers watts.
  P = DBM2W(DBM) rend la puissance en watts. Le dBm est une puissance
  absolue rapportée au milliwatt : zéro dBm vaut un milliwatt, trente
  dBm un watt.

  Dix décibels de plus, c'est dix fois plus de puissance ; trois, c'est
  le double. C'est toute l'échelle, et elle transforme les produits en
  sommes — ce qui est la raison d'être des décibels dans un bilan de
  liaison.

  Exemple :
     dbm2w(0)                        % 1e-3
     dbm2w(30)                       % 1
     dbm2w(3) / dbm2w(0)             % 2, a 0,2 %% pres

  Voir aussi W2DBM, FRIIS, PATHLOSS.
```

## `friisNoise`

```
FRIISNOISE Facteur de bruit d'une chaîne d'étages (formule de Friis).
  [F,FDB] = FRIISNOISE(FACTEURS,GAINS) rend le facteur de bruit total,
  en linéaire et en décibels :

     F = F1 + (F2-1)/G1 + (F3-1)/(G1 G2) + ...

  FACTEURS compte un facteur de bruit par étage, GAINS un gain de moins
  — celui du dernier étage ne sert à rien. Les deux sont linéaires, non
  en décibels.

  Ce que dit la formule : le premier étage domine, parce que le bruit
  des suivants est divisé par tout le gain qui les précède. C'est
  pourquoi l'amplificateur faible bruit se met tout devant, et pourquoi
  ce qui vient après compte de moins en moins.

  Le même matériel rangé à l'envers coûte des décibels de bruit en
  plus : l'ordre est un choix de conception, non de commodité.

  Exemple :
     facteurs = 10 .^ ([1 3 10] / 10);      % 1, 3 et 10 dB
     gains    = 10 .^ ([20 15] / 10);       % 20 et 15 dB
     [~, FdB] = friisNoise(facteurs, gains) % a peine plus que 1 dB

  Voir aussi DBM2W, W2DBM.
```

## `gamma2z`

```
GAMMA2Z Impédance à partir du coefficient de réflexion.
  Z = GAMMA2Z(G) rend Z0 (1 + G) / (1 - G), avec Z0 = 50 ohms ;
  GAMMA2Z(G,Z0) impose une autre impédance caractéristique.

  C'est la réciproque exacte de Z2GAMMA, y compris pour une charge
  complexe. Un coefficient de module un — toute la puissance revient —
  donne une impédance purement réactive, ou infinie.

  Exemple :
     gamma2z(0)                      % 50 : adaptee
     gamma2z(z2gamma(37 + 12i))      % 37 + 12i

  Voir aussi Z2GAMMA, VSWR.
```

## `gammain`

```
GAMMAIN Coefficient de réflexion à l'entrée d'un quadripôle chargé.
  G = GAMMAIN(S,Z0,ZL) : Gin = S11 + S12 S21 GL / (1 - S22 GL), avec
  GL = (ZL - Z0)/(ZL + Z0) (Pozar, équation 11.3). S est 2 x 2 ou
  2 x 2 x K.

  Exemple :
     gammain([0 1; 1 0], 50, 100)  % une ligne adaptée transmet GL : 1/3

  Voir aussi GAMMAOUT, Z2GAMMA.
```

## `gammaout`

```
GAMMAOUT Coefficient de réflexion à la sortie d'un quadripôle.
  G = GAMMAOUT(S,Z0,ZS) : Gout = S22 + S12 S21 GS / (1 - S11 GS), avec
  GS = (ZS - Z0)/(ZS + Z0) (Pozar, équation 11.4).

  Exemple :
     gammaout([0 1; 1 0], 50, 25)  % -1/3

  Voir aussi GAMMAIN, Z2GAMMA.
```

## `matlibre_rf_matrices`

```
MATLIBRE_RF_MATRICES Applique une conversion de paramètres à chaque fréquence.
  R = MATLIBRE_RF_MATRICES(M,FONCTION) : M est N x N, ou N x N x K pour K
  fréquences ; FONCTION transforme une matrice N x N.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     R = matlibre_rf_matrices(eye(2), @(m) 2 * m)

  Voir aussi S2Z, Z2S, S2Y, Y2S.
```

## `s2abcd`

```
S2ABCD Paramètres S d'un quadripôle vers paramètres ABCD (chaîne).
  ABCD = S2ABCD(S) pour 50 ohms, S2ABCD(S,Z0) sinon ; S est 2 x 2 ou
  2 x 2 x K. Les formules de Pozar (tableau 4.2) :
     A = ((1+S11)(1-S22) + S12 S21) / (2 S21)
     B = z0 ((1+S11)(1+S22) - S12 S21) / (2 S21)
     C = ((1-S11)(1-S22) - S12 S21) / (2 S21 z0)
     D = ((1-S11)(1+S22) + S12 S21) / (2 S21)
  Les matrices ABCD de quadripôles en cascade se multiplient.

  Exemple :
     s2abcd([0 1; 1 0])            % une ligne adaptée sans retard : eye(2)

  Voir aussi ABCD2S, S2Z.
```

## `s2y`

```
S2Y Paramètres S vers paramètres Y : Y = (1/z0) (I - S)(I + S)^-1.
  Y = S2Y(S) pour 50 ohms, S2Y(S,Z0) pour une autre référence ; S est
  N x N ou N x N x K.

  Exemple :
     Y = s2y([0 1; 1 0])           % une ligne adaptée sans pertes

  Voir aussi Y2S, S2Z.
```

## `s2z`

```
S2Z Paramètres S vers paramètres Z : Z = z0 (I + S)(I - S)^-1.
  Z = S2Z(S) convertit les paramètres S, N x N ou N x N x K (K
  fréquences), en paramètres Z, pour une impédance de référence de
  50 ohms ; S2Z(S,Z0) la choisit. Comme MATLAB (Pozar, Microwave
  Engineering, tableau 4.2).

  Exemple :
     S = [0 0.7079; 0.7079 0];     % atténuateur adapté de 3 dB
     Z = s2z(S)                    % réseau en T : 150.3, 141.9, 150.3

  Voir aussi Z2S, S2Y, S2ABCD, Z2GAMMA.
```

## `sparam2zparam`

```
SPARAM2ZPARAM Paramètres S d'un quadripôle vers paramètres Z.
  Z = SPARAM2ZPARAM(S) convertit une matrice S 2x2 en matrice Z, avec
  Z0 = 50 ohms ; SPARAM2ZPARAM(S,Z0) impose l'impédance de référence.

     Z = Z0 (I + S) (I - S)^-1

  Les paramètres S décrivent un quadripôle par des ondes, les Z par des
  tensions et des courants. Les deux disent la même chose, mais les S se
  mesurent à haute fréquence — un circuit ouvert ou un court-circuit
  franc n'y existent pas — tandis que les Z se composent par simple
  addition quand deux quadripôles se mettent en série.

  La conversion n'est pas toujours possible : une ligne parfaitement
  transparente et adaptée, S = [0 1; 1 0], n'a pas de matrice Z finie —
  (I - S) y est singulière. Ce n'est pas un défaut de la fonction mais
  une propriété du circuit.

  Un quadripôle réciproque et symétrique en S le reste en Z.

  Exemple :
     a = 10 ^ (-6 / 20);             % attenuateur adapte de 6 dB
     Z = sparam2zparam([0 a; a 0], 50);
     Z(1,2) - Z(2,1)                 % 0 : reciproque

  Voir aussi Z2GAMMA, GAMMA2Z.
```

## `vswr`

```
VSWR Taux d'ondes stationnaires à partir du coefficient de réflexion.
  S = VSWR(G) rend (1 + |G|) / (1 - |G|), le rapport du maximum au
  minimum de la tension le long de la ligne.

  Le TOS vaut un quand rien ne revient, et croît sans borne quand tout
  revient. C'est le même renseignement que le module du coefficient de
  réflexion, sur une échelle que les appareils de mesure affichent.

  Il ne distingue pas la nature du désaccord : cent ohms et vingt-cinq
  sur une ligne de cinquante donnent le même deux, l'un par excès,
  l'autre par défaut.

  Exemple :
     vswr(0)                         % 1 : adaptee
     vswr(1/3)                       % 2
     vswr(z2gamma(100)) == vswr(z2gamma(25))    % true

  Voir aussi Z2GAMMA, GAMMA2Z.
```

## `w2dbm`

```
W2DBM Conversion watts vers dBm.
  D = W2DBM(WATTS) rend la puissance en dBm. C'est la réciproque exacte
  de DBM2W.

  Une puissance nulle rend moins l'infini, ce qui est la limite juste et
  non une erreur : aucune puissance, aucun décibel.

  Exemple :
     w2dbm(1)                        % 30
     w2dbm(dbm2w(-42))               % -42

  Voir aussi DBM2W, FRIISNOISE.
```

## `y2s`

```
Y2S Paramètres Y vers paramètres S : S = (I - z0 Y)(I + z0 Y)^-1.
  S = Y2S(Y) pour 50 ohms, Y2S(Y,Z0) pour une autre référence.

  Exemple :
     S = y2s([1 -1; -1 1] / 100)   % une impédance série de 100 ohms

  Voir aussi S2Y, Z2S.
```

## `z2gamma`

```
Z2GAMMA Coefficient de réflexion d'une impédance.
  G = Z2GAMMA(Z) rend (Z - 50) / (Z + 50) ; Z2GAMMA(Z,Z0) impose une
  autre impédance caractéristique.

  Le coefficient de réflexion dit quelle part de l'onde incidente
  revient, en amplitude et en phase. Une charge adaptée ne renvoie rien ;
  un court-circuit renvoie tout en opposition de phase, un circuit
  ouvert tout en phase. Une réactance pure renvoie tout, avec une phase
  quelconque.

  La fraction de puissance réfléchie est le carré de son module ; le
  reste passe dans la charge.

  Une impédance infinie rend NaN : la formule y est indéterminée, comme
  dans MATLAB. Sa limite, elle, vaut bien +1.

  Exemple :
     z2gamma(50)                     % 0 : adaptee
     z2gamma(100)                    % 1/3
     abs(z2gamma(100))^2             % 1/9 de la puissance revient

  Voir aussi GAMMA2Z, VSWR, SPARAM2ZPARAM.
```

## `z2s`

```
Z2S Paramètres Z vers paramètres S : S = (Z - z0 I)(Z + z0 I)^-1.
  S = Z2S(Z) convertit des paramètres Z, N x N ou N x N x K, en
  paramètres S pour 50 ohms ; Z2S(Z,Z0) choisit la référence.

  Exemple :
     % Pozar, l'atténuateur de 3 dB en T.
     K = 10 ^ (3 / 20);
     R1 = 50 * (K - 1) / (K + 1);  R3 = 100 * K / (K ^ 2 - 1);
     S = z2s([R1 + R3, R3; R3, R1 + R3])   % S11 = 0, S21 = 0.7079

  Voir aussi S2Z, Y2S, ABCD2S.
```

