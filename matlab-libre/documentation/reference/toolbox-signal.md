# Toolbox `signal`

```
% Signal Processing Toolbox — traitement du signal.
%
% Complète les fonctions natives (fft, filter, conv, freqz, fenêtres) par
% la conception de filtres, l'analyse spectrale et la mesure.
%
% Conception de filtres
%   fir1        - Filtre RIF par fenêtrage
%   fir2        - Filtre RIF suivant un gabarit de réponse
%   butter      - Filtre de Butterworth (bilinéaire)
%   cheby1      - Chebyshev de type I, ondulation en bande passante
%   cheby2      - Chebyshev de type II, ondulation en bande coupée
%   buttord     - Ordre minimal d'un Butterworth
%   cheb1ord    - Ordre minimal d'un Chebyshev I
%   cheb2ord    - Ordre minimal d'un Chebyshev II
%   kaiserord   - Ordre et bêta d'un RIF fenêtré par Kaiser
%   prototypeVersNumerique - Prototype analogique -> filtre numérique
%
% Structures de filtres
%   tf2zp / zp2tf   - Fonction de transfert <-> zéros, pôles, gain
%   tf2sos / sos2tf - Fonction de transfert <-> sections du second ordre
%   zp2sos          - Zéros et pôles -> sections du second ordre
%   sosfilt         - Filtrage en cascade de sections
%   polystab        - Replie les racines dans le disque unité
%
% Réponses
%   impz        - Réponse impulsionnelle
%   stepz       - Réponse indicielle
%   grpdelay    - Temps de propagation de groupe
%   zplane      - Zéros et pôles dans le plan complexe
%
% Fenêtres
%   kaiser, triang, tukeywin, gausswin, blackmanharris, flattopwin,
%   nuttallwin, parzenwin, bohmanwin, barthannwin
%   enbw        - Largeur de bande de bruit équivalente
%
% Transformées
%   dct / idct  - Transformée en cosinus discrète
%   czt         - Transformée en Z sur une spirale (Bluestein)
%   goertzel    - Composantes choisies de la transformée de Fourier
%   dftmtx      - Matrice de la transformée de Fourier discrète
%   hilbert     - Signal analytique
%   cconv       - Convolution circulaire
%
% Analyse spectrale
%   periodogram - Densité spectrale de puissance
%   pwelch      - Périodogramme moyenné de Welch
%   spectrogram - Transformée de Fourier à court terme
%   cpsd        - Densité interspectrale
%   mscohere    - Cohérence quadratique moyenne
%   tfestimate  - Estimation de fonction de transfert
%   bandpower   - Puissance dans une bande
%   meanfreq    - Fréquence moyenne
%   medfreq     - Fréquence médiane
%
% Rééchantillonnage
%   resample    - Rééchantillonnage rationnel
%   decimate    - Réduction d'un facteur entier
%   interp      - Augmentation d'un facteur entier
%   buffer      - Découpage en colonnes
%
% Mesures et comparaisons
%   rms, rssq, peak2peak, peak2rms - Amplitudes
%   snr         - Rapport signal sur bruit
%   findpeaks   - Détection de maxima locaux
%   envelope    - Enveloppe d'un signal
%   xcov        - Covariance croisée
%   finddelay   - Retard entre deux signaux
%   alignsignals - Recalage de deux signaux
%   seqperiod   - Période d'une séquence
%
% Signaux d'essai
%   chirp, square, sawtooth
%
% Filtrage
%   medfilt1    - Filtre médian glissant
%   sgolayfilt  - Lissage de Savitzky-Golay
%
% Analyse et prédicats
%   freqs       - Réponse en fréquence d'un filtre analogique
%   phasez      - Réponse en phase déroulée
%   phasedelay  - Retard de phase
%   zerophase   - Amplitude à phase nulle, signe compris
%   isstable    - Tous les pôles dans le cercle unité
%   isminphase  - Zéros et pôles dans le cercle unité
%   ismaxphase  - Zéros hors du cercle unité
%   islinphase  - Coefficients symétriques ou antisymétriques
%   firtype     - Type d'un RIF à phase linéaire, de 1 à 4
%
% Conversions entre représentations
%   residuez    - Éléments simples en z^-1
%   sos2zp, ss2zp, zp2ss, ss2sos, sos2ss
%
% Transformées supplémentaires
%   dst / idst  - Transformée en sinus discrète, première espèce
%   fwht / ifwht - Walsh-Hadamard rapide, trois rangements
%   rceps       - Cepstre réel, et version à phase minimale
%   cceps / icceps - Cepstre complexe et son inverse
%
% Fenêtres
%   chebwin     - Dolph-Tchebychev, lobes secondaires égaux
%   taylorwin   - Taylor, celle des radars
%   window      - Aiguillage par nom ou par poignée
%
% Formes d'onde
%   rectpuls, tripuls, gauspuls - Impulsions élémentaires
%   diric       - Noyau de Dirichlet
%   pulstran    - Train d'impulsions
%   vco         - Oscillateur commandé en tension
%   modulate / demod - Modulation et démodulation
%   sgolay      - Matrice de lissage de Savitzky-Golay
%
% Fonctions internes (absentes de MATLAB)
%   papillonHadamard, permutationWalsh, rangerWalsh, rangerWalshInverse
%
% Mesures sur un signal à deux états
%   statelevels - Niveaux bas et haut, par histogramme
%   midcross    - Traversées du niveau médian
%   risetime, falltime, slewrate - Fronts
%   overshoot, undershoot, settlingtime - Régime transitoire
%   pulsewidth, pulseperiod, pulsesep, dutycycle - Impulsions
%
% Distorsion et plage dynamique
%   thd         - Distorsion harmonique totale
%   sinad       - Signal sur bruit et distorsion
%   sfdr        - Plage dynamique libre de parasites
%   toi         - Point d'interception d'ordre trois
%
% Prédiction linéaire
%   ac2poly, poly2ac   - Autocorrélation et polynôme de prédiction
%   ac2rc, rc2ac       - Autocorrélation et coefficients de réflexion
%   poly2rc, rc2poly   - Polynôme et coefficients de réflexion
%   schurrc            - Réflexion par l'algorithme de Schur
%   poly2lsf, lsf2poly - Fréquences spectrales de raies
%
% Modèles autorégressifs et spectres paramétriques
%   aryule, arburg, arcov, armcov - Estimation du modèle
%   pyulear, pburg, pcov, pmcov   - Densité spectrale associée
%   corrmtx     - Matrice de données pour la corrélation
%   dpss        - Fenêtres de Slepian
%   pmtm        - Densité spectrale multi-fenêtres de Thomson
%
% Méthodes à sous-espaces
%   rootmusic, rooteig - Fréquences par les racines du polynôme du bruit
%   pmusic, peig       - Pseudospectres correspondants
%
% Fonctions internes supplémentaires (absentes de MATLAB)
%   arSpectre, signalLobe, signalSommet, signalSpectrePuissance,
%   signalNiveaux, signalTraverses, signalTransitions,
%   signalMatriceCorrelation, puissancesSousEspace, lireOptionsSousEspace
```

## `ac2poly`

```
AC2POLY Polynôme de prédiction d'une suite d'autocorrélation.
  [A,E] = AC2POLY(R) résout les équations de Yule-Walker par
  Levinson-Durbin. E est la puissance de l'erreur de prédiction.

  Exemple :
     [a, e] = ac2poly([1 0.5 0.25]);   % a = [1 -0.5 0]
```

## `ac2rc`

