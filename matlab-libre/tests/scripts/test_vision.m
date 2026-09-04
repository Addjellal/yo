% test_vision.m — nuages de points, géométrie de la caméra, stéréovision,
% détecteurs de points d'intérêt, flot optique, régions et annotation.
%
% Chaque vérification est une propriété que la géométrie ou l'optique
% impose : une transformation rigide conserve les distances, projeter puis
% relever sur un plan rend le point de départ, corriger la distorsion
% annule ce que l'appliquer a fait, une rectification met les points
% correspondants sur la même ligne, une disparité double vaut une
% profondeur de moitié.
disp('--- vision ---');

rng(7);
% Un nuage se range et se mesure.
xyz = rand(1000, 3);
p = pointCloud(xyz);
fprintf('points : %d\n', p.Count);
assert(p.Count == 1000);
assert(abs(p.XLimits(1) - min(xyz(:,1))) < 1e-12);
assert(abs(p.ZLimits(2) - max(xyz(:,3))) < 1e-12);
% Un nuage organisé se déplie.
organise = pointCloud(reshape(xyz(1:900, :), 30, 30, 3));
assert(organise.Count == 900);
% Transformation rigide : la distance entre points ne change pas.
T = [rotz(30) * roty(20), [1; 2; 3]; 0 0 0 1];
q = pctransform(p, T);
avant = sqrt(sum((xyz(1,:) - xyz(2,:)) .^ 2));
apres = sqrt(sum((q.Location(1,:) - q.Location(2,:)) .^ 2));
fprintf('distance avant %.10f, apres %.10f\n', avant, apres);
assert(abs(avant - apres) < 1e-12);
% Et la transformation inverse ramène au départ.
retour = pctransform(q, inv(T));
assert(max(max(abs(retour.Location - xyz))) < 1e-10);
% Une translation pure déplace le barycentre d'autant.
t = pctransform(p, [eye(3), [1;2;3]; 0 0 0 1]);
assert(max(abs(mean(t.Location) - mean(xyz) - [1 2 3])) < 1e-12);
% Allègement au hasard : la proportion est respectée.
r = pcdownsample(p, 'random', 0.25);
fprintf('tirage au hasard : %d points\n', r.Count);
assert(r.Count == 250);
% Moyenne par grille : moins de points, même étendue à un pas près.
g = pcdownsample(p, 'gridAverage', 0.2);
fprintf('grille de pas 0.2 : %d points (au plus 125 cubes)\n', g.Count);
assert(g.Count < 1000 && g.Count <= 125);
assert(g.XLimits(1) >= p.XLimits(1) - 1e-12);
assert(g.XLimits(2) <= p.XLimits(2) + 1e-12);
% La moyenne par grille réduit le bruit, à condition que le pas dépasse
% l'amplitude du bruit : sinon la grille sépare selon l'axe même qu'on
% voudrait lisser.
plan = [rand(4000, 2) * 10, zeros(4000, 1)];
bruite = plan + [zeros(4000, 2), 0.1 * randn(4000, 1)];
allege = pcdownsample(pointCloud(bruite), 'gridAverage', 1);
fprintf('ecart au plan : brut %.5f, allege %.5f (%d points)\n', ...
        std(bruite(:,3)), std(allege.Location(:,3)), allege.Count);
