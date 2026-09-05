% statistiques.m — Statistics and Machine Learning Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/statistiques.m
%
% Le cas : un essai clinique imaginaire. Deux groupes, un traitement, et
% la question qu'on se pose toujours — l'écart observé est-il réel, ou
% le hasard suffit-il à l'expliquer ?

fprintf('=== Statistiques : decrire, tester, ajuster, classer ===\n\n');

%% 1. Décrire
rng(42);
temoin = 100 + 15 * randn(60, 1);
traite = 108 + 15 * randn(60, 1);
fprintf('Groupe temoin : n = %d\n', numel(temoin));
fprintf('  moyenne %.2f, ecart type %.2f, mediane %.2f\n', ...
        mean(temoin), std(temoin), median(temoin));
fprintf('  quartiles %s\n', mat2str(round(prctile(temoin, [25 50 75]), 2)));
fprintf('Groupe traite : n = %d\n', numel(traite));
fprintf('  moyenne %.2f, ecart type %.2f\n', mean(traite), std(traite));
% L'écart type de l'échantillon divise par n-1 : c'est ce qui le rend
% non biaisé pour la variance de la population.
assert(abs(var(temoin) - sum((temoin - mean(temoin)) .^ 2) / (numel(temoin) - 1)) < 1e-10);
assert(abs(std(temoin) ^ 2 - var(temoin)) < 1e-10);

%% 2. Tester
% Le test de Student compare deux moyennes. Il rend une décision, une
% probabilité critique, et un intervalle de confiance sur l'écart.
[decision, p, intervalle, statistiques] = ttest2(traite, temoin);
fprintf('\nTest de Student a deux echantillons :\n');
fprintf('  ecart des moyennes : %.3f\n', mean(traite) - mean(temoin));
fprintf('  t = %.4f, ddl = %d, p = %.5f\n', statistiques.tstat, statistiques.df, p);
fprintf('  intervalle de confiance a 95 %% : [%.3f %.3f]\n', intervalle(1), intervalle(2));
fprintf('  decision : %s\n', ternaire(decision, 'ecart significatif', 'rien de concluant'));
% Un intervalle de confiance qui exclut zéro et un p sous 5 %, c'est la
% même information dite deux fois.
assert((p < 0.05) == (intervalle(1) > 0 || intervalle(2) < 0));
assert(intervalle(1) < mean(traite) - mean(temoin));
assert(intervalle(2) > mean(traite) - mean(temoin));

% Le test de normalité, avant de se fier au précédent.
[normal, pNormal] = kstest((temoin - mean(temoin)) / std(temoin));
fprintf('  normalite du temoin : p = %.4f, %s\n', pNormal, ...
        ternaire(normal, 'rejetee', 'non rejetee'));

% Un test non paramétrique, qui ne suppose pas la normalité.
pRang = ranksum(traite, temoin);
fprintf('  test des rangs : p = %.5f\n', pRang);

%% 3. Lois de probabilité
% Chaque loi vient avec sa densité, sa fonction de répartition, son
% inverse et son tirage. Les quatre sont cohérentes entre elles.
mu = 100;
sigma = 15;
assert(abs(normcdf(norminv(0.975, mu, sigma), mu, sigma) - 0.975) < 1e-10);
assert(abs(normpdf(mu, mu, sigma) - 1 / (sigma * sqrt(2 * pi))) < 1e-12);
fprintf('\nLoi normale (%g, %g) :\n', mu, sigma);
fprintf('  quantile 97.5 %% : %.4f\n', norminv(0.975, mu, sigma));
fprintf('  P(X < 130)      : %.4f\n', normcdf(130, mu, sigma));
% La règle des trois sigmas, vérifiée plutôt que récitée.
fprintf('  P(|X - mu| < 2 sigma) : %.6f\n', ...
        normcdf(mu + 2 * sigma, mu, sigma) - normcdf(mu - 2 * sigma, mu, sigma));
assert(abs(normcdf(mu + 2 * sigma, mu, sigma) - normcdf(mu - 2 * sigma, mu, sigma) ...
           - 0.9545) < 1e-3);
% Ajuster une loi sur des données, et retrouver ses paramètres.
[muEstime, sigmaEstime] = normfit(temoin);
fprintf('  ajustee sur le temoin : mu = %.2f, sigma = %.2f\n', muEstime, sigmaEstime);
assert(abs(muEstime - mean(temoin)) < 1e-10);

