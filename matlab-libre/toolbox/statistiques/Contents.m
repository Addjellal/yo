% Statistics and Machine Learning Toolbox — statistiques et apprentissage.
%
% Chaque loi suit la même convention que MATLAB : ...PDF pour la densité
% ou la probabilité, ...CDF pour la répartition, ...INV pour le quantile,
% ...RND pour les tirages, ...STAT pour la moyenne et la variance, ...FIT
% pour l'estimation des paramètres.
%
% Lois decentrees (puissance des tests)
%   ncx2pdf, ncx2cdf, ncx2inv          - Khi-deux decentre
%   nctpdf, nctcdf, nctinv             - Student decentre
%   ncfpdf, ncfcdf, ncfinv             - Fisher decentre
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
%   gevpdf, gevcdf, gevinv, gevrnd     - Valeurs extrêmes généralisées
%   gevfit
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
% Lois multivariées
%   mvnpdf, mvncdf, mvnrnd             - Normale : densité, répartition,
%                                        tirages
%   wishrnd, iwishrnd                  - Wishart et Wishart inverse
%
% Descriptions
%   zscore, iqr, mad, skewness, kurtosis, tabulate
%   geomean, harmmean, trimmean        - Moyennes géométrique, harmonique,
%                                        élaguée
%   tiedrank                           - Rangs, les liens au rang moyen
%   corr                               - Pearson, Spearman, Kendall
%   crosstab                           - Table de contingence et khi-deux
%   ksdensity                          - Densité estimée par noyau
%   ecdf                               - Répartition empirique
%   bootstrp, bootci, jackknife        - Rééchantillonnage
%   boxplot                            - Boîtes à moustaches
%   normplot, probplot, histfit        - Diagrammes de loi
%   normspec                           - Densité et tolérances
%   refline, refcurve, lsline, gname   - Ajouts à un tracé
%
% Valeurs manquantes
%   nanmean, nanmedian, nanstd, nanvar - La famille NAN..., qui écarte
%   nansum, nanmax, nanmin, nancov       les NaN. Depuis R2015a, on écrit
%                                        plutôt mean(x,'omitnan').
%
% Groupes
%   grp2idx                            - Numérote les modalités
%   grpstats                           - Moyennes et écarts par groupe
%
% Tests
%   ttest, ttest2                      - Student, un et deux échantillons
%   ztest                              - Moyenne, écart type connu
%   vartest, vartest2                  - Variance : khi-deux, Fisher
%   anova1, anova2                     - Analyse de variance à un, deux
%                                        facteurs
%   multcompare                        - Comparaisons deux à deux
%   kruskalwallis, friedman            - Analyse de variance sur les rangs
%   ranksum                            - Wilcoxon-Mann-Whitney
%   signrank, signtest                 - Rangs signés, signe
%   kstest, kstest2                    - Kolmogorov-Smirnov
%   jbtest, lillietest                 - Normalité
%   chi2gof                            - Adéquation par le khi-deux
%   runstest                           - Suites : l'ordre est-il quelconque ?
%
% Régression
%   regress, fitlm                     - Moindres carrés, avec diagnostics
%   regstats                           - Leviers, distance de Cook,
%                                        Durbin-Watson
%   robustfit                          - Moindres carrés repondérés
%   ridge, stepwisefit                 - Pénalisation, sélection pas à pas
%   nlinfit, nlparci                   - Ajustement non linéaire
%   polyconf                           - Intervalle de prédiction d'un
%                                        polynôme
%   hougen                             - Le modèle d'essai de Hougen-Watson
%
% Apprentissage
%   pca, princomp, pcacov              - Analyse en composantes principales
%   canoncorr                          - Corrélations canoniques
%   cmdscale, mdscale                  - Positionnement multidimensionnel
%   procrustes                         - Superposition de deux nuages
%   kmeans, silhouette                 - Partitionnement
%   pdist, pdist2, squareform, mahal   - Distances entre observations
%   linkage, cluster, clusterdata      - Regroupement hiérarchique
%   cophenet, dendrogram               - Fidélité de l'arbre, et son dessin
%   knnsearch, fitcknn                 - Plus proches voisins
%   fitctree, fitrtree                 - Arbres de décision et de régression
%   fitcnb                             - Bayésien naïf
%   fitcsvm, fitrsvm                   - Vecteurs de support
%   discardSupportVectors              - Allège une SVM linéaire
%   fitclinear, fitrlinear             - Modèles linéaires en grande dimension
%   fitcecoc                           - Plusieurs classes par codes correcteurs
%   fitrgp                             - Processus gaussien
%   predict                            - Prédiction, quel que soit le modèle
%   relieff, sequentialfs              - Choix de variables
%   confusionmat                       - Matrice de confusion
%   cvpartition                        - Découpage pour la validation croisée
%
% Modèles de régression
%   fitglm                             - Modèle linéaire généralisé
%   mnrfit, mnrval                     - Logistique multinomiale
%   fitlme                             - Effets mixtes, intercept aléatoire
%   lasso                              - Régression pénalisée en norme 1
%   nnmf                               - Factorisation non négative
%
% Mélanges et modèles cachés
%   gmdistribution, fitgmdist          - Mélange gaussien, ajusté par EM
%   hmmgenerate, hmmdecode             - Modèle de Markov caché
%   hmmviterbi, hmmestimate, hmmtrain  - Chemin, estimation, Baum-Welch
%
% Analyse de la variance et plans
%   anovan                             - Plusieurs facteurs
%   manova1                            - Analyse multivariée
%   rowexch, x2fx                      - Plan D-optimal et matrice du modèle
%   polytool, stepwise                 - Ajustement polynomial, pas à pas
%
% Copules et simulation
%   copulacdf, copulapdf, copularnd    - Copules gaussienne, de Student,
%                                        de Clayton, de Frank, de Gumbel
%   pearsrnd                           - Loi du système de Pearson
%   slicesample                        - Échantillonnage par tranches
%   dataset                            - Tableau de données, ancienne forme
%
% Ajustement de lois
%   mle, fitdist                       - Maximum de vraisemblance
%   statset, statget                   - Options des ajustements
%
% Fonctions internes (absentes de MATLAB)
%   statAjuster, statForme, statEtendre - Règles de taille des arguments
%   statQuantileDiscret                 - Marche entière pour les ...INV
%   statPrefixeLoi                      - Nom de loi vers préfixe
%   matlibre_distance                   - Une métrique de PDIST
%   matlibre_arbre_reduit               - Le haut d'un arbre de fusions
%   matlibre_ordre_feuilles             - Feuilles rangées sans croisement
%   matlibre_gauss_legendre             - Nœuds et poids de quadrature
%   matlibre_normale_bivariee           - Drezner-Wesolowsky
%   matlibre_plage_studentisee          - Loi de Tukey, et sa répartition
%   matlibre_marge_comparaison          - Correction de multiplicité
%   matlibre_kolmogorov_queue           - Queue de la loi de Kolmogorov
%   matlibre_probabilite_suites         - Loi exacte du nombre de suites
%   matlibre_quantile_par_dichotomie    - Inverse d'une répartition
%   matlibre_poids_robuste              - Fonctions de poids de ROBUSTFIT
%   matlibre_nelder_mead                - Simplexe, sans dérivée
%   matlibre_regression_isotone         - La suite croissante la plus proche
%   matlibre_points_traces              - Les points déjà dessinés
%   predictBayesNaif, predictSvm        - Rouages de PREDICT
%   predictLineaire, predictEcoc        - Idem
%   predictGp, predictArbreRegression   - Idem
%   clusterMelange, tirerMelange        - Rouages des mélanges gaussiens
%   lireOptionsSvm, noyauSvm            - Rouages des SVM
%   standardiserSvm, resoudreSmo        - Idem
%   lireOptionsLineaire, descenteLineaire - Rouages des modèles linéaires
%   noyauGp                             - Covariance d'un processus gaussien
%   normaliserLignes, lireNomsHmm       - Rouages des modèles cachés
%   indicesSymboles                     - Idem
