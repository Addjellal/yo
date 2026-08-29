# Tableaux, tailles et classes

Fonctions natives du groupe `base`.

## `I`

```
I  L'unité imaginaire, en majuscule ; synonyme de i.

    Syntaxe
       I

    Exemples
       I^2                                % -1
       isequal(I, 1i)

    Voir aussi I, J, COMPLEX, ABS.
```

## `Inf`

```
INF  L'infini de la virgule flottante.
    INF rend +∞. INF(N) rend une matrice N par N d'infinis.
    -INF est l'infini négatif. 1/0 vaut Inf, et non une erreur.

    Syntaxe
       Inf
       Inf(n)
       Inf(m,n)

    Exemples
       1/0                        % Inf
       -1/0                       % -Inf
       isinf([1 Inf -Inf])        % [0 1 1]
       min([3 1 4])               % démarrer une recherche depuis Inf

    Voir aussi NAN, ISINF, ISFINITE, REALMAX.
```

## `J`

```
J  L'unité imaginaire, en majuscule ; synonyme de j.

    Syntaxe
       J

    Exemples
       J^2                                % -1
       isequal(J, 1j)

    Voir aussi J, I, COMPLEX, ABS.
```

## `NaN`

```
NAN  « Not a Number » : le résultat d'une opération indéterminée.
    NAN rend NaN. NAN(N) rend une matrice N par N de NaN.
    0/0 et Inf-Inf valent NaN. NaN n'est égal à rien, pas même à lui-même :
    on le teste avec ISNAN.

    Syntaxe
       NaN
       NaN(n)
       NaN(m,n)

    Exemples
       0/0                        % NaN
       NaN == NaN                 % 0 — jamais égal
       isnan([1 NaN 3])           % [0 1 0]
       x = [1 NaN 3];
       mean(x(~isnan(x)))         % moyenne en ignorant les trous

    Voir aussi ISNAN, INF, ISFINITE.
```

## `cast`

```
CAST  Convertit dans la classe d'un autre tableau.
    CAST(X,'nom') convertit X dans la classe nommée.
    CAST(X,'like',Y) convertit X dans la classe de Y.

    Syntaxe
       y = cast(x,'nom')
       y = cast(x,'like',y)

    Exemples
       cast(3.7,'int8')           % 4
       cast(300,'uint8')          % 255 — la saturation, pas le débordement
       y = single(1);
       class(cast(pi,'like',y))   % 'single'

    Voir aussi DOUBLE, SINGLE, INT8, CLASS.
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
       A = magic(3);  B = ones(3);
       cat(3, A, B)               % empile en profondeur

    Voir aussi HORZCAT, VERTCAT, RESHAPE, PERMUTE.
```

## `char`

```
CHAR  Convertit en tableau de caractères.
    CHAR(X) sur des nombres rend les caractères de ces codes.
    CHAR(S1,S2,...) empile les textes en lignes, complétées d'espaces.

    Syntaxe
       s = char(x)
       s = char(s1,s2,...)

    Exemples
       char(72)                   % 'H'
       char([72 101 108 108 111]) % 'Hello'
       char('un','deux')          % deux lignes, complétées d'espaces
       double('a':'e')

    Voir aussi DOUBLE, STRING, CELLSTR, BLANKS.
```

## `circshift`

```
CIRCSHIFT  Décale circulairement les éléments.
    CIRCSHIFT(A,K) décale de K, ce qui sort d'un côté rentrant de l'autre.
    CIRCSHIFT(A,K,DIM) décale selon la dimension DIM.

    Syntaxe
       B = circshift(A,k)
       B = circshift(A,k,dim)

    Exemples
       circshift([1 2 3 4], 1)        % [4 1 2 3]
       circshift([1 2 3 4], -1)       % [2 3 4 1]
       circshift(magic(3), 1, 2)      % décale les colonnes

    Voir aussi FLIP, ROT90, FFTSHIFT, PERMUTE.
```

## `class`

```
CLASS  Nom de la classe d'une valeur.
    CLASS(X) rend le nom de la classe de X : 'double', 'single', 'char',
    'logical', 'cell', 'struct', 'function_handle', 'int8'..'uint64'.

    Syntaxe
       c = class(x)

    Exemples
       class(1)                   % 'double'
       class('a')                 % 'char'
       class({1,2})               % 'cell'
       class(int8(1))             % 'int8'
       class(@sin)                % 'function_handle'

    Voir aussi ISA, ISNUMERIC, ISCHAR, ISCELL, ISSTRUCT.
```

## `colon`

