# Toolbox `cartographie`

```
% Mapping Toolbox — géodésie et projections.
%
% Sur la sphère et l'ellipsoïde
%   distance           - Longueur d'arc et azimut ; géodésique de Vincenty sur l'ellipsoïde
%   azimuth            - Azimut d'un point vers un autre
%   reckon             - Point atteint en suivant un azimut sur une distance
%   areaint            - Aire exacte d'un polygone à côtés de grand cercle
%   areaquad           - Aire d'un quadrangle entre parallèles et méridiens
%   referenceEllipsoid - Ellipsoïde de référence : WGS84, GRS80, Hayford, Bessel, Clarke
%   wgs84Ellipsoid     - L'ellipsoïde du GPS
%   distanceGC         - Distance orthodromique en mètres et cap initial (MatLibre)
%
% Projections
%   deg2utm            - Transverse universelle de Mercator, par fuseau
```

## `areaint`

```
AREAINT Aire d'un polygone tracé sur la sphère ou l'ellipsoïde.
  A = AREAINT(LAT,LON) rend l'aire du polygone de sommets (LAT,LON), en
  degrés, comme la fraction de la sphère qu'il couvre — la convention de
  MATLAB. Le polygone se referme tout seul ; des NaN séparent plusieurs
  polygones, et A a alors un élément par polygone. L'aire est positive
  quel que soit le sens de parcours ; c'est celle de la plus petite des
  deux régions que le contour sépare.
  AREAINT(LAT,LON,ELLIPSOIDE) la rend en unités carrées de l'ellipsoïde
  — un objet REFERENCEELLIPSOID, [a e], ou un rayon seul —, par les
  latitudes authaliques, qui portent l'ellipsoïde sur la sphère de même
  aire.
  AREAINT(...,'radians') lit les angles en radians.

  Les côtés sont des arcs de grand cercle, et l'aire est exacte : la
  somme des excès sphériques des triangles qu'ils forment avec un point
  de référence (formule de Van Oosterom et Strackee, 1983). MATLAB, lui,
  intègre par trapèzes une intégrale de Green : sa documentation rend
  0.0792 puis 0.0829 pour un fuseau de trente degrés décrit avec des
  sommets espacés de 30 puis de 10 degrés, dont l'aire exacte est 1/12,
  0.0833 — la valeur que rend AREAINT dans les deux cas.

  Exemple :
     areaint([0 0 90], [0 90 0])          % un octant : 0.125
     lat = [-90:30:90 60:-30:-60]; lon = [zeros(1,7) 30*ones(1,5)];
     areaint(lat, lon)                    % fuseau de 30 degrés : 1/12
     areaint([0 0 10 10], [0 10 10 0], 6371000)   % en mètres carrés

  Voir aussi AREAQUAD, DISTANCE, RECKON, REFERENCEELLIPSOID.
```

## `areaquad`

```
AREAQUAD Aire d'un quadrangle délimité par deux parallèles et deux méridiens.
  A = AREAQUAD(LAT1,LON1,LAT2,LON2) rend l'aire de la région comprise
  entre les latitudes LAT1 et LAT2 et les longitudes LON1 et LON2, en
  degrés, comme fraction de la sphère :
     A = |LON2 - LON1|/360 * |sin(LAT2) - sin(LAT1)|/2.
  AREAQUAD(...,ELLIPSOIDE) la rend en unités carrées de l'ellipsoïde, par
  les latitudes authaliques ; AREAQUAD(...,'radians') lit des radians.

  Exemple :
     areaquad(90, 0, -90, 30)     % 1/12 : le fuseau de trente degrés
     areaquad(0, 0, 90, 360)      % 0.5 : l'hémisphère nord

  Voir aussi AREAINT, REFERENCEELLIPSOID.
```

## `azimuth`

```
AZIMUTH Azimut d'un point vers un autre, sur la sphère ou l'ellipsoïde.
  AZ = AZIMUTH(LAT1,LON1,LAT2,LON2) rend l'azimut au départ du grand
  cercle qui va du premier point au second, en degrés, compté du nord
  vers l'est, dans [0, 360).
  AZIMUTH(PT1,PT2), AZIMUTH(...,ELLIPSOIDE), AZIMUTH(...,'radians') et
  AZIMUTH('rh',...) se lisent comme pour DISTANCE.

  Exemple :
     azimuth(0, 0, 10, 0)          % 0 : plein nord
     azimuth(0, 0, 0, 10)          % 90 : plein est

  Voir aussi DISTANCE, RECKON.
```

