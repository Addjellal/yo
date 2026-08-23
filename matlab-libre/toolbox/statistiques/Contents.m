% Statistics and Machine Learning Toolbox — statistiques et apprentissage.
%
% Chaque loi suit la même convention que MATLAB : ...PDF pour la densité
% ou la probabilité, ...CDF pour la répartition, ...INV pour le quantile,
% ...RND pour les tirages, ...STAT pour la moyenne et la variance, ...FIT
% pour l'estimation des paramètres.
%
% Lois continues
%   normpdf, normcdf, norminv, normrnd - Loi normale (natives)
%   normstat, normfit, normlike        - Moments, ajustement, vraisemblance
%   betapdf, betacdf, betainv, betarnd - Loi bêta
%   betastat, betafit, betalike
%   gampdf, gamcdf, gaminv, gamrnd     - Loi gamma
%   gamstat, gamfit
%   chi2pdf, chi2cdf, chi2inv          - Khi-deux
%   chi2rnd, chi2stat
%   tpdf, tcdf, tinv, trnd, tstat      - Student
%   fpdf, fcdf, finv, frnd, fstat      - Fisher-Snedecor
%   exppdf, expcdf, expinv, exprnd     - Exponentielle
%   expstat, expfit
%   unifpdf, unifcdf, unifinv, unifrnd - Uniforme continue
%   unifstat, unifit
%   raylpdf, raylcdf, raylinv, raylrnd - Rayleigh
%   raylstat, raylfit
%   wblpdf, wblcdf, wblinv, wblrnd     - Weibull
%   wblstat, wblfit
%   lognpdf, logncdf, logninv, lognrnd - Log-normale
%   lognstat, lognfit
%   evpdf, evcdf, evinv, evrnd, evstat - Valeurs extrêmes (Gumbel)
%
% Lois discrètes
%   binopdf, binocdf, binoinv, binornd - Binomiale
%   binostat, binofit                    (intervalle de Clopper-Pearson)
%   poisspdf, poisscdf, poissinv       - Poisson
%   poissrnd, poisstat, poissfit
%   geopdf, geocdf, geoinv, geornd     - Géométrique
%   geostat
%   hygepdf, hygecdf, hygeinv          - Hypergéométrique
%   hygernd, hygestat
%   nbinpdf, nbincdf, nbininv          - Binomiale négative
%   nbinrnd, nbinstat
%   unidpdf, unidcdf, unidinv          - Uniforme discrète
%   unidrnd, unidstat
%
% Accès par nom de loi
%   pdf, cdf, icdf, random             - 'Normal', 'Poisson', 'Weibull'…
%
% Descriptions
%   zscore, iqr, mad, skewness, kurtosis, tabulate
%   crosstab                           - Table de contingence et khi-deux
%   ksdensity                          - Densité estimée par noyau
%   bootstrp                           - Rééchantillonnage bootstrap
%
% Tests
%   ttest, ttest2                      - Student, un et deux échantillons
%   anova1                             - Analyse de variance à un facteur
%   ranksum                            - Wilcoxon-Mann-Whitney
%   signrank                           - Rangs signés de Wilcoxon
%   kstest                             - Kolmogorov-Smirnov
%
% Régression
%   regress, fitlm                     - Moindres carrés, avec diagnostics
%
% Apprentissage
%   pca                                - Analyse en composantes principales
%   kmeans, silhouette                 - Partitionnement
%   knnsearch, fitcknn, predictknn     - Plus proches voisins
%   fitctree, predicttree              - Arbre de décision
%   confusionmat                       - Matrice de confusion
%   cvpartition                        - Découpage pour la validation croisée
%
% Fonctions internes (absentes de MATLAB)
%   statAjuster, statForme, statEtendre - Règles de taille des arguments
%   statQuantileDiscret                 - Marche entière pour les ...INV
%   statPrefixeLoi                      - Nom de loi vers préfixe