```
COLON  L'opérateur « : », sous forme de fonction.
    COLON(A,B) vaut A:B ; COLON(A,PAS,B) vaut A:PAS:B.

    Syntaxe
       v = colon(a,b)
       v = colon(a,pas,b)

    Exemples
       colon(1,5)                     % [1 2 3 4 5]
       colon(0,2,10)                  % [0 2 4 6 8 10]
       isequal(colon(1,5), 1:5)

    Voir aussi LINSPACE, RESHAPE, END.
```

## `complex`

```
COMPLEX  Construit un nombre complexe.
    COMPLEX(A,B) rend A + Bi, et force le stockage complexe même si B est
    nul — c'est sa raison d'être.

    Syntaxe
       z = complex(a,b)
       z = complex(a)

    Exemples
       complex(1,2)                   % 1 + 2i
       isreal(complex(3,0))           % 0 — la partie imaginaire existe
       isreal(3 + 0)                  % 1
       abs(complex(3,4))              % 5

    Voir aussi REAL, IMAG, ISREAL, ABS, ANGLE.
```

## `ctranspose`

```
CTRANSPOSE  Transposée conjuguée, l'opérateur « ' ».
    CTRANSPOSE(A) transpose et conjugue. Sur du réel, c'est la transposée.

    Syntaxe
       B = ctranspose(A)
       B = A'

    Exemples
       z = [1+2i 3-1i];
       z'                         % conjuguée et transposée
       A = magic(3);
       isequal(A', A.')           % vrai : A est réelle

    Voir aussi TRANSPOSE, CONJ, MLDIVIDE.
```

## `double`

```
DOUBLE  Convertit en double précision.
    DOUBLE(X) convertit X en double : c'est la classe par défaut de tout
    calcul en MATLAB. Sur du texte, elle rend les codes des caractères.

    Syntaxe
       y = double(x)

    Exemples
       double(int8(-5))           % -5, en double
       double('A')                % 65
       double(true)               % 1
       class(double(single(1)))   % 'double'

    Voir aussi SINGLE, INT32, CHAR, LOGICAL, CAST, CLASS.
```

## `e`

```
E  Le nombre e, base du logarithme naturel, 2.71828182845905.

    Syntaxe
       e

    Exemples
       e
       abs(e - exp(1)) < 1e-12
       log(e)                         % 1

    Voir aussi EXP, LOG, PI.
```

## `eps`

```
EPS  Précision relative de la virgule flottante.
    EPS est l'écart entre 1 et le nombre flottant suivant, soit
    2.2204e-16 en double précision.
    EPS(X) rend l'écart entre X et le flottant suivant.
    EPS('single') rend la précision en simple précision.

    C'est avec quoi on compare des flottants : « a == b » est presque
    toujours faux, « abs(a-b) < 1e-10 » est ce qu'on veut dire.

    Syntaxe
       eps
       eps(x)
       eps('single')

    Exemples
       eps
       0.1 + 0.2 == 0.3               % faux
       abs((0.1+0.2) - 0.3) < eps     % vrai
       eps(1e6)

    Voir aussi REALMIN, REALMAX, FLINTMAX, ROUND.
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
       A = [2 1; 1 3];
       A \ eye(size(A))      % une façon d'écrire inv(A)

    Voir aussi ZEROS, ONES, DIAG, INV.
```

## `false`

```
FALSE  Tableau logique de faux.
    FALSE rend le scalaire logique faux.
    FALSE(N) rend une matrice N par N de faux.

    Syntaxe
       false
       false(n)
       false(m,n)

    Exemples
       false
       vus = false(1,10);
       vus([2 5]) = true;
       find(vus)

    Voir aussi TRUE, LOGICAL, ANY, ALL.
```

## `flintmax`

```
FLINTMAX  Plus grand entier représenté exactement en flottant.
    FLINTMAX vaut 2^53 en double précision : au-delà, les entiers
    consécutifs ne sont plus tous représentables.

    Syntaxe
       m = flintmax
       m = flintmax('single')

    Exemples
       flintmax
       flintmax + 1 == flintmax + 2   % vrai : la précision est perdue
       flintmax == 2^53

    Voir aussi INTMAX, REALMAX, EPS, INT64.
```

## `flip`

```
FLIP  Retourne l'ordre des éléments.
    FLIP(A) retourne selon la première dimension non singleton.
    FLIP(A,DIM) retourne selon la dimension DIM.

    Syntaxe
       B = flip(A)
       B = flip(A,dim)

    Exemples
       flip([1 2 3])                  % [3 2 1]
       flip(magic(3), 2)              % colonnes inversées

    Voir aussi FLIPLR, FLIPUD, ROT90, CIRCSHIFT.
```

