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
  [BANC,CENTRES] = MELFILTERBANK(N,NFFT,FS) rend N filtres
  triangulaires répartis sur l'échelle de Mel, chacun donné par ses
  poids sur les NFFT/2+1 raies d'une transformée de Fourier, et leurs
  fréquences centrales en hertz.

  L'oreille ne perçoit pas les fréquences linéairement : deux sons
  séparés de cent hertz s'entendent très différents dans les graves et
  presque identiques dans les aigus. L'échelle de Mel épouse cette
  perception —

     mel = 2595 log10(1 + f / 700)

  — si bien que des filtres régulièrement espacés en mel s'écartent de
  plus en plus en hertz. C'est ce qui donne aux coefficients cepstraux
  leur pertinence : ils résument le son comme l'oreille le résume.

  Les filtres se recouvrent à mi-hauteur : chaque raie compte dans deux
  filtres voisins, ce qui évite les discontinuités entre bandes.

  Exemple :
     [banc, centres] = melFilterBank(26, 512, 16000);
     size(banc)                      % 26 par 257
     diff(centres(1:3))              % petit ecart dans les graves
     diff(centres(end-2:end))        % bien plus grand dans les aigus

  Voir aussi MFCCSIMPLE, SPECTRALCENTROID, FFT.
```

## `mfccSimple`

```
MFCCSIMPLE Coefficients cepstraux sur l'échelle de Mel.
  C = MFCCSIMPLE(X,FS) découpe X en trames de trente millisecondes qui
  se recouvrent de moitié, et rend une ligne de coefficients par
  trame : treize par défaut.
  C = MFCCSIMPLE(X,FS,N) demande N coefficients.
  C = MFCCSIMPLE(X,FS,N,LONGUEUR,PAS) règle la trame et le pas, en
  échantillons.
  [C,INSTANTS] = MFCCSIMPLE(...) rend en outre l'instant du centre de
  chaque trame, en secondes.

  Le calcul, pour chaque trame : le spectre de puissance, l'énergie
  dans chaque bande de Mel, son logarithme, puis une transformée en
  cosinus discrète.

  Chacune des trois étapes a sa raison. Les bandes de Mel résument le
  spectre comme l'oreille le résume. Le logarithme transforme le
  produit du son par le canal — micro, salle, distance — en une somme,
  qui devient une constante additive. La transformée en cosinus
  décorrèle les bandes, très redondantes entre elles, et concentre
  l'information sur les premiers coefficients.

  Le premier coefficient porte l'énergie de la trame : c'est le seul
  qui change quand on éloigne le micro. Les suivants décrivent la forme
  du spectre, et c'est ce qu'on garde pour reconnaître un son
  indépendamment de son niveau.

  Le découpage en trames est indispensable : la parole change tous les
  dix à trente millisecondes, et un seul jeu de coefficients pour tout
  un enregistrement ne décrirait qu'une moyenne sans intérêt.

  Exemple :
     [c, t] = mfccSimple(sin(2 * pi * 440 * (0:15999)' / 16000), 16000);
     size(c)                         % une ligne par trame
     size(c, 2)                      % 13 coefficients

  Voir aussi MELFILTERBANK, SPECTRALCENTROID, DCT.
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

