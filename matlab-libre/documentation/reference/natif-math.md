# Mathematiques elementaires

Fonctions natives du groupe `math`.

## `abs`

```
ABS  Valeur absolue, ou module d'un complexe.
    Y = ABS(X) rend |X|. Pour un complexe, ABS rend le module,
    SQRT(REAL(X).^2 + IMAG(X).^2).

    Syntaxe
       Y = abs(X)

    Exemples

       abs(-3)                    % 3
       abs(3 + 4i)                % 5
       x = sin(2*pi*(0:63)/64);
       abs(fft(x))                % spectre d'amplitude

    Voir aussi SIGN, ANGLE, REAL, IMAG, HYPOT.
```

## `acos`

```
ACOS  Arc cosinus, en radians.
    ACOS(X) rend l'angle dont le cosinus vaut X, dans [0, pi] pour X dans
    [-1, 1], complexe au-delà.

    Syntaxe
       Y = acos(X)

    Exemples
       acos(1)                % 0
       acos(0)                % 1.5708, soit pi/2
       acos(-1)               % 3.1416, soit pi
       abs(acos(cos(0.7)) - 0.7) < 1e-12  % vrai

    Voir aussi COS, ASIN, ATAN, ACOSD, ACOSH.
```

## `acosd`

```
ACOSD  Arc cosinus, en degrés.
    ACOSD(X) rend l'angle en degrés dont le cosinus vaut X : le résultat
    est dans [0, 180] pour X dans [-1, 1]. Hors de cet intervalle il est
    complexe, comme dans MATLAB.

    Syntaxe
       Y = acosd(X)

    Exemples
       acosd(0)               % 90
       acosd(1)               % 0
       acosd([1 0.5 0 -1])    % 0  60  90  180
       acosd(cosd(30))        % 30

    Voir aussi COSD, ASIND, ATAND, ACOS, RAD2DEG.
```

## `acosh`

```
ACOSH  Arc cosinus hyperbolique.
    ACOSH(X) rend log(X + sqrt(X^2 - 1)), défini pour X >= 1 ; en deçà,
    le résultat est complexe.

    Syntaxe
       Y = acosh(X)

    Exemples
       acosh(1)               % 0
       acosh(cosh(1.5))       % 1.5
       imag(acosh(0)) ~= 0    % vrai : sous 1, le resultat est complexe

    Voir aussi COSH, ASINH, ATANH, ACOS.
```

## `and`

```
AND  Et logique, sous forme de fonction.
    AND(A,B) est ce qu'écrit A & B : vrai là où les deux sont non nuls.
    Contrairement à &&, l'opérateur travaille élément par élément et
    évalue toujours ses deux arguments.

    Syntaxe
       T = and(A,B)

    Exemples
       and(true, false)           % faux
       and([1 0 1], [1 1 0])      % 1  0  0
       and([2 0], [3 3])          % 1  0 : tout non-nul est vrai

    Voir aussi OR, NOT, XOR, ALL, ANY.
```

## `angle`

```
ANGLE  Argument d'un nombre complexe, en radians.
    P = ANGLE(Z) rend l'argument de Z, dans ]-pi, pi].

    Syntaxe
       P = angle(Z)

    Exemples

       angle(1i)                  % pi/2
       angle(-1)                  % pi
       x = randn(1,64);
       unwrap(angle(fft(x)))      % phase déroulée d'un spectre

    Voir aussi ABS, UNWRAP, REAL, IMAG, ATAN2.
```

## `arg`

```
ARG  Argument d'un nombre complexe, en radians.
    ARG(Z) rend l'angle que fait Z avec l'axe réel, dans ]-pi, pi]. C'est
    le nom qu'Octave donne à ANGLE ; MatLibre accepte les deux.

    Syntaxe
       A = arg(Z)

    Exemples
       arg(1i)                % 1.5708
       arg(-1)                % 3.1416
       arg(1 + 1i)            % 0.7854
       abs(arg(1+1i) - angle(1+1i)) < 1e-15   % vrai : c'est la meme chose

    Voir aussi ANGLE, ABS, REAL, IMAG, ATAN2.
```

## `asin`

```
ASIN  Arc sinus, en radians.
    ASIN(X) rend l'angle dont le sinus vaut X. Pour X dans [-1, 1], le
    résultat est dans [-pi/2, pi/2] ; hors de cet intervalle, il est
    complexe, comme dans MATLAB.

    Syntaxe
       Y = asin(X)

    Exemples
       asin(1)                % 1.5708, soit pi/2
       asin(0.5)              % 0.5236, soit pi/6
       asin(sin(0.3))         % 0.3, la fonction reciproque
       real(asin(2)) > 0      % vrai : hors de [-1,1], le resultat est complexe

    Voir aussi SIN, ACOS, ATAN, ASIND, ASINH.
```

## `asind`

```
ASIND  Arc sinus, en degrés.
    ASIND(X) rend l'angle en degrés dont le sinus vaut X : le résultat
    est dans [-90, 90] pour X dans [-1, 1].

    Syntaxe
       Y = asind(X)

    Exemples
       asind(1)               % 90
       asind(0.5)             % 30
       asind([0 0.5 1])       % 0  30  90
       asind(sind(20))        % 20

    Voir aussi SIND, ACOSD, ATAND, ASIN.
```

## `asinh`

```
ASINH  Arc sinus hyperbolique.
    ASINH(X) rend log(X + sqrt(X^2 + 1)) : la fonction réciproque de
    SINH, définie sur tout l'axe réel.

    Syntaxe
       Y = asinh(X)

    Exemples
       asinh(0)               % 0
       asinh(sinh(2))         % 2
       abs(asinh(1) - log(1 + sqrt(2))) < 1e-12   % vrai

    Voir aussi SINH, ACOSH, ATANH, ASIN.
```

## `atan`

```
ATAN  Arc tangente, en radians.
    ATAN(X) rend l'angle dont la tangente vaut X, dans ]-pi/2, pi/2[.
    Pour retrouver le quadrant d'un point, il faut les deux coordonnées :
    c'est ATAN2 qu'il faut alors.

    Syntaxe
       Y = atan(X)

    Exemples
       atan(1)                % 0.7854, soit pi/4
       atan(0)                % 0
       atan(Inf)              % 1.5708
       atan(tan(0.4))         % 0.4

    Voir aussi TAN, ATAN2, ASIN, ACOS, ATAND.
```

## `atan2`

```
ATAN2  Arc tangente à quatre quadrants.
    P = ATAN2(Y,X) rend l'angle du point (X,Y), dans ]-pi, pi]. À la
    différence d'ATAN(Y/X), ATAN2 distingue les quadrants et gère X = 0.

    Syntaxe
       P = atan2(Y,X)

    Exemples

       atan2(1,1)                 % pi/4
       atan2(1,-1)                % 3*pi/4 — et non -pi/4
       dx = 3;  dy = 4;
       theta = atan2(dy, dx);

    Voir aussi ATAN, ANGLE, HYPOT, CART2POL.
```

## `atan2d`

```
ATAN2D  Arc tangente à quatre quadrants, en degrés.
    ATAN2D(Y,X) rend l'angle en degrés, dans ]-180, 180], que fait le
    point (X,Y) avec l'axe des abscisses. Les signes des deux arguments
    donnent le quadrant, ce qu'ATAND ne peut pas savoir.

    Syntaxe
       A = atan2d(Y,X)

    Exemples
       atan2d(1, 1)           % 45
       atan2d(1, -1)          % 135 : le deuxieme quadrant
       atan2d(-1, -1)         % -135
       atan2d(0, -1)          % 180

    Voir aussi ATAN2, ATAND, ANGLE, CART2POL.
```