## `fliplr`

```
FLIPLR  Retourne de gauche à droite.
    FLIPLR(A) inverse l'ordre des colonnes.

    Syntaxe
       B = fliplr(A)

    Exemples
       fliplr([1 2 3])                % [3 2 1]
       fliplr(magic(3))

    Voir aussi FLIPUD, FLIP, ROT90.
```

## `flipud`

```
FLIPUD  Retourne de haut en bas.
    FLIPUD(A) inverse l'ordre des lignes.

    Syntaxe
       B = flipud(A)

    Exemples
       flipud([1;2;3])                % [3;2;1]
       flipud(magic(3))

    Voir aussi FLIPLR, FLIP, ROT90.
```

## `float`

```
float  Conversion en simple precision. Synonyme de single, propre a MatLibre : MATLAB ne connait que single.
```

## `horzcat`

```
HORZCAT  Concaténation horizontale, l'opérateur « [A, B] ».

    Syntaxe
       C = horzcat(A,B,...)
       C = [A, B]

    Exemples
       horzcat([1 2], [3 4])                  % [1 2 3 4]
       [magic(2), ones(2,1)]

    Voir aussi VERTCAT, CAT, REPMAT.
```

## `i`

```
I  L'unité imaginaire, racine de -1.
    I vaut sqrt(-1). J en est le synonyme. Écrire « 3i » plutôt que « 3*i »
    est plus sûr : le suffixe ne peut pas être masqué par une variable
    nommée i — celle d'une boucle, par exemple.

    Syntaxe
       i
       j

    Exemples
       i^2                            % -1
       z = 3 + 4i;
       abs(z)                         % 5
       real(z)                        % 3

    Voir aussi J, COMPLEX, REAL, IMAG, ABS, ANGLE.
```

## `ind2sub`

```
IND2SUB  Indices par dimension à partir de l'indice linéaire.
    [I,J] = IND2SUB(TAILLE,K) est l'inverse de SUB2IND.

    Syntaxe
       [i,j] = ind2sub(taille,k)

    Exemples
       A = magic(4);
       [~, k] = max(A(:));
       [i,j] = ind2sub(size(A), k);   % où est le maximum
       A(i,j) == max(A(:))

    Voir aussi SUB2IND, FIND, SIZE, MAX.
```

## `inf`

```
INF  Synonyme de Inf, l'infini de la virgule flottante.

    Syntaxe
       inf
       inf(n)

    Exemples
       inf
       1/0 == inf
       size(inf(2,3))

    Voir aussi INF, NAN, ISINF, ISFINITE.
```

## `int16`

```
INT16  Convertit en entier signé 16 bits, dans [-32768, 32767].

    Syntaxe
       y = int16(x)

    Exemples
       int16(1000)
       int16(40000)                   % 32767, saturé
       intmin('int16')

    Voir aussi INT8, INT32, INT64, UINT16, INTMAX.
```

## `int32`

```
INT32  Convertit en entier signé 32 bits.
    INT32(X) arrondit X et le ramène dans [-2147483648, 2147483647] : le
    calcul entier de MATLAB sature, il ne déborde pas.

    Syntaxe
       y = int32(x)

    Exemples
       int32(3.7)                 % 4
       int32(-3.5)                % -4 — on arrondit en s'éloignant de zéro
       int32(2^40)                % 2147483647, saturé
       intmax('int32')

    Voir aussi INT8, INT16, INT64, UINT32, INTMAX, INTMIN, CAST.
```

## `int64`

```
INT64  Convertit en entier signé 64 bits.
    C'est la classe à prendre pour des entiers au-delà de FLINTMAX, que
    le double ne représente plus exactement.

    Syntaxe
       y = int64(x)

    Exemples
       int64(2)^62
       intmax('int64')
       int64(9007199254740993)        % au-delà de flintmax

    Voir aussi INT32, UINT64, FLINTMAX, INTMAX.
```

## `int8`

```
INT8  Convertit en entier signé 8 bits, dans [-128, 127].
    Le calcul entier de MATLAB sature : il ne déborde pas.

    Syntaxe
       y = int8(x)

    Exemples
       int8(100)
       int8(200)                      % 127, saturé
       int8(100) + int8(100)          % 127, saturé aussi
       intmax('int8')

    Voir aussi INT16, INT32, INT64, UINT8, INTMAX, CAST.
```

## `intmax`

