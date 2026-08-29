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
linsolve  Resolution de systeme lineaire.
```

## `logm`

```
logm  Logarithme de matrice.
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
null  Base du noyau.
```

## `orth`

```
orth  Base orthonormale de l'image.
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

       A = magic(4);
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
vander  Matrice de Vandermonde.
```

