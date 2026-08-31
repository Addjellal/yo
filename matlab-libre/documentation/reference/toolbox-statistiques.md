# Toolbox `statistiques`

```
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
%   knnsearch, fitcknn, predictknn     - Plus proches voisins
%   fitctree, predicttree              - Arbre de décision
%   confusionmat                       - Matrice de confusion
%   cvpartition                        - Découpage pour la validation croisée
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
```

## `anova1`

```
ANOVA1 Analyse de variance à un facteur.
  P = ANOVA1(Y,GROUPE) teste l'hypothèse « tous les groupes ont la même
  moyenne ». Y est un vecteur d'observations, GROUPE dit à quel groupe
  appartient chacune — sous la forme qu'accepte GRP2IDX : des nombres,
  des noms, un tableau de cellules.

  P = ANOVA1(Y) où Y est une matrice traite chaque colonne comme un
  groupe. C'est la forme la plus courte quand les groupes ont tous le
  même effectif.

  P est la probabilité critique : la chance d'observer un écart entre
  moyennes au moins aussi grand si toutes étaient égales. Une petite
  valeur conduit à rejeter cette égalité.

  [P,TABLEAU] = ANOVA1(...) rend en outre le tableau de l'analyse, sous
  la forme d'une structure :
     SSB, dfB    somme des carrés et degrés de liberté intergroupes ;
     SSW, dfW    idem intragroupes ;
     MSB, MSW    les carrés moyens, quotients des précédents ;
     F           leur rapport, la statistique du test ;
     p           la probabilité critique.

  [P,TABLEAU,STATS] = ANOVA1(...) rend de quoi comparer les groupes
  deux à deux par MULTCOMPARE : leurs moyennes, leurs effectifs, leurs
  noms et le degré de liberté résiduel.

  Le test suppose des groupes normaux et de même variance. Quand la
  normalité est douteuse, KRUSKALWALLIS répond à la même question sur
  les rangs.

  Exemples :
     y = [5 6 7 10 11 12];
     g = [1 1 1 2 2 2];
     anova1(y, g)                     % petit : les moyennes different

     anova1([1 2; 2 3; 3 4])          % deux colonnes, deux groupes

     [p, t, s] = anova1(y, g);
     t.F                              % la statistique de Fisher

  Voir aussi ANOVA2, KRUSKALWALLIS, MULTCOMPARE, TTEST2, GRPSTATS.
```

## `anova2`

```
ANOVA2 Analyse de variance à deux facteurs, plan équilibré.
  P = ANOVA2(Y,REPS) teste trois hypothèses à la fois sur un tableau Y
  dont les colonnes sont les niveaux d'un facteur et les lignes ceux
  d'un autre. REPS dit combien de lignes consécutives de Y sont des
  répétitions du même couple de niveaux ; il vaut 1 quand il n'y en a
  qu'une par case.

  P est un vecteur de deux ou trois probabilités critiques :
     P(1)  l'effet des colonnes ;
     P(2)  l'effet des lignes ;
     P(3)  leur interaction, quand REPS est supérieur à 1.

  [P,TABLEAU] = ANOVA2(...) rend le détail sous la forme d'une
  structure : sommes des carrés, degrés de liberté, carrés moyens et
  statistiques de Fisher pour les colonnes, les lignes, l'interaction
  et l'erreur.

  Le plan doit être équilibré : autant d'observations dans chaque case.
  C'est ce qui permet d'écrire les sommes des carrés comme une somme de
  termes indépendants.

  Exemples :
     % Trois traitements (colonnes), deux blocs (lignes), sans repetition
     y = [12 15 20; 13 16 22];
     anova2(y)

     % Deux repetitions par case
     y = [10 12; 11 13; 20 25; 21 24];
     anova2(y, 2)

  Voir aussi ANOVA1, KRUSKALWALLIS, FRIEDMAN, MULTCOMPARE.
```

## `betacdf`

```
BETACDF Fonction de répartition de la loi bêta.
  C'est la fonction bêta incomplète régularisée.
```

## `betafit`

```
BETAFIT Estimation des paramètres d'une loi bêta.
  Le maximum de vraisemblance est cherché par NELDER-MEAD sur
  BETALIKE, en partant de l'estimation par les moments.
```

## `betainv`

```
BETAINV Quantile de la loi bêta.
  Inversion par dichotomie de la bêta incomplète régularisée sur [0,1].

  Exemple :  betainv(0.5, 1, 1)   % 0.5, la loi uniforme
```

## `betalike`

```
BETALIKE Opposé de la log-vraisemblance d'une loi bêta.
  PARAMS vaut [A B] ; les données doivent être dans ]0,1[.
```

## `betapdf`

```
BETAPDF Densité de la loi bêta.
  Y = BETAPDF(X,A,B) = x^(a-1)*(1-x)^(b-1)/B(a,b) sur [0,1], nulle
  ailleurs.

  Exemple :  betapdf(0.5, 1, 1)   % 1 : la loi uniforme
```

## `betarnd`

```
BETARND Tirages d'une loi bêta.
  Le rapport G1/(G1+G2) de deux gammas indépendantes de formes A et B
  suit la loi bêta.
```

## `betastat`

```
BETASTAT Moyenne et variance de la loi bêta.
  Exemple :  [m,v] = betastat(1, 1)   % 0.5 et 1/12
```

## `binocdf`

```
BINOCDF Répartition de la loi binomiale.
  La somme des probabilités jusqu'à X s'écrit avec la bêta incomplète
  régularisée : P(X <= k) = I_{1-p}(n-k, k+1). C'est exact pour tout N,
  là où la somme directe coûterait N termes.

  Exemple :  binocdf(5, 10, 0.5)   % 0.623046875
```

## `binofit`

```
BINOFIT Estimation de la probabilité d'une loi binomiale.
  [PHAT,PCI] = BINOFIT(X,N,ALPHA) rend la proportion observée et
  l'intervalle de confiance exact de Clopper et Pearson, celui que
  MATLAB documente : ses bornes sont des quantiles de la loi bêta.
```

## `binoinv`

```
BINOINV Quantile de la loi binomiale.
  Le plus petit entier X tel que BINOCDF(X,N,P) >= Y.

  Exemple :  binoinv(0.5, 10, 0.5)   % 5
```

## `binornd`

```
BINORND Tirages d'une loi binomiale.
  Somme de N indicatrices de Bernoulli quand N est petit, inversion de
  la répartition sinon.
```

## `binostat`

```
BINOSTAT Moyenne et variance de la loi binomiale.
  Exemple :  [m,v] = binostat(10, 0.5)   % 5 et 2.5
```

## `bootci`

```
BOOTCI Intervalle de confiance par bootstrap.
  CI = BOOTCI(NBOOT,FONCTION,D) rend l'intervalle de confiance à 95
  pour cent de FONCTION(D), estimé en rééchantillonnant D avec remise
  NBOOT fois. FONCTION est une poignée ; D est un vecteur colonne, ou
  une matrice dont on tire les lignes.

  CI = BOOTCI(NBOOT,{FONCTION,D1,D2,...}) passe plusieurs jeux de
  données, rééchantillonnés ensemble : les lignes tirées sont les mêmes
  dans tous, ce qui préserve leur appariement.

  [CI,STATS] = BOOTCI(...) rend aussi les NBOOT valeurs simulées.

  BOOTCI(...,'alpha',A) change le niveau.
  BOOTCI(...,'type',T) choisit la méthode :
     'bca'       corrigée du biais et accélérée (défaut) : elle
                 redresse à la fois le décalage de la loi bootstrap et
                 sa dissymétrie, à l'aide du jackknife ;
     'percentile' ou 'per'  les simples quantiles empiriques ;
     'basic'     l'intervalle du pivot, réfléchi autour de l'estimation ;
     'normal' ou 'norm'  moyenne et écart type bootstrap, loi normale ;
     'student' ou 'stud' la forme studentisée, par un bootstrap
                 imbriqué.

  Le bootstrap répond à la question « de combien mon estimation
  aurait-elle varié si j'avais tiré un autre échantillon ? », sans
  demander de formule analytique : il convient donc aux statistiques
  pour lesquelles on n'en connaît pas, comme la médiane ou un rapport.

  Exemples :
     x = randn(100, 1) + 5;
     bootci(1000, @mean, x)                 % encadre 5
     bootci(1000, @median, x)
     bootci(1000, {@(a, b) corr(a, b), randn(50,1), randn(50,1)})
     bootci(1000, @mean, x, 'type', 'percentile')

  Voir aussi BOOTSTRP, NLPARCI, PRCTILE, JACKKNIFE, RANDSAMPLE.
```

## `bootstrp`

```
BOOTSTRP Rééchantillonnage bootstrap.
  S = BOOTSTRP(N,F,DONNEES) tire N échantillons avec remise dans les
  données et applique F à chacun. Chaque ligne de S est un tirage.

  Exemple :
     s = bootstrp(100, @mean, randn(50, 1));
```

## `boxplot`

```
BOXPLOT Boîtes à moustaches.
  BOXPLOT(Y) dessine une boîte à moustaches par colonne de Y. Pour un
  vecteur, une seule boîte.

  BOXPLOT(Y,GROUPE) dessine une boîte par groupe, GROUPE prenant l'une
  des formes qu'accepte GRP2IDX — des nombres, des noms, un tableau de
  cellules.

  Chaque boîte se lit ainsi :
     la boîte va du premier au troisième quartile ;
     le trait à l'intérieur est la médiane ;
     les moustaches vont jusqu'à l'observation la plus éloignée qui
     reste à moins de 1,5 écart interquartile de la boîte ;
     les points au-delà sont marqués d'une croix : ce sont les valeurs
     qu'on qualifie d'aberrantes, sans que cela préjuge de rien.

  BOXPLOT(...,'Labels',L) nomme les boîtes avec les chaînes de L.
  BOXPLOT(...,'Whisker',W) change le facteur 1,5 en W. W = 0 fait
  partir les moustaches jusqu'aux extrêmes, sans aucune valeur
  aberrante.
  BOXPLOT(...,'Orientation','horizontal') couche les boîtes.
  BOXPLOT(...,'Notch','on') creuse la boîte autour de la médiane, d'une
  profondeur qui donne un intervalle de confiance approché : deux
  encoches qui ne se recouvrent pas signalent des médianes différentes.

  Exemples :
     boxplot(randn(100, 3));

     y = [1 2 3 3 4 20 10 11 12 13];
     g = [1 1 1 1 1 1 2 2 2 2];
     boxplot(y, g);              % la valeur 20 sort en croix

     boxplot(randn(50, 2), 'Labels', {'avant', 'apres'});

  Voir aussi HISTOGRAM, PRCTILE, IQR, MEDIAN, GRPSTATS, ANOVA1.
```

## `canoncorr`

```
CANONCORR Analyse des corrélations canoniques.
  [A,B,R] = CANONCORR(X,Y) cherche les combinaisons linéaires des
  colonnes de X et de celles de Y qui sont le plus corrélées entre
  elles. A et B portent les coefficients de ces combinaisons, une par
  colonne ; R donne les corrélations obtenues, en ordre décroissant.

  C'est la généralisation de la corrélation à deux groupes de
  variables : au lieu de demander comment une variable de X est liée à
  une variable de Y, on demande comment l'ensemble X est lié à
  l'ensemble Y. La première paire canonique est celle qui capte le plus
  de ce lien, la deuxième la plus grande part de ce qui reste, et ainsi
  de suite.

  [A,B,R,U,V] = CANONCORR(X,Y) rend aussi les variables canoniques :
  U = (X - moyenne) * A et V = (Y - moyenne) * B. La corrélation entre
  U(:,k) et V(:,k) vaut R(k) ; toutes les autres paires sont
  décorrélées.

  [A,B,R,U,V,STATS] = CANONCORR(X,Y) rend le test de Bartlett de la
  nullité des corrélations restantes : STATS.p(k) est la probabilité
  critique de l'hypothèse « toutes les corrélations à partir de la
  k-ième sont nulles ».

  Le calcul passe par les factorisations QR de X et Y centrées, puis
  par la décomposition en valeurs singulières de leur produit : c'est
  la voie stable, qui n'inverse aucune matrice de covariance.

  Exemples :
     % Y depend de X par une seule combinaison
     X = randn(100, 3);
     Y = [X(:,1) - X(:,2), randn(100, 1)] + 0.1 * randn(100, 2);
     [A, B, r] = canoncorr(X, Y);
     r(1)                        % proche de 1
     r(2)                        % beaucoup plus petit

  Voir aussi CORR, PCA, PCACOV, REGRESS, SVD.
```

## `cdf`

```
CDF Fonction de répartition d'une loi nommée.
  P = CDF('name', X, A, B, C).

  Exemple :  cdf('Poisson', 2, 1)   % 0.9197
```

## `chi2cdf`

```
CHI2CDF Répartition du khi-deux : gamma incomplète régularisée.
```

## `chi2gof`

```
CHI2GOF Test du khi-deux d'adéquation.
  H = CHI2GOF(X) teste l'hypothèse « X suit une loi normale ». Les
  observations sont réparties en classes, et l'on compare l'effectif
  observé de chaque classe à celui qu'on attendrait sous la loi. La
  statistique est

     chi2 = somme (observe - attendu)^2 / attendu

  qui suit une loi du khi-deux à K-1-P degrés de liberté, où K est le
  nombre de classes et P le nombre de paramètres estimés sur les
  données — deux pour une normale ajustée.

  [H,P] = CHI2GOF(...) rend la probabilité critique.
  [H,P,STATS] = CHI2GOF(...) rend le détail : les bords des classes,
  les effectifs observés et attendus, la statistique et les degrés de
  liberté.

  CHI2GOF(...,'NBins',N) fixe le nombre de classes, dix par défaut.
  CHI2GOF(...,'Edges',E) impose les bords des classes.
  CHI2GOF(...,'CDF',F) teste une autre loi que la normale : F est une
  poignée de fonction qui rend la répartition, par exemple
  @(t) expcdf(t, 2). Aucun paramètre n'est alors compté comme estimé.
  CHI2GOF(...,'Expected',E) donne directement les effectifs attendus,
  ce qui teste une loi discrète connue.
  CHI2GOF(...,'NParams',P) dit combien de paramètres ont été estimés.
  CHI2GOF(...,'EMin',M) fusionne les classes dont l'effectif attendu
  tombe sous M, cinq par défaut : l'approximation du khi-deux ne vaut
  que si les classes sont assez garnies.
  CHI2GOF(...,'Alpha',A) change le seuil.

  Exemples :
     chi2gof(randn(500, 1))                      % 0 : normal
     chi2gof(exprnd(1, 500, 1))                  % 1 : ne l'est pas
     chi2gof(exprnd(2, 500, 1), 'CDF', @(t) expcdf(t, 2))

     % Un de six faces, lance six cents fois
     des = randi(6, 600, 1);
     chi2gof(des, 'Edges', 0.5:1:6.5, 'Expected', repmat(100, 1, 6))

  Voir aussi KSTEST, LILLIETEST, JBTEST, CROSSTAB, HISTCOUNTS.
```

## `chi2inv`

```
CHI2INV Quantile du khi-deux, par dichotomie sur la répartition.
  Exemple :  chi2inv(0.95, 1)   % 3.8415
```

## `chi2rnd`

```
CHI2RND Tirages d'un khi-deux à V degrés de liberté.
  Le khi-deux à V degrés est une gamma de forme V/2 et d'échelle 2.
```

## `chi2stat`

```
CHI2STAT Moyenne et variance du khi-deux.
  Exemple :  [m,v] = chi2stat(4)   % 4 et 8
```

## `cluster`

```
CLUSTER Coupe un arbre de regroupement en groupes.
  T = CLUSTER(Z,'maxclust',K) coupe l'arbre Z — celui que rend
  LINKAGE — de façon à obtenir au plus K groupes, et rend un vecteur
  qui donne, pour chaque observation, le numéro de son groupe. La
  coupure se fait à la plus petite hauteur qui laisse K groupes : on
  défait simplement les K-1 dernières fusions.

  T = CLUSTER(Z,'cutoff',C) coupe à la hauteur C : deux observations
  sont dans le même groupe si elles ont été réunies en dessous de C.

  T = CLUSTER(Z,'cutoff',C,'criterion','distance') est la même chose,
  écrite comme dans MATLAB.

  Les groupes sont numérotés dans l'ordre où leur première observation
  apparaît, de sorte que T(1) vaut toujours 1.

  Exemples :
     X = [1 1; 1.2 1; 5 5; 5.1 5.2];
     Z = linkage(X);
     cluster(Z, 'maxclust', 2)     % [1;1;2;2]
     cluster(Z, 'cutoff', 1)       % la meme coupure, par la hauteur

  Voir aussi LINKAGE, CLUSTERDATA, DENDROGRAM, COPHENET, KMEANS.
```

## `clusterdata`

```
CLUSTERDATA Regroupe des observations, de la distance à la coupure.
  T = CLUSTERDATA(X,CUTOFF) fait d'un seul geste ce que font PDIST,
  LINKAGE et CLUSTER : il calcule les distances entre les lignes de X,
  bâtit l'arbre, puis le coupe.

  Si CUTOFF est un entier supérieur ou égal à 2, c'est le nombre de
  groupes voulu. Sinon, c'est une hauteur de coupure. C'est la règle de
  MATLAB, un peu surprenante : CLUSTERDATA(X,2) demande deux groupes,
  CLUSTERDATA(X,2.0001) coupe à la hauteur 2.0001.

  T = CLUSTERDATA(X,'maxclust',K) lève l'ambiguïté et demande K groupes.
  T = CLUSTERDATA(X,'cutoff',C) coupe à la hauteur C.

  Les options 'linkage' et 'distance' choisissent la méthode de LINKAGE
  et la métrique de PDIST :

     T = clusterdata(X, 'maxclust', 3, 'linkage', 'ward');

  Exemples :
     X = [1 1; 1.2 1; 5 5; 5.1 5.2];
     clusterdata(X, 2)                       % [1;1;2;2]
     clusterdata(X, 'maxclust', 2, 'linkage', 'average')

  Voir aussi PDIST, LINKAGE, CLUSTER, DENDROGRAM, KMEANS.
```

## `cmdscale`

```
CMDSCALE Positionnement multidimensionnel métrique.
  Y = CMDSCALE(D) cherche des coordonnées dont les distances
  euclidiennes reproduisent les dissemblances D. D est la matrice
  carrée des distances, ou le vecteur que rend PDIST.

  C'est l'analyse en coordonnées principales : on double-centre la
  matrice des carrés des distances, on la diagonalise, et les vecteurs
  propres mis à l'échelle de leurs valeurs propres donnent les
  coordonnées. Quand D vient bel et bien d'un nuage euclidien, on le
  retrouve exactement, à une isométrie près.

  Y = CMDSCALE(D,P) ne garde que les P premières coordonnées.

  [Y,E] = CMDSCALE(D) rend en outre les valeurs propres. Elles disent
  combien de dimensions sont nécessaires : celles qui sont
  négligeables — ou négatives, quand D n'est pas euclidienne — peuvent
  être laissées.

  Exemples :
     X = [0 0; 3 0; 0 4; 3 4];
     Y = cmdscale(pdist(X));
     max(abs(pdist(Y) - pdist(X)))     % nul a l'arrondi pres

     [Y, e] = cmdscale(pdist(randn(20, 3)));
     e(1:5)'                            % trois valeurs, puis du bruit

  Voir aussi MDSCALE, PDIST, SQUAREFORM, PCA, PROCRUSTES.
```

