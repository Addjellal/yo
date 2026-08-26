# Toolbox `audio`

```
% Audio Toolbox — sons et descripteurs.
%
%   audiowrite, audioread - Fichiers WAV PCM 16 bits
%   spectralCentroid      - Centre de gravité spectral
%   zerocrossrate         - Taux de passages par zéro
%   melFilterBank         - Banc de filtres de Mel
%   mfccSimple            - Coefficients cepstraux
%   dbfs                  - Niveau en dB pleine échelle
```

## `audioread`

```
AUDIOREAD Lit un fichier WAV PCM 16 bits monophonique.
```

## `audiowrite`

```
AUDIOWRITE Écrit un fichier WAV PCM 16 bits monophonique.
```

## `dbfs`

```
DBFS Niveau en décibels pleine échelle.
```

## `melFilterBank`

```
MELFILTERBANK Banc de filtres triangulaires sur l'échelle de Mel.
```

## `mfccSimple`

```
MFCCSIMPLE Coefficients cepstraux sur l'échelle de Mel.
```

## `spectralCentroid`

```
SPECTRALCENTROID Centre de gravité du spectre, en hertz.
```

## `zerocrossrate`

```
ZEROCROSSRATE Proportion de passages par zéro.
  R = ZEROCROSSRATE(X) compte les changements de signe et divise par la
  longueur de la fenêtre, comme le fait MATLAB.

  Exemple :
     zerocrossrate([1 -1 1 -1])   % 0.75
```