```
INTMAX  Plus grand entier d'une classe.
    INTMAX rend le plus grand int32.
    INTMAX('nom') le fait pour 'int8'..'int64', 'uint8'..'uint64'.

    Syntaxe
       m = intmax
       m = intmax('nom')

    Exemples
       intmax
       intmax('int8')             % 127
       intmax('uint8')            % 255
       intmax('int8') + int8(1)   % 127, saturé

    Voir aussi INTMIN, REALMAX, FLINTMAX, INT32.
```

## `intmin`

```
INTMIN  Plus petit entier d'une classe.
    INTMIN rend le plus petit int32.
    INTMIN('nom') le fait pour les autres classes entières.

    Syntaxe
       m = intmin
       m = intmin('nom')

    Exemples
       intmin
       intmin('int8')             % -128
       intmin('uint8')            % 0

    Voir aussi INTMAX, REALMIN, INT32.
```

## `ipermute`

```
IPERMUTE  Inverse de PERMUTE.
    IPERMUTE(B,ORDRE) défait PERMUTE(A,ORDRE).

    Syntaxe
       A = ipermute(B,ordre)

    Exemples
       A = reshape(1:24, 2, 3, 4);
       B = permute(A, [3 1 2]);
       isequal(ipermute(B, [3 1 2]), A)

    Voir aussi PERMUTE, RESHAPE, SQUEEZE.
```

## `is_function_handle`

```
is_function_handle  Vrai pour une poignee de fonction.
```

## `isa`

```
ISA  La valeur est-elle de la classe donnée.
    ISA(X,'nom') teste la classe exacte, mais accepte aussi les familles
    'numeric', 'float' et 'integer'.

    Syntaxe
       tf = isa(x,'nom')

    Exemples
       isa(1,'double')            % 1
       isa(int8(1),'integer')     % 1
       isa(single(1),'float')     % 1
       isa('abc','numeric')       % 0

    Voir aussi CLASS, ISNUMERIC, ISFLOAT, ISINTEGER.
```

## `iscell`

```
ISCELL  La valeur est-elle un tableau de cellules.
    ISCELL(X) rend vrai pour {1,'a'}.

    Syntaxe
       tf = iscell(x)

    Exemples
       iscell({1,'a'})            % 1
       iscell([1 2])              % 0

    Voir aussi ISCELLSTR, CELL, ISSTRUCT, CLASS.
```

## `ischar`

```
ISCHAR  La valeur est-elle un tableau de caractères.
    ISCHAR(X) rend vrai pour 'abc', faux pour "abc" — qui est une chaîne.

    Syntaxe
       tf = ischar(x)

    Exemples
       ischar('abc')              % 1
       ischar(65)                 % 0
       if ischar('bonjour')
           disp('du texte');
       end

    Voir aussi ISSTRING, ISCELLSTR, CHAR, CLASS.
```

## `iscolumn`

```
ISCOLUMN  La valeur est-elle un vecteur colonne, c'est-à-dire N par 1.

    Syntaxe
       tf = iscolumn(x)

    Exemples
       iscolumn([1;2;3])              % 1
       iscolumn([1 2 3])              % 0
       v = (1:5)';
       iscolumn(v)

    Voir aussi ISROW, ISVECTOR, SIZE.
```

## `isempty`

```
ISEMPTY  Le tableau est-il vide.
    ISEMPTY(X) rend vrai si l'une des dimensions de X est nulle.

    Syntaxe
       tf = isempty(x)

    Exemples
       isempty([])                % 1
       isempty('')                % 1
       isempty(zeros(0,3))        % 1
       isempty(0)                 % 0
       C = {};
       if isempty(C)
           disp('rien à traiter');
       end

    Voir aussi SIZE, NUMEL, LENGTH, ISSCALAR.
```

## `isequal`

```
ISEQUAL  Les valeurs sont-elles identiques.
    ISEQUAL(A,B) compare taille et contenu, et rend un seul booléen — à la
    différence de « == », qui compare élément par élément.
    ISEQUAL(A,B,C,...) compare toutes les valeurs entre elles.
    Deux NaN ne sont jamais égaux : voir ISEQUALN.

    Syntaxe
       tf = isequal(a,b)
       tf = isequal(a,b,c,...)

    Exemples
       isequal([1 2], [1 2])          % 1
       isequal([1 2], [1 2 3])        % 0 — tailles différentes
       isequal(struct('a',1), struct('a',1))   % 1
       isequal(NaN, NaN)              % 0

    Voir aussi ISEQUALN, EQ, STRCMP.
```

