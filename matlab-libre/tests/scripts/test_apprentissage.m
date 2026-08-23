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

disp('apprentissage : toutes les verifications passent');
