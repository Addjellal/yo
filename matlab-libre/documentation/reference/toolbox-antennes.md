# Toolbox `antennes`

```
% Antenna Toolbox — diagrammes, directivité, bilans.
%
% Éléments
%   dipolePattern - Diagramme d'un dipôle, de longueur quelconque
%
% Réseaux
%   arrayFactor   - Facteur d'un réseau linéaire uniforme, avec balayage
%
% Mesures sur un diagramme
%   beamwidth     - Ouverture à mi-puissance
%   directivity   - Directivité, rapportée à l'isotrope
%
% Bilan de liaison
%   friis         - Puissance reçue en espace libre
```

## `arrayFactor`

```
ARRAYFACTOR Facteur d'un réseau linéaire uniforme.
  AF = ARRAYFACTOR(N,D,THETA,PHASE) pour N éléments espacés de D
  longueurs d'onde, THETA en radians depuis l'axe du réseau, PHASE le
  déphasage progressif d'un élément au suivant.

  Le facteur de réseau vaut N quand tous les éléments s'additionnent en
  phase, et s'annule N-1 fois par période du déphasage psi = 2 pi d
  cos(theta) + phase. Entre deux zéros il y a un lobe : N-1 en tout, un
  principal et N-2 secondaires.

  Le premier lobe secondaire d'un réseau uniforme tend vers -13,26 dB du
  principal quand N croît, et ne descend jamais plus bas : c'est le prix
  d'une alimentation uniforme, et la raison pour laquelle on pondère les
  amplitudes quand on veut mieux.

  Le déphasage progressif dépointe le faisceau sans rien bouger : c'est
  tout le principe du balayage électronique. Il suffit de poser
  PHASE = -2 pi d cos(visée).

  Espacer de plus d'une demi-longueur d'onde fait apparaître des lobes
  de réseau : un second maximum aussi fort que le principal, dans une
  direction parasite. C'est la limite qui fixe le pas d'un réseau.

  Exemple :
     theta = linspace(1e-6, pi - 1e-6, 4001);
     AF = arrayFactor(8, 0.5, theta);
     max(AF)                         % 8 : les huit en phase
     AF = arrayFactor(8, 0.5, theta, -2*pi*0.5*cosd(60));   % vise a 60

  Voir aussi DIRECTIVITY, BEAMWIDTH, DIPOLEPATTERN, STEERINGVECTOR.
```

## `beamwidth`

```
BEAMWIDTH Ouverture à mi-puissance (-3 dB), en radians.
  LARGEUR = BEAMWIDTH(THETA,DIAGRAMME) rend l'écart angulaire entre les
  deux points où la puissance tombe à la moitié du maximum, de part et
  d'autre de celui-ci. DIAGRAMME est en amplitude, non en puissance.

  L'ouverture varie comme l'inverse de la longueur totale d'un réseau,
  non comme l'inverse du nombre d'éléments : doubler la longueur divise
  l'ouverture par deux. C'est la résolution angulaire, et elle ne
  s'achète qu'en étendue physique.

  La mesure se fait sur l'échantillonnage fourni : un maillage trop
  grossier la surestime.

  Exemple :
     theta = linspace(1e-6, pi - 1e-6, 20001);
     rad2deg(beamwidth(theta, dipolePattern(theta, 0.5)))   % 78

  Voir aussi DIRECTIVITY, DIPOLEPATTERN, ARRAYFACTOR.
```

## `dipolePattern`

```
DIPOLEPATTERN Diagramme de rayonnement d'un dipôle de longueur L/lambda.
  E = DIPOLEPATTERN(THETA,L) où THETA est en radians et L la longueur
  rapportée à la longueur d'onde (0.5 pour un demi-onde).

  Le diagramme est nul dans l'axe du fil et maximal
  perpendiculairement : rien ne part dans la direction où l'on regarde
  le fil par le bout, ce qui est une conséquence directe du rayonnement
  d'un élément de courant.

  Le demi-onde ouvre à 78 degrés à mi-puissance et a une directivité de
  1,64, soit 2,15 dBi : ces deux nombres du cours se retrouvent en
  passant le diagramme à BEAMWIDTH et DIRECTIVITY.

  Allonger le dipôle resserre le faisceau et augmente la directivité,
  jusqu'à une longueur d'onde environ ; au-delà, des lobes secondaires
  apparaissent et lui reprennent de la puissance. Un dipôle très court
  tend vers le doublet élémentaire, de directivité 1,5.

  Exemple :
     theta = linspace(1e-6, pi - 1e-6, 20001);
     E = dipolePattern(theta, 0.5);
     rad2deg(beamwidth(theta, E / max(E)))       % 78 degres
     directivity(theta, E / max(E))              % 1.64

  Voir aussi DIRECTIVITY, BEAMWIDTH, ARRAYFACTOR, FRIIS.
```

## `directivity`

```
DIRECTIVITY Directivité estimée à partir d'un diagramme en puissance.
  D = DIRECTIVITY(THETA,DIAGRAMME) rend le rapport entre l'intensité
  maximale et l'intensité moyenne sur toute la sphère, en supposant le
  diagramme de révolution autour de l'axe polaire.

  Une antenne ne crée pas de puissance : elle la répartit. La
  directivité mesure exactement cela — combien de fois plus de puissance
  part dans la meilleure direction que si tout était rayonné
  uniformément. Une antenne isotrope a donc une directivité de un, par
  définition, et c'est à elle que le « i » de dBi renvoie.

  Le calcul intègre en sin(theta) d theta : c'est l'élément d'angle
  solide, et l'oublier fausse tout.

  Exemple :
     theta = linspace(1e-6, pi - 1e-6, 20001);
     directivity(theta, ones(size(theta)))       % 1 : isotrope
     directivity(theta, dipolePattern(theta, 0.5))   % 1.64

  Voir aussi BEAMWIDTH, DIPOLEPATTERN, FRIIS.
```

## `friis`

```
FRIIS Puissance reçue en espace libre (formule de Friis).
  PR = FRIIS(PT,GT,GR,LAMBDA,DISTANCE) rend la puissance reçue, en
  watts. Les gains sont linéaires, non en décibels.

  La puissance décroît comme le carré de la distance. Ce n'est pas une
  perte dans le milieu — le vide n'absorbe rien — mais l'étalement de la
  puissance sur une sphère de plus en plus grande : doubler la distance
  coûte exactement six décibels.

  La liaison est réciproque : échanger émetteur et récepteur ne change
  rien. Et le gain se paie deux fois si les deux bouts en profitent.

  La formule suppose l'espace libre, la polarisation adaptée et le champ
  lointain. Rien de tout cela n'est vrai en intérieur, où l'exposant
  effectif monte à trois ou quatre — c'est ce que PATHLOSS permet de
  modéliser.

  Exemple :
     friis(1, 10, 10, 0.125, 100)
     friis(1, 10, 10, 0.125, 200) / friis(1, 10, 10, 0.125, 100)  % 0.25

  Voir aussi PATHLOSS, DIRECTIVITY, DBM2W.
```

