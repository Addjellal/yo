# Toolbox `virgule-fixe`

```
% Fixed-Point Designer — nombres à virgule fixe.
%
% Un nombre à virgule fixe est un entier stocké sur W bits, signé ou non,
% et une échelle : il vaut son entier fois la pente, plus le biais — la
% pente 2^-F pour F bits après la virgule. Une valeur y est arrondie et
% ramenée dans les bornes du type ; les calculs suivent des règles
% (FIMATH) : en pleine précision, rien ne se perd, la taille grandit.
%
% Objets
%   fi                 - Un nombre, ou un tableau, à virgule fixe
%   numerictype        - Le type : signe, taille, échelle
%   fimath             - Les règles de calcul : arrondi, débordement, tailles
%   fixdt              - Un type de données pour Simulink (Simulink.NumericType)
%
% Calculs
%   divide             - Le quotient, dans un type donné
%   (et, sur un FI : +, -, .*, *, .^, abs, sum, max, min, comparaisons,
%   upperbound, lowerbound, range, eps, storedInteger, bin, hex, dec, oct)
%
% Tests
%   isfi               - Vrai pour un FI
%   isnumerictype      - Vrai pour un NUMERICTYPE
%   isfimath           - Vrai pour un FIMATH
%
% Les entiers stockés sont des doubles : au-delà de 53 bits, les derniers
% se perdent. Les échelles qui ne sont pas des puissances de deux
% calculent sur les valeurs et rangent le résultat dans le type du
% premier opérande.
```

## `divide`

```
DIVIDE Le quotient de deux nombres à virgule fixe, dans le type T.
  C = DIVIDE(T,A,B) divise A par B, terme à terme, et range le quotient
  dans le type T (NUMERICTYPE), selon les règles de calcul de A — ou de
  B, s'il est seul à en porter. A et B sont des FI ou des doubles.

  Exemple :
     c = divide(numerictype(1, 16, 12), fi(1), fi(3))    % 0.3333

  Voir aussi FI, NUMERICTYPE.
```

## `fi`

```
FI Un nombre, ou un tableau, à virgule fixe.
  A = FI(V) range les valeurs V en virgule fixe : signées, sur des mots
  de 16 bits, avec autant de bits après la virgule que la plus grande
  valeur en laisse — la meilleure précision. FI(pi) garde 13 bits après
  la virgule ; un entier de MATLAB garde son type (int8 : 8 bits, sans
  virgule).
  A = FI(V,S), FI(V,S,W) : signé ou non (S vrai ou faux), sur W bits, en
  meilleure précision.
  A = FI(V,S,W,F) : F bits après la virgule — une valeur vaut son entier
  stocké fois 2^-F.
  A = FI(V,S,W,PENTE,BIAIS) et FI(V,S,W,AJUSTEMENT,EXPOSANT,BIAIS) : une
  valeur vaut PENTE fois son entier stocké, plus BIAIS.
  A = FI(V,T) et FI(V,T,F) : le type T (NUMERICTYPE, ou ce que rend
  FIXDT) et les règles de calcul F (FIMATH), qui peuvent aussi suivre les
  nombres : FI(V,1,16,8,F).
  Les propriétés se donnent aussi par paires : FI(V,1,16,8,
  'RoundingMethod','Floor','OverflowAction','Wrap').

  Une valeur est arrondie au plus proche et saturée aux bornes du type,
  sauf règles contraires ; NaN devient 0. Les calculs suivent FIMATH :
  en pleine précision, A + B garde la plus fine des deux échelles et
  gagne un bit ; A .* B additionne tailles et bits après la virgule ;
  SUM gagne ceil(log2(N)) bits. Un double qui se mêle au calcul prend le
  signe et la taille de l'autre opérande, en meilleure précision. Une
  division demande le type du quotient : DIVIDE(T,A,B).

  Propriétés : data (la valeur, en double), int (l'entier stocké), bin,
  hex, dec, oct, numerictype, fimath, Signed, Signedness, WordLength,
  FractionLength, Slope, Bias, DataTypeMode, RoundingMethod,
  OverflowAction, ProductMode, SumMode. Écrire l'une des propriétés du
  type range à nouveau la valeur dans le type changé.

  Les entiers stockés sont des doubles : au-delà de 53 bits, les derniers
  se perdent.

  Exemple :
     a = fi(pi)                     % 3.1416 : 16 bits, 13 après la virgule
     a.bin                          % '0110010010001000'
     b = fi(0.1, 1, 8, 6);
     c = a + b                      % 17 bits, 13 après la virgule
     d = a * b                      % 24 bits, 19 après la virgule
     fi(300, 0, 8, 0)               % 255 : saturé
     fi(300, 0, 8, 0, 'OverflowAction', 'Wrap')      % 44

  Voir aussi NUMERICTYPE, FIMATH, FIXDT, DIVIDE, ISFI, UPPERBOUND.
```