## `isequaln`

```
ISEQUALN  Comme ISEQUAL, mais NaN y est égal à NaN.
    C'est ce qu'on veut pour comparer des données à trous.

    Syntaxe
       tf = isequaln(a,b)

    Exemples
       isequal([1 NaN], [1 NaN])      % 0
       isequaln([1 NaN], [1 NaN])     % 1

    Voir aussi ISEQUAL, ISNAN.
```

## `isfloat`

```
ISFLOAT  La valeur est-elle en virgule flottante.
    ISFLOAT(X) rend vrai pour double et single.

    Syntaxe
       tf = isfloat(x)

    Exemples
       isfloat(1)                     % 1
       isfloat(single(1))             % 1
       isfloat(int8(1))               % 0

    Voir aussi ISINTEGER, ISNUMERIC, ISA, CLASS.
```

## `isinteger`

```
ISINTEGER  La valeur est-elle d'une classe entière.
    ISINTEGER(X) rend vrai pour int8..int64 et uint8..uint64, faux pour un
    double qui se trouve valoir un entier.

    Syntaxe
       tf = isinteger(x)

    Exemples
       isinteger(int8(1))             % 1
       isinteger(3)                   % 0 — un double vaut 3, sans être entier
       mod(3,1) == 0                  % le test qu'on voulait sans doute

    Voir aussi ISFLOAT, ISNUMERIC, ISA, INT32.
```

## `islogical`

```
ISLOGICAL  La valeur est-elle un tableau logique.

    Syntaxe
       tf = islogical(x)

    Exemples
       islogical(true)                % 1
       islogical(1)                   % 0
       islogical([1 2] > 1)           % 1

    Voir aussi LOGICAL, TRUE, FALSE, ISNUMERIC.
```

## `ismatrix`

```
ISMATRIX  La valeur a-t-elle exactement deux dimensions.

    Syntaxe
       tf = ismatrix(x)

    Exemples
       ismatrix(magic(3))             % 1
       ismatrix(5)                    % 1
       ismatrix(ones(2,3,4))          % 0

    Voir aussi ISVECTOR, ISSCALAR, NDIMS, SIZE.
```

## `isnumeric`

```
ISNUMERIC  La valeur est-elle numérique.
    ISNUMERIC(X) rend vrai pour les doubles, les simples et les entiers,
    faux pour les logiques, les caractères, les cellules et les structures.

    Syntaxe
       tf = isnumeric(x)

    Exemples
       isnumeric(1)               % 1
       isnumeric(int8(1))         % 1
       isnumeric(true)            % 0 — un logique n'est pas numérique
       isnumeric('a')             % 0

    Voir aussi ISA, CLASS, ISFLOAT, ISINTEGER, ISLOGICAL.
```

## `isobject`

```
ISOBJECT  La valeur est-elle un objet d'une classe définie par
    l'utilisateur.

    Syntaxe
       tf = isobject(x)

    Exemples
       isobject(1)                    % 0
       isobject(containers.Map())     % 1

    Voir aussi CLASS, ISA, ISSTRUCT.
```

## `isreal`

```
ISREAL  La valeur est-elle dépourvue de partie imaginaire.
    ISREAL(X) rend faux dès que X a une partie imaginaire enregistrée,
    même nulle : c'est le stockage qui compte, pas la valeur.

    Syntaxe
       tf = isreal(x)

    Exemples
       isreal(3)                      % 1
       isreal(3 + 0i)                 % 0 — la partie imaginaire existe
       isreal(abs(3 + 4i))            % 1
       isreal(complex(1,0))           % 0

    Voir aussi COMPLEX, REAL, IMAG, ISNUMERIC.
```

## `isrow`

```
ISROW  La valeur est-elle un vecteur ligne, c'est-à-dire 1 par N.

    Syntaxe
       tf = isrow(x)

    Exemples
       isrow([1 2 3])                 % 1
       isrow([1;2;3])                 % 0
       x = 1:5;
       if ~isrow(x), x = x'; end      % forcer une ligne

    Voir aussi ISCOLUMN, ISVECTOR, ISSCALAR, SIZE.
```

## `isscalar`

```
ISSCALAR  La valeur est-elle un scalaire, c'est-à-dire 1x1.

    Syntaxe
       tf = isscalar(x)

    Exemples
       isscalar(5)                % 1
       isscalar([1 2])            % 0
       isscalar('a')              % 1
       isscalar('ab')             % 0

    Voir aussi ISVECTOR, ISMATRIX, ISEMPTY, SIZE.
```

