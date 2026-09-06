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
