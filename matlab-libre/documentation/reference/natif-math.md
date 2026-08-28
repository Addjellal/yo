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
       abs(fft(x))                % spectre d'amplitude

    Voir aussi SIGN, ANGLE, REAL, IMAG, HYPOT.
```

## `acos`

```
acos  Arc cosinus.
```

## `acosd`

```
acosd  Arc cosinus, en degres.
```

## `acosh`

```
acosh  Arc cosinus hyperbolique.
```

## `and`

```
and  Et logique.
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
       unwrap(angle(fft(x)))      % phase déroulée d'un spectre

    Voir aussi ABS, UNWRAP, REAL, IMAG, ATAN2.
```

## `arg`

```
arg  Argument d'un complexe.
```

## `asin`

```
asin  Arc sinus.
```

## `asind`

```
asind  Arc sinus, en degres.
```

## `asinh`

```
asinh  Arc sinus hyperbolique.
```

## `atan`

```
atan  Arc tangente.
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
       angle = atan2(dy, dx);

    Voir aussi ATAN, ANGLE, HYPOT, CART2POL.
```

## `atan2d`

```
atan2d  Arc tangente a quatre quadrants, en degres.
```

## `atand`

```
atand  Arc tangente, en degres.
```

## `atanh`

```
atanh  Arc tangente hyperbolique.
```

## `besselj`

```
besselj  Bessel de premiere espece.
```

## `bessely`

```
bessely  Bessel de seconde espece.
```

## `beta`

```
beta  Fonction beta.
```

## `betainc`

```
betainc  Fonction beta incomplete regularisee.
```

## `betaln`

```
betaln  Logarithme de la fonction beta.
```

## `bin2dec`

```
bin2dec  Chaine binaire vers entier.
```

## `bitand`

```
bitand  Et binaire.
```

## `bitcmp`

```
bitcmp  Complement binaire.
```

## `bitor`

```
bitor  Ou binaire.
```

## `bitshift`

```
bitshift  Decalage binaire.
```

## `bitxor`

```
bitxor  Ou exclusif binaire.
```

## `ceil`

```
ceil  Arrondi vers plus l'infini.
```

## `conj`

```
conj  Conjugue complexe.
```

## `cos`

```
cos  Cosinus (radians).
```

## `cosd`

```
cosd  Cosinus en degres.
```

## `cosh`

```
cosh  Cosinus hyperbolique.
```

## `cot`

```
cot  Cotangente.
```

## `cotd`

```
cotd  Cotangente en degres.
```

## `coth`

```
coth  Cotangente hyperbolique.
```

## `csc`

```
csc  Cosecante.
```

## `cscd`

```
cscd  Cosecante en degres.
```

## `csch`

```
csch  Cosecante hyperbolique.
```

## `dec2bin`

```
dec2bin  Entier vers chaine binaire.
```

## `dec2hex`

```
dec2hex  Entier vers chaine hexadecimale.
```

## `deg2rad`

```
deg2rad  Degres vers radians.
```

## `eq`

```
eq  Egalite.
```

## `erf`

```
erf  Fonction d'erreur.
```

## `erfc`

```
erfc  Fonction d'erreur complementaire.
```

## `erfcinv`

```
erfcinv  Reciproque de erfc.
```

## `erfinv`

```
erfinv  Reciproque de erf.
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
       y = exp(-t/tau);           % décroissance

    Voir aussi LOG, EXPM1, POWER, EXPM.
```

## `expm1`

```
expm1  exp(x)-1, precis pres de zero.
```

## `factor`

```
factor  Decomposition en facteurs premiers.
```

## `factorial`

```
factorial  Factorielle.
```

## `fix`

```
fix  Arrondi vers zero.
```

## `floor`

```
floor  Arrondi vers moins l'infini.
```

## `gamma`

```
gamma  Fonction gamma.
```

## `gammainc`

```
gammainc  Fonction gamma incomplete regularisee.
```

## `gammaln`

```
gammaln  Logarithme de la fonction gamma.
```

## `gcd`

```
gcd  Plus grand commun diviseur.
```

## `ge`

```
ge  Superieur ou egal.
```

## `gt`

```
gt  Strictement superieur.
```

## `hex2dec`

```
hex2dec  Chaine hexadecimale vers entier.
```

## `hypot`

```
hypot  sqrt(a^2+b^2) sans debordement.
```

## `idivide`

```
idivide  Division entiere avec mode d'arrondi.
```

## `imag`

```
imag  Partie imaginaire.
```

## `isfinite`

```
isfinite  Vrai pour les valeurs finies.
```

## `isinf`

```
isinf  Vrai pour les infinis.
```

## `isnan`

```
isnan  Vrai pour les NaN.
```

## `isprime`

```
isprime  Test de primalite.
```

## `lcm`

```
lcm  Plus petit commun multiple.
```

## `ldivide`

```
ldivide  Division a gauche element par element.
```

## `le`

```
le  Inferieur ou egal.
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
       dB = 20*log10(abs(H));     % pour des décibels, log10

    Voir aussi LOG2, LOG10, LOG1P, EXP, REALLOG.
```

## `log10`

```
log10  Logarithme decimal.
```

## `log1p`

```
log1p  log(1+x), precis pres de zero.
```

## `log2`

```
log2  Logarithme en base 2.
```

## `lt`

```
lt  Strictement inferieur.
```

## `minus`

```
minus  Soustraction.
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
       mod(k-1, n) + 1            % indice cyclique de 1 à n

    Voir aussi REM, IDIVIDE, FLOOR.
```

## `mpower`

```
mpower  Puissance matricielle.
```

## `mrdivide`

```
mrdivide  Division matricielle a droite.
```

## `mtimes`

```
mtimes  Produit matriciel.
```

## `nchoosek`

```
nchoosek  Coefficient binomial ou combinaisons.
```

## `ne`

```
ne  Difference.
```

## `not`

```
not  Negation logique.
```

## `nthroot`

```
nthroot  Racine n-ieme reelle.
```

## `or`

```
or  Ou logique.
```

## `plus`

```
plus  Addition.
```

## `power`

```
power  Puissance element par element.
```

## `primes`

```
primes  Nombres premiers jusqu'a n.
```

## `psi`

```
psi  Fonction digamma et polygamma.
```

## `rad2deg`

```
rad2deg  Radians vers degres.
```

## `rdivide`

```
rdivide  Division a droite element par element.
```

## `real`

```
real  Partie reelle.
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
sec  Secante.
```

## `secd`

```
secd  Secante en degres.
```

## `sech`

```
sech  Secante hyperbolique.
```

## `sign`

```
sign  Signe : -1, 0 ou 1.
```

## `sin`

```
sin  Sinus (radians).
```

## `sinc`

```
sinc  sin(pi x)/(pi x).
```

## `sind`

```
sind  Sinus en degres.
```

## `sinh`

```
sinh  Sinus hyperbolique.
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
tan  Tangente (radians).
```

## `tand`

```
tand  Tangente en degres.
```

## `tanh`

```
tanh  Tangente hyperbolique.
```

## `times`

```
times  Produit element par element.
```

## `uminus`

```
uminus  Moins unaire.
```

## `uplus`

```
uplus  Plus unaire.
```

## `xor`

```
xor  Ou exclusif.
```

