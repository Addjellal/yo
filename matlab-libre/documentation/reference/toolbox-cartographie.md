# Toolbox `cartographie`

```
% Mapping Toolbox — géodésie et projections.
%
% Sur la sphère
%   distanceGC  - Distance orthodromique et cap initial
%   reckon      - Point atteint en suivant un cap sur une distance
%   areaint     - Aire d'un polygone, en projection équivalente
%
% Projections
%   deg2utm     - Transverse universelle de Mercator, par fuseau
```

## `areaint`

```
AREAINT Aire d'un polygone tracé sur la sphère.
  A = AREAINT(LATITUDES,LONGITUDES) rend l'aire en mètres carrés sur
  une sphère de rayon terrestre ; AREAINT(...,RAYON) impose le rayon.
  Le polygone se referme tout seul : le dernier sommet est relié au
  premier.

  Le calcul se fait dans la projection cylindrique équivalente — celle
  où l'ordonnée est le sinus de la latitude — par la formule

     A = R^2 / 2 * |somme (lon(j) - lon(k)) (sin lat(k) + sin lat(j))|

  Cette projection conserve les aires, si bien que l'aire du polygone
  projeté est celle du polygone sur la sphère — à condition que ses
  côtés soient droits dans la projection. C'est le cas des côtés à
  latitude constante et des méridiens, donc de tout rectangle en
  latitude-longitude : pour ceux-là le résultat est exact.

  Ce n'est pas le cas d'un côté qui suit un arc de grand cercle : cet
  arc se courbe dans la projection, et l'aire rendue est celle du
  polygone à côtés droits, non celle du polygone à côtés géodésiques.
  Un triangle sphérique à sommet au pôle en donne un exemple net : la
  formule rend la moitié de son aire véritable.

  Exemple :
     % Un rectangle de dix degres sur dix, a l'equateur.
     areaint([0 0 10 10], [0 10 10 0])
     % Son aire exacte : R^2 (lon2-lon1) (sin lat2 - sin lat1)
     6371000 ^ 2 * (10 * pi / 180) * sind(10)

  Voir aussi DISTANCEGC, RECKON, DEG2UTM.
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

## `reckon`

```
RECKON Point atteint en suivant un cap sur une distance donnée.
  [LAT2,LON2] = RECKON(LAT1,LON1,DISTANCE,CAP) rend le point atteint en
  suivant l'orthodromie de cap initial CAP, en degrés, sur DISTANCE
  mètres. RECKON(...,RAYON) impose le rayon.

  C'est la réciproque de DISTANCEGC : partir d'un point, suivre le cap
  et la distance qu'elle donne, et retomber sur l'autre point. C'est la
  vérification qui éprouve les deux à la fois.

  Suivre le cap initial ne veut pas dire garder ce cap : l'orthodromie
  le fait varier. Le point rendu est bien celui d'un grand cercle, non
  d'une route à cap constant.

  Exemple :
     [lat, lon] = reckon(0, 0, 111195, 0);        % un degre vers le nord
     [d, cap] = distanceGC(48.86, 2.35, 40.71, -74.01);
     reckon(48.86, 2.35, d, cap)                  % retombe sur New York

  Voir aussi DISTANCEGC, AREAINT, DEG2UTM.
```

