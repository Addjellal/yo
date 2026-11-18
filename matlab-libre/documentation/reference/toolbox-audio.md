# Toolbox `audio`

```
% Audio Toolbox — sons et descripteurs.
%
% Fichiers
%   audiowrite, audioread - Fichiers WAV PCM 16 bits
%
% Descripteurs (signatures de MATLAB)
%   spectralCentroid      - Centroïde spectral trame par trame (Peeters, 2004)
%   zerocrossrate         - Taux de passages par zéro ou par un niveau
%
% Échelles perceptives
%   hz2mel, mel2hz        - Échelle de Mel (O'Shaughnessy, 1987)
%   hz2bark, bark2hz      - Échelle de Bark (Traunmüller, 1990)
%   hz2erb, erb2hz        - Échelle ERB (Glasberg et Moore, 1990)
%
% Propres à MatLibre
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

## `bark2hz`

```
BARK2HZ Échelle de Bark vers les hertz, inverse de HZ2BARK (Traunmüller, 1990).
  Les corrections des bouts s'inversent d'abord — sous 2 Bark,
  (b - 0.3) / 0.85 ; au-dessus de 20.1, (b + 4.422) / 1.22 — puis
  HZ = 1960 (b + 0.53) / (26.28 - b).

  Exemple :
     bark2hz(hz2bark(1000))     % 1000

  Voir aussi HZ2BARK, MEL2HZ, ERB2HZ.
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

## `erb2hz`

```
ERB2HZ Échelle ERB vers les hertz, inverse de HZ2ERB (Glasberg et Moore, 1990).
  HZ = (10^(ERB/A) - 1) / 0.00437, A = 1000 ln(10) / (24.7 x 4.37).

  Exemple :
     erb2hz(hz2erb(440))        % 440

  Voir aussi HZ2ERB, MEL2HZ, BARK2HZ.
```

## `hz2bark`

```
HZ2BARK Fréquences en hertz vers l'échelle de Bark (Traunmüller, 1990).
  BARK = HZ2BARK(HZ) = 26.81 HZ / (1960 + HZ) - 0.53, corrigé aux deux
  bouts comme dans MATLAB : sous 2 Bark, b + 0.15 (2 - b) ; au-dessus de
  20.1 Bark, b + 0.22 (b - 20.1). L'échelle de Bark compte les bandes
  critiques de l'oreille (Zwicker) : 1000 Hz tombent vers 8.5 Bark.

  Exemple :
     hz2bark(1000)              % 8.527

  Voir aussi BARK2HZ, HZ2MEL, HZ2ERB.
```

## `hz2erb`

```
HZ2ERB Fréquences en hertz vers l'échelle ERB (Glasberg et Moore, 1990).
  ERB = HZ2ERB(HZ) = A log10(1 + 0.00437 HZ), A = 1000 ln(10) / (24.7
  x 4.37) : le nombre de bandes rectangulaires équivalentes sous HZ, la
  bande à F valant 24.7 (4.37 F/1000 + 1) hertz. 1000 Hz valent 15.57.

  Exemple :
     hz2erb(1000)               % 15.572

  Voir aussi ERB2HZ, HZ2MEL, HZ2BARK.
```

## `hz2mel`

```
HZ2MEL Fréquences en hertz vers l'échelle de Mel.
  MEL = HZ2MEL(HZ) = 2595 log10(1 + HZ/700), la formule
  d'O'Shaughnessy (1987) qu'emploie MATLAB. Par construction, 1000 Hz
  valent 1000 mels.

  Exemple :
     hz2mel([0 1000 4000])      % 0, 1000, 2146.1

  Voir aussi MEL2HZ, HZ2BARK, HZ2ERB, MELFILTERBANK.
```

## `mel2hz`

