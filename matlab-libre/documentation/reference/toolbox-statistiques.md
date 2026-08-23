# Toolbox `statistiques`

```
% Statistics and Machine Learning Toolbox — statistiques et apprentissage.
%
% Lois de probabilité
%   normpdf, normcdf, norminv          - Loi normale (natives)
%   betapdf, betacdf                   - Loi bêta
%   gampdf, gamcdf                     - Loi gamma
%   chi2pdf, chi2cdf, chi2inv          - Khi-deux
%   tcdf, tinv                         - Student
%   fpdf, fcdf, finv                   - Fisher
%   unifpdf, unifcdf                   - Uniforme continue
%   raylpdf, raylcdf                   - Rayleigh
%   wblpdf, wblcdf                     - Weibull
%   lognpdf, logncdf                   - Log-normale
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

## `betapdf`

```
BETAPDF Densité de la loi bêta.
  Y = BETAPDF(X,A,B) = x^(a-1)*(1-x)^(b-1)/B(a,b) sur [0,1], nulle
  ailleurs.

  Exemple :  betapdf(0.5, 1, 1)   % 1 : la loi uniforme
```

## `bootstrp`

```
BOOTSTRP Rééchantillonnage bootstrap.
  S = BOOTSTRP(N,F,DONNEES) tire N échantillons avec remise dans les
  données et applique F à chacun. Chaque ligne de S est un tirage.

  Exemple :
     s = bootstrp(100, @mean, randn(50, 1));
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

## `chi2pdf`

```
CHI2PDF Densité du khi-deux à V degrés de liberté.
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

## `gamcdf`

```
GAMCDF Répartition de la loi gamma : la gamma incomplète régularisée.
```

## `gampdf`

```
GAMPDF Densité de la loi gamma, de forme A et d'échelle B.
  Exemple :  gampdf(1, 1, 1)   % exp(-1), la loi exponentielle
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

## `lognpdf`

```
LOGNPDF Densité de la loi log-normale.
  MU et SIGMA sont la moyenne et l'écart-type du logarithme.
```

## `mad`

```
MAD Écart absolu moyen, ou médian si le second argument vaut 1.
```

## `pca`

```
PCA Analyse en composantes principales.
  [C,S,L] = PCA(X) centre les colonnes de X, puis rend les vecteurs
  propres de la covariance (C), les coordonnées des individus (S) et les
  valeurs propres (L), triés par variance décroissante.
```

## `predictknn`

```
PREDICTKNN Prédiction d'un classifieur k plus proches voisins.
```

## `predicttree`

```
PREDICTTREE Prédiction d'un arbre construit par FITCTREE.
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

## `raylpdf`

```
RAYLPDF Densité de la loi de Rayleigh de paramètre B.
  Y = X/B^2 * exp(-X^2/(2*B^2)) pour X >= 0.
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

## `unifcdf`

```
UNIFCDF Répartition de la loi uniforme continue sur [A,B].
```

## `unifpdf`

```
UNIFPDF Densité de la loi uniforme continue sur [A,B].
```

## `wblcdf`

```
WBLCDF Répartition de la loi de Weibull.
```

## `wblpdf`

```
WBLPDF Densité de la loi de Weibull, d'échelle A et de forme B.
  Exemple :  wblpdf(1, 1, 1)   % exp(-1)
```

## `zscore`

```
ZSCORE Centrage et réduction colonne par colonne.
```

