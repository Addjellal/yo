# Algebre lineaire

Fonctions natives du groupe `algebre`.

## `chol`

```
chol  Factorisation de Cholesky.
```

## `cond`

```
cond  Conditionnement en norme 2.
```

## `det`

```
DET  Déterminant d'une matrice carrée.
    D = DET(X) rend le déterminant, calculé par la décomposition LU.

    Tester la singularité par « det(A) == 0 » est fragile : la valeur est
    sensible à l'échelle. RANK ou COND répondent mieux.

    Syntaxe
       d = det(A)

    Exemples
       det([1 2; 3 4])            % -2
       det(eye(5))                % 1

    Voir aussi INV, RANK, COND, LU, TRACE.
```

## `eig`

```
EIG  Valeurs et vecteurs propres.
    E = EIG(A) rend le vecteur des valeurs propres de A.
    [V,D] = EIG(A) rend les vecteurs propres en colonnes de V et les
    valeurs propres sur la diagonale de D, de sorte que A*V = V*D.

    Syntaxe
       e = eig(A)
       [V,D] = eig(A)

    Exemples
       eig([2 0; 0 3])            % [2; 3]
       [V,D] = eig(A);
       max(abs(eig(A))) < 1       % stabilité d'un système discret

    Voir aussi SVD, POLY, ROOTS, EXPM.
```

## `expm`

```
expm  Exponentielle de matrice.
```

## `hilb`

```
hilb  Matrice de Hilbert.
```

## `inv`

```
INV  Inverse d'une matrice carrée.
    Y = INV(X) rend l'inverse de X. Un avertissement signale une matrice
    mal conditionnée ou singulière.

    Pour résoudre A*x = b, préférer « x = A\b » : c'est plus rapide et
    plus précis que « x = inv(A)*b ».

    Syntaxe
       Y = inv(X)

    Exemples
       inv([2 0; 0 4])            % [0.5 0; 0 0.25]
       x = A \ b;                 % plutôt que inv(A)*b

    Voir aussi MLDIVIDE, PINV, DET, RANK, COND, LU.
```

## `isdiag`

```
isdiag  Matrice diagonale ?
```

## `issymmetric`

```
issymmetric  Matrice symetrique ?
```

## `istril`

```
istril  Triangulaire inferieure ?
```

## `istriu`

```
istriu  Triangulaire superieure ?
```

## `linsolve`

```
linsolve  Resolution de systeme lineaire.
```

## `logm`

```
logm  Logarithme de matrice.
```

## `lu`

```
lu  Factorisation LU avec pivot.
```

## `norm`

```
NORM  Norme d'un vecteur ou d'une matrice.
    N = NORM(X) rend la norme 2 : la longueur euclidienne d'un vecteur,
    la plus grande valeur singulière d'une matrice.
    N = NORM(X,P) rend la norme p : 1, 2, Inf, ou 'fro' pour Frobenius.

    Syntaxe
       n = norm(v)
       n = norm(A,p)

    Exemples
       norm([3 4])                % 5
       norm(A - B, 'fro')         % écart entre deux matrices
       norm(A*x - b) / norm(b)    % résidu relatif

    Voir aussi COND, RANK, SVD, HYPOT.
```

## `null`

```
null  Base du noyau.
```

## `orth`

```
orth  Base orthonormale de l'image.
```

## `pinv`

```
pinv  Pseudo-inverse de Moore-Penrose.
```

## `qr`

```
qr  Factorisation QR de Householder.
```

## `rank`

```
RANK  Rang d'une matrice.
    K = RANK(A) rend le nombre de valeurs singulières de A qui dépassent
    une tolérance choisie d'après la précision machine et la taille.
    K = RANK(A,TOL) impose la tolérance.

    Syntaxe
       k = rank(A)
       k = rank(A,tol)

    Exemples
       rank([1 2; 2 4])           % 1 — les lignes sont proportionnelles
       rank(eye(3))               % 3

    Voir aussi SVD, DET, NULL, ORTH, COND.
```

## `rcond`

```
rcond  Estimation de l'inverse du conditionnement.
```

## `rref`

```
rref  Forme echelonnee reduite.
```

## `sqrtm`

```
sqrtm  Racine carree de matrice.
```

## `svd`

```
SVD  Décomposition en valeurs singulières.
    S = SVD(A) rend le vecteur des valeurs singulières, décroissantes.
    [U,S,V] = SVD(A) donne A = U*S*V'.
    [U,S,V] = SVD(A,'econ') rend une forme économique.

    Syntaxe
       s = svd(A)
       [U,S,V] = svd(A)
       [U,S,V] = svd(A,'econ')

    Exemples
       s = svd(A);
       cond2 = s(1)/s(end);       % conditionnement en norme 2
       rang = sum(s > 1e-10);

    Voir aussi EIG, RANK, COND, PINV, NORM.
```

## `toeplitz`

```
toeplitz  Matrice de Toeplitz.
```

## `trace`

```
trace  Somme de la diagonale.
```

## `vander`

```
vander  Matrice de Vandermonde.
```