## `confusionmat`

```
CONFUSIONMAT Matrice de confusion.
  M(i,j) compte les observations de la classe i classées en j.
```

## `cophenet`

```
COPHENET Corrélation cophénétique : l'arbre est-il fidèle aux distances ?
  C = COPHENET(Z,Y) compare l'arbre Z que rend LINKAGE aux distances Y
  que rend PDIST. Pour chaque paire d'observations, la distance
  cophénétique est la hauteur à laquelle l'arbre les réunit ; C est la
  corrélation entre ces hauteurs et les distances vraies.

  C vaut au plus 1. Une valeur proche de 1 dit que l'arbre représente
  fidèlement les distances ; une valeur basse, que le regroupement les
  a beaucoup déformées. C'est le moyen usuel de choisir entre plusieurs
  méthodes de LINKAGE sur le même jeu de données.

  [C,D] = COPHENET(Z,Y) rend en outre le vecteur D des distances
  cophénétiques, rangé comme celui de PDIST.

  Exemples :
     X = [1 1; 1.2 1; 5 5; 5.1 5.2];
     Y = pdist(X);
     cophenet(linkage(X, 'single'), Y)
     cophenet(linkage(X, 'average'), Y)   % souvent la meilleure

  Voir aussi LINKAGE, PDIST, CLUSTER, DENDROGRAM, SQUAREFORM.
```

## `corr`

```
CORR Corrélation linéaire ou de rangs entre colonnes.
  RHO = CORR(X) rend la matrice P x P des corrélations entre les P
  colonnes de X. La diagonale vaut 1.

  RHO = CORR(X,Y) rend la matrice des corrélations entre chaque colonne
  de X et chaque colonne de Y ; elle a autant de lignes que X a de
  colonnes et autant de colonnes que Y en a.

  [RHO,PVAL] = CORR(...) rend en outre la probabilité critique du test
  « la corrélation vraie est nulle ». Une petite valeur — moins de 0.05
  par exemple — signifie qu'une corrélation aussi forte serait rare si
  les deux variables étaient sans lien.

  CORR(...,'type',T) choisit la mesure :
     'Pearson'   la corrélation linéaire ordinaire (défaut) ;
     'Spearman'  la corrélation de Pearson sur les rangs, qui mesure
                 une croissance conjointe même non linéaire ;
     'Kendall'   le tau de Kendall, fondé sur les paires concordantes.

  CORR diffère de CORRCOEF sur deux points : il accepte deux matrices
  de largeurs différentes, et il connaît les rangs.

  Exemples :
     x = (1:10)';
     corr(x, x .^ 3)                       % 0.9284 : lié, mais courbé
     corr(x, x .^ 3, 'type', 'Spearman')   % 1 exactement : monotone
     [r, p] = corr(randn(50, 1), randn(50, 1));   % p souvent grand

  Voir aussi CORRCOEF, COV, TIEDRANK, PARTIALCORR, REGRESS.
```

## `crosstab`

```
CROSSTAB Table de contingence de deux variables discrètes.
  [T,CHI2,P] = CROSSTAB(X,Y) rend la table des effectifs, la statistique
  du khi-deux d'indépendance et sa p-valeur.

  Exemple :
     crosstab([1 1 2 2], [1 2 1 2])   % [1 1; 1 1]
```

## `cvpartition`

```
CVPARTITION Découpage d'un jeu de données pour la validation croisée.
  P = CVPARTITION(N,'HoldOut',F) réserve une fraction F pour le test.
  P = CVPARTITION(N,'KFold',K) découpe en K blocs.
```

## `dendrogram`

```
DENDROGRAM Dessine l'arbre de regroupement.
  DENDROGRAM(Z) trace l'arbre que rend LINKAGE : chaque fusion est un
  U dont les deux montants partent des groupes réunis et dont la
  traverse est à la hauteur de la fusion. Les feuilles sont rangées de
  façon qu'aucun U n'en croise un autre.

  DENDROGRAM(Z,P) ne montre que P feuilles au plus : les groupes du bas
  de l'arbre sont réunis en feuilles collectives, dont l'étiquette
  porte l'effectif entre parenthèses. P = 0 montre toutes les
  observations. Le défaut est 30, comme dans MATLAB.

  H = DENDROGRAM(...) rend les poignées des traits.
  [H,T] = DENDROGRAM(...) rend aussi, pour chaque observation, le
  numéro de la feuille où elle a été rangée.
  [H,T,OUTPERM] = DENDROGRAM(...) rend l'ordre des feuilles, de gauche
  à droite.

  DENDROGRAM(...,'Orientation',O) tourne l'arbre : 'top' (défaut),
  'bottom', 'left' ou 'right'.
  DENDROGRAM(...,'ColorThreshold',C) colorie en couleurs distinctes les
  sous-arbres qui se referment sous la hauteur C.
  DENDROGRAM(...,'Labels',L) remplace les numéros des feuilles par les
  noms du tableau de cellules L.

  Exemples :
     X = [1 1; 1.2 1; 5 5; 5.1 5.2; 5 5.3];
     Z = linkage(X, 'average');
     dendrogram(Z);
     dendrogram(Z, 'ColorThreshold', 1);   % les deux grappes colorees

  Voir aussi LINKAGE, CLUSTER, CLUSTERDATA, COPHENET, PDIST.
```

## `ecdf`

```
ECDF Fonction de répartition empirique.
  [F,X] = ECDF(Y) rend la répartition empirique de l'échantillon Y :
  F(k) est la proportion d'observations inférieures ou égales à X(k).
  C'est l'escalier qui monte de 0 à 1, d'une marche de 1/N à chaque
  observation distincte.

  Le premier point est toujours (X(1), 0) avec X(1) la plus petite
  observation : l'escalier part de zéro, comme le veut MATLAB, de sorte
  que STAIRS(X,F) trace la marche complète.

  [F,X,LO,UP] = ECDF(Y) rend en outre les bornes d'un intervalle de
  confiance à 95 pour cent, calculé point par point par la formule de
  Greenwood ramenée au cas sans censure.

  ECDF(...,'alpha',A) change le niveau : A = 0.01 pour 99 pour cent.

  ECDF(Y) sans sortie demandée trace directement l'escalier.

  Exemples :
     [f, x] = ecdf([3 1 4 1 5]);
     [x, f]                  % l'escalier, points et hauteurs
     ecdf(randn(200, 1));    % la courbe en S de la loi normale

  Voir aussi CDF, NORMCDF, HISTCOUNTS, KSDENSITY, STAIRS, KSTEST.
```

## `evcdf`

```
EVCDF Répartition de la loi des valeurs extrêmes.
  Exemple :  evcdf(0, 0, 1)   % 1 - exp(-1) = 0.6321
```

## `evinv`

```
EVINV Quantile de la loi des valeurs extrêmes.
```

## `evpdf`

```
EVPDF Densité de la loi des valeurs extrêmes.
  C'est la loi de Gumbel des minima, celle que MATLAB nomme « extreme
  value » : y = exp(z)*exp(-exp(z))/sigma avec z = (x-mu)/sigma.

  Exemple :  evpdf(0, 0, 1)   % exp(-1) = 0.3679
```

## `evrnd`

```
EVRND Tirages d'une loi des valeurs extrêmes.
```

## `evstat`

```
EVSTAT Moyenne et variance de la loi des valeurs extrêmes.
  La moyenne vaut mu - sigma*gamma d'Euler, la variance sigma^2*pi^2/6.

  Exemple :  [m,v] = evstat(0, 1)   % -0.5772 et 1.6449
```

## `expfit`

```
EXPFIT Estimation du paramètre d'une loi exponentielle.
  MU = EXPFIT(X) estime la moyenne de la loi exponentielle dont X
  paraît tiré. Le maximum de vraisemblance est simplement la moyenne
  empirique : c'est l'une des rares lois où l'estimation ne demande
  aucune recherche numérique.

  [MU,MUCI] = EXPFIT(X) rend aussi l'intervalle de confiance à 95 pour
  cent. Il est exact, non approché : 2*N*MU/mu suit une loi du khi-deux
  à 2N degrés de liberté, ce qui donne les bornes directement.

  [...] = EXPFIT(X,ALPHA) donne un intervalle à 100*(1-ALPHA) pour cent.

  Pour une matrice, chaque colonne est ajustée séparément.

  Exemples :
     x = exprnd(4, 500, 1);
     [mu, ci] = expfit(x)              % mu proche de 4
     expfit(x, 0.01)

  Voir aussi EXPPDF, EXPCDF, EXPINV, EXPSTAT, MLE, FITDIST.
```

## `expinv`

```
EXPINV Quantile de la loi exponentielle de moyenne MU.
  Exemple :  expinv(0.5, 1)   % log(2) = 0.6931
```

## `exprnd`

```
EXPRND Tirages d'une loi exponentielle de moyenne MU.
  EXPRND(MU), EXPRND(MU,M), EXPRND(MU,M,N), EXPRND(MU,[M N]).
```

## `expstat`

```
EXPSTAT Moyenne et variance de la loi exponentielle.
```

## `fcdf`

```
FCDF Répartition de la loi de Fisher.
  F(x) = I_{d1 x / (d1 x + d2)}(d1/2, d2/2).
```

## `finv`

```
FINV Quantile de la loi de Fisher, par dichotomie.
```

## `fitcknn`

```
FITCKNN Classifieur par k plus proches voisins.
  M = FITCKNN(X,Y) mémorise les données ; utiliser PREDICTKNN pour
  classer de nouvelles observations.
```

## `fitctree`

```
FITCTREE Arbre de décision binaire (CART, critère de Gini).
  T = FITCTREE(X,Y) construit un arbre ; PREDICTTREE l'utilise.
  Option 'MinLeafSize' (1 par défaut) et 'MaxDepth' (8 par défaut).
```

## `fitdist`

```
FITDIST Ajuste une loi de probabilité à des données.
  PD = FITDIST(X,NOM) ajuste à X la loi nommée et rend un objet qui la
  décrit. NOM est l'un de 'Normal', 'Exponential', 'Poisson', 'Gamma',
  'Weibull', 'Lognormal', 'Rayleigh', 'Uniform', 'Beta', 'Binomial',
  'Kernel', 'Extreme Value'.

  L'objet rendu porte les champs :
     DistributionName  le nom de la loi ;
     ParameterNames    le nom de chaque paramètre ;
     ParameterValues   leurs valeurs estimées ;
     NumParameters     leur nombre ;
     InputData         les données ajustées.

  et, pour les lois qui en ont, un champ par paramètre : mu, sigma, a,
  b, lambda, selon la loi.

  Les fonctions PDF, CDF, ICDF et RANDOM acceptent cet objet en
  premier argument :

     pd = fitdist(x, 'Normal');
     pdf(pd, 0)                % la densite en zero
     icdf(pd, 0.95)            % le quantile a 95 %
     random(pd, 100, 1)        % cent tirages

  PD = FITDIST(X,NOM,'By',GROUPE) ajuste une loi par groupe et rend un
  tableau de cellules d'objets.

  Exemples :
     pd = fitdist(normrnd(5, 2, 500, 1), 'Normal');
     [pd.mu, pd.sigma]                    % proche de [5 2]
     pdf(pd, 5)

     pd = fitdist(exprnd(3, 500, 1), 'Exponential');
     pd.mu

  Voir aussi MLE, NORMFIT, PDF, CDF, ICDF, RANDOM, HISTFIT, PROBPLOT.
```

## `fitlm`

```
FITLM Modèle linéaire avec ordonnée à l'origine.
  M = FITLM(X,Y) ajuste Y = b0 + X*b et rend une structure décrivant le
  modèle : coefficients, R2, résidus, écarts types.
```

## `fpdf`

```
FPDF Densité de la loi de Fisher.
```

## `friedman`

```
FRIEDMAN Analyse de variance sur les rangs, par blocs.
  P = FRIEDMAN(Y,REPS) teste l'hypothèse « les colonnes de Y ont le
  même effet », en classant les observations à l'intérieur de chaque
  bloc — chaque ligne, ou chaque groupe de REPS lignes. C'est le
  pendant non paramétrique d'ANOVA2 sans interaction : le classement
  par bloc élimine l'effet des lignes sans avoir à le modéliser.

  REPS vaut 1 par défaut : une observation par case.

  La statistique vaut

     Q = 12/(b*k*(k+1)) * somme(R_j^2) - 3*b*(k+1)

  où b est le nombre de blocs, k celui des colonnes, R_j la somme des
  rangs de la colonne j ; elle suit une loi du khi-deux à k-1 degrés de
  liberté.

  [P,TABLEAU] = FRIEDMAN(...) rend le détail du calcul.
  [P,TABLEAU,STATS] = FRIEDMAN(...) rend de quoi appeler MULTCOMPARE.

  Exemples :
     % Quatre juges (lignes), trois vins (colonnes)
     y = [3 5 8; 2 6 9; 4 5 7; 3 6 8];
     friedman(y)                  % petit : les vins different

  Voir aussi ANOVA2, KRUSKALWALLIS, SIGNRANK, MULTCOMPARE.
```

## `frnd`

```
FRND Tirages d'une loi de Fisher-Snedecor.
  Le rapport de deux khi-deux réduits suit la loi F.
```

## `fstat`

```
FSTAT Moyenne et variance de la loi de Fisher-Snedecor.
  La moyenne n'existe que pour V2 > 2, la variance que pour V2 > 4 ;
  ailleurs MATLAB rend NaN.

  Exemple :  [m,v] = fstat(4, 10)   % 1.25 et 1.354166...
```

## `gamcdf`

```
GAMCDF Répartition de la loi gamma : la gamma incomplète régularisée.
```

## `gamfit`

```
GAMFIT Estimation des paramètres d'une loi gamma.
  Le maximum de vraisemblance vérifie log(a) - psi(a) = log(moyenne) -
  moyenne des logarithmes ; on résout par Newton, en partant de
  l'approximation de Thom, puis l'échelle suit.

  PHAT vaut [A B] : forme et échelle.
```

## `gaminv`

```
GAMINV Quantile de la loi gamma de forme A et d'échelle B.
  L'inversion se fait par dichotomie sur GAMMAINC, la gamma incomplète
  régularisée : la répartition vaut gammainc(x/b, a).

  Exemple :  gaminv(0.5, 1, 1)   % log(2) = 0.6931
```

## `gampdf`

```
GAMPDF Densité de la loi gamma, de forme A et d'échelle B.
  Exemple :  gampdf(1, 1, 1)   % exp(-1), la loi exponentielle
```

## `gamrnd`

```
GAMRND Tirages d'une loi gamma de forme A et d'échelle B.
  GAMRND(A,B), GAMRND(A,B,M), GAMRND(A,B,M,N), GAMRND(A,B,[M N]).

  Méthode de Marsaglia et Tsang (2000) : pour une forme au moins égale
  à 1 on pose d = a - 1/3, c = 1/sqrt(9d), et on accepte d*(1+c*z)^3
  avec z normal selon un test en une ligne ; le taux d'acceptation
  dépasse 95 %. Une forme inférieure à 1 se ramène à la précédente en
  multipliant par u^(1/a). Tous les tirages sont menés de front, seuls
  les refusés sont retirés au tour suivant.
```

## `gamstat`

```
GAMSTAT Moyenne et variance de la loi gamma.
  Exemple :  [m,v] = gamstat(2, 3)   % 6 et 18
```

## `geocdf`

```
GEOCDF Répartition de la loi géométrique.
  Exemple :  geocdf(2, 0.5)   % 0.875
```

## `geoinv`

```
GEOINV Quantile de la loi géométrique.
```

## `geomean`

```
GEOMEAN Moyenne géométrique.
  M = GEOMEAN(X) rend la racine N-ième du produit des N éléments de X.
  Pour une matrice, une ligne de moyennes, une par colonne. C'est la
  moyenne qui convient aux taux de croissance et aux rapports : la
  moyenne géométrique de 1.10 et 0.90 vaut 0.9950, non 1.

  M = GEOMEAN(X,DIM) travaille le long de la dimension DIM.

  Le calcul passe par les logarithmes, de sorte qu'un produit de mille
  facteurs ne déborde pas. Les valeurs doivent être positives ou
  nulles ; un zéro rend la moyenne nulle.

  Exemples :
     geomean([1 4 16])                 % 4
     geomean([1.10 0.90])              % 0.99499
     geomean([1 2; 3 4])               % [1.7321 2.8284]

  Voir aussi MEAN, HARMMEAN, TRIMMEAN, MEDIAN.
```

## `geopdf`

```
GEOPDF Probabilité de la loi géométrique.
  Comme dans MATLAB, X compte les échecs avant le premier succès : le
  support est 0, 1, 2, ...

  Exemple :  geopdf(2, 0.5)   % 0.125
```

## `geornd`

```
GEORND Tirages d'une loi géométrique.
```

## `geostat`

```
GEOSTAT Moyenne et variance de la loi géométrique.
  Exemple :  [m,v] = geostat(0.25)   % 3 et 12
```

## `gevcdf`

```
GEVCDF Répartition de la loi généralisée des valeurs extrêmes.
  P = GEVCDF(X,K,SIGMA,MU) rend la répartition de la loi GEV de
  paramètre de forme K, d'échelle SIGMA et de position MU :

     F(x) = exp( -(1 + k*(x-mu)/sigma)^(-1/k) )       si k ~= 0
     F(x) = exp( -exp(-(x-mu)/sigma) )                si k = 0

  Le signe de K décide de la famille : K > 0 donne la loi de Fréchet,
  à queue lourde ; K < 0 la loi de Weibull renversée, bornée à droite ;
  K = 0 la loi de Gumbel, celle des valeurs extrêmes ordinaire.

  Le support est borné d'un côté dès que K n'est pas nul : la
  répartition vaut 0 ou 1 au-delà.

  Les arguments par défaut sont K = 0, SIGMA = 1, MU = 0.

  C'est la loi limite du maximum d'un grand nombre d'observations,
  quelle que soit leur loi de départ — c'est le théorème de
  Fisher-Tippett, qui fait de la GEV pour les maxima ce que la normale
  est pour les moyennes.

  Exemples :
     gevcdf(1, 0, 1, 0)            % 0.6922 : Gumbel
     gevcdf(1, 0.5, 1, 0)          % Frechet
     gevcdf(10, -0.5, 1, 0)        % 1 : la loi est bornee a 2

  Voir aussi GEVPDF, GEVINV, GEVRND, EVCDF, WBLCDF.
```

## `gevfit`

