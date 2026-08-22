# Toolbox `statistiques`

```
% Statistics and Machine Learning Toolbox — statistiques et apprentissage.
%
%   zscore, iqr, mad, skewness, kurtosis  - Statistiques descriptives
%   tabulate, crosstab                    - Tableaux d'effectifs
%   ttest, ttest2                         - Tests de Student
%   anova1                                - Analyse de variance à un facteur
%   regress, robustfit                    - Régression linéaire
%   fitlm                                 - Modèle linéaire complet
%   pca                                   - Analyse en composantes principales
%   kmeans                                - Partition en k classes
%   knnsearch, fitcknn                    - Plus proches voisins
%   fitcnb                                - Classifieur bayésien naïf
%   fitctree                              - Arbre de décision (CART)
%   linkage, cluster                      - Classification hiérarchique
%   silhouette                            - Qualité d'une partition
%   confusionmat                          - Matrice de confusion
%   cvpartition                           - Découpage en apprentissage/test
```

## `anova1`

```
ANOVA1 Analyse de variance à un facteur.
  P = ANOVA1(Y,GROUPE) teste l'égalité des moyennes des groupes.
```

## `chi2cdf`

```
CHI2CDF Répartition du khi-deux : gamma incomplète régularisée.
```

## `confusionmat`

```
CONFUSIONMAT Matrice de confusion.
  M(i,j) compte les observations de la classe i classées en j.
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

## `kurtosis`

```
KURTOSIS Coefficient d'aplatissement (3 pour une loi normale).
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

## `regress`

```
REGRESS Régression linéaire multiple par moindres carrés.
  B = REGRESS(Y,X) rend les coefficients de Y = X*B.
  [B,BINT,R,RINT,STATS] = REGRESS(...) rend aussi les intervalles de
  confiance à 95 %, les résidus, et [R2, F, p, variance résiduelle].
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

## `zscore`

```
ZSCORE Centrage et réduction colonne par colonne.
```