assert(std(allege.Location(:,3)) < std(bruite(:,3)) / 3);
% Un pas plus petit que le bruit ne lisse pas : la grille découpe selon z.
fin = pcdownsample(pointCloud(bruite), 'gridAverage', 0.05);
assert(std(fin.Location(:,3)) > std(bruite(:,3)) / 1.5);
% Un nombre de points visé est approché.
vise = pcdownsample(pointCloud(rand(5000,3)), 'nonuniformGridSample', 500);
fprintf('vise 500, obtenu %d\n', vise.Count);
assert(abs(vise.Count - 500) < 150);
% Débruitage : les points isolés partent, les autres restent.
propre = randn(1000, 3);
aberrants = 30 * randn(10, 3);
melange = pointCloud([propre; aberrants]);
[nettoye, gardes, rejetes] = pcdenoise(melange, 'NumNeighbors', 6, 'Threshold', 1);
fprintf('rejetes : %d, dont aberrants : %d sur 10\n', numel(rejetes), sum(rejetes > 1000));
assert(sum(rejetes > 1000) >= 9);
assert(nettoye.Count == numel(gardes));
% Fusion : deux nuages identiques fondus donnent le nuage d'origine.
a = pointCloud(rand(200, 3));
fusion = pcmerge(a, a, 1e-6);
fprintf('fusion de deux copies : %d points (attendu 200)\n', fusion.Count);
assert(fusion.Count == 200);
% Normales : sur un plan horizontal, toutes selon z.
plat = pointCloud([rand(400, 2) * 5, zeros(400, 1)]);
n = pcnormals(plat, 8);
fprintf('normales : |z| moyen %.10f\n', mean(abs(n(:,3))));
assert(min(abs(n(:,3))) > 1 - 1e-8);
% Sur un plan incliné, elles suivent l'inclinaison.
incline = [rand(400,2) * 5, zeros(400,1)];
incline(:,3) = 0.5 * incline(:,1);
attendu = [-0.5 0 1] / sqrt(1.25);
ni = pcnormals(pointCloud(incline), 8);
alignement = abs(ni * attendu.');
fprintf('alignement minimal : %.10f\n', min(alignement));
assert(min(alignement) > 1 - 1e-6);
disp('nuages de points : ok');

rng(11);
% Ajustement de plan : le plan trouvé est celui qui a servi à engendrer.
plan = [rand(600, 2) * 10, zeros(600, 1)];
plan(:, 3) = 0.5 * plan(:, 1) - 0.2 * plan(:, 2) + 3 + 0.01 * randn(600, 1);
aberrants = [rand(60, 2) * 10, 20 * rand(60, 1)];
p = pointCloud([plan; aberrants]);
[m, dedans, dehors, err] = pcfitplane(p, 0.05);
% Le plan vrai : 0.5x - 0.2y - z + 3 = 0, normalisé.
vrai = [0.5 -0.2 -1 3] / norm([0.5 -0.2 -1]);
trouve = m.Parameters;
if sign(trouve(3)) ~= sign(vrai(3)), trouve = -trouve; end
fprintf('trouve : %s\n', mat2str(round(trouve, 4)));
fprintf('vrai   : %s\n', mat2str(round(vrai, 4)));
assert(max(abs(trouve - vrai)) < 0.01);
fprintf('dedans %d, dehors %d, erreur %.5f\n', numel(dedans), numel(dehors), err);
assert(numel(dedans) > 580 && numel(dehors) >= 55);
assert(err < 0.02);
% Les aberrants sont bien tous dehors.
assert(all(dehors > 600));
% Une direction imposée : le plan rendu respecte la contrainte, même
% quand elle l'écarte du plan dominant.
contraint = pcfitplane(p, 0.5, [1 0 0], 10);
angle = acos(min(abs(contraint.Normal * [1;0;0]), 1)) * 180 / pi;
fprintf('normale contrainte a %.3f degres de x\n', angle);
assert(angle <= 10 + 1e-9);
% Et une contrainte impossible à satisfaire est refusée.
refuse = false;
try
    pcfitplane(pointCloud([rand(300,2)*10, zeros(300,1)]), 0.05, [1 0 0], 1);
catch e
    refuse = strcmp(e.identifier, 'vision:pcfitplane:Aucun');
end
fprintf('contrainte impossible refusee : %d\n', refuse);
assert(refuse);
% Segmentation par distance : deux amas séparés font deux groupes. Le
% seuil doit dépasser l'écart entre voisins d'un même amas, sans
% atteindre l'écart entre amas.
rng(11);
deux = pointCloud([randn(200, 3); randn(200, 3) + 20]);
[etiquettes, nombre] = pcsegdist(deux, 3);
fprintf('groupes : %d\n', nombre);
assert(nombre == 2);
assert(all(etiquettes(1:200) == etiquettes(1)));
assert(all(etiquettes(201:end) == etiquettes(201)));
assert(etiquettes(1) ~= etiquettes(201));
% Trois amas, dont un minuscule qu'on écarte.
trois = pointCloud([randn(200,3); randn(200,3) + 20; randn(3,3) + 40]);
[e3, n3] = pcsegdist(trois, 3);
assert(n3 == 3);
[e4, n4] = pcsegdist(trois, 3, 'NumClusterPoints', [10 inf]);
fprintf('avec taille minimale : %d groupes, %d points ecartes\n', n4, sum(e4 == 0));
assert(n4 == 2 && sum(e4 == 0) == 3);
% Recalage : la transformation retrouvée est celle qui a servi.
a = pointCloud(rand(400, 3) * 5);
T = [rotz(12) * rotx(7), [0.4; -0.3; 0.2]; 0 0 0 1];
b = pctransform(a, T);
[Trouve, recale, err] = pcregistericp(b, a, 'MaxIterations', 60, 'Tolerance', [1e-10 1e-10]);
fprintf('erreur de recalage : %.3e\n', err);
assert(err < 1e-6);
% La transformation trouvée est l'inverse de celle appliquée.
compose = Trouve * T;
fprintf('ecart a l''identite : %.3e\n', max(max(abs(compose - eye(4)))));
assert(max(max(abs(compose - eye(4)))) < 1e-6);
% Et le nuage recalé coïncide avec l'original.
assert(max(max(abs(recale.Location - a.Location))) < 1e-6);
% Partir de l'identité sur des nuages déjà alignés ne bouge rien.
[Tident, ~, errIdent] = pcregistericp(a, a);
% La distance au carré se calcule par développement, ce qui laisse une
% erreur d'annulation de l'ordre de la racine de l'epsilon machine sur
% une distance nulle.
assert(max(max(abs(Tident - eye(4)))) < 1e-8 && errIdent < 1e-5);
disp('plans, segments et recalage : ok');

rng(3);
c = cameraIntrinsics([800 750], [320 240], [480 640]);
assert(abs(c.FocalLength(1) - 800) < 1e-12 && abs(c.PrincipalPoint(2) - 240) < 1e-12);
% Le centre optique se projette au point principal.
pc = worldToImage(c, eye(3), [0 0 10], [0 0 0]);
fprintf('centre projette en %s\n', mat2str(pc));
assert(max(abs(pc - [320 240])) < 1e-9);
% Un point décalé d'un mètre à dix mètres se projette à f/10 pixels.
p2 = worldToImage(c, eye(3), [0 0 10], [1 0 0]);
fprintf('decalage : %s (attendu %.1f pixels)\n', mat2str(round(p2 - pc, 6)), 800 / 10);
assert(abs(p2(1) - pc(1) - 80) < 1e-9 && abs(p2(2) - pc(2)) < 1e-9);
% Un point derrière la caméra est signalé.
[~, devant] = worldToImage(c, eye(3), [0 0 10], [0 0 -20; 0 0 0]);
assert(isequal(devant(:)', [false true]));
% Aller-retour : projeter puis relever sur le plan z = 0 rend les mêmes
% points.
sol = [rand(50, 2) * 4 - 2, zeros(50, 1)];
R = rotx(160);
t = [0 1 8];
image = worldToImage(c, R, t, sol);
retour = pointsToWorld(c, R, t, image);
fprintf('aller-retour : ecart max %.3e\n', max(max(abs(retour - sol(:, 1:2)))));
assert(max(max(abs(retour - sol(:, 1:2)))) < 1e-9);
% La matrice de projection donne la même chose que worldToImage.
P = cameraMatrix(c, R, t);
homogene = [sol, ones(50, 1)] * P;
parMatrice = homogene(:, 1:2) ./ repmat(homogene(:, 3), 1, 2);
assert(max(max(abs(parMatrice - image))) < 1e-9);
% Distorsion : la corriger annule ce que l'appliquer a fait.
avecCoeff = cameraIntrinsics([800 750], [320 240], [480 640], ...
                             'RadialDistortion', [-0.25 0.08], ...
                             'TangentialDistortion', [0.001 -0.002]);
sol2 = [rand(40, 2) * 6 - 3, zeros(40, 1)];
sansDistorsion = worldToImage(avecCoeff, eye(3), [0 0 10], sol2);
avecDistorsion = worldToImage(avecCoeff, eye(3), [0 0 10], sol2, 'ApplyDistortion', true);
fprintf('deplacement du a la distorsion : %.4f pixels au plus\n', ...
        max(sqrt(sum((avecDistorsion - sansDistorsion) .^ 2, 2))));
assert(max(sqrt(sum((avecDistorsion - sansDistorsion) .^ 2, 2))) > 1);
corriges = undistortPoints(avecDistorsion, avecCoeff);
fprintf('apres correction : ecart max %.3e\n', max(max(abs(corriges - sansDistorsion))));
assert(max(max(abs(corriges - sansDistorsion))) < 1e-8);
% Sans distorsion, la correction ne change rien.
assert(max(max(abs(undistortPoints(image, c) - image))) < 1e-9);
% cameraParameters relit sa matrice.
cp = cameraParameters('IntrinsicMatrix', c.IntrinsicMatrix);
assert(abs(cp.FocalLength(1) - 800) < 1e-12 && abs(cp.PrincipalPoint(1) - 320) < 1e-12);
% Reconstruction : une disparité constante donne un plan à distance
% constante.
Q = [1 0 0 -320; 0 1 0 -240; 0 0 0 800; 0 0 1/0.1 0];
disparites = 20 * ones(6, 8);
xyzScene = reconstructScene(disparites, Q);
profondeurs = xyzScene(:, :, 3);
fprintf('profondeur : %.4f partout (attendu %.4f)\n', profondeurs(1,1), 800 * 0.1 / 20);
assert(max(max(abs(profondeurs - 800 * 0.1 / 20))) < 1e-9);
% Une disparité nulle donne l'infini, signalé par NaN.
disparites(2, 3) = 0;
xyz2 = reconstructScene(disparites, Q);
assert(isnan(xyz2(2, 3, 3)));
% Une disparité deux fois plus grande donne une profondeur deux fois plus
% petite : c'est toute la stéréovision.
xyzLoin = reconstructScene(10 * ones(3, 3), Q);
xyzPres = reconstructScene(20 * ones(3, 3), Q);
assert(abs(xyzLoin(1,1,3) / xyzPres(1,1,3) - 2) < 1e-12);
disp('geometrie de la camera : ok');

rng(11);
% Rectification sans calibrage : deux vues d'une même scène.
K = [800 0 320; 0 800 240; 0 0 1];
angle = 4 * pi / 180;
Rot = [cos(angle) 0 sin(angle); 0 1 0; -sin(angle) 0 cos(angle)];
tr = [-0.5; 0.02; 0.05];
nbPoints = 60;
X = [randn(1, nbPoints) * 0.8; randn(1, nbPoints) * 0.6; 5 + rand(1, nbPoints) * 3];
u1 = K * X;
q1 = [u1(1, :) ./ u1(3, :); u1(2, :) ./ u1(3, :)].';
u2 = K * (Rot * X + repmat(tr, 1, nbPoints));
q2 = [u2(1, :) ./ u2(3, :); u2(2, :) ./ u2(3, :)].';
F = estimateFundamentalMatrix(q1, q2);
residu = max(abs(sum(([q2 ones(nbPoints,1)] * F) .* [q1 ones(nbPoints,1)], 2)));
fprintf('contrainte epipolaire : %.2e\n', residu);
assert(residu < 1e-9);
[T1, T2] = estimateUncalibratedRectification(F, q1, q2, [480 640]);
r1 = matlibre_appliquer_homographie(T1.', q1);
r2 = matlibre_appliquer_homographie(T2.', q2);
ecartLigne = max(abs(r1(:,2) - r2(:,2)));
fprintf('ecart de ligne apres rectification : %.2e pixel\n', ecartLigne);
assert(ecartLigne < 1e-6);
% Les deux images redressées ont même taille et même cadrage.
I1 = zeros(480, 640); I1(200:280, 300:380) = 1;
I2 = zeros(480, 640); I2(200:280, 320:400) = 1;
[J1, J2] = rectifyStereoImages(I1, I2, T1, T2, 'OutputView', 'full');
assert(isequal(size(J1), size(J2)));
[V1, V2] = rectifyStereoImages(I1, I2, T1, T2);
assert(isequal(size(V1), size(V2)));
% La vue valide tient dans la vue complète.
assert(size(V1, 1) <= size(J1, 1) && size(V1, 2) <= size(J1, 2));
% Une transformation identité laisse l'image intacte.
assert(max(max(abs(matlibre_projeter_image(magic(4), eye(3), [1 1 4 4], 0) - magic(4)))) < 1e-10);
disp('rectification : ok');

rng(1);
% Appariement semi-global : une scène décalée de trois colonnes.
motif = imfilter(rand(40, 100), fspecial('gaussian', 7, 1.5), 'replicate');
gauche = motif(:, 11:80);
droite = motif(:, 14:83);
carte = disparitySGM(gauche, droite, 'DisparityRange', [0 16]);
zone = carte(10:30, 25:60);
zone = zone(~isnan(zone));
fprintf('disparite : mediane %.3f, ecart type %.3f (attendu 3)\n', ...
        median(zone), std(zone));
assert(abs(median(zone) - 3) < 0.25);
assert(std(zone) < 0.5);
% Le même décalage se retrouve par appariement de blocs.
blocs = disparityBM(gauche, droite, 'BlockSize', 7, 'DisparityRange', [0 16]);
assert(abs(median(median(blocs(10:30, 25:60))) - 3) < 1);
% Un intervalle qui ne contient pas la disparité ne la trouve pas.
horsPortee = disparitySGM(gauche, droite, 'DisparityRange', [8 24], ...
                          'UniquenessThreshold', 0);
assert(median(median(horsPortee(10:30, 25:60))) >= 8);
% La transformée de recensement ne retient que l'ordre des intensités :
% doubler l'image ne change rien à l'appariement.
carteClaire = disparitySGM(gauche * 2, droite * 2, 'DisparityRange', [0 16]);
zoneClaire = carteClaire(10:30, 25:60);
assert(abs(median(zoneClaire(~isnan(zoneClaire))) - 3) < 0.25);
disp('stereovision : ok');

rng(1);
% Flot optique de Farnebäck : un déplacement imposé est retrouvé.
A = imfilter(rand(60, 60), fspecial('gaussian', 9, 2), 'replicate');
B = matlibre_deplacer_image(A, -3 * ones(60), 2 * ones(60));
[u, v] = opticalFlowFarneback(A, B);
fprintf('flot : u %.3f (attendu 3), v %.3f (attendu -2)\n', ...
        median(median(u(15:45, 15:45))), median(median(v(15:45, 15:45))));
assert(abs(median(median(u(15:45, 15:45))) - 3) < 0.1);
assert(abs(median(median(v(15:45, 15:45))) + 2) < 0.1);
% Deux images identiques ne bougent pas.
[u0, v0] = opticalFlowFarneback(A, A);
assert(max(max(abs(u0))) < 1e-8 && max(max(abs(v0))) < 1e-8);
% L'expansion polynomiale est exacte sur un polynôme du second degré.
[X, Y] = meshgrid(1:11, 1:11);
f = 3 + 2*X - 4*Y + 5*X.^2 + 7*Y.^2 + 6*X.*Y;
[b1, b2, a11, a22, a12] = matlibre_expansion_polynomiale(f, 7);
assert(abs(a11(6,6) - 5) < 1e-9 && abs(a22(6,6) - 7) < 1e-9 && abs(a12(6,6) - 3) < 1e-9);
assert(abs(b1(6,6) - (2 + 10*6 + 6*6)) < 1e-9);
assert(abs(b2(6,6) - (-4 + 14*6 + 6*6)) < 1e-9);
disp('flot optique : ok');

% Régions homogènes : un contour n'est traversé par aucune région.
gris = zeros(60, 60); gris(:, 31:end) = 1;
[L, nombreRegions] = superpixels(gris, 16);
fprintf('superpixels : %d regions\n', nombreRegions);
assert(all(L(:, 30) ~= L(:, 31)));
assert(isequal(unique(L(:)).', 1:nombreRegions));
couleurs = zeros(60, 60, 3);
couleurs(:, :, 1) = 1; couleurs(1:30, :, 1) = 0; couleurs(1:30, :, 2) = 1;
[Lc, nc] = superpixels(couleurs, 25);
assert(all(Lc(30, :) ~= Lc(31, :)));
assert(nc > 5 && nc <= 25);
% Les régions couvrent tout et sont connexes.
assert(all(Lc(:) > 0));
% Le nombre demandé est approché, sans être dépassé de beaucoup.
rng(7);
texture = imfilter(rand(80, 100, 3), fspecial('gaussian', 9, 3), 'replicate');
[Lt, nt] = superpixels(texture, 40);
fprintf('sur une texture : %d regions demandees 40\n', nt);
assert(nt >= 20 && nt <= 60);
tailles = accumarray(Lt(:), 1);
assert(min(tailles) > 8000 / nt / 6);
disp('superpixels : ok');

% Écriture dans une image : la fonte trace ce qu'on lui demande.
motifTexte = matlibre_police_5x7('Ab');
assert(isequal(size(motifTexte), [7 11]));
assert(any(motifTexte(:)));
assert(~any(any(matlibre_police_5x7(' '))));
vide = zeros(60, 200);
ecrite = insertText(vide, [10 20], 'MatLibre', 'FontSize', 14);
assert(isequal(size(ecrite), [60 200 3]));
assert(sum(ecrite(:) > 0.5) > 100);
% Le cartouche est jaune et le texte noir, par défaut.
[lignesTexte, colonnesTexte] = find(all(ecrite < 0.1, 3));
assert(~isempty(lignesTexte));
% L'ancrage place le cartouche là où on le dit.
basDroite = insertText(vide, [100 40], 'ok', 'AnchorPoint', 'RightBottom');
[l2, c2] = find(any(basDroite > 0.1, 3));
assert(max(l2) == 40 && max(c2) == 100);
% Une classe entière reste entière.
enOctets = insertText(uint8(zeros(40, 80)), [5 10], 'x');
assert(isa(enOctets, 'uint8'));
% Annotation : le rectangle est tracé à la couleur demandée.
annotee = insertObjectAnnotation(zeros(80, 140), 'rectangle', ...
                                 [20 30 40 25], 'chat');
assert(max(abs(squeeze(annotee(30, 25, :)).' - [1 1 0])) < 1e-9);
assert(max(abs(squeeze(annotee(55, 25, :)).' - [1 1 0])) < 1e-9);
% Un cercle aussi, et l'étiquette peut être un nombre.
cercle = insertObjectAnnotation(zeros(80, 140), 'circle', [60 40 20], 0.93, ...
                                'Color', 'red');
assert(max(abs(squeeze(cercle(40, 80, :)).' - [1 0 0])) < 1e-9);
% Superposition d'étiquettes : deux régions, deux couleurs, fond intact.
fond = zeros(20, 20);
etiquettesImage = zeros(20, 20);
etiquettesImage(5:10, 5:10) = 1;
etiquettesImage(12:18, 12:18) = 2;
superposee = labeloverlay(fond, etiquettesImage, 'Transparency', 0);
c1 = squeeze(superposee(7, 7, :)).';
c2b = squeeze(superposee(15, 15, :)).';
assert(norm(c1 - c2b) > 0.2);
assert(all(superposee(1, 1, :) == 0));
% Une transparence de moitié mélange à parts égales.
melangee = labeloverlay(ones(20, 20), etiquettesImage, 'Transparency', 0.5);
assert(abs(melangee(7, 7, 1) - (0.5 + 0.5 * c1(1))) < 1e-9);
% Seules les étiquettes retenues sont peintes.
choisie = labeloverlay(fond, etiquettesImage, 'IncludedLabels', 1, 'Transparency', 0);
assert(all(choisie(15, 15, :) == 0));
% Un masque logique est accepté.
assert(any(reshape(labeloverlay(fond, logical(etiquettesImage)), [], 1) > 0));
disp('annotation : ok');

% Détecteurs de points d'intérêt.
% Le score de FAST distingue un coin d'un bord et d'une zone plate.
carre = zeros(21); carre(1:10, 1:10) = 1;
scoreFast = matlibre_score_fast(carre);
assert(scoreFast(10, 10) > 0.5);
assert(scoreFast(10, 5) == 0 && scoreFast(17, 17) == 0);
% Un maximum sur un plateau n'est retenu qu'une fois.
assert(numel(matlibre_maxima_locaux([0 0 0 0; 0 1 1 0; 0 0 0 0], 0.5)) == 1);
% SURF : une tache gaussienne est trouvée en son centre, et son échelle
% croît avec la largeur de la tache.
echellesTrouvees = zeros(1, 3);
sigmas = [3 5 8];
for k = 1:3
    tache = zeros(160);
    tache(80, 80) = 1;
    tache = imfilter(tache, fspecial('gaussian', 8 * sigmas(k) + 1, sigmas(k)), 'replicate');
    tache = tache / max(tache(:));
    [ps, ms, es] = detectSURFFeatures(tache, 'MetricThreshold', 10);
    assert(~isempty(ps));
    assert(max(abs(ps(1, :) - [80 80])) <= 1);
    echellesTrouvees(k) = es(1);
end
fprintf('SURF : echelles %s pour des sigmas %s\n', ...
        mat2str(round(echellesTrouvees, 2)), mat2str(sigmas));
assert(all(diff(echellesTrouvees) > 0));
% La théorie veut que le determinant de la hessienne culmine à sigma sur
% racine de deux : c'est ce qu'on retrouve, à la finesse de la grille
% d'échelles près.
assert(max(abs(echellesTrouvees - sigmas / sqrt(2)) ./ sigmas) < 0.35);
% Une image uniforme ne donne aucun point.
assert(isempty(detectSURFFeatures(zeros(60))));
assert(isempty(detectBRISKFeatures(zeros(60))));
assert(isempty(detectORBFeatures(zeros(60))));
% ORB : les coins d'un carré sont trouvés, à quelques pixels près.
formes = zeros(120);
formes(20:44, 20:44) = 1;
formes(70:100, 70:100) = 1;
formes = imfilter(formes, fspecial('gaussian', 5, 0.8), 'replicate');
coinsVrais = [20 20; 20 44; 44 20; 44 44; 70 70; 70 100; 100 70; 100 100];
[po, mo, oo, eo] = detectORBFeatures(formes);
distances = zeros(size(po, 1), 1);
for k = 1:size(po, 1)
    ecarts = coinsVrais - repmat([po(k, 2), po(k, 1)], size(coinsVrais, 1), 1);
    distances(k) = min(sqrt(sum(ecarts .^ 2, 2)));
end
fprintf('ORB : %d points, distance mediane aux coins %.2f\n', ...
        numel(distances), median(distances));
assert(median(distances) < 4);
assert(all(eo >= 1) && max(eo) > 1);
% L'orientation tourne avec l'image : un quart de tour la décale d'autant.
rayon = zeros(41); rayon(21, 21:41) = 1;
rayon = imfilter(rayon, fspecial('gaussian', 5, 1), 'replicate');
angleDroit = matlibre_orientation_centroide(rayon, 21, 21, 12);
angleTourne = matlibre_orientation_centroide(rot90(rayon), 21, 21, 12);
fprintf('orientation : %.3f puis %.3f apres un quart de tour\n', ...
        angleDroit, angleTourne);
assert(abs(angleDroit) < 0.05);
assert(abs(abs(angleTourne) - pi / 2) < 0.05);
% BRISK : agrandir l'image double l'échelle des points trouvés.
[~, ~, echellesPetite] = detectBRISKFeatures(formes);
[~, ~, echellesGrande] = detectBRISKFeatures(imresize(formes, 2));
fprintf('BRISK : echelle mediane %.2f puis %.2f apres agrandissement\n', ...
        median(echellesPetite), median(echellesGrande));
assert(median(echellesGrande) > 1.5 * median(echellesPetite));
assert(all(ismember(echellesPetite, matlibre_echelles_brisk(4))));
disp('detecteurs : ok');

disp('vision : toutes les verifications passent');