```
GEVFIT Ajuste une loi généralisée des valeurs extrêmes.
  P = GEVFIT(X) estime par maximum de vraisemblance les trois
  paramètres de la loi GEV : P(1) la forme K, P(2) l'échelle SIGMA,
  P(3) la position MU.

  Le point de départ vient des moments : on ajuste d'abord une loi de
  Gumbel — forme nulle — dont l'échelle et la position se lisent dans
  la moyenne et l'écart type, puis on laisse la forme varier.

  L'estimation par maximum de vraisemblance de la GEV n'est régulière
  que pour K supérieur à -0.5 ; en deçà, la vraisemblance n'est pas
  bornée et l'estimation peut ne pas converger. C'est une propriété de
  la loi, non un défaut du calcul.

  Exemples :
     x = gevrnd(0.2, 1.5, 3, 2000, 1);
     p = gevfit(x)                  % proche de [0.2 1.5 3]

  Voir aussi GEVCDF, GEVPDF, GEVINV, GEVRND, MLE, WBLFIT.
```

## `gevinv`

```
GEVINV Quantile de la loi généralisée des valeurs extrêmes.
  X = GEVINV(P,K,SIGMA,MU) rend le quantile d'ordre P de la loi GEV.
  La forme est close :

     x = mu + sigma * ((-log p)^(-k) - 1) / k        si k ~= 0
     x = mu - sigma * log(-log p)                    si k = 0

  Les arguments par défaut sont K = 0, SIGMA = 1, MU = 0.

  Exemples :
     gevinv(0.99, 0, 1, 0)         % le niveau de retour centennal
     gevcdf(gevinv(0.7, 0.3), 0.3) % rend 0.7

  Voir aussi GEVCDF, GEVPDF, GEVRND, EVINV, WBLINV.
```

## `gevpdf`

```
GEVPDF Densité de la loi généralisée des valeurs extrêmes.
  D = GEVPDF(X,K,SIGMA,MU) rend la densité de la loi GEV de paramètre
  de forme K, d'échelle SIGMA et de position MU. La densité est nulle
  hors du support, qui est borné d'un côté dès que K n'est pas nul.

  Les arguments par défaut sont K = 0, SIGMA = 1, MU = 0.

  Exemples :
     gevpdf(0, 0, 1, 0)            % 0.3679 : le mode de Gumbel
     x = linspace(-3, 6, 200);
     plot(x, gevpdf(x, 0), x, gevpdf(x, 0.4), x, gevpdf(x, -0.4));

  Voir aussi GEVCDF, GEVINV, GEVRND, EVPDF, WBLPDF.
```

## `gevrnd`

```
GEVRND Tirages d'une loi généralisée des valeurs extrêmes.
  R = GEVRND(K,SIGMA,MU) tire une observation de la loi GEV.
  R = GEVRND(K,SIGMA,MU,M,N) rend une matrice M x N de tirages.
  R = GEVRND(K,SIGMA,MU,[M N]) fait la même chose.

  Le tirage se fait par inversion : GEVINV appliqué à un tirage
  uniforme, ce qui est exact et n'a pas de taux de rejet.

  Exemples :
     r = gevrnd(0.2, 1, 0, 1000, 1);
     histfit(r, 30, 'kernel');
     gevrnd(0, 1, 0, 3, 3)

  Voir aussi GEVCDF, GEVPDF, GEVINV, EVRND, WBLRND.
```

## `gname`

```
GNAME Étiquette les points d'un nuage.
  GNAME(ETIQUETTES) écrit à côté de chaque point du tracé courant le
  nom correspondant du tableau de cellules ETIQUETTES.

  GNAME sans argument numérote les points de 1 à N.

  GNAME(ETIQUETTES,H) n'étiquette que les points de la courbe dont H
  est la poignée.

  H = GNAME(...) rend les poignées des textes posés.

  Dans MATLAB, GNAME attend un clic de souris et n'étiquette que le
  point désigné. MatLibre n'a pas de curseur interactif sur ses
  figures : il étiquette tous les points d'un coup, ce qui rend le même
  service quand le nuage est petit — et c'est bien pour un petit nuage
  qu'on étiquette.

  Exemples :
     x = [1 2 3 4];
     y = [2 4 3 5];
     plot(x, y, 'o');
     gname({'nord', 'sud', 'est', 'ouest'});

  Voir aussi TEXT, PLOT, BOXPLOT, GSCATTER.
```

## `grp2idx`

```
GRP2IDX Numérote les modalités d'une variable de groupe.
  [G,NOMS] = GRP2IDX(GROUPE) transforme une variable de groupe — un
  vecteur de nombres, un tableau de cellules de chaînes, une matrice de
  caractères — en indices entiers 1, 2, 3… G(i) donne le numéro du
  groupe de la i-ème observation, et NOMS{G(i)} son nom d'origine.

  L'ordre est celui du tri : pour des nombres, l'ordre croissant ; pour
  des noms, l'ordre alphabétique. Deux appels sur les mêmes données
  donnent donc toujours la même numérotation.

  C'est la brique dont se servent les fonctions qui regroupent —
  GRPSTATS, ANOVA1, BOXPLOT — pour ne pas avoir à traiter chaque forme
  de variable de groupe séparément.

  Une observation manquante — NaN, ou la chaîne vide — reçoit l'indice
  NaN et n'ouvre pas de groupe.

  Exemples :
     [g, noms] = grp2idx({'b', 'a', 'b'})
     % g = [2; 1; 2], noms = {'a'; 'b'}

     [g, noms] = grp2idx([10 20 10 30])
     % g = [1; 2; 1; 3], noms = {'10'; '20'; '30'}

  Voir aussi GRPSTATS, ANOVA1, UNIQUE, CROSSTAB, TABULATE.
```

## `grpstats`

```
GRPSTATS Statistiques par groupe.
  M = GRPSTATS(X,GROUPE) rend la moyenne de X pour chaque groupe. X est
  un vecteur colonne, ou une matrice dont chaque ligne est une
  observation ; GROUPE dit à quel groupe appartient chaque ligne, sous
  la forme qu'accepte GRP2IDX — nombres ou noms.

  Le résultat a une ligne par groupe, dans l'ordre que rend GRP2IDX.

  [M,S] = GRPSTATS(X,GROUPE) rend aussi l'écart type de chaque groupe.
  [M,S,N] = GRPSTATS(...) rend le nombre d'observations par groupe.
  [M,S,N,NOMS] = GRPSTATS(...) rend les noms des groupes.

  GRPSTATS(X,GROUPE,ALPHA) où ALPHA est un nombre entre 0 et 1 dessine
  les moyennes et leur intervalle de confiance à 100*(1-ALPHA) pour
  cent, au lieu de rendre des valeurs.

  Sans GROUPE, ou avec un GROUPE vide, tout est traité comme un seul
  groupe.

  Exemples :
     x = [1 2 3 10 11 12]';
     g = {'a','a','a','b','b','b'};
     [m, s, n] = grpstats(x, g)
     % m = [2; 11], s = [1; 1], n = [3; 3]

  Voir aussi GRP2IDX, ANOVA1, ACCUMARRAY, SPLITAPPLY, TABULATE.
```

## `harmmean`

```
HARMMEAN Moyenne harmonique.
  M = HARMMEAN(X) rend l'inverse de la moyenne des inverses : N divisé
  par la somme des 1/X. Pour une matrice, une ligne de moyennes, une
  par colonne. C'est la moyenne qui convient aux vitesses et aux débits :
  parcourir la moitié du trajet à 30 et l'autre à 60 donne une vitesse
  moyenne de 40, non de 45.

  M = HARMMEAN(X,DIM) travaille le long de la dimension DIM.

  Les valeurs doivent être strictement positives ; un zéro rend la
  moyenne nulle, une valeur négative n'a pas de sens ici.

  Exemples :
     harmmean([30 60])                 % 40
     harmmean([1 2 4])                 % 1.7143
     harmmean([1 2; 3 4])              % [1.5 2.6667]

  Voir aussi MEAN, GEOMEAN, TRIMMEAN, MEDIAN.
```

## `histfit`

```
HISTFIT Histogramme et densité ajustée.
  HISTFIT(X) trace l'histogramme de X et, par-dessus, la densité de la
  loi normale ajustée sur les mêmes données. C'est le moyen le plus
  court de juger de l'œil si une loi convient.

  HISTFIT(X,NBINS) fixe le nombre de classes. Sans lui, MatLibre en
  prend la racine carrée du nombre d'observations, comme MATLAB.

  HISTFIT(X,NBINS,LOI) ajuste une autre loi : 'normal' (défaut),
  'lognormal', 'exponential', 'weibull', 'gamma', 'rayleigh', 'kernel'
  pour une densité estimée par noyau.

  H = HISTFIT(...) rend les poignées : l'histogramme d'abord, la courbe
  ensuite.

  La densité est mise à l'échelle de l'histogramme — multipliée par le
  nombre d'observations et par la largeur des classes — de sorte que
  les deux se superposent.

  Exemples :
     histfit(randn(500, 1));
     histfit(exprnd(2, 500, 1), 20, 'exponential');
     histfit(wblrnd(1, 2, 500, 1), 20, 'weibull');
     histfit(randn(300, 1), 15, 'kernel');

  Voir aussi HISTOGRAM, NORMPLOT, PROBPLOT, KSDENSITY, NORMFIT.
```

## `hougen`

```
HOUGEN Modèle de vitesse de réaction de Hougen-Watson.
  Y = HOUGEN(BETA,X) évalue

             b1 * x2 - x3 / b5
     y = ---------------------------
         1 + b2*x1 + b3*x2 + b4*x3

  où X porte trois colonnes — les pressions partielles d'hydrogène, de
  n-pentane et d'isopentane — et BETA cinq paramètres.

  C'est le modèle de cinétique chimique dont MATLAB se sert depuis
  toujours pour illustrer l'ajustement non linéaire : il est réputé
  difficile, ses paramètres étant fortement corrélés et le point de
  départ décidant du minimum atteint.

  Exemples :
     % Les donnees de Hougen et Watson, telles que Bates et Watts
     % les publient
     x = [470 300 10; 285 80 10; 470 300 120; 470 80 120; 470 80 10;
          100 190 10; 100 80 65; 470 190 65; 100 300 54; 100 300 120;
          100 80 120; 285 300 10; 285 190 120];
     y = [8.55; 3.79; 4.82; 0.02; 2.75; 14.39; 2.54; 4.35; 13.00;
          8.50; 0.05; 11.32; 3.13];
     beta = nlinfit(x, y, @hougen, [1 0.05 0.02 0.1 2]);
     max(abs(y - hougen(beta, x)))

  Voir aussi NLINFIT, NLPARCI, LSQCURVEFIT, FITNLM.
```

## `hygecdf`

```
HYGECDF Répartition de la loi hypergéométrique.
  Le support est fini : la somme directe des probabilités est exacte.
```

## `hygeinv`

```
HYGEINV Quantile de la loi hypergéométrique.
```

## `hygepdf`

```
HYGEPDF Probabilité de la loi hypergéométrique.
  HYGEPDF(X,M,K,N) : tirage sans remise de N objets dans une population
  de M, dont K portent le caractère cherché ; X est le nombre d'objets
  marqués obtenus.

  Exemple :  hygepdf(2, 10, 4, 3)   % 0.3
```

## `hygernd`

```
HYGERND Tirages d'une loi hypergéométrique.
  Le support est fini et petit : quand les trois paramètres sont les
  mêmes partout — le cas courant — la répartition est tabulée une fois
  puis inversée d'un bloc.
```

## `hygestat`

```
HYGESTAT Moyenne et variance de la loi hypergéométrique.
  La variance porte le facteur de population finie (M-N)/(M-1).

  Exemple :  [m,v] = hygestat(10, 4, 3)   % 1.2 et 0.56
```

## `icdf`

```
ICDF Quantile d'une loi nommée.
  X = ICDF('name', P, A, B, C).

  Exemple :  icdf('Normal', 0.975, 0, 1)   % 1.9600
```

## `iqr`

```
IQR Écart interquartile.
```

## `iwishrnd`

```
IWISHRND Tirage d'une matrice de Wishart inverse.
  W = IWISHRND(SIGMA,DF) tire une matrice de la loi de Wishart inverse
  de paramètre SIGMA et de DF degrés de liberté : si X suit une
  Wishart de paramètre inv(SIGMA) et de DF degrés, alors inv(X) suit
  cette loi.

  C'est la loi a priori conjuguée de la covariance d'une normale
  multivariée : c'est à ce titre qu'on la rencontre en statistique
  bayésienne.

  W = IWISHRND(SIGMA,DF,DI) emploie le facteur de Cholesky DI de
  inv(SIGMA) déjà calculé.
  [W,DI] = IWISHRND(SIGMA,DF) le rend, pour le réemployer.

  L'espérance de W vaut SIGMA/(DF-p-1) quand DF dépasse p+1.

  Exemples :
     S = [2 1; 1 3];
     W = iwishrnd(S, 10);
     M = zeros(2); for k = 1:4000, M = M + iwishrnd(S, 10); end
     M / 4000              % proche de S/(10-2-1)

  Voir aussi WISHRND, MVNRND, CHOL, COV.
```

## `jackknife`

```
JACKKNIFE Rééchantillonnage en retirant une observation à la fois.
  VALEURS = JACKKNIFE(FONCTION,D) évalue FONCTION sur les N
  échantillons obtenus en retirant tour à tour chacune des N
  observations de D. Le résultat compte une ligne par observation
  retirée.

  VALEURS = JACKKNIFE(FONCTION,D1,D2,...) retire la même ligne de tous
  les jeux à la fois, ce qui préserve leur appariement.

  Le jackknife répond à la même question que le bootstrap — de combien
  l'estimation varierait-elle ? — mais de façon déterministe : il n'y a
  pas de tirage au sort, donc pas de germe, et deux appels donnent
  exactement la même chose. Son estimation de la variance est

     (N-1)/N * somme (valeur_i - moyenne des valeurs)^2

  Il ne convient qu'aux statistiques régulières : sur une médiane, il
  donne des résultats trompeurs, là où le bootstrap tient encore.

  Exemples :
     x = randn(50, 1);
     v = jackknife(@mean, x);
     variance = (49 / 50) * sum((v - mean(v)) .^ 2);
     [variance, var(x) / 50]        % les deux coincident

     jackknife(@(a, b) corr(a, b), randn(30,1), randn(30,1));

  Voir aussi BOOTSTRP, BOOTCI, RANDSAMPLE, VAR.
```

## `jbtest`

```
JBTEST Test de normalité de Jarque-Bera.
  H = JBTEST(X) teste l'hypothèse « X suit une loi normale, de moyenne
  et de variance quelconques ». Il ne regarde que les deux moments qui
  distinguent la normale : l'asymétrie, qui doit être nulle, et
  l'aplatissement, qui doit valoir trois. La statistique est

     JB = N/6 * (S^2 + (K-3)^2/4)

  où S est l'asymétrie et K l'aplatissement de l'échantillon.

  H vaut 1 si la normalité est rejetée au seuil ALPHA, 0.05 par défaut.

  [H,P] = JBTEST(...) rend la probabilité critique.
  [H,P,JB] = JBTEST(...) rend la statistique.
  [H,P,JB,CV] = JBTEST(...) rend la valeur critique au seuil ALPHA.

  Pour un grand échantillon, JB suit une loi du khi-deux à deux degrés
  de liberté. Pour un petit — moins de deux mille observations —, cette
  approximation est trop indulgente ; MatLibre calcule alors la
  probabilité par simulation, comme le fait MATLAB, avec un germe fixé
  pour que deux appels donnent la même réponse.

  Le test ne voit que l'asymétrie et l'aplatissement : une loi qui
  partage ces deux moments avec la normale sans lui ressembler passe
  sans encombre. LILLIETEST, qui compare les répartitions entières, est
  plus complet.

  Exemples :
     jbtest(randn(1000, 1))            % 0 : normal
     jbtest(exprnd(1, 1000, 1))        % 1 : tres dissymetrique
     [h, p, jb] = jbtest(rand(500, 1)) % la loi uniforme est plate

  Voir aussi LILLIETEST, KSTEST, SKEWNESS, KURTOSIS, CHI2GOF.
```

## `kmeans`

```
KMEANS Partition en k classes par l'algorithme de Lloyd.
  [IDX,C] = KMEANS(X,K) partitionne les lignes de X en K classes.
  Options : 'MaxIter' (100), 'Start' (matrice des centres initiaux).
```

## `knnsearch`

```
KNNSEARCH Plus proches voisins par recherche exhaustive.
  [IDX,D] = KNNSEARCH(X,Y) trouve, pour chaque ligne de Y, la ligne de X
  la plus proche. Option 'K' pour en demander plusieurs.
```

## `kruskalwallis`

```
KRUSKALWALLIS Analyse de variance sur les rangs.
  P = KRUSKALWALLIS(Y,GROUPE) teste l'hypothèse « tous les groupes
  suivent la même distribution », sur les rangs des observations plutôt
  que sur leurs valeurs. C'est la réponse non paramétrique à la même
  question qu'ANOVA1 : elle ne suppose ni normalité ni égalité des
  variances, et résiste aux valeurs aberrantes.

  P = KRUSKALWALLIS(Y) où Y est une matrice traite chaque colonne comme
  un groupe.

  La statistique du test vaut

     H = 12/(N(N+1)) * somme(n_i * (R_i - (N+1)/2)^2)

  où R_i est le rang moyen du groupe i ; elle suit approximativement
  une loi du khi-deux à K-1 degrés de liberté. Elle est corrigée des
  liens par le facteur usuel.

  [P,TABLEAU] = KRUSKALWALLIS(...) rend le détail : la statistique, les
  degrés de liberté, les sommes des carrés des rangs.
  [P,TABLEAU,STATS] = KRUSKALWALLIS(...) rend de quoi appeler
  MULTCOMPARE.

  Exemples :
     y = [1 2 3 100 101 102];
     g = [1 1 1 2 2 2];
     kruskalwallis(y, g)          % 0.0495 : le maximum possible a 3+3
     anova1(y, g)                 % beaucoup plus petit, mais suppose
                                  % la normalite

  Voir aussi ANOVA1, RANKSUM, FRIEDMAN, MULTCOMPARE, TIEDRANK.
```

## `ksdensity`

```
KSDENSITY Estimation de densité par noyau.
  [F,XI] = KSDENSITY(X) estime la densité de X sur 100 points. Le noyau
  est gaussien et la largeur de bande suit la règle de Silverman :
  1,06 * sigma * n^(-1/5).

  Exemple :
     [f, xi] = ksdensity(randn(1000, 1));
```

## `kstest`

```
KSTEST Test de Kolmogorov-Smirnov contre la loi normale centrée réduite.
  [H,P,D] = KSTEST(X) compare la répartition empirique de X à celle de
  la loi normale standard. H vaut 1 quand l'hypothèse est rejetée.

  La p-valeur vient de la série de Kolmogorov, tronquée à cent termes.
```

## `kstest2`

