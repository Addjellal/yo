%% Fusion de capteurs : deux mesures valent mieux qu'une
% Aucun capteur ne dit toute la vérité. L'accéléromètre donne un angle
% juste en moyenne mais bruité ; le gyromètre donne une vitesse propre
% mais dont l'intégrale dérive. Fusionner, c'est prendre à chacun ce
% qu'il a de bon : les basses fréquences de l'un, les hautes de l'autre.
%
% Voir aussi COMPLEMENTARYFILTER, KALMANFILTER, MADGWICKUPDATE, TRACKASSIGN.

fprintf('=== Fusion de capteurs ===\n');

%% 1. Les deux capteurs, chacun avec son défaut
% On simule un angle qui oscille lentement. L'accéléromètre le mesure
% avec un bruit blanc important ; le gyromètre mesure sa dérivée, avec un
% biais constant faible — c'est le défaut typique d'un gyromètre bon
% marché, et il suffit à ruiner l'intégration.
rng(3);
dt = 0.01;
n = 2000;
t = (0:n-1) * dt;
vrai = 0.5 * sin(2 * pi * 0.2 * t);
vitesseVraie = 0.5 * 2 * pi * 0.2 * cos(2 * pi * 0.2 * t);

bruitAccel = 0.15;
biaisGyro = 0.02;
accel = vrai + bruitAccel * randn(1, n);
gyro = vitesseVraie + biaisGyro + 0.005 * randn(1, n);

% L'intégration seule du gyromètre : la dérive est linéaire en temps,
% exactement le biais multiplié par la durée.
integre = cumsum(gyro) * dt;
fprintf('\nLes deux capteurs pris seuls, sur %g s :\n', t(end));
fprintf('  accelerometre : ecart type %.4f, biais %.4f\n', ...
        std(accel - vrai), mean(accel - vrai));
fprintf('  gyrometre integre : derive finale %.4f (biais %g x %g s = %.4f)\n', ...
        integre(end) - vrai(end), biaisGyro, t(end), biaisGyro * t(end));
assert(abs(std(accel - vrai) - bruitAccel) < 0.02, ...
       'l''accelerometre est bruite mais sans biais');
assert(abs(mean(accel - vrai)) < 0.02, 'sans biais, donc juste en moyenne');
assert(abs((integre(end) - vrai(end)) - biaisGyro * t(end)) < 0.05, ...
       'la derive du gyrometre est le biais integre');

%% 2. Le filtre complémentaire
% Un pôle, deux gains : ALPHA sur l'intégration du gyromètre, 1-ALPHA sur
% l'accéléromètre. C'est un passe-haut sur l'un et un passe-bas sur
% l'autre, dont la somme fait exactement un — d'où le nom.
%
% La constante de temps de la coupure vaut ALPHA*dt/(1-ALPHA) : c'est la
% durée pendant laquelle on fait confiance au gyromètre avant que
% l'accéléromètre reprenne la main.
alpha = 0.98;
tau = alpha * dt / (1 - alpha);
fprintf('\nFiltre complementaire, alpha = %g :\n', alpha);
fprintf('  constante de temps %.3f s (coupure %.3f Hz)\n', tau, 1 / (2*pi*tau));

estime = zeros(1, n);
estime(1) = accel(1);
for k = 2:n
    estime(k) = complementaryFilter(accel(k), gyro(k), dt, alpha, estime(k-1));
end
regime = 500:n;
erreurFiltre = std(estime(regime) - vrai(regime));
fprintf('  ecart type residuel : %.4f (accelerometre seul %.4f)\n', ...
        erreurFiltre, std(accel(regime) - vrai(regime)));
assert(erreurFiltre < std(accel(regime) - vrai(regime)) / 3, ...
       'le filtre doit battre nettement l''accelerometre seul');
% Et il ne dérive pas, contrairement au gyromètre : l'accéléromètre le
% recale en permanence.
assert(abs(mean(estime(regime) - vrai(regime))) < 0.05, ...
       'et ne pas deriver, contrairement au gyrometre seul');
fprintf('  biais residuel %.4f, contre %.4f pour le gyrometre integre\n', ...
        mean(estime(regime) - vrai(regime)), ...
        mean(integre(regime) - vrai(regime)));

% Le réglage d'ALPHA arbitre entre bruit et retard : plus il est proche
% de un, moins l'accéléromètre passe, mais plus le suivi tarde.
for a = [0.90 0.98 0.999]
    e = zeros(1, n);
    e(1) = accel(1);
    for k = 2:n
        e(k) = complementaryFilter(accel(k), gyro(k), dt, a, e(k-1));
    end
    fprintf('  alpha = %.3f : bruit %.4f, biais %+.4f\n', ...
            a, std(e(regime) - vrai(regime)), mean(e(regime) - vrai(regime)));
end

