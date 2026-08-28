# Tableaux, tailles et classes

Fonctions natives du groupe `base`.

## `I`

```
I  Unite imaginaire.
```

## `Inf`

```
Inf  Tableau d'infinis.
```

## `J`

```
J  Unite imaginaire.
```

## `NaN`

```
NaN  Tableau de NaN.
```

## `cast`

```
cast  Conversion vers une classe nommee.
```

## `cat`

```
CAT  Concatène des tableaux.
    C = CAT(DIM,A,B,...) concatène selon la dimension DIM.
    CAT(1,A,B) empile verticalement, comme [A;B].
    CAT(2,A,B) accole horizontalement, comme [A,B].

    Syntaxe
       C = cat(dim,A1,A2,...,An)

    Exemples
       cat(1, [1 2], [3 4])       % [1 2; 3 4]
       cat(2, [1;2], [3;4])       % [1 3; 2 4]
       cat(3, A, B)               % empile en profondeur

    Voir aussi HORZCAT, VERTCAT, RESHAPE, PERMUTE.
```

## `char`

```
char  Conversion char.
```

## `circshift`

```
circshift  Decalage circulaire.
```

## `class`

```
class  Nom de la classe d'une valeur.
```

## `colon`

```
colon  Equivalent fonctionnel de a:b:c.
```

## `complex`

```
complex  Construit un nombre complexe.
```

## `ctranspose`

```
ctranspose  Transposition conjuguee.
```

## `double`

```
double  Conversion double.
```

## `e`

```
e  2.71828182845905...
```

## `eps`

```
eps  Precision relative des flottants.
```

## `eye`

```
EYE  Matrice identité.
    EYE(N) rend la matrice identité N par N.
    EYE(M,N) rend une matrice M par N dont la diagonale vaut un.
    EYE(SIZE(A)) rend une identité de la taille de A.

    Syntaxe
       I = eye
       I = eye(n)
       I = eye(n,m)
       I = eye(___,classe)

    Exemples
       eye(3)                % identité 3x3
       A \ eye(size(A))      % une façon d'écrire inv(A)

    Voir aussi ZEROS, ONES, DIAG, INV.
```

## `false`

```
false  Tableau logique faux.
```

## `flintmax`

```
flintmax  Plus grand entier exact.
```

## `flip`

```
flip  Retourne selon une dimension.
```

## `fliplr`

```
fliplr  Retourne de gauche a droite.
```

## `flipud`

```
flipud  Retourne de haut en bas.
```

## `horzcat`

```
horzcat  Concatenation horizontale.
```

## `i`

```
i  Unite imaginaire.
```

## `ind2sub`

```
ind2sub  Index lineaire vers indices.
```

## `inf`

```
inf  Tableau d'infinis.
```

## `int16`

```
int16  Entier signe 16 bits.
```

## `int32`

```
int32  Entier signe 32 bits.
```

## `int64`

```
int64  Entier signe 64 bits.
```

## `int8`

```
int8  Entier signe 8 bits.
```

## `intmax`

```
intmax  Plus grand entier d'une classe.
```

## `intmin`

```
intmin  Plus petit entier d'une classe.
```

## `ipermute`

```
ipermute  Permutation inverse.
```

## `is_function_handle`

```
is_function_handle  Vrai pour une poignee de fonction.
```

## `isa`

```
isa  Teste l'appartenance a une classe.
```

## `iscell`

```
iscell  Vrai pour un tableau de cellules.
```

## `ischar`

```
ischar  Vrai pour un tableau de caracteres.
```

## `iscolumn`

```
iscolumn  Vrai pour un vecteur colonne.
```

## `isempty`

```
isempty  Vrai si le tableau est vide.
```

## `isequal`

```
isequal  Egalite de contenu.
```

## `isequaln`

```
isequaln  Egalite, NaN compris.
```

## `isfloat`

```
isfloat  Vrai pour double ou single.
```

## `isinteger`

```
isinteger  Vrai pour un entier machine.
```

## `islogical`

```
islogical  Vrai pour un tableau logique.
```

## `ismatrix`

```
ismatrix  Vrai pour un tableau 2-D.
```

## `isnumeric`

```
isnumeric  Vrai pour un tableau numerique.
```

## `isobject`

```
isobject  Vrai pour un objet.
```

## `isreal`

```
isreal  Vrai si aucune partie imaginaire.
```

## `isrow`

```
isrow  Vrai pour un vecteur ligne.
```

## `isscalar`

```
isscalar  Vrai pour un tableau 1x1.
```

## `isstring`

```
isstring  Vrai pour un tableau string.
```

## `isstruct`

```
isstruct  Vrai pour une structure.
```

## `isvector`