## `atand`

```
ATAND  Arc tangente, en degrés.
    ATAND(X) rend l'angle en degrés dont la tangente vaut X, dans
    ]-90, 90[.

    Syntaxe
       Y = atand(X)

    Exemples
       atand(1)               % 45
       atand(0)               % 0
       atand(Inf)             % 90
       atand(tand(15))        % 15

    Voir aussi TAND, ATAN, ATAN2D, ASIND.
```

## `atanh`

```
ATANH  Arc tangente hyperbolique.
    ATANH(X) rend log((1+X)/(1-X))/2, défini pour |X| < 1 ; aux bornes il
    vaut ±Inf, au-delà il est complexe.

    Syntaxe
       Y = atanh(X)

    Exemples
       atanh(0)               % 0
       atanh(tanh(0.6))       % 0.6
       atanh(1)               % Inf
       abs(atanh(0.5) - log(3)/2) < 1e-12    % vrai

    Voir aussi TANH, ASINH, ACOSH, ATAN.
```

## `besselj`

```
BESSELJ  Fonction de Bessel de première espèce.
    BESSELJ(NU,Z) rend J_nu(Z), solution bornée en zéro de l'équation de
    Bessel. Elle décrit les modes d'une membrane circulaire, la
    diffraction par une ouverture ronde, les modes d'un guide d'ondes.

    Syntaxe
       J = besselj(nu,Z)

    Exemples
       besselj(0, 0)          % 1
       besselj(1, 0)          % 0
       abs(besselj(0, 2.404825557)) < 1e-6   % le premier zero de J0
       besselj(0, [0 1 2])    % 1  0.7652  0.2239

    Voir aussi BESSELY, BESSELI, BESSELK.
```

## `bessely`

```
BESSELY  Fonction de Bessel de seconde espèce.
    BESSELY(NU,Z) rend Y_nu(Z), la seconde solution de l'équation de
    Bessel. Elle diverge en zéro : c'est ce qui l'écarte des problèmes
    posés sur un disque plein, et ce qui la rend nécessaire sur un anneau.

    Syntaxe
       Y = bessely(nu,Z)

    Exemples
       bessely(0, 1)          % 0.0883
       bessely(0, 0)          % -Inf
       bessely(0, [1 2 3])    % 0.0883  0.5104  0.3769

    Voir aussi BESSELJ, BESSELI, BESSELK.
```

## `beta`

```
BETA  Fonction bêta d'Euler.
    BETA(Z,W) rend gamma(Z)*gamma(W)/gamma(Z+W). Pour des entiers, elle
    s'exprime avec des factorielles et donne l'inverse d'un coefficient
    binomial pondéré.

    Syntaxe
       B = beta(Z,W)

    Exemples
       beta(1, 1)             % 1
       abs(beta(2, 3) - 1/12) < 1e-12        % vrai
       abs(beta(0.5, 0.5) - pi) < 1e-12      % vrai
       abs(beta(3, 4) - gamma(3)*gamma(4)/gamma(7)) < 1e-15

    Voir aussi BETAINC, BETALN, GAMMA, NCHOOSEK.
```

## `betainc`

```
BETAINC  Fonction bêta incomplète, normalisée.
    BETAINC(X,Z,W) rend la part de l'intégrale de la loi bêta accumulée
    jusqu'à X, pour X dans [0, 1] : une valeur entre 0 et 1. C'est la
    fonction de répartition de la loi bêta.

    Syntaxe
       P = betainc(X,Z,W)

    Exemples
       betainc(0, 2, 3)       % 0
       betainc(1, 2, 3)       % 1
       abs(betainc(0.5, 1, 1) - 0.5) < 1e-12   % la loi uniforme
       betainc(0.5, 2, 2)     % 0.5, par symetrie

    Voir aussi BETA, BETALN, GAMMAINC.
```

## `betaln`

```
BETALN  Logarithme de la fonction bêta.
    BETALN(Z,W) rend log(BETA(Z,W)) sans calculer la bêta, qui déborde ou
    s'annule pour de grands arguments.

    Syntaxe
       L = betaln(Z,W)

    Exemples
       betaln(1, 1)           % 0
       abs(betaln(2, 3) - log(1/12)) < 1e-12    % vrai
       betaln(500, 500) < 0   % vrai, la ou beta(500,500) rend 0

    Voir aussi BETA, BETAINC, GAMMALN.
```

## `bin2dec`

```
BIN2DEC  Texte binaire vers entier.
    BIN2DEC(S) lit une chaîne de 0 et de 1 et rend l'entier qu'elle
    représente. Les espaces sont ignorés.

    Syntaxe
       D = bin2dec(S)

    Exemples
       bin2dec('1010')        % 10
       bin2dec('11111111')    % 255
       bin2dec('0')           % 0
       dec2bin(bin2dec('1101'))   % '1101'

    Voir aussi DEC2BIN, HEX2DEC, DEC2HEX.
```

## `bitand`

```
BITAND  Et bit à bit.
    BITAND(A,B) rend l'entier dont chaque bit vaut 1 quand il vaut 1 dans
    A et dans B. Les arguments doivent être des entiers positifs, ou des
    entiers d'un type entier.

    Syntaxe
       C = bitand(A,B)

    Exemples
       bitand(12, 10)         % 8, soit 1100 et 1010 -> 1000
       bitand(255, 15)        % 15
       bitand([12 7], [10 3]) % 8  3

    Voir aussi BITOR, BITXOR, BITCMP, BITSHIFT, DEC2BIN.
```

## `bitcmp`

```
BITCMP  Complément bit à bit.
    BITCMP(A) retourne tous les bits de A, dans la largeur de son type :
    pour un uint8, les huit bits ; pour un double, les cinquante-trois de
    la mantisse.

    Syntaxe
       C = bitcmp(A)

    Exemples
       bitcmp(uint8(0))       % 255
       bitcmp(uint8(15))      % 240
       bitcmp(uint16(0))      % 65535
       bitcmp(bitcmp(uint8(42)))  % 42

    Voir aussi BITAND, BITOR, BITXOR, BITSHIFT.
```

## `bitor`

```
BITOR  Ou bit à bit.
    BITOR(A,B) rend l'entier dont chaque bit vaut 1 quand il vaut 1 dans
    A ou dans B.

    Syntaxe
       C = bitor(A,B)

    Exemples
       bitor(12, 10)          % 14, soit 1100 ou 1010 -> 1110
       bitor(8, 1)            % 9
       bitor([1 2], [4 8])    % 5  10

    Voir aussi BITAND, BITXOR, BITCMP, BITSHIFT.
```

## `bitshift`

```
BITSHIFT  Décalage de bits.
    BITSHIFT(A,K) décale les bits de A de K rangs vers la gauche quand K
    est positif — ce qui multiplie par 2^K —, vers la droite quand il est
    négatif — ce qui divise, en perdant les bits sortis.

    Syntaxe
       C = bitshift(A,K)

    Exemples
       bitshift(1, 3)         % 8
       bitshift(12, -2)       % 3
       bitshift(uint8(255), 1)    % 254 : le bit sorti est perdu
       bitshift([1 2 4], 2)   % 4  8  16

    Voir aussi BITAND, BITOR, BITXOR, POW2, IDIVIDE.
```

## `bitxor`

