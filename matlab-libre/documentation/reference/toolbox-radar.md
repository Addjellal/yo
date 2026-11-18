# Toolbox `radar`

```
% Radar Toolbox — équation du radar et traitement d'impulsions.
%
% Bilan de portée (signatures de MATLAB)
%   radareqrng      - Portée maximale, par l'équation du radar
%   radareqpow      - Puissance crête nécessaire pour une portée donnée
%   radareqsnr      - Rapport signal sur bruit d'une cible
%   physconst       - Vitesse de la lumière, constante de Boltzmann, rayon terrestre
%
% Distances et vitesses
%   time2range      - Retard d'écho vers distance
%   range2time      - Distance vers retard d'écho
%   bw2rangeres     - Résolution en distance d'une bande passante
%   rangeres2bw     - Bande passante d'une résolution en distance
%   speed2dop       - Décalage Doppler d'un aller simple
%   dop2speed       - Vitesse radiale d'un décalage Doppler
%   dopplerShift    - Décalage Doppler d'un écho, aller et retour (MatLibre)
%
% Traitement d'impulsions
%   matchedFilter   - Filtre adapté à l'impulsion émise
%   pulseCompression - Compression d'impulsion, avec l'axe des retards
```

## `bw2rangeres`

```
BW2RANGERES Résolution en distance d'une bande passante : c/(2B).
  DR = BW2RANGERES(B) rend la résolution en distance (m) d'un signal de
  bande B (Hz) ; BW2RANGERES(B,C) prend la célérité C (par défaut celle
  de la lumière). Deux cibles plus proches que DR se confondent après
  compression d'impulsion.

  Exemple :
     bw2rangeres(10e6)          % 14.99 m pour 10 MHz

  Voir aussi RANGERES2BW, PULSECOMPRESSION.
```

## `dop2speed`

```
DOP2SPEED Vitesse radiale à partir d'un décalage Doppler d'aller simple.
  V = DOP2SPEED(DOP,LAMBDA) rend DOP*LAMBDA (m/s), comme MATLAB. Pour un
  écho radar, diviser d'abord le décalage mesuré par deux.

  Exemple :
     dop2speed(1000, physconst('LightSpeed') / 10e9)   % 29.98 m/s

  Voir aussi SPEED2DOP, DOPPLERSHIFT.
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

## `matlibre_radar_options`

```
MATLIBRE_RADAR_OPTIONS Les options nom-valeur de l'équation du radar.
  O = MATLIBRE_RADAR_OPTIONS(ARGS,NOM,PERMIS) lit RCS (m^2, 1), Ts (K,
  290), Gain (dB, 20 ; scalaire, ou [Gt Gr]), Loss (dB, 0),
  CustomFactor (dB, 0), AtmosphericLoss et PropagationFactor (dB, 0) et
  unitstr ('m', 'km', 'mi', 'nmi') parmi les noms PERMIS.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     o = matlibre_radar_options({'Gain', 30}, 'radareqpow', {'Gain'});
     o.Gain                     % [30 30]

  Voir aussi RADAREQPOW, RADAREQRNG, RADAREQSNR.
```

## `matlibre_radar_portees`

```
MATLIBRE_RADAR_PORTEES Portées d'émission et de réception d'un radar.
  Une portée (monostatique), [Rt Rr] (bistatique), une colonne de J
  portées ou une matrice J x 2.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [Rt, Rr] = matlibre_radar_portees([50e3 75e3], 'radareqpow')

  Voir aussi RADAREQPOW, RADAREQSNR.
```

## `physconst`

```
PHYSCONST Constantes physiques des toolboxes de radar et d'antennes.
  C = PHYSCONST(NOM) rend la constante NOM, comme MATLAB :
     'LightSpeed'   vitesse de la lumière dans le vide, 299 792 458 m/s
     'Boltzmann'    constante de Boltzmann, 1,380649e-23 J/K (CODATA, SI 2019)
     'EarthRadius'  rayon moyen de la Terre, 6 371 000 m

  Exemple :
     lambda = physconst('LightSpeed') / 1e9     % 0.2998 m à 1 GHz
     10 * log10(physconst('Boltzmann') * 290)   % -203.98 dBW/Hz

  Voir aussi RADAREQPOW, RADAREQRNG, RADAREQSNR, RANGE2TIME.
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
RADAREQPOW Puissance crête nécessaire, par l'équation du radar.
  PT = RADAREQPOW(LAMBDA,TGTRNG,SNR,TAU) rend la puissance crête (W) qui
  donne le rapport signal sur bruit SNR (dB) sur une cible à la portée
  TGTRNG (m), pour une longueur d'onde LAMBDA (m) et une durée
  d'impulsion TAU (s) — la signature de MATLAB :

     Pt = SNR (4 pi)^3 k Ts Rt^2 Rr^2 L / (tau Gt Gr lambda^2 sigma)

  TGTRNG est une portée, ou [Rt Rr] pour un radar bistatique.
  Options : 'RCS' (m^2, 1), 'Ts' (K, 290), 'Gain' (dB, 20, ou [Gt Gr]),
  'Loss' (dB, 0), 'CustomFactor' (dB, 0).

  Exemple :
     % Documentation de MATLAB.
     lambda = physconst('LightSpeed') / 1e9;
     radareqpow(lambda, 50e3, 6, 1e-6)              % 2.1996e+05 W

  Voir aussi RADAREQRNG, RADAREQSNR, PHYSCONST.