```
KSTEST2 Kolmogorov-Smirnov à deux échantillons.
  H = KSTEST2(X1,X2) teste l'hypothèse « X1 et X2 sont tirés de la même
  loi ». La statistique est la plus grande distance verticale entre
  leurs deux répartitions empiriques :

     D = max |F1(x) - F2(x)|

  H vaut 1 si l'hypothèse est rejetée au seuil de 5 pour cent.

  [H,P] = KSTEST2(...) rend la probabilité critique, calculée par la
  série asymptotique de Kolmogorov avec l'effectif effectif
  n1*n2/(n1+n2).
  [H,P,D] = KSTEST2(...) rend la statistique elle-même.

  KSTEST2(...,'Alpha',A) change le seuil.
  KSTEST2(...,'Tail',T) choisit le côté : 'unequal' (défaut) pour une
  différence quelconque, 'larger' pour « F1 est au-dessus de F2 »,
  'smaller' pour l'inverse.

  Le test ne suppose rien sur la forme des lois, et détecte aussi bien
  un décalage qu'un changement de dispersion ou de forme. C'est ce qui
  fait sa souplesse et sa faiblesse : il est moins puissant qu'un test
  dirigé vers un écart précis.

  Exemples :
     kstest2(randn(100,1), randn(100,1))          % 0 : meme loi
     kstest2(randn(100,1), randn(100,1) + 2)      % 1 : decalees
     kstest2(randn(100,1), randn(100,1) * 3)      % 1 : dispersions

  Voir aussi KSTEST, ECDF, RANKSUM, TTEST2, LILLIETEST.
```

## `kurtosis`

```
KURTOSIS Coefficient d'aplatissement (3 pour une loi normale).
```

## `lillietest`

```
LILLIETEST Test de normalité de Lilliefors.
  H = LILLIETEST(X) teste l'hypothèse « X suit une loi normale, de
  moyenne et de variance quelconques ». C'est le test de
  Kolmogorov-Smirnov appliqué après avoir estimé ces deux paramètres
  sur l'échantillon lui-même.

  Cette estimation change tout : la statistique est plus petite qu'elle
  ne le serait avec les vrais paramètres, puisque la normale ajustée
  colle par construction aux données. Employer la table de
  Kolmogorov-Smirnov ordinaire ferait donc conclure à la normalité
  beaucoup trop souvent. Lilliefors a établi la bonne loi ; MatLibre la
  retrouve par simulation, avec un germe fixé.

  [H,P] = LILLIETEST(...) rend la probabilité critique.
  [H,P,D] = LILLIETEST(...) rend la statistique de Kolmogorov-Smirnov.
  [H,P,D,CV] = LILLIETEST(...) rend la valeur critique.

  LILLIETEST(...,'Alpha',A) change le seuil, 0.05 par défaut.
  LILLIETEST(...,'Distr',D) change la loi testée : 'norm' (défaut),
  'exp' pour l'exponentielle, 'ev' pour la loi des valeurs extrêmes.

  Exemples :
     lillietest(randn(200, 1))         % 0 : normal
     lillietest(exprnd(1, 200, 1))     % 1 : ce n'est pas normal
     lillietest(exprnd(1, 200, 1), 'Distr', 'exp')   % 0 : c'est exponentiel

  Voir aussi KSTEST, KSTEST2, JBTEST, CHI2GOF, NORMFIT.
```

## `linkage`

```
LINKAGE Arbre de regroupement hiérarchique.
  Z = LINKAGE(Y) construit l'arbre de regroupement à partir du vecteur
  de distances Y que rend PDIST. Z compte N-1 lignes, une par fusion,
  et trois colonnes : les deux groupes réunis, puis la distance à
  laquelle ils l'ont été. Les observations d'origine portent les
  numéros 1 à N ; le groupe formé à la k-ième fusion porte le numéro
  N+k, de sorte qu'il peut être réuni à son tour.

  Z = LINKAGE(X) où X est une matrice d'observations — une par ligne —
  calcule d'abord PDIST(X), puis l'arbre.

  Z = LINKAGE(...,METHODE) choisit comment mesurer la distance entre
  deux groupes :
     'single'    la plus courte distance entre leurs membres (défaut),
                 dite du plus proche voisin ; elle suit les filaments ;
     'complete'  la plus longue, dite du diamètre ; elle fait des
                 groupes compacts ;
     'average'   la moyenne de toutes les paires (UPGMA) ;
     'weighted'  la moyenne des deux sous-groupes, à poids égal
                 (WPGMA) ;
     'centroid'  la distance entre les centres de gravité (UPGMC) ;
     'median'    la distance entre les centres, chacun placé au milieu
                 de ses deux sous-groupes (WPGMC) ;
     'ward'      l'accroissement de l'inertie intragroupe qu'entraîne
                 la fusion ; c'est la méthode qui fait les groupes les
                 plus équilibrés.

  Z = LINKAGE(X,METHODE,METRIQUE) passe METRIQUE à PDIST. Les méthodes
  'centroid', 'median' et 'ward' n'ont de sens que pour la distance
  euclidienne.

  Les distances de 'centroid' et 'median' peuvent décroître d'une
  fusion à la suivante — c'est l'inversion, propre à ces deux méthodes,
  et non une erreur de calcul.

  Exemples :
     X = [1 1; 1.2 1; 5 5; 5.1 5.2];
     Z = linkage(X)
     % deux paires serrees, puis leur reunion, loin
     T = cluster(Z, 'maxclust', 2)   % [1;1;2;2]
     dendrogram(Z);

     Z = linkage(X, 'ward');
     cophenet(Z, pdist(X))           % proche de 1 : l'arbre est fidele

  Voir aussi PDIST, CLUSTER, CLUSTERDATA, COPHENET, DENDROGRAM, KMEANS.
```

## `logncdf`

```
LOGNCDF Répartition de la loi log-normale.
```

## `lognfit`

```
LOGNFIT Estimation des paramètres d'une loi log-normale.
  On ajuste une normale sur les logarithmes.
```

## `logninv`

```
LOGNINV Quantile de la loi log-normale.
  Le logarithme d'une variable log-normale est normal : le quantile est
  l'exponentielle de celui de la normale.

  Exemple :  logninv(0.5, 0, 1)   % 1
```

## `lognpdf`

```
LOGNPDF Densité de la loi log-normale.
  MU et SIGMA sont la moyenne et l'écart-type du logarithme.
```

## `lognrnd`

```
LOGNRND Tirages d'une loi log-normale.
```

## `lognstat`

```
LOGNSTAT Moyenne et variance de la loi log-normale.
  MU et SIGMA sont ceux du logarithme, pas ceux de la variable.

  Exemple :  [m,v] = lognstat(0, 1)   % exp(0.5) et e(e-1)
```

## `lsline`

```
LSLINE Ajoute la droite des moindres carrés à un nuage de points.
  LSLINE ajuste une droite par moindres carrés sur les points déjà
  tracés dans l'axe courant, et l'ajoute au dessin. C'est REFLINE sans
  argument, sous le nom que MATLAB lui donne aussi.

  H = LSLINE rend la poignée de la droite.

  Exemples :
     x = 1:20;
     plot(x, 2 * x + randn(1, 20) * 2, 'o');
     lsline;

  Voir aussi REFLINE, REFCURVE, POLYFIT, REGRESS.
```

## `mad`

```
MAD Écart absolu moyen, ou médian si le second argument vaut 1.
```

## `mahal`

```
MAHAL Distance de Mahalanobis au nuage de référence.
  D = MAHAL(Y,X) rend, pour chaque ligne de Y, le carré de sa distance
  de Mahalanobis au nuage X :

     d = (y - m) * inv(C) * (y - m)'

  où m est la moyenne des lignes de X et C leur covariance. C'est la
  distance euclidienne mesurée après avoir blanchi les données : elle
  tient compte de ce que les variables n'ont ni la même dispersion ni
  la même corrélation. Un point à deux écarts types dans la direction
  où le nuage est étroit est plus loin qu'un point à deux écarts types
  là où il est large.

  Y et X doivent avoir le même nombre de colonnes, et X doit compter
  plus de lignes que de colonnes pour que la covariance soit
  inversible.

  Le calcul passe par la factorisation de Cholesky de C et une
  résolution triangulaire : on n'inverse pas la matrice.

  Exemples :
     X = randn(100, 2);
     mahal([0 0], X)              % proche de 0 : au centre du nuage
     mahal([5 5], X)              % grand : loin de tout

     % Une ellipse, non un cercle : le nuage est corrélé.
     X = randn(500, 2) * [1 0; 0.9 0.4];
     [mahal([1 1], X), mahal([1 -1], X)]

  Voir aussi PDIST, PDIST2, COV, CHOL, KNNSEARCH.
```

## `matlibre_arbre_reduit`

```
MATLIBRE_ARBRE_REDUIT L'arbre des GARDE derniers groupes seulement.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  DENDROGRAM s'en sert pour ne dessiner que le haut de l'arbre quand
  les observations sont trop nombreuses pour tenir sur un axe.
```

## `matlibre_distance`

```
MATLIBRE_DISTANCE Distance entre deux observations, selon la métrique nommée.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  PDIST et PDIST2 s'en servent pour n'écrire qu'une fois chacune des
  distances qu'ils proposent.
```

## `matlibre_gauss_legendre`

```
MATLIBRE_GAUSS_LEGENDRE Nœuds et poids de la quadrature de Gauss-Legendre.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  [X,W] = MATLIBRE_GAUSS_LEGENDRE(N) rend les N nœuds sur [-1,1] et
  leurs poids, tels que SUM(W .* F(X)) approche l'intégrale de F sur
  cet intervalle, exactement pour tout polynôme de degré inférieur à
  2N.

  Les nœuds sont les racines du polynôme de Legendre P_N, cherchées par
  la méthode de Newton depuis l'approximation de Tricomi ; le poids
  vaut 2 / ((1-x^2) P'_N(x)^2).

  Les tables déjà calculées sont gardées d'un appel à l'autre : la
  plage studentisée demande la même quadrature des milliers de fois,
  et la recalculer chaque fois coûtait plus que l'intégrale elle-même.
```

## `matlibre_kolmogorov_queue`

```
MATLIBRE_KOLMOGOROV_QUEUE Queue de la loi de Kolmogorov.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  P = MATLIBRE_KOLMOGOROV_QUEUE(L) rend

     Q(L) = 2 * somme_{k>=1} (-1)^(k-1) exp(-2 k^2 L^2)

  la probabilité que la statistique de Kolmogorov-Smirnov normalisée
  dépasse L. C'est la limite quand l'effectif grandit ; elle est déjà
  bonne à quelques dizaines d'observations.
```

## `matlibre_marge_comparaison`

_Pas de bloc d'aide._

## `matlibre_nelder_mead`

```
MATLIBRE_NELDER_MEAD Minimisation par simplexe, sans dérivée.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
  qui emploie FMINSEARCH. MLE s'en sert pour ne pas dépendre de la
  boîte à outils d'optimisation.

  MEILLEUR = MATLIBRE_NELDER_MEAD(F,P0,MAXITER,TOL) minimise F à partir
  de P0. La méthode déforme un simplexe de N+1 points : elle réfléchit
  le plus mauvais sommet à travers le centre des autres, l'étend si
  cela va mieux encore, le contracte sinon, et rétrécit tout le
  simplexe quand rien ne marche.
```

## `matlibre_normale_bivariee`

```
MATLIBRE_NORMALE_BIVARIEE Répartition normale à deux dimensions.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  MVNCDF s'en sert pour le cas de dimension deux, où la probabilité
  s'écrit

     P(h,k) = Phi(h)*Phi(k) + (1/2pi) * integrale de 0 a asin(rho)
              de exp(-(h^2 - 2*h*k*sin t + k^2) / (2 cos^2 t)) dt

  C'est la formule de Drezner et Wesolowsky. L'intégrale est évaluée
  par une quadrature de Gauss-Legendre à vingt points, ce qui donne
  une dizaine de chiffres exacts.
```

## `matlibre_ordre_feuilles`

```
MATLIBRE_ORDRE_FEUILLES Range les feuilles pour qu'aucun lien n'en croise un autre.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  C'est un parcours en profondeur depuis la racine : les feuilles
  sortent dans l'ordre où on les rencontre, et deux feuilles réunies
  tôt restent voisines.
```

## `matlibre_plage_studentisee`

```
MATLIBRE_PLAGE_STUDENTISEE Quantile de la plage studentisée.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  Q = MATLIBRE_PLAGE_STUDENTISEE(P,K,DDL) rend le quantile d'ordre P de
  l'étendue de K variables normales, divisée par un écart type estimé à
  DDL degrés de liberté. C'est la loi dont dépend le test de Tukey.

  Le quantile est trouvé par dichotomie sur la répartition, elle-même
  calculée par quadrature. Quarante bissections suffisent : elles
  ramènent l'intervalle de départ, large de vingt, sous le
  dix-milliardième.
```

## `matlibre_plage_studentisee_cdf`

```
MATLIBRE_PLAGE_STUDENTISEE_CDF Répartition de la plage studentisée.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Pour un écart type connu — DDL infini — la probabilité que l'étendue
  de K normales centrées réduites reste sous Q vaut

     K * integrale de phi(z) * [Phi(z) - Phi(z-q)]^(K-1) dz

  Pour un DDL fini, on intègre en outre sur la loi de l'estimateur de
  l'écart type, dont le carré suit un khi-deux réduit.

  Les deux intégrales sont évaluées par quadrature de Gauss-Legendre,
  sur un intervalle assez large pour que la queue négligée reste sous
  le millionième.
```

## `matlibre_poids_robuste`

```
MATLIBRE_POIDS_ROBUSTE Fonction de poids d'une régression robuste.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  [W,C] = MATLIBRE_POIDS_ROBUSTE(NOM) rend la fonction de poids nommée
  et sa constante de réglage par défaut. L'argument de W est le résidu
  déjà divisé par l'écart type robuste et par la constante.

  Les constantes sont celles de MATLAB : elles sont choisies pour que
  l'estimateur garde 95 pour cent de l'efficacité des moindres carrés
  quand les données sont bel et bien normales.
```

## `matlibre_points_traces`

```
MATLIBRE_POINTS_TRACES Tous les points de l'axe courant, en vrac.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  REFLINE, REFCURVE et LSLINE s'en servent pour ajuster une courbe sur
  ce qui est déjà dessiné, sans qu'on ait à leur repasser les données.
```

## `matlibre_probabilite_suites`

```
MATLIBRE_PROBABILITE_SUITES Probabilité exacte du test des suites.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  Le nombre de suites d'une permutation au hasard de N1 signes plus et
  N0 signes moins a une loi connue :

     P(R = 2k)   = 2 C(n1-1,k-1) C(n0-1,k-1) / C(n1+n0, n1)
     P(R = 2k+1) = [C(n1-1,k) C(n0-1,k-1) + C(n1-1,k-1) C(n0-1,k)]
                   / C(n1+n0, n1)

  La fonction rend la probabilité bilatérale : deux fois la queue la
  plus petite, plafonnée à un.
```

## `matlibre_quantile_par_dichotomie`

```
MATLIBRE_QUANTILE_PAR_DICHOTOMIE Inverse une répartition croissante.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  Les lois décentrées n'ont pas de quantile en forme close ; on inverse
  donc leur répartition. La bissection y suffit et ne peut pas
  diverger, la répartition étant croissante.

  MINIMUM est la borne inférieure du support — 0 pour un khi-deux,
  -Inf pour un Student décentré. ECHELLE donne l'ordre de grandeur par
  lequel commencer à chercher la borne supérieure.
```

## `matlibre_regression_isotone`

```
MATLIBRE_REGRESSION_ISOTONE La suite croissante la plus proche.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  Y = MATLIBRE_REGRESSION_ISOTONE(X) rend la suite croissante qui
  minimise la somme des carrés des écarts à X. C'est l'algorithme dit
  « pool adjacent violators » : tant qu'un terme est plus petit que
  son prédécesseur, on fond les deux blocs en un seul, dont la valeur
  est leur moyenne pondérée.

  Le positionnement multidimensionnel non métrique s'en sert : il ne
  demande aux distances que de respecter l'ordre des dissemblances, et
  cette régression donne la suite croissante que les distances doivent
  approcher.
```

## `mdscale`

```
MDSCALE Positionnement multidimensionnel non métrique.
  Y = MDSCALE(D,P) cherche P coordonnées par objet telles que les
  distances entre les points de Y reproduisent au mieux les
  dissemblances D. D est le vecteur que rend PDIST, ou la matrice
  carrée correspondante.

  Le positionnement métrique — CMDSCALE — cherche à reproduire les
  distances elles-mêmes. Le positionnement non métrique, lui, ne
  demande que de respecter leur ordre : deux objets plus dissemblables
  que deux autres doivent être plus éloignés, sans que le rapport des
  distances importe. C'est ce qui le rend applicable à des jugements
  de similarité, où seul le classement a un sens.

  [Y,STRESS] = MDSCALE(D,P) rend la contrainte finale, entre 0 et 1 :
  c'est l'écart résiduel entre les distances obtenues et les
  dissemblances ajustées, rapporté à leur taille. Sous 0.05 la
  représentation est excellente, au-delà de 0.20 elle est douteuse.

  MDSCALE(...,'criterion',C) choisit la contrainte à minimiser :
  'stress' (défaut), la forme de Kruskal ; 'sstress', qui porte sur les
  carrés des distances et pèse donc davantage les grandes ; 'metricstress'
  et 'metricsstress', qui ajustent les distances sans passer par les
  rangs.
  MDSCALE(...,'start',Y0) part d'une configuration donnée ; 'random'
  part d'un tirage. Sans elle, on part du positionnement métrique, qui
  est un bon point de départ et rend le résultat reproductible.
  MDSCALE(...,'replicates',R) recommence R fois depuis des départs au
  hasard et garde la meilleure : le critère a des minima locaux.

  Exemples :
     % Quatre villes, leurs distances : on retrouve le plan
     X = [0 0; 3 0; 0 4; 3 4];
     Y = mdscale(pdist(X), 2);
     max(abs(pdist(Y) - pdist(X)))     % petit : la carte est bonne

     [Y, contrainte] = mdscale(pdist(randn(20, 5)), 2);
     contrainte                        % plus grande : cinq dimensions
                                       % ne tiennent pas dans deux

  Voir aussi CMDSCALE, PDIST, SQUAREFORM, PCA, PROCRUSTES.
```

## `mle`

