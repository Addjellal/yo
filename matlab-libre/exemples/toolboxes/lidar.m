%% Lidar : du balayage au nuage, du nuage au modèle
% Un lidar rend des distances et des angles. Tout le travail consiste à en
% faire de la géométrie : passer en cartésien, alléger le nuage, y trouver
% les surfaces, et recaler deux relevés l'un sur l'autre.
%
% Voir aussi POINTCLOUDFROMRANGES, VOXELDOWNSAMPLE, FITPLANERANSAC, ICPREGISTER.

fprintf('=== Lidar ===\n');

%% 1. Du balayage polaire au nuage cartésien
% Cas d'école : un mur droit à deux mètres devant le capteur. En polaire
% la distance croît avec l'angle — d = 2/cos(theta) — et c'est en
% cartésien que le mur redevient une droite.
angles = deg2rad(-40:0.5:40);
distances = 2 ./ cos(angles);
points = pointCloudFromRanges(distances, angles);
fprintf('\nMur droit a 2 m, balaye sur %g degres :\n', ...
        rad2deg(angles(end) - angles(1)));
fprintf('  distance mesuree : %.3f m au centre, %.3f m au bord\n', ...
        distances(round(end/2)), distances(end));
fprintf('  en cartesien : x varie de %.4f a %.4f m\n', ...
        min(points(:,1)), max(points(:,1)));
assert(max(abs(points(:,1) - 2)) < 1e-12, 'le mur est bien a x = 2, partout');
assert(max(abs(points(:,2) - 2 * tan(angles(:)))) < 1e-12, ...
       'et y suit la tangente de l''angle');
% La conversion conserve la distance à l'origine : c'est un changement de
% coordonnées, rien de plus.
assert(max(abs(hypot(points(:,1), points(:,2)) - distances(:))) < 1e-12, ...
       'la conversion conserve les distances');

%% 2. Alléger le nuage
% Un lidar produit bien plus de points qu'il n'en faut. Le sous-
% échantillonnage par voxels garde un point par cellule, au barycentre :
% la densité s'égalise sans que la forme bouge.
rng(5);
dense = [randn(600, 2) * 0.3; randn(600, 2) * 0.3 + [3 0]];
reduits = voxelDownsample(dense, 0.25);
fprintf('\nSous-echantillonnage par voxels de %g m :\n', 0.25);
fprintf('  %d points -> %d points (%.1f %% gardes)\n', ...
        size(dense, 1), size(reduits, 1), 100 * size(reduits,1) / size(dense,1));
assert(size(reduits, 1) < size(dense, 1) / 3, 'le nuage doit maigrir nettement');
% Les deux amas restent séparés, et à la même place.
gauche = reduits(reduits(:,1) < 1.5, :);
droite = reduits(reduits(:,1) >= 1.5, :);
fprintf('  barycentres : (%.3f, %.3f) et (%.3f, %.3f)\n', ...
        mean(gauche(:,1)), mean(gauche(:,2)), mean(droite(:,1)), mean(droite(:,2)));
assert(abs(mean(gauche(:,1))) < 0.15 && abs(mean(droite(:,1)) - 3) < 0.15, ...
       'les deux amas restent ou ils etaient');
% Deux points d'une même cellule ne peuvent pas survivre tous les deux :
% c'est la garantie de la méthode.
distances2 = pdist2(reduits, reduits);
distances2(1:size(reduits,1)+1:end) = inf;
fprintf('  plus proche paire restante : %.4f m (cellule : %g m)\n', ...
        min(distances2(:)), 0.25);
assert(min(distances2(:)) > 1e-6, 'aucun point en double');
% Une cellule plus grosse laisse moins de points : la relation est
% monotone, et c'est le seul réglage de la méthode.
precedent = size(dense, 1);
for taille = [0.1 0.25 0.5 1.0]
    r = voxelDownsample(dense, taille);
    fprintf('  cellule %.2f m : %d points\n', taille, size(r, 1));
    assert(size(r, 1) < precedent, 'une cellule plus grosse garde moins de points');
    precedent = size(r, 1);