## `fimath`

```
FIMATH Les règles de calcul des nombres à virgule fixe.
  F = FIMATH rend les règles par défaut : arrondi au plus proche, les
  milieux vers +Inf (Nearest), saturation au débordement (Saturate),
  produits et sommes en pleine précision (FullPrecision).
  F = FIMATH('Nom', valeur, ...) les règle :
     RoundingMethod   Ceiling, Convergent, Floor, Nearest, Round, Zero
     OverflowAction   Saturate, Wrap
     ProductMode      FullPrecision, KeepLSB, KeepMSB, SpecifyPrecision
     ProductWordLength, ProductFractionLength   (32 et 30)
     SumMode          FullPrecision, KeepLSB, KeepMSB, SpecifyPrecision
     SumWordLength, SumFractionLength           (32 et 30)
     MaxProductWordLength, MaxSumWordLength     (65535)
     CastBeforeSum    true
  F = FIMATH(A) rend les règles du FI A.

  En pleine précision, une somme garde la plus fine des échelles et
  prend un bit de plus ; un produit additionne tailles et bits après la
  virgule. KeepLSB garde les bits de poids faible sur ProductWordLength
  (SumWordLength) bits, KeepMSB ceux de poids fort, SpecifyPrecision
  impose taille et virgule.

  Exemple :
     F = fimath('RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
     a = fi(pi, 1, 8, 5, F)         % 3.1250 : arrondi par défaut

  Voir aussi FI, NUMERICTYPE.
```

## `fixdt`

```
FIXDT Un type de données à virgule fixe pour Simulink.
  T = FIXDT(S,W) : signé ou non (S vaut 1 ou 0), sur W bits ; l'échelle
  reste à fixer.
  T = FIXDT(S,W,F) : F bits après la virgule.
  T = FIXDT(S,W,PENTE,BIAIS) : une valeur vaut PENTE fois son entier
  stocké, plus BIAIS.
  T = FIXDT(S,W,AJUSTEMENT,EXPOSANT,BIAIS) : la pente vaut AJUSTEMENT *
  2^EXPOSANT.
  T = FIXDT(NOM) lit un nom de type : 'double', 'single', 'boolean',
  'int8' … 'uint32', et les noms de Simulink — 'sfix16_En8' (signé, 16
  bits, 8 après la virgule), 'ufix8' (sans signe, sans virgule),
  'sfix16_E2' (virgule deux bits à droite), 'ufix8_S0p5_B2' (pente 0,5,
  biais 2 ; p est la virgule, n le signe moins).
  [T,ECHELLE] = FIXDT(...) rend aussi faux : MatLibre n'a pas de type
  « scaled double ».

  T est un Simulink.NumericType : il se donne à un bloc par
  OutDataTypeStr = 'fixdt(1,16,8)', ou par le nom sous lequel on l'a
  rangé, et à FI comme un NUMERICTYPE.

  Exemple :
     T = fixdt(1, 16, 8)
     fixdt('sfix16_En8')            % le même
     fi(pi, T)                      % 3.1406

  Voir aussi NUMERICTYPE, FI.
```

## `isfi`

