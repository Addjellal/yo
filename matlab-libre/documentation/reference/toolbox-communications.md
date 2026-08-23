# Toolbox `communications`

```
% Communications Toolbox — transmissions numériques.
%
%   awgn              - Ajout de bruit blanc gaussien
%   pskmod / pskdemod - Modulation de phase
%   qammod / qamdemod - Modulation d'amplitude en quadrature
%   de2bi / bi2de     - Entiers et vecteurs binaires
%   biterr / symerr   - Taux d'erreur binaire et symbole
%   berawgn           - Taux d'erreur théorique sur canal gaussien
%   convenc / vitdec  - Codage convolutif et décodage de Viterbi
%   hammgen / encode  - Code de Hamming
%   rcosdesign        - Filtre en racine de cosinus surélevé
%   eyediagram        - Diagramme de l'œil (données)
%
% Probabilités d'erreur
%   qfunc, qfuncinv - Fonction Q et sa réciproque
%
% Modulations supplémentaires
%   dpskmod, dpskdemod - Déplacement de phase différentiel
%   fskmod, fskdemod   - Déplacement de fréquence
%
% Codes correcteurs
%   hammgen         - Matrices d'un code de Hamming
%   encode, decode  - Codage en blocs, correction d'une erreur
```

## `awgn`

```
AWGN Ajoute un bruit blanc gaussien pour atteindre un rapport donné.
  Y = AWGN(X,SNR) ajoute du bruit tel que le rapport signal sur bruit
  vaille SNR décibels, la puissance du signal étant mesurée sur X.
```

## `base2dec`

```
BASE2DEC Chaîne dans une base quelconque vers entier.
```

## `berawgn`

```
BERAWGN Taux d'erreur binaire théorique sur canal gaussien.
  BER = BERAWGN(EBNO,'psk',M) ou BERAWGN(EBNO,'qam',M).
```

## `bi2de`

```
BI2DE Vecteurs de chiffres vers entiers, poids faible en tête.
```

## `biterr`

```
BITERR Nombre et taux d'erreurs binaires entre deux suites d'entiers.
```

## `convenc`

```
CONVENC Codeur convolutif systématique en octal.
  CODE = CONVENC(MESSAGE,GENERATEURS,CONTRAINTE) où GENERATEURS est un
  vecteur de polynômes en octal, par exemple [7 5] pour le code de
  rendement 1/2 et de longueur de contrainte 3.
```

## `de2bi`

```
DE2BI Entiers vers vecteurs de chiffres, poids faible en tête.
```

## `dec2base`

```
DEC2BASE Entier vers chaîne dans une base quelconque.
```

## `decode`

```
DECODE Décodage en blocs linéaires, avec correction d'une erreur.
  [MSG,ERR] = DECODE(CODE,N,K,'hamming/fmt') corrige une erreur par
  bloc grâce au syndrome, puis extrait les K bits d'information.

  Exemple :
     c = encode([1 0 1 1], 7, 4, 'hamming/fmt');
     c(3) = 1 - c(3);
     isequal(decode(c, 7, 4, 'hamming/fmt'), [1 0 1 1])   % vrai
```

## `dpskdemod`

```
DPSKDEMOD Démodulation par déplacement de phase différentiel.
```

## `dpskmod`

```
DPSKMOD Modulation par déplacement de phase différentiel.
  Y = DPSKMOD(X,M) code l'information dans la différence de phase entre
  deux symboles consécutifs : le récepteur n'a pas besoin de connaître
  la phase absolue.

  Exemple :
     y = dpskmod([0 1 0], 2);   % [1 -1 -1] : la phase bascule au 1
```

## `encode`

```
ENCODE Codage en blocs linéaires.
  CODE = ENCODE(MSG,N,K,'linear/fmt',G) multiplie chaque bloc de K bits
  par la matrice génératrice, modulo 2.
  CODE = ENCODE(MSG,N,K,'hamming/fmt') utilise le code de Hamming.

  Exemple :
     c = encode([1 0 1 1], 7, 4, 'hamming/fmt');
```

## `eyediagram`

```
EYEDIAGRAM Découpe un signal en segments de N échantillons.
  SEGMENTS = EYEDIAGRAM(X,N) rend une matrice dont chaque ligne est une
  trace ; sans sortie, la fonction les trace superposées.
```

## `fskdemod`

```
FSKDEMOD Démodulation par déplacement de fréquence, par corrélation.
```

## `fskmod`

```
FSKMOD Modulation par déplacement de fréquence.
  Y = FSKMOD(X,M,ECART,NECH,FS) : chaque symbole devient NECH
  échantillons d'une sinusoïde dont la fréquence dépend du symbole.

  Exemple :
     y = fskmod([0 1], 2, 100, 8, 1000);   % 16 échantillons
```

## `hammgen`

```
HAMMGEN Matrices d'un code de Hamming.
  [H,G,N,K] = HAMMGEN(M) rend la matrice de contrôle H (M x N), la
  matrice génératrice G (K x N), avec N = 2^M-1 et K = N-M.

  Les colonnes de H sont toutes les combinaisons binaires non nulles :
  c'est ce qui permet de localiser une erreur simple par son syndrome.

  Exemple :
     [H, G, n, k] = hammgen(3);   % n = 7, k = 4
```

## `pskdemod`

```
PSKDEMOD Démodulation de phase à M états, par décision du plus proche.
```

## `pskmod`

```
PSKMOD Modulation de phase à M états.
  Y = PSKMOD(X,M) associe au symbole k le point exp(2i pi k / M).
```

## `qamdemod`

```
QAMDEMOD Démodulation QAM par décision sur la grille.
```

## `qammod`

```
QAMMOD Modulation d'amplitude en quadrature à M états (M carré).
  La constellation est celle de la documentation : grille carrée
  centrée, d'espacement 2.
```

## `qfunc`

```
QFUNC Fonction Q : probabilité qu'une normale centrée réduite dépasse X.
  Q(X) = 0.5*erfc(X/sqrt(2)).

  Exemple :  qfunc(0)   % 0.5
```

## `qfuncinv`

```
QFUNCINV Réciproque de la fonction Q.
  Q(x) = 0.5*erfc(x/sqrt(2)), donc x = sqrt(2)*erfcinv(2*q).

  Exemple :
     qfuncinv(0.5)              % 0
     qfuncinv(qfunc(1.3))       % 1.3
```

## `rcosdesign`

```
RCOSDESIGN Filtre en cosinus surélevé, ou sa racine.
  H = RCOSDESIGN(BETA,SPAN,SPS,'sqrt') rend la racine du cosinus
  surélevé, normalisée en énergie.
```

## `symerr`

```
SYMERR Nombre et taux d'erreurs symbole.
```

## `vitdec`

```
VITDEC Décodage de Viterbi à décision dure.
  MESSAGE = VITDEC(CODE,GENERATEURS,CONTRAINTE) inverse CONVENC.
```