%% 4. Régression
% Une droite, ses coefficients, et ce qu'ils valent.
n = 80;
x = linspace(0, 10, n)';
rng(7);
y = 2.5 * x + 4 + 1.5 * randn(n, 1);
X = [ones(n, 1), x];
[coefficients, intervalles, residus, ~, stats] = regress(y, X);
fprintf('\nRegression lineaire :\n');
fprintf('  ordonnee a l''origine %.4f (vraie 4)\n', coefficients(1));
fprintf('  pente                %.4f (vraie 2.5)\n', coefficients(2));
fprintf('  R2 = %.4f, F = %.2f, p = %.3g\n', stats(1), stats(2), stats(3));
assert(abs(coefficients(2) - 2.5) < 0.2);
assert(stats(1) > 0.9);
% Les moindres carrés rendent les résidus orthogonaux aux régresseurs :
% c'est leur définition même.
assert(max(abs(X' * residus)) < 1e-9);
% Et l'intervalle de confiance contient la vraie valeur.
assert(intervalles(2, 1) < 2.5 && intervalles(2, 2) > 2.5);

% Une régression polynomiale, quand la droite ne suffit pas.
yCourbe = 0.5 * x .^ 2 - 3 * x + 10 + 0.5 * randn(n, 1);
coefficientsPoly = polyfit(x, yCourbe, 2);
fprintf('  polynome de degre 2 : %s (vrai [0.5 -3 10])\n', ...
        mat2str(round(coefficientsPoly, 3)));
assert(max(abs(coefficientsPoly - [0.5 -3 10])) < 0.3);

%% 5. Classer
% Trois nuages, et deux méthodes pour les retrouver : l'une sans
% étiquettes, l'autre avec.
rng(3);
centres = [0 0; 5 5; 0 6];
donnees = [];
verite = [];
for k = 1:3
    donnees = [donnees; centres(k, :) + 0.8 * randn(40, 2)];   %#ok<AGROW>
    verite = [verite; k * ones(40, 1)];                        %#ok<AGROW>
end
[groupes, centresTrouves] = kmeans(donnees, 3);
fprintf('\nClassification non supervisee (kmeans) :\n');
fprintf('  %d groupes, tailles %s\n', numel(unique(groupes)), ...
        mat2str(histcounts(groupes, 1:4)));
% Les centres trouvés sont les vrais, à l'ordre près.
distances = zeros(1, 3);
for k = 1:3
    distances(k) = min(sqrt(sum((centresTrouves - centres(k, :)) .^ 2, 2)));
end
fprintf('  ecart aux vrais centres : %s\n', mat2str(round(distances, 3)));
assert(max(distances) < 0.5);

% Avec étiquettes : l'analyse discriminante.
modele = fitcdiscr(donnees, verite);
predites = predict(modele, donnees);
justesse = mean(predites == verite);
fprintf('  justesse de l''analyse discriminante : %.2f %%\n', justesse * 100);
assert(justesse > 0.95);
confusion = confusionmat(verite, predites);
fprintf('  matrice de confusion :\n');
disp(confusion);
assert(sum(confusion(:)) == numel(verite));
assert(sum(diag(confusion)) == sum(predites == verite));

%% 6. Analyse en composantes principales
% Trouver les directions qui portent l'information. La première explique
% le plus de variance, et les composantes sont décorrélées entre elles.
[vecteurs, projections, valeurs] = pca(donnees);
part = valeurs / sum(valeurs) * 100;
fprintf('\nComposantes principales :\n');
fprintf('  variance expliquee : %s %%\n', mat2str(round(part', 2)));
assert(abs(sum(part) - 100) < 1e-9);
assert(part(1) >= part(2), 'les composantes sont rangees par variance');
% Les projections sont décorrélées, et les axes orthonormés.
assert(abs(corr(projections(:, 1), projections(:, 2))) < 1e-10);
assert(max(max(abs(vecteurs' * vecteurs - eye(2)))) < 1e-10);

fprintf('\nToutes les verifications passent.\n');

function texte = ternaire(condition, siVrai, siFaux)
    if condition
        texte = siVrai;
    else
        texte = siFaux;
    end
end