```
MLE Estimation par maximum de vraisemblance.
  P = MLE(X) ajuste une loi normale à X par maximum de vraisemblance et
  rend [moyenne, écart type].

  P = MLE(X,'distribution',NOM) ajuste une autre loi. Les noms
  reconnus : 'normal', 'exponential', 'poisson', 'gamma', 'weibull',
  'lognormal', 'rayleigh', 'uniform', 'beta', 'geometric',
  'binomial' — pour cette dernière, il faut donner 'ntrials'.

  P = MLE(X,'pdf',F,'start',P0) ajuste une loi quelconque : F est une
  poignée dont le premier argument est le vecteur des données et les
  suivants les paramètres, et P0 le point de départ de la recherche.
  'cdf' peut remplacer 'pdf' pour des données censurées ; MatLibre
  n'emploie alors la répartition que pour les points censurés.

  P = MLE(X,'logpdf',F,'start',P0) accepte directement le logarithme de
  la densité, ce qui évite les débordements sur de grands échantillons.

  [P,CI] = MLE(...) rend en outre les intervalles de confiance à 95
  pour cent, tirés de la matrice d'information observée — l'opposé de
  la hessienne de la log-vraisemblance, calculée par différences
  finies.

  MLE(...,'alpha',A) change le niveau de confiance.
  MLE(...,'options',O) passe une structure STATSET pour régler la
  recherche.

  Exemples :
     mle(randn(500, 1) * 2 + 3)                 % proche de [3 2]
     mle(exprnd(4, 500, 1), 'distribution', 'exponential')
     mle(poissrnd(3, 500, 1), 'distribution', 'poisson')

     % Une loi ecrite a la main : melange de deux normales centrees
     f = @(x, s1, s2) 0.5 * normpdf(x, 0, s1) + 0.5 * normpdf(x, 0, s2);
     mle([randn(300,1); randn(300,1)*4], 'pdf', f, 'start', [1 3])

  Voir aussi FITDIST, NORMFIT, EXPFIT, GAMFIT, WBLFIT, NLINFIT, STATSET.
```

## `multcompare`

```
MULTCOMPARE Comparaisons multiples après une analyse de variance.
  C = MULTCOMPARE(STATS) compare les groupes deux à deux, à partir de
  la structure STATS que rend ANOVA1, KRUSKALWALLIS ou FRIEDMAN. Une
  analyse de variance dit que les groupes ne sont pas tous égaux ;
  MULTCOMPARE dit lesquels diffèrent.

  C compte une ligne par paire et six colonnes :
     1, 2   les deux groupes comparés ;
     3      la borne basse de l'intervalle de confiance de leur écart ;
     4      l'écart estimé lui-même ;
     5      la borne haute ;
     6      la probabilité critique de la comparaison.

  Une paire dont l'intervalle ne contient pas zéro diffère au seuil
  retenu.

  [C,M] = MULTCOMPARE(STATS) rend en outre, pour chaque groupe, son
  estimation et son erreur type.
  [C,M,H] = MULTCOMPARE(STATS) trace les intervalles.
  [C,M,H,NOMS] = MULTCOMPARE(STATS) rend les noms des groupes.

  MULTCOMPARE(...,'alpha',A) change le seuil, 0.05 par défaut.

  MULTCOMPARE(...,'ctype',T) choisit la correction de la multiplicité :
     'tukey-kramer'  la plage studentisée, exacte pour des groupes de
                     même effectif et légèrement conservatrice sinon
                     (défaut) ;
     'bonferroni'    le seuil divisé par le nombre de paires : simple
                     et toujours valable, mais prudent ;
     'lsd'           aucune correction ; à ne prendre que si l'analyse
                     de variance a déjà conclu.

  Comparer K groupes deux à deux fait K(K-1)/2 tests : sans correction,
  la chance de conclure à tort au moins une fois grandit vite avec K.
  C'est tout l'objet de cette fonction.

  Exemples :
     y = [5 6 7 10 11 12 5.5 6.5 7.5];
     g = [1 1 1 2 2 2 3 3 3];
     [~, ~, stats] = anova1(y, g);
     c = multcompare(stats)
     % les paires 1-2 et 2-3 different, la paire 1-3 non

  Voir aussi ANOVA1, ANOVA2, KRUSKALWALLIS, FRIEDMAN, TTEST2.
```

## `mvncdf`

```
MVNCDF Répartition de la loi normale multivariée.
  P = MVNCDF(X) rend, pour chaque ligne de X, la probabilité qu'un
  tirage de la loi normale centrée réduite soit inférieur à X dans
  toutes ses coordonnées à la fois.

  P = MVNCDF(X,MU,SIGMA) prend MU pour moyenne et SIGMA pour
  covariance.

  P = MVNCDF(A,B,MU,SIGMA) rend la probabilité du pavé A < x < B.

  En dimension un, le calcul est exact — c'est NORMCDF. En dimension
  deux, il l'est aussi : la formule de Drezner-Wesolowsky donne la
  probabilité par une seule intégrale sur l'angle, évaluée par
  quadrature de Gauss. Au-delà, MatLibre intègre par tirages
  quasi-aléatoires, et la valeur rendue porte une erreur de l'ordre du
  millième.

  Exemples :
     mvncdf([0 0])                            % 0.25, par symetrie
     mvncdf([0 0], [0 0], [1 0.5; 0.5 1])     % 0.3333
     mvncdf([-1 -1], [1 1], [0 0], eye(2))    % le pave central
     mvncdf(0)                                % 0.5, comme normcdf

  Voir aussi MVNPDF, MVNRND, NORMCDF, MAHAL.
```

## `mvnpdf`

```
MVNPDF Densité de la loi normale multivariée.
  Y = MVNPDF(X) évalue en chaque ligne de X la densité de la loi
  normale centrée réduite de dimension P, où P est le nombre de
  colonnes de X. Y a autant de lignes que X.

  Y = MVNPDF(X,MU) prend MU pour moyenne, avec la covariance identité.
  MU est un vecteur ligne de longueur P, ou une matrice de la taille de
  X pour donner à chaque observation sa propre moyenne.

  Y = MVNPDF(X,MU,SIGMA) prend SIGMA pour covariance. SIGMA est une
  matrice P x P symétrique définie positive, ou un vecteur ligne de
  longueur P si la covariance est diagonale.

  La densité vaut

     (2*pi)^(-P/2) * det(SIGMA)^(-1/2) * exp(-d/2)

  où d est le carré de la distance de Mahalanobis de X à MU. Le calcul
  passe par la factorisation de Cholesky : ni déterminant ni inverse
  ne sont formés, ce qui reste exact pour un P élevé.

  Exemples :
     mvnpdf([0 0])                        % 0.15915 = 1/(2*pi)
     mvnpdf([0 0], [0 0], [1 0; 0 1])     % la meme chose
     mvnpdf([1 1; 0 0], [0 0], [2 1; 1 2])

     % La densite le long d'une ligne, pour une loi correlee :
     x = linspace(-3, 3, 7)';
     mvnpdf([x, x], [0 0], [1 0.8; 0.8 1])

  Voir aussi NORMPDF, MVNRND, MVNCDF, MAHAL, CHOL.
```

## `mvnrnd`

```
MVNRND Tirages d'une loi normale multivariée.
  X = MVNRND(MU,SIGMA) tire une observation de la loi normale de
  moyenne MU et de covariance SIGMA, rendue en ligne. MU est un vecteur
  de longueur P, SIGMA une matrice P x P symétrique définie positive.

  X = MVNRND(MU,SIGMA,N) tire N observations, une par ligne.

  Si MU est une matrice de N lignes, chaque ligne donne la moyenne de
  l'observation correspondante, et N n'est pas nécessaire.

  Le tirage passe par la factorisation de Cholesky : X = MU + Z*R où Z
  est normal centré réduit et R le facteur triangulaire supérieur de
  SIGMA. La covariance empirique de X tend donc bien vers SIGMA.

  Exemples :
     X = mvnrnd([0 0], [1 0.8; 0.8 1], 1000);
     cov(X)                      % proche de [1 0.8; 0.8 1]
     mean(X)                     % proche de [0 0]

     % Un nuage etire dans une direction :
     X = mvnrnd([5 5], [4 0; 0 0.25], 200);
     plot(X(:,1), X(:,2), '.'); axis('equal');

  Voir aussi MVNPDF, MVNCDF, RANDN, NORMRND, CHOL, COV.
```

## `nancov`

```
NANCOV Covariance en écartant les valeurs manquantes.
  C = NANCOV(X) rend la matrice de covariance des colonnes de X après
  avoir supprimé toute ligne portant au moins un NaN. C'est la
  suppression « par liste » : elle garde une matrice cohérente, au prix
  des lignes incomplètes.

  C = NANCOV(X,Y) traite X et Y comme deux variables et rend la
  matrice 2 x 2 de leurs covariances.

  C = NANCOV(...,'pairwise') calcule chaque terme sur les lignes où les
  deux variables concernées sont présentes. On garde ainsi plus de
  données, mais la matrice obtenue n'est pas nécessairement définie
  positive : chaque terme repose sur un sous-ensemble différent.

  Exemples :
     X = [1 2; 3 5; NaN 9; 4 8];
     nancov(X)                       % les lignes 1, 2 et 4
     nancov(X, 'pairwise')           % la variance de la 2e colonne
                                     % emploie ses quatre valeurs

  Voir aussi COV, NANVAR, NANMEAN, CORRCOEF, RMMISSING.
```

## `nanmax`

```
NANMAX Maximum en écartant les valeurs manquantes.
  M = NANMAX(X) rend le plus grand élément de X sans tenir compte des
  NaN. C'est déjà ce que fait MAX : NANMAX existe pour la symétrie de
  la famille NAN..., et pour les programmes écrits avant que MAX ne
  l'ait adopté.

  [M,I] = NANMAX(X) rend aussi l'indice où le maximum a été trouvé.

  M = NANMAX(X,Y) compare X et Y élément par élément ; là où l'un des
  deux est NaN, c'est l'autre qui l'emporte.

  M = NANMAX(X,[],DIM) cherche le long de la dimension DIM.

  Exemples :
     nanmax([1 NaN 5 2])               % 5
     [m, i] = nanmax([1 NaN 5 2])      % m = 5, i = 3
     nanmax([1 NaN], [NaN 4])          % [1 4]

  Voir aussi MAX, NANMIN, NANMEAN, ISNAN.
```

## `nanmean`

```
NANMEAN Moyenne en écartant les valeurs manquantes.
  M = NANMEAN(X) rend la moyenne de X en ignorant les NaN. Pour un
  vecteur, c'est un scalaire ; pour une matrice, une ligne de moyennes,
  une par colonne. Une colonne entièrement NaN donne NaN, faute de
  quoi que ce soit à moyenner.

  M = NANMEAN(X,DIM) moyenne le long de la dimension DIM.

  NANMEAN(X) est un raccourci pour MEAN(X,'omitnan'), qui est la forme
  recommandée depuis R2015a ; NANMEAN reste pour les programmes qui
  l'emploient déjà.

  Exemples :
     nanmean([1 2 NaN 4])              % 2.3333
     nanmean([1 NaN; 3 4])             % [2 4]
     nanmean([1 NaN; 3 4], 2)          % [1 ; 3.5]
     nanmean([NaN NaN])                % NaN

  Voir aussi MEAN, NANMEDIAN, NANSTD, NANSUM, ISNAN, RMMISSING.
```

## `nanmedian`

```
NANMEDIAN Médiane en écartant les valeurs manquantes.
  M = NANMEDIAN(X) rend la médiane de X en ignorant les NaN : la
  médiane porte sur les seules valeurs présentes, non sur un vecteur
  qu'un NaN suffirait à rendre indéfini.

  M = NANMEDIAN(X,DIM) travaille le long de la dimension DIM.

  NANMEDIAN(X) est un raccourci pour MEDIAN(X,'omitnan').

  Exemples :
     nanmedian([1 NaN 3 100])          % 3
     nanmedian([1 NaN; 3 4])           % [2 4]
     nanmedian([NaN NaN])              % NaN

  Voir aussi MEDIAN, NANMEAN, NANSTD, PRCTILE, QUANTILE.
```

## `nanmin`

```
NANMIN Minimum en écartant les valeurs manquantes.
  M = NANMIN(X) rend le plus petit élément de X sans tenir compte des
  NaN, comme le fait déjà MIN.

  [M,I] = NANMIN(X) rend aussi l'indice où le minimum a été trouvé.

  M = NANMIN(X,Y) compare X et Y élément par élément ; là où l'un des
  deux est NaN, c'est l'autre qui l'emporte.

  M = NANMIN(X,[],DIM) cherche le long de la dimension DIM.

  Exemples :
     nanmin([3 NaN 1 2])               % 1
     [m, i] = nanmin([3 NaN 1 2])      % m = 1, i = 3
     nanmin([1 NaN], [NaN 4])          % [1 4]

  Voir aussi MIN, NANMAX, NANMEAN, ISNAN.
```

## `nanstd`

```
NANSTD Écart type en écartant les valeurs manquantes.
  S = NANSTD(X) rend l'écart type de X en ignorant les NaN, normalisé
  par N-1 où N est le nombre de valeurs présentes — non le nombre
  d'éléments.

  S = NANSTD(X,1) normalise par N. S = NANSTD(X,0) revient au défaut.

  S = NANSTD(X,NORMALISATION,DIM) travaille le long de DIM.

  NANSTD(X) est un raccourci pour STD(X,'omitnan').

  Exemples :
     nanstd([1 2 NaN 3])               % 1, comme std([1 2 3])
     nanstd([1 2 NaN 3], 1)            % 0.8165
     nanstd([1 NaN; 3 5])              % [1.4142 0]

  Voir aussi STD, NANVAR, NANMEAN, VAR.
```

## `nansum`

```
NANSUM Somme en écartant les valeurs manquantes.
  S = NANSUM(X) additionne X en traitant chaque NaN comme un zéro.
  Une colonne entièrement NaN donne donc 0 — c'est la convention de
  MATLAB, et elle diffère de NANMEAN, qui rend NaN dans ce cas.

  S = NANSUM(X,DIM) additionne le long de la dimension DIM.

  NANSUM(X) est un raccourci pour SUM(X,'omitnan').

  Exemples :
     nansum([1 2 NaN 4])               % 7
     nansum([NaN NaN])                 % 0
     nansum([1 NaN; 3 4], 2)           % [1 ; 7]

  Voir aussi SUM, NANMEAN, NANMAX, NANMIN.
```

## `nanvar`

```
NANVAR Variance en écartant les valeurs manquantes.
  V = NANVAR(X) rend la variance de X en ignorant les NaN, normalisée
  par N-1 où N compte les seules valeurs présentes.

  V = NANVAR(X,1) normalise par N ; V = NANVAR(X,0) revient au défaut.

  V = NANVAR(X,NORMALISATION,DIM) travaille le long de DIM.

  NANVAR(X) est un raccourci pour VAR(X,'omitnan').

  Exemples :
     nanvar([1 2 NaN 3])               % 1
     nanvar([1 2 NaN 3], 1)            % 0.6667

  Voir aussi VAR, NANSTD, NANMEAN, NANCOV.
```

## `nbincdf`

```
NBINCDF Répartition de la loi binomiale négative.
  P(X <= k) = I_p(r, k+1), la bêta incomplète régularisée.
```

## `nbininv`

```
NBININV Quantile de la loi binomiale négative.
```

## `nbinpdf`

```
NBINPDF Probabilité de la loi binomiale négative.
  X compte les échecs avant le R-ième succès, R pouvant être réel.

  Exemple :  nbinpdf(2, 3, 0.5)   % 0.1875
```

## `nbinrnd`

```
NBINRND Tirages d'une loi binomiale négative.
  Mélange de Poisson par une gamma : c'est la représentation usuelle,
  valable même pour un R non entier.
```

## `nbinstat`

```
NBINSTAT Moyenne et variance de la loi binomiale négative.
  Exemple :  [m,v] = nbinstat(3, 0.5)   % 3 et 6
```

## `ncfcdf`

```
NCFCDF Répartition de la loi de Fisher décentrée.
  P = NCFCDF(X,V1,V2,DELTA) rend la probabilité qu'une variable de
  Fisher décentrée, à V1 et V2 degrés de liberté et de paramètre de
  décentrage DELTA, soit inférieure à X.

  C'est la loi du rapport (W1/V1)/(W2/V2) où W1 est un khi-deux
  décentré à V1 degrés et de paramètre DELTA, W2 un khi-deux ordinaire
  à V2 degrés. C'est la loi de la statistique d'une analyse de variance
  quand les moyennes ne sont pas égales : elle donne donc la puissance
  du test et la taille d'échantillon qu'il faudrait.

  Le calcul emploie le mélange de Poisson, chaque terme se ramenant à
  une répartition de Fisher ordinaire.

  Exemples :
     ncfcdf(3, 2, 10, 0)           % egale fcdf(3, 2, 10)
     ncfcdf(3, 2, 10, 5)           % plus petit
     1 - ncfcdf(finv(0.95, 2, 27), 2, 27, 6)    % la puissance d'une
                                                % analyse de variance

  Voir aussi FCDF, NCFPDF, NCFINV, NCX2CDF, NCTCDF, ANOVA1.
```

## `ncfinv`

```
NCFINV Quantile de la loi de Fisher décentrée.
  X = NCFINV(P,V1,V2,DELTA) rend la valeur X telle que
  NCFCDF(X,V1,V2,DELTA) vaille P.

  L'inverse est cherché par dichotomie sur la répartition.

  Exemples :
     ncfinv(0.95, 3, 20, 0)        % egale finv(0.95, 3, 20)
     ncfinv(0.95, 3, 20, 5)
     ncfcdf(ncfinv(0.6, 2, 12, 3), 2, 12, 3)    % rend 0.6

  Voir aussi NCFCDF, NCFPDF, FINV, NCX2INV, NCTINV.
```

## `ncfpdf`

```
NCFPDF Densité de la loi de Fisher décentrée.
  D = NCFPDF(X,V1,V2,DELTA) rend la densité en X de la loi de Fisher
  décentrée, à V1 et V2 degrés de liberté et de paramètre de
  décentrage DELTA.

  Comme la répartition, la densité s'écrit en mélange de Poisson de
  densités de Fisher ordinaires, chacune à V1+2k degrés au numérateur
  et mise à l'échelle en conséquence.

  Exemples :
     ncfpdf(2, 3, 20, 0)           % egale fpdf(2, 3, 20)
     x = linspace(0, 8, 200);
     plot(x, ncfpdf(x, 3, 20, 0), x, ncfpdf(x, 3, 20, 5));

  Voir aussi NCFCDF, NCFINV, FPDF, NCX2PDF, NCTPDF.
```

## `nctcdf`

```
NCTCDF Répartition du Student décentré.
  P = NCTCDF(X,V,DELTA) rend la probabilité qu'une variable de Student
  décentrée à V degrés de liberté et de paramètre DELTA soit inférieure
  à X.

  Le Student décentré est la loi de (Z + DELTA) / racine(W/V), où Z est
  normale centrée réduite et W un khi-deux à V degrés, indépendants.
  C'est la loi de la statistique d'un test de Student quand l'hypothèse
  nulle est fausse ; elle sert donc à calculer la puissance de ce test
  et la taille d'échantillon nécessaire.

  Contrairement au Student ordinaire, la loi n'est pas symétrique dès
  que DELTA n'est pas nul.

  Le calcul intègre la densité du khi-deux contre la répartition
  normale, par quadrature de Gauss-Legendre sur un intervalle qui
  couvre la masse à mieux que le millionième.

  Exemples :
     nctcdf(2, 10, 0)              % egale tcdf(2, 10)
     nctcdf(2, 10, 1)              % plus petit : la loi est decalee
     1 - nctcdf(tinv(0.95, 20), 20, 2)     % la puissance d'un test

  Voir aussi TCDF, NCTPDF, NCTINV, NCX2CDF, NCFCDF, TTEST.
```

