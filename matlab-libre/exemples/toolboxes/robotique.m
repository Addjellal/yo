%% Robotique : repères, bras, trajectoires
% Trois questions y reviennent sans cesse. Où est l'effecteur quand les
% articulations valent tant — la cinématique directe. Quelles
% articulations pour l'amener là — la cinématique inverse. Et comment
% l'y conduire sans à-coups — la génération de trajectoire.
%
% Chacune se vérifie par une propriété, non par une valeur recopiée :
% l'inverse annule la directe, la jacobienne est la dérivée, l'aire sous
% la vitesse est la distance.
%
% Voir aussi FKINE2R, IKINE2R, JACOBIAN2R, ROTM2QUAT, TRAPVELTRAJ.

fprintf('=== Robotique : reperes, bras, trajectoires ===\n');

%% 1. Le bras plan à deux segments
% Deux segments, deux articulations, un plan : c'est le plus petit bras
% qui ait déjà tout le problème — un espace de travail borné, deux
% solutions inverses, une singularité.
l1 = 1.0;
l2 = 0.6;
q = [0.4, 0.9];
[x, y] = fkine2R(q, l1, l2);
fprintf('\nBras 2R (l1=%g, l2=%g), q = [%.2f %.2f] :\n', l1, l2, q(1), q(2));
fprintf('  effecteur en (%.4f, %.4f)\n', x, y);

% La cinématique inverse retrouve exactement les angles de départ.
qRetour = ikine2R(x, y, l1, l2);
fprintf('  inverse : q = [%.4f %.4f], ecart %.2e\n', ...
        qRetour(1), qRetour(2), norm(qRetour - q));
assert(norm(qRetour - q) < 1e-12, 'l''inverse doit annuler la directe');

% Deux configurations mènent au même point : coude haut, coude bas. Elles
% sont symétriques l'une de l'autre par rapport à la droite qui joint
% l'épaule à l'effecteur.
qBas = ikine2R(x, y, l1, l2, false);
[xb, yb] = fkine2R(qBas, l1, l2);
fprintf('  coude bas : q = [%.4f %.4f], meme point (%.4f, %.4f)\n', ...
        qBas(1), qBas(2), xb, yb);
assert(abs(xb - x) < 1e-12 && abs(yb - y) < 1e-12, ...
       'les deux coudes atteignent le meme point');
assert(abs(qBas(2) + q(2)) < 1e-12, 'et sont opposees sur le coude');

% L'espace de travail est une couronne : rien à moins de |l1-l2| de
% l'épaule, rien au-delà de l1+l2. La couronne se referme en disque quand
% les deux segments sont égaux.
fprintf('  espace de travail : couronne de %.2f a %.2f\n', ...
        abs(l1 - l2), l1 + l2);
for portee = [l1 + l2, abs(l1 - l2)]
    qLimite = ikine2R(portee, 0, l1, l2);
    [xl, yl] = fkine2R(qLimite, l1, l2);
    assert(abs(hypot(xl, yl) - portee) < 1e-9, 'les bords sont atteignables');
end

%% 2. La jacobienne, et ce qu'elle dit des singularités
% La jacobienne relie vitesses articulaires et vitesse de l'effecteur.
% C'est par définition la dérivée de la cinématique directe : on peut donc
% la vérifier aux différences finies, sans rien savoir de sa formule.
J = jacobian2R(q, l1, l2);
h = 1e-6;
Jnum = zeros(2, 2);
for k = 1:2
    dq = zeros(1, 2);
    dq(k) = h;
    [xp, yp] = fkine2R(q + dq, l1, l2);
    [xm, ym] = fkine2R(q - dq, l1, l2);
    Jnum(:, k) = [(xp - xm); (yp - ym)] / (2 * h);
end
fprintf('\nJacobienne en q = [%.2f %.2f] :\n', q(1), q(2));
fprintf('  ecart a la derivee numerique : %.2e\n', norm(J - Jnum));
assert(norm(J - Jnum) < 1e-8, 'la jacobienne est la derivee de la directe');

% Bras tendu : le déterminant s'annule. L'effecteur ne peut plus bouger
% radialement, quelle que soit la commande — c'est la singularité, et
% c'est la jacobienne seule qui la signale.
fprintf('  det J = %.4f (bras plie), %.2e (bras tendu)\n', ...
        det(J), det(jacobian2R([0.4, 0], l1, l2)));
assert(abs(det(jacobian2R([0.4, 0], l1, l2))) < 1e-15, ...
       'bras tendu : la jacobienne est singuliere');
assert(abs(det(jacobian2R([0.4, pi], l1, l2))) < 1e-15, ...
       'bras replie : singuliere aussi');

