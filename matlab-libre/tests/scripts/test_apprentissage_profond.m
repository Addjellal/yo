% test_apprentissage_profond.m — dérivation automatique, couches, réseaux.
%
% Les vérifications sont de trois sortes. Les dérivées sont comparées à
% des différences finies centrées, ce qui les contrôle sans rien copier.
% Les opérations sont contrôlées par leurs propriétés : une convolution
% coïncide avec CONV2, une convolution transposée est l'adjointe d'une
% convolution, une normalisation rend une sortie exactement centrée
% réduite. Et l'ensemble est contrôlé par le fait : un réseau apprend, et
% sa perte s'effondre.
disp('--- apprentissage profond ---');

% Dérivation automatique : une expression composée, contre la différence
% finie.
rng(5);
A = randn(3, 4) * 0.7;
essais = {@(x) sum(sum(x, 1) .^ 2), ...
          @(x) sum(sum(cat(2, x, x .* 2) .^ 2)), ...
          @(x) sum(sum(repmat(x, 2, 3) .^ 2)), ...
          @(x) sum(sum(reshape(permute(x, [2 1]), 6, 2) .^ 3)), ...
          @(x) sum(sum(min(x, 0.2) .^ 4)), ...
          @(x) sum(mean(x, 2) .^ 3), ...
          @(x) sum(sum(abs(x) .^ (1.5 + 0 * x))), ...
          @(x) sum(sum((x.' * x) .^ 2)), ...
          @(x) sum(sum(exp(x) ./ (1 + abs(x)) + tanh(x) + sqrt(x .^ 2 + 1))), ...
          @(x) sum(sum(erf(x) + sin(x) .* cos(x)))};
noms = {'somme par colonnes', 'concatenation', 'repetition', 'permutation', ...
        'minimum', 'moyenne', 'puissance', 'produit matriciel', ...
        'expression composee', 'fonctions speciales'};
for k = 1:numel(essais)
    [~, g] = dlfeval(@(x) matlibre_essai_gradient(essais{k}, x), dlarray(A));
    num = matlibre_essai_difference(essais{k}, A);
    ecart = max(abs(num(:) - reshape(extractdata(g), [], 1)));
    fprintf('%-22s ecart %.2e\n', noms{k}, ecart);
    assert(ecart < 1e-6);
end
% L'affectation indexée se dérive aussi.
[~, g] = dlfeval(@(x) matlibre_essai_gradient(@matlibre_essai_affectation, x), dlarray(A));
num = matlibre_essai_difference(@matlibre_essai_affectation, A);
assert(max(abs(num(:) - reshape(extractdata(g), [], 1))) < 1e-6);
% DLGRADIENT hors de DLFEVAL est refusé.
refuse = false;
try
    dlgradient(dlarray(1), dlarray(1));
catch e
    refuse = strcmp(e.identifier, 'nnet:dlgradient:HorsDlfeval');
end
assert(refuse);
% Le format se transmet, et EXTRACTDATA rend le tableau nu.
x = dlarray(zeros(4, 8), 'CB');
assert(strcmp(dims(x), 'CB'));
assert(isequal(dims(x + 1), 'CB'));
assert(isempty(dims(stripdims(x))));
assert(finddim(x, 'B') == 2);
disp('derivation automatique : ok');

% Convolution : elle coïncide avec CONV2, et ses dérivées avec la
% différence finie.
rng(2);
A = randn(6, 7);
K = randn(3, 2);
assert(max(max(abs(conv2(A, K, 'valid') - extractdata(dlconv(dlarray(A, 'SS'), K, 0))))) < 1e-12);
X = randn(7, 6, 2, 3);
W = randn(3, 2, 2, 4);
B = randn(4, 1);
reglages = {{'Stride', 1}, {'Stride', 2, 'Padding', 1}, {'Padding', 'same'}, ...
            {'DilationFactor', 2, 'Padding', 'same'}};
for k = 1:numel(reglages)
    options = reglages{k};
    [gx, gw, gb] = dlfeval(@(a, b, c) matlibre_essai_conv(a, b, c, options), ...
                           dlarray(X), dlarray(W), dlarray(B));
    nx = matlibre_essai_difference(@(v) matlibre_essai_perte_conv(v, W, B, options), X);
    nw = matlibre_essai_difference(@(v) matlibre_essai_perte_conv(X, v, B, options), W);
    nb = matlibre_essai_difference(@(v) matlibre_essai_perte_conv(X, W, v, options), B);
    ecarts = [max(abs(nx(:) - reshape(extractdata(gx), [], 1))), ...
              max(abs(nw(:) - reshape(extractdata(gw), [], 1))), ...
              max(abs(nb(:) - reshape(extractdata(gb), [], 1)))];
    fprintf('convolution %-28s ecarts %.1e %.1e %.1e\n', mat2str(cell2mat(options(2:2:end))), ecarts);
    assert(max(ecarts) < 1e-6);
end
% Une convolution unidimensionnelle rend la bonne taille.
assert(isequal(size(extractdata(dlconv(dlarray(randn(12, 2, 3), 'SCB'), randn(4, 2, 5), zeros(5, 1)))), ...
               [9 5 3]));
% La convolution transposée est l'adjointe de la convolution : le produit
% scalaire de l'une avec un vecteur vaut celui du vecteur avec l'autre.
X = randn(6, 5, 2, 1);
W = randn(3, 2, 2, 3);
pas = [2 2];
Y = extractdata(dlconv(dlarray(X, 'SSCB'), W, zeros(3, 1), 'Stride', pas, 'DataFormat', 'SSCB'));
G = randn(size(Y));
Z = extractdata(matlibre_dl_convolution_transposee(dlarray(G, 'SSCB'), W, zeros(2, 1), pas, 0));
complet = zeros(size(X));
complet(1:size(Z, 1), 1:size(Z, 2), :, :) = Z;
produitUn = sum(sum(sum(sum(Y .* G))));
produitDeux = sum(sum(sum(sum(X .* complet))));
fprintf('adjointe : %.10f contre %.10f\n', produitUn, produitDeux);
assert(abs(produitUn - produitDeux) / abs(produitUn) < 1e-10);
disp('convolution : ok');

% Agrégation : les valeurs, puis les dérivées.
assert(isequal(extractdata(maxpool(dlarray(reshape(1:16, 4, 4), 'SS'), 2)), [6 14; 8 16]));
assert(isequal(extractdata(avgpool(dlarray(reshape(1:16, 4, 4), 'SS'), 2)), [3.5 11.5; 5.5 13.5]));
rng(4);
X = randn(6, 6, 2, 2);
cas = {{'max', 2, {}}, {'moyenne', 2, {}}, {'max', 3, {'Stride', 1}}, ...
       {'moyenne', 2, {'Padding', 'same', 'Stride', 3}}};
for k = 1:numel(cas)
    genre = cas{k}{1};
    fenetre = cas{k}{2};
    options = cas{k}{3};
    [~, g] = dlfeval(@(x) matlibre_essai_gradient(@(v) matlibre_essai_pool(v, genre, fenetre, options), x), ...
                     dlarray(X, 'SSCB'));
    num = matlibre_essai_difference(@(v) matlibre_essai_pool_nu(v, genre, fenetre, options), X);
    ecart = max(abs(num(:) - reshape(extractdata(g), [], 1)));
    fprintf('agregation %-8s fenetre %d ecart %.2e\n', genre, fenetre, ecart);
    assert(ecart < 1e-6);
end
disp('agregation : ok');

% Normalisations : la sortie est exactement centrée réduite.
rng(1);
x = dlarray(randn(4, 4, 3, 16), 'SSCB');
[y, mu, s2] = batchnorm(x, zeros(3, 1), ones(3, 1));
v = extractdata(y);
for c = 1:3
    bloc = v(:, :, c, :);
    assert(abs(mean(bloc(:))) < 1e-12);
    assert(abs(mean(bloc(:) .^ 2) - 1) < 1e-4);
end
assert(isequal(size(mu), [3 1]) && isequal(size(s2), [3 1]));
% Avec des statistiques imposées, la sortie ne dépend plus du lot.
seul = extractdata(batchnorm(x(:, :, :, 1), zeros(3, 1), ones(3, 1), mu, s2));
tout = extractdata(batchnorm(x, zeros(3, 1), ones(3, 1), mu, s2));
assert(max(max(max(abs(seul - tout(:, :, :, 1))))) < 1e-12);
yl = extractdata(layernorm(dlarray(randn(6, 8), 'CB'), 0, 1));
assert(max(abs(mean(yl, 1))) < 1e-12);
yg = extractdata(groupnorm(dlarray(randn(4, 4, 6, 3), 'SSCB'), zeros(6, 1), ones(6, 1), 3));
bloc = yg(:, :, 1:2, 1);
assert(abs(mean(bloc(:))) < 1e-12);
disp('normalisations : ok');

% Pertes.
assert(abs(extractdata(l1loss(dlarray([1 2], 'CB'), [0 0])) - 1.5) < 1e-12);
assert(abs(extractdata(l2loss(dlarray([1 2], 'CB'), [0 0])) - 2.5) < 1e-12);
assert(abs(extractdata(huber(dlarray([0.5 5], 'CB'), [0 0])) - (0.125 + 4.5) / 2) < 1e-12);
assert(max(abs(extractdata(huber(dlarray([0.5 5], 'CB'), [0 0], 'Reduction', 'none')) - [0.125 4.5])) < 1e-12);
% La perte de Huber se raccorde sans rupture de pente au point de
% transition : c'est ce qui la distingue d'un simple choix entre deux
% pertes.
h = 1e-6;
avant = extractdata(huber(dlarray(1 - h, 'CB'), 0, 'NormalizationFactor', 'none'));
apres = extractdata(huber(dlarray(1 + h, 'CB'), 0, 'NormalizationFactor', 'none'));
milieu = extractdata(huber(dlarray(1, 'CB'), 0, 'NormalizationFactor', 'none'));
assert(abs((apres - milieu) / h - (milieu - avant) / h) < 1e-4);
disp('pertes : ok');

% Solveurs : un pas connu, et la même règle sur toutes les formes de
% conteneurs.
[p, moyenne, carres] = adamupdate(dlarray(1), dlarray(0.5), [], [], 1);
assert(abs(extractdata(p) - 0.999) < 1e-6);
assert(abs(extractdata(sgdmupdate(dlarray(1), dlarray(2), [])) - 0.98) < 1e-12);
assert(abs(extractdata(rmspropupdate(dlarray(1), dlarray(0.5), [])) - 0.99683772) < 1e-6);
% Le pas d'Adam vaut le pas demandé au terme de régularisation près, qui
% vaut ici un cent-millionième : c'est ce que dit la tolérance.
s = adamupdate(struct('W', dlarray([1 2])), struct('W', dlarray([0.1 0.2])), [], [], 1, 0.1);
assert(max(abs(extractdata(s.W) - [0.9 1.9])) < 1e-6);
c = adamupdate({dlarray([1 2])}, {dlarray([0.1 0.2])}, [], [], 1, 0.1);
assert(max(abs(extractdata(c{1}) - [0.9 1.9])) < 1e-6);
t = table({'fc'}, {'Weights'}, {dlarray([1 2])}, 'VariableNames', {'Layer', 'Parameter', 'Value'});
gt = table({'fc'}, {'Weights'}, {dlarray([0.1 0.2])}, 'VariableNames', {'Layer', 'Parameter', 'Value'});
t2 = adamupdate(t, gt, [], [], 1, 0.1);
assert(max(abs(extractdata(t2.Value{1}) - [0.9 1.9])) < 1e-6);
assert(strcmp(t2.Layer{1}, 'fc'));
disp('solveurs : ok');

% Étiquettes.
assert(isequal(onehotencode({'a', 'b', 'a'}, 1), [1 0 1; 0 1 0]));
assert(isequal(size(onehotencode(categorical({'x', 'y', 'x'}), 2)), [3 2]));
assert(isequal(cellstr(onehotdecode([0.2 0.9; 0.8 0.1], {'a', 'b'}, 1)), {'b'; 'a'}));
% Coder puis décoder rend les étiquettes de départ.
etiquettes = {'chat', 'chien', 'chat', 'oiseau'};
code = onehotencode(etiquettes, 1);
assert(isequal(cellstr(onehotdecode(code, unique(etiquettes), 1)).', {'chat', 'chien', 'chat', 'oiseau'}));
% Matrice de confusion, sur des chaînes comme sur des nombres.
assert(isequal(confusionmat({'a', 'b', 'a'}, {'a', 'b', 'b'}), [1 1; 0 1]));
[m, classes] = confusionmat([1 2 1 3], [1 2 2 3]);
assert(isequal(m, [1 1 0; 0 1 0; 0 0 1]) && isequal(classes(:).', [1 2 3]));
assert(isequal(confusionchart({'a', 'b'}, {'a', 'b'}), eye(2)));
disp('etiquettes : ok');

% Couches récurrentes : les tailles annoncées sont celles produites.
rng(1);
x = dlarray(randn(3, 5, 7));
formes = {{lstmLayer(4), [4 5 7]}, {gruLayer(4), [4 5 7]}, {bilstmLayer(4), [8 5 7]}};
for k = 1:numel(formes)
    couche = formes{k}{1};
    parametres = matlibre_couche_initialiser(couche, 3, true);
    y = matlibre_couche_recurrente(couche, x, parametres);
    assert(isequal(size(extractdata(y)), formes{k}{2}));
end
couche = lstmLayer(4, 'OutputMode', 'last');
parametres = matlibre_couche_initialiser(couche, 3, true);
assert(isequal(size(extractdata(matlibre_couche_recurrente(couche, x, parametres))), [4 5]));
disp('couches recurrentes : ok');

% Graphe de couches et réseau.
lg = layerGraph({featureInputLayer(4), fullyConnectedLayer(3), softmaxLayer()});
assert(numel(lg.Layers) == 3 && height(lg.Connections) == 2);
assert(strcmp(lg.Connections.Source{1}, lg.Names{1}));
net = dlnetwork({featureInputLayer(2), fullyConnectedLayer(8), reluLayer(), ...
                 fullyConnectedLayer(3), softmaxLayer()});
assert(net.Initialized);
assert(height(net.Learnables) == 4);
Y = predict(net, dlarray(randn(2, 5), 'CB'));
assert(isequal(size(extractdata(Y)), [3 5]));
assert(max(abs(sum(extractdata(Y), 1) - 1)) < 1e-12);
sortie = activations(net, dlarray(randn(2, 5), 'CB'), net.Names{3});
assert(min(min(extractdata(sortie))) >= 0);
rapport = analyzeNetwork(net);
assert(height(rapport) == 5 && sum(rapport.Learnables) == 2 * 8 + 8 + 8 * 3 + 3);
assert(assembleNetwork({featureInputLayer(3), fullyConnectedLayer(2)}).Initialized);
% Un graphe ramifié : une connexion résiduelle.
lg = layerGraph();
lg = addLayers(lg, {featureInputLayer(4, 'Name', 'entree')});
lg = addLayers(lg, {fullyConnectedLayer(4, 'Name', 'dense'), reluLayer('Name', 'relu')});
lg = addLayers(lg, {additionLayer(2, 'Name', 'somme')});
lg = connectLayers(lg, 'entree', 'dense');
lg = connectLayers(lg, 'dense', 'relu');
lg = connectLayers(lg, 'relu', 'somme');
lg = connectLayers(lg, 'entree', 'somme');
residuel = dlnetwork(lg);
assert(residuel.Initialized);
sortieResiduelle = extractdata(predict(residuel, dlarray(randn(4, 6), 'CB')));
assert(isequal(size(sortieResiduelle), [4 6]));
disp('reseaux : ok');

% Lots successifs.
rng(1);
mbq = minibatchqueue(randn(3, 100), randn(2, 100), 'MiniBatchSize', 16, ...
                     'MiniBatchFormat', {'CB', ''});
lots = 0;
total = 0;
while hasdata(mbq)
    [Xlot, Tlot] = next(mbq);
    lots = lots + 1;
    total = total + size(Xlot, 2);
end
assert(lots == 7 && total == 100);
shuffle(mbq);
assert(hasdata(mbq));
mbq2 = minibatchqueue(randn(3, 100), 'MiniBatchSize', 32, 'PartialMiniBatch', 'discard');
complets = 0;
while hasdata(mbq2)
    next(mbq2);
    complets = complets + 1;
end
assert(complets == 3);
disp('lots : ok');

% Apprentissage : la perte s'effondre et le réseau classe juste.
rng(4);
n = 90;
centres = [0 0; 3 3; -3 3].';
X = zeros(2, n);
cible = zeros(3, n);
for k = 1:n
    classe = mod(k - 1, 3) + 1;
    X(:, k) = centres(:, classe) + 0.6 * randn(2, 1);
    cible(classe, k) = 1;
end
net = dlnetwork({featureInputLayer(2), fullyConnectedLayer(12), reluLayer(), ...
                 fullyConnectedLayer(3), softmaxLayer()});
dlX = dlarray(X, 'CB');
depart = extractdata(dlfeval(@(r) crossentropy(forward(r, dlX), cible), net));
moyenne = [];
carres = [];
for iteration = 1:250
    [~, gradients] = dlfeval(@matlibre_essai_perte_reseau, net, dlX, cible);
    [net, moyenne, carres] = adamupdate(net, gradients, moyenne, carres, iteration, 0.05);
end
fin = extractdata(dlfeval(@(r) crossentropy(forward(r, dlX), cible), net));
[~, predites] = max(extractdata(predict(net, dlX)), [], 1);
[~, vraies] = max(cible, [], 1);
fprintf('perte %.4f puis %.4f, justesse %.3f\n', depart, fin, mean(predites == vraies));
assert(fin < depart / 5);
assert(mean(predites == vraies) > 0.95);
disp('apprentissage : ok');

% Un réseau convolutif, avec normalisation par lot : il apprend, et sa
% prédiction emploie les statistiques accumulées.
rng(6);
n = 60;
X = zeros(8, 8, 1, n);
cible = zeros(2, n);
for k = 1:n
    classe = mod(k - 1, 2) + 1;
    image = 0.1 * randn(8, 8);
    position = randi(6) + 1;
    if classe == 1
        image(:, position) = image(:, position) + 1;
    else
        image(position, :) = image(position, :) + 1;
    end
    X(:, :, 1, k) = image;
    cible(classe, k) = 1;
end
net = dlnetwork({imageInputLayer([8 8 1]), convolution2dLayer(3, 4, 'Padding', 'same'), ...
                 batchNormalizationLayer(), reluLayer(), maxPooling2dLayer(2), ...
                 flattenLayer(), fullyConnectedLayer(2), softmaxLayer()});
dlX = dlarray(X, 'SSCB');
depart = extractdata(dlfeval(@(r) crossentropy(forward(r, dlX), cible), net));
moyenne = [];
carres = [];
for iteration = 1:80
    [~, gradients] = dlfeval(@matlibre_essai_perte_reseau, net, dlX, cible);
    [net, moyenne, carres] = adamupdate(net, gradients, moyenne, carres, iteration, 0.02);
end
[Y, etat] = forward(net, dlX);
net.State = etat;
fin = extractdata(crossentropy(Y, cible));
[~, predites] = max(extractdata(predict(net, dlX)), [], 1);
[~, vraies] = max(cible, [], 1);
fprintf('convolutif : perte %.4f puis %.4f, justesse %.3f\n', depart, fin, mean(predites == vraies));
assert(fin < depart / 3);
assert(mean(predites == vraies) > 0.9);
assert(height(net.State) == 2);
disp('reseau convolutif : ok');


% Un tableau de couches — la notation « [c1; c2; c3] » — doit etre
% eclate : c'est la facon naturelle d'empiler des couches, et sans cela
% les trois n'en feraient qu'une.
tableauCouches = [
    featureInputLayer(4)
    fullyConnectedLayer(8)
    reluLayer
    fullyConnectedLayer(2)
    softmaxLayer];
assert(isstruct(tableauCouches) && numel(tableauCouches) == 5);
grapheTableau = layerGraph(tableauCouches);
assert(numel(grapheTableau.Layers) == 5);
assert(numel(unique(grapheTableau.Names)) == 5, 'chaque couche porte son nom');
% Les couches se suivent dans l'ordre donne.
typesAttendus = {'input', 'fc', 'relu', 'fc', 'softmax'};
for indiceCouche = 1:5
    assert(strcmp(grapheTableau.Layers{indiceCouche}.type, typesAttendus{indiceCouche}));
end
% Et elles sont raccordees en chaine.
assert(height(grapheTableau.Connections) == 4);
% La meme chose en cellule donne le meme graphe.
grapheCellule = layerGraph({featureInputLayer(4), fullyConnectedLayer(8), ...
                            reluLayer, fullyConnectedLayer(2), softmaxLayer});
assert(isequal(grapheCellule.Names, grapheTableau.Names));
% ADDLAYERS accepte aussi le tableau.
grapheVide = addLayers(layerGraph(), [reluLayer('Name', 'a'); reluLayer('Name', 'b')]);
assert(isequal(grapheVide.Names, {'a', 'b'}));
% Une couche seule reste acceptee.
assert(numel(layerGraph(reluLayer).Layers) == 1);
disp('tableaux de couches : ok');

disp('apprentissage profond : toutes les verifications passent');
