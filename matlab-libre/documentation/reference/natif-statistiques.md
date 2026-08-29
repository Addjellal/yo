# Statistiques

Fonctions natives du groupe `statistiques`.

## `binopdf`

```
binopdf  Densite binomiale.
```

## `chi2pdf`

```
chi2pdf  Densite du khi-deux.
```

## `corrcoef`

```
CORRCOEF  Coefficients de corrélation.
    CORRCOEF(X,Y) rend la matrice 2x2 des corrélations : hors diagonale,
    le coefficient de Pearson, entre -1 et 1.

    Syntaxe
       R = corrcoef(x,y)
       R = corrcoef(X)

    Exemples
       x = 1:100;
       R = corrcoef(x, 2*x + 1);
       abs(R(1,2) - 1) < 1e-10        % corrélation parfaite
       R2 = corrcoef(x, -x);
       abs(R2(1,2) + 1) < 1e-10

    Voir aussi COV, POLYFIT, VAR.
```

## `cov`

```
COV  Covariance.
    COV(X) rend la variance d'un vecteur, ou la matrice de covariance des
    colonnes d'une matrice.
    COV(X,Y) rend la matrice 2x2 de deux vecteurs.

    Syntaxe
       C = cov(x)
       C = cov(x,y)

    Exemples
       x = randn(1,500);  y = 2*x + randn(1,500);
       C = cov(x, y);
       size(C)                        % [2 2]
       abs(C(1,1) - var(x)) < 1e-10

    Voir aussi CORRCOEF, VAR, STD, MEAN.
```

## `expcdf`

```
expcdf  Repartition exponentielle.
```

## `exppdf`

```
exppdf  Densite exponentielle.
```

## `histcounts`

```
HISTCOUNTS  Compte les valeurs par classe.
    [N,BORDS] = HISTCOUNTS(X) répartit X en classes choisies
    automatiquement.
    N = HISTCOUNTS(X,BORDS) compte selon les bords donnés : une valeur
    tombe dans la classe k si BORDS(k) <= x < BORDS(k+1).

    Syntaxe
       n = histcounts(x)
       [n,bords] = histcounts(x)
       n = histcounts(x,bords)

    Exemples
       histcounts([1 2 2 3], [1 2 3 4])       % [1 2 1]
       [n, bords] = histcounts(randn(1,1000));
       sum(n)                                 % 1000

    Voir aussi HISTOGRAM, ACCUMARRAY, MODE, BAR.
```

## `mean`

```
MEAN  Moyenne arithmétique.
    MEAN(X) rend la moyenne d'un vecteur, ou la moyenne de chaque colonne
    d'une matrice.
    MEAN(X,DIM) travaille selon la dimension DIM.

    Syntaxe
       m = mean(x)
       m = mean(x,dim)

    Exemples
       mean([1 2 3 4])                % 2.5000
       mean([1 2; 3 4])               % [2 3] — par colonnes
       mean([1 2; 3 4], 2)            % [1.5; 3.5]
       A = magic(4);
       mean(A(:))                     % moyenne de tout

    Voir aussi MEDIAN, MODE, STD, VAR, SUM.
```

## `median`

```
MEDIAN  Médiane : la valeur du milieu.
    MEDIAN(X) rend la médiane, insensible aux valeurs extrêmes — c'est ce
    qui la distingue de la moyenne.

    Syntaxe
       m = median(x)
       m = median(x,dim)

    Exemples
       median([1 2 3 4 100])          % 3
       mean([1 2 3 4 100])            % 22 — une valeur aberrante suffit
       median([1 2; 3 4])

    Voir aussi MEAN, MODE, PRCTILE, QUANTILE, SORT.
```

## `mode`

```
MODE  Valeur la plus fréquente.
    MODE(X) rend la valeur qui revient le plus souvent ; à égalité, la
    plus petite.

    Syntaxe
       m = mode(x)

    Exemples
       mode([1 2 2 3 3 3])            % 3
       mode([1 1 2 2])                % 1 — la plus petite à égalité

    Voir aussi MEDIAN, MEAN, HISTCOUNTS, UNIQUE.
```

## `movmean`

```
movmean  Moyenne glissante.
```

## `normalize`