```
ISFI Vrai pour un nombre à virgule fixe (FI).
  OUI = ISFI(X) vaut vrai si X est un objet FI.

  Exemple :
     isfi(fi(pi))                   % true
     isfi(pi)                       % false

  Voir aussi FI, ISNUMERICTYPE, ISFIMATH.
```

## `isfimath`

```
ISFIMATH Vrai pour des règles de calcul à virgule fixe (FIMATH).
  OUI = ISFIMATH(X) vaut vrai si X est un objet FIMATH.

  Exemple :
     isfimath(fimath)               % true

  Voir aussi FIMATH, ISFI, ISNUMERICTYPE.
```

## `isnumerictype`

```
ISNUMERICTYPE Vrai pour un type à virgule fixe (NUMERICTYPE).
  OUI = ISNUMERICTYPE(X) vaut vrai si X est un NUMERICTYPE, ou un
  Simulink.NumericType que rend FIXDT.

  Exemple :
     isnumerictype(numerictype(1, 16, 8))    % true

  Voir aussi NUMERICTYPE, ISFI, ISFIMATH.
```

## `matlibre_fixe_arrondir`

```
MATLIBRE_FIXE_ARRONDIR Arrondit comme Fixed-Point Designer.
  R = MATLIBRE_FIXE_ARRONDIR(X,METHODE) : Nearest arrondit au plus proche,
  les milieux vers +Inf ; Round de même, les milieux loin de zéro ;
  Convergent de même, les milieux vers le pair ; Floor vers -Inf,
  Ceiling vers +Inf, Zero vers zéro.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi FIMATH.
```

## `matlibre_fixe_bornes`

```
MATLIBRE_FIXE_BORNES Les entiers stockés extrêmes d'un type fixe.
  [BAS,HAUT] = MATLIBRE_FIXE_BORNES(T) : de -2^(W-1) à 2^(W-1)-1 pour un
  type signé de W bits, de 0 à 2^W-1 sinon.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi FI, UPPERBOUND, LOWERBOUND.
```

## `matlibre_fixe_calcul`

```
MATLIBRE_FIXE_CALCUL Les calculs, l'indexation et l'affichage de FI.
  R = MATLIBRE_FIXE_CALCUL(OP,A,B) calcule A OP B — 'plus', 'minus',
  'times', 'mtimes', 'power' — ou OP(A) — 'uminus', 'abs', 'sum', 'max',
  'min' — selon les règles FIMATH de l'opérande qui en porte, par défaut
  sinon. R = MATLIBRE_FIXE_CALCUL('concatener',DIM,A,B,...) met bout à
  bout dans le type du premier FI ; 'lire' et 'ecrire' font SUBSREF et
  SUBSASGN ; 'afficher' fait DISP.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi FI, FIMATH.
```

## `matlibre_fixe_chiffres`

```
MATLIBRE_FIXE_CHIFFRES Les entiers stockés écrits en base 2, 8, 16 ou 10.
  T = MATLIBRE_FIXE_CHIFFRES(Q,TYPE,BASE) : en base 2, 8 et 16, sur la
  taille du mot, un négatif en complément à deux ; en base 10, l'entier
  avec son signe. Les éléments d'une ligne sont séparés de trois
  espaces ; chaque ligne du tableau est une ligne du texte.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi BIN, HEX, DEC, OCT.
```

## `matlibre_fixe_precision`

```
MATLIBRE_FIXE_PRECISION Le plus de bits après la virgule qui tiennent.
  F = MATLIBRE_FIXE_PRECISION(V,SIGNE,W) rend le nombre de bits après la
  virgule le plus grand pour lequel toutes les valeurs de V, arrondies
  au plus proche, tiennent sur W bits, signés ou non : la meilleure
  précision, que prend FI quand l'échelle n'est pas donnée. Des zéros
  seuls en laissent W - 1 (W sans signe).

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi FI.
```

## `matlibre_fixe_quantifier`