## `deg2utm`

```
DEG2UTM Projection transverse universelle de Mercator (WGS84).
  [X,Y,FUSEAU] = DEG2UTM(LAT,LON) projette des coordonnées géodésiques,
  en degrés, vers des mètres est et nord dans le fuseau UTM qui contient
  le point.

  L'UTM découpe le monde en soixante fuseaux de six degrés de longitude,
  chacun avec sa propre projection. C'est ce qui limite la déformation à
  moins d'un pour mille — mais deux points de fuseaux différents ne se
  comparent pas : leurs coordonnées ne sont pas dans le même repère.

  La projection est conforme : elle conserve les angles, donc les
  formes locales, au prix des aires. C'est le choix qui convient à la
  navigation et au cadastre, non à une carte de densités.

  L'ordonnée est comptée depuis l'équateur ; l'abscisse depuis le
  méridien central du fuseau, décalée de 500 km pour rester positive.

  Exemple :
     [x, y, fuseau] = deg2utm(48.8566, 2.3522);   % Paris, fuseau 31
     fuseau

  Voir aussi DISTANCEGC, RECKON, AREAINT.
```

## `distance`

```
DISTANCE Distance entre deux points de la sphère ou de l'ellipsoïde.
  [ARCLEN,AZ] = DISTANCE(LAT1,LON1,LAT2,LON2) rend la longueur de l'arc
  de grand cercle entre les points, en degrés d'arc de la sphère, et
  l'azimut au départ, en degrés depuis le nord vers l'est.
  DISTANCE(PT1,PT2) prend deux matrices de points [lat lon].
  DISTANCE(...,ELLIPSOIDE) calcule sur l'ellipsoïde — un objet
  REFERENCEELLIPSOID, comme wgs84Ellipsoid, ou le vecteur [a e] — : la
  longueur de la géodésique est alors dans l'unité du demi-grand axe.
  DISTANCE(...,'radians') lit et rend les angles en radians.
  DISTANCE('rh',...) suit la loxodromie, à cap constant, au lieu du grand
  cercle — sur la sphère seulement.

  Sur l'ellipsoïde, la géodésique est calculée par la méthode inverse de
  Vincenty (1975), au dixième de millimètre ; pour deux points presque
  antipodaux, où elle ne converge pas, DISTANCE le dit par une erreur.

  Exemple :
     d = distance(0, 0, 0, 90)                       % 90 degrés d'arc
     % Vincenty (1975) et Geoscience Australia : de Flinders Peak à
     % Buninyong, sur l'ellipsoïde GRS80, 54972.271 m.
     s = distance(-(37 + 57/60 + 3.72030/3600), 144 + 25/60 + 29.52440/3600, ...
                  -(37 + 39/60 + 10.15610/3600), 143 + 55/60 + 35.38390/3600, ...
                  referenceEllipsoid('grs80'))

  Voir aussi AZIMUTH, RECKON, REFERENCEELLIPSOID, DISTANCEGC.
```

## `distanceGC`

```
DISTANCEGC Distance orthodromique et cap initial.
  [D,CAP] = DISTANCEGC(LAT1,LON1,LAT2,LON2) rend la distance en mètres
  le long du grand cercle, et le cap initial en degrés depuis le nord.
  DISTANCEGC(...,RAYON) impose le rayon.

  L'orthodromie est le plus court chemin sur la sphère : c'est
  l'intersection de celle-ci avec le plan qui passe par les deux points
  et le centre. Elle paraît courbe sur une carte de Mercator, ce qui
  n'est pas une illusion mais une propriété de la projection.

  Le cap rendu est le cap *initial* : il change tout au long du trajet,
  sauf le long d'un méridien ou de l'équateur. Le suivre constamment
  donnerait la loxodromie, plus longue.

  Exemple :
     [d, cap] = distanceGC(48.86, 2.35, 40.71, -74.01);   % Paris-New York
     d / 1000                        % environ 5837 km
     cap                             % pres de 292 degres, non 270

  Voir aussi RECKON, AREAINT, DEG2UTM, HAVERSINE.
```

