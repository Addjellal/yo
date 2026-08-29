# creux

Fonctions natives du groupe `creux`.

## `full`

```
FULL  Convertit une matrice creuse en matrice pleine.

    Syntaxe
       A = full(S)

    Exemples
       S = speye(3);
       full(S)
       issparse(full(S))                  % 0

    Voir aussi SPARSE, ISSPARSE, NNZ.
```

## `issparse`

```
ISSPARSE  La matrice est-elle creuse.

    Syntaxe
       tf = issparse(S)

    Exemples
       issparse(speye(3))                 % 1
       issparse(eye(3))                   % 0

    Voir aussi SPARSE, FULL, NNZ.
```

## `nnz`

```
NNZ  Nombre d'éléments non nuls.

    Syntaxe
       n = nnz(x)

    Exemples
       nnz([0 1 0 2])                         % 2
       nnz(eye(4))                            % 4
       nnz(magic(4) > 8)                      % combien dépassent 8

    Voir aussi FIND, NONZEROS, ANY, SUM, SPARSE.
```

## `nonzeros`

```
NONZEROS  Les éléments non nuls, en colonne.

    Syntaxe
       v = nonzeros(x)

    Exemples
       nonzeros([0 1 0 2])                    % [1; 2]
       A = eye(3);
       numel(nonzeros(A))                     % 3

    Voir aussi NNZ, FIND, SPARSE.
```

## `nzmax`

```
NZMAX  Place réservée aux non-nuls d'une matrice creuse.

    Syntaxe
       n = nzmax(S)

    Exemples
       S = sparse([1 2], [1 2], [3 4]);
       nzmax(S) >= nnz(S)

    Voir aussi NNZ, SPARSE, SPALLOC.
```

## `spalloc`

```
SPALLOC  Matrice creuse vide, avec de la place réservée.
    SPALLOC(M,N,NZ) crée une matrice M par N vide, en réservant la place
    de NZ non-nuls : remplir devient moins coûteux.

    Syntaxe
       S = spalloc(m,n,nz)

    Exemples
       S = spalloc(100, 100, 300);
       nnz(S)                             % 0 pour l'instant
       S(1,1) = 5;
       nnz(S)                             % 1

    Voir aussi SPARSE, NZMAX, SPEYE.
```

## `sparse`

```
SPARSE  Matrice creuse : seuls les non-nuls sont rangés.
    SPARSE(A) convertit une matrice pleine.
    SPARSE(I,J,V,M,N) construit une matrice M par N dont l'élément
    (I(k),J(k)) vaut V(k).

    Une matrice creuse d'un million de lignes tient en mémoire tant qu'elle
    a peu de non-nuls, et les opérations n'en parcourent que ceux-là.

    Syntaxe
       S = sparse(A)
       S = sparse(i,j,v,m,n)

    Exemples
       S = sparse([1 3], [2 3], [5 7], 3, 3);
       full(S)
       nnz(S)                             % 2
       issparse(S)

    Voir aussi FULL, SPEYE, SPDIAGS, NNZ, ISSPARSE, SPY.
```

## `spdiags`

```
SPDIAGS  Matrice creuse construite par diagonales.
    SPDIAGS(B,D,M,N) place les colonnes de B sur les diagonales D d'une
    matrice M par N.

    Syntaxe
       S = spdiags(B,d,m,n)

    Exemples
       n = 5;
       e = ones(n,1);
       L = spdiags([e -2*e e], [-1 0 1], n, n);   % le laplacien 1D
       full(L(1:3,1:3))

    Voir aussi SPARSE, DIAG, SPEYE, FULL.
```

## `speye`

```
SPEYE  Identité creuse.
    SPEYE(N) rend l'identité N par N sous forme creuse : N valeurs rangées
    au lieu de N².

    Syntaxe
       S = speye(n)
       S = speye(m,n)

    Exemples
       S = speye(4);
       nnz(S)                             % 4
       isequal(full(speye(3)), eye(3))

    Voir aussi SPARSE, EYE, SPDIAGS, SPONES.
```

## `spones`

```
SPONES  Remplace les non-nuls par des uns.
    SPONES(S) garde la structure de S et met 1 partout où elle n'est pas
    nulle : c'est le motif d'occupation.

    Syntaxe
       R = spones(S)

    Exemples
       S = sparse([1 2],[1 2],[3 4]);
       full(spones(S))
       nnz(spones(S)) == nnz(S)

    Voir aussi SPARSE, NNZ, SPY, FULL.
```

## `sprand`

```
SPRAND  Matrice creuse aléatoire, uniforme.
    SPRAND(M,N,DENSITE) rend une matrice M par N dont environ
    DENSITE*M*N éléments sont non nuls.

    Syntaxe
       S = sprand(m,n,densite)

    Exemples
       rng(0);
       S = sprand(50, 50, 0.05);
       issparse(S)
       nnz(S) < 50*50

    Voir aussi SPRANDN, SPARSE, RAND, SPY.
```

## `sprandn`

```
SPRANDN  Matrice creuse aléatoire, normale.

    Syntaxe
       S = sprandn(m,n,densite)

    Exemples
       rng(0);
       S = sprandn(20, 20, 0.1);
       issparse(S)

    Voir aussi SPRAND, SPARSE, RANDN.
```

## `spy`

```
SPY  Dessine la structure des non-nuls.
    SPY(S) place un point à chaque non-nul : la forme de la matrice se lit
    d'un coup d'oeil.

    Syntaxe
       spy(S)

    Exemples
       n = 20;
       e = ones(n,1);
       L = spdiags([e -2*e e], [-1 0 1], n, n);
       spy(L);

    Voir aussi SPARSE, NNZ, IMAGESC, PLOT.
```

