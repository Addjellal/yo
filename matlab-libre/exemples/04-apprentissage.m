% 04-apprentissage.m — partition, classifieur, réseau de neurones.

rng(42);

% Deux nuages gaussiens, séparés.
n = 60;
nuage1 = [randn(n, 1) * 0.4 + 1, randn(n, 1) * 0.4 + 1];
nuage2 = [randn(n, 1) * 0.4 + 4, randn(n, 1) * 0.4 + 4];
donnees = [nuage1; nuage2];
verite = [ones(n, 1); 2 * ones(n, 1)];

% Partition non supervisée.
[classes, centres] = kmeans(donnees, 2, 'Start', [1 1; 4 4]);
justes = sum(classes == verite);
fprintf('k-moyennes : %d / %d observations bien groupees\n', justes, 2 * n);
fprintf('Centres trouves : %s et %s\n', mat2str(round(centres(1, :), 2)), ...
        mat2str(round(centres(2, :), 2)));

% Analyse en composantes principales.
[coefficients, scores, valeurs, expliquee] = pca(donnees);
fprintf('Premiere composante : %.1f %% de la variance\n', expliquee(1));

% Arbre de décision, appris puis évalué.
arbre = fitctree(donnees, verite);
predit = predicttree(arbre, donnees);
fprintf('Arbre de decision : %.1f %% de bonnes reponses\n', ...
        100 * mean(predit == verite));
M = confusionmat(verite, predit);
fprintf('Matrice de confusion : %s\n', mat2str(M));

% Réseau de neurones sur le OU exclusif.
X = [0 0 1 1; 0 1 0 1];
Y = [1 0 0 1; 0 1 1 0];
couches = {fullyConnectedLayer(8), tanhLayer(), fullyConnectedLayer(2), softmaxLayer()};
options = trainingOptions('sgdm', 'MaxEpochs', 500, 'InitialLearnRate', 0.3, ...
                          'MiniBatchSize', 4);
reseau = trainNetwork(X, Y, couches, options);
sorties = predict(reseau, X);
fprintf('OU exclusif appris, entropie croisee finale : %.5f\n', ...
        crossentropy(sorties, Y));
fprintf('Classes predites : %s\n', mat2str(classify(reseau, X)'));

figure(1);
scatter(donnees(classes == 1, 1), donnees(classes == 1, 2));
hold on;
scatter(donnees(classes == 2, 1), donnees(classes == 2, 2));
hold off;
title('Partition en deux classes');
xlabel('x'); ylabel('y');
grid on;
print('exemple-apprentissage.svg');
fprintf('Figure ecrite dans exemple-apprentissage.svg\n');
