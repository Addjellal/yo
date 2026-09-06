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
  [Y,FS] = AUDIOREAD(FICHIER) rend les échantillons, ramenés entre -1 et
  1, et la fréquence d'échantillonnage.

  Seul le WAV PCM 16 bits mono est lu : ni compression, ni stéréo, ni
  flottant. Les formats compressés — MP3, AAC, Ogg — demandent un codec,
  et les intégrer signifierait une dépendance externe.

  La normalisation entre -1 et 1 est la convention de MATLAB : elle rend
  le traitement indépendant du nombre de bits, et c'est AUDIOWRITE qui
  refait la conversion en sens inverse.

  Exemple :
     audiowrite('essai.wav', sin(2*pi*440*(0:8000)/8000), 8000);
     [y, fs] = audioread('essai.wav');
     max(abs(y))                     % proche de 1

  Voir aussi AUDIOWRITE, DBFS, SPECTRALCENTROID.
```

## `audiowrite`

```
AUDIOWRITE Écrit un fichier WAV PCM 16 bits monophonique.
  AUDIOWRITE(FICHIER,Y,FS) écrit les échantillons Y, supposés entre -1
  et 1, à la fréquence FS.

  Ce qui sort de l'intervalle est écrêté, non mis à l'échelle : un signal
  qui dépasse est donc distordu, et il vaut mieux le normaliser
  soi-même avant d'écrire. L'écrêtage est la façon dont un convertisseur
  réel se comporte, et le silence ferait pire.

  La quantification sur seize bits introduit un bruit d'environ -96 dBFS :
  l'aller-retour par AUDIOREAD n'est donc pas exact, mais fidèle à
  1/32768 près.

  Exemple :
     audiowrite('essai.wav', 0.5 * sin(2*pi*440*(0:8000)/8000), 8000);
     [y, fs] = audioread('essai.wav');

  Voir aussi AUDIOREAD, DBFS.
```

## `dbfs`

```
DBFS Niveau en décibels pleine échelle.
  D = DBFS(X) rend vingt fois le logarithme décimal de la valeur
  efficace du signal.

  Zéro dBFS est la pleine échelle : un signal qui l'atteint sature. Tous
  les niveaux sont donc négatifs, et c'est la convention de tout
  l'audionumérique — contrairement au dBm, qui est une puissance
  absolue.

  Un sinus d'amplitude un vaut -3,01 dBFS, non zéro : sa valeur efficace
  est son amplitude divisée par racine de deux. C'est la confusion la
  plus fréquente entre niveau crête et niveau efficace.

  Exemple :
     dbfs(ones(1, 100))              % 0 : pleine echelle continue
     dbfs(sin(2*pi*(0:999)/100))     % -3.01 : un sinus de pointe a 1
     dbfs(0.1 * ones(1, 100))        % -20

  Voir aussi AUDIOREAD, RMS, SPECTRALCENTROID.
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
  C = SPECTRALCENTROID(X,FS) rend la moyenne des fréquences pondérée par
  l'amplitude du spectre. FS vaut un par défaut, auquel cas le résultat
  est une fréquence réduite.

  C'est le descripteur qui correspond le mieux à la « brillance »
  perçue d'un son : un son grave a un centroïde bas, un son clair un
  centroïde haut. Il sert dans presque toute classification de timbre.

  Les repères : le centroïde d'un sinus pur est sa fréquence ; celui
  d'un bruit blanc tombe au quart de la fréquence d'échantillonnage,
  c'est-à-dire au milieu de la bande utile.

  Exemple :
     fs = 8000; t = (0:fs-1) / fs;
     spectralCentroid(sin(2*pi*1000*t), fs)      % 1000
     spectralCentroid(randn(1, fs), fs)          % environ fs/4

  Voir aussi DBFS, MFCCSIMPLE, MELFILTERBANK.
```

## `zerocrossrate`

```
ZEROCROSSRATE Proportion de passages par zéro.
  R = ZEROCROSSRATE(X) compte les changements de signe et divise par la
  longueur de la fenêtre, comme le fait MATLAB.

  Exemple :
     zerocrossrate([1 -1 1 -1])   % 0.75
```

