# Algebre lineaire

Fonctions natives du groupe `algebre`.

## `chol`

```
CHOL  Factorisation de Cholesky.
    R = CHOL(A) rend R triangulaire supérieure telle que R'*R = A, pour A
    symétrique définie positive. Elle échoue sinon — ce qui en fait le test
    de définie-positivité.

    Syntaxe
       R = chol(A)

    Exemples
       A = [4 2; 2 3];
       R = chol(A);
       norm(R'*R - A) < 1e-12
       try
           chol([1 2; 2 1]);      % pas définie positive
       catch e
           disp('A n''est pas définie positive');
       end

    Voir aussi LU, QR, EIG, ISSYMMETRIC.
```

## `cond`

```
COND  Conditionnement d'une matrice.
    COND(A) est le rapport de la plus grande valeur singulière à la plus
    petite : il dit combien l'erreur relative sur b se retrouve amplifiée
    dans la solution de A*x = b.

    Syntaxe
       c = cond(A)

    Exemples
       cond(eye(3))               % 1 — le mieux possible
       cond(hilb(5))              % très grand : mal conditionnée

    Voir aussi RCOND, SVD, RANK, NORM.
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
       A = [4 1; 2 3];
       [V,D] = eig(A);
       max(abs(eig(0.5*A))) < 1   % stabilité d'un système discret

    Voir aussi SVD, POLY, ROOTS, EXPM.
```

## `expm`

```
EXPM  Exponentielle de matrice.
    EXPM(A) calcule e^A au sens matriciel — la somme de la série —, à ne
    pas confondre avec EXP(A), qui travaille élément par élément. C'est
    elle qui résout x' = A x.

    Syntaxe
       E = expm(A)

    Exemples
       expm(zeros(2))             % l'identité
       A = [0 1; -1 0];
       expm(A*pi)                 % -I, à l'arrondi près
       isequal(expm(diag([0 0])), exp(diag([0 0])))   % faux en général

    Voir aussi LOGM, SQRTM, EXP, EIG.
```

## `hilb`

```
HILB  Matrice de Hilbert.
    HILB(N) a pour élément (i,j) la valeur 1/(i+j-1). Célèbre pour son
    très mauvais conditionnement : c'est l'étalon des tests numériques.

    Syntaxe
       H = hilb(n)

    Exemples
       hilb(3)
       cond(hilb(5)) > 1e5                % franchement mal conditionnée

    Voir aussi COND, MAGIC, TOEPLITZ, INV.
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
       A = [2 1; 1 3];  b = [3; 5];
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
LINSOLVE  Résout A*X = B.
    LINSOLVE(A,B) résout le système ; c'est la forme explicite de
    l'opérateur « \ ».

    Syntaxe
       x = linsolve(A,B)

    Exemples
       A = [2 1; 1 3];  b = [3; 5];
       x = linsolve(A, b);
       norm(A*x - b) < 1e-12
       norm(x - (A\b)) < 1e-12

    Voir aussi MLDIVIDE, INV, LU, QR, PINV.
```

## `logm`

```
LOGM  Logarithme de matrice.
    LOGM(A) rend X tel que EXPM(X) = A.

    Syntaxe
       X = logm(A)

    Exemples
       A = expm([0 1; 0 0]);
       norm(logm(A) - [0 1; 0 0]) < 1e-10

    Voir aussi EXPM, SQRTM, LOG, EIG.
```

## `lu`

```
LU  Factorisation LU avec pivotage.
    [L,U] = LU(A) rend L (produit d'une triangulaire inférieure et d'une
    permutation) et U triangulaire supérieure, avec L*U = A.
    [L,U,P] = LU(A) rend la permutation à part : P*A = L*U.

    Syntaxe
       [L,U] = lu(A)
       [L,U,P] = lu(A)

    Exemples
       A = [4 3; 6 3];
       [L,U] = lu(A);
       norm(L*U - A) < 1e-12
       [L,U,P] = lu(A);
       norm(P*A - L*U) < 1e-12

    Voir aussi QR, CHOL, DET, MLDIVIDE, INV.
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
       A = magic(3);  B = ones(3);
       norm(A - B, 'fro')         % écart entre deux matrices
       x = A \ ones(3,1);  b = ones(3,1);
       norm(A*x - b) / norm(b)    % résidu relatif

    Voir aussi COND, RANK, SVD, HYPOT.
```

## `null`

```
NULL  Base du noyau d'une matrice.
    NULL(A) rend une base orthonormée des X tels que A*X = 0. Le noyau est
    vide quand A est de rang plein.

    Syntaxe
       Z = null(A)

    Exemples
       A = [1 2; 2 4];                    % rang 1
       Z = null(A);
       norm(A*Z) < 1e-10
       isempty(null(eye(3)))              % noyau vide

    Voir aussi ORTH, RANK, SVD, MLDIVIDE.
```

## `orth`

```
ORTH  Base orthonormée de l'image d'une matrice.
    ORTH(A) rend une base orthonormée de l'espace engendré par les
    colonnes de A ; elle a RANK(A) colonnes.

    Syntaxe
       Q = orth(A)

    Exemples
       A = [1 2; 2 4; 3 6];
       Q = orth(A);
       size(Q, 2) == rank(A)
       norm(Q'*Q - eye(size(Q,2))) < 1e-10

    Voir aussi NULL, QR, RANK, SVD.
```

