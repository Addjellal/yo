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
```

## `alignsignals`

```
ALIGNSIGNALS Aligne deux signaux en compensant leur retard.
  [XA,YA,D] = ALIGNSIGNALS(X,Y) ajoute des zéros en tête du signal en
  avance, de sorte que les deux se superposent.
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

## `dftmtx`

```
DFTMTX Matrice de la transformée de Fourier discrète.
  M = DFTMTX(N) : M*X vaut FFT(X). La matrice coûte N^2 : elle sert à
  raisonner, pas à calculer.
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

## `flattopwin`

```
FLATTOPWIN Fenêtre à sommet plat, pour la mesure d'amplitude.
  Coefficients de MathWorks : 0,21557895 ; 0,41663158 ; 0,277263158 ;
  0,083578947 ; 0,006947368.
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

## `idct`

```
IDCT Transformée en cosinus discrète inverse.
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

## `parzenwin`

```
PARZENWIN Fenêtre de Parzen, ou de de la Vallée Poussin.
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

## `periodogram`

```
PERIODOGRAM Densité spectrale de puissance par périodogramme.
  [PXX,F] = PERIODOGRAM(X) estime la densité spectrale de X.
  [PXX,F] = PERIODOGRAM(X,FENETRE,NFFT,FS) précise la fenêtre, la taille
  de la transformée et la fréquence d'échantillonnage.
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

## `pwelch`

```
PWELCH Densité spectrale par la méthode de Welch.
  [PXX,F] = PWELCH(X,LONGUEUR,RECOUVREMENT,NFFT,FS) découpe X en
  segments qui se recouvrent, fenêtre chacun, et moyenne les
  périodogrammes.
```

## `resample`

```
RESAMPLE Rééchantillonnage d'un facteur rationnel P/Q.
  Y = RESAMPLE(X,P,Q) interpole linéairement le signal sur la nouvelle
  grille temporelle.
```

## `rms`

```
RMS Valeur efficace (racine de la moyenne des carrés).
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

## `seqperiod`

```
SEQPERIOD Période la plus courte qui explique une séquence.
  P = SEQPERIOD(X) cherche le plus petit P tel que X(k+P) = X(k) pour
  tout k possible. Sans période exacte, rend celle qui minimise l'écart.

  Exemple :  seqperiod([1 2 1 2 1 2])   % 2
```

## `sgolayfilt`

```
SGOLAYFILT Lissage polynomial de Savitzky-Golay.
  Y = SGOLAYFILT(X,ORDRE,LONGUEUR) ajuste, sur chaque fenêtre de
  LONGUEUR points, un polynôme de degré ORDRE au sens des moindres
  carrés, et garde la valeur ajustée au centre.
```

## `snr`

```
SNR Rapport signal sur bruit, en décibels.
  R = SNR(SIGNAL,BRUIT) rend 10*log10(puissance signal / puissance bruit).
```

## `sos2tf`

```
SOS2TF Sections du second ordre vers fonction de transfert.
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

## `stepz`

```
STEPZ Réponse indicielle d'un filtre numérique.
  [H,T] = STEPZ(B,A,N) : la réponse à un échelon unité.
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

## `triang`

```
TRIANG Fenêtre triangulaire.
  W = TRIANG(N). Contrairement à BARTLETT, les extrémités ne sont pas
  nulles : c'est la différence que documente MathWorks entre les deux.

  Exemple :
     triang(4)'   % [0.25 0.75 0.75 0.25]
```

## `tukeywin`

```
TUKEYWIN Fenêtre de Tukey, cosinus surélevé à rapport réglable.
  W = TUKEYWIN(N,R) : R = 0 donne la fenêtre rectangulaire, R = 1 la
  fenêtre de Hann. R vaut 0,5 par défaut.

  Exemple :
     isequal(tukeywin(8, 0), rectwin(8))   % vrai
```

## `xcov`

```
XCOV Covariance croisée : la corrélation des signaux centrés.
  [C,LAGS] = XCOV(X,Y) retranche la moyenne avant de corréler.
  XCOV(X) donne l'autocovariance.

  Exemple :
     c = xcov([1 2 3 4], 'coeff');   % c(4) == 1
```

## `zp2sos`

```
ZP2SOS Zéros et pôles vers sections du second ordre.
  Les racines complexes sont appariées avec leur conjuguée ; les racines
  réelles sont groupées deux par deux. Le résultat est réel.
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