```
BITXOR  Ou exclusif bit à bit.
    BITXOR(A,B) rend l'entier dont chaque bit vaut 1 quand il diffère
    entre A et B. Appliqué deux fois avec la même clé, il rend le nombre
    de départ — c'est le principe du chiffrement de Vernam.

    Syntaxe
       C = bitxor(A,B)

    Exemples
       bitxor(12, 10)         % 6, soit 1100 xor 1010 -> 0110
       bitxor(5, 5)           % 0
       bitxor(bitxor(42, 7), 7)   % 42 : deux fois la meme cle

    Voir aussi BITAND, BITOR, BITCMP, XOR.
```

## `ceil`

```
CEIL  Arrondi vers le haut.
    CEIL(X) rend le plus petit entier supérieur ou égal à X. Pour les
    négatifs, cela veut dire vers zéro : ceil(-2.5) vaut -2.

    Syntaxe
       Y = ceil(X)

    Exemples
       ceil(2.1)              % 3
       ceil(-2.1)             % -2
       ceil([1.2 -1.2 3])     % 2  -1  3
       ceil(2)                % 2 : un entier ne bouge pas

    Voir aussi FLOOR, ROUND, FIX, IDIVIDE.
```

## `conj`

```
CONJ  Conjugué complexe.
    CONJ(Z) change le signe de la partie imaginaire. Le produit d'un
    nombre par son conjugué vaut le carré de son module.

    Syntaxe
       W = conj(Z)

    Exemples
       conj(3 + 4i)           % 3 - 4i
       conj([1+1i, 2-2i])     % 1-1i  2+2i
       (3+4i) * conj(3+4i)    % 25, soit abs(3+4i)^2

    Voir aussi REAL, IMAG, ABS, CTRANSPOSE.
```

## `cos`

```
COS  Cosinus, l'angle en radians.
    COS(X) rend le cosinus de chaque élément de X, l'angle étant compté
    en radians.

    Syntaxe
       Y = cos(X)

    Exemples
       cos(0)                 % 1
       cos(pi)                % -1
       cos([0 pi/3 pi])       % 1  0.5  -1
       cos(pi/2)              % 6.1e-17 : le zero exact n'est pas atteint

    Voir aussi SIN, TAN, ACOS, COSD, COSH.
```

## `cosd`

```
COSD  Cosinus, l'angle en degrés.
    COSD(X) rend le cosinus de X degrés, et exactement zéro aux multiples
    impairs de 90 degrés.

    Syntaxe
       Y = cosd(X)

    Exemples
       cosd(0)                % 1
       cosd(60)               % 0.5
       cosd(90)               % 0 exactement
       cosd([0 90 180])       % 1  0  -1

    Voir aussi COS, SIND, TAND, ACOSD.
```

## `cosh`

```
COSH  Cosinus hyperbolique.
    COSH(X) rend (exp(X) + exp(-X))/2. C'est la forme que prend une
    chaîne pesante suspendue par ses deux bouts — la chaînette.

    Syntaxe
       Y = cosh(X)

    Exemples
       cosh(0)                % 1
       cosh(1)                % 1.5431
       cosh(-2) == cosh(2)    % vrai : la fonction est paire
       abs(cosh(1)^2 - sinh(1)^2 - 1) < 1e-12   % l'identite fondamentale

    Voir aussi SINH, TANH, ACOSH, COS.
```

## `cot`

```
COT  Cotangente, l'angle en radians.
    COT(X) rend 1/TAN(X) : le rapport du cosinus au sinus.

    Syntaxe
       Y = cot(X)

    Exemples
       cot(pi/4)              % 1
       cot(pi/2)              % 6.1e-17, le zero au bruit pres
       abs(cot(pi/6) - sqrt(3)) < 1e-12   % vrai

    Voir aussi TAN, SEC, CSC, COTD, COTH.
```

## `cotd`

```
COTD  Cotangente, l'angle en degrés.
    COTD(X) rend 1/TAND(X).

    Syntaxe
       Y = cotd(X)

    Exemples
       cotd(45)               % 1
       cotd(90)               % 0
       abs(cotd(30) - sqrt(3)) < 1e-12    % vrai

    Voir aussi COT, TAND, SECD, CSCD.
```

## `coth`

```
COTH  Cotangente hyperbolique.
    COTH(X) rend 1/TANH(X). Elle n'est pas définie en zéro.

    Syntaxe
       Y = coth(X)

    Exemples
       coth(1)                % 1.3130
       abs(coth(1) - 1/tanh(1)) < 1e-12   % vrai
       coth(20)               % 1 au bruit pres

    Voir aussi TANH, SECH, CSCH, COT.
```

## `csc`

```
CSC  Cosécante, l'angle en radians.
    CSC(X) rend 1/SIN(X).

    Syntaxe
       Y = csc(X)

    Exemples
       csc(pi/2)              % 1
       csc(pi/6)              % 2
       abs(csc(pi/4) - sqrt(2)) < 1e-12   % vrai

    Voir aussi SIN, SEC, COT, CSCD, CSCH.
```

## `cscd`

```
CSCD  Cosécante, l'angle en degrés.
    CSCD(X) rend 1/SIND(X).

    Syntaxe
       Y = cscd(X)

    Exemples
       cscd(90)               % 1
       cscd(30)               % 2
       cscd(180)              % Inf

    Voir aussi CSC, SIND, SECD, COTD.
```

## `csch`

```
CSCH  Cosécante hyperbolique.
    CSCH(X) rend 1/SINH(X). Elle n'est pas définie en zéro.

    Syntaxe
       Y = csch(X)

    Exemples
       csch(1)                % 0.8509
       abs(csch(1) - 1/sinh(1)) < 1e-12   % vrai
       csch(-1) == -csch(1)   % vrai : la fonction est impaire

    Voir aussi SINH, SECH, COTH, CSC.
```

## `dec2bin`

```
DEC2BIN  Entier vers texte binaire.
    DEC2BIN(D) rend l'écriture binaire de D, dans une chaîne de
    caractères. DEC2BIN(D,N) la complète à gauche par des zéros pour
    atteindre N chiffres.

    Syntaxe
       S = dec2bin(D)
       S = dec2bin(D,N)

    Exemples
       dec2bin(10)            % '1010'
       dec2bin(5, 8)          % '00000101'
       dec2bin(0)             % '0'
       bin2dec(dec2bin(42))   % 42

    Voir aussi BIN2DEC, DEC2HEX, HEX2DEC, BITSHIFT.
```

## `dec2hex`

```
DEC2HEX  Entier vers texte hexadécimal.
    DEC2HEX(D) rend l'écriture hexadécimale de D, en majuscules.
    DEC2HEX(D,N) la complète à gauche par des zéros.

    Syntaxe
       S = dec2hex(D)
       S = dec2hex(D,N)

    Exemples
       dec2hex(255)           % 'FF'
       dec2hex(16, 4)         % '0010'
       dec2hex(0)             % '0'
       hex2dec(dec2hex(3735928559))   % 3735928559

    Voir aussi HEX2DEC, DEC2BIN, BIN2DEC.
```

## `deg2rad`

```
DEG2RAD  Degrés vers radians.
    DEG2RAD(X) rend X*pi/180.

    Syntaxe
       R = deg2rad(D)

    Exemples
       deg2rad(180)           % 3.1416
       deg2rad([0 90 180])    % 0  1.5708  3.1416
       abs(sin(deg2rad(30)) - 0.5) < 1e-15   % vrai

    Voir aussi RAD2DEG, SIND, COSD.
```

## `eq`