```
AC2RC Coefficients de réflexion d'une suite d'autocorrélation.
  [K,R0] = AC2RC(R) applique Levinson-Durbin : R(1) est la puissance du
  signal, K les coefficients de réflexion des ordres successifs.
```

## `alignsignals`

```
ALIGNSIGNALS Aligne deux signaux en compensant leur retard.
  [XA,YA,D] = ALIGNSIGNALS(X,Y) ajoute des zéros en tête du signal en
  avance, de sorte que les deux se superposent.
```

## `arSpectre`

```
ARSPECTRE Densité spectrale d'un modèle autorégressif.
  Le modèle X = E/A(z) a pour densité e/(fs |A(f)|^2), doublée sur la
  moitié positive du spectre quand on ne garde qu'un côté.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `arburg`

```
ARBURG Modèle autorégressif par la méthode de Burg.
  [A,E,K] = ARBURG(X,P) minimise, à chaque ordre, la somme des erreurs
  de prédiction avant et arrière sous la contrainte de la récurrence de
  Levinson. Contrairement à Yule-Walker, la méthode ne suppose aucune
  fenêtre : elle donne des estimations plus nettes sur les séries
  courtes, et le filtre reste toujours stable.

  Exemple :
     a = arburg(x, 4);
```

## `arcov`

```
ARCOV Modèle autorégressif par la méthode de la covariance.
  Moindres carrés sur l'erreur de prédiction avant, sans fenêtrage : on
  n'utilise que les échantillons pour lesquels toute la fenêtre de
  prédiction existe.
```

## `armcov`

```
ARMCOV Modèle autorégressif par la covariance modifiée.
  Moindres carrés sur les erreurs de prédiction avant et arrière à la
  fois : c'est la méthode qui résout le mieux deux sinusoïdes proches.
```

## `aryule`

```
ARYULE Modèle autorégressif par les équations de Yule-Walker.
  [A,E,K] = ARYULE(X,P) estime un modèle d'ordre P à partir de
  l'autocorrélation biaisée du signal, résolue par Levinson-Durbin. E
  est la variance de l'erreur de prédiction, K les coefficients de
  réflexion.

  Exemple :
     a = aryule(filter(1, [1 -0.9], randn(1000,1)), 1);
```

## `bandpower`

```
BANDPOWER Puissance moyenne d'un signal, éventuellement dans une bande.
  P = BANDPOWER(X) rend la puissance moyenne, soit la moyenne des
  carrés. P = BANDPOWER(X,FS,[F1 F2]) la restreint à une bande, par
  intégration du périodogramme.

  Exemple :
     bandpower([1 -1 1 -1])   % 1
```

## `barthannwin`

```
BARTHANNWIN Fenêtre de Bartlett-Hann.
```

## `blackmanharris`

```
BLACKMANHARRIS Fenêtre de Blackman-Harris à quatre termes.
  Coefficients : 0,35875 ; 0,48829 ; 0,14128 ; 0,01168.
```

## `bohmanwin`

```
BOHMANWIN Fenêtre de Bohman.
```

## `buffer`

```
BUFFER Découpe un signal en colonnes de longueur fixe.
  Y = BUFFER(X,N) range X en colonnes de N points, la dernière complétée
  par des zéros. BUFFER(X,N,P) fait se recouvrir les colonnes de P
  points (P négatif saute P points entre deux colonnes).

  Exemple :
     buffer(1:6, 3)   % [1 4; 2 5; 3 6]
```

## `butter`

```
BUTTER Filtre numérique de Butterworth.
  [B,A] = BUTTER(N,WN) conçoit un passe-bas d'ordre N de fréquence de
  coupure normalisée WN (0 < WN < 1, 1 = Nyquist).
  [B,A] = BUTTER(N,WN,'high') conçoit un passe-haut.

  Le prototype analogique est transposé par transformation bilinéaire
  avec pré-distorsion de la fréquence, comme le fait la fonction de
  référence.
```

## `buttord`

```
BUTTORD Ordre minimal d'un filtre de Butterworth.
  [N,WN] = BUTTORD(WP,WS,RP,RS) rend l'ordre le plus petit qui garde au
  plus RP décibels d'ondulation jusqu'à WP et au moins RS décibels
  d'atténuation à partir de WS. Les fréquences sont normalisées, 1 étant
  la moitié de la fréquence d'échantillonnage.

  Exemple :
     [n, Wn] = buttord(0.2, 0.4, 1, 40);   % n = 8
```

## `cceps`

```
CCEPS Cepstre complexe.
  [XHAT,ND] = CCEPS(X) rend le cepstre complexe et le nombre
  d'échantillons de retard retirés avant le déroulement de la phase.
  Le cepstre complexe garde la phase, à la différence de RCEPS.

  Exemple :
     xhat = cceps([1 0 0 0 0.5 0 0 0]);
```

## `cconv`

```
CCONV Convolution circulaire.
  C = CCONV(A,B,N) rend la convolution circulaire de longueur N. Sans N,
  la longueur vaut numel(A)+numel(B)-1, et le résultat coïncide alors
  avec la convolution ordinaire.

  Exemple :
     cconv([1 2], [1 1], 2)   % [3 3]
```

## `cheb1ord`

```
CHEB1ORD Ordre minimal d'un filtre de Chebyshev de type I.
  [N,WN] = CHEB1ORD(WP,WS,RP,RS). WN vaut WP : la bande passante est
  fixée par l'ondulation.
```

## `cheb2ord`

```
CHEB2ORD Ordre minimal d'un filtre de Chebyshev de type II.
  WN vaut WS : c'est la bande atténuée qui est fixée.
```

## `chebwin`

```
CHEBWIN Fenêtre de Dolph-Tchebychev.
  W = CHEBWIN(N,R) rend la fenêtre de N points dont les lobes
  secondaires sont tous à R décibels sous le lobe principal ; R vaut
  100 par défaut. C'est la fenêtre qui minimise la largeur du lobe
  principal à atténuation donnée.

  La construction est celle de Dolph : la transformée de la fenêtre est
  le polynôme de Tchebychev T(N-1) échantillonné sur le cercle, ce qui
  donne exactement des lobes secondaires égaux.

  Exemple :
     w = chebwin(51, 60);   % lobes secondaires à -60 dB
```

## `cheby1`

```
CHEBY1 Filtre de Chebyshev de type I.
  [B,A] = CHEBY1(N,RP,WN) conçoit un passe-bas d'ordre N dont
  l'ondulation en bande passante vaut RP décibels ; WN est la fréquence
  de coupure normalisée, 1 correspondant à la moitié de la fréquence
  d'échantillonnage.
  CHEBY1(N,RP,WN,'high') donne un passe-haut.

  Le prototype analogique est transformé par la bilinéaire, avec
  pré-distorsion de la fréquence, comme le fait MATLAB.

  Exemple :
     [b, a] = cheby1(2, 1, 0.3);

  Voir aussi BUTTER, CHEBY2, FIR1.
```

## `cheby2`

```
CHEBY2 Filtre de Chebyshev de type II, ondulation en bande atténuée.
  [B,A] = CHEBY2(N,RS,WN) : RS est l'atténuation minimale en décibels
  dans la bande coupée.
```

## `chirp`

```
CHIRP Sinusoïde à fréquence instantanée variable.
  Y = CHIRP(T,F0,T1,F1) balaie linéairement de F0 (à t=0) à F1 (à t=T1).
  Y = CHIRP(T,F0,T1,F1,'quadratic') fait un balayage quadratique.