## `pinv`

```
PINV  Pseudo-inverse de Moore-Penrose.
    PINV(A) rend la matrice qui donne la solution de moindre norme au sens
    des moindres carrés, y compris quand A n'est pas carrée ou est
    singulière.

    Syntaxe
       B = pinv(A)
       B = pinv(A,tol)

    Exemples
       A = [1 2; 2 4];            % singulière
       pinv(A)
       b = [1; 2];
       x = pinv(A) * b;           % solution de moindre norme

    Voir aussi INV, MLDIVIDE, SVD, RANK, LSQNONNEG.
```

## `qr`

```
QR  Factorisation QR.
    [Q,R] = QR(A) rend Q orthogonale et R triangulaire supérieure, avec
    Q*R = A. C'est la façon stable de résoudre les moindres carrés.

    Syntaxe
       [Q,R] = qr(A)

    Exemples
       A = [1 1; 1 2; 1 3];
       [Q,R] = qr(A);
       norm(Q*R - A) < 1e-12
       norm(Q'*Q - eye(size(Q,2))) < 1e-12

    Voir aussi LU, CHOL, SVD, MLDIVIDE, ORTH.
```

## `rank`

```
RANK  Rang d'une matrice.
    RANK(A) compte les valeurs singulières franchement non nulles.
    RANK(A,TOL) impose le seuil.

    Syntaxe
       r = rank(A)
       r = rank(A,tol)

    Exemples
       rank(eye(3))               % 3
       rank([1 2; 2 4])           % 1 — la seconde ligne est double
       rank(magic(4))             % 3, et non 4

    Voir aussi SVD, DET, COND, NULL, ORTH.
```

## `rcond`

```
RCOND  Estimation de l'inverse du conditionnement.
    RCOND(A) est proche de 1 pour une matrice bien conditionnée, et proche
    de 0 pour une matrice presque singulière.

    Syntaxe
       c = rcond(A)

    Exemples
       rcond(eye(3))                      % 1
       rcond([1 1; 1 1+1e-12]) < 1e-6     % presque singulière

    Voir aussi COND, DET, INV, MLDIVIDE.
```

## `rref`

```
RREF  Forme échelonnée réduite par lignes.
    RREF(A) rend la forme obtenue par élimination de Gauss-Jordan : c'est
    la méthode qu'on apprend, plus lisible que stable numériquement.
    [R,PIVOTS] = RREF(A) rend aussi les colonnes de pivot.

    Syntaxe
       R = rref(A)
       [R,pivots] = rref(A)

    Exemples
       rref([1 2; 2 4])
       [R, p] = rref(magic(4));
       numel(p) == rank(magic(4))

    Voir aussi RANK, MLDIVIDE, LU, INV.
```

## `sqrtm`

```
SQRTM  Racine carrée de matrice.
    SQRTM(A) rend X tel que X*X = A — à ne pas confondre avec SQRT(A),
    qui travaille élément par élément.

    Syntaxe
       X = sqrtm(A)

    Exemples
       A = [4 0; 0 9];
       X = sqrtm(A);
       norm(X*X - A) < 1e-10
       isequal(sqrt(A), [2 0; 0 3])       % sqrt, lui, va élément par élément

    Voir aussi EXPM, LOGM, SQRT, EIG.
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

       A = magic(4);
       s = svd(A);
       cond2 = s(1)/s(end);       % conditionnement en norme 2
       rang = sum(s > 1e-10);

    Voir aussi EIG, RANK, COND, PINV, NORM.
```

## `toeplitz`

```
TOEPLITZ  Matrice de Toeplitz : constante le long des diagonales.
    TOEPLITZ(C,R) prend C pour première colonne et R pour première ligne.
    TOEPLITZ(C) rend la matrice symétrique.

    Syntaxe
       T = toeplitz(c,r)
       T = toeplitz(c)

    Exemples
       toeplitz([1 2 3])
       toeplitz([1 2 3], [1 4 5])
       T = toeplitz([2 -1 0 0]);          % la matrice du laplacien 1D

    Voir aussi HILB, VANDER, DIAG, CONV.
```

## `trace`

```
TRACE  Somme des éléments diagonaux.
    TRACE(A) vaut SUM(DIAG(A)), et aussi la somme des valeurs propres.

    Syntaxe
       t = trace(A)

    Exemples
       trace(magic(3))
       A = [4 1; 2 3];
       abs(trace(A) - sum(eig(A))) < 1e-10

    Voir aussi DIAG, EIG, DET, RANK.
```

## `vander`

```
VANDER  Matrice de Vandermonde.
    VANDER(V) a pour colonnes les puissances décroissantes de V : c'est la
    matrice de l'interpolation polynomiale.

    Syntaxe
       A = vander(v)

    Exemples
       vander([1 2 3])
       v = [1 2 3];
       size(vander(v))                    % [3 3]

    Voir aussi POLYFIT, TOEPLITZ, HILB, POLYVAL.
```

