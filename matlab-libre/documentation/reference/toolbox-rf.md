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