## `matlibre_geodesie_arguments`

_Pas de bloc d'aide._

## `matlibre_geodesique_directe`

```
MATLIBRE_GEODESIQUE_DIRECTE Point atteint en suivant une géodésique.
  [PHI2,LAM2,AZ2] = MATLIBRE_GEODESIQUE_DIRECTE(PHI1,LAM1,S,AZ1,A,E),
  angles en radians, rend le point atteint depuis (PHI1,LAM1) en partant
  à l'azimut AZ1 sur la longueur S (unité de A), et l'azimut d'arrivée.
  Sur la sphère, les formules du grand cercle ; sur l'ellipsoïde, la
  méthode directe de Vincenty (1975), qui converge toujours.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [p, l] = matlibre_geodesique_directe(0, 0, pi/2, 0, 1, 0)   % le pôle

  Voir aussi RECKON, MATLIBRE_GEODESIQUE_INVERSE.
```

## `matlibre_geodesique_inverse`

```
MATLIBRE_GEODESIQUE_INVERSE Distance et azimuts entre deux points.
  [S,AZ1,AZ2] = MATLIBRE_GEODESIQUE_INVERSE(PHI1,LAM1,PHI2,LAM2,A,E),
  angles en radians, rend la longueur S de la géodésique (dans l'unité
  de A) et les azimuts au départ et à l'arrivée.

  Sur la sphère (E = 0), la formule des haversines. Sur l'ellipsoïde, la
  méthode de Vincenty (1975, « Direct and inverse solutions of geodesics
  on the ellipsoid with application of nested equations », Survey Review
  23(176)), précise au dixième de millimètre. Elle ne converge pas pour
  des points presque antipodaux : la fonction le dit au lieu de rendre
  un nombre faux.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     s = matlibre_geodesique_inverse(0, 0, 0, pi/2, 1, 0)   % pi/2

  Voir aussi DISTANCE, AZIMUTH, MATLIBRE_GEODESIQUE_DIRECTE.
```

## `matlibre_latitude_authalique`

```
MATLIBRE_LATITUDE_AUTHALIQUE Latitude de la sphère de même aire que l'ellipsoïde.
  BETA = MATLIBRE_LATITUDE_AUTHALIQUE(PHI,E), en radians : sin(beta) =
  q(phi)/q(pi/2), avec q(phi) = (1-e^2) [sin(phi)/(1-e^2 sin^2(phi))
  - 1/(2e) ln((1-e sin(phi))/(1+e sin(phi)))] (Snyder, Map Projections —
  A Working Manual, 1987, équation 3-11). La zone entre deux parallèles
  de l'ellipsoïde a la même aire que celle des parallèles authaliques sur
  la sphère de même surface.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_latitude_authalique(pi/2, 0.0818)   % pi/2

  Voir aussi AREAINT, AREAQUAD.
```

## `matlibre_loxodromie`

```
MATLIBRE_LOXODROMIE Longueur et cap de la loxodromie entre deux points.
  [S,AZ] = MATLIBRE_LOXODROMIE(PHI1,LAM1,PHI2,LAM2,A,E), en radians : la
  route à cap constant, droite sur la carte de Mercator. Sur la sphère
  seulement ; un ellipsoïde est refusé.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [s, az] = matlibre_loxodromie(0, 0, 0, pi/2, 1, 0)   % pi/2, pi/2

  Voir aussi DISTANCE, RECKON.
```

## `matlibre_unite_longueur`

```
MATLIBRE_UNITE_LONGUEUR Le nombre de mètres d'une unité de longueur.
  F = MATLIBRE_UNITE_LONGUEUR(UNITE) rend la longueur de UNITE en mètres ;
  NOM = MATLIBRE_UNITE_LONGUEUR(UNITE,'nom') son nom canonique.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_unite_longueur('km')            % 1000

  Voir aussi REFERENCEELLIPSOID.
```

## `reckon`

