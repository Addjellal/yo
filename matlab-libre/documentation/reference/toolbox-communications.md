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

## `eyediagram`

```
EYEDIAGRAM Découpe un signal en segments de N échantillons.
  SEGMENTS = EYEDIAGRAM(X,N) rend une matrice dont chaque ligne est une
  trace ; sans sortie, la fonction les trace superposées.
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

