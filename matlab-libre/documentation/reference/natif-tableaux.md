# Reductions et manipulations

Fonctions natives du groupe `tableaux`.

## `accumarray`

```
accumarray  Accumulation par indice.
```

## `all`

```
ALL  Vrai si tous les éléments sont vrais.
    Mêmes formes que ANY.

    Syntaxe
       B = all(A)
       B = all(A,dim)
       B = all(A,'all')

    Exemples
       all([1 1 0])               % 0
       if all(size(A) == size(B)), ... end

    Voir aussi ANY, FIND.
```

## `any`

```
ANY  Vrai si un élément au moins est vrai.
    B = ANY(A) rend vrai s'il existe un élément non nul. Sur une matrice,
    travaille par colonnes.
    B = ANY(A,DIM) travaille selon la dimension DIM.
    B = ANY(A,'all') sur tout le tableau.

    Syntaxe
       B = any(A)
       B = any(A,dim)
       B = any(A,'all')

    Exemples
       any([0 0 1])               % 1
       if any(isnan(x)), ... end
       any(A(:) < 0)              % un négatif quelque part ?

    Voir aussi ALL, FIND, XOR.
```

## `cross`

```
cross  Produit vectoriel.
```

## `cummax`

```
cummax  Maximum cumule.
```

## `cummin`

```
cummin  Minimum cumule.
```

## `cumprod`

```
cumprod  Produit cumule.
```

## `cumsum`

```
CUMSUM  Somme cumulée.
    B = CUMSUM(A) rend les sommes partielles : B(k) est la somme des k
    premiers éléments. Sur une matrice, travaille par colonnes.
    B = CUMSUM(A,DIM) selon la dimension DIM.

    Syntaxe
       B = cumsum(A)
       B = cumsum(A,dim)

    Exemples
       cumsum([1 2 3 4])              % [1 3 6 10]
       aire = cumsum(y) * pas;        % intégration rectangulaire

    Voir aussi SUM, CUMPROD, DIFF, TRAPZ.
```

## `cumtrapz`

```
cumtrapz  Integration cumulee.
```

## `diag`

```
diag  Diagonale ou matrice diagonale.
```

## `diff`

```
DIFF  Différences entre éléments voisins.
    Y = DIFF(X) rend X(2:end) - X(1:end-1) : un élément de moins que X.
    Y = DIFF(X,N) applique DIFF N fois.
    Y = DIFF(X,N,DIM) selon la dimension DIM.

    Syntaxe
       Y = diff(X)
       Y = diff(X,n)
       Y = diff(X,n,dim)

    Exemples
       diff([1 4 9 16])               % [3 5 7]
       pente = diff(y) ./ diff(x);    % dérivée approchée
       if all(diff(x) > 0), ... end   % x est-il croissant ?

    Voir aussi CUMSUM, GRADIENT, SORT, ISSORTED.
```

## `dot`

```
dot  Produit scalaire.
```

## `find`

```
FIND  Indices des éléments non nuls.
    I = FIND(X) rend les indices linéaires des éléments non nuls de X.
    I = FIND(X,K) rend les K premiers.
    I = FIND(X,K,'last') rend les K derniers.
    [R,C] = FIND(X) rend les indices de ligne et de colonne.
    [R,C,V] = FIND(X) rend en plus les valeurs.

    FIND s'emploie surtout sur un test : FIND(A > 3).

    Syntaxe
       k = find(X)
       k = find(X,n)
       k = find(X,n,direction)
       [row,col] = find(___)

    Exemples
       find([0 3 0 7])            % [2 4]
       find(A > 5)                % où A dépasse 5
       A(find(A < 0)) = 0;        % ou plus simplement A(A < 0) = 0

    Voir aussi ANY, ALL, NNZ, LOGICAL.
```

## `histc`

```
histc  Comptage par intervalles.
```

## `intersect`

```
intersect  Intersection.
```

## `ismember`

```
ISMEMBER  Test d'appartenance.
    TF = ISMEMBER(A,S) rend un tableau logique de la taille de A, vrai
    là où l'élément se trouve dans S.
    [TF,LOC] = ISMEMBER(A,S) rend en plus l'indice dans S, ou 0.
    ISMEMBER(A,S,'rows') travaille sur les lignes.

    Syntaxe
       tf = ismember(A,S)
       [tf,loc] = ismember(A,S)

    Exemples
       ismember(3, [1 2 3])           % 1
       ismember([1 5], [1 2 3])       % [1 0]
       x(ismember(x, aRetirer)) = [];

    Voir aussi UNIQUE, INTERSECT, SETDIFF, ANY, CONTAINS.
```

## `kron`

```
kron  Produit de Kronecker.
```

## `magic`

```
magic  Carre magique d'ordre n.
```

## `max`

