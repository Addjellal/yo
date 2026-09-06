# Toolbox `robotique`

```
% Robotics System Toolbox — cinématique, transformations, trajectoires.
%
% Rotations élémentaires
%   rotx, roty, rotz    - Rotation autour d'un axe, en degrés
%   angdiff             - Différence d'angles repliée dans [-pi, pi]
%
% Angles d'Euler (douze séquences : ZYX par défaut)
%   eul2rotm, rotm2eul  - Angles d'Euler et matrice de rotation
%   eul2quat, quat2eul  - Angles d'Euler et quaternion
%   eul2tform, tform2eul - Angles d'Euler et matrice homogène
%
% Quaternions
%   quat2rotm, rotm2quat - Quaternion et matrice de rotation
%   quat2axang, axang2quat - Quaternion et axe-angle
%   quat2tform, tform2quat - Quaternion et matrice homogène
%   quatmultiply, quatdivide - Composition
%   quatconj, quatinv, quatnormalize - Conjugué, inverse, normalisation
%   quatrotate          - Rotation d'un vecteur
%
% Axe et angle
%   axang2rotm, rotm2axang - Axe-angle et matrice de rotation
%   axang2tform, tform2axang - Axe-angle et matrice homogène
%
% Transformations homogènes
%   trvec2tform, tform2trvec - Translation et matrice homogène
%   rotm2tform, tform2rotm - Rotation et matrice homogène
%   dhTransform         - Matrice de Denavit-Hartenberg
%
% Bras plan à deux segments
%   fkine2R             - Cinématique directe
%   ikine2R             - Cinématique inverse (coude haut ou bas)
%   jacobian2R          - Jacobienne
%
% Trajectoires
%   cubicpolytraj       - Polynôme cubique par morceaux
%   quinticpolytraj     - Polynôme de degré cinq
%   bsplinepolytraj     - Courbe B-spline
%   trapveltraj         - Profil de vitesse trapézoïdal
%   rottraj             - Interpolation sphérique entre orientations
%   transformtraj       - Interpolation entre transformations homogènes
%
% Arbres de corps rigides
%   rigidBodyTree       - L'arbre : corps, liaisons, pesanteur
%   rigidBody           - Un corps : masse, centre de masse, inertie
%   rigidBodyJoint      - Une liaison : type, axe, butées
%   setFixedTransform   - Transformations fixes, par Denavit-Hartenberg
%   addBody, removeBody, replaceBody - Construire l'arbre
%   showdetails         - Afficher sa structure
%   homeConfiguration, randomConfiguration - Configurations
%   importrobot         - Lire un fichier URDF
%   loadrobot           - Charger un modèle du catalogue
%
% Cinématique et dynamique de l'arbre
%   getTransform        - Pose d'un corps dans le repère d'un autre
%   geometricJacobian   - Jacobienne géométrique
%   centerOfMass        - Centre de masse de l'ensemble
%   massMatrix          - Matrice d'inertie articulaire
%   velocityProduct     - Couples de Coriolis et centrifuges
%   gravityTorque       - Couples de pesanteur
%   inverseDynamics     - Couples d'un mouvement donné
%   forwardDynamics     - Accélérations sous des couples donnés
%   externalForce       - Matrice des efforts extérieurs
%
% Cinématique inverse
%   inverseKinematics   - Atteindre une pose
%   generalizedInverseKinematics - Satisfaire plusieurs contraintes
%   constraintPoseTarget, constraintPositionTarget
%   constraintOrientationTarget, constraintCartesianBounds
%   constraintJointBounds, constraintAiming, constraintDistanceBounds
%
% Mobiles à roues
%   unicycleKinematics  - L'unicycle
%   differentialDriveKinematics - Deux roues motrices
%   bicycleKinematics   - Direction avant
%   ackermannKinematics - Le braquage devenant un état
%   controllerPurePursuit - Suivi de chemin
%   controllerVFH       - Évitement d'obstacles
%
% Cartes d'occupation
%   binaryOccupancyMap  - Occupation binaire
%   occupancyMap        - Occupation probabiliste
```

## `ackermannKinematics`

```
ACKERMANNKINEMATICS Modèle d'Ackermann, le braquage devenant un état.
  MODELE = ACKERMANNKINEMATICS() décrit un véhicule où le braquage
  n'est plus une commande instantanée mais un état, commandé par sa
  vitesse de variation. C'est plus réaliste que le modèle bicyclette :
  une colonne de direction ne saute pas d'un angle à un autre.

  Propriétés :
     WheelBase        - l'empattement
     MaxSteeringAngle - le braquage maximal, en radians

  L'état est [X Y THETA PSI], la commande [V DPSI] :

     dtheta = V tan(PSI) / WheelBase,  dpsi = DPSI

  Exemple :
     modele = ackermannKinematics('WheelBase', 2.7);
     derivative(modele, [0 0 0 0], [10 0.2])

  Voir aussi BICYCLEKINEMATICS, UNICYCLEKINEMATICS.
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

## `bicycleKinematics`

```
BICYCLEKINEMATICS Modèle bicyclette d'un véhicule à direction avant.
  MODELE = BICYCLEKINEMATICS() décrit un véhicule dont la roue avant
  braque et dont la roue arrière suit. C'est le modèle de toute voiture
  à basse vitesse, et il diffère de l'unicycle sur un point décisif : il
  ne peut pas tourner sur place.

  Propriétés :
     WheelBase        - l'empattement, entre les deux essieux
     MaxSteeringAngle - le braquage maximal, en radians
     VehicleInputs    - 'VehicleSpeedSteeringAngle' ou
                        'VehicleSpeedHeadingRate'

  L'état est [X Y THETA]. Avec la vitesse V et le braquage PSI :

     dtheta = V tan(PSI) / WheelBase

  Le rayon de virage vaut donc WheelBase / tan(PSI), indépendant de la
  vitesse : c'est la formule d'Ackermann.

  Exemple :
     modele = bicycleKinematics('WheelBase', 2.7);
     derivative(modele, [0 0 0], [10 pi/12])

  Voir aussi ACKERMANNKINEMATICS, UNICYCLEKINEMATICS, BICYCLEMODEL.