```
EQ  Égalité, sous forme de fonction.
    EQ(A,B) est ce qu'écrit A == B : un tableau de booléens, comparé
    élément par élément. Pour comparer des tableaux entiers, ISEQUAL est
    plus sûr — il compare aussi les tailles.

    Syntaxe
       T = eq(A,B)

    Exemples
       eq(3, 3)                   % vrai
       eq([1 2 3], [1 5 3])       % 1  0  1
       eq(NaN, NaN)               % faux : un NaN n'egale rien, pas meme lui

    Voir aussi NE, ISEQUAL, LT, GT, STRCMP.
```

## `erf`

```
ERF  Fonction d'erreur.
    ERF(X) rend (2/sqrt(pi)) * l'intégrale de exp(-t^2) de 0 à X. Elle va
    de -1 à 1 et sert partout où une loi normale intervient : la
    probabilité qu'une variable centrée réduite tombe dans [-a, a] vaut
    erf(a/sqrt(2)).

    Syntaxe
       Y = erf(X)

    Exemples
       erf(0)                 % 0
       erf(Inf)               % 1
       erf(1)                 % 0.8427
       abs(erf(1/sqrt(2)) - 0.682689492) < 1e-8   % les 68 % a un ecart-type

    Voir aussi ERFC, ERFINV, ERFCINV, NORMCDF.
```

## `erfc`

```
ERFC  Fonction d'erreur complémentaire.
    ERFC(X) rend 1 - ERF(X), mais sans la perte de précision de la
    soustraction quand X est grand : erfc(10) vaut 2e-45, que 1-erf(10)
    ne saurait donner.

    Syntaxe
       Y = erfc(X)

    Exemples
       erfc(0)                % 1
       erfc(Inf)              % 0
       erfc(10) > 0           % vrai, la ou 1 - erf(10) rend 0
       abs(erfc(1) + erf(1) - 1) < 1e-15    % vrai

    Voir aussi ERF, ERFCINV, ERFINV.
```

## `erfcinv`

```
ERFCINV  Réciproque de la fonction d'erreur complémentaire.
    ERFCINV(Y) rend le X tel que ERFC(X) = Y, pour Y dans ]0, 2[.

    Syntaxe
       X = erfcinv(Y)

    Exemples
       erfcinv(1)             % 0
       abs(erfcinv(erfc(0.4)) - 0.4) < 1e-10   % vrai
       erfcinv(0)             % Inf

    Voir aussi ERFC, ERF, ERFINV.
```

## `erfinv`

```
ERFINV  Réciproque de la fonction d'erreur.
    ERFINV(Y) rend le X tel que ERF(X) = Y, pour Y dans ]-1, 1[. Aux
    bornes, elle vaut ±Inf.

    Syntaxe
       X = erfinv(Y)

    Exemples
       erfinv(0)              % 0
       abs(erfinv(erf(0.7)) - 0.7) < 1e-10   % vrai
       erfinv(1)              % Inf
       sqrt(2) * erfinv(0.95)   % 1.96, le quantile a 95 % de la loi normale

    Voir aussi ERF, ERFC, ERFCINV, NORMINV.
```

## `exp`

```
EXP  Exponentielle.
    Y = EXP(X) rend e élevé à la puissance X, terme à terme. Pour un
    complexe, EXP(x+iy) = EXP(x)*(COS(y)+i*SIN(y)).

    Syntaxe
       Y = exp(X)

    Exemples

       exp(1)                     % 2.7183
       exp(1i*pi)                 % -1, aux arrondis près
       t = 0:0.1:5;  tau = 1.5;
       y = exp(-t/tau);           % décroissance

    Voir aussi LOG, EXPM1, POWER, EXPM.
```

## `expm1`

```
EXPM1  Exponentielle moins un, précise près de zéro.
    EXPM1(X) rend exp(X)-1 sans la perte de précision de la soustraction
    quand X est petit.

    Syntaxe
       Y = expm1(X)

    Exemples
       expm1(0)               % 0
       expm1(1e-16)           % 1e-16, la ou exp(1e-16)-1 rend 0
       abs(expm1(1) - (exp(1) - 1)) < 1e-15    % vrai

    Voir aussi EXP, LOG1P.
```

## `factor`

```
FACTOR  Décomposition en facteurs premiers.
    FACTOR(N) rend, en ordre croissant, les facteurs premiers de N,
    répétés autant de fois qu'ils divisent. Leur produit redonne N.

    Syntaxe
       F = factor(N)

    Exemples
       factor(12)             % 2  2  3
       factor(97)             % 97 : un nombre premier n'a que lui-meme
       prod(factor(360))      % 360
       numel(factor(1024))    % 10, soit 2^10

    Voir aussi PRIMES, ISPRIME, GCD, LCM.
```

## `factorial`

```
FACTORIAL  Factorielle.
    FACTORIAL(N) rend le produit des entiers de 1 à N. Au-delà de 170, le
    résultat dépasse ce qu'un flottant peut porter, et vaut Inf.

    Syntaxe
       F = factorial(N)

    Exemples
       factorial(5)           % 120
       factorial(0)           % 1, par convention
       factorial([3 4 5])     % 6  24  120
       factorial(171)         % Inf : au-dela de ce que porte un double

    Voir aussi NCHOOSEK, GAMMA, PROD, PERMS.
```

## `fix`

```
FIX  Arrondi vers zéro.
    FIX(X) retire la partie fractionnaire : c'est FLOOR pour les
    positifs, CEIL pour les négatifs. La partie entière et le reste
    gardent ainsi le même signe.

    Syntaxe
       Y = fix(X)

    Exemples
       fix(2.9)               % 2
       fix(-2.9)              % -2
       fix([2.7 -2.7])        % 2  -2
       fix(7/2)               % 3

    Voir aussi FLOOR, CEIL, ROUND, REM, IDIVIDE.
```

## `floor`

```
FLOOR  Arrondi vers le bas.
    FLOOR(X) rend le plus grand entier inférieur ou égal à X. Pour les
    négatifs, cela veut dire à l'opposé de zéro : floor(-2.5) vaut -3.

    Syntaxe
       Y = floor(X)

    Exemples
       floor(2.9)             % 2
       floor(-2.1)            % -3
       floor([1.8 -1.8 4])    % 1  -2  4
       floor(7/2)             % 3

    Voir aussi CEIL, ROUND, FIX, MOD.
```

## `gamma`

```
GAMMA  Fonction gamma d'Euler.
    GAMMA(X) prolonge la factorielle aux réels : gamma(n) vaut (n-1)!
    pour un entier positif. Elle a des pôles aux entiers négatifs ou nuls.

    Syntaxe
       Y = gamma(X)

    Exemples
       gamma(5)               % 24, soit 4!
       gamma(1)               % 1
       abs(gamma(0.5) - sqrt(pi)) < 1e-12    % vrai
       gamma(6) == factorial(5)              % vrai

    Voir aussi GAMMALN, GAMMAINC, FACTORIAL, BETA, PSI.
```

## `gammainc`

```
GAMMAINC  Fonction gamma incomplète, normalisée.
    GAMMAINC(X,A) rend la part de l'intégrale de la loi gamma accumulée
    jusqu'à X : une valeur entre 0 et 1. GAMMAINC(X,A,'upper') rend la
    part qui reste, soit 1 moins la précédente.

    Syntaxe
       P = gammainc(X,A)
       P = gammainc(X,A,'upper')

    Exemples
       gammainc(0, 1)         % 0
       gammainc(Inf, 2)       % 1
       abs(gammainc(1, 1) - (1 - exp(-1))) < 1e-12   % la loi exponentielle
       abs(gammainc(2, 3) + gammainc(2, 3, 'upper') - 1) < 1e-12

    Voir aussi GAMMA, GAMMALN, BETAINC, ERF.
```

## `gammaln`