## `nctinv`

```
NCTINV Quantile du Student décentré.
  X = NCTINV(P,V,DELTA) rend la valeur X telle que NCTCDF(X,V,DELTA)
  vaille P.

  Comme le support s'étend de moins l'infini à plus l'infini, la
  recherche commence par élargir un intervalle de part et d'autre,
  puis procède par dichotomie.

  Exemples :
     nctinv(0.95, 10, 0)           % egale tinv(0.95, 10)
     nctinv(0.95, 10, 2)
     nctcdf(nctinv(0.3, 8, 1), 8, 1)       % rend 0.3

  Voir aussi NCTCDF, NCTPDF, TINV, NCX2INV, NCFINV.
```

## `nctpdf`

```
NCTPDF Densité du Student décentré.
  D = NCTPDF(X,V,DELTA) rend la densité en X de la loi de Student
  décentrée à V degrés de liberté et de paramètre DELTA.

  La densité s'obtient de la même façon que la répartition, en
  conditionnant sur l'estimateur de l'écart type :

     f(x) = E[ s * phi(x*s - delta) ]

  où s est la racine d'un khi-deux réduit à V degrés.

  Quand DELTA vaut zéro, on retrouve TPDF.

  Exemples :
     nctpdf(0, 10, 0)              % egale tpdf(0, 10)
     x = linspace(-4, 8, 200);
     plot(x, nctpdf(x, 10, 0), x, nctpdf(x, 10, 2));

  Voir aussi NCTCDF, NCTINV, TPDF, NCX2PDF, NCFPDF.
```

## `ncx2cdf`

```
NCX2CDF Répartition du khi-deux décentré.
  P = NCX2CDF(X,V,DELTA) rend la probabilité qu'une variable du
  khi-deux à V degrés de liberté et de paramètre de décentrage DELTA
  soit inférieure à X.

  Le khi-deux décentré est la loi de la somme des carrés de V normales
  d'écart type un dont les moyennes ne sont pas nulles ; DELTA est la
  somme des carrés de ces moyennes. C'est la loi sous l'hypothèse
  alternative des tests fondés sur le khi-deux, et c'est donc elle
  qu'il faut pour calculer leur puissance.

  Le calcul emploie le développement en mélange de Poisson :

     P(X<x) = somme_k  exp(-delta/2) (delta/2)^k / k!  *  chi2cdf(x, v+2k)

  Les termes sont sommés à partir du plus probable, vers la droite puis
  vers la gauche, ce qui reste exact pour un DELTA de plusieurs
  centaines.

  Les arguments peuvent être des tableaux de même taille, ou des
  scalaires.

  Exemples :
     ncx2cdf(5, 2, 0)              % 0.9179 : c'est chi2cdf(5,2)
     ncx2cdf(5, 2, 3)              % plus petit : la loi est decalee
     1 - ncx2cdf(chi2inv(0.95, 1), 1, 4)   % la puissance d'un test

  Voir aussi CHI2CDF, NCTCDF, NCFCDF, NCX2PDF, NCX2INV.
```

## `ncx2inv`

```
NCX2INV Quantile du khi-deux décentré.
  X = NCX2INV(P,V,DELTA) rend la valeur X telle que NCX2CDF(X,V,DELTA)
  vaille P.

  L'inverse est cherché par dichotomie sur la répartition : elle est
  strictement croissante, donc la bissection converge à coup sûr, sans
  dépendre d'un point de départ.

  Exemples :
     ncx2inv(0.95, 2, 0)           % egale chi2inv(0.95, 2)
     ncx2inv(0.95, 2, 3)           % plus grand : la loi est decalee
     ncx2cdf(ncx2inv(0.7, 3, 2), 3, 2)     % rend 0.7

  Voir aussi NCX2CDF, NCX2PDF, CHI2INV, NCTINV, NCFINV.
```

## `ncx2pdf`

```
NCX2PDF Densité du khi-deux décentré.
  D = NCX2PDF(X,V,DELTA) rend la densité en X de la loi du khi-deux à V
  degrés de liberté et de paramètre de décentrage DELTA.

  Comme la répartition, la densité s'écrit en mélange de Poisson :

     f(x) = somme_k  exp(-delta/2) (delta/2)^k / k!  *  chi2pdf(x, v+2k)

  Quand DELTA vaut zéro, on retrouve exactement CHI2PDF.

  Exemples :
     ncx2pdf(3, 2, 0)              % egale chi2pdf(3, 2)
     ncx2pdf(3, 2, 4)
     x = linspace(0, 25, 200);
     plot(x, ncx2pdf(x, 4, 0), x, ncx2pdf(x, 4, 6));

  Voir aussi NCX2CDF, NCX2INV, CHI2PDF, NCTPDF, NCFPDF.
```

## `nlinfit`

_Pas de bloc d'aide._

## `nlparci`

```
NLPARCI Intervalles de confiance des paramètres d'un ajustement.
  CI = NLPARCI(BETA,R,'jacobian',J) rend les intervalles de confiance à
  95 pour cent des paramètres BETA, à partir des résidus R et de la
  jacobienne J que rend NLINFIT.

  CI = NLPARCI(BETA,R,'covar',COVB) part de la covariance des
  paramètres plutôt que de la jacobienne. C'est la forme à préférer :
  elle évite de refactoriser la jacobienne, et NLINFIT rend déjà COVB.

  CI = NLPARCI(...,'alpha',A) change le niveau : A = 0.01 donne des
  intervalles à 99 pour cent.

  CI compte une ligne par paramètre : la borne basse, puis la haute.

  L'intervalle repose sur la linéarisation du modèle autour de la
  solution ; il n'est exact que si le modèle est peu courbé au
  voisinage. Pour un modèle très non linéaire, un intervalle par
  bootstrap est plus sûr.

  Exemples :
     x = (0:0.2:5)';
     y = 2.5 * exp(-0.8 * x) + 0.01 * randn(size(x));
     [b, r, J, covb] = nlinfit(x, y, @(p, t) p(1) * exp(-p(2) * t), [1; 1]);
     nlparci(b, r, 'covar', covb)
     nlparci(b, r, 'jacobian', J, 'alpha', 0.01)

  Voir aussi NLINFIT, REGRESS, BOOTCI, TINV.
```

## `normfit`

```
NORMFIT Estimation des paramètres d'une loi normale.
  [MU,SIGMA] = NORMFIT(X) estime la moyenne et l'écart type de la loi
  normale dont X paraît tiré. MU est la moyenne empirique ; SIGMA est
  l'estimateur sans biais, celui qui divise par N-1 — non celui du
  maximum de vraisemblance, qui divise par N.

  [MU,SIGMA,MUCI,SIGMACI] = NORMFIT(X) rend aussi les intervalles de
  confiance à 95 pour cent des deux paramètres. Celui de la moyenne
  vient de la loi de Student, celui de l'écart type de la loi du
  khi-deux ; ce dernier n'est pas centré sur l'estimation, la loi du
  khi-deux n'étant pas symétrique.

  [...] = NORMFIT(X,ALPHA) donne des intervalles à 100*(1-ALPHA) pour
  cent : ALPHA = 0.01 pour 99 pour cent.

  Pour une matrice, chaque colonne est ajustée séparément.

  Exemples :
     x = normrnd(5, 2, 500, 1);
     [mu, sigma] = normfit(x)              % proche de 5 et 2
     [mu, sigma, muci, sigmaci] = normfit(x, 0.01)
     normfit([randn(100,1), randn(100,1) + 10])   % deux colonnes

  Voir aussi NORMPDF, NORMCDF, NORMINV, NORMLIKE, MLE, FITDIST.
```

## `normlike`

```
NORMLIKE Opposé de la log-vraisemblance d'une loi normale.
  PARAMS vaut [MU SIGMA].
```

## `normplot`

```
NORMPLOT Droite de Henry : les données sont-elles normales ?
  NORMPLOT(X) place les observations triées de X en regard des
  quantiles de la loi normale, et trace la droite qui passe par les
  deux quartiles. Si X est normal, les points s'alignent sur cette
  droite ; la façon dont ils s'en écartent dit ce qui cloche :

     une courbure en S      des queues plus lourdes que la normale ;
     un arc                 une dissymétrie ;
     un point isolé au bout une valeur aberrante.

  Pour une matrice, chaque colonne donne sa propre série de points.

  L'axe des ordonnées est gradué en probabilités et non en quantiles :
  c'est ce qui permet de lire directement la proportion d'observations
  sous un seuil.

  H = NORMPLOT(X) rend les poignées des traits.

  Le tracé est un examen, non un test : quand il faut une réponse
  chiffrée, LILLIETEST ou JBTEST la donnent.

  Exemples :
     normplot(randn(200, 1));            % aligne
     normplot(exprnd(1, 200, 1));        % courbe : dissymetrique
     normplot(trnd(2, 200, 1));          % un S : queues lourdes

  Voir aussi PROBPLOT, HISTFIT, LILLIETEST, JBTEST, QQPLOT.
```

## `normspec`

```
NORMSPEC Densité normale, avec la région entre deux tolérances.
  NORMSPEC(BORNES) trace la densité de la loi normale centrée réduite
  et colorie la partie qui tombe entre les deux tolérances de BORNES.
  Une borne infinie — ou NaN — laisse ce côté ouvert.

  NORMSPEC(BORNES,MU,SIGMA) emploie la loi de moyenne MU et d'écart
  type SIGMA.

  P = NORMSPEC(...) rend la probabilité de la région coloriée : c'est
  la proportion de la production qui respecterait les tolérances si le
  procédé suivait cette loi.

  NORMSPEC(BORNES,MU,SIGMA,REGION) choisit ce qui est colorié :
  'inside' (défaut) ou 'outside', auquel cas P est la proportion de
  rebuts.

  [P,H] = NORMSPEC(...) rend les poignées du tracé.

  C'est l'outil du contrôle de fabrication : on y lit d'un coup d'œil
  si les tolérances laissent assez de marge au procédé.

  Exemples :
     normspec([-2 2])                    % 0.9545 : deux ecarts types
     normspec([9.9 10.1], 10, 0.05)      % un procede bien centre
     normspec([9.9 Inf], 10, 0.05)       % une seule tolerance
     normspec([-1 1], 0, 1, 'outside')   % la proportion de rebuts

  Voir aussi NORMCDF, NORMPDF, HISTFIT, CAPABILITY, BOXPLOT.
```

## `normstat`

```
NORMSTAT Moyenne et variance de la loi normale.
  Exemple :  [m,v] = normstat(3, 2)   % 3 et 4
```

## `pca`

```
PCA Analyse en composantes principales.
  [C,S,L] = PCA(X) centre les colonnes de X, puis rend les vecteurs
  propres de la covariance (C), les coordonnées des individus (S) et les
  valeurs propres (L), triés par variance décroissante.
```

## `pcacov`

```
PCACOV Composantes principales à partir de la covariance.
  COEFF = PCACOV(C) rend les composantes principales déduites de la
  matrice de covariance C, une par colonne, rangées par variance
  décroissante. C'est PCA quand on n'a plus les données mais seulement
  leur covariance — ce qui arrive souvent, une covariance étant tout ce
  qu'un article publie.

  [COEFF,L] = PCACOV(C) rend aussi les variances portées par chaque
  composante : ce sont les valeurs propres de C.

  [COEFF,L,EXPLIQUEE] = PCACOV(C) rend la part de la variance totale
  que chaque composante explique, en pour cent.

  Le signe de chaque colonne est fixé comme dans MATLAB : la
  composante de plus grande valeur absolue est rendue positive, de
  sorte que deux appels donnent le même résultat.

  PCACOV appliqué à une matrice de corrélation donne l'analyse en
  composantes principales normée, celle qu'il faut quand les variables
  n'ont pas la même unité.

  Exemples :
     X = randn(100, 3) * [1 0 0; 0.5 1 0; 0 0 2];
     [c1, l1] = pcacov(cov(X));
     [c2, ~, l2] = pca(X);
     max(abs(l1 - l2))            % les memes valeurs propres

     pcacov(corrcoef(X))          % l'analyse normee

  Voir aussi PCA, PRINCOMP, COV, CORRCOEF, EIG, CANONCORR.
```

## `pdf`

```
PDF Densité ou probabilité d'une loi nommée.
  Y = PDF('name', X, A, B, C) appelle la fonction de densité de la loi
  nommée. Les noms suivent MATLAB : 'Normal', 'Poisson', 'Weibull',
  'Chisquare', 'Discrete Uniform'…, avec leurs abréviations.

  Exemple :  pdf('Normal', 0, 0, 1)   % 0.3989
```

## `pdist`

```
PDIST Distances entre toutes les paires d'observations.
  D = PDIST(X) rend les distances euclidiennes entre les lignes de X,
  sous forme d'un vecteur ligne de N(N-1)/2 termes — seulement le
  triangle supérieur, puisque la matrice est symétrique et de diagonale
  nulle. L'ordre est celui des colonnes du triangle :

     (2,1) (3,1) … (N,1) (3,2) … (N,2) … (N,N-1)

  SQUAREFORM(D) redonne la matrice carrée.

  D = PDIST(X,METRIQUE) choisit la distance :
     'euclidean'    la racine de la somme des carrés (défaut) ;
     'seuclidean'   euclidienne normalisée par l'écart type de chaque
                    variable, pour que les unités ne pèsent plus ;
     'cityblock'    la somme des écarts absolus, dite de Manhattan ;
     'chebychev'    le plus grand écart, coordonnée par coordonnée ;
     'minkowski'    la norme p ; PDIST(X,'minkowski',P) fixe P (2 par
                    défaut) ;
     'cosine'       un moins le cosinus de l'angle entre les vecteurs ;
     'correlation'  un moins la corrélation des deux lignes, chacune
                    centrée sur sa propre moyenne ;
     'hamming'      la proportion de coordonnées qui diffèrent ;
     'jaccard'      la proportion de coordonnées qui diffèrent parmi
                    celles où au moins l'une des deux est non nulle ;
     'spearman'     un moins la corrélation des rangs.

  La métrique peut aussi être une poignée de fonction @(u,v) …, appelée
  sur une ligne u et une matrice v de lignes.

  Exemples :
     X = [0 0; 3 4; 0 4];
     pdist(X)                        % [5 4 3]
     squareform(pdist(X))            % la matrice 3 x 3
     pdist(X, 'cityblock')           % [7 4 3]
     pdist([1 0; 0 1], 'cosine')     % 1 : les vecteurs sont orthogonaux

  Voir aussi SQUAREFORM, PDIST2, LINKAGE, MAHAL, KMEANS, KNNSEARCH.
```

## `pdist2`

```
PDIST2 Distances entre deux jeux d'observations.
  D = PDIST2(X,Y) rend la matrice des distances euclidiennes entre les
  lignes de X et celles de Y : D(i,j) est la distance de X(i,:) à
  Y(j,:). Elle a autant de lignes que X et autant de colonnes que Y.

  D = PDIST2(X,Y,METRIQUE) choisit la distance, parmi les mêmes que
  PDIST : 'euclidean', 'seuclidean', 'cityblock', 'chebychev',
  'minkowski', 'cosine', 'correlation', 'hamming', 'jaccard',
  'spearman'. PDIST2(X,Y,'minkowski',P) fixe l'exposant.

  [D,I] = PDIST2(X,Y,METRIQUE,'Smallest',K) ne rend que les K plus
  petites distances de chaque colonne, triées, et les indices des
  lignes de X où elles ont été trouvées. 'Largest' fait l'inverse.
  C'est la forme qui sert à chercher les plus proches voisins sans
  construire toute la matrice de distances en mémoire utile.

  Exemples :
     X = [0 0; 3 4; 1 1];
     Y = [0 0; 1 1];
     pdist2(X, Y)                        % 3 x 2
     [d, i] = pdist2(X, Y, 'euclidean', 'Smallest', 1)
     % d = [0 0], i = [1 3] : chaque ligne de Y a sa jumelle dans X,
     % a la distance nulle, et I dit laquelle

  Voir aussi PDIST, SQUAREFORM, KNNSEARCH, MAHAL, KMEANS.
```

## `poisscdf`

```
POISSCDF Répartition de la loi de Poisson.
  P(X <= k) est la gamma incomplète supérieure d'ordre k+1 en lambda.

  Exemple :  poisscdf(2, 1)   % 0.919698602928
```

## `poissfit`

```
POISSFIT Estimation de l'intensité d'une loi de Poisson.
  LAMBDA = POISSFIT(X) estime l'intensité de la loi de Poisson dont X
  paraît tiré. Le maximum de vraisemblance est la moyenne empirique.

  [LAMBDA,LAMBDACI] = POISSFIT(X) rend aussi l'intervalle de confiance
  à 95 pour cent, obtenu par le lien exact entre la loi de Poisson et
  celle du khi-deux : la somme des observations, multipliée par deux,
  encadre l'intensité par deux quantiles de khi-deux.

  [...] = POISSFIT(X,ALPHA) donne un intervalle à 100*(1-ALPHA) pour
  cent.

  Pour une matrice, chaque colonne est ajustée séparément.

  Exemples :
     x = poissrnd(3, 500, 1);
     [lambda, ci] = poissfit(x)        % lambda proche de 3
     poissfit(x, 0.01)

  Voir aussi POISSPDF, POISSCDF, POISSINV, POISSTAT, MLE, FITDIST.
```

## `poissinv`

```
POISSINV Quantile de la loi de Poisson.
  Le plus petit entier X tel que POISSCDF(X,LAMBDA) >= P.
```

## `poissrnd`

```
POISSRND Tirages d'une loi de Poisson.
  Méthode du produit de Knuth pour les petites intensités : on
  multiplie des uniformes jusqu'à passer sous exp(-lambda). Au-delà,
  l'inversion de la répartition évite le nombre d'itérations qui
  croîtrait avec lambda.
```

## `poisstat`

```
POISSTAT Moyenne et variance de la loi de Poisson : toutes deux LAMBDA.
```

## `polyconf`

```
POLYCONF Évalue un polynôme ajusté et l'incertitude de la prédiction.
  Y = POLYCONF(P,X) évalue le polynôme P en X : c'est POLYVAL.

  [Y,DELTA] = POLYCONF(P,X,S) rend en outre la demi-largeur de
  l'intervalle de prédiction à 95 pour cent, à partir de la structure S
  que rend POLYFIT. Y ± DELTA encadre une observation future en X avec
  cette probabilité.

  POLYCONF(...,'alpha',A) change le niveau.
  POLYCONF(...,'predopt','curve') donne l'intervalle de la courbe
  ajustée elle-même — celui de la moyenne de Y en X — au lieu de celui
  d'une observation future. Il est plus étroit : il ne compte pas la
  dispersion résiduelle, seulement l'incertitude sur les coefficients.
  'observation' est le défaut.
  POLYCONF(...,'simopt','on') élargit l'intervalle de façon qu'il
  vaille simultanément pour tous les X, et non pour chacun pris à part.

  Exemples :
     x = (0:0.5:10)';
     y = 2 * x + 1 + randn(size(x));
     [p, S] = polyfit(x, y, 1);
     [yy, delta] = polyconf(p, x, S);
     plot(x, y, 'o', x, yy, '-', x, yy - delta, 'r:', x, yy + delta, 'r:');

     [~, etroit] = polyconf(p, x, S, 'predopt', 'curve');
     max(etroit) < max(delta)             % vrai : la courbe est mieux
                                          % connue qu'une observation

  Voir aussi POLYFIT, POLYVAL, NLPARCI, REGRESS, FITLM.
```