```

## `binaryOccupancyMap`

```
BINARYOCCUPANCYMAP Carte d'occupation binaire, en coordonnées du monde.
  MAP = BINARYOCCUPANCYMAP(LARGEUR,HAUTEUR,RESOLUTION) crée une carte de
  LARGEUR sur HAUTEUR mètres, à RESOLUTION cellules par mètre. La
  résolution vaut un par défaut.
  MAP = BINARYOCCUPANCYMAP(M) reprend une matrice logique déjà faite.

  Propriétés :
     GridSize             - [lignes colonnes]
     Resolution           - cellules par mètre
     XWorldLimits         - [minimum maximum] en x
     YWorldLimits         - [minimum maximum] en y
     GridLocationInWorld  - le coin inférieur gauche, dans le monde
     DefaultValue         - la valeur des cellules jamais renseignées

  Ce qu'on lui demande :
     SETOCCUPANCY, GETOCCUPANCY  - écrire et lire une cellule
     CHECKOCCUPANCY              - lire en signalant le hors carte
     WORLD2GRID, GRID2WORLD      - passer d'un repère à l'autre
     OCCUPANCYMATRIX             - la matrice entière
     INFLATE                     - épaissir les obstacles
     RAYCAST                     - les cellules traversées par un rayon
     MOVE                        - déplacer la carte dans le monde

  La ligne 1 de la grille est le haut de la carte, donc la plus grande
  ordonnée : c'est la convention des images, et celle de MATLAB.

  INFLATE épaissit les obstacles du rayon du robot, ce qui permet
  ensuite de planifier en traitant le robot comme un point — c'est tout
  l'intérêt de l'opération.

  Exemple :
     map = binaryOccupancyMap(10, 10, 2);
     setOccupancy(map, [5 5], 1);
     getOccupancy(map, [5 5])        % 1
     inflate(map, 0.5);
     getOccupancy(map, [5.4 5])      % 1 : l'obstacle a grossi

  Voir aussi OCCUPANCYMAP, CONTROLLERVFH.
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

## `constraintAiming`

```
CONSTRAINTAIMING Contrainte de visée : pointer l'axe z vers un point.
  C = CONSTRAINTAIMING(CORPS) demande que l'axe z de CORPS pointe vers
  TargetPoint, à AngularTolerance près.

  Propriétés :
     EndEffector        - le corps qui vise
     ReferenceBody      - le repère où le point est donné
     TargetPoint        - le point visé, [X Y Z]
     AngularTolerance   - l'écart angulaire toléré, en radians
     Weights            - le poids de la contrainte

  Viser laisse libre la rotation autour de l'axe de visée : c'est un
  degré de liberté de moins contraint qu'une orientation complète, et
  c'est exactement ce qu'il faut pour une caméra ou un outil de
  révolution.

  Exemple :
     c = constraintAiming('camera');
     c.TargetPoint = [1 0 0.5];

  Voir aussi CONSTRAINTORIENTATIONTARGET, GENERALIZEDINVERSEKINEMATICS.
```

## `constraintCartesianBounds`

```
CONSTRAINTCARTESIANBOUNDS Contrainte de boîte sur la position d'un corps.
  C = CONSTRAINTCARTESIANBOUNDS(CORPS) confine l'origine de CORPS dans
  une boîte, exprimée dans le repère TargetTransform.

  Propriétés :
     EndEffector      - le corps contraint
     ReferenceBody    - le repère de référence
     TargetTransform  - le repère où la boîte est décrite
     Bounds           - 3 lignes de [minimum maximum]
     Weights          - le poids de la contrainte

  Une boîte contraint sans fixer : c'est ce qu'il faut pour dire « reste
  au-dessus de la table » ou « ne dépasse pas cette limite », qui sont
  les contraintes réelles d'une cellule de travail.

  Exemple :
     c = constraintCartesianBounds('outil');
     c.Bounds = [-inf inf; -inf inf; 0.1 inf];   % rester en hauteur

  Voir aussi CONSTRAINTPOSITIONTARGET, GENERALIZEDINVERSEKINEMATICS.
```

## `constraintDistanceBounds`

```
CONSTRAINTDISTANCEBOUNDS Contrainte de distance entre deux corps.
  C = CONSTRAINTDISTANCEBOUNDS(CORPS) demande que la distance entre
  l'origine de CORPS et celle de ReferenceBody reste entre les Bounds.

  Propriétés :
     EndEffector    - le corps contraint
     ReferenceBody  - l'autre corps, la base par défaut
     Bounds         - [minimum maximum], en mètres
     Weights        - le poids de la contrainte

  Une distance minimale tient à l'écart d'un obstacle ; une distance
  maximale garde l'outil à portée. Les deux ensemble décrivent une
  coquille sphérique, sans rien dire de la direction.

  Exemple :
     c = constraintDistanceBounds('outil');
     c.Bounds = [0.2 0.8];

  Voir aussi CONSTRAINTCARTESIANBOUNDS, GENERALIZEDINVERSEKINEMATICS.
```

## `constraintJointBounds`

```
CONSTRAINTJOINTBOUNDS Contrainte de butée sur les liaisons.
  C = CONSTRAINTJOINTBOUNDS(ROBOT) reprend les butées déclarées par
  chaque liaison de ROBOT ; on peut ensuite les resserrer.

  Propriétés :
     Bounds   - une ligne [minimum maximum] par liaison mobile
     Weights  - un poids par liaison

  Resserrer les butées d'une seule liaison est la façon la plus simple
  de choisir entre deux solutions de cinématique inverse : coude haut ou
  coude bas ne diffèrent que par le signe d'un angle.

  Exemple :
     c = constraintJointBounds(robot);
     c.Bounds(2, :) = [0 pi];        % force le coude d'un cote

  Voir aussi GENERALIZEDINVERSEKINEMATICS, RIGIDBODYJOINT.
```

## `constraintOrientationTarget`

```
CONSTRAINTORIENTATIONTARGET Contrainte d'orientation sur un corps.
  C = CONSTRAINTORIENTATIONTARGET(CORPS) demande que CORPS prenne
  l'orientation TargetOrientation, donnée en quaternion, sans rien
  imposer à sa position.

  Propriétés :
     EndEffector           - le corps contraint
     ReferenceBody         - le repère de référence
     TargetOrientation     - le quaternion visé, [W X Y Z]
     OrientationTolerance  - l'écart angulaire toléré, en radians
     Weights               - le poids de la contrainte

  Exemple :
     c = constraintOrientationTarget('outil');
     c.TargetOrientation = eul2quat([pi/2 0 0]);

  Voir aussi CONSTRAINTPOSETARGET, GENERALIZEDINVERSEKINEMATICS.
```

## `constraintPoseTarget`