end

%% 3. Trouver la surface dominante malgré les points parasites
% RANSAC tire des échantillons au hasard, garde le modèle qui rallie le
% plus de points, et laisse les autres dehors. C'est ce qui le rend
% insensible aux points aberrants là où les moindres carrés cèdent.
rng(2);
n = 300;
t = linspace(0, 5, n).';
sol = [t, 0.2 * t + 1 + 0.01 * randn(n, 1)];      % une droite, peu bruitee
parasites = [rand(120, 1) * 5, rand(120, 1) * 4];  % du fouillis partout
nuage = [sol; parasites];

[modele, inliers] = fitPlaneRansac(nuage, 0.05, 500);
pente = -modele(1) / modele(2);
ordonnee = -modele(3) / modele(2);
fprintf('\nRANSAC sur %d points dont %d parasites :\n', ...
        size(nuage, 1), size(parasites, 1));
fprintf('  droite trouvee : y = %.4f x + %.4f (vraie : 0.2 x + 1)\n', ...
        pente, ordonnee);
fprintf('  %d points retenus sur %d\n', numel(inliers), size(nuage, 1));
assert(abs(pente - 0.2) < 0.03, 'la pente est retrouvee');
assert(abs(ordonnee - 1) < 0.05, 'l''ordonnee a l''origine aussi');
assert(numel(inliers) > 0.9 * n, 'presque tous les points du sol sont retenus');
assert(numel(inliers) < n + 0.3 * size(parasites, 1), ...
       'et peu de parasites ramasses au passage');

% Ce que les moindres carrés en font, eux : les parasites tirent la droite
% et la faussent. C'est tout l'argument de RANSAC en un chiffre.
moindresCarres = [nuage(:,1), ones(size(nuage,1),1)] \ nuage(:,2);
fprintf('  par moindres carres sur tout : y = %.4f x + %.4f\n', ...
        moindresCarres(1), moindresCarres(2));
assert(abs(moindresCarres(1) - 0.2) > 3 * abs(pente - 0.2), ...
       'les moindres carres se laissent tirer par les parasites');

% En trois dimensions, c'est un plan. Même méthode, même robustesse.
rng(4);
plan = [rand(300, 2) * 4, zeros(300, 1)];
plan(:, 3) = 0.3 * plan(:, 1) - 0.2 * plan(:, 2) + 0.5 + 0.01 * randn(300, 1);
nuage3 = [plan; rand(80, 3) .* [4 4 3]];
[modele3, inliers3] = fitPlaneRansac(nuage3, 0.05, 800);
normale = modele3(1:3) / norm(modele3(1:3));
attendue = [0.3; -0.2; -1] / norm([0.3; -0.2; -1]);
fprintf('  en 3-D : normale [%.4f %.4f %.4f], attendue [%.4f %.4f %.4f]\n', ...
        normale(1), normale(2), normale(3), attendue(1), attendue(2), attendue(3));
assert(min(norm(normale - attendue), norm(normale + attendue)) < 0.03, ...
       'la normale du plan est retrouvee (au signe pres)');
assert(numel(inliers3) > 280, 'et presque tout le plan est retenu');