```
MAX  Plus grand élément.
    M = MAX(A) rend le plus grand élément d'un vecteur, ou le plus grand
    de chaque colonne d'une matrice.
    [M,I] = MAX(A) rend en plus l'indice où il se trouve.
    C = MAX(A,B) compare A et B terme à terme.
    M = MAX(A,[],DIM) travaille selon la dimension DIM.

    Les NaN sont ignorés. Pour un complexe, MAX compare les modules.

    Syntaxe
       M = max(A)
       [M,I] = max(A)
       C = max(A,B)
       M = max(A,[],dim)
       M = max(A,[],'all')

    Exemples
       max([3 1 4 1 5])      % 5
       [m,i] = max([3 1 4]); % m = 4, i = 3
       max([1 2], [3 0])     % [3 2]

    Voir aussi MIN, SORT, BOUNDS, CUMMAX.
```

## `min`

```
MIN  Plus petit élément.
    Mêmes formes que MAX, pour le minimum.

    Syntaxe
       M = min(A)
       [M,I] = min(A)
       C = min(A,B)
       M = min(A,[],dim)

    Exemples
       min([3 1 4 1 5])      % 1
       [m,i] = min([3 1 4]); % m = 1, i = 2

    Voir aussi MAX, SORT, BOUNDS.
```

## `prod`

```
PROD  Produit des éléments.
    P = PROD(A) multiplie les colonnes d'une matrice, ou les éléments
    d'un vecteur.
    P = PROD(A,DIM) multiplie selon la dimension DIM.

    Syntaxe
       P = prod(A)
       P = prod(A,dim)

    Exemples
       prod([1 2 3 4])       % 24
       prod([1 2; 3 4])      % [3 8]

    Voir aussi SUM, CUMPROD, FACTORIAL.
```

## `setdiff`

```
setdiff  Difference ensembliste.
```

## `sort`

```
SORT  Trie dans l'ordre croissant.
    B = SORT(A) trie les colonnes d'une matrice, ou les éléments d'un
    vecteur, dans l'ordre croissant.
    B = SORT(A,'descend') trie dans l'ordre décroissant.
    [B,I] = SORT(A) rend en plus la permutation : B = A(I).
    B = SORT(A,DIM) trie selon la dimension DIM.

    Les NaN sont placés en fin. Un complexe est trié par module, puis
    par argument.

    Syntaxe
       B = sort(A)
       B = sort(A,direction)
       B = sort(A,dim,direction)
       [B,I] = sort(___)

    Exemples
       sort([3 1 2])              % [1 2 3]
       sort([3 1 2], 'descend')   % [3 2 1]
       [~,i] = sort(cle);         % trier autre chose par la même clé
       tableau = tableau(i,:);

    Voir aussi SORTROWS, UNIQUE, MAX, MIN, ISSORTED.
```

## `sortrows`

```
sortrows  Tri des lignes d'une matrice.
```

## `sum`

```
SUM  Somme des éléments.
    S = SUM(A) somme les colonnes d'une matrice, ou les éléments d'un
    vecteur.
    S = SUM(A,DIM) somme selon la dimension DIM.
    S = SUM(...,'omitnan') ignore les NaN.

    Syntaxe
       S = sum(A)
       S = sum(A,dim)
       S = sum(A,'all')
       S = sum(___,'omitnan')

    Exemples
       sum([1 2 3])          % 6
       sum([1 2; 3 4])       % [4 6]   — par colonnes
       sum([1 2; 3 4], 2)    % [3; 7]  — par lignes
       sum(A(:))             % somme de tout

    Voir aussi PROD, CUMSUM, MEAN, MAX, MIN.
```

## `trapz`

```
trapz  Integration par trapezes.
```

## `tril`

```
tril  Partie triangulaire inferieure.
```

## `triu`

```
triu  Partie triangulaire superieure.
```

## `union`

```
union  Reunion de deux ensembles.
```

## `unique`

```
UNIQUE  Valeurs distinctes, triées.
    C = UNIQUE(A) rend les valeurs distinctes de A, dans l'ordre
    croissant et sans répétition.
    [C,IA,IC] = UNIQUE(A) rend en plus les indices tels que
    C = A(IA) et A = C(IC).
    C = UNIQUE(A,'stable') garde l'ordre d'apparition.
    C = UNIQUE(A,'rows') travaille sur les lignes d'une matrice.

    Syntaxe
       C = unique(A)
       C = unique(A,'stable')
       C = unique(A,'rows')
       [C,ia,ic] = unique(___)

    Exemples
       unique([3 1 3 2])              % [1 2 3]
       unique([3 1 3 2], 'stable')    % [3 1 2]
       [c,~,ic] = unique(etiquettes);
       comptes = accumarray(ic, 1);   % combien de fois chacune

    Voir aussi SORT, ISMEMBER, INTERSECT, UNION, HISTCOUNTS.
```

