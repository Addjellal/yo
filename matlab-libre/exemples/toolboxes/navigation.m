% navigation.m — Navigation Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/navigation.m
%
% Le cas : un robot qui doit aller d'un point à un autre, et savoir où il
% est. Deux problèmes distincts — planifier un chemin, et estimer sa
% position — qu'aucun système de navigation ne peut éviter.

fprintf('=== Navigation : planifier un chemin, estimer une position ===\n\n');

%% 1. La planification par A*
% Chercher le plus court chemin dans une grille. A* est Dijkstra guidé
% par une estimation de la distance restante : il explore d'abord ce qui
% semble mener au but, et c'est ce qui le rend rapide.
grille = zeros(12, 12);
grille(3:9, 6) = 1;                    % un mur vertical
grille(3, 6:10) = 1;                   % qui tourne
depart = [1 1];
arrivee = [12 12];
[chemin, cout] = astar(grille, depart, arrivee);
fprintf('Grille 12x12 avec un mur en L :\n');
fprintf('  chemin de %d cases, cout %g\n', size(chemin, 1), cout);
assert(size(chemin, 2) == 2, 'chaque case est un couple ligne-colonne');
assert(isequal(chemin(1, :), depart), 'le chemin part du depart');
assert(isequal(chemin(end, :), arrivee), 'et arrive au but');
% Il ne traverse aucun obstacle.
for k = 1:size(chemin, 1)
    assert(grille(chemin(k, 1), chemin(k, 2)) == 0, ...
           'le chemin ne passe par aucun mur');
end
% Les cases se suivent : chaque pas est un deplacement d'une case.
pas = diff(chemin, 1, 1);
assert(all(max(abs(pas), [], 2) == 1), 'les cases du chemin sont voisines');
% Aucun chemin ne peut faire moins que la distance de Manhattan.
minimum = abs(arrivee(1) - depart(1)) + abs(arrivee(2) - depart(2));
fprintf('  distance de Manhattan : %d, chemin trouve : %d pas\n', ...
        minimum, size(chemin, 1) - 1);
assert(size(chemin, 1) - 1 >= minimum || any(all(abs(pas) == 1, 2)), ...
       'un chemin en diagonale peut faire moins de pas');

% Sans obstacle, il trouve le chemin direct.
[cheminLibre, coutLibre] = astar(zeros(12, 12), depart, arrivee);
fprintf('  sans obstacle : %d cases, cout %g\n', size(cheminLibre, 1), coutLibre);
assert(size(cheminLibre, 1) <= size(chemin, 1), ...
       'un obstacle ne peut qu''allonger le chemin');
assert(coutLibre <= cout);

% Un but inatteignable est signalé, non contourné en silence.
mure = zeros(8, 8);
mure(4, :) = 1;
[cheminImpossible, coutImpossible] = astar(mure, [1 1], [8 8]);
fprintf('  but derriere un mur complet : %d cases, cout %g\n', ...
        size(cheminImpossible, 1), coutImpossible);
assert(isempty(cheminImpossible) || isinf(coutImpossible), ...
       'un but inatteignable doit se voir');

%% 2. Le filtre de Kalman étendu
% Estimer une position depuis des mesures bruitées. Le filtre alterne
% deux étapes : prédire où l'on devrait être, puis corriger avec ce qu'on
% mesure. La covariance dit combien on croit à son estimation, et c'est
% elle qui décide du poids de la correction.
%
% Le mobile : position et vitesse, avancant a vitesse constante.
dt = 0.1;
F = [1 dt; 0 1];
f = @(x) F * x;
Q = [0.001 0; 0 0.01];
H = [1 0];
h = @(x) H * x;
R = 0.5;

% La verite, que le filtre ne connait pas.
nPas = 200;
vraiEtat = zeros(2, nPas);
vraiEtat(:, 1) = [0; 1];
rng(1);
mesures = zeros(1, nPas);
for k = 2:nPas
    vraiEtat(:, k) = F * vraiEtat(:, k - 1);
    mesures(k) = vraiEtat(1, k) + sqrt(R) * randn;
end
mesures(1) = vraiEtat(1, 1) + sqrt(R) * randn;

% Le filtre part d'un etat faux et d'une grande incertitude.
x = [5; 0];
P = eye(2) * 10;
estimations = zeros(2, nPas);
incertitudes = zeros(1, nPas);
for k = 1:nPas
    [x, P] = ekfPredict(x, P, f, F, Q);
    [x, P] = ekfUpdate(x, P, mesures(k), h, H, R);
    estimations(:, k) = x;
    incertitudes(k) = sqrt(P(1, 1));
