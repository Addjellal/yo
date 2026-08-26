% test_apprentissage.m — réseaux de neurones et vision par ordinateur.
% Les réseaux sont vérifiés sur des problèmes dont la solution est
% connue : XOR, qu'un perceptron simple ne peut pas résoudre et qu'une
% couche cachée résout exactement. Les fonctions de vision le sont sur
% des géométries calculées à la main.
disp('--- apprentissage ---');

%% --------------------------------------------------------- couches
c = leakyReluLayer(0.1);
assert(strcmp(c.type, 'leakyrelu'));
assert(abs(c.pente - 0.1) < 1e-12);
assert(abs(leakyReluLayer().pente - 0.01) < 1e-12);
assert(abs(eluLayer().alpha - 1) < 1e-12);
assert(abs(dropoutLayer(0.3).probabilite - 0.3) < 1e-12);
assert(strcmp(batchNormalizationLayer().type, 'batchnorm'));
assert(strcmp(classificationLayer().type, 'classification'));
assert(strcmp(regressionLayer().type, 'regression'));
assert(featureInputLayer(5).taille == 5);

%% ------------------------------------------------ XOR, cas d'école
X = [0 0 1 1; 0 1 0 1];
Y = [1 0 0 1; 0 1 1 0];       % classe 1 pour 0, classe 2 pour 1
options = trainingOptions('sgdm', 'MaxEpochs', 4000, ...
                          'InitialLearnRate', 0.5, 'Verbose', false);

couches = {fullyConnectedLayer(8), reluLayer(), fullyConnectedLayer(2), softmaxLayer()};
reseau = trainNetwork(X, Y, couches, options);
p = predict(reseau, X);
[~, classes] = max(p);
assert(isequal(classes, [1 2 2 1]));
assert(crossentropy(p, Y) < 0.01);
% Les colonnes du softmax somment à 1.
assert(max(abs(sum(p, 1) - 1)) < 1e-12);

% La couche de sortie de MATLAB ne change rien au résultat : elle ne fait
% que déclarer le coût.
avecSortie = {fullyConnectedLayer(8), reluLayer(), fullyConnectedLayer(2), ...
              softmaxLayer(), classificationLayer()};
reseau2 = trainNetwork(X, Y, avecSortie, options);
[~, classes2] = max(predict(reseau2, X));
assert(isequal(classes2, [1 2 2 1]));

% ReLU à fuite et ELU résolvent aussi le problème.
for activation = {leakyReluLayer(0.1), eluLayer()}
    couches3 = {fullyConnectedLayer(8), activation{1}, fullyConnectedLayer(2), softmaxLayer()};
    [~, c3] = max(predict(trainNetwork(X, Y, couches3, options), X));
    assert(isequal(c3, [1 2 2 1]));
end

% Normalisation par lot : le réseau apprend toujours, et la couche est
% transparente en prédiction quand elle n'a pas vu de lot.
couches4 = {fullyConnectedLayer(8), batchNormalizationLayer(), reluLayer(), ...
            fullyConnectedLayer(2), softmaxLayer()};
[~, c4] = max(predict(trainNetwork(X, Y, couches4, options), X));
assert(isequal(c4, [1 2 2 1]));

% Régression : approcher la fonction identité sur [0,1].
t = linspace(0, 1, 21);
couchesR = {fullyConnectedLayer(10), tanhLayer(), fullyConnectedLayer(1), regressionLayer()};
optionsR = trainingOptions('sgdm', 'MaxEpochs', 3000, ...
                           'InitialLearnRate', 0.1, 'Verbose', false);
reseauR = trainNetwork(t, t, couchesR, optionsR);
assert(mse(predict(reseauR, t), t) < 0.01);

%% ------------------------------------------- couches convolutives
% Constructeurs.
c = convolution2dLayer(3, 8, 'Padding', 'same', 'Stride', 2);
assert(strcmp(c.type, 'conv2d'));
assert(isequal(c.taille, [3 3]));
assert(c.filtres == 8);
assert(isequal(c.pas, [2 2]));
assert(strcmp(c.marge, 'same'));
assert(isequal(convolution2dLayer([2 5], 1).taille, [2 5]));
assert(isequal(convolution2dLayer(3, 1).pas, [1 1]));
assert(isequal(maxPooling2dLayer(2).pas, [2 2]));       % pas = taille par défaut
assert(isequal(maxPooling2dLayer(3, 'Stride', 1).pas, [1 1]));
assert(strcmp(averagePooling2dLayer(2).type, 'avgpool'));
assert(strcmp(flattenLayer().type, 'flatten'));
assert(isequal(imageInputLayer([8 8]).taille, [8 8 1]));