## `isstring`

```
ISSTRING  La valeur est-elle un tableau de strings.
    ISSTRING(X) distingue "abc", une string, de 'abc', un tableau de
    caractères.

    Syntaxe
       tf = isstring(x)

    Exemples
       isstring("abc")                % 1
       isstring('abc')                % 0
       ischar('abc')                  % 1

    Voir aussi ISCHAR, STRING, ISCELLSTR.
```

## `isstruct`

```
ISSTRUCT  La valeur est-elle une structure.
    ISSTRUCT(X) rend vrai pour une structure ou un tableau de structures.

    Syntaxe
       tf = isstruct(x)

    Exemples
       s.a = 1;
       isstruct(s)                % 1
       isstruct([1 2])            % 0

    Voir aussi ISFIELD, FIELDNAMES, STRUCT, CLASS.
```

## `isvector`

```
ISVECTOR  La valeur est-elle un vecteur, ligne ou colonne.

    Syntaxe
       tf = isvector(x)

    Exemples
       isvector([1 2 3])          % 1
       isvector([1;2;3])          % 1
       isvector(magic(3))         % 0
       isvector(5)                % 1 — un scalaire est un vecteur

    Voir aussi ISSCALAR, ISROW, ISCOLUMN, ISMATRIX.
```

## `j`

```
J  L'unité imaginaire, synonyme de I.
    J vaut sqrt(-1) ; les électroniciens l'écrivent ainsi, i désignant
    déjà un courant.

    Syntaxe
       j

    Exemples
       j^2                            % -1
       1 + 2j
       isequal(1i, 1j)

    Voir aussi I, COMPLEX, ABS, ANGLE.
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
LOGICAL  Convertit en booléens.
    LOGICAL(X) rend faux là où X vaut zéro, vrai ailleurs. Un tableau
    logique sert de masque d'indexation.

    Syntaxe
       y = logical(x)

    Exemples
       logical([0 2 -1])          % [0 1 1]
       x = 1:5;
       x(logical([1 0 1 0 1]))    % [1 3 5]
       class(x > 2)               % 'logical'

    Voir aussi TRUE, FALSE, FIND, ANY, ALL.
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
MESHGRID  Grille de coordonnées à partir de deux vecteurs.
    [X,Y] = MESHGRID(x,y) rend deux matrices : X répète x en lignes, Y
    répète y en colonnes. C'est ce qu'on donne à SURF, MESH ou CONTOUR.
    [X,Y] = MESHGRID(x) vaut MESHGRID(x,x).

    Syntaxe
       [X,Y] = meshgrid(x,y)
       [X,Y] = meshgrid(x)

    Exemples
       [X,Y] = meshgrid(1:3, 1:2);
       X
       Y
       [X,Y] = meshgrid(-2:0.1:2);
       surf(X, Y, X.^2 - Y.^2);

    Voir aussi NDGRID, SURF, MESH, CONTOUR.
```

## `nan`

```
NAN  Synonyme de NaN, « Not a Number ».

    Syntaxe
       nan
       nan(n)

    Exemples
       isnan(nan)                     % 1
       size(nan(2,3))
       nan == nan                     % 0

    Voir aussi NAN, ISNAN, INF.
```

## `ndgrid`

```
NDGRID  Grille de coordonnées, convention tableau.
    [X,Y] = NDGRID(x,y) est comme MESHGRID, mais X varie selon les lignes
    et Y selon les colonnes : c'est la convention des tableaux, transposée
    de celle du graphique.

    Syntaxe
       [X,Y] = ndgrid(x,y)

    Exemples
       [X, Y] = ndgrid(1:3, 1:2);
       size(X)                            % [3 2]
       [Xm, Ym] = meshgrid(1:3, 1:2);
       isequal(X, Xm')                    % l'une est la transposée de l'autre

    Voir aussi MESHGRID, SUB2IND, INTERP2.
```

## `ndims`

```
NDIMS  Nombre de dimensions.
    NDIMS(A) vaut NUMEL(SIZE(A)), et jamais moins de 2 : en MATLAB, un
    scalaire est une matrice 1x1.

    Syntaxe
       n = ndims(A)

    Exemples
       ndims(5)                               % 2
       ndims(magic(3))                        % 2
       ndims(ones(2,3,4))                     % 3

    Voir aussi SIZE, NUMEL, LENGTH, SQUEEZE.
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
PERMUTE  Réordonne les dimensions d'un tableau.
    PERMUTE(A,ORDRE) échange les dimensions selon ORDRE ; c'est la
    transposée généralisée aux tableaux de plus de deux dimensions.

    Syntaxe
       B = permute(A,ordre)

    Exemples
       A = reshape(1:24, 2, 3, 4);
       size(permute(A, [3 1 2]))      % [4 2 3]
       isequal(permute(magic(3), [2 1]), magic(3)')

    Voir aussi IPERMUTE, RESHAPE, SQUEEZE, TRANSPOSE.
```