## `predictknn`

```
PREDICTKNN Prédiction d'un classifieur k plus proches voisins.
```

## `predicttree`

```
PREDICTTREE Prédiction d'un arbre construit par FITCTREE.
```

## `princomp`

```
PRINCOMP Analyse en composantes principales (nom historique).
  [COEFF,SCORE,LATENT] = PRINCOMP(X) fait ce que fait PCA : il centre
  les colonnes de X, cherche les directions de plus grande variance, et
  rend les vecteurs propres (COEFF), les coordonnées des individus dans
  cette base (SCORE) et les variances portées (LATENT).

  [COEFF,SCORE,LATENT,TSQUARED] = PRINCOMP(X) rend en outre le T carré
  de Hotelling de chaque observation : sa distance au centre du nuage,
  mesurée dans la métrique des composantes. C'est ce qui sert à
  repérer les individus atypiques.

  PRINCOMP est le nom que la fonction portait avant R2012b ; PCA lui a
  succédé, avec les mêmes trois premières sorties. MatLibre garde les
  deux, pour que les programmes anciens tournent sans retouche.

  Exemples :
     X = randn(100, 3) * [1 0 0; 0.5 1 0; 0 0 2];
     [coeff, score, latent, t2] = princomp(X);
     cumsum(latent) / sum(latent)     % la part expliquee cumulee
     max(t2)                          % l'individu le plus atypique

  Voir aussi PCA, PCACOV, MAHAL, CANONCORR, COV.
```

## `probplot`

```
PROBPLOT Diagramme de probabilité pour une loi quelconque.
  PROBPLOT(Y) place les observations de Y en regard des quantiles de la
  loi normale, comme NORMPLOT.

  PROBPLOT(LOI,Y) emploie une autre loi de référence. LOI est un nom :
  'normal', 'lognormal', 'exponential', 'weibull', 'extreme value',
  'rayleigh', 'logistic', 'uniform'. Les points s'alignent si Y suit
  cette loi.

  PROBPLOT(LOI,Y,CENSURE,FREQUENCE) accepte les arguments de MATLAB
  pour les données censurées et pondérées ; MatLibre les reçoit et
  n'en tient pas compte.

  H = PROBPLOT(...) rend les poignées des traits.

  La droite est celle qui passe par les premier et troisième
  quartiles : elle représente la loi ajustée sans être influencée par
  les extrêmes, ce qui laisse voir les écarts en bout de queue.

  Les positions de tracé sont celles de MATLAB, (i-0.5)/n : elles
  évitent que la plus grande observation soit placée à la probabilité
  un, qui n'a pas de quantile fini.

  Exemples :
     probplot(randn(200, 1));
     probplot('exponential', exprnd(2, 200, 1));   % aligne
     probplot('weibull', wblrnd(1, 2, 200, 1));    % aligne aussi
     probplot('normal', exprnd(1, 200, 1));        % ne s'aligne pas

  Voir aussi NORMPLOT, HISTFIT, ECDF, LILLIETEST, KSTEST.
```

## `procrustes`

```
PROCRUSTES Superposition de deux nuages de points.
  D = PROCRUSTES(X,Y) cherche la rotation, la mise à l'échelle et la
  translation qui rapprochent le plus le nuage Y du nuage X, et rend la
  dissemblance qui subsiste : la somme des carrés des écarts, rapportée
  à la dispersion de X. Elle vaut 0 quand les deux nuages sont
  superposables, 1 quand Y n'apporte rien de plus qu'un point unique.

  Les deux nuages doivent avoir le même nombre de points, et le
  i-ième point de l'un correspond au i-ième de l'autre.

  [D,Z] = PROCRUSTES(X,Y) rend le nuage Y transformé, celui qui se
  superpose à X.

  [D,Z,T] = PROCRUSTES(X,Y) rend la transformation, dans une structure
  de trois champs : T.c la translation, T.T la rotation, T.b l'échelle,
  telles que Z = T.b * Y * T.T + T.c.

  PROCRUSTES(...,'Scaling',false) interdit la mise à l'échelle : la
  transformation se réduit à une rotation et une translation.
  PROCRUSTES(...,'Reflection',false) interdit la réflexion : la
  rotation garde l'orientation. 'best' laisse choisir celle qui
  rapproche le plus, ce qui est le défaut.

  C'est l'outil de la morphométrie et de la comparaison de
  configurations : il répond à « ces deux formes sont-elles les mêmes,
  à la position, l'orientation et la taille près ? »

  Exemples :
     X = [0 0; 1 0; 1 1; 0 1];
     Y = X * [0 1; -1 0] * 3 + 5;      % tourne, agrandi, deplace
     [d, Z] = procrustes(X, Y);
     d                                  % pratiquement zero
     max(max(abs(Z - X)))               % Z retombe sur X

  Voir aussi PDIST, MDSCALE, PCA, CANONCORR, SVD.
```

## `random`

```
RANDOM Tirages d'une loi nommée.
  R = RANDOM('name', A, B, C, M, N) : les paramètres d'abord, les
  dimensions ensuite, comme pour les fonctions ...RND.

  Exemple :  random('Poisson', 4, 1, 5)   % cinq tirages
```

## `ranksum`

```
RANKSUM Test de Wilcoxon-Mann-Whitney sur deux échantillons.
  P = RANKSUM(X,Y) rend la p-valeur bilatérale de l'hypothèse « les deux
  échantillons viennent de la même loi ». L'approximation normale est
  utilisée, avec correction de continuité.

  Exemple :
     ranksum(1:10, 11:20)   % très petite : les deux groupes diffèrent
```

## `raylcdf`

```
RAYLCDF Répartition de la loi de Rayleigh.
```

## `raylfit`

```
RAYLFIT Estimation du paramètre d'une loi de Rayleigh.
  Le maximum de vraisemblance vaut sqrt(sum(x^2)/(2n)).
```

## `raylinv`

```
RAYLINV Quantile de la loi de Rayleigh de paramètre B.
  Exemple :  raylinv(0.5, 1)   % sqrt(2 log 2) = 1.1774
```

## `raylpdf`

```
RAYLPDF Densité de la loi de Rayleigh de paramètre B.
  Y = X/B^2 * exp(-X^2/(2*B^2)) pour X >= 0.
```

## `raylrnd`

```
RAYLRND Tirages d'une loi de Rayleigh.
```

## `raylstat`

```
RAYLSTAT Moyenne et variance de la loi de Rayleigh.
  Exemple :  [m,v] = raylstat(1)   % sqrt(pi/2) et 2 - pi/2
```

## `refcurve`

```
REFCURVE Ajoute une courbe polynomiale de référence à un tracé.
  REFCURVE(P) ajoute au tracé courant la courbe du polynôme dont les
  coefficients sont P, rangés du degré le plus haut au plus bas comme
  le veut POLYVAL. La courbe est dessinée d'un bout à l'autre de l'axe
  des abscisses, sans en changer les limites.

  REFCURVE sans argument ajoute la parabole des moindres carrés sur les
  points déjà tracés.

  H = REFCURVE(...) rend la poignée de la courbe.

  Exemples :
     x = linspace(-3, 3, 40);
     plot(x, x .^ 2 + randn(1, 40) * 0.5, 'o');
     refcurve([1 0 0]);          % la parabole vraie
     refcurve;                   % celle des moindres carres

  Voir aussi REFLINE, POLYFIT, POLYVAL, LINE.
```

## `refline`

```
REFLINE Ajoute une droite de référence à un tracé.
  REFLINE(M,B) ajoute la droite Y = M*X + B au tracé courant, d'un bout
  à l'autre de l'axe des abscisses, sans changer les limites.

  REFLINE(COEFFS) où COEFFS est le vecteur [M B] fait la même chose.

  REFLINE sans argument ajuste les moindres carrés sur les points déjà
  tracés et ajoute la droite de régression. C'est la forme la plus
  employée : on trace un nuage, puis on appelle REFLINE.

  H = REFLINE(...) rend la poignée de la droite.

  Exemples :
     x = 1:20;
     plot(x, 2 * x + randn(1, 20) * 2, 'o');
     refline;                    % la droite des moindres carres
     refline(2, 0);              % la droite vraie, pour comparer

  Voir aussi REFCURVE, LSLINE, POLYFIT, LINE, YLINE.
```

## `regress`

```
REGRESS Régression linéaire multiple par moindres carrés.
  B = REGRESS(Y,X) rend les coefficients de Y = X*B.
  [B,BINT,R,RINT,STATS] = REGRESS(...) rend aussi les intervalles de
  confiance à 95 %, les résidus, et [R2, F, p, variance résiduelle].
```

## `regstats`

```
REGSTATS Régression linéaire et ses diagnostics.
  S = REGSTATS(Y,X) ajuste Y = b0 + X*b par moindres carrés et rend une
  structure portant tout ce qu'on demande d'ordinaire à une régression :

     beta        les coefficients, le terme constant en tête ;
     yhat        les valeurs ajustées ;
     r           les résidus ;
     mse         la variance résiduelle ;
     rsquare     le coefficient de détermination ;
     adjrsquare  le même, corrigé du nombre de variables ;
     tstat       une sous-structure : erreurs types, t et p de chaque
                 coefficient, plus leurs intervalles de confiance ;
     fstat       le test global de nullité de tous les coefficients ;
     covb        la covariance des coefficients ;
     leverage    le levier de chaque observation — sa capacité à tirer
                 la droite à elle ;
     cookd       la distance de Cook : de combien l'ajustement change
                 si l'on retire cette observation ;
     dffits      l'effet de ce retrait sur la seule valeur ajustée ;
     standres, studres  les résidus réduits, ordinaires et studentisés ;
     dwstat      la statistique de Durbin-Watson, qui détecte
                 l'autocorrélation des résidus.

  S = REGSTATS(Y,X,MODELE) choisit la forme du modèle : 'linear'
  (défaut), 'interaction' pour ajouter les produits croisés,
  'quadratic' pour y ajouter les carrés, 'purequadratic' pour les
  carrés sans les croisements.

  S = REGSTATS(Y,X,MODELE,QUOI) où QUOI est un tableau de cellules de
  noms ne calcule que ceux-là. Un seul nom, donné comme chaîne, rend
  directement la valeur au lieu d'une structure.

  Un levier proche de un, une distance de Cook supérieure à 4/N :
  ce sont les observations à regarder de près avant de conclure.

  Exemples :
     x = (1:20)';
     y = 2 * x + 1 + randn(20, 1);
     s = regstats(y, x);
     s.beta                       % proche de [1 ; 2]
     s.rsquare
     find(s.cookd > 4 / 20)       % les observations influentes

     regstats(y, x, 'linear', 'rsquare')

  Voir aussi REGRESS, FITLM, ROBUSTFIT, POLYFIT, ANOVA1.
```

## `ridge`

```
RIDGE Régression pénalisée par la norme des coefficients.
  B = RIDGE(Y,X,K) résout

     minimiser  ||y - X*b||^2 + K * ||b||^2

  au lieu des seuls moindres carrés. Quand les colonnes de X sont
  presque colinéaires, les moindres carrés donnent des coefficients
  énormes et de signes contraires, qui se compensent ; la pénalité les
  ramène vers zéro et rend l'ajustement stable, au prix d'un biais.

  Par défaut X est centré et réduit avant l'ajustement, et B est rendu
  dans cette échelle-là, sans terme constant : c'est ainsi que K a le
  même sens pour toutes les colonnes.

  B = RIDGE(Y,X,K,0) ramène ensuite les coefficients à l'échelle
  d'origine et ajoute le terme constant en première ligne, de sorte
  que Y s'estime par [1 X]*B.

  K peut être un vecteur : B a alors une colonne par valeur, ce qui
  donne la trace de la régression pénalisée — le dessin des
  coefficients en fonction de la pénalité, dont on se sert pour
  choisir K.

  Exemples :
     % Deux colonnes presque identiques
     x1 = (1:20)';
     X = [x1, x1 + randn(20, 1) * 0.01];
     y = 3 * x1 + randn(20, 1);
     X \ y                        % coefficients enormes et opposes
     ridge(y, X, 1)               % ramenes pres l'un de l'autre

     trace = ridge(y, X, 0:0.5:10);
     plot(0:0.5:10, trace');      % la trace de la penalisation

  Voir aussi REGRESS, ROBUSTFIT, LASSO, PCA, FITLM.
```

## `robustfit`

```
ROBUSTFIT Régression linéaire robuste, par moindres carrés repondérés.
  B = ROBUSTFIT(X,Y) ajuste Y = B(1) + X*B(2:end) en donnant moins de
  poids aux observations qui s'écartent du modèle. Une seule valeur
  aberrante suffit à faire basculer une régression ordinaire ;
  ROBUSTFIT la reconnaît à son résidu et la fait taire.

  La méthode est celle des moindres carrés repondérés : on ajuste, on
  mesure les résidus, on en tire un poids par observation, on réajuste,
  et l'on recommence jusqu'à ce que les coefficients ne bougent plus.

  B = ROBUSTFIT(X,Y,POIDS) choisit la fonction de poids :
     'bisquare'   celle de Tukey, qui annule le poids au-delà du
                  réglage (défaut) ;
     'huber'      poids en 1/|r| au-delà du réglage : moins brutale,
                  elle ne rejette jamais tout à fait ;
     'andrews', 'cauchy', 'fair', 'logistic', 'talwar', 'welsch'
                  les autres fonctions de MATLAB ;
     'ols'        aucun repondérage : les moindres carrés ordinaires.
  POIDS peut aussi être une poignée @(r) …, qui rend le poids à partir
  du résidu réduit.

  B = ROBUSTFIT(X,Y,POIDS,REGLAGE) change la constante de réglage.
  B = ROBUSTFIT(X,Y,POIDS,REGLAGE,'off') n'ajoute pas de terme
  constant : X est pris tel quel.

  [B,STATS] = ROBUSTFIT(...) rend en outre les résidus, les poids
  finaux, l'écart type robuste et les erreurs types des coefficients.

  Exemples :
     x = (1:20)';
     y = 2 * x + 1;
     y(10) = 100;                    % une valeur aberrante
     [x ones(20,1)] \ y              % les moindres carres : fausses
     robustfit(x, y)                 % proche de [1 ; 2]

  Voir aussi REGRESS, FITLM, POLYFIT, RIDGE, LSCOV.
```

## `runstest`

```
RUNSTEST Test des suites : l'ordre des observations est-il quelconque ?
  H = RUNSTEST(X) teste l'hypothèse « les observations de X sont dans
  un ordre quelconque », en comptant les suites — les plages
  consécutives de valeurs toutes au-dessus ou toutes au-dessous de la
  médiane. Trop peu de suites signale une tendance ou une persistance ;
  trop de suites, une alternance.

  H = RUNSTEST(X,V) compare à V au lieu de la médiane. V peut aussi
  être 'mean' pour la moyenne, ou 'median'.

  [H,P] = RUNSTEST(...) rend la probabilité critique, par
  l'approximation normale du nombre de suites.
  [H,P,STATS] = RUNSTEST(...) rend le nombre de suites, les effectifs
  au-dessus et au-dessous, et la statistique centrée réduite.

  RUNSTEST(...,'Alpha',A) change le seuil.
  RUNSTEST(...,'Method','exact') calcule la probabilité exacte, par
  dénombrement, au lieu de l'approximation normale ; c'est ce qu'il
  faut pour de petits échantillons.

  C'est le test qu'on fait sur les résidus d'une régression : s'ils
  sont bien du bruit, leurs signes doivent alterner au hasard ; s'ils
  forment de longues plages de même signe, le modèle a manqué quelque
  chose.

  Exemples :
     x = repmat([1 -1], 1, 20);
     runstest(x)                       % 1 : quarante suites, bien trop
     runstest(1:40)                    % 1 : une seule montee, deux suites
     runstest(randn(100, 1))           % 0 : rien a signaler
     [h, p, s] = runstest(1:8);
     s.nruns                           % 2

  Voir aussi SIGNTEST, KSTEST, AUTOCORR, MEDIAN.
```

## `signrank`

```
SIGNRANK Test des rangs signés de Wilcoxon, sur échantillons appariés.
  P = SIGNRANK(X) teste la médiane nulle ; SIGNRANK(X,Y) teste la
  médiane de X-Y.
```

## `signtest`

```
SIGNTEST Test du signe sur la médiane.
  P = SIGNTEST(X) teste l'hypothèse « la médiane de X est nulle » en ne
  regardant que le signe des observations : combien sont positives,
  combien négatives. Sous l'hypothèse, ce nombre suit une loi binomiale
  de paramètre un demi.

  P = SIGNTEST(X,Y) teste que la médiane de X-Y est nulle, sur
  échantillons appariés. Si Y est un scalaire, il teste que la médiane
  de X vaut Y.

  [P,H] = SIGNTEST(...) rend aussi la décision : H vaut 1 quand
  l'hypothèse est rejetée au seuil ALPHA, 0.05 par défaut.
  [P,H,STATS] = SIGNTEST(...) rend le nombre d'observations positives.

  C'est le test le moins exigeant de tous : il ne suppose rien sur la
  forme de la loi, pas même la symétrie que demande SIGNRANK. En
  contrepartie, il détecte moins bien un écart réel, puisqu'il jette
  l'amplitude des observations pour n'en garder que le signe.

  Les observations nulles sont écartées, comme le veut la convention.

  Exemples :
     signtest([-2 -1 1 2])            % 1 : deux de chaque cote
     signtest([1 2 3 4 5 6 7 8])      % 0.0078 : toutes positives
     signtest([10 11 12], 11)         % teste la mediane 11

  Voir aussi SIGNRANK, TTEST, RANKSUM, MEDIAN, BINOCDF.
```

## `silhouette`

```
SILHOUETTE Indice de silhouette de chaque observation.
```

## `skewness`

```
SKEWNESS Coefficient d'asymétrie (moment d'ordre trois normalisé).
```

## `squareform`

```
SQUAREFORM Passe du vecteur des distances à la matrice carrée, et retour.
  S = SQUAREFORM(D) où D est le vecteur que rend PDIST rebâtit la
  matrice carrée des distances : S(i,j) est la distance de i à j, la
  diagonale est nulle et la matrice symétrique.

  D = SQUAREFORM(S) où S est une matrice carrée symétrique de diagonale
  nulle rend le vecteur des distances, dans l'ordre de PDIST.

  La fonction devine le sens d'après la forme de l'argument. Pour le
  lui imposer :
     SQUAREFORM(D,'tomatrix')  force le passage au carré ;
     SQUAREFORM(S,'tovector')  force le passage au vecteur.

  Ce dernier sert quand l'argument est de taille 1 x 1, seul cas
  ambigu : c'est aussi bien la distance d'une paire que la matrice
  d'un unique point.

  Exemples :
     d = pdist([0 0; 3 4; 0 4])      % [5 4 3]
     S = squareform(d)               % [0 5 4; 5 0 3; 4 3 0]
     squareform(S)                   % [5 4 3], on revient au vecteur

  Voir aussi PDIST, PDIST2, LINKAGE, TRIU.
```

