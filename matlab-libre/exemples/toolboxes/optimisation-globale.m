% optimisation-globale.m — Global Optimization Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/optimisation-globale.m
%
% Le cas : une fonction à minimums multiples. Une descente locale s'arrête
% au premier creux rencontré ; les méthodes globales, elles, explorent.
% C'est tout le sujet, et il n'y a pas de méthode qui garantisse le
% minimum global en temps fini — seulement des façons d'augmenter ses
% chances.

fprintf('=== Optimisation globale : sortir du premier creux ===\n\n');

%% 1. Le problème
% La fonction de Rastrigin en deux dimensions : un paraboloïde couvert de
% creux réguliers. Son minimum global est en zéro, et il y a une centaine
% de minimums locaux dans le domaine.
rastrigin = @(x) 20 + sum(x .^ 2 - 10 * cos(2 * pi * x), 2);
bornesBasses = [-5.12 -5.12];
bornesHautes = [5.12 5.12];
fprintf('Fonction de Rastrigin en dimension 2 :\n');
fprintf('  minimum global en (0,0), valeur %.4f\n', rastrigin([0 0]));
assert(abs(rastrigin([0 0])) < 1e-12);
% Compter les creux sur une grille : la difficulte se voit.
grille = -5:0.05:5;
[X, Y] = meshgrid(grille, grille);
valeurs = 20 + X .^ 2 - 10 * cos(2 * pi * X) + Y .^ 2 - 10 * cos(2 * pi * Y);
locaux = 0;
for i = 2:size(valeurs, 1) - 1
    for j = 2:size(valeurs, 2) - 1
        voisinage = valeurs(i-1:i+1, j-1:j+1);
        if valeurs(i, j) <= min(voisinage(:))
            locaux = locaux + 1;
        end
    end
end
fprintf('  environ %d minimums locaux sur la grille\n', locaux);
assert(locaux > 50, 'la fonction doit bien avoir de nombreux creux');

