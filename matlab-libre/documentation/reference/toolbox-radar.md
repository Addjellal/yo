# Toolbox `radar`

```
% Radar Toolbox — équation du radar et traitement d'impulsions.
%
% Bilan de portée
%   radareqrng      - Portée maximale, par l'équation du radar
%   radareqpow      - Puissance nécessaire pour une portée donnée
%
% Distances et vitesses
%   time2range      - Retard d'écho vers distance
%   range2time      - Distance vers retard d'écho
%   dopplerShift    - Décalage Doppler d'une cible radiale
%
% Traitement d'impulsions
%   matchedFilter   - Filtre adapté à l'impulsion émise
%   pulseCompression - Compression d'impulsion, avec l'axe des retards
```

## `dopplerShift`

```
DOPPLERSHIFT Décalage Doppler d'une cible en rapprochement.
  FD = DOPPLERSHIFT(VITESSE,FREQUENCE) rend 2 V F / c, le décalage en
  hertz de l'écho d'une cible qui se rapproche à VITESSE mètres par
  seconde. DOPPLERSHIFT(V,F,C) impose une autre célérité.

  Le facteur deux vient, là encore, de l'aller-retour : la cible reçoit
  déjà une fréquence décalée, et la renvoie décalée une seconde fois.

  Une vitesse négative — la cible s'éloigne — donne un décalage négatif.
  C'est ce signe qui permet de distinguer approche et éloignement, ce
  qu'aucune mesure de distance seule ne donne.

  Seule la composante radiale compte : une cible qui passe
  perpendiculairement, si vite soit-elle, ne produit aucun décalage.
  C'est la limite qui explique les angles morts d'un radar de trafic.

  Exemple :
     dopplerShift(30, 24e9)          % environ 4,8 kHz a 30 m/s
     dopplerShift(-30, 24e9)         % le meme, negatif : elle s'eloigne

  Voir aussi MATCHEDFILTER, PULSECOMPRESSION, RADAREQRNG.
```

## `matchedFilter`

```
MATCHEDFILTER Filtre adapté : corrélation avec la réplique retournée.
  Y = MATCHEDFILTER(SIGNAL,REFERENCE) corrèle le signal reçu avec une
  réplique de l'impulsion émise, en convoluant par sa version retournée
  et conjuguée.

  C'est le filtre qui maximise le rapport signal à bruit à l'instant de
  la cible — on démontre qu'aucun autre ne fait mieux face à un bruit
  blanc. Le gain vaut le produit temps-bande de l'impulsion : c'est ce
  qui permet de détecter un écho enfoui sous le bruit.

  Le maximum de la sortie tombe à la fin de l'impulsion reçue, non à son
  début : PULSECOMPRESSION en tient compte pour rendre le retard.

  Exemple :
     impulsion = exp(1i * pi * (0:63).^2 / 64);   % chirp
     recu = [zeros(1, 100), impulsion, zeros(1, 100)];
     [~, position] = max(abs(matchedFilter(recu, impulsion)));

  Voir aussi PULSECOMPRESSION, XCORR, CONV.
```

## `pulseCompression`

```
PULSECOMPRESSION Compression d'impulsion et position du maximum.
  [Y,RETARDS] = PULSECOMPRESSION(RECU,IMPULSION) applique le filtre
  adapté et rend, en plus, l'axe des retards en échantillons — décalé
  pour que le maximum tombe sur le début de l'écho, non sur sa fin.

  La compression d'impulsion résout un dilemme : une impulsion longue
  porte de l'énergie, une impulsion brève sépare deux cibles proches.
  Une impulsion longue modulée — un chirp — donne les deux à la fois,
  parce que le filtre adapté la comprime à la durée qu'impose sa bande.

  La résolution en distance ne dépend donc que de la bande occupée, non
  de la durée de l'impulsion.

  Exemple :
     impulsion = exp(1i * pi * (0:63).^2 / 64);
     recu = [zeros(1, 200), impulsion, zeros(1, 50)];
     [y, retards] = pulseCompression(recu, impulsion);
     [~, k] = max(abs(y));
     retards(k)                      % 200 : la ou l'echo commence

  Voir aussi MATCHEDFILTER, TIME2RANGE.
```