```
GAMMALN  Logarithme de la fonction gamma.
    GAMMALN(X) rend log(gamma(X)) sans passer par gamma, qui déborde dès
    X = 172. C'est la forme à employer dans un calcul de probabilités.

    Syntaxe
       Y = gammaln(X)

    Exemples
       gammaln(1)             % 0
       abs(gammaln(5) - log(24)) < 1e-12     % vrai
       gammaln(1000) > 0      % vrai, la ou gamma(1000) rend Inf
       abs(gammaln(0.5) - log(sqrt(pi))) < 1e-12    % vrai

    Voir aussi GAMMA, GAMMAINC, BETALN, FACTORIAL.
```

## `gcd`

```
GCD  Plus grand commun diviseur.
    GCD(A,B) rend le plus grand entier qui divise A et B. [G,U,V] =
    GCD(A,B) rend en plus les coefficients de Bézout : U*A + V*B = G.

    Syntaxe
       G = gcd(A,B)
       [G,U,V] = gcd(A,B)

    Exemples
       gcd(12, 18)            % 6
       gcd(7, 13)             % 1 : deux nombres premiers entre eux
       gcd([12 15], [18 25])  % 6  5
       [g, u, v] = gcd(12, 18);
       u * 12 + v * 18        % 6, l'identite de Bezout

    Voir aussi LCM, FACTOR, MOD, REM.
```

## `ge`

```
GE  Supérieur ou égal, sous forme de fonction.
    GE(A,B) est ce qu'écrit A >= B.

    Syntaxe
       T = ge(A,B)

    Exemples
       ge(3, 3)                   % vrai
       ge([1 5 3], 3)             % 0  1  1
       all(ge([3 4 5], 3))        % vrai

    Voir aussi GT, LE, LT, EQ.
```

## `gt`

```
GT  Strictement supérieur, sous forme de fonction.
    GT(A,B) est ce qu'écrit A > B.

    Syntaxe
       T = gt(A,B)

    Exemples
       gt(4, 3)                   % vrai
       gt([1 5 3], 3)             % 0  1  0
       nnz(gt([1 5 3 8], 3))      % 2

    Voir aussi GE, LT, LE, FIND, MAX.
```

## `hex2dec`

```
HEX2DEC  Texte hexadécimal vers entier.
    HEX2DEC(S) lit une chaîne de chiffres hexadécimaux, majuscules ou
    minuscules, et rend l'entier qu'elle représente.

    Syntaxe
       D = hex2dec(S)

    Exemples
       hex2dec('FF')          % 255
       hex2dec('ff')          % 255 : la casse est indifferente
       hex2dec('10')          % 16
       hex2dec('DEADBEEF')    % 3735928559

    Voir aussi DEC2HEX, BIN2DEC, DEC2BIN.
```

## `hypot`

```
HYPOT  Hypoténuse, sans débordement.
    HYPOT(X,Y) rend sqrt(X^2 + Y^2) en évitant le débordement : le calcul
    direct échoue dès que X^2 dépasse le plus grand nombre représentable,
    alors que le résultat, lui, tient.

    Syntaxe
       C = hypot(A,B)

    Exemples
       hypot(3, 4)            % 5
       hypot(1e200, 1e200)    % 1.4142e200, la ou sqrt(x^2+y^2) rend Inf
       hypot([3 5], [4 12])   % 5  13

    Voir aussi ABS, NORM, SQRT.
```

## `idivide`

```
IDIVIDE  Division entière, avec la règle d'arrondi qu'on choisit.
    IDIVIDE(A,B,MODE) divise deux tableaux d'entiers en arrondissant
    comme MODE le demande : 'fix' vers zéro, 'floor' vers le bas, 'ceil'
    vers le haut, 'round' au plus proche. Sans MODE, c'est 'fix' —
    contrairement à A./B, qui arrondit au plus proche.

    Syntaxe
       C = idivide(A,B)
       C = idivide(A,B,mode)

    Exemples
       idivide(int32(7), int32(2))              % 3
       idivide(int32(7), int32(2), 'ceil')      % 4
       idivide(int32(-7), int32(2), 'floor')    % -4
       int32(7) / int32(2)                      % 4 : la division arrondit

    Voir aussi RDIVIDE, FIX, FLOOR, CEIL, MOD.
```

## `imag`

```
IMAG  Partie imaginaire.
    IMAG(Z) rend la partie imaginaire de chaque élément : un nombre réel,
    sans le i.

    Syntaxe
       Y = imag(Z)

    Exemples
       imag(3 + 4i)           % 4
       imag([1+2i, 5])        % 2  0
       imag(1i)               % 1

    Voir aussi REAL, CONJ, ABS, ANGLE.
```

## `isfinite`

```
ISFINITE  Vrai pour les valeurs finies.
    ISFINITE(X) rend un tableau de booléens, vrai là où l'élément n'est
    ni infini ni NaN.

    Syntaxe
       T = isfinite(X)

    Exemples
       isfinite([1 Inf NaN -Inf])   % 1  0  0  0
       all(isfinite([1 2 3]))       % vrai
       sum(isfinite([1 NaN 3]))     % 2

    Voir aussi ISINF, ISNAN, ISREAL, RMMISSING.
```

## `isinf`

```
ISINF  Vrai pour les infinis.
    ISINF(X) rend un tableau de booléens, vrai là où l'élément vaut +Inf
    ou -Inf. Un NaN n'est pas un infini.

    Syntaxe
       T = isinf(X)

    Exemples
       isinf([1 Inf NaN -Inf])      % 0  1  0  1
       isinf(1/0)                   % vrai
       any(isinf([1 2 3]))          % faux

    Voir aussi ISFINITE, ISNAN, INF.
```

## `isnan`

```
ISNAN  Vrai pour les « pas un nombre ».
    ISNAN(X) rend un tableau de booléens, vrai là où l'élément est NaN.
    C'est le seul moyen de les reconnaître : NaN == NaN est faux, par
    définition de la norme des flottants.

    Syntaxe
       T = isnan(X)

    Exemples
       isnan([1 NaN 3])       % 0  1  0
       NaN == NaN             % faux : d'ou l'utilite d'isnan
       isnan(0/0)             % vrai
       sum(isnan([1 NaN NaN]))    % 2

    Voir aussi ISFINITE, ISINF, NAN, RMMISSING, ISMISSING.
```

## `isprime`

```
ISPRIME  Vrai pour les nombres premiers.
    ISPRIME(X) rend un tableau de booléens, vrai là où l'élément est un
    entier premier. Les valeurs doivent être des entiers positifs.

    Syntaxe
       T = isprime(X)

    Exemples
       isprime(7)             % vrai
       isprime([1 2 3 4 9])   % 0  1  1  0  0
       sum(isprime(1:20))     % 8 : il y a huit premiers jusqu'a 20

    Voir aussi PRIMES, FACTOR, GCD, NCHOOSEK.
```

## `lcm`

```
LCM  Plus petit commun multiple.
    LCM(A,B) rend le plus petit entier positif que divisent à la fois A
    et B. Il vaut A*B/GCD(A,B).

    Syntaxe
       L = lcm(A,B)

    Exemples
       lcm(4, 6)              % 12
       lcm(3, 5)              % 15
       lcm([4 6], [6 8])      % 12  24
       lcm(12, 18) * gcd(12, 18) == 12 * 18    % vrai

    Voir aussi GCD, FACTOR, MOD.
```

## `ldivide`