%% 4. Recaler deux relevés
% Un robot qui a bougé revoit la même scène sous un autre angle. ICP
% cherche la rotation et la translation qui les superposent, en alternant
% appariement au plus proche voisin et recalage optimal.
%
% Cas d'école : on prend un nuage, on lui applique une transformation
% connue, et ICP doit la retrouver exactement.
rng(8);
forme = [cos(linspace(0, 2*pi, 60)).', sin(linspace(0, 2*pi, 60)).'] .* [2 1];
forme = forme + 0.05 * randn(size(forme));
angleVrai = deg2rad(12);
Rvrai = [cos(angleVrai) -sin(angleVrai); sin(angleVrai) cos(angleVrai)];
tVrai = [0.4 -0.25];
cible = (Rvrai * forme.').' + tVrai;

[R, t, erreur] = icpRegister(forme, cible, 60);
angleTrouve = atan2(R(2,1), R(1,1));
fprintf('\nICP entre deux releves de la meme scene :\n');
fprintf('  rotation vraie %.3f deg, trouvee %.3f deg\n', ...
        rad2deg(angleVrai), rad2deg(angleTrouve));
fprintf('  translation vraie [%.3f %.3f], trouvee [%.3f %.3f]\n', ...
        tVrai(1), tVrai(2), t(1), t(2));
fprintf('  erreur d''appariement residuelle : %.5f m\n', erreur);
assert(abs(rad2deg(angleTrouve - angleVrai)) < 1, 'ICP retrouve la rotation');
assert(norm(t - tVrai) < 0.1, 'et la translation');
assert(norm(R' * R - eye(2)) < 1e-12, 'la transformation trouvee est rigide');
assert(abs(det(R) - 1) < 1e-12, 'sans symetrie ni changement d''echelle');
assert(erreur < 0.05, 'et les nuages se superposent');

% Ce qu'ICP ne peut pas faire : lever une ambiguïté que la géométrie ne
% contient pas. Un cercle parfait est invariant par rotation ; aucune
% méthode d'appariement ne peut dire de combien il a tourné, parce que la
% question n'a pas de réponse. ICP superpose alors parfaitement les deux
% nuages tout en rendant une rotation quelconque.
cercle = [cos(linspace(0, 2*pi, 121)).', sin(linspace(0, 2*pi, 121)).'];
cercle = cercle(1:end-1, :);
angleTrop = deg2rad(37);
Rtrop = [cos(angleTrop) -sin(angleTrop); sin(angleTrop) cos(angleTrop)];
[Rt, ~, erreurTrop] = icpRegister(cercle, (Rtrop * cercle.').', 60);
fprintf('  cercle tourne de %g deg : ICP en trouve %.1f, erreur %.2e\n', ...
        rad2deg(angleTrop), rad2deg(atan2(Rt(2,1), Rt(1,1))), erreurTrop);
assert(erreurTrop < 1e-3, 'les nuages se superposent parfaitement');
assert(abs(rad2deg(atan2(Rt(2,1), Rt(1,1))) - 37) > 5, ...
       'mais la rotation trouvee n''est pas celle appliquee : elle est indecidable');

% Sur la même forme non symétrique, en revanche, un écart de quatre-vingt-
% dix degrés se rattrape encore : la géométrie de l'ellipse suffit à
% guider l'appariement.
angleGrand = deg2rad(90);
Rgrand = [cos(angleGrand) -sin(angleGrand); sin(angleGrand) cos(angleGrand)];
[Rg, ~, erreurGrand] = icpRegister(forme, (Rgrand * forme.').', 60);
fprintf('  ellipse tournee de 90 deg : ICP en trouve %.1f, erreur %.4f\n', ...
        rad2deg(atan2(Rg(2,1), Rg(1,1))), erreurGrand);
assert(abs(rad2deg(atan2(Rg(2,1), Rg(1,1))) - 90) < 2, ...
       'une forme asymetrique donne prise a l''appariement');

% Deux nuages déjà superposés : ICP ne doit rien faire.
[Ri, ti, erreurI] = icpRegister(forme, forme, 10);
fprintf('  sur deux nuages identiques : rotation %.2e deg, translation %.2e m\n', ...
        rad2deg(abs(atan2(Ri(2,1), Ri(1,1)))), norm(ti));
assert(norm(Ri - eye(2)) < 1e-9 && norm(ti) < 1e-9, ...
       'rien a recaler : ICP rend l''identite');
assert(erreurI < 1e-12, 'et une erreur nulle');

fprintf('\nToutes les verifications passent.\n');