% Convolution à noyau connu : x = reshape(1:16,4,4), noyau de uns 3x3.
% La sortie vaut la somme de chaque bloc 3x3, calculée à la main.
c = convolution2dLayer(3, 1);
c.W = ones(3, 3, 1, 1);
c.b = 0;
x = reshape(1:16, 4, 4);
y = couchesConvolution('avant', c, x);
assert(isequal(size(y), [2 2]));
assert(isequal(y, [54 90; 63 99]));

% Le biais s'ajoute à tout le plan.
c.b = 10;
assert(isequal(couchesConvolution('avant', c, x), [64 100; 73 109]));

% 'same' conserve la taille quand le pas vaut 1 ; sinon elle diminue.
c2 = convolution2dLayer(3, 2, 'Padding', 'same');
c2.W = zeros(3, 3, 1, 2);
c2.b = zeros(1, 2);
assert(isequal(size(couchesConvolution('avant', c2, zeros(6, 5))), [6 5 2]));
c3 = convolution2dLayer(2, 1, 'Stride', 2);
c3.W = ones(2, 2);
c3.b = 0;
assert(isequal(size(couchesConvolution('avant', c3, zeros(6, 6))), [3 3]));

% Agrégation : valeurs exactes sur reshape(1:16,4,4).
assert(isequal(couchesConvolution('avant', maxPooling2dLayer(2), x), [6 14; 8 16]));
assert(isequal(couchesConvolution('avant', averagePooling2dLayer(2), x), ...
               [3.5 11.5; 5.5 13.5]));
% Fenêtres qui se recouvrent : pas de 1 sur une fenêtre de 2.
assert(isequal(couchesConvolution('avant', maxPooling2dLayer(2, 'Stride', 1), x), ...
               [6 10 14; 7 11 15; 8 12 16]));

% Aplatissement : aller-retour exact sur un tableau 4-D.
img = reshape(1:24, 2, 3, 2, 2);
[plat, aplati] = couchesConvolution('avant', flattenLayer(), img);
assert(isequal(size(plat), [12 2]));
assert(isequal(aplati.forme, [2 3 2 2]));
assert(isequal(couchesConvolution('arriere', aplati, [], plat, plat), img));

% Le maximum ne renvoie le gradient qu'au pixel gagnant.
p = maxPooling2dLayer(2);
yp = couchesConvolution('avant', p, x);
dp = couchesConvolution('arriere', p, x, yp, ones(2));
assert(isequal(dp, [0 0 0 0; 0 1 0 1; 0 0 0 0; 0 1 0 1]));
% La moyenne le répartit également.
a = averagePooling2dLayer(2);
ya = couchesConvolution('avant', a, x);
assert(max(max(abs(couchesConvolution('arriere', a, x, ya, ones(2)) - 0.25))) < 1e-15);

% Gradients de la convolution vérifiés par différences finies centrées.
rand('seed', 7);
cg = convolution2dLayer([2 3], 2);
xg = rand(5, 4, 2, 3);
[yg, cg] = couchesConvolution('avant', cg, xg);
assert(isequal(size(yg), [4 2 2 3]));
g = rand(size(yg));
[dx, gW, gB] = couchesConvolution('arriere', cg, xg, yg, g);
cout = @(t) sum(t(:) .* g(:));
h = 1e-6;
ecart = 0;
for k = 1:numel(xg)
    xplus = xg;  xplus(k)  = xplus(k)  + h;
    xmoins = xg; xmoins(k) = xmoins(k) - h;
    num = (cout(couchesConvolution('avant', cg, xplus)) - ...
           cout(couchesConvolution('avant', cg, xmoins))) / (2 * h);
    ecart = max(ecart, abs(num - dx(k)));