```
LDIVIDE  Division élément par élément à gauche, sous forme de fonction.
    LDIVIDE(A,B) est ce qu'écrit A .\ B, c'est-à-dire B ./ A. La forme à
    gauche existe surtout pour sa version matricielle, MLDIVIDE, qui
    résout un système linéaire.

    Syntaxe
       C = ldivide(A,B)

    Exemples
       ldivide(2, [10 20])        % 5  10
       ldivide([1 2], [10 20])    % 10  10
       isequal(ldivide(2, 8), rdivide(8, 2))    % vrai

    Voir aussi RDIVIDE, MLDIVIDE, TIMES.
```

## `le`

```
LE  Inférieur ou égal, sous forme de fonction.
    LE(A,B) est ce qu'écrit A <= B.

    Syntaxe
       T = le(A,B)

    Exemples
       le(3, 3)                   % vrai
       le([1 5 3], 3)             % 1  0  1
       all(le([1 2 3], [1 2 3]))  % vrai

    Voir aussi LT, GE, GT, EQ.
```

## `log`

```
LOG  Logarithme népérien.
    Y = LOG(X) rend le logarithme de base e. Pour un X négatif réel, le
    résultat est complexe.

    Syntaxe
       Y = log(X)

    Exemples

       log(exp(2))                % 2
       log(-1)                    % 0 + 3.1416i
       H = [1 0.5 0.25];
       dB = 20*log10(abs(H));     % pour des décibels, log10

    Voir aussi LOG2, LOG10, LOG1P, EXP, REALLOG.
```

## `log10`

```
LOG10  Logarithme décimal.
    LOG10(X) rend le logarithme en base dix. Un argument négatif donne un
    résultat complexe, comme dans MATLAB.

    Syntaxe
       Y = log10(X)

    Exemples
       log10(100)             % 2
       log10(1)               % 0
       log10([1 10 1000])     % 0  1  3
       log10(0)               % -Inf

    Voir aussi LOG, LOG2, EXP, SEMILOGX.
```

## `log1p`

```
LOG1P  Logarithme de 1+X, précis près de zéro.
    LOG1P(X) rend log(1+X) sans perdre les chiffres significatifs quand X
    est petit : log(1+1e-16) rend zéro, log1p(1e-16) rend 1e-16.

    Syntaxe
       Y = log1p(X)

    Exemples
       log1p(0)               % 0
       log1p(1e-16)           % 1e-16, la ou log(1+1e-16) rend 0
       abs(log1p(1) - log(2)) < 1e-15    % vrai

    Voir aussi LOG, EXPM1, LOG10.
```

## `log2`

```
LOG2  Logarithme binaire.
    LOG2(X) rend le logarithme en base deux. [F,E] = LOG2(X) rend la
    forme normalisée d'un nombre en virgule flottante : X = F*2^E avec F
    dans [0.5, 1).

    Syntaxe
       Y = log2(X)
       [F,E] = log2(X)

    Exemples
       log2(8)                % 3
       log2(1024)             % 10
       [f, e] = log2(8);
       f * 2^e                % 8 : la decomposition redonne le nombre

    Voir aussi LOG, LOG10, POW2, NEXTPOW2.
```

## `lt`

```
LT  Strictement inférieur, sous forme de fonction.
    LT(A,B) est ce qu'écrit A < B.

    Syntaxe
       T = lt(A,B)

    Exemples
       lt(2, 3)                   % vrai
       lt([1 5 3], 3)             % 1  0  0
       sum(lt(rand(1, 10), 2))    % 10 : tous les tirages sont sous 2

    Voir aussi LE, GT, GE, SORT, FIND.
```

## `minus`

```
MINUS  Soustraction, sous forme de fonction.
    MINUS(A,B) est ce qu'écrit A - B.

    Syntaxe
       C = minus(A,B)

    Exemples
       minus(5, 3)            % 2
       minus([10 20], [1 2])  % 9  18
       minus(10, [1 2 3])     % 9  8  7

    Voir aussi PLUS, UMINUS, TIMES, DIFF.
```

## `mldivide`

```
MLDIVIDE  Division à gauche, « A\b » : résout A*x = b.
    X = A\B résout le système A*X = B. Pour une matrice carrée, la
    factorisation adaptée est choisie ; pour une matrice rectangulaire,
    la solution est celle des moindres carrés.

    C'est la façon d'inverser un système : plus rapide et plus précise
    que INV(A)*B.

    Syntaxe
       X = A\B
       X = mldivide(A,B)

    Exemples

       A = [2 1; 1 3];  b = [3; 5];
       x = A \ b;                 % [0.8; 1.4]
       X = [ones(10,1) (1:10)'];  y = (1:10)' * 2 + 1;
       p = X \ y;                 % régression aux moindres carrés

    Voir aussi MRDIVIDE, INV, LU, QR, PINV, LSQMINNORM.
```

## `mod`

```
MOD  Reste de la division, du signe du diviseur.
    M = MOD(X,Y) rend X - FLOOR(X./Y).*Y. Le résultat a le signe de Y.
    MOD(X,0) rend X.

    MOD et REM diffèrent quand les signes diffèrent : MOD(-1,3) vaut 2,
    REM(-1,3) vaut -1.

    Syntaxe
       M = mod(a,m)

    Exemples

       mod(7,3)                   % 1
       mod(-1,3)                  % 2
       k = 5;  n = 4;
       mod(k-1, n) + 1            % indice cyclique de 1 à n

    Voir aussi REM, IDIVIDE, FLOOR.
```

## `mpower`

```
MPOWER  Puissance matricielle, sous forme de fonction.
    MPOWER(A,N) est ce qu'écrit A ^ N. Pour une matrice carrée et un
    entier N, c'est le produit matriciel répété ; pour un scalaire, la
    puissance ordinaire.

    Syntaxe
       C = mpower(A,N)

    Exemples
       mpower(2, 10)              % 1024
       mpower([1 1; 0 1], 3)      % [1 3; 0 1]
       isequal(mpower([2 0; 0 3], 2), [4 0; 0 9])   % vrai

    Voir aussi POWER, MTIMES, EXPM, SQRTM.
```

## `mrdivide`

```
MRDIVIDE  Division matricielle à droite, sous forme de fonction.
    MRDIVIDE(A,B) est ce qu'écrit A / B : la solution X de X*B = A. Pour
    un scalaire, c'est la division ordinaire.

    Syntaxe
       C = mrdivide(A,B)

    Exemples
       mrdivide(6, 3)             % 2
       mrdivide([2 4], 2)         % 1  2
       X = mrdivide([1 2], [1 0; 0 2]);
       max(abs(X * [1 0; 0 2] - [1 2])) < 1e-12    % vrai

    Voir aussi MLDIVIDE, RDIVIDE, INV, LINSOLVE.
```

## `mtimes`

```
MTIMES  Produit matriciel, sous forme de fonction.
    MTIMES(A,B) est ce qu'écrit A * B : le produit des matrices, qui
    demande que A ait autant de colonnes que B a de lignes. Un scalaire
    multiplie tout.

    Syntaxe
       C = mtimes(A,B)

    Exemples
       mtimes([1 2; 3 4], [1; 1])     % [3; 7]
       mtimes(2, [1 2 3])             % 2  4  6
       mtimes([1 2], [3; 4])          % 11, le produit scalaire

    Voir aussi TIMES, MRDIVIDE, MPOWER, DOT, CROSS.
```

## `nchoosek`

```
NCHOOSEK  Coefficient binomial, ou combinaisons.
    NCHOOSEK(N,K) rend le nombre de façons de choisir K éléments parmi N,
    quand N est un scalaire. NCHOOSEK(V,K), avec V un vecteur, rend
    toutes ces combinaisons, une par ligne.

    Syntaxe
       C = nchoosek(N,K)
       C = nchoosek(V,K)

    Exemples
       nchoosek(5, 2)         % 10
       nchoosek(6, 0)         % 1
       nchoosek([1 2 3], 2)   % [1 2; 1 3; 2 3]
       size(nchoosek(1:5, 3)) % 10  3

    Voir aussi FACTORIAL, PERMS, COMBNK.
```