## `pi`

```
PI  Le nombre π, 3.14159265358979.
    PI rend l'approximation en double précision de π.

    Syntaxe
       pi

    Exemples
       pi
       cos(pi)                    % -1
       t = 0:0.01:2*pi;
       plot(t, sin(t));

    Voir aussi E, EPS, SIN, COS, EXP.
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
       a = -2;  b = 5;
       a + (b-a)*rand(1,100)      % 100 tirages entre a et b
       rng(0); rand(1,3)          % suite reproductible

    Voir aussi RANDN, RANDI, RANDPERM, RNG.
```

## `randi`

```
RANDI  Entiers pseudo-aléatoires.
    RANDI(N) tire un entier entre 1 et N.
    RANDI(N,M,K) rend une matrice M par K.
    RANDI([A B],...) tire entre A et B.

    Syntaxe
       x = randi(n)
       x = randi(n,m,k)
       x = randi([a b],m,k)

    Exemples
       rng(0);
       x = randi(6, 1, 10);           % dix lancers de dé
       all(x >= 1 & x <= 6)
       randi([10 20], 1, 5);

    Voir aussi RAND, RANDN, RANDPERM, RNG.
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
       mu = 10;  sigma = 2;  n = 5;
       mu + sigma*randn(1,n)      % loi normale de paramètres mu, sigma

    Voir aussi RAND, RANDI, RNG.
```

## `randperm`

```
RANDPERM  Permutation aléatoire.
    RANDPERM(N) rend une permutation des entiers 1 à N.
    RANDPERM(N,K) en rend K, tirés sans remise.

    Syntaxe
       p = randperm(n)
       p = randperm(n,k)

    Exemples
       rng(0);
       p = randperm(5);
       isequal(sort(p), 1:5)
       x = 10:10:50;
       x(randperm(numel(x)))          % mélanger un vecteur

    Voir aussi RANDI, RAND, RNG, SORT.
```

## `realmax`

```
REALMAX  Plus grand double fini, 1.7977e+308.

    Syntaxe
       realmax
       realmax('single')

    Exemples
       realmax
       realmax * 2                % Inf — au-delà, c'est l'infini

    Voir aussi REALMIN, INF, EPS, INTMAX.
```

## `realmin`

```
REALMIN  Plus petit double normalisé positif, 2.2251e-308.

    Syntaxe
       realmin
       realmin('single')

    Exemples
       realmin
       realmin / 2                % encore représentable, dénormalisé

    Voir aussi REALMAX, EPS, INF.
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
       x = [1; 2; 3];  n = 4;
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
       A = magic(3);
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
ROT90  Rotation d'un quart de tour dans le sens direct.
    ROT90(A) tourne A de 90 degrés.
    ROT90(A,K) tourne de K quarts de tour.

    Syntaxe
       B = rot90(A)
       B = rot90(A,k)

    Exemples
       rot90([1 2; 3 4])
       isequal(rot90(magic(3), 4), magic(3))   % quatre quarts, on revient

    Voir aussi FLIPLR, FLIPUD, FLIP, TRANSPOSE.
```

## `single`

```
SINGLE  Convertit en simple précision.
    SINGLE(X) convertit X en flottant 32 bits : deux fois moins de
    mémoire, environ sept chiffres significatifs au lieu de seize.

    Syntaxe
       y = single(x)

    Exemples
       single(pi)
       eps('single')
       class(single(1) + 1)       % 'single' — la simple l'emporte

    Voir aussi DOUBLE, CAST, EPS, CLASS.
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
       A = magic(4);
       [m,n] = size(A);

    Voir aussi NUMEL, LENGTH, NDIMS, RESHAPE.
```

## `squeeze`

```
SQUEEZE  Retire les dimensions de longueur 1.
    SQUEEZE(A) supprime les dimensions singleton au-delà de la deuxième :
    un tableau 1x1x5 devient un vecteur colonne de 5.

    Syntaxe
       B = squeeze(A)

    Exemples
       A = reshape(1:6, 1, 1, 6);
       size(squeeze(A))               % [6 1]
       size(squeeze(ones(2,1,3)))     % [2 3]

    Voir aussi RESHAPE, PERMUTE, SIZE.
```