end
assert(ecart < 1e-7);
ecart = 0;
for k = 1:numel(cg.W)
    cplus = cg;  cplus.W(k)  = cplus.W(k)  + h;
    cmoins = cg; cmoins.W(k) = cmoins.W(k) - h;
    num = (cout(couchesConvolution('avant', cplus, xg)) - ...
           cout(couchesConvolution('avant', cmoins, xg))) / (2 * h);
    ecart = max(ecart, abs(num - gW(k)));
end
assert(ecart < 1e-7);
ecart = 0;
for k = 1:numel(cg.b)
    cplus = cg;  cplus.b(k)  = cplus.b(k)  + h;
    cmoins = cg; cmoins.b(k) = cmoins.b(k) - h;
    num = (cout(couchesConvolution('avant', cplus, xg)) - ...
           cout(couchesConvolution('avant', cmoins, xg))) / (2 * h);
    ecart = max(ecart, abs(num - gB(k)));
end
assert(ecart < 1e-7);

% Action inconnue : erreur identifiée.
essai = false;
try
    couchesConvolution('milieu', flattenLayer(), 1);
catch err
    essai = strcmp(err.identifier, 'nnet:couchesConvolution:UnknownAction');
end
assert(essai);

%% ----------------------------- réseau convolutif de bout en bout
% Barres verticales contre barres horizontales dans des images 8x8 : une
% couche dense seule y arriverait aussi, mais on vérifie ici que la pile
% entrée-image / convolution / ReLU / agrégation / aplatissement /
% dense / softmax s'apprend et prédit sans erreur.
rand('seed', 3);
nImages = 24;
Ximg = zeros(8, 8, 1, nImages);
Yimg = zeros(2, nImages);
for k = 1:nImages
    plan = zeros(8);
    if mod(k, 2) == 1
        plan(:, mod(k, 6) + 2) = 1;
        Yimg(1, k) = 1;
    else
        plan(mod(k, 6) + 2, :) = 1;
        Yimg(2, k) = 1;
    end
    Ximg(:, :, 1, k) = plan;
end
couchesConv = {imageInputLayer([8 8 1]), convolution2dLayer(3, 4, 'Padding', 'same'), ...
               reluLayer(), maxPooling2dLayer(2), flattenLayer(), ...
               fullyConnectedLayer(2), softmaxLayer(), classificationLayer()};
optionsConv = trainingOptions('sgdm', 'MaxEpochs', 120, 'InitialLearnRate', 0.05, ...
                              'MiniBatchSize', 8, 'Verbose', false);