```
CONSTRAINTPOSETARGET Contrainte de pose complète sur un corps.
  C = CONSTRAINTPOSETARGET(CORPS) demande que CORPS atteigne la pose
  TargetTransform, exprimée dans le repère de ReferenceBody.

  Propriétés :
     EndEffector           - le corps contraint
     ReferenceBody         - le repère de référence, la base par défaut
     TargetTransform       - la pose visée, matrice 4x4
     OrientationTolerance  - l'écart d'orientation toléré, en radians
     PositionTolerance     - l'écart de position toléré, en mètres
     Weights               - [orientation position]

  Une tolérance non nulle donne du jeu : la contrainte n'est violée
  qu'au-delà. C'est ce qui permet d'en satisfaire plusieurs à la fois
  quand aucune configuration ne les vérifie exactement.

  Exemple :
     c = constraintPoseTarget('effecteur');
     c.TargetTransform = trvec2tform([0.4 0.2 0]);

  Voir aussi GENERALIZEDINVERSEKINEMATICS, CONSTRAINTPOSITIONTARGET.
```

## `constraintPositionTarget`

```
CONSTRAINTPOSITIONTARGET Contrainte de position sur un corps.
  C = CONSTRAINTPOSITIONTARGET(CORPS) demande que l'origine de CORPS
  atteigne TargetPosition, sans rien imposer à son orientation.

  Propriétés :
     EndEffector        - le corps contraint
     ReferenceBody      - le repère de référence, la base par défaut
     TargetPosition     - le point visé, [X Y Z]
     PositionTolerance  - l'écart toléré, en mètres
     Weights            - le poids de la contrainte

  Ne contraindre que la position laisse au solveur les degrés de liberté
  d'orientation : c'est ce qu'on veut d'un bras redondant, dont on veut
  fixer le point sans imposer la pose de l'outil.

  Exemple :
     c = constraintPositionTarget('effecteur');
     c.TargetPosition = [0.4 0.2 0];

  Voir aussi CONSTRAINTPOSETARGET, GENERALIZEDINVERSEKINEMATICS.
```

## `controllerPurePursuit`

```
CONTROLLERPUREPURSUIT Suivi de chemin par poursuite pure.
  CTRL = CONTROLLERPUREPURSUIT() construit le régulateur ; on lui donne
  ensuite les points de passage, puis on l'appelle avec la pose :

     [V,OMEGA] = CTRL([X Y THETA])

  Propriétés :
     Waypoints              - les points de passage, en lignes
     LookaheadDistance      - la distance de visée
     DesiredLinearVelocity  - la vitesse d'avance voulue
     MaxAngularVelocity     - la vitesse de rotation maximale

  [V,OMEGA,POINT] = CTRL(POSE) rend aussi le point visé.

  Le régulateur vise un point du chemin situé à LookaheadDistance devant
  lui et décrit l'arc de cercle qui y mène. La distance de visée est le
  seul réglage : courte, le suivi oscille ; longue, il coupe les
  virages.

  Le point visé se cherche à partir du point le plus proche, jamais
  depuis le début du chemin : sans cela, le régulateur finirait par
  viser le départ, derrière lui.

  Exemple :
     ctrl = controllerPurePursuit();
     ctrl.Waypoints = [0 0; 1 0; 2 1];
     ctrl.LookaheadDistance = 0.5;
     [v, w] = ctrl([0 0 0]);

  Voir aussi PUREPURSUIT, CONTROLLERVFH, DIFFERENTIALDRIVEKINEMATICS.
```

## `controllerVFH`

```
CONTROLLERVFH Évitement d'obstacles par histogramme de champ de vecteurs.
  VFH = CONTROLLERVFH() construit le régulateur ; on l'appelle avec un
  relevé télémétrique et la direction voulue :

     CAP = VFH(DISTANCES,ANGLES,DIRECTIONVOULUE)

  Propriétés :
     NumAngularSectors       - le nombre de secteurs de l'histogramme
     DistanceLimits          - [minimum maximum] des distances prises
     RobotRadius             - le rayon du robot
     SafetyDistance          - la marge ajoutée au rayon
     MinTurningRadius        - le rayon de virage minimal
     TargetDirectionWeight   - le poids de la direction voulue
     CurrentDirectionWeight  - le poids du cap actuel
     PreviousDirectionWeight - le poids du cap précédent
     HistogramThresholds     - [bas haut] de l'hystérésis

  Le principe : découper le tour du robot en secteurs, mesurer dans
  chacun la densité d'obstacles, retenir les vallées assez larges pour
  passer, et y choisir la direction qui coûte le moins — en pesant
  l'écart au but, l'écart au cap actuel et l'écart au cap précédent.
  Ce dernier terme est ce qui empêche le robot d'hésiter entre deux
  passages équivalents.

  Rend NaN quand aucune direction ne convient : c'est un renseignement,
  non un échec — il faut alors reculer ou changer de but.

  Exemple :
     vfh = controllerVFH();
     distances = 3 * ones(1, 181);
     distances(80:100) = 0.4;              % un obstacle droit devant
     cap = vfh(distances, linspace(-pi/2, pi/2, 181), 0);

  Voir aussi CONTROLLERPUREPURSUIT, BINARYOCCUPANCYMAP.
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

## `differentialDriveKinematics`

```
DIFFERENTIALDRIVEKINEMATICS Modèle d'un mobile à entraînement différentiel.
  MODELE = DIFFERENTIALDRIVEKINEMATICS() décrit un robot à deux roues
  motrices indépendantes. C'est le modèle des robots d'intérieur les
  plus répandus : tourner sur place ne leur coûte rien, faire des
  trajectoires courbes non plus.

  Propriétés :
     WheelRadius     - le rayon des roues
     TrackWidth      - l'écartement entre les deux roues
     WheelSpeedRange - [minimum maximum] de la vitesse de roue
     VehicleInputs   - 'WheelSpeeds' ou 'VehicleSpeedHeadingRate'

  L'état est [X Y THETA]. Avec les vitesses de roue WL et WR :

     V = R (WR + WL) / 2,  OMEGA = R (WR - WL) / TrackWidth

  Les deux roues à la même vitesse donnent une ligne droite ; en sens
  contraire, une rotation sur place. Tout le reste est entre les deux.

  Exemple :
     modele = differentialDriveKinematics('WheelRadius', 0.1, ...
                                          'TrackWidth', 0.5);
     derivative(modele, [0 0 0], [1 1])       % tout droit
     derivative(modele, [0 0 0], [-1 1])      % sur place

  Voir aussi UNICYCLEKINEMATICS, BICYCLEKINEMATICS, ACKERMANNKINEMATICS.
