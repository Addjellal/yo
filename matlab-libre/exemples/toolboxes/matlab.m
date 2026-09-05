% matlab.m — la bibliothèque de base, cas d'école.
%
%   matlibre exemples/toolboxes/matlab.m
%
% Le cas : un jeu de mesures à charger, nettoyer, analyser et tracer.
% C'est la boucle de travail la plus courante, et elle n'emploie que la
% bibliothèque de base — aucune boîte à outils.

fprintf('=== Bibliotheque de base : charger, nettoyer, analyser, tracer ===\n\n');

%% 1. L'algèbre linéaire
% Résoudre A x = b, et savoir si le résultat est fiable.
A = [4 -2 1; -2 4 -2; 1 -2 4];
b = [11; -16; 17];
x = A \ b;
fprintf('Systeme lineaire 3x3 :\n');
fprintf('  solution %s\n', mat2str(round(x', 6)));
fprintf('  residu %.3e\n', norm(A * x - b));
assert(norm(A * x - b) < 1e-12);
% Le conditionnement dit combien l'erreur sur b se retrouve sur x.
fprintf('  conditionnement %.4f\n', cond(A));
assert(cond(A) < 100, 'ce systeme est bien conditionne');
% Une matrice symetrique definie positive : ses valeurs propres sont
% positives, et sa factorisation de Cholesky existe.
valeursPropres = sort(eig(A));
fprintf('  valeurs propres %s\n', mat2str(round(valeursPropres', 4)));
assert(all(valeursPropres > 0));
R = chol(A);
assert(max(max(abs(R' * R - A))) < 1e-12, 'A = R'' R par definition');
% La decomposition en valeurs singulieres, la plus generale.
[U, S, V] = svd(A);
assert(max(max(abs(U * S * V' - A))) < 1e-12);
assert(max(max(abs(U' * U - eye(3)))) < 1e-12, 'U est orthogonale');
% Pour une matrice symetrique, valeurs singulieres et valeurs propres
% coincident en module.
assert(max(abs(sort(diag(S)) - sort(abs(valeursPropres)))) < 1e-12);

%% 2. Les données
% Charger, repérer les manques, les combler ou les écarter.
rng(1);
n = 200;
temps = (1:n)';
mesures = 20 + 5 * sin(temps / 20) + 0.8 * randn(n, 1);
mesures([37 38 91 150]) = NaN;
mesures(120) = 95;                      % une valeur aberrante
fprintf('\nJeu de %d mesures :\n', n);
fprintf('  %d valeurs manquantes\n', sum(ismissing(mesures)));
assert(sum(ismissing(mesures)) == 4);
% La moyenne ordinaire est contaminee par les manques ; celle qui les
% omet ne l'est pas.
assert(isnan(mean(mesures)));
fprintf('  moyenne en omettant les manques : %.4f\n', mean(mesures, 'omitnan'));
% Combler par interpolation.
comblees = fillmissing(mesures, 'linear');
assert(~any(ismissing(comblees)));
fprintf('  apres comblement : moyenne %.4f\n', mean(comblees));

% Repérer les valeurs aberrantes : celles qui s'écartent de plus de trois
% écarts absolus médians. La médiane est employée parce qu'elle ne bouge
% pas quand une valeur part très loin, contrairement à la moyenne.
aberrantes = isoutlier(comblees);
fprintf('  %d valeurs aberrantes reperees, a l''indice %s\n', ...
        sum(aberrantes), mat2str(find(aberrantes)'));
assert(aberrantes(120), 'la valeur a 95 doit etre reperee');
propres = filloutliers(comblees, 'linear');
fprintf('  apres correction : maximum %.4f (contre %.4f)\n', ...
        max(propres), max(comblees));
assert(max(propres) < 40);

%% 3. Les statistiques descriptives
fprintf('\nDescription :\n');
fprintf('  moyenne %.4f, mediane %.4f, ecart type %.4f\n', ...
        mean(propres), median(propres), std(propres));
fprintf('  etendue [%.4f %.4f]\n', min(propres), max(propres));
% Les bornes se lisent d'un coup.
% BOUNDS rend les deux bornes en deux sorties, comme dans MATLAB.
[borneBasse, borneHaute] = bounds(propres);
assert(borneBasse == min(propres) && borneHaute == max(propres));
% Les quantiles decoupent la distribution.
quartiles = prctile(propres, [25 50 75]);
fprintf('  quartiles %s\n', mat2str(round(quartiles, 4)));
assert(abs(quartiles(2) - median(propres)) < 1e-9);
assert(quartiles(1) < quartiles(2) && quartiles(2) < quartiles(3));
% Une moyenne mobile lisse ; sa longueur decide de ce qu'on garde.
lisse = movmean(propres, 15);
fprintf('  ecart type : brut %.4f, lisse %.4f\n', std(propres), std(lisse));
assert(std(lisse) < std(propres), 'lisser reduit la dispersion');
assert(numel(lisse) == numel(propres), 'la longueur est preservee');

%% 4. Grouper
% Découper en catégories, puis résumer chaque groupe. C'est l'opération
% qui structure toute analyse de données.
tranches = discretize(propres, [0 18 22 100], 'categorical', ...
                      {'bas', 'moyen', 'haut'});
[groupes, noms] = findgroups(tranches);
moyennes = splitapply(@mean, propres, groupes);
comptes = splitapply(@numel, propres, groupes);
fprintf('\nPar tranche :\n');
for k = 1:numel(noms)
    fprintf('  %-6s : %3d valeurs, moyenne %.4f\n', char(noms(k)), ...
            comptes(k), moyennes(k));
end
assert(sum(comptes) == n, 'chaque valeur tombe dans exactement une tranche');
% La moyenne des moyennes, ponderee, redonne la moyenne generale.
assert(abs(sum(moyennes .* comptes) / n - mean(propres)) < 1e-12);
% Les tranches sont ordonnees comme leurs bornes.
assert(moyennes(1) < moyennes(end));

%% 5. Le calcul numérique
% Intégrer, dériver, résoudre — sans formule.
fprintf('\nCalcul numerique :\n');
aire = integral(@(t) exp(-t .^ 2), -Inf, Inf);
fprintf('  integrale de exp(-t^2) sur R : %.10f (racine de pi %.10f)\n', ...
        aire, sqrt(pi));
assert(abs(aire - sqrt(pi)) < 1e-9);
% Une equation differentielle : la decroissance exponentielle.
[tSolution, ySolution] = ode45(@(t, y) -2 * y, [0 3], 3);
exacte = 3 * exp(-2 * tSolution);
fprintf('  ode45 sur y'' = -2y : ecart maximal %.3e\n', ...
        max(abs(ySolution - exacte)));
assert(max(abs(ySolution - exacte)) < 1e-5);
% Une racine.
racine = fzero(@(t) t ^ 3 - 2 * t - 5, 2);
fprintf('  racine de t^3 - 2t - 5 : %.10f\n', racine);
assert(abs(racine ^ 3 - 2 * racine - 5) < 1e-12);
% Un gradient numerique.
pente = gradient(propres);
assert(numel(pente) == numel(propres));

%% 6. Le texte et les fichiers
fprintf('\nTexte et fichiers :\n');
% Ecrire, relire, comparer.
fichier = [tempname '.csv'];
donnees = [temps, propres];
ecriture = fopen(fichier, 'w');
fprintf(ecriture, '%d,%.6f\n', donnees.');
fclose(ecriture);
relues = readmatrix(fichier);
fprintf('  %d lignes ecrites puis relues\n', size(relues, 1));
assert(isequal(size(relues), size(donnees)));
assert(max(max(abs(relues - donnees))) < 1e-5);
delete(fichier);
assert(~isfile(fichier), 'le fichier temporaire doit etre efface');
% Manipuler du texte.
phrase = "  Le premier essai du jour  ";
fprintf('  [%s] -> [%s]\n', phrase, strip(phrase));
assert(strlength(strip(phrase)) == strlength(phrase) - 4);
mots = split(strip(phrase));
assert(numel(mots) == 5);
assert(strcmp(join(mots, "-"), "Le-premier-essai-du-jour"));
% Chercher et remplacer avec une expression reguliere.
remplacee = regexprep("essai 12 et essai 34", '\d+', 'N');
assert(strcmp(remplacee, "essai N et essai N"));
nombres = regexp("essai 12 et essai 34", '\d+', 'match');
assert(isequal(nombres, {'12', '34'}));

%% 7. Le tracé
% Une figure hors écran : les exemples doivent tourner sans affichage.
figure('Visible', 'off');
plot(temps, propres, 'b-', temps, lisse, 'r-', 'LineWidth', 1);
xlabel('temps'); ylabel('mesure');
title('Mesures et moyenne mobile');
legend('brut', 'lisse', 'Location', 'best');
grid on;
axes1 = gca;
fprintf('\nTrace : %d courbes, axes de %.1f a %.1f\n', ...
        numel(findobj(axes1, 'Type', 'line')), axes1.XLim(1), axes1.XLim(2));
assert(numel(findobj(axes1, 'Type', 'line')) == 2);
% MatLibre dessine en SVG de bout en bout : le trace est vectoriel, sans
% matriceur. Un autre format est refuse plutot qu'ecrit ailleurs en
% silence.
image = [tempname '.svg'];
saveas(gcf, image);
assert(isfile(image), 'la figure doit s''enregistrer');
info = dir(image);
fprintf('  image enregistree : %d octets\n', info.bytes);
assert(info.bytes > 0);
contenu = fileread(image);
assert(contains(contenu, '<svg'), 'le fichier est bien du SVG');
delete(image);
refuseFormat = false;
try
    saveas(gcf, [tempname '.png']);
catch
    refuseFormat = true;
end
assert(refuseFormat, 'un format non gere doit etre refuse, non ecrit ailleurs');
close all;

fprintf('\nToutes les verifications passent.\n');