%% 2. Ce qu'une descente locale donne
% Partie d'un point quelconque, elle tombe dans le creux le plus proche.
rng(1);
departs = -5 + 10 * rand(20, 2);
resultatsLocaux = zeros(20, 1);
for k = 1:20
    [~, resultatsLocaux(k)] = fminsearch(@(x) rastrigin(x(:).'), departs(k, :));
end
fprintf('\n20 descentes locales depuis des points au hasard :\n');
fprintf('  meilleure %.4f, pire %.4f, mediane %.4f\n', ...
        min(resultatsLocaux), max(resultatsLocaux), median(resultatsLocaux));
assert(median(resultatsLocaux) > 1, ...
       'la plupart des descentes s''arretent dans un creux secondaire');

%% 3. Le recuit simulé
% Il accepte parfois de monter, avec une probabilité qui décroît. C'est
% ce qui lui permet de ressortir d'un creux — et c'est aussi pourquoi il
% faut le laisser refroidir lentement.
rng(3);
[solutionRecuit, valeurRecuit] = simulannealbnd(@(x) rastrigin(x(:).'), ...
                                                [3 3], bornesBasses, bornesHautes);
fprintf('\nRecuit simule depuis (3,3) :\n');
fprintf('  solution %s, valeur %.4f\n', ...
        mat2str(round(solutionRecuit, 4)), valeurRecuit);
assert(valeurRecuit < median(resultatsLocaux), ...
       'le recuit doit faire mieux qu''une descente moyenne');

%% 4. L'algorithme génétique
% Une population de solutions, croisée et mutée de génération en
% génération. Il n'utilise aucune dérivée : c'est ce qui le rend
% applicable à des problèmes où l'on ne sait rien de la fonction.
rng(5);
[solutionGenetique, valeurGenetique] = ga(@(x) rastrigin(x(:).'), 2, [], [], ...
                                          [], [], bornesBasses, bornesHautes);
fprintf('\nAlgorithme genetique :\n');
fprintf('  solution %s, valeur %.4f\n', ...
        mat2str(round(solutionGenetique, 4)), valeurGenetique);
assert(valeurGenetique < median(resultatsLocaux));
assert(all(solutionGenetique >= bornesBasses - 1e-9));
assert(all(solutionGenetique <= bornesHautes + 1e-9));

%% 5. L'essaim particulaire
% Des particules qui se souviennent de leur meilleur point et de celui du
% groupe. Elles convergent sans qu'aucune ne calcule de gradient.
rng(7);
[solutionEssaim, valeurEssaim] = particleswarm(@(x) rastrigin(x(:).'), 2, ...
                                               bornesBasses, bornesHautes);
fprintf('\nEssaim particulaire :\n');
fprintf('  solution %s, valeur %.4f\n', ...
        mat2str(round(solutionEssaim, 4)), valeurEssaim);
assert(valeurEssaim < median(resultatsLocaux));

%% 6. La recherche par motifs
% Elle explore selon un maillage qu'elle resserre. Déterministe, elle
% donne toujours le même résultat depuis le même départ — ce qu'aucune
% des trois précédentes ne garantit.
[solutionMotif, valeurMotif] = patternsearch(@(x) rastrigin(x(:).'), [3 3], ...
                                             [], [], [], [], ...
                                             bornesBasses, bornesHautes);
[solutionMotif2, valeurMotif2] = patternsearch(@(x) rastrigin(x(:).'), [3 3], ...
                                               [], [], [], [], ...
                                               bornesBasses, bornesHautes);
fprintf('\nRecherche par motifs depuis (3,3) :\n');
fprintf('  solution %s, valeur %.4f\n', ...
        mat2str(round(solutionMotif, 4)), valeurMotif);
assert(isequal(solutionMotif, solutionMotif2), ...
       'la methode est deterministe : deux appels identiques donnent le meme point');

%% 7. Les départs multiples
% La méthode la plus simple, et souvent la plus efficace : lancer la
% descente locale depuis beaucoup de points et garder le meilleur.
% Deux ecritures mènent au même résultat : l'objet MULTISTART avec RUN,
% comme dans MATLAB, ou la fonction MULTISTART directement.
probleme = createOptimProblem('fminunc', 'objective', @(x) rastrigin(x(:).'), ...
                              'x0', [3 3], 'lb', bornesBasses, 'ub', bornesHautes);
fprintf('\nDeparts multiples :\n');
qualites = zeros(1, 3);
nombres = [5 40 200];
for k = 1:3
    rng(11);
    [~, qualites(k)] = run(MultiStart('Display', 'off'), probleme, nombres(k));
    fprintf('  %3d departs : valeur %.4f\n', nombres(k), qualites(k));
end
% Plus de departs ne peut pas nuire : le meilleur d'un ensemble plus
% grand est au moins aussi bon. C'est la seule garantie de la methode,
% et elle suffit souvent.
assert(all(diff(qualites) <= 1e-9), ...
       'la qualite ne peut que s''ameliorer avec le nombre de departs');
assert(qualites(end) < median(resultatsLocaux), ...
       'elle bat largement une descente unique');
% Le solveur local employe compte autant que le nombre de departs : sur
% une fonction aussi accidentee, une methode sans derivee explore mieux
% qu'une descente de gradient, qui se laisse piéger par le premier creux.
rng(11);
meilleurSimplex = inf;
for k = 1:200
    depart = bornesBasses + rand(1, 2) .* (bornesHautes - bornesBasses);
    [~, v] = fminsearch(@(x) rastrigin(x(:).'), depart);
    meilleurSimplex = min(meilleurSimplex, v);
end
fprintf('  200 departs, simplexe au lieu du gradient : %.6f\n', meilleurSimplex);
assert(meilleurSimplex < 1e-3, 'le minimum global vaut zero, on doit y arriver');

%% 8. Plusieurs objectifs à la fois
% Quand deux critères s'opposent, il n'y a pas une solution mais un front
% : les points qu'on ne peut améliorer sur un critère sans dégrader
% l'autre.
objectifs = @(x) [sum(x .^ 2, 2), sum((x - 2) .^ 2, 2)];
rng(13);
[frontX, frontF] = gamultiobj(objectifs, 2, [], [], [], [], [-5 -5], [5 5]);
fprintf('\nDeux objectifs opposes :\n');
fprintf('  %d points sur le front\n', size(frontX, 1));
assert(size(frontX, 1) > 3, 'le front doit compter plusieurs points');
% Aucun point du front n'en domine un autre : c'est la definition.
domine = false;
for i = 1:size(frontF, 1)
    for j = 1:size(frontF, 1)
        if i == j, continue, end
        if all(frontF(i, :) <= frontF(j, :) + 1e-9) && ...
           any(frontF(i, :) < frontF(j, :) - 1e-6)
            domine = true;
        end
    end
end
assert(~domine, 'aucun point du front n''en domine un autre');
% Les deux extremes du front sont les optimums de chaque objectif seul.
fprintf('  meilleur du premier objectif : %.4f\n', min(frontF(:, 1)));
fprintf('  meilleur du second objectif  : %.4f\n', min(frontF(:, 2)));
assert(min(frontF(:, 1)) < 0.5, 'un bout du front approche l''optimum de f1');
assert(min(frontF(:, 2)) < 0.5, 'l''autre bout approche celui de f2');

fprintf('\nToutes les verifications passent.\n');