```
MEL2HZ Échelle de Mel vers les hertz : HZ = 700 (10^(MEL/2595) - 1).
  L'inverse exact de HZ2MEL (O'Shaughnessy, 1987).

  Exemple :
     mel2hz(1000)               % 1000

  Voir aussi HZ2MEL, BARK2HZ, ERB2HZ.
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
SPECTRALCENTROID Centroïde spectral, trame par trame (Peeters, 2004).
  CENTROID = SPECTRALCENTROID(X,FS) découpe le signal X (une colonne par
  voie) en trames, et rend pour chacune le centre de gravité de son
  spectre, en hertz :
     centroïde = somme(f_k s_k) / somme(s_k),
  sur les raies f_k de la bande Range. CENTROID a une ligne par trame et
  une colonne par voie. Comme MATLAB, les trames durent par défaut
  30 ms (fenêtre rectangulaire) et se recouvrent de 20 ms.

  CENTROID = SPECTRALCENTROID(S,F), F étant un vecteur de fréquences,
  prend S pour un spectre déjà calculé : numel(F) lignes, une colonne
  par spectre (et une page par voie). Les options n'y servent pas.

  Options, pour un signal temporel :
     'Window'         fenêtre (défaut rectwin(round(FS*0.03)))
     'OverlapLength'  recouvrement en échantillons (défaut round(FS*0.02))
     'FFTLength'      longueur de la transformée (défaut numel(Window))
     'Range'          bande [fmin fmax] en hertz (défaut [0 FS/2])
     'SpectrumType'   'power' (défaut, s = |X|²) ou 'magnitude' (|X|)
  Le spectre d'une trame est |FFT|² (ou |FFT|) de la trame fenêtrée, sur
  les raies de 0 à FS/2.

  Sans argument de sortie, trace le centroïde en fonction du temps.

  Exemple :
     fs = 8000; t = (0:fs - 1).' / fs;
     c = spectralCentroid(sin(2 * pi * 1000 * t), fs);   % 1000 Hz partout

  Voir aussi ZEROCROSSRATE, MELFILTERBANK, STFT.
```

## `zerocrossrate`

```
ZEROCROSSRATE Taux de passages par zéro (ou par un niveau).
  RATE = ZEROCROSSRATE(X) rend le taux de passages par zéro de X, comme
  MATLAB : le nombre de passages divisé par la longueur de la fenêtre.
  Une matrice X est traitée colonne par colonne, une colonne par voie.
  [RATE,COUNT,INDICES] = ZEROCROSSRATE(X) rend aussi le nombre de
  passages par fenêtre et les échantillons marqués (fenêtres x
  WindowLength x voies, logiques).

  Options (nom, valeur) :
     'Method'          'difference' (défaut) ou 'comparison'
     'WindowLength'    longueur des fenêtres (défaut : tout le signal)
     'OverlapLength'   recouvrement des fenêtres (défaut 0)
     'Level'           niveau dont on compte les passages (défaut 0)
     'Threshold'       les écarts au niveau de module au plus égal à ce
                       seuil comptent pour zéro (défaut 0)
     'InitialState'    l'échantillon qui précède le signal (défaut 0)
     'TransitionEdge'  'both' (défaut), 'rising' ou 'falling'
     'ZeroPositive'    un zéro compte comme positif (défaut false)

  Méthode 'difference' : chaque échantillon apporte |sgn(x(i)) -
  sgn(x(i-1))| / 2, où sgn suit SIGN (zéro a son propre signe, sauf
  ZeroPositive) ; un passage franc de +1 à -1 compte un, un passage par
  un zéro compte deux demis. Méthode 'comparison' : un passage ne compte
  qu'une fois achevé, quand le signe non nul s'inverse. L'échantillon
  initial vaut 0 par défaut : un premier échantillon non nul compte
  donc pour un demi passage en méthode 'difference'. Le taux est le
  compte divisé par WindowLength.

  Exemples :
     % Documentation de MATLAB.
     x = [1 -1 1 -1 1 -1 1 -1 1 -1];
     zerocrossrate(x)                         % 0.95
     zerocrossrate(x, 'Method', 'comparison') % 0.90
     zerocrossrate(x, 'ZeroPositive', true)   % 0.90
     zerocrossrate(x, 'InitialState', 1)      % 0.90

  Voir aussi SIGN, SPECTRALCENTROID, RMS.
```