```

## `radareqrng`

```
RADAREQRNG Portée maximale théorique, par l'équation du radar.
  R = RADAREQRNG(LAMBDA,SNR,PT,TAU) rend la portée (m) à laquelle une
  cible donne le rapport signal sur bruit SNR (dB), pour une longueur
  d'onde LAMBDA (m), une puissance crête PT (W) et une durée d'impulsion
  TAU (s) — la signature de MATLAB :

     R = (Pt tau Gt Gr lambda^2 sigma / ((4 pi)^3 k Ts L SNR))^(1/4)

  Options : 'RCS' (m^2, 1), 'Ts' (K, 290), 'Gain' (dB, 20, ou [Gt Gr]),
  'Loss' (dB, 0), 'CustomFactor' (dB, 0), 'unitstr' ('m', 'km', 'mi',
  'nmi') pour l'unité de la portée rendue.

  La portée varie comme la racine quatrième de la puissance : doubler la
  portée demande seize fois plus de puissance.

  Exemple :
     % Documentation de MATLAB.
     lambda = physconst('LightSpeed') / 10e9;
     radareqrng(lambda, 6, 1e6, 10e-6)              % 4.1057e+04 m

  Voir aussi RADAREQPOW, RADAREQSNR, PHYSCONST.
```

## `radareqsnr`

```
RADAREQSNR Rapport signal sur bruit par l'équation du radar, en dB.
  SNR = RADAREQSNR(LAMBDA,TGTRNG,PT,TAU) rend le rapport signal sur bruit
  (dB) d'une cible à la portée TGTRNG (m), pour une longueur d'onde LAMBDA
  (m), une puissance crête PT (W) et une durée d'impulsion TAU (s) :

     SNR = Pt tau Gt Gr lambda^2 sigma / ((4 pi)^3 k Ts Rt^2 Rr^2 L)

  TGTRNG est une portée (radar monostatique) ou [Rt Rr], les portées de
  l'émetteur et du récepteur (bistatique), ou une colonne / une matrice
  J x 2 de telles portées.
  Options : 'RCS' (m^2, 1), 'Ts' (K, 290), 'Gain' (dB, 20, ou [Gt Gr]),
  'Loss' (dB, 0), 'AtmosphericLoss' et 'PropagationFactor' (dB, 0, un
  par trajet ou [aller retour]), 'CustomFactor' (dB, 0).

  Exemple :
     % Documentation de MATLAB.
     lambda = physconst('LightSpeed') / 1e9;
     radareqsnr(lambda, 50e3, 1e6, 0.2e-6)        % 5.5868 dB

  Voir aussi RADAREQPOW, RADAREQRNG, PHYSCONST.
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

## `rangeres2bw`

```
RANGERES2BW Bande passante nécessaire à une résolution en distance : c/(2 dR).
  B = RANGERES2BW(DR) rend la bande (Hz) qui donne la résolution DR (m) ;
  RANGERES2BW(DR,C) prend la célérité C.

  Exemple :
     rangeres2bw(1)             % 149.9 MHz pour un mètre

  Voir aussi BW2RANGERES.
```

## `speed2dop`

```
SPEED2DOP Décalage Doppler d'un aller simple, à partir de la vitesse radiale.
  DOP = SPEED2DOP(V,LAMBDA) rend V/LAMBDA (Hz) pour une vitesse radiale V
  (m/s, positive en rapprochement) et une longueur d'onde LAMBDA (m),
  comme MATLAB. Pour un radar, l'onde fait l'aller et le retour : le
  décalage vaut le double, 2*V/LAMBDA (c'est ce que rend DOPPLERSHIFT).

  Exemple :
     speed2dop(30, physconst('LightSpeed') / 10e9)     % 1000.7 Hz

  Voir aussi DOP2SPEED, DOPPLERSHIFT, PHYSCONST.
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

