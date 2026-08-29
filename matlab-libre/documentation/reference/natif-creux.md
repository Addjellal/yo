# creux

Fonctions natives du groupe `creux`.

## `full`

```
full  Matrice pleine correspondante.
```

## `issparse`

```
issparse  Le stockage est-il creux.
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
nzmax  Place reservee aux non-nuls.
```

## `spalloc`

```
spalloc  Matrice creuse vide.
```

## `sparse`

```
sparse  Matrice creuse.
  S = sparse(A) comprime une matrice pleine.
  S = sparse(m,n) cree une matrice creuse de zeros.
  S = sparse(i,j,v,m,n) construit depuis des triplets ; les
  doublons s'additionnent.
```

## `spdiags`

```
spdiags  Matrice creuse par diagonales.
```

## `speye`

```
speye  Identite creuse.
```

## `spones`

```
spones  Motif de non-nuls, valeurs a 1.
```

## `sprand`

```
sprand  Matrice creuse uniforme.
```

## `sprandn`

```
sprandn  Matrice creuse normale.
```

## `spy`

```
spy  Trace le motif des non-nuls.
```