```
isvector  Vrai pour un vecteur.
```

## `j`

```
j  Unite imaginaire.
```

## `length`

```
LENGTH  Longueur du plus grand côté.
    L = LENGTH(A) rend MAX(SIZE(A)) pour un tableau non vide, et 0 pour
    un tableau vide. Pour un vecteur, c'est son nombre d'éléments.

    Syntaxe
       L = length(A)

    Exemples
       length(1:10)          % 10
       length(zeros(3,7))    % 7
       length([])            % 0

    Voir aussi NUMEL, SIZE, NDIMS.
```

## `linspace`

```
LINSPACE  Vecteur de points régulièrement espacés.
    Y = LINSPACE(A,B) rend 100 points également répartis entre A et B.
    Y = LINSPACE(A,B,N) en rend N. Les bornes A et B sont incluses.

    LINSPACE contrôle le NOMBRE de points, là où le deux-points contrôle
    le PAS : « 0:0.1:1 » et « linspace(0,1,11) » donnent le même vecteur.

    Syntaxe
       y = linspace(a,b)
       y = linspace(a,b,n)

    Exemples
       linspace(0,1,5)       % [0 0.25 0.5 0.75 1]
       linspace(0,2*pi,1000) % 1000 points sur une période

    Voir aussi LOGSPACE, COLON.
```

## `logical`

```
logical  Conversion logique.
```

## `logspace`

```
LOGSPACE  Vecteur de points espacés logarithmiquement.
    Y = LOGSPACE(A,B) rend 50 points entre 10^A et 10^B.
    Y = LOGSPACE(A,B,N) en rend N.

    Syntaxe
       y = logspace(a,b)
       y = logspace(a,b,n)

    Exemples
       logspace(0,3,4)       % [1 10 100 1000]
       f = logspace(-1,3,200);   % un axe de Bode

    Voir aussi LINSPACE, SEMILOGX.
```

## `meshgrid`

```
meshgrid  Grille cartesienne.
```

## `nan`

```
nan  Tableau de NaN.
```

## `ndgrid`

```
ndgrid  Grille en ordre tableau.
```

## `ndims`

```
ndims  Nombre de dimensions (au moins 2).
```

## `numel`

```
NUMEL  Nombre d'éléments d'un tableau.
    N = NUMEL(A) rend le nombre d'éléments de A, c'est-à-dire le produit
    de ses dimensions.

    Syntaxe
       n = numel(A)

    Exemples
       numel(zeros(2,3))     % 6
       numel('bonjour')      % 7
       numel({1,2,3})        % 3

    Voir aussi SIZE, LENGTH, NDIMS.
```

## `ones`

```
ONES  Tableau de uns.
    ONES(N) rend une matrice N par N de uns.
    ONES(M,N) rend une matrice M par N de uns.
    ONES(...,CLASSE) rend un tableau de la classe donnée.

    Syntaxe
       X = ones
       X = ones(n)
       X = ones(sz1,...,szN)
       X = ones(___,classe)

    Exemples
       ones(3)               % matrice 3x3 de uns
       5 * ones(1,4)         % vecteur [5 5 5 5]
       ones(2,2,'single')

    Voir aussi ZEROS, EYE, REPMAT.
```

## `permute`

```
permute  Permute les dimensions.
```

## `pi`

```
pi  3.14159265358979...
```

## `rand`

```
RAND  Nombres pseudo-aléatoires uniformes sur ]0,1[.
    R = RAND(N) rend une matrice N par N.
    R = RAND(M,N) rend une matrice M par N.
    R = RAND(SIZE(A)) rend un tableau de la taille de A.

    La suite est reproductible : RNG(graine) la fixe.

    Syntaxe
       X = rand
       X = rand(n)
       X = rand(sz1,...,szN)

    Exemples
       rand(3)                    % matrice 3x3
       a + (b-a)*rand(1,100)      % 100 tirages entre a et b
       rng(0); rand(1,3)          % suite reproductible

    Voir aussi RANDN, RANDI, RANDPERM, RNG.
```

## `randi`

```
randi  Entiers uniformes.
```

## `randn`

```
RANDN  Nombres pseudo-aléatoires normaux, de moyenne 0 et d'écart-type 1.
    Mêmes formes que RAND.

    Syntaxe
       X = randn(n)
       X = randn(sz1,...,szN)

    Exemples
       randn(1,1000)              % bruit blanc gaussien
       mu + sigma*randn(1,n)      % loi normale de paramètres mu, sigma

    Voir aussi RAND, RANDI, RNG.
```

## `randperm`

```
randperm  Permutation aleatoire.
```

## `realmax`

```
realmax  Plus grand flottant.
```

## `realmin`

```
realmin  Plus petit flottant normalise.
```

