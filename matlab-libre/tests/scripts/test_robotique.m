% test_robotique.m — arbres de corps rigides, dynamique, cinématique inverse.
%
% Tout ce qui suit se vérifie contre une propriété : la cinématique
% inverse annule la directe, la jacobienne est la dérivée de la
% cinématique, la matrice d'inertie est symétrique définie positive, et la
% dynamique d'un bras plan à deux masses ponctuelles a une forme fermée
% qu'on écrit à côté.

fprintf('robotique : arbres de corps rigides\n');

%% Séquences d'angles d'Euler
sequences = {'ZYX','XYZ','YXZ','ZXY','YZX','XZY','ZYZ','ZXZ','XYX','XZX','YXY','YZY'};
rng(7);
pireAngles = 0;
pireMatrices = 0;
for s = 1:numel(sequences)
    propre = sequences{s}(1) == sequences{s}(3);
    for essai = 1:50
        e = [rand*2*pi - pi, (rand - 0.5) * 2.5, rand*2*pi - pi];
        if propre
            e(2) = rand * 2.5 + 0.2;
        end
        R = eul2rotm(e, sequences{s});
        assert(norm(R' * R - eye(3)) < 1e-13, 'eul2rotm rend une rotation');
        er = rotm2eul(R, sequences{s});
        pireAngles = max(pireAngles, max(abs(er - e)));
        pireMatrices = max(pireMatrices, norm(eul2rotm(er, sequences{s}) - R));
    end
end
assert(pireAngles < 1e-12, 'les douze sequences bouclent sur les angles');
assert(pireMatrices < 1e-12, 'et sur les matrices');
% Cas dégénérés : les angles changent, la rotation non.
for s = 1:numel(sequences)
    for b = [0 pi/2 -pi/2 pi]
        if sequences{s}(1) == sequences{s}(3) && abs(b) == pi/2
            continue
        end
        R = eul2rotm([0.7 b -0.3], sequences{s});
        assert(norm(eul2rotm(rotm2eul(R, sequences{s}), sequences{s}) - R) < 1e-12, ...
               'le blocage de cardan garde la rotation');
    end
end
% Composition intrinsèque, et empilement.
assert(norm(eul2rotm([0.3 0.2 0.1], 'XYZ') - ...
           rotx(rad2deg(0.3)) * roty(rad2deg(0.2)) * rotz(rad2deg(0.1))) < 1e-14, ...
       'XYZ compose Rx Ry Rz dans cet ordre');
E = rand(5, 3);
P = eul2rotm(E);
assert(isequal(size(P), [3 3 5]), 'une pile N sur 3 donne un 3x3xN');
assert(max(max(abs(rotm2eul(P) - E))) < 1e-12, 'et revient telle quelle');
assert(isequal(size(eul2quat(E)), [5 4]), 'eul2quat empile aussi');
assert(max(abs(quat2eul(eul2quat([0.3 0.2 0.1], 'ZYZ'), 'ZYZ') - [0.3 0.2 0.1])) < 1e-12, ...
       'la sequence se propage au quaternion');
fprintf('  douze sequences d''Euler : %.1e sur les angles\n', pireAngles);

%% Un bras plan monté en arbre, comparé aux formules fermées
l1 = 1.0; l2 = 0.6;
robot = rigidBodyTree('DataFormat', 'row');
noms = {'bras1', 'bras2'};
L = [l1 l2];
for k = 1:2
    b = rigidBody(noms{k});
    b.Joint = rigidBodyJoint(sprintf('j%d', k), 'revolute');
    setFixedTransform(b.Joint, [L(k) 0 0 0], 'dh');
    b.Mass = 0; b.Inertia = zeros(1, 6);
    if k == 1, parent = 'base'; else, parent = noms{k-1}; end
    addBody(robot, b, parent);
end
assert(robot.NumBodies == 2, 'deux corps');
assert(matlibre_nddl(robot) == 2, 'deux degres de liberte');
q = [0.4 0.9];
T = getTransform(robot, q, 'bras2');
[x, y] = fkine2R(q, l1, l2);
assert(abs(T(1,4) - x) < 1e-12 && abs(T(2,4) - y) < 1e-12, ...
       'l''arbre retrouve fkine2R');
J = geometricJacobian(robot, q, 'bras2');
assert(norm(J(4:5, :) - jacobian2R(q, l1, l2)) < 1e-12, ...
       'et la jacobienne de jacobian2R');
% La jacobienne est bien la dérivée : différences finies sur la pose.
h = 1e-6;
for k = 1:2
    dq = zeros(1, 2); dq(k) = h;
    Tp = getTransform(robot, q + dq, 'bras2');
    Tm = getTransform(robot, q - dq, 'bras2');
    v = (Tp(1:3,4) - Tm(1:3,4)) / (2*h);
    assert(norm(v - J(4:6, k)) < 1e-6, 'la jacobienne est la derivee');
end
% Pose relative : d'un corps à lui-même, l'identité.
assert(norm(getTransform(robot, q, 'bras2', 'bras2') - eye(4)) < 1e-14, ...
       'la pose d''un corps dans son propre repere est l''identite');
assert(norm(getTransform(robot, q, 'bras1', 'bras2') * ...
            getTransform(robot, q, 'bras2', 'bras1') - eye(4)) < 1e-13, ...
       'les poses relatives s''inversent');

%% Dynamique, contre la forme fermée du bras à deux masses ponctuelles
m1 = 2; m2 = 1.5; g = 9.81;
robot.Gravity = [0 -g 0];
robot.Bodies{1}.Mass = m1;
robot.Bodies{2}.Mass = m2;
qd = [0.7 -1.1];
qdd = [0.3 -0.2];
c2 = cos(q(2)); s2 = sin(q(2));
Mth = [(m1+m2)*l1^2 + m2*l2^2 + 2*m2*l1*l2*c2, m2*l2^2 + m2*l1*l2*c2; ...
        m2*l2^2 + m2*l1*l2*c2,                  m2*l2^2];
Gth = [(m1+m2)*g*l1*cos(q(1)) + m2*g*l2*cos(q(1)+q(2)), m2*g*l2*cos(q(1)+q(2))];
Cth = [-m2*l1*l2*s2*(2*qd(1)*qd(2) + qd(2)^2), m2*l1*l2*s2*qd(1)^2];
assert(norm(massMatrix(robot, q) - Mth) < 1e-12, 'matrice d''inertie');
assert(norm(gravityTorque(robot, q) - Gth) < 1e-12, 'couples de pesanteur');
assert(norm(velocityProduct(robot, q, qd) - Cth) < 1e-12, 'couples de Coriolis');
tau = inverseDynamics(robot, q, qd, qdd);
assert(norm(tau - ((Mth*qdd(:)).' + Cth + Gth)) < 1e-12, 'dynamique inverse');
assert(norm(forwardDynamics(robot, q, qd, tau) - qdd) < 1e-10, ...
       'la dynamique directe annule l''inverse');
% La matrice d'inertie est symétrique définie positive, toujours.
rng(3);
for essai = 1:20
    M = massMatrix(robot, (rand(1,2) - 0.5) * 2 * pi);
    assert(norm(M - M.') < 1e-12, 'symetrique');
    assert(all(eig(M) > 0), 'definie positive');
end
% Centre de masse : la moyenne pondérée, calculée à côté.
[cx, cy] = fkine2R([q(1) 0], l1, 0);
[ex, ey] = fkine2R(q, l1, l2);
attendu = (m1*[cx cy 0] + m2*[ex ey 0]) / (m1 + m2);
assert(norm(centerOfMass(robot, q) - attendu) < 1e-12, 'centre de masse');
% Un effort extérieur sur l'effecteur se transmet par la jacobienne :
% tau = J' * torseur, c'est le principe des travaux virtuels.
torseur = [0 0 0 3 -2 0].';
fext = externalForce(robot, 'bras2', torseur);
robot.Gravity = [0 0 0];
tauExt = inverseDynamics(robot, q, zeros(1,2), zeros(1,2), fext);
assert(norm(tauExt + (J.' * torseur).') < 1e-10, ...
       'un effort exterieur se transmet par la transposee de la jacobienne');
robot.Gravity = [0 -g 0];
fprintf('  dynamique du bras plan : ecart a la forme fermee %.1e\n', ...
        norm(massMatrix(robot, q) - Mth));

%% Cinématique inverse
robotIK = loadrobot('planarArm2R', 'DataFormat', 'row');
ik = inverseKinematics('RigidBodyTree', robotIK);
qVrai = [0.4 0.9];
cible = getTransform(robotIK, qVrai, 'outil');
[config, info] = ik('outil', cible, [0 0 1 1 1 0], [0.1 0.1]);
assert(info.ExitFlag == 1, 'la cinematique inverse aboutit');
assert(norm(getTransform(robotIK, config, 'outil') - cible) < 1e-6, ...
       'et atteint la pose demandee');
% Contraintes : les butées choisissent le coude.
gik = generalizedInverseKinematics('RigidBodyTree', robotIK, ...
        'ConstraintInputs', {'position', 'joint'});
cibleP = constraintPositionTarget('outil');
cibleP.TargetPosition = cible(1:3, 4).';
butees = constraintJointBounds(robotIK);
butees.Bounds(2, :) = [0 pi];
haut = gik([0.1 0.1], cibleP, butees);
butees.Bounds(2, :) = [-pi 0];
bas = gik([0.1 -0.1], cibleP, butees);
assert(haut(2) > 0 && bas(2) < 0, 'les butees choisissent le coude');
assert(norm(getTransform(robotIK, haut, 'outil')(1:3,4) - cible(1:3,4)) < 1e-5, ...
       'coude haut : le point est atteint');
assert(norm(getTransform(robotIK, bas, 'outil')(1:3,4) - cible(1:3,4)) < 1e-5, ...
       'coude bas aussi');
fprintf('  cinematique inverse : %d iterations, erreur %.1e\n', ...
        info.Iterations, info.PoseErrorNorm);

%% Un robot du catalogue, et un URDF
ur5 = loadrobot('universalUR5', 'DataFormat', 'row');
assert(matlibre_nddl(ur5) == 6, 'l''UR5 a six axes');
ikur = inverseKinematics('RigidBodyTree', ur5);
qUr = [0.3 -0.7 1.2 -0.4 0.5 0.1];
cibleUr = getTransform(ur5, qUr, 'outil');
[cUr, infoUr] = ikur('outil', cibleUr, ones(1,6), zeros(1,6));
assert(infoUr.ExitFlag == 1, 'la cinematique inverse de l''UR5 aboutit');
assert(norm(getTransform(ur5, cUr, 'outil') - cibleUr) < 1e-5, ...
       'et retrouve la pose');

urdf = ['<?xml version="1.0"?><robot name="deux">' ...
        '<link name="base_link"/>' ...
        '<link name="l1"><inertial><mass value="2"/><origin xyz="0.5 0 0"/>' ...
        '<inertia ixx="0.01" iyy="0.02" izz="0.03" ixy="0" ixz="0" iyz="0"/>' ...
        '</inertial></link>' ...
        '<link name="l2"/>' ...
        '<joint name="j1" type="revolute"><parent link="base_link"/>' ...
        '<child link="l1"/><origin xyz="0 0 0" rpy="0 0 0"/><axis xyz="0 0 1"/>' ...
        '<limit lower="-3.14" upper="3.14"/></joint>' ...
        '<joint name="j2" type="revolute"><parent link="l1"/><child link="l2"/>' ...
        '<origin xyz="1 0 0" rpy="0 0 0"/><axis xyz="0 0 1"/>' ...
        '<limit lower="-3.14" upper="3.14"/></joint></robot>'];
importe = importrobot(urdf, 'DataFormat', 'row');
assert(strcmp(importe.BaseName, 'base_link'), 'la base se reconnait a n''avoir pas de parent');
assert(matlibre_nddl(importe) == 2, 'deux liaisons mobiles');
assert(abs(importe.Bodies{1}.Mass - 2) < 1e-12, 'la masse est lue');
Tu = getTransform(importe, [0 pi/2], 'l2');
assert(abs(Tu(1,4) - 1) < 1e-12 && abs(Tu(2,4)) < 1e-12, ...
       'la transformation d''origine place le second corps');
fprintf('  UR5 et URDF : ok\n');

%% Modèles de mobiles
u = unicycleKinematics();
assert(norm(derivative(u, [0 0 0], [1 0.5]).' - [1 0 0.5]) < 1e-14, 'unicycle');
dd = differentialDriveKinematics('WheelRadius', 0.1, 'TrackWidth', 0.5);
assert(norm(derivative(dd, [0 0 0], [1 1]).' - [0.1 0 0]) < 1e-14, ...
       'deux roues egales : tout droit');
assert(abs(derivative(dd, [0 0 0], [-1 1])(3) - 0.4) < 1e-14, ...
       'deux roues opposees : sur place');
bk = bicycleKinematics('WheelBase', 2.7);
d = derivative(bk, [0 0 0], [10 deg2rad(10)]);
assert(abs(10 / d(3) - 2.7 / tan(deg2rad(10))) < 1e-9, ...
       'le rayon suit la formule d''Ackermann');
ak = ackermannKinematics('WheelBase', 2.7);
da = derivative(ak, [0 0 0 deg2rad(10)], [10 0.2]);
assert(abs(da(3) - d(3)) < 1e-12 && abs(da(4) - 0.2) < 1e-14, ...
       'le braquage devient un etat');

%% Régulateurs et cartes
ctrl = controllerPurePursuit();
ctrl.Waypoints = [linspace(0, 20, 201).', zeros(201, 1)];
ctrl.LookaheadDistance = 1;
ctrl.DesiredLinearVelocity = 1;
ctrl.MaxAngularVelocity = 2;
[v, w] = ctrl([0 0 0]);
assert(abs(v - 1) < 1e-14 && abs(w) < 1e-12, 'sur le chemin, rien a corriger');
[~, wg] = ctrl([0 0.5 0]);
[~, wd] = ctrl([0 -0.5 0]);
assert(wg < 0 && wd > 0, 'le regulateur corrige du bon cote');
assert(abs(wg + wd) < 1e-12, 'et symetriquement');

vfh = controllerVFH();
angles = linspace(-pi/2, pi/2, 181);
distances = 3 * ones(1, 181);
assert(abs(vfh(distances, angles, 0)) < 0.1, 'sans obstacle, tout droit');
distances(75:105) = 0.3;
cap = vfh(distances, angles, 0);
assert(abs(cap) > 0.1, 'devant un obstacle, il se detourne');
assert(~isnan(cap), 'et trouve un passage');

map = binaryOccupancyMap(10, 10, 2);
assert(isequal(map.GridSize, [20 20]), 'la grille suit la resolution');
setOccupancy(map, [5 5], 1);
assert(getOccupancy(map, [5 5]) == 1, 'la cellule est occupee');
assert(getOccupancy(map, [1 1]) == 0, 'les autres non');
assert(checkOccupancy(map, [50 50]) == -1, 'hors carte : inconnu');
ij = world2grid(map, [5 5]);
assert(norm(grid2world(map, ij) - [5.25 5.25]) < 1e-12, ...
       'grid2world rend le centre de la cellule');
avant = sum(sum(occupancyMatrix(map)));
inflate(map, 0.5);
assert(sum(sum(occupancyMatrix(map))) > avant, 'l''obstacle grossit');
assert(getOccupancy(map, [5.4 5]) == 1, 'et deborde sur ses voisines');

carte = occupancyMap(10, 10, 2);
assert(abs(getOccupancy(carte, [5 5]) - 0.5) < 1e-12, 'inconnue au depart');
assert(checkOccupancy(carte, [5 5]) == -1, 'ni libre ni occupee');
for k = 1:5, updateOccupancy(carte, [5 5], true); end
assert(getOccupancy(carte, [5 5]) > 0.9, 'cinq observations la rendent sure');
assert(checkOccupancy(carte, [5 5]) == 1, 'et elle compte pour occupee');
for k = 1:20, updateOccupancy(carte, [5 5], false); end
assert(getOccupancy(carte, [5 5]) < 0.2, 'vingt observations contraires la retournent');
rayon = occupancyMap(10, 10, 2);
insertRay(rayon, [1 1 0], 3, 0, 5);
assert(getOccupancy(rayon, [4 1]) > 0.5, 'le rayon marque son point d''arret');
assert(getOccupancy(rayon, [2.5 1]) < 0.5, 'et libere ce qu''il traverse');
fprintf('  mobiles, regulateurs et cartes : ok\n');

fprintf('robotique : tous les tests passent\n');
