# Toolbox `aerospatial`

```
% Aerospace Toolbox — atmosphère, repères et grandeurs de vol.
%
% Atmosphère
%   atmosisa      - Atmosphère type internationale, jusqu'à 20 km
%   dpressure     - Pression dynamique, qui fixe les efforts
%   machnumber    - Nombre de Mach, qui fixe l'aérodynamique
%
% Attitude
%   angle2dcm     - Angles d'Euler vers matrice de cosinus directeurs
%   dcm2angle     - Réciproque
%
% Position
%   geodetic2ecef - Latitude, longitude, altitude vers repère terrestre
```

## `angle2dcm`

```
ANGLE2DCM Angles d'Euler (radians) vers matrice de cosinus directeurs.
  DCM = ANGLE2DCM(R1,R2,R3) rend la matrice qui passe du repère de
  référence au repère du mobile, dans l'ordre ZYX — lacet, tangage,
  roulis. ANGLE2DCM(R1,R2,R3,ORDRE) emploie une autre séquence.

  Attention au sens : la matrice de cosinus directeurs de
  l'aéronautique va du repère fixe vers le repère mobile, alors que
  EUL2ROTM rend la rotation inverse, du mobile vers le fixe. Les deux
  sont transposées l'une de l'autre, et les confondre inverse tous les
  signes.

  Exemple :
     dcm = angle2dcm(deg2rad(30), 0, 0);
     [r1, r2, r3] = dcm2angle(dcm);
     rad2deg(r1)                         % 30

  Voir aussi DCM2ANGLE, EUL2ROTM, ROTM2EUL.
```

## `atmosisa`

```
ATMOSISA Atmosphère type internationale (troposphère et stratosphère).
  [T,A,P,RHO] = ATMOSISA(H) rend la température (K), la vitesse du son
  (m/s), la pression (Pa) et la masse volumique (kg/m^3) à l'altitude H,
  en mètres.

  L'atmosphère type est une convention, non une mesure : elle fixe au
  niveau de la mer 288,15 K et 101325 Pa, puis une décroissance de
  6,5 K par kilomètre jusqu'à 11 km — la tropopause —, et une
  température constante au-dessus. C'est ce modèle qui sert à étalonner
  les altimètres et à comparer des performances d'avions.

  La vitesse du son ne dépend que de la température : elle tombe à
  295 m/s à la tropopause, contre 340 au sol, et n'y bouge plus. C'est
  pourquoi un avion de ligne y vole à Mach constant.

  Le modèle s'arrête à 20 km ; au-delà, la valeur rendue est celle de la
  tropopause prolongée.

  Exemple :
     [T, a, P, rho] = atmosisa(0);       % 288.15 K, 340 m/s
     [T, a] = atmosisa(11000);           % 216.65 K, 295 m/s
     atmosisa(11000) - atmosisa(15000)   % 0 : isotherme au-dessus

  Voir aussi MACHNUMBER, DPRESSURE.
```

## `dcm2angle`

```
DCM2ANGLE Matrice de cosinus directeurs vers angles d'Euler ZYX.
  [R1,R2,R3] = DCM2ANGLE(DCM) rend le lacet, le tangage et le roulis, en
  radians. C'est la réciproque d'ANGLE2DCM.

  Au tangage de plus ou moins quatre-vingt-dix degrés, lacet et roulis
  ne sont plus séparément déterminés : c'est le blocage de cardan, une
  propriété des angles d'Euler et non un défaut de la conversion. Les
  quaternions n'ont pas ce défaut, ce qui explique leur emploi en
  navigation inertielle.

  Exemple :
     [r1, r2, r3] = dcm2angle(angle2dcm(0.3, 0.2, 0.1));
     [r1 r2 r3]                          % [0.3 0.2 0.1]

  Voir aussi ANGLE2DCM, ROTM2EUL, ROTM2QUAT.
```

## `dpressure`

```
DPRESSURE Pression dynamique 0.5 rho V^2.
  Q = DPRESSURE(RHO,VITESSE) rend la pression dynamique, en pascals.

  C'est elle, et non la vitesse, qui fixe les efforts aérodynamiques :
  portance et traînée valent q S C, où S est une surface de référence et
  C un coefficient sans dimension. Deux vols à même pression dynamique
  chargent la structure de la même façon, quelle que soit l'altitude.

  Elle croît comme le carré de la vitesse et décroît avec la masse
  volumique : c'est pourquoi un avion vole plus vite en altitude pour
  la même charge structurale.

  Exemple :
     [~, ~, ~, rho] = atmosisa(0);
     dpressure(rho, 100)                 % environ 6100 Pa
     [~, ~, ~, rho11] = atmosisa(11000);
     dpressure(rho11, 250)               % a 250 m/s en altitude

  Voir aussi ATMOSISA, MACHNUMBER.
```

## `geodetic2ecef`

```
GEODETIC2ECEF Coordonnées géodésiques (degrés) vers repère terrestre WGS84.
  [X,Y,Z] = GEODETIC2ECEF(LAT,LON,ALT) convertit latitude et longitude,
  en degrés, et altitude au-dessus de l'ellipsoïde, en mètres, vers le
  repère cartésien lié à la Terre : origine au centre, X vers le méridien
  de Greenwich à l'équateur, Z vers le pôle nord.

  C'est le repère dans lequel travaille un récepteur GPS : les positions
  des satellites y sont données, et c'est là que se résout la
  trilatération. Les coordonnées géodésiques n'en sont qu'une lecture
  commode.

  L'ellipsoïde WGS84 est aplati d'environ un trois-centième : la
  distance du centre au pôle est plus courte de 21 km que celle à
  l'équateur. Traiter la Terre comme une sphère fausse donc les
  altitudes de plusieurs kilomètres selon la latitude.

  Exemple :
     [x, y, z] = geodetic2ecef(0, 0, 0);      % x = 6378137, le rayon
     [x, y, z] = geodetic2ecef(90, 0, 0);     % z = 6356752, plus court
     norm([x y z])

  Voir aussi ATMOSISA, DEG2UTM.
```

## `machnumber`

```
MACHNUMBER Nombre de Mach.
  M = MACHNUMBER(VITESSE,VITESSESON) rend le rapport des deux.

  Le nombre de Mach, non la vitesse, est ce qui gouverne l'aérodynamique
  au-delà d'environ 0,3 : c'est lui qui décide de la compressibilité de
  l'air, de l'apparition des ondes de choc et de la traînée d'onde.

  La vitesse du son décroissant avec l'altitude, une vitesse constante
  donne un Mach croissant : un avion qui monte à vitesse indiquée
  constante s'approche du transsonique sans accélérer.

  Exemple :
     [~, a] = atmosisa(11000);
     machnumber(250, a)                  % environ 0,85
     machnumber(250, 340)                % le meme avion au sol

  Voir aussi ATMOSISA, DPRESSURE.
```