## `ne`

```
NE  Différence, sous forme de fonction.
    NE(A,B) est ce qu'écrit A ~= B.

    Syntaxe
       T = ne(A,B)

    Exemples
       ne(3, 4)                   % vrai
       ne([1 2 3], [1 5 3])       % 0  1  0
       ne(NaN, NaN)               % vrai

    Voir aussi EQ, ISEQUAL, NOT.
```

## `not`

```
NOT  Négation logique, sous forme de fonction.
    NOT(A) est ce qu'écrit ~A : vrai là où A est nul.

    Syntaxe
       T = not(A)
    
    Exemples
       not(false)                 % vrai
       not([1 0 3])               % 0  1  0
       isequal(not(not([1 0])), logical([1 0]))   % vrai

    Voir aussi AND, OR, XOR, ANY, ALL.
```

## `nthroot`

```
NTHROOT  Racine n-ième réelle.
    NTHROOT(X,N) rend la racine n-ième réelle de X. Contrairement à
    X^(1/N), qui rend la racine complexe de plus petit argument, elle
    accepte un X négatif quand N est impair.

    Syntaxe
       Y = nthroot(X,N)

    Exemples
       nthroot(27, 3)         % 3
       nthroot(-8, 3)         % -2, la ou (-8)^(1/3) rend 1 + 1.7321i
       nthroot(16, 4)         % 2
       nthroot([8 27], 3)     % 2  3

    Voir aussi SQRT, POWER, REALSQRT, CBRT.
```

## `or`

```
OR  Ou logique, sous forme de fonction.
    OR(A,B) est ce qu'écrit A | B : vrai là où l'un au moins est non nul.

    Syntaxe
       T = or(A,B)

    Exemples
       or(true, false)            % vrai
       or([1 0 0], [0 1 0])       % 1  1  0
       any(or([0 0], [0 1]))      % vrai

    Voir aussi AND, NOT, XOR, ANY.
```

## `plus`

```
PLUS  Addition, sous forme de fonction.
    PLUS(A,B) est ce qu'écrit A + B. Les deux termes doivent avoir la
    même taille, ou l'un des deux être un scalaire ; les tailles se
    complètent aussi par diffusion, une ligne contre une colonne donnant
    une matrice.

    Écrire l'opérateur sous forme de fonction sert à le passer à une
    autre : ARRAYFUN, CELLFUN, ACCUMARRAY en prennent volontiers.

    Syntaxe
       C = plus(A,B)

    Exemples
       plus(2, 3)             % 5
       plus([1 2], [10 20])   % 11  22
       plus([1 2 3], 10)      % 11  12  13
       plus([1; 2], [10 20])  % diffusion : matrice 2x2

    Voir aussi MINUS, TIMES, SUM, BSXFUN.
```

## `power`

```
POWER  Puissance élément par élément, sous forme de fonction.
    POWER(A,B) est ce qu'écrit A .^ B.

    Syntaxe
       C = power(A,B)

    Exemples
       power([1 2 3], 2)          % 1  4  9
       power(2, [1 2 3])          % 2  4  8
       power([1 2; 3 4], 0)       % que des uns

    Voir aussi MPOWER, TIMES, EXP, NTHROOT.
```

## `primes`

```
PRIMES  Les nombres premiers jusqu'à N.
    PRIMES(N) rend, en ligne, tous les nombres premiers inférieurs ou
    égaux à N. Le calcul passe par le crible d'Ératosthène.

    Syntaxe
       P = primes(N)

    Exemples
       primes(20)             % 2  3  5  7  11  13  17  19
       numel(primes(100))     % 25
       max(primes(50))        % 47

    Voir aussi ISPRIME, FACTOR, NCHOOSEK.
```

## `psi`

```
PSI  Fonction digamma, dérivée logarithmique de gamma.
    PSI(X) rend la dérivée de log(gamma(X)). PSI(K,X) rend la K-ième
    dérivée : la polygamma d'ordre K.

    Syntaxe
       Y = psi(X)
       Y = psi(K,X)

    Exemples
       abs(psi(1) + 0.5772156649) < 1e-8     % l'oppose de la constante d'Euler
       abs(psi(2) - (1 - 0.5772156649)) < 1e-8
       psi(1, 1) > 0          % la trigamma est positive

    Voir aussi GAMMA, GAMMALN.
```

## `rad2deg`

```
RAD2DEG  Radians vers degrés.
    RAD2DEG(X) rend X*180/pi.

    Syntaxe
       D = rad2deg(R)

    Exemples
       rad2deg(pi)            % 180
       rad2deg(pi/2)          % 90
       rad2deg(atan(1))       % 45

    Voir aussi DEG2RAD, ATAND, ANGLE.
```

## `rdivide`

```
RDIVIDE  Division élément par élément, sous forme de fonction.
    RDIVIDE(A,B) est ce qu'écrit A ./ B.

    Syntaxe
       C = rdivide(A,B)

    Exemples
       rdivide([10 20], [2 5])    % 5  4
       rdivide([1 2 3], 2)        % 0.5  1  1.5
       rdivide(1, 0)              % Inf

    Voir aussi LDIVIDE, MRDIVIDE, TIMES, IDIVIDE.
```

## `real`

```
REAL  Partie réelle.
    REAL(Z) rend la partie réelle de chaque élément.

    Syntaxe
       X = real(Z)

    Exemples
       real(3 + 4i)           % 3
       real([1+2i, 5])        % 1  5
       real(exp(1i*pi))       % -1

    Voir aussi IMAG, CONJ, ABS, ANGLE, COMPLEX.
```

## `rem`

```
REM  Reste de la division, du signe du dividende.
    R = REM(X,Y) rend X - FIX(X./Y).*Y. Le résultat a le signe de X.

    Syntaxe
       R = rem(a,b)

    Exemples
       rem(7,3)                   % 1
       rem(-1,3)                  % -1

    Voir aussi MOD, FIX, IDIVIDE.
```

## `round`

```
ROUND  Arrondit au plus proche.
    Y = ROUND(X) arrondit à l'entier le plus proche, les demis s'éloignant
    de zéro.
    Y = ROUND(X,N) arrondit à N décimales.

    Syntaxe
       Y = round(X)
       Y = round(X,n)

    Exemples
       round(2.5)                 % 3
       round(-2.5)                % -3
       round(pi, 2)               % 3.14

    Voir aussi FLOOR, CEIL, FIX.
```

## `sec`

```
SEC  Sécante, l'angle en radians.
    SEC(X) rend 1/COS(X).

    Syntaxe
       Y = sec(X)

    Exemples
       sec(0)                 % 1
       sec(pi/3)              % 2
       abs(sec(pi/4) - sqrt(2)) < 1e-12   % vrai

    Voir aussi COS, CSC, COT, SECD, SECH.
```

## `secd`

```
SECD  Sécante, l'angle en degrés.
    SECD(X) rend 1/COSD(X).

    Syntaxe
       Y = secd(X)

    Exemples
       secd(0)                % 1
       secd(60)               % 2
       secd(90)               % Inf

    Voir aussi SEC, COSD, CSCD, COTD.
```

## `sech`