```

## `corrmtx`

```
CORRMTX Matrice de données pour l'estimation de la corrélation.
  X = CORRMTX(V,M,METHODE) rend une matrice rectangulaire dont X'*X est
  une estimation de la matrice d'autocorrélation d'ordre M+1. METHODE
  vaut 'autocorrelation' (par défaut), 'prewindowed', 'postwindowed',
  'covariance' ou 'modified'.

  [X,R] = CORRMTX(...) rend aussi X'*X.

  Exemple :
     [X, R] = corrmtx(randn(100,1), 4, 'modified');
```

## `cpsd`

```
CPSD Densité interspectrale de puissance, par la méthode de Welch.
  [PXY,F] = CPSD(X,Y,...) : même découpage que PWELCH, mais le produit
  croisé X conjugué par Y.
```

## `czt`

```
CZT Transformée en Z sur une spirale (algorithme de Bluestein).
  G = CZT(X,M,W,A) évalue la transformée en Z de X en M points pris sur
  la spirale A*W^(-k). Avec M = N, W = exp(-2i*pi/N) et A = 1, c'est la
  transformée de Fourier discrète.

  Exemple :
     n = 8; norm(czt(1:n) - fft((1:n)')) < 1e-10
```

## `dct`

```
DCT Transformée en cosinus discrète de type II, normalisée.
  Y = DCT(X) applique la transformée utilisée par MATLAB :
     y(k) = w(k) * sum_{m=1}^{N} x(m) cos(pi (2m-1)(k-1) / (2N))
  avec w(1) = 1/sqrt(N) et w(k) = sqrt(2/N) sinon.
```

## `decimate`

```
DECIMATE Réduit la fréquence d'échantillonnage d'un facteur entier.
  Y = DECIMATE(X,R) filtre X passe-bas puis garde un échantillon sur R.
  Le filtre est un RIF d'ordre 30 par défaut, appliqué en phase nulle
  pour ne pas décaler le signal ; DECIMATE(X,R,N) choisit l'ordre.

  Exemple :
     numel(decimate(1:100, 4))   % 25
```

## `demod`

```
DEMOD Démodulation, réciproque de MODULATE.
  X = DEMOD(Y,FC,FS,METHODE). La démodulation d'amplitude multiplie par
  la porteuse puis filtre passe-bas ; celle de phase et de fréquence
  passe par la transformée de Hilbert.
```

## `dftmtx`

```
DFTMTX Matrice de la transformée de Fourier discrète.
  M = DFTMTX(N) : M*X vaut FFT(X). La matrice coûte N^2 : elle sert à
  raisonner, pas à calculer.
```

## `diric`

```
DIRIC Fonction de Dirichlet, ou sinus cardinal périodique.
  Y = DIRIC(X,N) vaut sin(N X/2)/(N sin(X/2)), prolongée par
  (-1)^(k(N-1)) aux multiples de 2 pi.

  C'est la transformée de Fourier de la fenêtre rectangulaire de N
  points, normalisée.

  Exemple :  diric(0, 5)   % 1
```

## `dpss`

```
DPSS Suites sphéroïdales aplaties discrètes, ou fenêtres de Slepian.
  [E,V] = DPSS(N,NW,K) rend les K premières suites de longueur N et de
  produit temps-bande NW, ainsi que leurs taux de concentration V.

  Ce sont les suites de longueur N dont l'énergie est la plus
  concentrée dans la bande [-NW/N, NW/N]. Elles s'obtiennent comme
  vecteurs propres d'une matrice tridiagonale symétrique qui commute
  avec le noyau de concentration : c'est numériquement bien plus sûr
  que de diagonaliser le noyau lui-même, et la structure tridiagonale
  permet de n'extraire que les K vecteurs voulus, par bissection sur la
  suite de Sturm puis itération inverse.

  Exemple :
     [E, V] = dpss(128, 4, 7);   % sept fenêtres, V proches de 1
```

## `dst`

```
DST Transformée en sinus discrète, première espèce.
  Y(k) = somme des X(n) sin(pi n k/(N+1)), k = 1..N.

  Exemple :  dst([1 0 0])   % [sin(pi/4) sin(pi/2) sin(3pi/4)]
```

## `dutycycle`

```
DUTYCYCLE Rapport cyclique des impulsions.
  D = DUTYCYCLE(X,FS) rend, pour chaque période, la largeur de
  l'impulsion divisée par la période.

  Exemple :
     dutycycle([0 1 1 0 0 1 1 0 0 1], 1)   % environ 0.5
```

## `enbw`

```
ENBW Largeur de bande de bruit équivalente d'une fenêtre.
  B = ENBW(W) rend N*sum(w.^2)/sum(w)^2, en bacs de la transformée.
  ENBW(W,FS) la donne en hertz.

  Exemple :  enbw(rectwin(10))   % 1
```

## `envelope`

```
ENVELOPE Enveloppes supérieure et inférieure d'un signal.
  [H,B] = ENVELOPE(X) utilise le module du signal analytique.
```

## `falltime`

```
FALLTIME Temps de descente d'un signal à deux états.
  Symétrique de RISETIME : de 90 % à 10 % sur chaque front descendant.
```

## `finddelay`

```
FINDDELAY Retard entre deux signaux, par corrélation croisée.
  D = FINDDELAY(X,Y) : Y est en retard de D échantillons sur X quand D
  est positif.

  Exemple :
     x = [1 2 3 0 0]; y = [0 0 1 2 3]; finddelay(x, y)   % 2
```

## `findpeaks`

```
FINDPEAKS Maxima locaux d'un signal.
  PICS = FINDPEAKS(X) rend les valeurs des maxima locaux.
  [PICS,POS] = FINDPEAKS(X) rend aussi leurs indices.
  Options par paires : 'MinPeakHeight', 'MinPeakDistance'.
```

## `fir1`

```
FIR1 Filtre à réponse impulsionnelle finie, par fenêtrage.
  B = FIR1(N,WN) conçoit un passe-bas d'ordre N dont la fréquence de
  coupure normalisée est WN (1 correspond à la moitié de la fréquence
  d'échantillonnage). B contient N+1 coefficients.
  B = FIR1(N,WN,'high') conçoit un passe-haut.
  B = FIR1(N,[W1 W2]) conçoit un passe-bande.
  B = FIR1(N,[W1 W2],'stop') conçoit un coupe-bande.

  La fenêtre de Hamming est appliquée par défaut, comme dans la
  documentation MathWorks.
```

## `fir2`

```
FIR2 Filtre RIF défini par un gabarit de réponse en fréquence.
  B = FIR2(N,F,M) conçoit un filtre d'ordre N dont le module suit la
  courbe donnée par les points (F,M). F va de 0 à 1, 1 étant la moitié
  de la fréquence d'échantillonnage, et doit être croissant.

  La méthode est celle de l'échantillonnage en fréquence : on
  interpole le gabarit sur une grille fine, on repasse en temps par
  transformée inverse, puis on fenêtre.

  Exemple :
     b = fir2(20, [0 0.5 0.5 1], [1 1 0 0]);
```

## `firtype`

```
FIRTYPE Type d'un filtre RIF à phase linéaire, de 1 à 4.
  Type 1 : symétrique, longueur impaire.  Type 2 : symétrique, paire.
  Type 3 : antisymétrique, impaire.       Type 4 : antisymétrique, paire.
```

## `flattopwin`

```
FLATTOPWIN Fenêtre à sommet plat, pour la mesure d'amplitude.
  Coefficients de MathWorks : 0,21557895 ; 0,41663158 ; 0,277263158 ;
  0,083578947 ; 0,006947368.
```

## `freqs`

```
FREQS Réponse en fréquence d'un filtre analogique.
  H = FREQS(B,A,W) évalue B(s)/A(s) en s = j*W. Sans W, deux cents
  points logarithmiques couvrant les pôles et les zéros.

  Exemple :  abs(freqs(1, [1 1], 1))   % 1/sqrt(2), le passe-bas RC
```

## `fwht`

```
FWHT Transformée de Walsh-Hadamard rapide.
  Y = FWHT(X) transforme X, dont la longueur est complétée à la
  puissance de deux supérieure. Le facteur 1/N est porté par la
  transformée directe, comme dans MATLAB.

  Y = FWHT(X,N) impose la longueur. Y = FWHT(X,N,ORDRE) choisit
  l'ordre des fonctions de Walsh : 'sequency' (par défaut, rangées par
  nombre de changements de signe), 'hadamard' (ordre naturel de la
  construction de Sylvester) ou 'dyadic' (ordre de Paley).

  Exemple :
     fwht([1 0 0 0])   % [0.25 0.25 0.25 0.25]
```

## `gauspuls`

```
GAUSPULS Impulsion sinusoïdale à enveloppe gaussienne.
  YI = GAUSPULS(T,FC,BW,BWR) : porteuse à FC hertz, largeur de bande
  relative BW mesurée à BWR décibels. FC vaut 1000, BW 0,5 et BWR -6.

  [YI,YQ,YE] = GAUSPULS(...) rend aussi la voie en quadrature et
  l'enveloppe.

  TC = GAUSPULS('cutoff',FC,BW,BWR,TPE) rend l'instant où l'enveloppe
  retombe TPE décibels sous son maximum.

  Exemple :
     t = -1e-3:1e-6:1e-3;  y = gauspuls(t, 1e4, 0.6);
```

## `gausswin`

```
GAUSSWIN Fenêtre gaussienne.
  W = GAUSSWIN(N,ALPHA) où ALPHA est l'inverse de l'écart-type, en
  demi-largeurs. ALPHA vaut 2,5 par défaut.

  W(k) = exp(-0.5 * (ALPHA * (2k/(N-1) - 1))^2).
```

## `goertzel`

```
GOERTZEL Composantes choisies de la transformée de Fourier discrète.
  Y = GOERTZEL(X,K) rend X(k) pour les indices K donnés, calculés par
  l'algorithme de Goertzel : un filtre du second ordre par indice, ce qui
  coûte moins qu'une transformée complète quand on ne veut qu'un raie.

  Les indices suivent la convention de MATLAB : 1 correspond à la
  composante continue.

  Exemple :
     x = [1 2 3 4]; abs(goertzel(x, 1) - sum(x)) < 1e-12
```

## `grpdelay`

```
GRPDELAY Temps de propagation de groupe d'un filtre numérique.
  [GD,W] = GRPDELAY(B,A,N) rend le retard de groupe, en échantillons,
  sur N points entre 0 et pi.

  Le retard est -d(arg H)/dw ; il se calcule ici par la formule exacte
  Re{ (B'(w)/B(w)) - (A'(w)/A(w)) }, où les dérivées viennent de la
  pondération des coefficients par leur indice.
```

## `hilbert`

```
HILBERT Signal analytique par transformée de Hilbert.
  Y = HILBERT(X) rend un signal complexe dont la partie réelle est X et
  la partie imaginaire sa transformée de Hilbert.
```

## `icceps`

```
ICCEPS Cepstre complexe inverse.
  X = ICCEPS(XHAT,ND) reconstitue le signal à partir de son cepstre
  complexe et du retard ND rendu par CCEPS.
```

## `idct`

```
IDCT Transformée en cosinus discrète inverse.
```

## `idst`

```
IDST Transformée en sinus discrète inverse.
  La matrice de la DST-I est symétrique et son carré vaut (N+1)/2 fois
  l'identité : l'inverse n'est donc qu'un facteur d'échelle.
```

## `ifwht`

```
IFWHT Transformée de Walsh-Hadamard inverse.
  La transformée directe porte le facteur 1/N ; l'inverse n'en a pas.

  Exemple :
     ifwht(fwht([1 2 3 4]))   % [1 2 3 4]
```

## `impz`

```
IMPZ Réponse impulsionnelle d'un filtre numérique.
  [H,T] = IMPZ(B,A,N) rend les N premiers points de la réponse à une
  impulsion unité. Sans N, la longueur est choisie assez grande pour que
  la réponse soit retombée.

  Exemple :
     impz(1, [1 -0.5], 4)'   % [1 0.5 0.25 0.125]
```

## `interp`

```
INTERP Augmente la fréquence d'échantillonnage d'un facteur entier.
  Y = INTERP(X,R) insère R-1 zéros entre les échantillons puis filtre
  passe-bas ; le résultat a R fois plus de points, et le gain est
  compensé pour que l'amplitude soit conservée.
```

## `islinphase`

```
ISLINPHASE Le filtre est-il à phase linéaire ?
  Un RIF est à phase linéaire si ses coefficients sont symétriques ou
  antisymétriques. Un RII ne l'est qu'avec un dénominateur trivial.
```

## `ismaxphase`

```
ISMAXPHASE Le filtre est-il à phase maximale ?
  Tous les zéros sont hors du cercle unité, les pôles dedans.
```

## `isminphase`

```
ISMINPHASE Le filtre est-il à phase minimale ?
  Tous les zéros et tous les pôles doivent être dans le cercle unité.
```

## `isstable`

```
ISSTABLE Le filtre est-il stable ?
  Un filtre numérique est stable si tous ses pôles sont strictement à
  l'intérieur du cercle unité.

  ISSTABLE(SOS) accepte aussi une matrice de sections du second ordre.
```

## `kaiser`

```
KAISER Fenêtre de Kaiser.
  W = KAISER(N,BETA) rend la fenêtre de Kaiser de N points, de paramètre
  BETA. BETA vaut 0,5 par défaut. La fenêtre est symétrique.

  Elle vaut I0(BETA*sqrt(1-(2k/(N-1)-1)^2)) / I0(BETA), où I0 est la
  fonction de Bessel modifiée de première espèce d'ordre zéro.

  Exemple :
     w = kaiser(5, 5);   % w(3) == 1

  Voir aussi HAMMING, HANN, BLACKMAN, CHEBWIN, KAISERORD.
```

## `kaiserord`

```
KAISERORD Ordre et paramètre d'un filtre RIF fenêtré par Kaiser.
  [N,WN,BETA,GENRE] = KAISERORD(F,A,DEV,FS) applique les formules de
  Kaiser : BETA dépend de l'atténuation demandée, et N de la largeur de
  la bande de transition.

  Exemple :
     [n, Wn, beta] = kaiserord([1000 1200], [1 0], [0.05 0.01], 8000);
```

## `lireOptionsSousEspace`

```
LIREOPTIONSSOUSESPACE Analyse les arguments communs aux méthodes sous-espace.
  Reconnaît une fréquence d'échantillonnage et le mot-clé 'corr'.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `lsf2poly`

```
LSF2POLY Polynôme de prédiction à partir des fréquences de raies.
  Inverse de POLY2LSF : les racines de rangs pairs reconstituent Q,
  celles de rangs impairs P, et A = (P + Q)/2.
```

## `meanfreq`

```
MEANFREQ Fréquence moyenne, pondérée par la puissance spectrale.
  F = MEANFREQ(X,FS) rend le barycentre du spectre.
```

## `medfilt1`

```
MEDFILT1 Filtre médian glissant d'ordre N.
  Y = MEDFILT1(X,N) remplace chaque échantillon par la médiane de la
  fenêtre de N points centrée dessus. N vaut 3 par défaut.
```

## `medfreq`

```
MEDFREQ Fréquence médiane : celle qui coupe la puissance en deux.
```

## `midcross`

```
MIDCROSS Instants de traversée du niveau médian.
  [C,NIVEAU] = MIDCROSS(X,FS) rend les instants où le signal coupe le
  niveau à mi-chemin entre ses deux états, et ce niveau.

  Exemple :
     midcross([0 0 1 1], 1)   % 1.5 : la moitié est franchie là
```

## `modulate`

```
MODULATE Modulation d'un signal en bande de base.
  Y = MODULATE(X,FC,FS,METHODE) où METHODE vaut 'am' (double bande à
  porteuse supprimée, par défaut), 'amdsb-tc' (porteuse transmise),
  'fm', 'pm' ou 'qam'.

  Exemple :
     fs = 1e4;  x = sin(2*pi*10*(0:999)'/fs);
     y = modulate(x, 1e3, fs, 'am');
```

## `mscohere`

```
MSCOHERE Cohérence quadratique moyenne entre deux signaux.
  C = MSCOHERE(X,Y,...) vaut |Pxy|^2 / (Pxx*Pyy) : entre 0 et 1, elle
  dit quelle part de Y s'explique linéairement par X, fréquence par
  fréquence.
```

## `nuttallwin`

```
NUTTALLWIN Fenêtre de Blackman-Nuttall à quatre termes.
  Coefficients : 0,3635819 ; 0,4891775 ; 0,1365995 ; 0,0106411.
```

## `overshoot`

```
OVERSHOOT Dépassement après chaque transition, en pourcentage.
  Le dépassement est mesuré entre le niveau d'état atteint et
  l'extremum observé après la transition, rapporté à l'écart entre les
  deux états. Il vaut zéro si le signal ne dépasse pas.

  Exemple :
     overshoot([0 0 1.2 1 1 1], 1)   % 20 %
```

## `papillonHadamard`

```
PAPILLONHADAMARD Transformée de Hadamard rapide, ordre naturel.
  Chaque étage remplace un couple (a,b) par (a+b, a-b) : c'est la
  construction de Sylvester appliquée en place, en N log2 N additions.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `parzenwin`

```
PARZENWIN Fenêtre de Parzen, ou de de la Vallée Poussin.
```

## `pburg`

```
PBURG Densité spectrale par la méthode de Burg.
  Même principe que PYULEAR, avec un modèle estimé par ARBURG : plus
  sûr sur les séries courtes.
```

## `pcov`

```
PCOV Densité spectrale par la méthode de la covariance.
```

## `peak2peak`

```
PEAK2PEAK Écart entre le maximum et le minimum.
  Exemple :  peak2peak([1 5 2])   % 4
```

## `peak2rms`

```
PEAK2RMS Rapport entre la valeur crête et la valeur efficace.
  Exemple :  peak2rms([1 -1 1 -1])   % 1
```

## `peig`

```
PEIG Pseudospectre par la méthode des vecteurs propres.
  Comme PMUSIC, avec chaque vecteur du sous-espace bruit pondéré par
  l'inverse de sa valeur propre.
```

## `periodogram`

```
PERIODOGRAM Densité spectrale de puissance par périodogramme.
  [PXX,F] = PERIODOGRAM(X) estime la densité spectrale de X.
  [PXX,F] = PERIODOGRAM(X,FENETRE,NFFT,FS) précise la fenêtre, la taille
  de la transformée et la fréquence d'échantillonnage.
```

## `permutationWalsh`

```
PERMUTATIONWALSH Rangement des fonctions de Walsh.
  Rend le vecteur d'indices qui fait passer de l'ordre naturel de
  Sylvester à l'ordre demandé : 'hadamard' (identité), 'dyadic'
  (renversement des bits, ordre de Paley) ou 'sequency' (renversement
  puis code de Gray, rangement par nombre de changements de signe).

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `phasedelay`

```
PHASEDELAY Retard de phase d'un filtre numérique.
  Le retard de phase vaut -phi(w)/w. Pour un filtre à phase linéaire
  d'ordre N il vaut N/2 échantillons, constant.
```

## `phasez`

```
PHASEZ Réponse en phase déroulée d'un filtre numérique.
  [PHI,W] = PHASEZ(B,A,N) rend la phase continue sur N points entre 0
  et pi, comme FREQZ pour le module.
```

## `pmcov`

```
PMCOV Densité spectrale par la méthode de la covariance modifiée.
```

## `pmtm`

```
PMTM Densité spectrale par la méthode multi-fenêtres de Thomson.
  [PXX,F] = PMTM(X,NW,NFFT,FS) moyenne les périodogrammes obtenus avec
  les 2*NW-1 premières fenêtres de Slepian, pondérés par leur taux de
  concentration. NW vaut 4 par défaut.

  Chaque fenêtre voit le signal autrement : la moyenne réduit la
  variance de l'estimation sans élargir autant qu'un lissage.

  Exemple :
     [pxx, f] = pmtm(x, 4, 512, 1000);
```

## `pmusic`

```
PMUSIC Pseudospectre par la méthode MUSIC.
  [S,F] = PMUSIC(X,P,NFFT,FS) rend l'inverse de la projection du
  vecteur directeur sur le sous-espace bruit : le pseudospectre monte
  très haut aux fréquences présentes, mais ses valeurs ne sont pas des
  puissances.

  Exemple :
     [S, f] = pmusic(x, 4, 1024, 1000);
```

## `poly2ac`

```
POLY2AC Autocorrélation d'un polynôme de prédiction.
  R = POLY2AC(A,EFINAL) rend la suite d'autocorrélation dont A est le
  filtre de prédiction et EFINAL l'erreur résiduelle.
```

## `poly2lsf`

```
POLY2LSF Fréquences spectrales de raies d'un polynôme de prédiction.
  LSF = POLY2LSF(A) forme les polynômes somme et différence
     P(z) = A(z) + z^-(p+1) A(1/z),   Q(z) = A(z) - z^-(p+1) A(1/z),
  dont toutes les racines sont sur le cercle unité et s'entrelacent.
  Les LSF sont leurs arguments, rangés par ordre croissant dans
  ]0, pi[. C'est la représentation utilisée par les codeurs de parole :
  elle se quantifie sans perdre la stabilité.

  Exemple :
     lsf = poly2lsf([1 -0.5]);
```

## `poly2rc`

```
POLY2RC Coefficients de réflexion d'un polynôme de prédiction.
  K = POLY2RC(A) applique la récurrence de Levinson à l'envers : à
  chaque étape, le dernier coefficient du polynôme d'ordre M est le
  coefficient de réflexion K(M), et le polynôme d'ordre M-1 s'en
  déduit.

  [K,E] = POLY2RC(A,EFINAL) rend aussi les erreurs de prédiction de
  chaque ordre, à partir de l'erreur finale.

  Exemple :
     k = poly2rc([1 0.6149 0.9899 0 0.0031 -0.0082]);
```

## `polystab`

```
POLYSTAB Stabilise un polynôme en repliant ses racines dans le disque.
  B = POLYSTAB(A) remplace chaque racine de module supérieur à 1 par son
  inverse conjugué : le module de la réponse est conservé, mais le
  polynôme devient à phase minimale.
```

## `prototypeVersNumerique`

```
PROTOTYPEVERSNUMERIQUE Prototype analogique -> filtre numérique.
  Applique la transformation passe-bas ou passe-haut puis la
  transformation bilinéaire, avec pré-distorsion de la fréquence :
  omega = 2*tan(pi*Wn/2), comme le veut la conception de MATLAB.
  GAINREFERENCE est le module attendu en continu (passe-bas) ou à
  Nyquist (passe-haut) ; il vaut 1 par défaut, mais un Chebyshev de
  type I d'ordre pair descend à 10^(-RP/20).
```

## `puissancesSousEspace`

```
PUISSANCESSOUSESPACE Puissance de chaque composante sinusoïdale.
  La matrice de corrélation vaut A P A' + sigma^2 I ; sigma^2 est la
  moyenne des plus petites valeurs propres, et P se lit par moindres
  carrés une fois les fréquences connues.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `pulseperiod`

```
PULSEPERIOD Période des impulsions.
  P = PULSEPERIOD(X,FS) rend l'écart entre deux fronts montants
  consécutifs, mesuré au niveau médian.
```

## `pulsesep`

```
PULSESEP Séparation entre impulsions.
  S = PULSESEP(X,FS) rend l'écart entre la fin d'une impulsion et le
  début de la suivante, mesuré au niveau médian.
```

## `pulsewidth`

```
PULSEWIDTH Largeur des impulsions à mi-hauteur.
  W = PULSEWIDTH(X,FS) rend la durée entre le front montant et le front
  descendant qui le suit, mesurée au niveau médian.

  PULSEWIDTH(...,'Polarity','negative') mesure les creux.
```

## `pulstran`

```
PULSTRAN Train d'impulsions.
  Y = PULSTRAN(T,D,@FONC,...) somme les impulsions FONC(T-D(k)). Si D
  a deux colonnes, la seconde donne l'amplitude de chaque impulsion.

  Y = PULSTRAN(T,D,P,FS) répète le prototype échantillonné P, supposé
  échantillonné à FS hertz, par interpolation linéaire.

  Exemple :
     t = 0:1/1e3:1;  y = pulstran(t, 0:0.1:1, @rectpuls, 0.02);
```

## `pwelch`

```
PWELCH Densité spectrale par la méthode de Welch.
  [PXX,F] = PWELCH(X,LONGUEUR,RECOUVREMENT,NFFT,FS) découpe X en
  segments qui se recouvrent, fenêtre chacun, et moyenne les
  périodogrammes.
```

## `pyulear`

```
PYULEAR Densité spectrale par un modèle autorégressif de Yule-Walker.
  [PXX,F] = PYULEAR(X,P,NFFT,FS). Le spectre paramétrique n'a pas de
  lobes de fuite : il est lisse, et sa résolution ne dépend pas de la
  longueur de l'enregistrement mais de l'ordre choisi.

  Exemple :
     [pxx, f] = pyulear(x, 8, 512, 1000);
```

## `rangerWalsh`

```
RANGERWALSH Passe de l'ordre naturel à l'ordre demandé.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `rangerWalshInverse`

```
RANGERWALSHINVERSE Revient de l'ordre demandé à l'ordre naturel.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `rc2ac`

```
RC2AC Autocorrélation à partir des coefficients de réflexion.
  R = RC2AC(K,R0) remonte la récurrence de Levinson : à chaque ordre,
  le nouveau terme d'autocorrélation se déduit du polynôme courant.
```

## `rc2poly`

```
RC2POLY Polynôme de prédiction à partir des coefficients de réflexion.
  A = RC2POLY(K) applique la récurrence de Levinson dans le sens
  direct. C'est l'inverse de POLY2RC.

  [A,E] = RC2POLY(K,R0) rend aussi l'erreur de prédiction finale, à
  partir de la puissance R0 du signal.
```

## `rceps`

```
RCEPS Cepstre réel.
  Y = RCEPS(X) rend le cepstre réel, transformée de Fourier inverse du
  logarithme du module du spectre.

  [Y,YM] = RCEPS(X) rend aussi la version à phase minimale de X : le
  cepstre est replié sur les temps positifs, puis exponentié.

  Exemple :
     y = rceps([1 0 0 0 0.5 0 0 0]);   % un écho à l'échantillon 5
```

## `rectpuls`

```
RECTPULS Impulsion rectangulaire de largeur W centrée en zéro.
  L'impulsion vaut 1 sur [-W/2, W/2[ et 0 ailleurs ; W vaut 1 par défaut.

  Exemple :  rectpuls([-1 -0.4 0 0.4 1])   % [0 1 1 1 0]
```

## `resample`

```
RESAMPLE Rééchantillonnage d'un facteur rationnel P/Q.
  Y = RESAMPLE(X,P,Q) interpole linéairement le signal sur la nouvelle
  grille temporelle.
```

## `residuez`

```
RESIDUEZ Éléments simples d'une fraction en z^-1.
  [R,P,K] = RESIDUEZ(B,A) décompose

     B(z)     R(1)                R(n)
     ---- = ----------- + ... + ----------- + K(1) + K(2) z^-1 + ...
     A(z)   1-P(1)z^-1          1-P(n)z^-1

  B et A sont donnés en puissances croissantes de z^-1, comme pour
  FILTER. Le calcul passe par RESIDUE sur la variable w = z^-1 : un
  terme R/(w-P) s'y réécrit (-R/P)/(1-w/P), d'où P -> 1/P.

  Exemple :
     [r,p] = residuez(1, [1 -0.5])   % r = 1, p = 0.5
```

## `risetime`

```
RISETIME Temps de montée d'un signal à deux états.
  R = RISETIME(X,FS) rend, pour chaque front montant, la durée entre le
  passage à 10 % et le passage à 90 % de l'écart entre les deux états.

  RISETIME(...,'PercentReferenceLevels',[BAS HAUT]) change les seuils.

  Exemple :
     risetime([0 0 0.5 1 1], 1)   % 0.8 : de 10 % à 90 %
```

## `rms`

```
RMS Valeur efficace (racine de la moyenne des carrés).
```

## `rooteig`

```
ROOTEIG Fréquences par la méthode des vecteurs propres.
  Comme ROOTMUSIC, mais chaque vecteur propre du sous-espace bruit est
  pondéré par l'inverse de sa valeur propre : les directions les moins
  bruitées pèsent davantage.
```

## `rootmusic`

```
ROOTMUSIC Fréquences par la méthode MUSIC, racines du polynôme du bruit.
  W = ROOTMUSIC(X,P) estime les P fréquences, en radians par
  échantillon, de P exponentielles complexes noyées dans du bruit. Une
  sinusoïde réelle en compte deux : lui donner P = 2.

  W = ROOTMUSIC(X,P,FS) rend les fréquences en hertz.
  W = ROOTMUSIC(R,P,'corr') prend R pour matrice de corrélation.

  [W,POW] = ROOTMUSIC(...) estime aussi la puissance de chaque
  composante.

  La méthode ne cherche pas un maximum de spectre : elle prend les
  racines du polynôme formé par le sous-espace bruit, ce qui donne des
  fréquences continues, sans quantification par une grille.

  Exemple :
     n = (0:99)';
     x = 2*cos(0.4*pi*n) + cos(0.6*pi*n) + 0.1*randn(100,1);
     w = rootmusic(x, 4);
```

## `rssq`

```
RSSQ Racine de la somme des carrés.
  Exemple :  rssq([3 4])   % 5
```

## `sawtooth`

```
SAWTOOTH Signal en dents de scie de période 2*pi.
  Y = SAWTOOTH(T) monte de -1 à +1 sur chaque période.
  Y = SAWTOOTH(T,LARGEUR) place le sommet à LARGEUR*2*pi.
```

## `schurrc`

```
SCHURRC Coefficients de réflexion par l'algorithme de Schur.
  [K,E] = SCHURRC(R) applique la récurrence de Schur sur la suite
  d'autocorrélation : elle donne les mêmes coefficients de réflexion
  que Levinson-Durbin sans former le polynôme de prédiction, ce qui la
  rend plus stable numériquement et parallélisable.

  Exemple :
     k = schurrc([1 0.5 0.25]);   % [-0.5 0]
```

## `seqperiod`

```
SEQPERIOD Période la plus courte qui explique une séquence.
  P = SEQPERIOD(X) cherche le plus petit P tel que X(k+P) = X(k) pour
  tout k possible. Sans période exacte, rend celle qui minimise l'écart.

  Exemple :  seqperiod([1 2 1 2 1 2])   % 2
```

## `settlingtime`

```
SETTLINGTIME Temps d'établissement après chaque transition.
  S = SETTLINGTIME(X,FS,D) rend la durée entre la traversée médiane et
  l'instant à partir duquel le signal reste dans une bande de D pour
  cent de l'écart entre états autour du niveau atteint. D vaut 2 par
  défaut.
```

## `sfdr`

```
SFDR Plage dynamique libre de parasites, en décibels.
  R = SFDR(X) compare la puissance du fondamental à celle du plus fort
  parasite, harmonique ou non.

  Exemple :
     t = (0:999)'/1000;
     sfdr(cos(2*pi*50*t) + 0.01*cos(2*pi*130*t))   % environ 40 dB
```

## `sgolay`

```
SGOLAY Matrice de lissage de Savitzky-Golay.
  B = SGOLAY(K,F) rend la matrice F x F de projection sur les polynômes
  de degré K : la ligne centrale de B est le filtre à appliquer au
  milieu du signal, les autres lignes traitent les bords.

  [B,G] = SGOLAY(K,F) rend aussi la matrice des différentiateurs : la
  colonne j+1 de G donne le filtre de la dérivée j-ième, au facteur
  j! près.

  Exemple :
     b = sgolay(2, 5);   % lissage quadratique sur cinq points
```

## `sgolayfilt`

```
SGOLAYFILT Lissage polynomial de Savitzky-Golay.
  Y = SGOLAYFILT(X,ORDRE,LONGUEUR) ajuste, sur chaque fenêtre de
  LONGUEUR points, un polynôme de degré ORDRE au sens des moindres
  carrés, et garde la valeur ajustée au centre.
```

## `signalLobe`

```
SIGNALLOBE Puissance d'un lobe spectral autour de la raie K.
  On somme de part et d'autre du sommet tant que le spectre décroît :
  la fuite de la fenêtre est ainsi ramassée avec la raie.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `signalMatriceCorrelation`

```
SIGNALMATRICECORRELATION Matrice d'autocorrélation pour les méthodes sous-espace.
  Si le premier argument est déjà une matrice de corrélation carrée, on
  la prend telle quelle. Sinon on l'estime par la méthode de la
  covariance modifiée, avant et arrière, sur une fenêtre d'ordre
  suffisant pour laisser un sous-espace bruit non vide.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `signalNiveaux`

```
SIGNALNIVEAUX Niveaux d'état et seuils de référence d'un signal.
  Traduit des pourcentages de l'écart entre les deux états en valeurs
  absolues, comme le font toutes les mesures de transition de MATLAB.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `signalSommet`

```
SIGNALSOMMET Indice du maximum local le plus proche de AUTOUR.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `signalSpectrePuissance`

```
SIGNALSPECTREPUISSANCE Spectre de puissance unilatéral, fenêtre de Kaiser.
  Normalisé pour que la somme sur le lobe d'une sinusoïde d'amplitude A
  rende A^2/2, sa puissance. La fenêtre de Kaiser à beta = 38 est celle
  que MATLAB emploie pour ses mesures de distorsion : ses lobes
  secondaires à -180 dB laissent voir des harmoniques très faibles.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `signalTransitions`

```
SIGNALTRANSITIONS Découpe le signal en transitions et les mesure.
  Rend une matrice à cinq colonnes : instant de la traversée basse,
  instant de la traversée haute, instant de la traversée médiane,
  polarité (+1 montante, -1 descendante) et indice de l'échantillon de
  la traversée médiane.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `signalTraverses`

```
SIGNALTRAVERSES Instants de traversée d'un seuil, par interpolation.
  Rend les instants où X coupe SEUIL et, pour chacun, un booléen vrai
  si la traversée est montante.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `sinad`

```
SINAD Rapport signal sur bruit et distorsion, en décibels.
  R = SINAD(X) compare la puissance du fondamental à celle de tout le
  reste, harmoniques et bruit confondus, la composante continue exclue.

  Exemple :
     t = (0:999)'/1000;
     sinad(cos(2*pi*50*t) + 0.1*cos(2*pi*100*t))   % environ 20 dB
```

## `slewrate`

```
SLEWRATE Vitesse de balayage d'un signal à deux états.
  S = SLEWRATE(X,FS) rend, pour chaque transition, la pente moyenne
  entre les seuils bas et haut : l'écart d'amplitude divisé par la
  durée. La pente est négative sur un front descendant.

  Exemple :
     slewrate([0 0 1 1], 1)   % 0.8/0.8 = 1 par seconde
```

## `snr`

```
SNR Rapport signal sur bruit, en décibels.
  R = SNR(SIGNAL,BRUIT) rend 10*log10(puissance signal / puissance bruit).
```

## `sos2ss`

```
SOS2SS Représentation d'état d'un enchaînement de sections du second ordre.
```

## `sos2tf`

```
SOS2TF Sections du second ordre vers fonction de transfert.
```

## `sos2zp`

```
SOS2ZP Zéros, pôles et gain d'un enchaînement de sections du second ordre.
  [Z,P,K] = SOS2ZP(SOS,G) où SOS a une section par ligne, sous la forme
  [b0 b1 b2 a0 a1 a2].
```

## `sosfilt`

```
SOSFILT Filtre par sections du second ordre, en cascade.
  Y = SOSFILT(SOS,X) applique chaque ligne de SOS l'une après l'autre.
  C'est la forme numériquement stable pour les filtres d'ordre élevé.
```

## `spectrogram`

```
SPECTROGRAM Transformée de Fourier à court terme.
  S = SPECTROGRAM(X,FENETRE,RECOUVREMENT,NFFT,FS) découpe X en tranches
  pondérées par FENETRE, qui se recouvrent de RECOUVREMENT points, et
  rend une colonne de spectre par tranche. Comme dans MATLAB, seules les
  fréquences positives sont gardées pour un signal réel.

  [S,F,T] = SPECTROGRAM(...) rend aussi l'axe des fréquences et celui
  des instants, pris au centre de chaque tranche.

  Exemple :
     [s, f, t] = spectrogram(sin(2*pi*50*(0:999)/1000), 128, 64, 128, 1000);
```

## `square`

```
SQUARE Signal carré de période 2*pi.
  Y = SQUARE(T) vaut +1 sur la première moitié de la période, -1 sur la
  seconde. Y = SQUARE(T,RAPPORT) fixe le rapport cyclique en pour cent.
```

## `ss2sos`

```
SS2SOS Sections du second ordre d'une représentation d'état.
```

## `ss2zp`

```
SS2ZP Zéros, pôles et gain d'une représentation d'état.
  Les pôles sont les valeurs propres de A ; les zéros sont les racines
  du numérateur de la fonction de transfert.
```

## `statelevels`

```
STATELEVELS Niveaux bas et haut d'un signal à deux états.
  NIVEAUX = STATELEVELS(X) rend [BAS HAUT] par la méthode de
  l'histogramme : l'étendue est découpée en NBINS classes (100 par
  défaut), séparées en deux moitiés, et chaque niveau est le mode de sa
  moitié. METHODE vaut 'mode' (par défaut) ou 'mean'.

  [NIVEAUX,HISTOGRAMME,BORNES] = STATELEVELS(...) rend aussi le compte
  par classe et les bornes utilisées.

  Exemple :
     statelevels([zeros(1,50) ones(1,50)])   % [0 1]
```

## `stepz`

```
STEPZ Réponse indicielle d'un filtre numérique.
  [H,T] = STEPZ(B,A,N) : la réponse à un échelon unité.
```

## `taylorwin`

```
TAYLORWIN Fenêtre de Taylor.
  W = TAYLORWIN(N,NBAR,SLL) rend la fenêtre de N points dont les NBAR
  premiers lobes secondaires sont proches de SLL décibels, les suivants
  décroissant. NBAR vaut 4 et SLL -30 par défaut.

  C'est la fenêtre des antennes et des radars : à la différence de
  Dolph-Tchebychev, elle ne garde pas des lobes égaux jusqu'au bout, ce
  qui évite les impulsions aux extrémités.

  Exemple :
     w = taylorwin(64, 5, -35);
```

## `tf2sos`

```
TF2SOS Fonction de transfert vers sections du second ordre.
  [SOS,G] = TF2SOS(B,A) rend une matrice Lx6, chaque ligne étant
  [b0 b1 b2 1 a1 a2], et le gain global G. Les pôles complexes sont
  appariés à leur conjugué, ce qui garde des coefficients réels.
```

## `tf2zp`

```
TF2ZP Fonction de transfert vers zéros, pôles et gain.
  [Z,P,K] = TF2ZP(B,A). Les coefficients sont donnés par puissances
  décroissantes ; K est b(1)/a(1).

  Exemple :
     [z, p, k] = tf2zp([1 -1], [1 -0.5]);   % z = 1, p = 0.5, k = 1
```

## `tfestimate`

```
TFESTIMATE Estimation de la fonction de transfert entre deux signaux.
  H = TFESTIMATE(X,Y,...) vaut Pxy/Pxx : la réponse du système qui mène
  de X à Y, au sens des moindres carrés.
```

## `thd`

```
THD Distorsion harmonique totale, en décibels.
  R = THD(X) rend le rapport, en décibels, entre la puissance des
  harmoniques et celle du fondamental. La valeur est négative : plus
  elle est basse, plus le signal est pur.

  R = THD(X,FS,N) prend en compte N harmoniques, six par défaut.

  [R,POW,FREQ] = THD(...) rend aussi la puissance et la fréquence de
  chaque harmonique, fondamental compris.

  Exemple :
     t = (0:999)'/1000;
     x = cos(2*pi*50*t) + 0.1*cos(2*pi*100*t);
     thd(x)      % -20 dB : l'harmonique est dix fois plus petite
```

## `toi`

```
TOI Point d'interception d'ordre trois.
  OIP3 = TOI(X,FS) mesure, sur un signal à deux tons, le niveau
  extrapolé où les produits d'intermodulation d'ordre trois
  rejoindraient les fondamentaux. Le résultat est en décibels par
  rapport à la puissance unité.

  [OIP3,F,FIM] = TOI(...) rend aussi les fréquences des deux tons et
  celles des produits 2f1-f2 et 2f2-f1.

  Exemple :
     t = (0:4095)'/1e4;
     x = cos(2*pi*1000*t) + cos(2*pi*1100*t) + 0.001*cos(2*pi*900*t) ...
         + 0.001*cos(2*pi*1200*t);
     toi(x, 1e4)
```

## `triang`

```
TRIANG Fenêtre triangulaire.
  W = TRIANG(N). Contrairement à BARTLETT, les extrémités ne sont pas
  nulles : c'est la différence que documente MathWorks entre les deux.

  Exemple :
     triang(4)'   % [0.25 0.75 0.75 0.25]
```

## `tripuls`

```
TRIPULS Impulsion triangulaire de largeur W et d'asymétrie S.
  S vaut 0 pour un triangle symétrique, -1 pour une rampe descendante,
  +1 pour une rampe montante. W vaut 1 et S vaut 0 par défaut.

  Exemple :  tripuls([-0.5 -0.25 0 0.25 0.5])   % [0 0.5 1 0.5 0]
```

## `tukeywin`

```
TUKEYWIN Fenêtre de Tukey, cosinus surélevé à rapport réglable.
  W = TUKEYWIN(N,R) : R = 0 donne la fenêtre rectangulaire, R = 1 la
  fenêtre de Hann. R vaut 0,5 par défaut.

  Exemple :
     isequal(tukeywin(8, 0), rectwin(8))   % vrai
```

## `undershoot`

```
UNDERSHOOT Creux avant chaque transition, en pourcentage.
  Symétrique d'OVERSHOOT : l'extremum est cherché avant la transition,
  du côté opposé au niveau de départ.
```

## `vco`

```
VCO Oscillateur commandé en tension.
  Y = VCO(X,FC,FS) rend un cosinus dont la fréquence instantanée suit
  X : X = -1 donne 0 hertz, X = 0 donne FC, X = +1 donne 2*FC.

  Y = VCO(X,[FMIN FMAX],FS) fixe les fréquences des extrêmes -1 et +1.

  Exemple :
     fs = 1e4;  t = (0:fs-1)'/fs;  y = vco(sin(2*pi*t), 1e3, fs);
```

## `window`

```
WINDOW Fabrique une fenêtre par son nom ou sa poignée.
  W = WINDOW(@hamming, N) équivaut à HAMMING(N).
  W = WINDOW(@chebwin, N, R) passe les arguments supplémentaires.

  Exemple :
     w = window(@kaiser, 64, 5);
```

## `xcov`

```
XCOV Covariance croisée : la corrélation des signaux centrés.
  [C,LAGS] = XCOV(X,Y) retranche la moyenne avant de corréler.
  XCOV(X) donne l'autocovariance.

  Exemple :
     c = xcov([1 2 3 4], 'coeff');   % c(4) == 1
```

## `zerophase`

```
ZEROPHASE Réponse en amplitude à phase nulle.
  [HR,W,PHI] = ZEROPHASE(B,A,N) décompose la réponse en fréquence en
  H(e^jw) = HR(w) exp(j PHI(w)) avec HR réelle. Contrairement au
  module, HR peut être négative : son signe porte les sauts de phase
  de pi que provoquent les zéros posés sur le cercle unité.

  Pour un RIF à phase linéaire la décomposition est exacte : retirer le
  retard (N-1)/2 rend la réponse réelle pour les types 1 et 2,
  imaginaire pure pour les types 3 et 4. Sinon l'amplitude vaut le
  module, affecté du signe qui bascule à chaque zéro sur le cercle.

  Exemple :
     [hr, w] = zerophase([1 1]);   % hr = 2 cos(w/2), jamais négatif
```

## `zp2sos`

```
ZP2SOS Zéros et pôles vers sections du second ordre.
  Les racines complexes sont appariées avec leur conjuguée ; les racines
  réelles sont groupées deux par deux. Le résultat est réel.
```

## `zp2ss`

```
ZP2SS Représentation d'état à partir des zéros, pôles et gain.
```

## `zp2tf`

```
ZP2TF Zéros, pôles et gain vers fonction de transfert.
  [B,A] = ZP2TF(Z,P,K) rend les coefficients par puissances décroissantes.
```

## `zplane`

```
ZPLANE Trace les zéros et les pôles dans le plan complexe.
  ZPLANE(B,A) à partir des coefficients, ZPLANE(Z,P) à partir des zéros
  et des pôles. Le cercle unité sert de repère.
```

