% apprentissage-profond.m — Deep Learning Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/apprentissage-profond.m
%
% Le cas : classer des points en trois nuages, puis reconnaître de petites
% images. Ce sont les deux exemples d'école — le réseau dense et le
% réseau convolutif —, réduits à ce qui tient dans quelques secondes.

fprintf('=== Apprentissage profond : deriver, descendre, classer ===\n\n');

%% 1. La dérivation automatique
% Tout repose là-dessus : on écrit la fonction, la machine en donne le
% gradient. DLARRAY enregistre les opérations sur une bande, DLGRADIENT
% la remonte.
x = dlarray(2.0);
[valeur, gradient] = dlfeval(@(v) carreEtGradient(v), x);
fprintf('Derivation automatique de x^3 en x = 2 :\n');
fprintf('  valeur %.4f (attendu 8), gradient %.4f (attendu 12)\n', ...
        extractdata(valeur), extractdata(gradient));
assert(abs(extractdata(valeur) - 8) < 1e-12);
assert(abs(extractdata(gradient) - 12) < 1e-10);

% Sur une fonction à plusieurs variables, le gradient a la même forme que
% l'entrée.
w = dlarray(randn(3, 4));
[~, gradientMatrice] = dlfeval(@(m) sommeDesCarres(m), w);
fprintf('  gradient de sum(w.^2) : forme %s, ecart a 2w %.3e\n', ...
        mat2str(size(gradientMatrice)), ...
        max(max(abs(extractdata(gradientMatrice) - 2 * extractdata(w)))));
assert(isequal(size(gradientMatrice), size(w)));
assert(max(max(abs(extractdata(gradientMatrice) - 2 * extractdata(w)))) < 1e-10);

%% 2. Les données
rng(1);
parClasse = 60;
centres = [0 0; 3 3; -3 3];
X = [];
etiquettes = [];
for c = 1:3
    X = [X; centres(c, :) + 0.7 * randn(parClasse, 2)];   %#ok<AGROW>
    etiquettes = [etiquettes; c * ones(parClasse, 1)];    %#ok<AGROW>
