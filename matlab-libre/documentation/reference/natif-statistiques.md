# Statistiques

Fonctions natives du groupe `statistiques`.

## `binopdf`

```
BINOPDF  Densité de la loi binomiale.
    BINOPDF(K,N,P) rend la probabilité d'obtenir K succès en N essais de
    probabilité P.

    Syntaxe
       y = binopdf(k,n,p)

    Exemples
       binopdf(0, 3, 0.5)                 % 0.1250
       abs(sum(binopdf(0:10, 10, 0.3)) - 1) < 1e-12

    Voir aussi POISSPDF, NORMPDF, NCHOOSEK.
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
EXPCDF  Répartition de la loi exponentielle.

    Syntaxe
       p = expcdf(x,mu)

    Exemples
       abs(expcdf(2, 2) - (1 - exp(-1))) < 1e-12
       expcdf(0, 1)                       % 0

    Voir aussi EXPPDF, NORMCDF.
```

## `exppdf`

```
EXPPDF  Densité de la loi exponentielle.
    EXPPDF(X,MU) rend la densité de moyenne MU.

    Syntaxe
       y = exppdf(x,mu)

    Exemples
       abs(exppdf(0, 2) - 0.5) < 1e-12
       abs(trapz(0:0.001:60, exppdf(0:0.001:60, 2)) - 1) < 1e-3

    Voir aussi EXPCDF, POISSPDF, NORMPDF.
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
MOVMEAN  Moyenne glissante.
    MOVMEAN(X,K) rend la moyenne sur une fenêtre de K points centrée sur
    chaque élément ; aux bords, la fenêtre se raccourcit.

    Syntaxe
       y = movmean(x,k)

    Exemples
       movmean([1 2 3 4 5], 3)
       x = sin(linspace(0,2*pi,100)) + 0.3*randn(1,100);
       lisse = movmean(x, 9);
       std(lisse) < std(x)

    Voir aussi MEAN, FILTER, CONV, CUMSUM.
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
NORMRND  Tirages selon une loi normale.
    NORMRND(MU,SIGMA,M,N) rend une matrice M par N de tirages.

    Syntaxe
       x = normrnd(mu,sigma)
       x = normrnd(mu,sigma,m,n)

    Exemples
       rng(0);
       x = normrnd(10, 2, 1, 5000);
       abs(mean(x) - 10) < 0.2
       abs(std(x) - 2) < 0.2

    Voir aussi RANDN, UNIFRND, NORMPDF, RNG.
```

## `poisspdf`

```
POISSPDF  Densité de la loi de Poisson.
    POISSPDF(K,LAMBDA) rend la probabilité d'observer K événements quand
    on en attend LAMBDA.

    Syntaxe
       y = poisspdf(k,lambda)

    Exemples
       abs(poisspdf(0, 1) - exp(-1)) < 1e-12
       abs(sum(poisspdf(0:60, 3)) - 1) < 1e-10

    Voir aussi BINOPDF, EXPPDF, NORMPDF.
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
RANDSAMPLE  Tire au hasard dans une population.
    RANDSAMPLE(N,K) tire K entiers parmi 1..N, sans remise.
    RANDSAMPLE(V,K) tire K éléments de V.
    RANDSAMPLE(...,true) tire avec remise.

    Syntaxe
       y = randsample(n,k)
       y = randsample(v,k)
       y = randsample(v,k,true)

    Exemples
       rng(0);
       y = randsample(10, 3);
       numel(unique(y)) == 3              % sans remise
       randsample([10 20 30], 2);

    Voir aussi RANDPERM, RANDI, RAND, RNG.
```

## `range`

```
RANGE  Étendue : maximum moins minimum.

    Syntaxe
       r = range(x)

    Exemples
       range([3 1 4 1 5])                 % 4
       range(magic(3))                    % par colonnes

    Voir aussi MAX, MIN, STD, PRCTILE.
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
UNIFRND  Tirages selon une loi uniforme.
    UNIFRND(A,B,M,N) tire dans [A,B].

    Syntaxe
       x = unifrnd(a,b)
       x = unifrnd(a,b,m,n)

    Exemples
       rng(0);
       x = unifrnd(-1, 1, 1, 1000);
       all(x >= -1 & x <= 1)

    Voir aussi RAND, NORMRND, RANDI, RNG.
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