```
SECH  Sécante hyperbolique.
    SECH(X) rend 1/COSH(X). Elle vaut 1 en zéro et décroît vers zéro des
    deux côtés : c'est la forme du soliton.

    Syntaxe
       Y = sech(X)

    Exemples
       sech(0)                % 1
       sech(1)                % 0.6481
       sech(-1) == sech(1)    % vrai

    Voir aussi COSH, CSCH, COTH, SEC.
```

## `sign`

```
SIGN  Signe d'un nombre.
    SIGN(X) rend 1 pour X > 0, -1 pour X < 0, et 0 pour X nul. Pour un
    complexe, elle rend X/ABS(X) : le nombre ramené sur le cercle unité.

    Syntaxe
       Y = sign(X)

    Exemples
       sign(-3.2)             % -1
       sign([2 0 -5])         % 1  0  -1
       sign(0)                % 0
       abs(sign(3 + 4i) - (0.6 + 0.8i)) < 1e-15    % vrai

    Voir aussi ABS, SIGNUM, MAX, MIN.
```

## `sin`

```
SIN  Sinus, l'angle en radians.
    SIN(X) rend le sinus de chaque élément de X, l'angle étant compté en
    radians. Pour un argument complexe, la fonction est prolongée par
    sin(a+bi) = sin(a)cosh(b) + i cos(a)sinh(b).

    Syntaxe
       Y = sin(X)

    Exemples
       sin(0)                 % 0
       sin(pi/2)              % 1
       sin([0 pi/6 pi/2])     % 0  0.5  1
       t = linspace(0, 2*pi, 5);
       max(sin(t))            % 1

    Voir aussi COS, TAN, ASIN, SIND, SINH, DEG2RAD.
```

## `sinc`

```
SINC  Sinus cardinal.
    SINC(X) rend sin(pi*X)/(pi*X), et 1 en zéro. C'est la réponse
    impulsionnelle du filtre passe-bas idéal, et la transformée de
    Fourier d'une fenêtre rectangulaire.

    Syntaxe
       Y = sinc(X)

    Exemples
       sinc(0)                % 1
       sinc(1)                % 0 : la fonction s'annule aux entiers
       sinc([0 1 2 0.5])      % 1  0  0  0.6366
       abs(sinc(0.5) - 2/pi) < 1e-12    % vrai

    Voir aussi SIN, FFT, FIR1.
```

## `sind`

```
SIND  Sinus, l'angle en degrés.
    SIND(X) rend le sinus de X degrés. Contrairement à SIN(X*pi/180),
    la fonction rend exactement zéro aux multiples de 180 degrés : c'est
    tout l'intérêt des variantes en degrés.

    Syntaxe
       Y = sind(X)

    Exemples
       sind(0)                % 0
       sind(30)               % 0.5
       sind(180)              % 0 exactement, la ou sin(pi) vaut 1.2e-16
       sind([0 90 180 270])   % 0  1  0  -1

    Voir aussi SIN, COSD, TAND, ASIND, DEG2RAD.
```

## `sinh`

```
SINH  Sinus hyperbolique.
    SINH(X) rend (exp(X) - exp(-X))/2.

    Syntaxe
       Y = sinh(X)

    Exemples
       sinh(0)                % 0
       sinh(1)                % 1.1752
       abs(sinh(1) - (exp(1) - exp(-1))/2) < 1e-15   % vrai
       sinh(-2) == -sinh(2)   % vrai : la fonction est impaire

    Voir aussi COSH, TANH, ASINH, SIN.
```

## `sqrt`

```
SQRT  Racine carrée.
    Y = SQRT(X) rend la racine carrée de X. Pour un X négatif réel, le
    résultat est complexe.

    Syntaxe
       Y = sqrt(X)

    Exemples
       sqrt(16)                   % 4
       sqrt(-4)                   % 0 + 2i
       sqrt([1 4 9])              % [1 2 3]

    Voir aussi NTHROOT, REALSQRT, EXP, POWER.
```

## `tan`

```
TAN  Tangente, l'angle en radians.
    TAN(X) rend la tangente, c'est-à-dire SIN(X)/COS(X). Elle n'est pas
    définie aux multiples impairs de pi/2, où le calcul rend un très
    grand nombre plutôt qu'un infini : pi/2 n'est pas représentable
    exactement en virgule flottante.

    Syntaxe
       Y = tan(X)

    Exemples
       tan(0)                 % 0
       tan(pi/4)              % 1
       tan([0 pi/6 pi/4])     % 0  0.5774  1

    Voir aussi SIN, COS, ATAN, ATAN2, TAND, TANH.
```

## `tand`

```
TAND  Tangente, l'angle en degrés.
    TAND(X) rend la tangente de X degrés. Aux multiples impairs de 90
    degrés, où la tangente n'existe pas, elle rend Inf — ce que TAN ne
    peut pas faire, faute de pouvoir représenter pi/2 exactement.

    Syntaxe
       Y = tand(X)

    Exemples
       tand(45)               % 1
       tand(0)                % 0
       tand(90)               % Inf
       abs(tand(60) - sqrt(3)) < 1e-12    % vrai

    Voir aussi TAN, SIND, COSD, ATAND, ATAN2D.
```

## `tanh`

```
TANH  Tangente hyperbolique.
    TANH(X) rend SINH(X)/COSH(X), c'est-à-dire une valeur dans ]-1, 1[
    qui tend vers ±1 aux grands arguments. C'est la fonction d'activation
    classique des réseaux de neurones.

    Syntaxe
       Y = tanh(X)

    Exemples
       tanh(0)                % 0
       tanh(1)                % 0.7616
       tanh(20)               % 1 au bruit pres
       all(abs(tanh([-3 0 3])) <= 1)    % vrai

    Voir aussi SINH, COSH, ATANH, TAN.
```

## `times`

```
TIMES  Multiplication élément par élément, sous forme de fonction.
    TIMES(A,B) est ce qu'écrit A .* B : chaque élément multiplié par
    celui d'en face, sans produit matriciel.

    Syntaxe
       C = times(A,B)

    Exemples
       times([1 2 3], [4 5 6])    % 4  10  18
       times([1 2], 10)           % 10  20
       times([1 2; 3 4], [1 0; 0 1])  % [1 0; 0 4], non le produit matriciel

    Voir aussi MTIMES, RDIVIDE, POWER, PROD.
```

## `uminus`

```
UMINUS  Opposé, sous forme de fonction.
    UMINUS(A) est ce qu'écrit -A.

    Syntaxe
       C = uminus(A)

    Exemples
       uminus(3)              % -3
       uminus([1 -2 3])       % -1  2  -3
       uminus(uminus(7))      % 7

    Voir aussi UPLUS, MINUS, ABS, SIGN.
```

## `uplus`

```
UPLUS  Plus unaire, sous forme de fonction.
    UPLUS(A) est ce qu'écrit +A : la valeur elle-même. La fonction existe
    pour que les classes puissent la redéfinir, et pour la symétrie avec
    UMINUS.

    Syntaxe
       C = uplus(A)

    Exemples
       uplus(3)               % 3
       uplus([1 -2])          % 1  -2
       isequal(uplus([1 2]), [1 2])   % vrai

    Voir aussi UMINUS, PLUS.
```

## `xor`

```
XOR  Ou exclusif logique.
    XOR(A,B) rend vrai là où l'un des deux est vrai, mais pas les deux.
    À ne pas confondre avec BITXOR, qui travaille bit à bit sur des
    entiers.

    Syntaxe
       T = xor(A,B)

    Exemples
       xor(true, false)           % vrai
       xor(true, true)            % faux
       xor([1 0 1 0], [1 1 0 0])  % 0  1  1  0

    Voir aussi AND, OR, NOT, BITXOR.
```