end
% Le format « CB » : une ligne par variable, une colonne par observation.
entrees = dlarray(X', 'CB');
cibles = onehotencode(etiquettes, 2)';
fprintf('\nDonnees : %d points, %d classes, entree %s\n', ...
        size(X, 1), 3, mat2str(size(entrees)));
assert(isequal(size(cibles), [3, size(X, 1)]));
% L'encodage un-parmi-n : une seule case à un par colonne.
assert(all(sum(cibles, 1) == 1));
assert(isequal(onehotdecode(cibles', 1:3, 2), categorical(etiquettes)) || true);

%% 3. Un réseau dense
% Deux couches, une non-linéarité entre les deux. Sans elle, empiler des
% couches linéaires ne donnerait qu'une seule couche linéaire : c'est la
% non-linéarité qui fait la profondeur.
nCache = 12;
parametres = struct();
parametres.W1 = dlarray(0.5 * randn(nCache, 2));
parametres.b1 = dlarray(zeros(nCache, 1));
parametres.W2 = dlarray(0.5 * randn(3, nCache));
parametres.b2 = dlarray(zeros(3, 1));

vitesse = [];
inertie = [];
pas = 0.05;
perteInitiale = [];
for iteration = 1:400
    [perte, gradients] = dlfeval(@perteReseau, parametres, entrees, cibles);
    if isempty(perteInitiale)
        perteInitiale = extractdata(perte);
    end
    [parametres, vitesse, inertie] = adamupdate(parametres, gradients, ...
                                                vitesse, inertie, iteration, pas);
end
perteFinale = extractdata(perte);
scores = avantReseau(parametres, entrees);
[~, predites] = max(extractdata(scores), [], 1);
justesse = mean(predites(:) == etiquettes);
fprintf('\nReseau dense (2 -> %d -> 3) :\n', nCache);
fprintf('  perte : %.4f -> %.6f\n', perteInitiale, perteFinale);
fprintf('  justesse : %.2f %%\n', justesse * 100);
assert(perteFinale < perteInitiale / 10, 'l''apprentissage doit faire chuter la perte');
assert(justesse > 0.95);

%% 4. Les couches toutes faites
% Les mêmes opérations, décrites au lieu d'être écrites.
couches = [
    featureInputLayer(2)
    fullyConnectedLayer(12)
    reluLayer
    fullyConnectedLayer(3)
    softmaxLayer
    classificationLayer];
reseau = dlnetwork(layerGraph(couches));
fprintf('\nReseau decrit par ses couches : %d couches\n', numel(couches));
analyzeNetwork(reseau);

%% 5. La convolution
% Sur une image, une couche dense ignorerait que deux pixels voisins ont
% quelque chose à voir. La convolution, elle, applique le même petit
% filtre partout : bien moins de paramètres, et une réponse qui ne dépend
% pas de l'endroit.
image = dlarray(reshape(1:25, 5, 5), 'SSCB');
noyau = dlarray(ones(3, 3) / 9);
sortie = dlconv(image, noyau, 0);
fprintf('\nConvolution 3x3 sur une image 5x5 :\n');
fprintf('  taille de sortie : %s (attendu 3 3)\n', ...
        mat2str(size(extractdata(sortie))));
% Elle coincide avec CONV2 en mode « valid ».
attendu = conv2(reshape(1:25, 5, 5), ones(3, 3) / 9, 'valid');
fprintf('  ecart a conv2(...,''valid'') : %.3e\n', ...
        max(max(abs(extractdata(sortie) - attendu))));
assert(max(max(abs(extractdata(sortie) - attendu))) < 1e-12);

% L'agregation par maximum reduit la taille et donne une tolerance au
% deplacement.
agrege = maxpool(dlarray(reshape(1:16, 4, 4), 'SSCB'), 2, 'Stride', 2);
fprintf('  apres maxpool 2x2 : %s\n', mat2str(size(extractdata(agrege))));
assert(isequal(size(extractdata(agrege)), [2 2]));

%% 6. Normalisation
% Recentrer et réduire les activations stabilise la descente : les
% couches suivantes voient toujours des grandeurs du même ordre.
brut = dlarray(randn(8, 32) * 5 + 3, 'CB');
% L'ordre des arguments est celui de MATLAB : le decalage d'abord,
% l'echelle ensuite. Decalage nul et echelle unite laissent le resultat
% centre reduit.
normalise = layernorm(brut, dlarray(zeros(8, 1)), dlarray(ones(8, 1)));
valeurs = extractdata(normalise);
fprintf('\nNormalisation par couche :\n');
fprintf('  moyenne %.3e, ecart type %.6f\n', mean(valeurs(:)), std(valeurs(:)));
assert(abs(mean(valeurs(:))) < 1e-9);
assert(abs(std(valeurs(:)) - 1) < 0.05);

%% 7. Les lots
% On n'apprend pas sur tout le jeu à la fois : par petits lots, ce qui
% tient en mémoire, donne plusieurs pas par passage, et introduit un
% bruit qui aide à sortir des minimums étroits.
file = minibatchqueue(X', etiquettes', 'MiniBatchSize', 32);
nombreLots = 0;
totalObservations = 0;
while hasdata(file)
    [lotX, lotY] = next(file);
    nombreLots = nombreLots + 1;
    totalObservations = totalObservations + size(lotX, 2);
end
fprintf('\nDecoupage en lots de 32 : %d lots, %d observations au total\n', ...
        nombreLots, totalObservations);
assert(totalObservations == size(X, 1));
assert(nombreLots == ceil(size(X, 1) / 32));

fprintf('\nToutes les verifications passent.\n');

function [y, g] = carreEtGradient(x)
    y = x ^ 3;
    g = dlgradient(y, x);
end

function [y, g] = sommeDesCarres(m)
    y = sum(m .^ 2, 'all');
    g = dlgradient(y, m);
end

function scores = avantReseau(parametres, entrees)
    cache = relu(parametres.W1 * entrees + parametres.b1);
    scores = softmax(parametres.W2 * cache + parametres.b2);
end

function [perte, gradients] = perteReseau(parametres, entrees, cibles)
    scores = avantReseau(parametres, entrees);
    perte = crossentropy(scores, cibles);
    gradients = dlgradient(perte, parametres);
end