```
RECKON Point atteint en suivant un azimut sur une distance donnée.
  [LAT2,LON2] = RECKON(LAT,LON,ARCLEN,AZ) rend le point atteint depuis
  (LAT,LON) en partant à l'azimut AZ sur le grand cercle, après un arc
  ARCLEN — en degrés d'arc de la sphère, comme dans MATLAB.
  RECKON(LAT,LON,ARCLEN,AZ,ELLIPSOIDE) suit la géodésique de
  l'ellipsoïde — un objet REFERENCEELLIPSOID ou le vecteur [a e] — et
  ARCLEN est alors une longueur, dans l'unité du demi-grand axe. Un
  rayon seul, ou [R 0], fait une sphère de rayon R : RECKON(LAT,LON,D,AZ,
  6371000) avance de D mètres.
  RECKON(...,'radians') lit et rend les angles en radians ;
  RECKON('rh',...) suit la loxodromie, à cap constant.

  C'est la réciproque de DISTANCE : partir d'un point, suivre l'azimut et
  la longueur qu'elle donne, et retomber sur l'autre point. Sur
  l'ellipsoïde, la méthode directe de Vincenty (1975).

  Suivre l'azimut initial ne veut pas dire garder ce cap : le grand cercle
  le fait varier. Le point rendu est bien celui d'un grand cercle, non
  d'une route à cap constant — sauf avec 'rh'.

  Exemple :
     [lat, lon] = reckon(0, 0, 90, 0)              % le pôle Nord
     [lat, lon] = reckon(0, 0, 111195, 0, 6371000) % un degré vers le nord
     [s, az] = distance(48.86, 2.35, 40.71, -74.01, wgs84Ellipsoid);
     [lat, lon] = reckon(48.86, 2.35, s, az, wgs84Ellipsoid) % New York

  Voir aussi DISTANCE, AZIMUTH, AREAINT.
```

## `referenceEllipsoid`

```
REFERENCEELLIPSOID Ellipsoïde de référence d'un système géodésique.
  E = REFERENCEELLIPSOID(NOM) rend l'ellipsoïde NOM, en mètres :
     'wgs84'          a = 6378137 m, 1/f = 298,257223563 (GPS)
     'grs80'          a = 6378137 m, 1/f = 298,257222101 (ETRS89, RGF93)
     'international'  a = 6378388 m, 1/f = 297 (Hayford 1910)
     'bessel'         a = 6377397,155 m, 1/f = 299,1528128 (Bessel 1841)
     'clarke66'       a = 6378206,4 m, b = 6356583,8 m (Clarke 1866)
     'sphere'         la sphère de même aire que WGS84 n'est pas fournie :
                      un rayon scalaire, ou [R 0], fait une sphère
  E = REFERENCEELLIPSOID(NOM,UNITE) l'exprime en 'meter', 'kilometer'
  (ou 'km'), 'foot' ou 'mile'.
  E = REFERENCEELLIPSOID(VECTEUR) prend [a e], le demi-grand axe et
  l'excentricité.

  Les propriétés : Code, Name, LengthUnit, SemimajorAxis, SemiminorAxis,
  InverseFlattening, Eccentricity, Flattening, ThirdFlattening,
  MeanRadius, SurfaceArea, Volume.

  DISTANCE, AZIMUTH, RECKON, AREAINT et AREAQUAD prennent un tel objet —
  ou le vecteur [a e] — pour calculer sur l'ellipsoïde plutôt que sur la
  sphère unité.

  Exemple :
     e = referenceEllipsoid('wgs84');
     e.SemiminorAxis          % 6356752.314245...
     e.Eccentricity           % 0.0818191908...

  Voir aussi WGS84ELLIPSOID, DISTANCE, RECKON, AREAINT.
```

## `wgs84Ellipsoid`

```
WGS84ELLIPSOID L'ellipsoïde du World Geodetic System 1984.
  E = WGS84ELLIPSOID rend l'ellipsoïde WGS84 en mètres ;
  WGS84ELLIPSOID(UNITE) dans une autre unité : 'kilometer', 'km'...
  C'est l'ellipsoïde du GPS : a = 6378137 m, 1/f = 298,257223563.

  Exemple :
     e = wgs84Ellipsoid('km');
     e.SemimajorAxis          % 6378.137

  Voir aussi REFERENCEELLIPSOID, DISTANCE.
```