## `sub2ind`

```
SUB2IND  Indice linéaire à partir des indices par dimension.
    SUB2IND(TAILLE,I,J) rend l'indice unique correspondant à (I,J) dans un
    tableau de la taille donnée. MATLAB range par colonnes.

    Syntaxe
       k = sub2ind(taille,i,j)

    Exemples
       A = magic(3);
       k = sub2ind(size(A), 2, 3);
       A(k) == A(2,3)
       sub2ind([3 3], 1, 2)           % 4

    Voir aussi IND2SUB, SIZE, RESHAPE, FIND.
```

## `transpose`

```
TRANSPOSE  Transposée non conjuguée, l'opérateur « .' ».
    TRANSPOSE(A) échange lignes et colonnes sans conjuguer. Sur du
    complexe, c'est « .' » et non « ' ».

    Syntaxe
       B = transpose(A)
       B = A.'

    Exemples
       transpose([1 2; 3 4])
       z = [1+2i 3-1i];
       z.'                        % transposée seule
       z'                         % transposée conjuguée

    Voir aussi CTRANSPOSE, PERMUTE, RESHAPE.
```

## `true`

```
TRUE  Tableau logique de vrais.
    TRUE rend le scalaire logique vrai.
    TRUE(N) rend une matrice N par N de vrais.

    Syntaxe
       true
       true(n)
       true(m,n)

    Exemples
       true
       masque = true(1,5);
       masque(3) = false;
       x = 10:10:50;
       x(masque)

    Voir aussi FALSE, LOGICAL, ANY, ALL.
```

## `typecast`

```
typecast  Relit les octets d'une valeur dans une autre classe.
```

## `uint16`

```
UINT16  Convertit en entier non signé 16 bits, dans [0, 65535].
    C'est la classe des images en 16 bits par canal.

    Syntaxe
       y = uint16(x)

    Exemples
       uint16(70000)                  % 65535, saturé
       uint16(-1)                     % 0, saturé
       intmax('uint16')

    Voir aussi UINT8, UINT32, INT16, INTMAX.
```

## `uint32`

```
UINT32  Convertit en entier non signé 32 bits, dans [0, 4294967295].

    Syntaxe
       y = uint32(x)

    Exemples
       uint32(5e9)                    % saturé
       intmax('uint32')

    Voir aussi UINT16, UINT64, INT32, INTMAX.
```

## `uint64`

```
UINT64  Convertit en entier non signé 64 bits.

    Syntaxe
       y = uint64(x)

    Exemples
       uint64(2)^63
       intmax('uint64')

    Voir aussi UINT32, INT64, FLINTMAX, INTMAX.
```

## `uint8`

```
UINT8  Convertit en entier non signé 8 bits.
    UINT8(X) arrondit X et le ramène dans [0, 255]. C'est la classe des
    images en niveaux de gris et des canaux de couleur.

    Syntaxe
       y = uint8(x)

    Exemples
       uint8(200)                 % 200
       uint8(300)                 % 255, saturé
       uint8(-5)                  % 0, saturé
       uint8(3.5)                 % 4

    Voir aussi UINT16, INT8, INTMAX, IMAGE, CAST.
```

## `validateattributes`

```
VALIDATEATTRIBUTES  Vérifie qu'une valeur a la forme attendue.
    VALIDATEATTRIBUTES(A,CLASSES,ATTRIBUTS) lève une erreur explicite si A
    n'est pas d'une des classes, ou ne respecte pas les attributs :
    'positive', 'nonempty', 'scalar', 'vector', 'integer', 'finite'…

    Syntaxe
       validateattributes(a,classes,attributs)

    Exemples
       validateattributes(3, {'numeric'}, {'positive','scalar'});
       try
           validateattributes(-1, {'numeric'}, {'positive'});
       catch e
           disp('rejeté, comme il se doit');
       end

    Voir aussi ASSERT, NARGINCHK, ERROR, ISA.
```

## `vertcat`

```
VERTCAT  Concaténation verticale, l'opérateur « [A; B] ».

    Syntaxe
       C = vertcat(A,B,...)
       C = [A; B]

    Exemples
       vertcat([1 2], [3 4])                  % [1 2; 3 4]
       [magic(2); ones(1,2)]

    Voir aussi HORZCAT, CAT, REPMAT.
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
       A = magic(4);
       zeros(size(A))        % de la taille de A

    Voir aussi ONES, EYE, NAN, RAND, SIZE.
```

