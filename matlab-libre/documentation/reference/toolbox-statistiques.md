# Toolbox `statistiques`

```
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
```

## `anova1`

```
ANOVA1 Analyse de variance à un facteur.
  P = ANOVA1(Y,GROUPE) teste l'égalité des moyennes des groupes.
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

## `bootstrp`

```
BOOTSTRP Rééchantillonnage bootstrap.
  S = BOOTSTRP(N,F,DONNEES) tire N échantillons avec remise dans les
  données et applique F à chacun. Chaque ligne de S est un tirage.

  Exemple :
     s = bootstrp(100, @mean, randn(50, 1));
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

## `confusionmat`

```
CONFUSIONMAT Matrice de confusion.
  M(i,j) compte les observations de la classe i classées en j.
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
  Le maximum de vraisemblance est la moyenne empirique.
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

## `kurtosis`

```
KURTOSIS Coefficient d'aplatissement (3 pour une loi normale).
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

## `mad`

```
MAD Écart absolu moyen, ou médian si le second argument vaut 1.
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

## `normfit`

```
NORMFIT Estimation des paramètres d'une loi normale.
  La moyenne est l'estimateur du maximum de vraisemblance ; l'écart
  type est l'estimateur sans biais, en n-1, comme dans MATLAB.
```

## `normlike`

```
NORMLIKE Opposé de la log-vraisemblance d'une loi normale.
  PARAMS vaut [MU SIGMA].
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

## `pdf`

```
PDF Densité ou probabilité d'une loi nommée.
  Y = PDF('name', X, A, B, C) appelle la fonction de densité de la loi
  nommée. Les noms suivent MATLAB : 'Normal', 'Poisson', 'Weibull',
  'Chisquare', 'Discrete Uniform'…, avec leurs abréviations.

  Exemple :  pdf('Normal', 0, 0, 1)   % 0.3989
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
  Le maximum de vraisemblance est la moyenne empirique.
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

## `predictknn`

```
PREDICTKNN Prédiction d'un classifieur k plus proches voisins.
```

## `predicttree`

```
PREDICTTREE Prédiction d'un arbre construit par FITCTREE.
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

## `regress`

```
REGRESS Régression linéaire multiple par moindres carrés.
  B = REGRESS(Y,X) rend les coefficients de Y = X*B.
  [B,BINT,R,RINT,STATS] = REGRESS(...) rend aussi les intervalles de
  confiance à 95 %, les résidus, et [R2, F, p, variance résiduelle].
```

## `signrank`

```
SIGNRANK Test des rangs signés de Wilcoxon, sur échantillons appariés.
  P = SIGNRANK(X) teste la médiane nulle ; SIGNRANK(X,Y) teste la
  médiane de X-Y.
```

## `silhouette`

```
SILHOUETTE Indice de silhouette de chaque observation.
```

## `skewness`

```
SKEWNESS Coefficient d'asymétrie (moment d'ordre trois normalisé).
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

## `tinv`

```
TINV Quantile de la loi de Student, par dichotomie sur TCDF.
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

## `zscore`

```
ZSCORE Centrage et réduction colonne par colonne.
```