```

## `eul2quat`

```
EUL2QUAT Angles d'Euler vers quaternion.
  Q = EUL2QUAT([A B C]) rend le quaternion [W X Y Z] de la rotation
  décrite par les trois angles, en radians, dans la séquence ZYX.

  Q = EUL2QUAT(EUL,SEQUENCE) emploie une autre séquence ; les douze
  d'EUL2ROTM sont acceptées.

  Une matrice N sur 3 rend une matrice N sur 4.

  Exemple :
     eul2quat([0 0 0])                       % [1 0 0 0]
     eul2quat([pi/2 0 0])                    % un quart de tour en lacet
     eul2quat([0.3 0.2 0.1], 'ZYZ')

  Voir aussi QUAT2EUL, EUL2ROTM, QUAT2ROTM, EUL2TFORM.
```

## `eul2rotm`

```
EUL2ROTM Angles d'Euler vers matrice de rotation.
  R = EUL2ROTM([A B C]) interprète les trois angles, en radians, dans
  la séquence ZYX : la rotation vaut Rz(A) Ry(B) Rx(C).

  R = EUL2ROTM(EUL,SEQUENCE) emploie une autre séquence. Les douze sont
  acceptées : les six de Tait-Bryan — 'ZYX', 'XYZ', 'YXZ', 'ZXY',
  'YZX', 'XZY' — et les six d'Euler propres, qui reviennent à leur
  premier axe — 'ZYZ', 'ZXZ', 'XYX', 'XZX', 'YXY', 'YZY'.

  Une matrice N sur 3 rend un tableau 3x3xN, une rotation par ligne.

  Les rotations s'appliquent dans l'ordre où on les lit, chacune autour
  des axes déjà tournés par les précédentes. C'est la convention dite
  intrinsèque, et c'est celle de MATLAB.

  Exemple :
     eul2rotm([pi/2 0 0])                    % un quart de tour en lacet
     eul2rotm([0.3 0.2 0.1], 'XYZ')          % autre sequence, autre R
     size(eul2rotm(rand(5, 3)))              % 3 3 5

  Voir aussi ROTM2EUL, EUL2QUAT, EUL2TFORM, ROTX, ROTY, ROTZ.
```

## `eul2tform`

```
EUL2TFORM Angles d'Euler vers matrice homogène 4x4.
  T = EUL2TFORM([A B C]) rend la transformation de rotation pure
  correspondant aux trois angles, en radians, dans la séquence ZYX. La
  translation est nulle.

  T = EUL2TFORM(EUL,SEQUENCE) emploie une autre séquence ; les douze
  d'EUL2ROTM sont acceptées.

  Une matrice N sur 3 rend un tableau 4x4xN.

  Exemple :
     T = eul2tform([pi / 2 0 0]);
     T(1:3, 1:3)                     % la rotation seule
     eul2tform([0.3 0.2 0.1], 'XYZ')

  Voir aussi TFORM2EUL, EUL2ROTM, EUL2QUAT, ROTM2TFORM.
```

## `fkine2R`

```
FKINE2R Cinématique directe d'un bras plan à deux segments.
  [X,Y] = FKINE2R([Q1 Q2],L1,L2) rend la position de l'effecteur.
```

## `generalizedInverseKinematics`

```
GENERALIZEDINVERSEKINEMATICS Cinématique inverse sous contraintes.
  GIK = GENERALIZEDINVERSEKINEMATICS('RigidBodyTree',ROBOT, ...
        'ConstraintInputs',{'position','joint'}) construit le solveur.
  [CONFIG,INFO] = GIK(DEPART,C1,C2,...) cherche la configuration qui
  satisfait au mieux toutes les contraintes.

  ConstraintInputs annonce les types attendus, dans l'ordre :
  'pose', 'position', 'orientation', 'cartesian', 'joint', 'aiming',
  'distance'.

  Là où INVERSEKINEMATICS ne connaît qu'une pose à atteindre, celui-ci
  accepte plusieurs contraintes de natures différentes et cherche le
  compromis. C'est ce qu'il faut dès qu'un robot est redondant : une
  position à tenir, une orientation approximative, et des butées à
  respecter font trois exigences que rien n'oblige à être compatibles.

  Chaque contrainte rend un résidu nul quand elle est satisfaite ; le
  solveur minimise la somme de leurs carrés par moindres carrés amortis,
  la jacobienne étant obtenue par différences finies — les contraintes
  n'ayant pas toutes de dérivée analytique simple.

  INFO rend Iterations, NumRandomRestarts, ExitFlag, Status et
  ConstraintViolations, une structure par contrainte.

  Exemple :
     gik = generalizedInverseKinematics('RigidBodyTree', robot, ...
               'ConstraintInputs', {'position', 'joint'});
     cible = constraintPositionTarget('effecteur');
     cible.TargetPosition = [0.4 0.2 0];
     [config, info] = gik(homeConfiguration(robot), cible, ...
                          constraintJointBounds(robot));

  Voir aussi INVERSEKINEMATICS, CONSTRAINTPOSETARGET, CONSTRAINTJOINTBOUNDS.
```

## `ikine2R`

```
IKINE2R Cinématique inverse d'un bras plan à deux segments.
  Q = IKINE2R(X,Y,L1,L2) rend les deux angles articulaires.
```

## `importrobot`

```
IMPORTROBOT Construit un arbre de corps rigides à partir d'un URDF.
  ROBOT = IMPORTROBOT(CHEMIN) lit le fichier URDF et rend un
  RIGIDBODYTREE.
  ROBOT = IMPORTROBOT(TEXTE) accepte aussi le contenu du fichier.
  ROBOT = IMPORTROBOT(...,'DataFormat',F) fixe le format des
  configurations, 'struct' par défaut.

  Sont lus : les liaisons — revolute, continuous, prismatic, fixed —,
  leurs axes, leurs butées, la transformation d'origine avec ses angles
  de roulis-tangage-lacet, et les masses, centres de masse et inerties
  déclarés dans les balises « inertial ».

  Une liaison « continuous » devient une rotoïde sans butée : c'est ce
  que le format veut dire, et l'arbre n'a pas d'autre type pour cela.

  Ce qui n'est pas lu — la géométrie visuelle, les collisions, les
  matériaux, les transmissions — ne sert ni à la cinématique ni à la
  dynamique, qui sont ce que l'arbre calcule.

  Exemple :
     robot = importrobot('bras.urdf');
     showdetails(robot);
     getTransform(robot, homeConfiguration(robot), 'outil')

  Voir aussi RIGIDBODYTREE, LOADROBOT, ADDBODY.
