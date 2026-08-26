% test_parallele.m — parfor, spmd et parfeval sur un vrai pool de fils.
% Chaque vérification compare le résultat parallèle au résultat séquentiel
% exact : l'ordre d'exécution ne doit rien changer.
disp('--- parallele ---');

%% ------------------------------------------------------------- pool
p = gcp();
assert(isstruct(p));
assert(p.NumWorkers >= 1);
assert(p.Connected);
parpool(3);
q = gcp('nocreate');
assert(q.NumWorkers == 3);
delete(q);
assert(isempty(gcp('nocreate')));
parpool(4);

%% --------------------------------------------------- parfor en tranches
n = 200;
r = zeros(1, n);
parfor i = 1:n
    r(i) = i^2;
end
assert(sum(r) == 2686700);              % n(n+1)(2n+1)/6 pour n = 200
assert(isequal(r, (1:n).^2));

% Tranche sur une cellule.
c = cell(1, 5);
parfor i = 1:5
    c{i} = repmat('x', 1, i);
end
assert(numel(c{3}) == 3);
assert(strcmp(c{5}, 'xxxxx'));

% Variable temporaire, réutilisée d'une itération à l'autre.
s = zeros(1, 10);
parfor i = 1:10
    x = 0;
    for k = 1:5
        x = x + k * i;
    end
    s(i) = x;
end
assert(isequal(s, 15 * (1:10)));        % somme(1..5) = 15

%% ------------------------------------------------------ parfor réductions
total = 0;
parfor i = 1:100
    total = total + i;
end
assert(total == 5050);

produit = 1;
parfor i = 1:10
    produit = produit * i;
end
assert(produit == 3628800);             % 10!

maxi = -Inf;
parfor i = 1:20
    maxi = max(maxi, i * 3);
end
assert(maxi == 60);

liste = [];
parfor i = 1:5
    liste = [liste, i];
end
assert(isequal(sort(liste), 1:5));      % l'ordre d'arrivée est libre

drapeau = true;
parfor i = 1:10
    drapeau = drapeau & (i > 0);
end
assert(drapeau);

% Valeur d'avant la boucle réintégrée une seule fois.
depart = 1000;
parfor i = 1:4
    depart = depart + i;
end
assert(depart == 1010);

%% ------------------------------------------------------ variables diffusées
facteur = 7;
d = zeros(1, 6);
parfor i = 1:6
    d(i) = i * facteur;
end
assert(isequal(d, (1:6) * 7));

%% ------------------------------------------------- corps non parallélisable
% Écriture indexée par autre chose que la variable de boucle : MatLibre
% retombe sur l'exécution séquentielle et rend le même résultat.
acc = zeros(1, 5);
parfor i = 1:5
    acc(6 - i) = i;
end
assert(isequal(acc, [5 4 3 2 1]));

%% ------------------------------------------------------------------ spmd
spmd
    v = labindex * 10;
    m = numlabs;
end
assert(iscell(v));
assert(numel(v) == 4);
assert(v{1} == 10);
assert(v{4} == 40);
assert(m{1} == 4);

%% -------------------------------------------------------------- parfeval
f = parfeval(@(x) x^2, 1, 7);
wait(f);
assert(fetchOutputs(f) == 49);

g = parfeval(@max, 1, [3 9 2]);
assert(fetchOutputs(g) == 9);

futurs = cell(1, 4);
for k = 1:4
    futurs{k} = parfeval(@(x) x + 1, 1, k);
end
sommes = 0;
for k = 1:4
    sommes = sommes + fetchOutputs(futurs{k});
end
assert(sommes == 14);                   % 2+3+4+5

%% ------------------------------------------------------ pararrayfun, parcellfun
assert(isequal(pararrayfun(@(x) x^2, 1:4), [1 4 9 16]));
assert(isequal(parcellfun(@numel, {'a', 'bb', 'ccc'}), [1 2 3]));

%% ----------------------------------------------------- parfor imbriqué
% Une boucle parfor à l'intérieur d'une autre s'exécute séquentiellement,
% comme dans MATLAB : seul le niveau extérieur est réparti.
grille = zeros(4, 4);
parfor i = 1:4
    ligne = zeros(1, 4);
    for j = 1:4
        ligne(j) = i * j;
    end
    grille(i, :) = ligne;
end
assert(isequal(grille, (1:4)' * (1:4)));

delete(gcp('nocreate'));
disp('parallele : toutes les verifications passent');