%% 3. Le filtre de Kalman, qui règle ALPHA tout seul
% Le filtre complémentaire fixe le compromis une fois pour toutes ; le
% filtre de Kalman le recalcule à chaque pas à partir des covariances.
% Sur un modèle position-vitesse, il estime en prime le biais du
% gyromètre, qu'on ne mesure jamais.
%
% État : [angle ; biais]. Le gyromètre entre en commande, non en mesure —
% c'est ce montage qui permet d'identifier son biais.
A = [1 -dt; 0 1];
B = [dt; 0];
H = [1 0];
Q = [1e-6 0; 0 1e-8];
R = bruitAccel ^ 2;
x = [accel(1); 0];
P = eye(2);
kalman = zeros(2, n);
for k = 1:n
    [x, P] = kalmanFilter(x, P, accel(k), A, H, Q, R, gyro(k), B);
    kalman(:, k) = x;
end
fprintf('\nFiltre de Kalman a deux etats (angle, biais gyro) :\n');
fprintf('  ecart type residuel %.4f\n', std(kalman(1, regime) - vrai(regime)));
fprintf('  biais gyro estime %.5f (vrai %g), jamais mesure\n', ...
        mean(kalman(2, regime)), biaisGyro);
assert(std(kalman(1, regime) - vrai(regime)) < std(accel(regime) - vrai(regime)) / 3, ...
       'Kalman bat aussi l''accelerometre seul');
assert(abs(mean(kalman(2, regime)) - biaisGyro) < 0.01, ...
       'et identifie le biais du gyrometre');

%% 4. Madgwick : l'attitude en trois dimensions
% Un quaternion, un gyromètre trois axes, un accéléromètre trois axes.
% L'accéléromètre ne voit que la gravité : il fixe le roulis et le
% tangage, jamais le lacet. C'est une limite de principe, pas de méthode.
%
% Cas d'école : capteur immobile, penché de trente degrés en roulis. Le
% gyromètre ne dit rien, l'accéléromètre voit la gravité de travers, et
% le filtre doit converger vers ce roulis en partant de zéro.
roulis = deg2rad(30);
g = [0; sin(roulis); cos(roulis)] * 9.81;
q = [1 0 0 0];
for k = 1:3000
    q = madgwickUpdate(q, [0 0 0], g.', 0.01, 0.5);
end
eul = quat2eul(q, 'XYZ');
fprintf('\nMadgwick, capteur immobile penche de 30 degres :\n');
fprintf('  roulis estime %.3f degres apres convergence\n', rad2deg(eul(1)));
assert(abs(rad2deg(eul(1)) - 30) < 1, 'le roulis se retrouve par la gravite');
assert(abs(norm(q) - 1) < 1e-9, 'le quaternion reste unitaire');

% Le gyromètre seul fait tourner le quaternion : sans accéléromètre
% (beta = 0), c'est une simple intégration de la vitesse angulaire.
q = [1 0 0 0];
vitesse = [0 0 deg2rad(90)];
for k = 1:100
    q = madgwickUpdate(q, vitesse, [0 0 0], 0.01, 0);
end
eul = quat2eul(q, 'ZYX');
fprintf('  90 deg/s de lacet pendant 1 s : %.3f degres integres\n', ...
        rad2deg(eul(1)));
assert(abs(rad2deg(eul(1)) - 90) < 0.5, 'le gyrometre s''integre correctement');

%% 5. Associer des mesures à des pistes
% Suivre plusieurs objets demande d'abord de savoir quelle mesure va à
% quelle piste. Le plus proche voisin global fait ce travail, avec un
% seuil qui laisse une mesure sans piste plutôt que de l'attribuer de
% travers.
pistes = [0 0; 10 0; 0 10];
mesures = [10.2 0.3; 0.1 -0.2; 0.4 9.7];
assignation = trackAssign(pistes, mesures);
fprintf('\nAssociation de %d mesures a %d pistes :\n', ...
        size(mesures, 1), size(pistes, 1));
for k = 1:numel(assignation)
    fprintf('  piste %d (%g,%g) -> mesure %d (%g,%g)\n', ...
            k, pistes(k,1), pistes(k,2), assignation(k), ...
            mesures(assignation(k),1), mesures(assignation(k),2));
end
assert(isequal(assignation(:).', [2 1 3]), ...
       'chaque piste prend la mesure qui lui est la plus proche');
assert(numel(unique(assignation)) == numel(assignation), ...
       'et aucune mesure n''est prise deux fois');

% Une mesure trop lointaine ne doit être attribuée à personne : le seuil
% est ce qui distingue le suivi de l'invention.
loin = [0.1 -0.2; 50 50];
assignation = trackAssign([0 0; 10 0], loin, 3);
fprintf('  avec un seuil de 3 : piste 1 -> mesure %d, piste 2 -> %d\n', ...
        assignation(1), assignation(2));
assert(assignation(1) == 1, 'la mesure proche est prise');
assert(assignation(2) == 0, 'la lointaine est laissee de cote');

fprintf('\nToutes les verifications passent.\n');