## `statAjuster`

```
STATAJUSTER Étend les arguments à une taille commune.
  Les fonctions de loi de MATLAB acceptent que chaque argument soit un
  scalaire ou un tableau, à condition que tous les tableaux aient la
  même taille ; le résultat prend cette taille. STATAJUSTER applique
  cette règle une fois pour toutes.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `statEtendre`

```
STATETENDRE Répète un paramètre scalaire à la taille demandée.
  Un paramètre déjà de la bonne taille passe tel quel ; toute autre
  taille est une erreur, comme dans MATLAB.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `statForme`

```
STATFORME Taille demandée à un générateur aléatoire.
  Les fonctions ...RND de MATLAB acceptent des dimensions après les
  paramètres : RND(A,M), RND(A,M,N), RND(A,[M N]). Sans dimension, le
  résultat prend la taille des paramètres.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `statPrefixeLoi`

```
STATPREFIXELOI Préfixe des fonctions d'une loi nommée.
  MATLAB accepte pour chaque loi un nom long et une abréviation :
  'Normal' ou 'norm', 'Chisquare' ou 'chi2', et ainsi de suite.
  STATPREFIXELOI ramène les deux au préfixe des fonctions ...PDF,
  ...CDF, ...INV et ...RND.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `statQuantileDiscret`

```
STATQUANTILEDISCRET Plus petit entier dont la répartition atteint P.
  REPARTITION est une poignée de fonction, DEPART un point de départ
  pour la marche, MAXIMUM la borne supérieure du support. Comme dans
  MATLAB, le quantile d'une loi discrète est le plus petit entier X tel
  que F(X) >= P ; la comparaison se fait sur la même fonction de
  répartition que celle exportée, si bien que l'aller-retour est exact.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `statget`

```
STATGET Lit un champ d'une structure d'options statistiques.
  V = STATGET(OPTIONS,'nom') rend la valeur du champ nommé, ou la
  matrice vide s'il n'est pas renseigné.

  V = STATGET(OPTIONS,'nom',DEFAUT) rend DEFAUT quand le champ est
  absent ou vide. C'est la forme dont se servent les fonctions
  d'ajustement : elles n'ont pas à savoir si l'utilisateur a fourni
  une structure complète, une structure partielle, ou rien du tout.

  La comparaison des noms ne tient pas compte de la casse.

  Exemples :
     options = statset('MaxIter', 500);
     statget(options, 'MaxIter')            % 500
     statget(options, 'TolFun', 1e-8)       % 1e-8, le defaut
     statget([], 'MaxIter', 100)            % 100

  Voir aussi STATSET, NLINFIT, MLE, OPTIMGET.
```

## `statset`

```
STATSET Structure d'options des fonctions statistiques.
  OPTIONS = STATSET('nom1',valeur1,'nom2',valeur2,...) construit la
  structure d'options que prennent les fonctions d'ajustement de la
  boîte à outils : NLINFIT, MLE, KMEANS, entre autres.

  OPTIONS = STATSET sans argument rend la structure par défaut, tous
  les champs vides : chaque fonction emploie alors sa propre valeur.

  OPTIONS = STATSET(ANCIENNES,'nom',valeur,...) part d'une structure
  existante et n'en change que ce qui est nommé.

  V = STATSET(OPTIONS,'nom') n'est pas la forme de MATLAB ; pour lire
  un champ, employez STATGET.

  Les champs reconnus :
     Display        'off', 'final' ou 'iter' ;
     MaxIter        nombre maximal d'itérations ;
     MaxFunEvals    nombre maximal d'évaluations ;
     TolFun         tolérance sur la fonction ;
     TolX           tolérance sur les paramètres ;
     TolBound       tolérance sur les bornes ;
     GradObj        'on' si le gradient est fourni ;
     DerivStep      pas des différences finies ;
     FunValCheck    'on' pour refuser un NaN ou un infini ;
     Robust         'on' pour un ajustement robuste ;
     WgtFun         fonction de poids, si Robust vaut 'on' ;
     Tune           constante de réglage de cette fonction ;
     Streams, UseParallel, UseSubstreams : acceptés, sans effet.

  Exemples :
     options = statset('MaxIter', 1000, 'TolFun', 1e-12);
     nlinfit(x, y, modele, depart, options);

     serrees = statset(options, 'TolX', 1e-14);

  Voir aussi STATGET, NLINFIT, MLE, KMEANS, OPTIMSET.
```

## `stepwisefit`

```
STEPWISEFIT Régression pas à pas : quelles variables garder ?
  [B,SE,PVAL,INMODEL] = STEPWISEFIT(X,Y) construit une régression en
  ajoutant et retirant des variables une à une : à chaque pas, il
  ajoute celle qui apporte le plus, si elle apporte assez, et retire
  celle qui n'apporte plus assez. Il s'arrête quand plus rien ne bouge.

  B donne le coefficient de chaque colonne de X — celui qu'elle aurait
  si on l'ajoutait au modèle courant, pour celles qui n'y sont pas.
  INMODEL dit lesquelles ont été retenues. SE et PVAL sont l'erreur
  type et la probabilité critique de chaque coefficient.

  [...,STATS] = STEPWISEFIT(...) rend le détail du modèle final : le
  terme constant, la variance résiduelle, le R carré, la statistique de
  Fisher.

  STEPWISEFIT(...,'penter',P) fixe le seuil d'entrée, 0.05 par défaut.
  STEPWISEFIT(...,'premove',P) fixe le seuil de sortie, 0.10 par
  défaut. Le second doit dépasser le premier, faute de quoi la
  procédure peut boucler en ajoutant et retirant sans fin la même
  variable.
  STEPWISEFIT(...,'inmodel',V) part d'un modèle donné plutôt que du
  modèle vide.
  STEPWISEFIT(...,'display','off') n'affiche rien ; c'est le défaut de
  MatLibre.

  La sélection pas à pas est commode et trompeuse : les probabilités
  critiques du modèle final ne valent plus, puisqu'on a choisi les
  variables en les regardant. Elle sert à explorer, non à conclure.

  Exemples :
     X = randn(100, 5);
     y = 3 * X(:,2) - 2 * X(:,4) + randn(100, 1);
     [b, se, p, garde] = stepwisefit(X, y);
     find(garde)                  % 2 et 4 y sont toujours ; une autre
                                  % s'y glisse parfois, c'est le defaut
                                  % de la methode
     [b(2), b(4)]                 % proches de 3 et -2

     % Un seuil d'entree plus severe ecarte les fausses trouvailles
     [~, ~, ~, severe] = stepwisefit(X, y, 'penter', 0.01, 'premove', 0.05);

  Voir aussi REGRESS, REGSTATS, FITLM, RIDGE, LASSO.
```

## `tabulate`

```
TABULATE Effectifs et fréquences des valeurs distinctes.
  T = TABULATE(X) rend une matrice [valeur, effectif, pourcentage].
```

## `tcdf`

```
TCDF Fonction de répartition de la loi de Student.
  P = TCDF(T,NU) utilise la relation avec la fonction beta incomplète :
     P(T <= t) = 1 - I_{nu/(nu+t^2)}(nu/2, 1/2) / 2   pour t >= 0
  ce qui est exact et rapide, contrairement à une intégration numérique.
```

## `tiedrank`

```
TIEDRANK Rangs, les valeurs égales recevant leur rang moyen.
  R = TIEDRANK(X) rend le rang de chaque élément de X. Le plus petit
  reçoit le rang 1. Quand plusieurs valeurs sont égales, chacune reçoit
  la moyenne des rangs qu'elles auraient occupés : deux valeurs égales
  aux places 3 et 4 reçoivent toutes deux 3.5.

  C'est ce dont les tests de rangs ont besoin — RANKSUM, SIGNRANK, la
  corrélation de Spearman — pour que les liens ne faussent pas la
  statistique.

  [R,N] = TIEDRANK(X) rend en outre un terme de correction des liens,
  somme des (t^3 - t) sur les groupes de t valeurs égales, divisée par
  deux. Il vaut 0 s'il n'y a aucun lien.

  Pour une matrice, chaque colonne est classée séparément.

  Les NaN reçoivent le rang NaN et ne comptent pas dans le classement.

  Exemples :
     tiedrank([10 20 20 40])           % [1 2.5 2.5 4]
     tiedrank([3 1 2])                 % [3 1 2]
     [r, n] = tiedrank([1 1 1])        % r = [2 2 2], n = 12

  Voir aussi SORT, RANKSUM, SIGNRANK, CORR.
```

## `tinv`

```
TINV Quantile de la loi de Student, par dichotomie sur TCDF.
```

## `trimmean`

```
TRIMMEAN Moyenne élaguée.
  M = TRIMMEAN(X,P) rend la moyenne de X après avoir écarté les P pour
  cent des valeurs les plus extrêmes — la moitié en haut, la moitié en
  bas. C'est un compromis entre la moyenne, sensible à une seule valeur
  aberrante, et la médiane, qui n'emploie qu'un point.

  Le nombre de valeurs retirées de chaque côté est FLOOR(N*P/200) :
  TRIMMEAN(X,10) sur 100 points en retire cinq en haut et cinq en bas.
  TRIMMEAN(X,0) est la moyenne ordinaire ; TRIMMEAN(X,100) tend vers
  la médiane.

  M = TRIMMEAN(X,P,DIM) travaille le long de la dimension DIM.

  Exemples :
     x = [1 2 3 4 5 6 7 8 9 1000];
     mean(x)                           % 104.5, tirée par la dernière
     trimmean(x, 20)                   % 5.5, insensible
     trimmean(1:10, 0)                 % 5.5

  Voir aussi MEAN, MEDIAN, GEOMEAN, HARMMEAN, PRCTILE.
```

## `trnd`

```
TRND Tirages d'une loi de Student à V degrés de liberté.
  Le rapport d'une normale centrée réduite à la racine d'un khi-deux
  réduit suit la loi de Student.
```

## `tstat`

```
TSTAT Moyenne et variance de la loi de Student.
  La moyenne n'existe que pour NU > 1, la variance que pour NU > 2.
```

## `ttest`

```
TTEST Test de Student sur la moyenne d'un échantillon.
  [H,P] = TTEST(X,MU) teste l'hypothèse « la moyenne de X vaut MU ».
  H vaut 1 si l'hypothèse est rejetée au seuil ALPHA (5 % par défaut).
```

## `ttest2`

```
TTEST2 Test de Student sur deux échantillons indépendants.
```

## `unidcdf`

```
UNIDCDF Répartition de la loi uniforme discrète sur 1..N.
```

## `unidinv`

```
UNIDINV Quantile de la loi uniforme discrète sur 1..N.
```

## `unidpdf`

```
UNIDPDF Probabilité de la loi uniforme discrète sur 1..N.
  Exemple :  unidpdf(3, 6)   % 1/6, un dé
```

## `unidrnd`

```
UNIDRND Tirages d'une loi uniforme discrète sur 1..N.
```

## `unidstat`

```
UNIDSTAT Moyenne et variance de la loi uniforme discrète.
  Exemple :  [m,v] = unidstat(6)   % 3.5 et 35/12, un dé
```

## `unifcdf`

```
UNIFCDF Répartition de la loi uniforme continue sur [A,B].
```

## `unifinv`

```
UNIFINV Quantile de la loi uniforme continue sur [A,B].
```

## `unifit`

```
UNIFIT Estimation des bornes d'une loi uniforme continue.
  Le maximum de vraisemblance est le minimum et le maximum observés.
```

## `unifpdf`

```
UNIFPDF Densité de la loi uniforme continue sur [A,B].
```

## `unifstat`

```
UNIFSTAT Moyenne et variance de la loi uniforme continue.
  Exemple :  [m,v] = unifstat(0, 1)   % 0.5 et 1/12
```

## `vartest`

```
VARTEST Test du khi-deux sur une variance.
  H = VARTEST(X,V) teste l'hypothèse « la variance de X vaut V ». La
  statistique est

     chi2 = (N-1) * var(X) / V

  qui suit, sous l'hypothèse et pour des données normales, une loi du
  khi-deux à N-1 degrés de liberté.

  [H,P] = VARTEST(...) rend la probabilité critique.
  [H,P,CI] = VARTEST(...) rend l'intervalle de confiance de la
  variance ; il n'est pas centré sur l'estimation, la loi du khi-deux
  n'étant pas symétrique.
  [H,P,CI,STATS] = VARTEST(...) rend la statistique et ses degrés de
  liberté.

  VARTEST(...,'Alpha',A) change le seuil, 0.05 par défaut.
  VARTEST(...,'Tail',T) choisit le côté : 'both', 'right', 'left'.

  Le test est sensible à la non-normalité : un échantillon à queues
  lourdes le fait conclure à tort bien plus souvent que le seuil ne le
  laisse croire.

  Exemples :
     x = randn(100, 1) * 3;
     [h, p, ci] = vartest(x, 9)     % la vraie variance est 9
     vartest(x, 1)                  % rejette : elle vaut bien plus

  Voir aussi VARTEST2, TTEST, VAR, CHI2CDF, CHI2INV.
```

## `vartest2`

```
VARTEST2 Test de Fisher sur l'égalité de deux variances.
  H = VARTEST2(X,Y) teste l'hypothèse « X et Y ont la même variance ».
  La statistique est le rapport des variances estimées, qui suit une
  loi de Fisher-Snedecor sous l'hypothèse et pour des données normales.

  [H,P] = VARTEST2(...) rend la probabilité critique.
  [H,P,CI] = VARTEST2(...) rend l'intervalle de confiance du rapport
  des variances.
  [H,P,CI,STATS] = VARTEST2(...) rend la statistique et les deux degrés
  de liberté.

  VARTEST2(...,'Alpha',A) change le seuil ; VARTEST2(...,'Tail',T)
  choisit le côté : 'both', 'right', 'left'.

  C'est le test qu'on fait avant TTEST2 pour décider s'il faut ou non
  demander l'option d'égalité des variances. Il est lui-même très
  sensible à la non-normalité : sur des données douteuses, mieux vaut
  employer directement la forme de TTEST2 qui ne suppose pas l'égalité.

  Exemples :
     x = randn(50, 1);
     y = randn(50, 1) * 3;
     [h, p] = vartest2(x, y)        % rejette : les variances different
     vartest2(randn(50,1), randn(50,1))   % ne rejette pas

  Voir aussi VARTEST, TTEST2, VAR, FCDF, FINV.
```

## `wblcdf`

```
WBLCDF Répartition de la loi de Weibull.
```

## `wblfit`

```
WBLFIT Estimation des paramètres d'une loi de Weibull.
  Le maximum de vraisemblance annule
     sum(x^b log x)/sum(x^b) - 1/b - moyenne(log x),
  équation en la seule forme B, résolue par Newton ; l'échelle A suit
  par (sum(x^b)/n)^(1/b).

  PHAT vaut [A B] : échelle et forme.
```

## `wblinv`

```
WBLINV Quantile de la loi de Weibull d'échelle A et de forme B.
  Exemple :  wblinv(1 - exp(-1), 1, 1)   % 1
```

## `wblpdf`

```
WBLPDF Densité de la loi de Weibull, d'échelle A et de forme B.
  Exemple :  wblpdf(1, 1, 1)   % exp(-1)
```

## `wblrnd`

```
WBLRND Tirages d'une loi de Weibull.
```

## `wblstat`

```
WBLSTAT Moyenne et variance de la loi de Weibull.
  Les moments s'écrivent avec la fonction gamma :
  E[X] = a*gamma(1+1/b), Var[X] = a^2*(gamma(1+2/b) - gamma(1+1/b)^2).

  Exemple :  [m,v] = wblstat(1, 1)   % 1 et 1, la loi exponentielle
```

## `wishrnd`

```
WISHRND Tirage d'une matrice de Wishart.
  W = WISHRND(SIGMA,DF) tire une matrice de la loi de Wishart de
  paramètre d'échelle SIGMA et de DF degrés de liberté. C'est la loi de

     W = somme des x_i * x_i'

  où les x_i sont DF tirages indépendants d'une loi normale
  multivariée centrée de covariance SIGMA. Autrement dit, c'est la loi
  de la matrice des sommes de carrés et de produits croisés — celle
  dont dépend la covariance empirique.

  W = WISHRND(SIGMA,DF,D) emploie le facteur de Cholesky D de SIGMA
  déjà calculé, ce qui évite de le refaire à chaque tirage.
  [W,D] = WISHRND(SIGMA,DF) rend ce facteur, pour le réemployer.

  DF n'a pas besoin d'être entier : le tirage passe par la
  décomposition de Bartlett, où les carrés de la diagonale suivent des
  lois du khi-deux à DF-i+1 degrés. C'est aussi ce qui le rend rapide :
  il ne coûte pas DF tirages normaux, mais p(p+1)/2 tirages en tout.

  L'espérance de W vaut DF*SIGMA.

  Exemples :
     S = [2 1; 1 3];
     W = wishrnd(S, 10);
     % Sur beaucoup de tirages, la moyenne tend vers 10*S
     M = zeros(2); for k = 1:4000, M = M + wishrnd(S, 10); end
     M / 4000

  Voir aussi IWISHRND, MVNRND, COV, CHOL, CHI2RND.
```

## `zscore`

```
ZSCORE Centrage et réduction colonne par colonne.
```

## `ztest`

```
ZTEST Test sur la moyenne, l'écart type étant connu.
  H = ZTEST(X,M,SIGMA) teste l'hypothèse « la moyenne de X vaut M »
  quand l'écart type de la population, SIGMA, est connu — non estimé
  sur l'échantillon. H vaut 1 si l'hypothèse est rejetée au seuil de
  5 pour cent, 0 sinon.

  [H,P] = ZTEST(...) rend la probabilité critique.
  [H,P,CI] = ZTEST(...) rend l'intervalle de confiance de la moyenne.
  [H,P,CI,Z] = ZTEST(...) rend la statistique du test,

     Z = (moyenne(X) - M) / (SIGMA / racine(N))

  ZTEST(...,'Alpha',A) change le seuil.
  ZTEST(...,'Tail',T) choisit le côté testé : 'both' (défaut), 'right'
  pour l'hypothèse « la moyenne dépasse M », 'left' pour l'inverse.

  Quand SIGMA n'est pas connu — le cas ordinaire —, c'est TTEST qu'il
  faut employer : il l'estime, et paie cette estimation par une loi de
  Student au lieu d'une normale.

  Exemples :
     x = [102 100 104 99 101];
     [h, p] = ztest(x, 100, 2)         % l'ecart type est connu : 2
     ztest(x, 100, 2, 'Tail', 'right')

  Voir aussi TTEST, TTEST2, VARTEST, SIGNTEST, NORMCDF.
```