## `repmat`

```
REPMAT  Répète un tableau en mosaïque.
    B = REPMAT(A,M,N) fait une mosaïque de M par N copies de A.
    B = REPMAT(A,[M N P ...]) pour plus de dimensions.
    B = REPMAT(A,N) fait N par N copies.

    Syntaxe
       B = repmat(A,n)
       B = repmat(A,r1,...,rN)
       B = repmat(A,r)

    Exemples
       repmat([1 2], 2, 3)        % 2x6
       repmat(x, 1, n)            % n copies d'un vecteur colonne

    Voir aussi KRON, RESHAPE, CAT, MESHGRID.
```

## `reshape`

```
RESHAPE  Change la forme d'un tableau.
    B = RESHAPE(A,M,N) rend une matrice M par N dont les éléments sont
    ceux de A, pris colonne par colonne. Le nombre d'éléments doit être
    conservé.
    B = RESHAPE(A,M,N,P,...) ou RESHAPE(A,[M N P ...]) pour plus de
    dimensions.
    Une dimension peut valoir [] : elle est alors calculée.

    Syntaxe
       B = reshape(A,sz1,...,szN)
       B = reshape(A,sz)

    Exemples
       reshape(1:6, 2, 3)    % [1 3 5; 2 4 6]
       reshape(1:6, 2, [])   % même résultat
       reshape(A, 1, [])     % A en un vecteur ligne

    Voir aussi SIZE, PERMUTE, SQUEEZE, CIRCSHIFT.
```

## `rng`

```
RNG  Fixe ou lit l'état du générateur aléatoire.
    RNG(GRAINE) part de la graine donnée : la suite devient reproductible.
    RNG('default') revient à l'état de démarrage.
    S = RNG rend l'état courant ; RNG(S) le restaure.

    Syntaxe
       rng(graine)
       rng('default')
       s = rng;
       rng(s)

    Exemples
       rng(42); a = rand(1,3);
       rng(42); b = rand(1,3);    % b est identique à a
       s = rng; x = rand; rng(s); y = rand;   % y == x

    Voir aussi RAND, RANDN, RANDI.
```

## `rot90`

```
rot90  Rotation de 90 degres.
```

## `single`

```
single  Conversion single.
```

## `size`

```
SIZE  Dimensions d'un tableau.
    D = SIZE(A) rend un vecteur ligne dont les éléments sont les
    longueurs de A selon chaque dimension.
    [M,N] = SIZE(A) rend le nombre de lignes et de colonnes.
    M = SIZE(A,DIM) rend la longueur selon la dimension DIM.

    Un tableau a toujours au moins deux dimensions : SIZE d'un scalaire
    rend [1 1].

    Syntaxe
       sz = size(A)
       [m,n] = size(A)
       szdim = size(A,dim)

    Exemples
       size(zeros(2,3))      % [2 3]
       size(zeros(2,3), 2)   % 3
       [m,n] = size(A);

    Voir aussi NUMEL, LENGTH, NDIMS, RESHAPE.
```

## `squeeze`

```
squeeze  Retire les dimensions unitaires.
```

## `sub2ind`

```
sub2ind  Indices vers index lineaire.
```

## `transpose`

```
transpose  Transposition simple.
```

## `true`

```
true  Tableau logique vrai.
```

## `uint16`

```
uint16  Entier non signe 16 bits.
```

## `uint32`

```
uint32  Entier non signe 32 bits.
```

## `uint64`

```
uint64  Entier non signe 64 bits.
```

## `uint8`

```
uint8  Entier non signe 8 bits.
```

## `validateattributes`

```
validateattributes  Verifie des attributs (tolerant).
```

## `vertcat`

```
vertcat  Concatenation verticale.
```

## `zeros`

```
ZEROS  Tableau de zéros.
    ZEROS(N) rend une matrice N par N de zéros.
    ZEROS(M,N) rend une matrice M par N de zéros.
    ZEROS(M,N,P,...) rend un tableau M par N par P de zéros.
    ZEROS(SIZE(A)) rend un tableau de la taille de A.
    ZEROS(...,CLASSE) rend un tableau de la classe donnée : 'double',
    'single', 'int8'..'int64', 'uint8'..'uint64', 'logical'.

    Syntaxe
       X = zeros
       X = zeros(n)
       X = zeros(sz1,...,szN)
       X = zeros(sz)
       X = zeros(___,classe)

    Exemples
       zeros(2)              % matrice 2x2 de zéros
       zeros(2,3)            % matrice 2x3
       zeros(1,4,'int8')     % vecteur d'entiers 8 bits
       zeros(size(A))        % de la taille de A

    Voir aussi ONES, EYE, NAN, RAND, SIZE.
```