```
NORMALIZE  Normalise des données.
    NORMALIZE(X) centre et réduit : moyenne nulle, écart-type 1.
    NORMALIZE(X,'range') ramène dans [0,1].

    Syntaxe
       y = normalize(x)
       y = normalize(x,'range')

    Exemples
       y = normalize([1 2 3 4 5]);
       abs(mean(y)) < 1e-12
       z = normalize([1 2 3], 'range');
       [min(z) max(z)]                % [0 1]

    Voir aussi MEAN, STD, RESCALE, ZSCORE.
```

## `normcdf`

```
NORMCDF  Fonction de répartition de la loi normale.
    NORMCDF(X) rend la probabilité qu'une normale centrée réduite soit
    inférieure à X.

    Syntaxe
       p = normcdf(x)
       p = normcdf(x,mu,sigma)

    Exemples
       abs(normcdf(0) - 0.5) < 1e-12
       abs(normcdf(1.96) - 0.975) < 1e-3

    Voir aussi NORMPDF, NORMINV, ERF.
```

## `norminv`

```
NORMINV  Quantiles de la loi normale.
    NORMINV(P) rend la valeur x telle que NORMCDF(x) = P.

    Syntaxe
       x = norminv(p)
       x = norminv(p,mu,sigma)

    Exemples
       abs(norminv(0.975) - 1.96) < 1e-3
       abs(norminv(normcdf(0.7)) - 0.7) < 1e-10

    Voir aussi NORMCDF, NORMPDF, PRCTILE.
```

## `normpdf`

```
NORMPDF  Densité de la loi normale.
    NORMPDF(X) est la densité de la loi normale centrée réduite.
    NORMPDF(X,MU,SIGMA) celle de la loi de moyenne MU et d'écart-type SIGMA.

    Syntaxe
       y = normpdf(x)
       y = normpdf(x,mu,sigma)

    Exemples
       abs(normpdf(0) - 1/sqrt(2*pi)) < 1e-12
       x = -4:0.1:4;
       plot(x, normpdf(x));

    Voir aussi NORMCDF, NORMINV, NORMRND, RANDN.
```

## `normrnd`

```
normrnd  Tirage normal.
```

## `poisspdf`

```
poisspdf  Densite de Poisson.
```

## `prctile`

```
PRCTILE  Centiles d'un échantillon.
    PRCTILE(X,P) rend le centile d'ordre P, P étant entre 0 et 100.

    Syntaxe
       y = prctile(x,p)

    Exemples
       prctile(1:100, 50)             % la médiane
       prctile(1:100, [25 75])        % les quartiles
       x = randn(1,10000);
       ecart = prctile(x,75) - prctile(x,25);

    Voir aussi QUANTILE, MEDIAN, SORT, HISTCOUNTS.
```

## `quantile`

```
QUANTILE  Quantiles d'un échantillon.
    QUANTILE(X,P) rend le quantile d'ordre P, P étant entre 0 et 1 — c'est
    PRCTILE avec une autre échelle.

    Syntaxe
       y = quantile(x,p)

    Exemples
       quantile(1:100, 0.5)
       quantile(1:100, [0.25 0.75])

    Voir aussi PRCTILE, MEDIAN, SORT.
```

## `randsample`

```
randsample  Tirage dans un ensemble.
```

## `range`

```
range  Etendue.
```

## `std`

```
STD  Écart-type.
    STD(X) rend l'écart-type estimé, normalisé par N-1.
    STD(X,1) normalise par N — l'écart-type de la population.

    Syntaxe
       s = std(x)
       s = std(x,1)
       s = std(x,w,dim)

    Exemples
       std([2 4 4 4 5 5 7 9])         % 2.1381
       std([2 4 4 4 5 5 7 9], 1)      % 2
       std(randn(1,10000)) - 1        % proche de zéro

    Voir aussi VAR, MEAN, MEDIAN, NORMALIZE.
```

## `tpdf`

```
tpdf  Densite de Student.
```

## `unifrnd`

```
unifrnd  Tirage uniforme.
```

## `var`

```
VAR  Variance.
    VAR(X) rend la variance estimée, normalisée par N-1.
    VAR(X,1) normalise par N.

    Syntaxe
       v = var(x)
       v = var(x,1)

    Exemples
       var([1 2 3 4])                 % 1.6667
       abs(var([1 2 3 4]) - std([1 2 3 4])^2) < 1e-12

    Voir aussi STD, MEAN, COV.
```