reseauConv = trainNetwork(Ximg, Yimg, couchesConv, optionsConv);
% La couche d'entrée d'image ne transforme rien : elle est retirée, la
% convolution garde ses poids appris.
assert(numel(reseauConv.couches) == 6);
assert(reseauConv.spatial);
assert(isequal(reseauConv.entree, [8 8 1]));
assert(isequal(size(reseauConv.couches{1}.W), [3 3 1 4]));
pConv = predict(reseauConv, Ximg);
assert(isequal(size(pConv), [2 nImages]));
[~, obtenu] = max(pConv);
[~, attendu] = max(Yimg);
assert(isequal(obtenu, attendu));
assert(crossentropy(pConv, Yimg) < 0.05);
assert(max(abs(sum(pConv, 1) - 1)) < 1e-12);
assert(isequal(classify(reseauConv, Ximg)', obtenu));
% Une seule image passe aussi.
assert(isequal(size(predict(reseauConv, Ximg(:, :, :, 1))), [2 1]));

% L'agrégation par moyenne donne un réseau qui apprend également.
couchesMoy = {imageInputLayer([8 8 1]), convolution2dLayer(3, 4, 'Padding', 'same'), ...
              reluLayer(), averagePooling2dLayer(2), flattenLayer(), ...
              fullyConnectedLayer(2), softmaxLayer(), classificationLayer()};
[~, obtenuMoy] = max(predict(trainNetwork(Ximg, Yimg, couchesMoy, optionsConv), Ximg));
assert(isequal(obtenuMoy, attendu));

%% ----------------------------------------------- vision : géométrie
assert(isequal(bbox2points([1 2 10 20]), [1 2; 11 2; 11 22; 1 22]));
assert(isequal(bboxresize([1 1 10 20], 2), [2 2 20 40]));
assert(isequal(bboxresize([2 4 10 20], [0.5 2]), [4 2 20 10]));

% Recouvrement : une boîte avec elle-même vaut 1, deux boîtes disjointes 0.
assert(abs(bboxOverlapRatio([1 1 10 10], [1 1 10 10]) - 1) < 1e-12);
assert(abs(bboxOverlapRatio([1 1 10 10], [50 50 10 10])) < 1e-12);
% Deux carrés de côté 10 décalés de 5 : intersection 25, union 175.
assert(abs(bboxOverlapRatio([0 0 10 10], [5 5 10 10]) - 25 / 175) < 1e-9);

m = bboxOverlapRatioMatrix([1 1 10 10], [1 1 10 10; 50 50 10 10]);
assert(isequal(size(m), [1 2]));
assert(abs(m(1) - 1) < 1e-12 && abs(m(2)) < 1e-12);

% Suppression des non-maxima : deux boîtes qui se recouvrent fortement se
% réduisent à une, la troisième reste.
boites = [1 1 10 10; 2 2 10 10; 50 50 10 10];
[gardees, scores] = selectStrongestBbox(boites, [0.9; 0.8; 0.7]);
assert(size(gardees, 1) == 2);
assert(abs(scores(1) - 0.9) < 1e-12);

[choisis, indices] = selectStrongest([1 2; 3 4; 5 6], [0.1; 0.9; 0.5], 2);
assert(isequal(choisis, [3 4; 5 6]));
assert(isequal(indices(:)', [2 3]));

% Marqueur : l'image devient couleur et le pixel visé est peint.
img = insertMarker(zeros(20), [10 10], 'plus', 'Color', [1 0 0], 'Size', 2);
assert(isequal(size(img), [20 20 3]));
assert(abs(img(10, 10, 1) - 1) < 1e-12);
assert(abs(img(10, 10, 2)) < 1e-12);
assert(abs(img(1, 1, 1)) < 1e-12);      % le reste n'a pas bougé

%% ------------------------------------- vision : images intégrales
% La somme d'un rectangle se lit en quatre accès.
tableIntegrale = integralImage(ones(3));
assert(isequal(size(tableIntegrale), [4 4]));
assert(tableIntegrale(end, end) == 9);
assert(tableIntegrale(3, 3) - tableIntegrale(1, 3) - tableIntegrale(3, 1) + tableIntegrale(1, 1) == 4);
integraleMagique = integralImage(magic(5));
assert(abs(integraleMagique(end, end) - sum(sum(magic(5)))) < 1e-12);
noyauCarre = struct('BoundingBoxes', [1 1 3 3], 'Weights', 1);
reponseIntegrale = integralFilter(integralImage(ones(5)), noyauCarre);
assert(isequal(size(reponseIntegrale), [3 3]));
assert(abs(reponseIntegrale(1) - 9) < 1e-12);
% Filtre à deux rectangles : détecte un bord vertical.
noyauBord = struct('BoundingBoxes', [1 1 2 2; 3 1 2 2], 'Weights', [1 -1]);
assert(all(integralFilter(integralImage([ones(4, 2) zeros(4, 2)]), noyauBord) == 4));

%% ------------------------------------------ vision : points d'intérêt
% Un carré blanc sur fond noir a quatre coins, et le détecteur de
% Shi-Tomasi les trouve tous les quatre.
carre = zeros(20);
carre(6:15, 6:15) = 1;
coinsMinEigen = detectMinEigenFeatures(carre);
assert(size(coinsMinEigen, 1) == 4);
coinsTries = sortrows(coinsMinEigen);
assert(max(max(abs(coinsTries - [7 7; 7 14; 14 7; 14 14]))) <= 1);
% Sélection uniforme : les points retenus couvrent toute l'image.
rng(2);
pointsDenses = rand(500, 2) * 100;
retenus = selectUniform(pointsDenses, 20, [100 100]);
assert(size(retenus, 1) == 20);
assert(min(retenus(:, 1)) < 25 && max(retenus(:, 1)) > 75);

%% ------------------------------------------------ vision : descripteurs
% HOG : la longueur suit la formule de Dalal et Triggs, et chaque bloc est
% normalisé à un.
descripteurHog = extractHOGFeatures(zeros(64, 64));
assert(numel(descripteurHog) == 1764);
[descripteur32, dispositionHog] = extractHOGFeatures(rand(32, 32));
assert(numel(descripteur32) == prod(dispositionHog.NumBlocks) * ...
       prod(dispositionHog.BlockSize) * dispositionHog.NumBins);
assert(isequal(dispositionHog.NumBlocks, [3 3]));
assert(abs(norm(descripteur32(1:36)) - 1) < 1e-9);
% La normalisation par bloc rend le descripteur insensible au gain.
imageHog = rand(32);
assert(max(abs(extractHOGFeatures(imageHog) - extractHOGFeatures(imageHog * 3))) < 1e-12);
% LBP : la longueur vaut P*(P-1)+3 par cellule, ou P+2 si l'on demande
% l'invariance par rotation.
assert(numel(extractLBPFeatures(rand(32))) == 59);
assert(numel(extractLBPFeatures(rand(32), 'Upright', false)) == 10);
assert(numel(extractLBPFeatures(rand(32), 'CellSize', [16 16])) == 236);
assert(abs(norm(extractLBPFeatures(rand(32))) - 1) < 1e-9);
% Avec quatre voisins, tous sur des positions entières, le motif ne dépend
% que de l'ordre des intensités : une transformation monotone ne change
% rien.
textureLbp = rand(24);
assert(max(abs(extractLBPFeatures(textureLbp, 'NumNeighbors', 4) - ...
               extractLBPFeatures(textureLbp .^ 2, 'NumNeighbors', 4))) < 1e-12);

%% ------------------------------------- vision : géométrie épipolaire
% Rodrigues : aller-retour exact, matrice orthogonale de déterminant un.
matriceRotation = rotationVectorToMatrix([0 0 pi/2]);
assert(max(abs(matriceRotation * [1; 0; 0] - [0; 1; 0])) < 1e-12);
assert(norm(matriceRotation * matriceRotation' - eye(3)) < 1e-12);
assert(abs(det(matriceRotation) - 1) < 1e-12);
vecteurRotation = [0.1 0.2 0.3];
assert(max(abs(rotationMatrixToVector(rotationVectorToMatrix(vecteurRotation)) - vecteurRotation)) < 1e-12);
assert(isequal(rotationMatrixToVector(eye(3)), [0 0 0]));
assert(max(abs(rotationMatrixToVector(rotationVectorToMatrix([pi 0 0])) - [pi 0 0])) < 1e-6);

% Scène synthétique : deux vues d'un nuage de points.
rng(3);
nuage3D = [rand(30, 1) * 4 - 2, rand(30, 1) * 4 - 2, rand(30, 1) * 3 + 5];
projection1 = [eye(3), zeros(3, 1)];
projection2 = [rotationVectorToMatrix([0 0.05 0]), [-1; 0.1; 0]];
homogene1 = (projection1 * [nuage3D ones(30, 1)]')';
vue1 = homogene1(:, 1:2) ./ [homogene1(:, 3) homogene1(:, 3)];
homogene2 = (projection2 * [nuage3D ones(30, 1)]')';
vue2 = homogene2(:, 1:2) ./ [homogene2(:, 3) homogene2(:, 3)];
matriceFondamentale = estimateFundamentalMatrix(vue1, vue2);
% La contrainte épipolaire est vérifiée, et la matrice est de rang deux.
assert(max(abs(sum(([vue2 ones(30, 1)] * matriceFondamentale) .* [vue1 ones(30, 1)], 2))) < 1e-10);
assert(min(svd(matriceFondamentale)) < 1e-12);
assert(rank(matriceFondamentale, 1e-8) == 2);
% Chaque point de la seconde vue est sur la droite épipolaire de son
% correspondant.
droitesEpipolaires = epipolarLine(matriceFondamentale, vue1);
assert(max(abs(sum(droitesEpipolaires .* [vue2 ones(30, 1)], 2))) < 1e-10);
assert(all(sqrt(sum(droitesEpipolaires(:, 1:2) .^ 2, 2)) > 1e-9));
% Triangulation : on retrouve le nuage de départ.
[nuageReconstruit, erreursReprojection] = triangulate(vue1, vue2, projection1, projection2);
assert(max(max(abs(nuageReconstruit - nuage3D))) < 1e-10);
assert(max(erreursReprojection) < 1e-10);
assert(max(abs(triangulate([0 0], [-1 0], [eye(3) zeros(3, 1)], [eye(3) [-1; 0; 0]]) - [0 0 1])) < 1e-10);
% Les matrices 4x3 de MATLAB sont acceptées telles quelles.
assert(max(abs(triangulate([0 0], [-1 0], [eye(3) zeros(3, 1)]', [eye(3) [-1; 0; 0]]') - [0 0 1])) < 1e-10);
% MSAC écarte les appariements aberrants.
vueSalie = vue2;
vueSalie(1:5, :) = vueSalie(1:5, :) + 30;
[matriceRobuste, valides] = estimateFundamentalMatrix(vue1, vueSalie, ...
    'Method', 'MSAC', 'DistanceThreshold', 0.01, 'NumTrials', 300);
assert(sum(valides) == 25);
assert(~any(valides(1:5)));
residusPropres = abs(sum(([vue2 ones(30, 1)] * matriceRobuste) .* [vue1 ones(30, 1)], 2));
assert(max(residusPropres(6:end)) < 1e-10);

%% --------------------------------------- vision : stéréo et mouvement
anaglyphe = stereoAnaglyph(zeros(4), ones(4));
assert(isequal(reshape(anaglyphe(1, 1, :), 1, 3), [0 1 1]));
% Disparité : une barre décalée de trois puis de cinq colonnes.
imageGauche = zeros(20, 40);
imageGauche(:, 10:15) = 1;
imageDroite = zeros(20, 40);
imageDroite(:, 7:12) = 1;
carteDisparite = disparityBM(imageGauche, imageDroite, 'BlockSize', 5, 'DisparityRange', [0 8]);
bandeDisparite = carteDisparite(6:15, 11:14);
assert(median(bandeDisparite(:)) == 3);
imageDroite5 = zeros(20, 40);
imageDroite5(:, 5:10) = 1;
carte5 = disparityBM(imageGauche, imageDroite5, 'BlockSize', 5, 'DisparityRange', [0 8]);
bande5 = carte5(6:15, 11:14);
assert(median(bande5(:)) == 5);
% Horn et Schunck : sur un motif lisse décalé d'un pixel, le champ
% retrouve le déplacement dans les deux directions.
[grilleX, grilleY] = meshgrid(1:40, 1:40);
motifA = sin(2 * pi * grilleX / 12) .* sin(2 * pi * grilleY / 12);
motifDecaleX = sin(2 * pi * (grilleX - 1) / 12) .* sin(2 * pi * grilleY / 12);
[flotX, flotY] = opticalFlowHS(motifA, motifDecaleX, 'MaxIteration', 300, 'Smoothness', 0.5);
assert(abs(mean(mean(flotX(10:30, 10:30))) - 1) < 0.05);
assert(abs(mean(mean(flotY(10:30, 10:30)))) < 0.05);
motifDecaleY = sin(2 * pi * grilleX / 12) .* sin(2 * pi * (grilleY - 1) / 12);
[flotX2, flotY2] = opticalFlowHS(motifA, motifDecaleY, 'MaxIteration', 300, 'Smoothness', 0.5);
assert(abs(mean(mean(flotY2(10:30, 10:30))) - 1) < 0.05);
assert(abs(mean(mean(flotX2(10:30, 10:30)))) < 0.05);
assert(~any(any(isnan(flotX))));

%% ---------------------------------------- vision : appariement optimal
% Le cas glouton et le cas optimal diffèrent : l'algorithme hongrois
% trouve le minimum global.
[appariements, pistesLibres, detectionsLibres] = assignDetectionsToTracks([1 100; 100 2], 50);
assert(isequal(appariements, [1 1; 2 2]));
assert(isempty(pistesLibres) && isempty(detectionsLibres));
coutsTrois = [4 1 3; 2 0 5; 3 2 2];
appariementsTrois = assignDetectionsToTracks(coutsTrois, 100);
coutTotal = 0;
for k = 1:size(appariementsTrois, 1)
    coutTotal = coutTotal + coutsTrois(appariementsTrois(k, 1), appariementsTrois(k, 2));
end
assert(coutTotal == 5);
% Vérification exhaustive sur une matrice cinq par cinq.
rng(4);
coutsCinq = round(rand(5) * 20);
appariementsCinq = assignDetectionsToTracks(coutsCinq, 1000);
coutMunkres = 0;
for k = 1:size(appariementsCinq, 1)
    coutMunkres = coutMunkres + coutsCinq(appariementsCinq(k, 1), appariementsCinq(k, 2));
end
toutesPermutations = perms(1:5);
coutOptimal = Inf;
for k = 1:size(toutesPermutations, 1)
    somme = 0;
    for i = 1:5
        somme = somme + coutsCinq(i, toutesPermutations(k, i));
    end
    coutOptimal = min(coutOptimal, somme);
end
assert(coutMunkres == coutOptimal);
% Au-delà du coût de non-appariement, mieux vaut laisser seul.
[appariementsChers, pistesSeules, detectionsSeules] = assignDetectionsToTracks([1 100; 100 200], 50);
assert(isequal(appariementsChers, [1 1]));
assert(isequal(pistesSeules', 2) && isequal(detectionsSeules', 2));
[~, ~, detectionsRestantes] = assignDetectionsToTracks([1 100 100], 50);
assert(isequal(detectionsRestantes', [2 3]));

%% ------------------------------------ vision : transformations et boîtes
pointsDamier = generateCheckerboardPoints([3 4], 10);
assert(isequal(size(pointsDamier), [6 2]));
assert(isequal(pointsDamier(1, :), [0 0]));
assert(isequal(sort(unique(pointsDamier(:, 1)))', [0 10 20]));
% Transformations exactes : similitude, affine, projective.
sourceTransfo = [0 0; 1 0; 0 1; 2 2; 3 1];
cibleSimilitude = sourceTransfo * 2 + 3;
transfoSimilitude = estimateGeometricTransform2D(sourceTransfo, cibleSimilitude, 'similarity');
assert(max(max(abs([sourceTransfo ones(5, 1)] * transfoSimilitude - [cibleSimilitude ones(5, 1)]))) < 1e-10);
cibleAffine = sourceTransfo * [2 0; 1 3] + [1 -2];
transfoAffine = estimateGeometricTransform2D(sourceTransfo, cibleAffine, 'affine');
assert(max(max(abs([sourceTransfo ones(5, 1)] * transfoAffine - [cibleAffine ones(5, 1)]))) < 1e-10);
homographie = [1 0.2 0.001; -0.1 1.1 0.002; 3 -2 1];
sourceProjective = [0 0; 10 0; 10 10; 0 10; 5 3];
homogeneProjective = [sourceProjective ones(5, 1)] * homographie;
cibleProjective = homogeneProjective(:, 1:2) ./ [homogeneProjective(:, 3) homogeneProjective(:, 3)];
transfoProjective = estimateGeometricTransform2D(sourceProjective, cibleProjective, 'projective');
verifProjective = [sourceProjective ones(5, 1)] * transfoProjective;
assert(max(max(abs(verifProjective(:, 1:2) ./ [verifProjective(:, 3) verifProjective(:, 3)] - cibleProjective))) < 1e-9);
% Précision et rappel d'une détection de boîtes.
[precisionParfaite, rappelParfait] = bboxPrecisionRecall([10 10 20 20], [10 10 20 20]);
assert(precisionParfaite == 1 && rappelParfait == 1);
[precisionFausse, rappelFausse] = bboxPrecisionRecall([10 10 20 20; 100 100 5 5], [10 10 20 20]);
assert(abs(precisionFausse - 0.5) < 1e-12 && rappelFausse == 1);
[precisionManquee, rappelManque] = bboxPrecisionRecall([10 10 20 20], [10 10 20 20; 60 60 10 10]);
assert(precisionManquee == 1 && abs(rappelManque - 0.5) < 1e-12);

disp('apprentissage : toutes les verifications passent');