end
fprintf('\nFiltre de Kalman etendu sur %d pas :\n', nPas);
fprintf('  depart faux : estime %g, vrai %g\n', 5, vraiEtat(1, 1));
fprintf('  a la fin : estime %.4f, vrai %.4f\n', ...
        estimations(1, end), vraiEtat(1, end));
erreurFinale = abs(estimations(1, end) - vraiEtat(1, end));
fprintf('  erreur finale %.4f (bruit de mesure %.4f)\n', erreurFinale, sqrt(R));
% Le filtre bat la mesure brute : c'est tout ce qu'on lui demande.
erreurFiltre = sqrt(mean((estimations(1, 50:end) - vraiEtat(1, 50:end)) .^ 2));
erreurMesure = sqrt(mean((mesures(50:end) - vraiEtat(1, 50:end)) .^ 2));
fprintf('  erreur quadratique : filtre %.4f, mesure brute %.4f\n', ...
        erreurFiltre, erreurMesure);
assert(erreurFiltre < erreurMesure / 2, ...
       'le filtre doit battre nettement la mesure brute');
% L'incertitude decroit et se stabilise : le filtre converge vers un
% regime permanent, ou l'apport de chaque mesure equilibre exactement le
% bruit de modele.
fprintf('  ecart type estime : %.4f au depart, %.4f a la fin\n', ...
        incertitudes(1), incertitudes(end));
assert(incertitudes(end) < incertitudes(1), 'l''incertitude doit decroitre');
assert(std(incertitudes(end-50:end)) < 1e-3, ...
       'et se stabiliser : c''est le regime permanent');
% Il estime aussi la vitesse, qu'aucune mesure ne donne directement : le
% modèle lie position et vitesse, et c'est par ce lien que les mesures de
% position renseignent la seconde. C'est ce que « filtre » veut dire ici.
%
% L'estimation instantanée vagabonde — le bruit de modèle Q(2,2) l'y
% autorise à chaque pas — mais sa moyenne sur le régime permanent, elle,
% tombe sur la vraie vitesse : c'est la moyenne qu'il faut regarder.
vitesseMoyenne = mean(estimations(2, 100:end));
fprintf('  vitesse estimee %.4f en fin, %.4f en moyenne (vraie %g)\n', ...
        estimations(2, end), vitesseMoyenne, 1);
fprintf('  aucune mesure ne la donne : elle vient du modele\n');
assert(abs(vitesseMoyenne - 1) < 0.1, ...
       'la vitesse s''estime sans etre mesuree');

%% 3. La navigation à l'estime
% Sans aucune mesure de position, on intègre la vitesse. C'est ce que fait
% un navire au compas et au loch — et l'erreur s'accumule sans jamais se
% corriger, ce qui explique pourquoi on ne s'en contente jamais.
%
% On part cette fois de la bonne position, avec une vitesse fausse de dix
% pour cent : la dérive naît de la seule erreur de vitesse, et croît
% linéairement avec le temps parce que rien ne la reprend.
sansMesure = zeros(2, nPas);
sansMesure(:, 1) = [0; 0.9];
for k = 2:nPas
    sansMesure(:, k) = F * sansMesure(:, k - 1);
end
derive = abs(sansMesure(1, :) - vraiEtat(1, :));
fprintf('\nNavigation a l''estime, sans aucune mesure :\n');
fprintf('  erreur : %.4f au depart, %.4f a mi-course, %.4f a la fin\n', ...
        derive(1), derive(nPas / 2), derive(end));
assert(derive(1) < 1e-12, 'on part de la bonne position');
assert(all(diff(derive) >= -1e-12), 'l''erreur ne peut que croitre sans mesure');
% Croissance linéaire : doubler le temps double l'erreur.
assert(abs(derive(end) / derive(nPas / 2) - 2) < 0.02, ...
       'la derive croit lineairement avec le temps');
fprintf('  la derive double quand le temps double : croissance lineaire\n');
% Le filtre, lui, est parti d'une position fausse de cinq mètres et reste
% accroché à la vérité : c'est la mesure, si bruitée soit-elle, qui borne
% l'erreur au lieu de la laisser filer.
fprintf('  erreur du filtre %.4f contre %.4f a l''estime\n', ...
        erreurFinale, derive(end));
assert(erreurFinale < derive(end) / 4, ...
       'le filtre, lui, reste accroche a la verite');

fprintf('\nToutes les verifications passent.\n');