```

## `inverseKinematics`

```
INVERSEKINEMATICS Cinématique inverse d'un arbre de corps rigides.
  IK = INVERSEKINEMATICS('RigidBodyTree',ROBOT) construit le solveur.
  [CONFIG,INFO] = IK(CORPS,POSE,POIDS,DEPART) cherche la configuration
  qui amène CORPS sur la POSE demandée — une matrice homogène 4x4 — en
  partant de DEPART.

  POIDS compte six nombres : les trois premiers pèsent l'erreur
  d'orientation, les trois derniers l'erreur de position. Les mettre à
  zéro revient à ne pas contraindre la composante correspondante — c'est
  ainsi qu'on demande une position sans imposer l'orientation.

  Propriétés :
     RigidBodyTree     - l'arbre sur lequel on résout
     SolverParameters  - les réglages : MaxIterations, MaxTime,
                         SolutionTolerance, AllowRandomRestart

  INFO rend Iterations, NumRandomRestarts, PoseErrorNorm, ExitFlag et
  Status — 'success' ou 'best available'.

  La résolution se fait par moindres carrés amortis : à chaque pas on
  linéarise par la jacobienne géométrique et on résout

     (J' W J + lambda I) dq = J' W e

  L'amortissement lambda monte quand le pas échoue et descend quand il
  réussit. C'est ce qui rend la méthode sûre au voisinage des
  singularités, où la jacobienne seule n'est plus inversible.

  Quand la descente s'arrête sur un minimum local, le solveur repart
  d'une configuration tirée au hasard : c'est la seule parade contre les
  minima locaux, et le nombre de reprises figure dans INFO.

  Exemple :
     ik = inverseKinematics('RigidBodyTree', robot);
     cible = trvec2tform([0.5 0.3 0]);
     [config, info] = ik('effecteur', cible, [0 0 0 1 1 1], ...
                         homeConfiguration(robot));

  Voir aussi GENERALIZEDINVERSEKINEMATICS, RIGIDBODYTREE, GETTRANSFORM.
```

## `jacobian2R`

```
JACOBIAN2R Jacobienne d'un bras plan à deux segments.
  J = JACOBIAN2R([Q1 Q2],L1,L2) rend la matrice 2x2 qui relie les
  vitesses articulaires à la vitesse de l'effecteur : v = J qpoint.

  C'est par définition la dérivée de la cinématique directe : on peut
  donc la vérifier aux différences finies, sans rien savoir de sa
  formule.

  Son déterminant s'annule quand le bras est tendu ou complètement
  replié : l'effecteur ne peut alors plus bouger radialement, quelle que
  soit la commande. C'est la singularité, et c'est la jacobienne seule
  qui la signale.

  Exemple :
     J = jacobian2R([0.4 0.9], 1, 0.6);
     det(jacobian2R([0.4 0], 1, 0.6))        % 0 : bras tendu
     det(jacobian2R([0.4 pi], 1, 0.6))       % 0 : bras replie

  Voir aussi FKINE2R, IKINE2R, GEOMETRICJACOBIAN.
```

## `loadrobot`

```
LOADROBOT Charge un modèle de robot du catalogue.
  ROBOT = LOADROBOT(NOM) rend un RIGIDBODYTREE monté d'après les
  paramètres de Denavit-Hartenberg publiés pour ce robot.
  [ROBOT,DONNEES] = LOADROBOT(...) rend aussi une structure décrivant
  la source des paramètres et la configuration de repos.
  LOADROBOT(...,'DataFormat',F,'Gravity',G) règle l'arbre.

  Modèles disponibles :
     'universalUR3', 'universalUR5', 'universalUR10'
                         - les trois bras à six axes d'Universal Robots
     'puma560'           - le Unimation PUMA 560, six axes
     'stanfordArm'       - le bras de Stanford, cinq rotoïdes et une
                           prismatique
     'scara'             - un SCARA à quatre axes
     'planarArm2R', 'planarArm3R'
                         - les bras plans du cours

  LOADROBOT('list') rend la liste des noms.

  Les longueurs viennent des tables publiées par les constructeurs ou
  des manuels de robotique. Les masses sont celles annoncées quand elles
  le sont ; les inerties, faute de chiffres publics, sont celles d'une
  barre homogène de la longueur du segment. La cinématique est donc
  exacte, la dynamique seulement plausible — ce qui suffit à éprouver un
  algorithme, non à régler un robot réel.

  Exemple :
     robot = loadrobot('universalUR5', 'DataFormat', 'row');
     showdetails(robot);
     T = getTransform(robot, homeConfiguration(robot), 'outil');

  Voir aussi IMPORTROBOT, RIGIDBODYTREE, INVERSEKINEMATICS.
```

## `matlibre_rob_axe`

```
MATLIBRE_ROB_AXE Rotation élémentaire autour d'un axe numéroté.
  R = MATLIBRE_ROB_AXE(AXE,ANGLE) rend la rotation d'ANGLE radians
  autour de l'axe 1, 2 ou 3 — x, y ou z.

  ROTX, ROTY et ROTZ font la même chose en degrés et par trois
  fonctions distinctes ; ici l'axe est un nombre, ce qui permet de
  composer une séquence quelconque dans une boucle.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rob_bresenham`

```
MATLIBRE_ROB_BRESENHAM Cellules d'une grille traversées par un segment.
  CELLULES = MATLIBRE_ROB_BRESENHAM([I1 J1],[I2 J2]) rend la suite des
  indices, extrémités comprises.

  L'algorithme n'emploie que des entiers : c'est ce qui le rend exact,
  là où un pas en flottant finirait par sauter une cellule ou en
  compter deux.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
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

## `matlibre_rob_poseRelative`

```
MATLIBRE_ROB_POSERELATIVE Pose d'un corps dans un repère de référence.
  Une référence vide vaut le repère de base : c'est la convention des
  objets de contrainte, dont la propriété ReferenceBody est vide par
  défaut.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

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

## `matlibre_rob_sequence`

```
MATLIBRE_ROB_SEQUENCE Décode une séquence d'angles d'Euler.
  [AXES,SIGNE,TIERS,PROPRE] = MATLIBRE_ROB_SEQUENCE('ZYX') rend les
  trois numéros d'axe, la parité de la permutation, le numéro de l'axe
  qui ne figure pas dans une séquence propre, et si la séquence est
  propre — c'est-à-dire si son premier et son troisième axe coïncident.

  Les douze séquences valides se partagent en deux familles. Les six
  séquences de Tait-Bryan emploient les trois axes — ZYX, XYZ, ... ;
  les six séquences d'Euler propres reviennent au premier axe — ZYZ,
  XYX, ... Les formules d'extraction diffèrent d'une famille à l'autre,
  et c'est PROPRE qui les départage.

  SIGNE vaut +1 quand la séquence est une permutation circulaire de
  XYZ, -1 sinon. Ce seul nombre suffit à écrire les douze extractions
  d'un coup, au lieu de douze jeux de formules.

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

## `matlibre_rob_xml`

```
MATLIBRE_ROB_XML Lecture d'un document XML simple.
  NOEUDS = MATLIBRE_ROB_XML(TEXTE) rend un tableau de structures à
  quatre champs : Nom, Attributs — une structure nom-valeur —, Enfants,
  et Texte.

  Le lecteur couvre ce qu'un fichier URDF emploie : éléments, attributs
  entre guillemets simples ou doubles, balises auto-fermantes,
  commentaires et déclaration initiale. Il ne prétend pas lire le XML
  dans toute sa généralité — ni entités, ni espaces de noms, ni
  sections littérales — parce qu'un URDF n'en a pas besoin.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `occupancyMap`

```
OCCUPANCYMAP Carte d'occupation probabiliste.
  MAP = OCCUPANCYMAP(LARGEUR,HAUTEUR,RESOLUTION) crée une carte où
  chaque cellule porte une probabilité d'être occupée, et non un simple
  oui ou non. Les cellules valent 0.5 tant que rien ne les a
  renseignées : ni libres, ni occupées, inconnues.

  Propriétés :
     GridSize, Resolution, XWorldLimits, YWorldLimits
     GridLocationInWorld  - le coin inférieur gauche, dans le monde
     DefaultValue         - la probabilité des cellules jamais vues
     OccupiedThreshold    - au-dessus, la cellule compte pour occupée
     FreeThreshold        - en dessous, elle compte pour libre
     ProbabilitySaturation - [bas haut] où les probabilités se bloquent

  Ce qu'on lui demande :
     SETOCCUPANCY, GETOCCUPANCY - écrire et lire une probabilité
     UPDATEOCCUPANCY            - accumuler une observation
     CHECKOCCUPANCY             - trancher : 0 libre, 1 occupée, -1 inconnue
     INSERTRAY                  - intégrer tout un relevé télémétrique
     RAYCAST, INFLATE, OCCUPANCYMATRIX, WORLD2GRID, GRID2WORLD

  Les mises à jour se font en logarithme de rapport de cotes : dans
  cette échelle, accumuler des observations indépendantes revient à les
  additionner, ce qui est à la fois exact et sans risque de saturation
  numérique aux extrêmes.

  La saturation, elle, est voulue : borner les probabilités à [0.001,
  0.999] permet à la carte de se corriger quand le monde change, là où
  une certitude absolue serait définitive.

  Exemple :
     map = occupancyMap(10, 10, 2);
     updateOccupancy(map, [5 5], true);      % une observation d'obstacle
     getOccupancy(map, [5 5])                % au-dessus de 0.5
     insertRay(map, [1 1 0], 3, 0, 5);       % un rayon complet

  Voir aussi BINARYOCCUPANCYMAP, CONTROLLERVFH.
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
QUAT2EUL Quaternion vers angles d'Euler.
  EUL = QUAT2EUL([W X Y Z]) rend les trois angles de la séquence ZYX,
  en radians.

  EUL = QUAT2EUL(Q,SEQUENCE) emploie une autre séquence ; les douze
  d'EUL2ROTM sont acceptées.

  Une matrice N sur 4 rend une matrice N sur 3.

  Le passage se fait par la matrice de rotation : les angles d'Euler
  n'ont pas d'expression plus directe qui évite les cas particuliers,
  et celui du blocage de cardan — quand le deuxième angle atteint un
  quart de tour — se traite au même endroit pour les deux chemins.

  Exemple :
     quat2eul(eul2quat([0.3 0.2 0.1]))       % [0.3 0.2 0.1]
     quat2eul(eul2quat([0.3 0.2 0.1], 'XYZ'), 'XYZ')

  Voir aussi EUL2QUAT, QUAT2ROTM, ROTM2EUL.
```

## `quat2rotm`

```
QUAT2ROTM Quaternion [w x y z] vers matrice de rotation.
  R = QUAT2ROTM(Q) rend la matrice 3x3 correspondante. Le quaternion est
  normalisé au passage : un quaternion non unitaire décrirait une
  rotation avec changement d'échelle, ce qui n'est pas une rotation.

  Le résultat est orthogonal de déterminant un, à la précision machine.

  Exemple :
     R = quat2rotm([1 0 0 0]);       % l'identite
     quat2rotm(rotm2quat(rotz(30))) - rotz(30)    % ~0

  Voir aussi ROTM2QUAT, QUAT2EUL, QUAT2AXANG.
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
  Q = QUATCONJ(A) change le signe de la partie vectorielle.

  Pour un quaternion unitaire — donc pour toute rotation — le conjugué
  est l'inverse : c'est ce qui rend l'inversion d'une rotation gratuite,
  là où l'inverse d'une matrice demanderait une transposition au mieux.

  Sur un quaternion non unitaire, conjugué et inverse diffèrent : QUATINV
  divise en plus par le carré de la norme.

  Exemple :
     q = rotm2quat(rotz(30));
     quatmultiply(q, quatconj(q))    % [1 0 0 0]
     quatconj(q) - quatinv(q)        % ~0 : q est unitaire

  Voir aussi QUATINV, QUATNORMALIZE, QUATMULTIPLY.
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
  Q = QUATMULTIPLY(A,B) compose les deux rotations : le résultat
  correspond au produit des matrices de rotation, dans le même ordre.

  C'est ce qui fait l'intérêt des quaternions : composer deux rotations
  coûte seize multiplications au lieu de vingt-sept, et le résultat
  reste unitaire à la précision machine — là où un produit de matrices
  dérive lentement de l'orthogonalité et demande une réorthogonalisation.

  Le produit n'est pas commutatif, pas plus que celui des rotations.

  Exemple :
     q1 = rotm2quat(rotz(30));
     q2 = rotm2quat(roty(-20));
     quat2rotm(quatmultiply(q1, q2)) - rotz(30) * roty(-20)   % ~0

  Voir aussi QUATDIVIDE, QUATCONJ, QUATINV, QUAT2ROTM.
```

## `quatnormalize`

```
QUATNORMALIZE Quaternion unitaire.
  Q = QUATNORMALIZE(A) divise par la norme.

  Seuls les quaternions unitaires représentent des rotations. Une longue
  suite de produits fait lentement dériver la norme par accumulation
  d'erreurs d'arrondi : renormaliser de temps en temps est le remède, et
  il est bien moins coûteux que la réorthogonalisation d'une matrice.

  Exemple :
     norm(quatnormalize([2 0 0 0]))  % 1
     quatnormalize([2 0 0 0])        % [1 0 0 0]

  Voir aussi QUATCONJ, QUATINV, QUATMULTIPLY.
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

## `rigidBody`

```
RIGIDBODY Corps rigide d'un arbre articulé.
  BODY = RIGIDBODY(NOM) crée un corps portant une liaison fixe du même
  nom. On lui donne ensuite sa liaison, sa masse et son inertie, puis on
  l'attache à un arbre par ADDBODY.

  Propriétés :
     Name          - le nom du corps
     Joint         - la liaison qui le relie à son parent
     Mass          - sa masse, en kilogrammes
     CenterOfMass  - son centre de masse, dans son propre repère
     Inertia       - [Ixx Iyy Izz Iyz Ixz Ixy] au centre de masse
     Parent        - le nom de son parent, une fois attaché
     Children      - les noms de ses enfants

  L'inertie se donne au centre de masse et dans le repère du corps : ce
  sont les six coefficients distincts de la matrice symétrique, dans
  l'ordre des trois termes diagonaux puis des trois produits.

  Exemple :
     corps = rigidBody('bras');
     corps.Joint = rigidBodyJoint('j1', 'revolute');
     corps.Mass = 2;
     corps.CenterOfMass = [0.25 0 0];
     corps.Inertia = [0.01 0.05 0.05 0 0 0];

  Voir aussi RIGIDBODYJOINT, RIGIDBODYTREE, ADDBODY.
```

## `rigidBodyJoint`

```
RIGIDBODYJOINT Liaison entre deux corps rigides.
  JNT = RIGIDBODYJOINT(NOM) crée une liaison fixe.
  JNT = RIGIDBODYJOINT(NOM,TYPE) où TYPE vaut 'fixed', 'revolute' ou
  'prismatic'.

  Propriétés :
     Name                     - le nom de la liaison
     Type                     - 'fixed', 'revolute' ou 'prismatic'
     JointAxis                - l'axe de rotation ou de translation
     HomePosition             - la position de repos
     PositionLimits           - [minimum maximum]
     JointToParentTransform   - du repère de liaison au corps parent
     ChildToJointTransform    - du corps enfant au repère de liaison

  La pose du corps enfant dans le repère du parent vaut

     T = JointToParentTransform * Tliaison(q) * ChildToJointTransform

  où Tliaison(q) est la rotation d'angle q — ou la translation de q —
  autour de JointAxis. Les deux transformations fixes encadrent donc le
  seul degré de liberté : l'une place la liaison sur le parent, l'autre
  place l'enfant sur la liaison.

  SETFIXEDTRANSFORM remplit ces deux transformations à partir des
  paramètres de Denavit-Hartenberg, standard ou modifiés, ce qui évite
  de les écrire à la main.

  Exemple :
     jnt = rigidBodyJoint('j1', 'revolute');
     jnt.JointAxis = [0 0 1];
     setFixedTransform(jnt, [0.5 0 0 0], 'dh');

  Voir aussi RIGIDBODY, RIGIDBODYTREE, SETFIXEDTRANSFORM.
```

## `rigidBodyTree`

```
RIGIDBODYTREE Arbre de corps rigides articulés.
  ROBOT = RIGIDBODYTREE() crée un arbre réduit à sa base.
  ROBOT = RIGIDBODYTREE('DataFormat',F,'MaxNumBodies',N) fixe le format
  des configurations — 'struct', 'row' ou 'column'.

  L'arbre décrit un robot : une base, des corps, et pour chaque corps la
  liaison qui le rattache à son parent. De cette seule description on
  tire toute la cinématique — GETTRANSFORM, GEOMETRICJACOBIAN — et toute
  la dynamique — MASSMATRIX, INVERSEDYNAMICS, FORWARDDYNAMICS.

  Propriétés :
     NumBodies     - le nombre de corps, base non comprise
     Bodies        - les corps, dans l'ordre où ils ont été ajoutés
     BodyNames     - leurs noms
     BaseName      - le nom de la base, 'base' par défaut
     Gravity       - le vecteur de pesanteur, nul par défaut
     DataFormat    - la forme des configurations

  Une configuration se donne sous trois formes, selon DataFormat : un
  tableau de structures à deux champs — JointName et JointPosition —,
  un vecteur ligne, ou un vecteur colonne. Le format par défaut est le
  tableau de structures, qui nomme ce qu'il porte ; les deux autres sont
  plus commodes dès qu'on calcule.

  Exemple :
     robot = rigidBodyTree('DataFormat', 'row');
     corps = rigidBody('bras1');
     corps.Joint = rigidBodyJoint('j1', 'revolute');
     setFixedTransform(corps.Joint, [1 0 0 0], 'dh');
     addBody(robot, corps, 'base');
     getTransform(robot, 0, 'bras1')

  Voir aussi RIGIDBODY, RIGIDBODYJOINT, ADDBODY, GETTRANSFORM,
  GEOMETRICJACOBIAN, INVERSEKINEMATICS, IMPORTROBOT, LOADROBOT.
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
ROTM2EUL Matrice de rotation vers angles d'Euler.
  EUL = ROTM2EUL(R) rend les trois angles, en radians, de la séquence
  ZYX : ceux tels que R vaut Rz(A) Ry(B) Rx(C).

  EUL = ROTM2EUL(R,SEQUENCE) emploie une autre séquence. Les douze
  séquences d'EUL2ROTM sont acceptées.

  Un tableau 3x3xN rend une matrice N sur 3, une ligne par rotation.

  Le second angle sort d'un arc-tangente à deux arguments, non d'un
  arc-sinus : c'est ce qui garde la précision quand il approche le
  quart de tour, là où le sinus s'aplatit.

  Au quart de tour exactement — le blocage de cardan — les deux autres
  angles ne sont plus déterminés séparément, seule leur somme l'est.
  La fonction annule alors le premier et met tout dans le troisième.

  Exemple :
     rotm2eul(eul2rotm([0.3 0.2 0.1]))       % [0.3 0.2 0.1]
     rotm2eul(rotz(90))                      % [pi/2 0 0]
     rotm2eul(eul2rotm([0.3 0.2 0.1], 'ZYZ'), 'ZYZ')

  Voir aussi EUL2ROTM, ROTM2QUAT, TFORM2EUL, ROTM2AXANG.
```

## `rotm2quat`

```
ROTM2QUAT Matrice de rotation vers quaternion [w x y z].
  Q = ROTM2QUAT(R) rend le quaternion unitaire de la rotation R.

  Le calcul se fait en quatre branches selon lequel des quatre termes
  est le plus grand : extraire w de la trace seule perdrait toute
  précision près d'un demi-tour, où la trace vaut -1 et où w s'annule.
  Choisir la branche la plus grande garde la précision partout.

  Un quaternion et son opposé décrivent la même rotation : la fonction
  rend celui dont la partie scalaire est positive.

  Exemple :
     q = rotm2quat(rotz(30));
     norm(q)                         % 1
     quat2rotm(q) - rotz(30)         % ~0

  Voir aussi QUAT2ROTM, ROTM2EUL, ROTM2AXANG.
```

## `rotm2tform`

```
ROTM2TFORM Rotation vers matrice homogène.
  T = ROTM2TFORM(R) place la rotation dans le coin supérieur gauche
  d'une matrice 4x4, la translation restant nulle.

  Exemple :
     rotm2tform(rotz(90))
     tform2rotm(rotm2tform(rotz(90))) - rotz(90)   % 0

  Voir aussi TFORM2ROTM, TRVEC2TFORM, EUL2TFORM.
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
  R = ROTX(ANGLE) rend la matrice 3x3 de la rotation d'ANGLE degrés
  autour de l'axe x, dans le sens direct — la règle de la main droite.

  Les degrés, non les radians : c'est la convention de MATLAB pour ces
  trois fonctions, et elle diffère de celle d'EUL2ROTM. Les confondre
  donne un résultat qui a l'air d'une rotation et n'est pas la bonne.

  Le résultat est orthogonal de déterminant un, à la précision machine.

  Exemple :
     rotx(90)
     rotx(30) * rotx(60)             % rotx(90) : les angles s'ajoutent

  Voir aussi ROTY, ROTZ, EUL2ROTM, AXANG2ROTM.
```

## `roty`

```
ROTY Rotation autour de l'axe y, angle en degrés.
  R = ROTY(ANGLE) rend la matrice 3x3 de la rotation d'ANGLE degrés
  autour de l'axe y, dans le sens direct — la règle de la main droite.

  Les degrés, non les radians : c'est la convention de MATLAB pour ces
  trois fonctions, et elle diffère de celle d'EUL2ROTM. Les confondre
  donne un résultat qui a l'air d'une rotation et n'est pas la bonne.

  Le résultat est orthogonal de déterminant un, à la précision machine.

  Exemple :
     roty(90)
     roty(30) * roty(60)             % roty(90) : les angles s'ajoutent

  Voir aussi ROTX, ROTZ, EUL2ROTM, AXANG2ROTM.
```

## `rotz`

```
ROTZ Rotation autour de l'axe z, angle en degrés.
  R = ROTZ(ANGLE) rend la matrice 3x3 de la rotation d'ANGLE degrés
  autour de l'axe z, dans le sens direct — la règle de la main droite.

  Les degrés, non les radians : c'est la convention de MATLAB pour ces
  trois fonctions, et elle diffère de celle d'EUL2ROTM. Les confondre
  donne un résultat qui a l'air d'une rotation et n'est pas la bonne.

  Le résultat est orthogonal de déterminant un, à la précision machine.

  Exemple :
     rotz(90)
     rotz(30) * rotz(60)             % rotz(90) : les angles s'ajoutent

  Voir aussi ROTX, ROTY, EUL2ROTM, AXANG2ROTM.
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
TFORM2EUL Matrice homogène vers angles d'Euler.
  EUL = TFORM2EUL(T) ne lit que la partie rotation, et rend les trois
  angles de la séquence ZYX.

  EUL = TFORM2EUL(T,SEQUENCE) emploie une autre séquence ; les douze
  d'EUL2ROTM sont acceptées.

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
  R = TFORM2ROTM(T) rend le bloc 3x3 supérieur gauche.

  La fonction ne vérifie pas que ce bloc est bien une rotation : sur une
  transformation qui porterait un changement d'échelle ou un
  cisaillement, elle rendrait ce bloc tel quel.

  Exemple :
     T = trvec2tform([1 2 3]) * rotm2tform(rotz(30));
     tform2rotm(T) - rotz(30)        % 0

  Voir aussi ROTM2TFORM, TFORM2TRVEC, TFORM2EUL.
```

## `tform2trvec`

```
TFORM2TRVEC Translation contenue dans une matrice homogène.
  V = TFORM2TRVEC(T) rend les trois premières lignes de la dernière
  colonne, sous forme de vecteur ligne.

  Avec TFORM2ROTM, elle décompose une transformation : T se recompose
  exactement en TRVEC2TFORM(V) * ROTM2TFORM(R), dans cet ordre — la
  rotation d'abord, puis la translation.

  Exemple :
     T = trvec2tform([1 2 3]) * rotm2tform(rotz(30));
     tform2trvec(T)                  % [1 2 3]

  Voir aussi TRVEC2TFORM, TFORM2ROTM.
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
  T = TRVEC2TFORM([X Y Z]) rend la transformation de translation pure :
  l'identité avec la translation dans la dernière colonne.

  Les coordonnées homogènes existent pour cela : une translation n'est
  pas linéaire en dimension trois, mais elle l'est en dimension quatre.
  C'est ce qui permet de composer rotations et translations par un
  simple produit de matrices.

  Exemple :
     T = trvec2tform([1 2 3]) * rotm2tform(rotz(30));
     tform2trvec(T)                  % [1 2 3]

  Voir aussi TFORM2TRVEC, ROTM2TFORM, EUL2TFORM.
```

## `unicycleKinematics`

```
UNICYCLEKINEMATICS Modèle cinématique de l'unicycle.
  MODELE = UNICYCLEKINEMATICS() décrit un mobile commandé par sa vitesse
  d'avance et sa vitesse de rotation. C'est le modèle le plus simple
  d'un robot à roues, et celui auquel les autres se ramènent.

  Propriétés :
     WheelRadius    - le rayon de roue, pour la commande en tours/s
     WheelSpeedRange - [minimum maximum] de la vitesse de roue
     VehicleInputs  - 'VehicleSpeedHeadingRate' ou 'WheelSpeedHeadingRate'

  L'état est [X Y THETA]. DERIVATIVE(MODELE,ETAT,COMMANDE) rend sa
  dérivée, qu'on intègre ensuite comme on veut :

     dx = V cos(THETA), dy = V sin(THETA), dtheta = OMEGA

  Exemple :
     modele = unicycleKinematics();
     derivative(modele, [0 0 0], [1 0.5])     % [1 0 0.5]

  Voir aussi DIFFERENTIALDRIVEKINEMATICS, BICYCLEKINEMATICS,
  ACKERMANNKINEMATICS, CONTROLLERPUREPURSUIT.
```