```
MATLIBRE_FIXE_QUANTIFIER Les entiers stockés d'une valeur dans un type fixe.
  Q = MATLIBRE_FIXE_QUANTIFIER(V,T,F) rend l'entier que stocke chaque
  valeur de V dans le type T (NUMERICTYPE) : (V - Bias) / Slope, arrondi
  selon F.RoundingMethod, puis ramené dans les bornes du type selon
  F.OverflowAction — saturé, ou replié comme en complément à deux.
  [Q,DEBORDE] = ... dit aussi si une valeur a débordé. NaN devient 0,
  avec un avertissement, comme dans MATLAB ; un infini sature.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi FI, FIMATH.
```

## `matlibre_fixe_stocke`

```
MATLIBRE_FIXE_STOCKE Les entiers stockés, dans le plus petit entier de MATLAB.
  Q = MATLIBRE_FIXE_STOCKE(Q,T) : int8 à int64 pour un type signé de 8 à
  64 bits, uint8 à uint64 sinon ; au-delà de 64 bits, des doubles.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi STOREDINTEGER.
```

## `matlibre_fixe_type`

```
MATLIBRE_FIXE_TYPE Les travaux de NUMERICTYPE : construire, lire, montrer.
  T = MATLIBRE_FIXE_TYPE('positionnel',T,ARGS) règle T sur (S), (S,W),
  (S,W,F), (S,W,PENTE,BIAIS) ou (S,W,AJUSTEMENT,EXPOSANT,BIAIS).
  T = MATLIBRE_FIXE_TYPE('flottant',T,NOM) en fait un double, un single
  ou un booléen ; T = MATLIBRE_FIXE_TYPE('mode',T,TEXTE) le règle sur un
  DataTypeMode écrit ; S = MATLIBRE_FIXE_TYPE('echelle',TEXTE) vérifie
  un Scaling ; TEXTE = MATLIBRE_FIXE_TYPE('texte',T) l'écrit
  « numerictype(1,16,8) » ; MATLIBRE_FIXE_TYPE('afficher',T) le montre.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi NUMERICTYPE, FI.
```

## `matlibre_fixe_versType`

```
MATLIBRE_FIXE_VERSTYPE Un type à virgule fixe, de ce qui le décrit.
  T = MATLIBRE_FIXE_VERSTYPE(X) rend l'embedded.numerictype que décrit X :
  un NUMERICTYPE, un Simulink.NumericType (ce que rend FIXDT), ou un nom
  de type de Simulink ('sfix16_En8', 'fixdt(1,16,8)').

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi NUMERICTYPE, FIXDT.
```

## `numerictype`

```
NUMERICTYPE Le type d'un nombre à virgule fixe : signe, taille, échelle.
  T = NUMERICTYPE rend le type par défaut : signé, mots de 16 bits dont
  15 après la virgule.
  T = NUMERICTYPE(S) et T = NUMERICTYPE(S,W) : signé ou non, mots de W
  bits ; l'échelle reste à fixer — FI prend alors la meilleure précision.
  T = NUMERICTYPE(S,W,F) : F bits après la virgule.
  T = NUMERICTYPE(S,W,PENTE,BIAIS) : une valeur vaut PENTE fois son
  entier stocké, plus BIAIS.
  T = NUMERICTYPE(S,W,AJUSTEMENT,EXPOSANT,BIAIS) : la pente vaut
  AJUSTEMENT * 2^EXPOSANT, AJUSTEMENT allant de 1 à 2.
  T = NUMERICTYPE('double'), NUMERICTYPE('single'),
  NUMERICTYPE('boolean').
  T = NUMERICTYPE(A) rend le type du FI A.
  Les propriétés se donnent aussi par paires : NUMERICTYPE('Signed',
  false, 'WordLength', 8, 'FractionLength', 4).

  Propriétés : DataTypeMode, Signed, Signedness, WordLength,
  FractionLength, Slope, Bias, FixedExponent, SlopeAdjustmentFactor,
  Scaling ('BinaryPoint', 'SlopeBias' ou 'Unspecified').

  Exemple :
     T = numerictype(1, 16, 8)
     T.Slope                        % 0.0039
     a = fi(pi, T)                  % 3.1406
     numerictype(0, 8, 0.5, 10)     % pente 0.5, biais 10

  Voir aussi FI, FIMATH, FIXDT.
```