% Loin de la singularité, la jacobienne convertit correctement une petite
% vitesse articulaire en vitesse cartésienne.
qPoint = [0.1; -0.2];
vitesse = J * qPoint;
dt = 1e-5;
[x2, y2] = fkine2R(q + dt * qPoint', l1, l2);
vitesseNum = ([x2; y2] - [x; y]) / dt;
fprintf('  v = J*qpoint : [%.4f %.4f], par integration [%.4f %.4f]\n', ...
        vitesse(1), vitesse(2), vitesseNum(1), vitesseNum(2));
assert(norm(vitesse - vitesseNum) < 1e-4, 'J convertit bien les vitesses');

%% 3. Les représentations de la rotation
% Matrice, quaternion, angles d'Euler, axe-angle : quatre façons de dire
% la même chose. Les conversions doivent donc former des allers-retours
% exacts, et la matrice rester orthogonale à chaque étape.
R = rotz(30) * roty(-20) * rotx(45);
fprintf('\nRotation R = Rz(30) Ry(-20) Rx(45) :\n');
fprintf('  orthogonale : ||R''R - I|| = %.2e, det = %.10f\n', ...
        norm(R' * R - eye(3)), det(R));
assert(norm(R' * R - eye(3)) < 1e-14, 'une rotation est orthogonale');
assert(abs(det(R) - 1) < 1e-14, 'de determinant un');

quat = rotm2quat(R);
fprintf('  quaternion [%.4f %.4f %.4f %.4f], norme %.12f\n', ...
        quat(1), quat(2), quat(3), quat(4), norm(quat));
assert(abs(norm(quat) - 1) < 1e-14, 'un quaternion de rotation est unitaire');
assert(norm(quat2rotm(quat) - R) < 1e-13, 'aller-retour matrice-quaternion');

eul = rotm2eul(R);
assert(norm(eul2rotm(eul) - R) < 1e-13, 'aller-retour matrice-Euler');
axang = rotm2axang(R);
fprintf('  axe [%.4f %.4f %.4f], angle %.4f rad\n', ...
        axang(1), axang(2), axang(3), axang(4));
assert(abs(norm(axang(1:3)) - 1) < 1e-13, 'l''axe est unitaire');
assert(norm(axang2rotm(axang) - R) < 1e-13, 'aller-retour matrice-axe-angle');

% Le produit de quaternions correspond au produit de matrices : c'est ce
% qui fait leur intérêt, composer sans passer par neuf coefficients.
q1 = rotm2quat(rotz(30));
q2 = rotm2quat(roty(-20));
assert(norm(quat2rotm(quatmultiply(q1, q2)) - rotz(30) * roty(-20)) < 1e-13, ...
       'le produit de quaternions compose les rotations');
fprintf('  quatmultiply compose comme le produit de matrices\n');

% L'inverse d'un quaternion unitaire est son conjugué, et faire tourner un
% vecteur conserve sa norme.
assert(norm(quatmultiply(quat, quatinv(quat)) - [1 0 0 0]) < 1e-13, ...
       'q * q^-1 = 1');
assert(norm(quatconj(quat) - quatinv(quat)) < 1e-14, ...
       'unitaire : l''inverse est le conjugue');
v = [0.3 -0.7 0.2];
vTourne = quatrotate(quat, v);
fprintf('  rotation d''un vecteur : norme %.12f avant, %.12f apres\n', ...
        norm(v), norm(vTourne));
assert(abs(norm(vTourne) - norm(v)) < 1e-14, 'une rotation conserve la norme');

%% 4. Denavit-Hartenberg
% La convention DH décrit chaque liaison par quatre nombres. Le produit
% des matrices donne la pose de l'effecteur : c'est la cinématique directe
% d'un bras quelconque, écrite une fois pour toutes.
%
% On le vérifie sur le bras 2R déjà connu, monté en DH : a=l, alpha=0,
% d=0, theta=q. Le résultat doit retomber sur FKINE2R.
T = dhTransform(l1, 0, 0, q(1)) * dhTransform(l2, 0, 0, q(2));
p = tform2trvec(T);
fprintf('\nDenavit-Hartenberg, bras 2R monte en DH :\n');
fprintf('  effecteur en (%.4f, %.4f, %.4f)\n', p(1), p(2), p(3));
assert(abs(p(1) - x) < 1e-12 && abs(p(2) - y) < 1e-12, ...
       'DH retrouve la cinematique directe');
assert(abs(p(3)) < 1e-15, 'le bras reste dans son plan');
% Une transformation homogène se décompose en rotation et translation.
assert(norm(tform2rotm(T) - rotz(rad2deg(q(1) + q(2)))) < 1e-13, ...
       'la rotation accumulee est la somme des angles');
assert(norm(trvec2tform(p) * rotm2tform(tform2rotm(T)) - T) < 1e-13, ...
       'T se recompose de sa rotation et de sa translation');

%% 5. Les trajectoires
% Relier deux points est facile ; les relier sans que les moteurs sautent
% l'est moins. Le degré du polynôme est exactement le nombre de conditions
% qu'on veut imposer aux extrémités.
instants = [0 2];
echantillons = linspace(0, 2, 201);
depart = [0; 0.5];
arrivee = [1.5; -0.3];

[qc, qdc, qddc] = cubicpolytraj([depart arrivee], instants, echantillons);
[qq, qdq, qddq] = quinticpolytraj([depart arrivee], instants, echantillons);
fprintf('\nTrajectoires point a point sur %g s :\n', instants(2));
fprintf('  cubique   : depart (%.4f, %.4f), arrivee (%.4f, %.4f)\n', ...
        qc(1,1), qc(2,1), qc(1,end), qc(2,end));
assert(norm(qc(:, 1) - depart) < 1e-12, 'la cubique part du bon point');
assert(norm(qc(:, end) - arrivee) < 1e-12, 'et arrive au bon');
assert(norm(qdc(:, 1)) < 1e-12 && norm(qdc(:, end)) < 1e-12, ...
       'a vitesse nulle aux deux bouts');

% La quintique impose en plus l'accélération nulle aux bouts : c'est
% précisément ce que la cubique ne peut pas faire, faute de degrés de
% liberté. Le prix en est une vitesse de pointe plus élevée.
fprintf('  quintique : acceleration au depart %.2e (cubique : %.4f)\n', ...
        norm(qddq(:, 1)), norm(qddc(:, 1)));
assert(norm(qddq(:, 1)) < 1e-10 && norm(qddq(:, end)) < 1e-10, ...
       'la quintique annule aussi l''acceleration aux bouts');
assert(norm(qddc(:, 1)) > 0.1, 'la cubique, elle, part avec un a-coup');
vitesseCubique = max(abs(qdc(1, :)));
vitesseQuintique = max(abs(qdq(1, :)));
fprintf('  vitesse de pointe : cubique %.4f, quintique %.4f\n', ...
        vitesseCubique, vitesseQuintique);
assert(vitesseQuintique > vitesseCubique, ...
       'la douceur aux bouts se paie en vitesse de pointe');

% Le profil trapézoïdal : rampe, palier, rampe. L'aire sous la courbe de
% vitesse est la distance parcourue — c'est la définition même.
[qt, qdt, ~, tt] = trapveltraj([depart arrivee], 200, 'EndTime', 2);
aire = trapz(tt, qdt(1, :));
fprintf('  trapezoidal : aire sous la vitesse %.6f, distance %.6f\n', ...
        aire, arrivee(1) - depart(1));
assert(abs(aire - (arrivee(1) - depart(1))) < 1e-3, ...
       'l''aire sous la vitesse est la distance');
assert(abs(qt(1, end) - arrivee(1)) < 1e-9, 'et le point d''arrivee est atteint');
% Le palier est un vrai palier : la vitesse y est constante.
milieu = qdt(1, round(end/2) + (-10:10));
assert(std(milieu) < 1e-9, 'le palier est a vitesse constante');
fprintf('  palier a %.4f, constant a %.2e pres\n', milieu(1), std(milieu));

%% 6. Interpoler des orientations
% Interpoler entre deux rotations n'est pas interpoler leurs coefficients.
% ROTTRAJ suit le plus court chemin sur la sphère des rotations, à vitesse
% angulaire constante : chaque pas y fait le même angle.
R0 = rotm2quat(eye(3));
R1 = rotm2quat(rotz(90));
% ROTTRAJ rend les quaternions en colonnes : une colonne par instant.
[Rs, omega] = rottraj(R0, R1, [0 1], linspace(0, 1, 11));
angles = zeros(1, size(Rs, 2) - 1);
for k = 1:numel(angles)
    relatif = quatmultiply(quatinv(Rs(:, k).'), Rs(:, k + 1).');
    aa = quat2axang(relatif);
    angles(k) = aa(4);
end
fprintf('\nInterpolation de rotation, 0 a 90 degres en dix pas :\n');
fprintf('  angle par pas : %.6f rad, ecart type %.2e\n', ...
        mean(angles), std(angles));
assert(std(angles) < 1e-12, 'la vitesse angulaire est constante');
assert(abs(sum(angles) - pi/2) < 1e-12, 'et le total fait bien 90 degres');
assert(norm(quat2rotm(Rs(:, end).') - rotz(90)) < 1e-12, ...
       'l''arrivee est la rotation demandee');
assert(all(abs(vecnorm(omega, 2, 1) - pi/2) < 1e-9), ...
       'omega est constant, egal a l''angle total sur la duree');

%% 7. Les angles se soustraient modulo un tour
% C'est le piège classique de tout asservissement de cap : la différence
% entre 179 et -179 degrés vaut deux degrés, non trois cent cinquante-huit.
fprintf('\nDifference d''angles :\n');
fprintf('  angdiff(3.1, -3.1) = %.4f, et non %.4f\n', ...
        angdiff(3.1, -3.1), -3.1 - 3.1);
assert(abs(angdiff(3.1, -3.1) - (2*pi - 6.2)) < 1e-12, ...
       'la difference se replie dans [-pi, pi]');
assert(abs(angdiff(deg2rad(179), deg2rad(-179)) - deg2rad(2)) < 1e-12, ...
       '179 a -179 : deux degres');
assert(all(abs(angdiff([0 pi/2 pi]) - pi/2) < 1e-12), ...
       'et sur un vecteur, les differences successives');

fprintf('\nToutes les verifications passent.\n');