## `radareqpow`

```
RADAREQPOW Puissance d'émission nécessaire pour une portée donnée.
  PT = RADAREQPOW(LAMBDA,R,G,SIGMA,PMIN) résout l'équation du radar en
  puissance :

     Pt = Pmin (4 pi)^3 R^4 / (G^2 lambda^2 sigma)

  C'est l'exacte réciproque de RADAREQRNG : ce que l'une rend en portée,
  l'autre le rend en puissance, et les deux se recomposent.

  La puissance croît comme la puissance quatrième de la portée : c'est
  ce qui rend les radars longue portée si gourmands, et c'est aussi ce
  qui rend une cible furtive — un SIGMA divisé par cent — si difficile,
  puisqu'il faut alors cent fois plus de puissance à portée égale.

  Exemple :
     Pt = radareqpow(0.03, 50e3, 1e4, 1, 1e-12);
     radareqrng(0.03, Pt, 1e4, 1, 1e-12)     % 50000, la portee voulue

  Voir aussi RADAREQRNG, DOPPLERSHIFT.
```

## `radareqrng`

```
RADAREQRNG Portée maximale d'un radar, en mètres.
  R = RADAREQRNG(LAMBDA,PT,G,SIGMA,PMIN) applique l'équation du radar :

     R = ((Pt G^2 lambda^2 sigma) / ((4 pi)^3 Pmin))^(1/4)

     LAMBDA  la longueur d'onde, en mètres
     PT      la puissance émise, en watts
     G       le gain de l'antenne, linéaire
     SIGMA   la surface équivalente radar de la cible, en mètres carrés
     PMIN    la plus petite puissance détectable, en watts

  La racine quatrième est ce qu'il faut retenir : l'onde s'étale à
  l'aller et au retour, si bien que doubler la portée demande seize fois
  plus de puissance. C'est pourquoi on gagne davantage sur l'antenne —
  dont le gain intervient au carré — que sur l'émetteur.

  Exemple :
     radareqrng(0.03, 1e3, 1e4, 1, 1e-12)
     radareqrng(0.03, 16e3, 1e4, 1, 1e-12)   % seize fois la puissance,
                                             % deux fois la portee

  Voir aussi RADAREQPOW, TIME2RANGE, RANGE2TIME.
```

## `range2time`

```
RANGE2TIME Temps d'aller-retour pour une distance donnée.
  T = RANGE2TIME(R) rend 2 R / c ; RANGE2TIME(R,C) impose une autre
  célérité.

  C'est ce temps qui fixe la cadence de répétition d'un radar : deux
  impulsions ne doivent pas se chevaucher, sans quoi on ne sait plus
  laquelle a produit l'écho. La portée non ambiguë est donc la distance
  correspondant à la période de répétition.

  Exemple :
     range2time(30e3)                % 200 microsecondes
     1 / range2time(150e3)           % cadence maximale non ambigue

  Voir aussi TIME2RANGE, RADAREQRNG.
```

## `time2range`

```
TIME2RANGE Distance correspondant à un temps d'aller-retour.
  R = TIME2RANGE(T) rend c T / 2, la distance d'une cible dont l'écho
  revient après T secondes. TIME2RANGE(T,C) impose une autre célérité —
  celle du son dans l'eau, par exemple, pour un sonar.

  Le facteur deux est le trajet aller-retour : c'est l'erreur la plus
  commune du domaine, et elle double toutes les distances.

  Une microseconde vaut environ cent cinquante mètres : c'est le repère
  qu'on garde en tête pour lire un écran radar.

  Exemple :
     time2range(1e-6)                % environ 150 m
     time2range(range2time(30e3))    % 30000

  Voir aussi RANGE2TIME, RADAREQRNG.
```

