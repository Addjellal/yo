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
%   ellip       - Filtre elliptique, ou de Cauer
%   ellipord    - Ordre minimal d'un elliptique
%   besself     - Filtre analogique de Bessel
%   maxflat     - Butterworth généralisé, degrés numérateur et
%                 dénominateur séparés, ou RIF symétrique
%   prototypeVersNumerique - Prototype analogique -> filtre numérique
%
% Prototypes analogiques et transformations
%   buttap      - Prototype de Butterworth
%   cheb1ap     - Prototype de Chebyshev de type I
%   cheb2ap     - Prototype de Chebyshev de type II
%   ellipap     - Prototype elliptique
%   besselap    - Prototype de Bessel
%   bilinear    - Transformation bilinéaire, avec prédistorsion
%   impinvar    - Transformation par invariance impulsionnelle
%
% Filtrage direct d'un signal
%   lowpass     - Passe-bas appliqué à un signal
%   highpass    - Passe-haut appliqué à un signal
%   bandpass    - Passe-bande appliqué à un signal
%   bandstop    - Coupe-bande appliqué à un signal
%   filtic      - Conditions initiales d'un filtre
%   latcfilt    - Filtrage par une structure en treillis
%   intfilt     - Filtre d'interpolation
%
% Modèles rationnels
%   prony       - Modèle rationnel d'une réponse impulsionnelle
%   stmcb       - Modèle par la méthode de Steiglitz-McBride
%   invfreqz    - Filtre numérique ajusté sur une réponse en fréquence
%   invfreqs    - Filtre analogique ajusté sur une réponse en fréquence
%   rlevinson   - Levinson-Durbin à l'envers
%
% Structures de filtres
%   tf2zp / zp2tf   - Fonction de transfert <-> zéros, pôles, gain
%   tf2sos / sos2tf - Fonction de transfert <-> sections du second ordre
%   zp2sos          - Zéros et pôles -> sections du second ordre
%   sosfilt         - Filtrage en cascade de sections
%   polystab        - Replie les racines dans le disque unité
%   tf2zpk          - Transfert numérique -> zéros, pôles, gain
%   tf2latc / latc2tf - Fonction de transfert <-> treillis
%   convmtx         - Matrice de convolution
%   eqtflength      - Met numérateur et dénominateur à la même longueur
%   polyscale       - Déplace les racines vers l'origine
%
% Mesures et conversions
%   pow2db / db2pow - Puissance <-> décibels
%   mag2db / db2mag - Amplitude <-> décibels
%   detrend         - Retire la tendance d'un signal
%   discretize      - (MATLAB de base) classes d'un vecteur
%   uencode / udecode - Quantification uniforme
%   bitrevorder     - Ordre des bits inversés
%   parzen          - Fenêtre de Parzen, comme parzenwin
%   strips          - Trace un signal en bandes superposées
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
%
% Conception de filtres, suite
%   ellip       - Filtre elliptique, ou de Cauer
%   ellipord    - Ordre minimal d'un filtre elliptique
%   besself     - Filtre analogique de Bessel, retard de groupe plat
%   firpm       - RIF équiondulant, échange de Remez
%   yulewalk    - Filtre récursif ajusté sur un gabarit de module
%   invfreqz    - Filtre ajusté sur une réponse en fréquence complexe
%
% Fonctions internes supplémentaires (absentes de MATLAB)
%   prototypeElliptique - Pôles et zéros du prototype de Cauer
```

## `ac2poly`

```
AC2POLY Polynôme de prédiction d'une suite d'autocorrélation.
  [A,E] = AC2POLY(R) résout les équations de Yule-Walker par
  Levinson-Durbin. E est la puissance de l'erreur de prédiction.

  Exemple :
     [a, e] = ac2poly([1 0.5 0.25]);   % a = [1 -0.5 0]

  Voir aussi POLY2AC, AC2RC, LEVINSON, LPC.
```

## `ac2rc`

```
AC2RC Coefficients de réflexion d'une suite d'autocorrélation.
  [K,R0] = AC2RC(R) applique Levinson-Durbin : R(1) est la puissance du
  signal, K les coefficients de réflexion des ordres successifs.

  Exemple :
     r = [1 0.5 0.2];
     [k, r0] = ac2rc(r);
     all(abs(k) < 1)             % 1 : une autocorrelation valide donne |k| < 1

  Voir aussi RC2AC, AC2POLY, POLY2RC, LEVINSON.
```

## `alignsignals`

```
ALIGNSIGNALS Aligne deux signaux en compensant leur retard.
  [XA,YA,D] = ALIGNSIGNALS(X,Y) ajoute des zéros en tête du signal en
  avance, de sorte que les deux se superposent.

  Exemple :
     x = [0 0 1 2 3 0];
     [xa, ya, d] = alignsignals(x, [1 2 3 0 0 0]);
     d                           % le decalage retrouve

  Voir aussi FINDDELAY.
```

## `appliquerBande`

```
APPLIQUERBANDE Filtrage à phase nulle des fonctions lowpass et voisines.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [b, a] = butter(4, 0.3);
     rng(1);
     t = (0:255)' / 256;
     y = appliquerBande(sin(2*pi*5*t) + 0.5*sin(2*pi*90*t), b, a);
     rms(y - sin(2*pi*5*t)) < 0.3

  Voir aussi LOWPASS, CONCEVOIRBANDE.
```

## `arSpectre`

```
ARSPECTRE Densité spectrale d'un modèle autorégressif.
  Le modèle X = E/A(z) a pour densité e/(fs |A(f)|^2), doublée sur la
  moitié positive du spectre quand on ne garde qu'un côté.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [pxx, f] = arSpectre([1 -0.5], 1, 512, 1);
     pxx(1) > pxx(end)           % 1 : un pole reel positif est passe-bas

  Voir aussi PYULEAR, PBURG, PCOV.
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
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [a, e] = arburg(x, 4);
     all(abs(roots(a)) < 1) % 1 : Burg garantit un modele stable

  Voir aussi ARYULE, ARCOV, ARMCOV, PBURG.
```

## `arcov`

```
ARCOV Modèle autorégressif par la méthode de la covariance.
  Moindres carrés sur l'erreur de prédiction avant, sans fenêtrage : on
  n'utilise que les échantillons pour lesquels toute la fenêtre de
  prédiction existe.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [a, e] = arcov(x, 4);
     numel(a)                    % 5 : un modele d'ordre quatre

  Voir aussi ARMCOV, ARBURG, ARYULE, PCOV.
```

## `armcov`

```
ARMCOV Modèle autorégressif par la covariance modifiée.
  Moindres carrés sur les erreurs de prédiction avant et arrière à la
  fois : c'est la méthode qui résout le mieux deux sinusoïdes proches.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [a, e] = armcov(x, 4);
     all(abs(roots(a)) < 1.2)

  Voir aussi ARCOV, ARBURG, PMCOV.
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

  Voir aussi ARBURG, ARCOV, LEVINSON, PYULEAR.
```

## `bandpass`

```
BANDPASS Filtre passe-bande appliqué à un signal.
  Y = BANDPASS(X,[W1 W2]) ne laisse passer que ce qui se trouve entre
  W1 et W2, fréquences normalisées entre 0 et 1.
  Y = BANDPASS(X,[F1 F2],FS) donne les fréquences en hertz.

  Les options sont celles de LOWPASS.

  [Y,B,A] = BANDPASS(...) rend aussi les coefficients du filtre.

  Exemple :
     t = (0:999)' / 1000;
     x = sin(2*pi*10*t) + sin(2*pi*100*t) + sin(2*pi*400*t);
     y = bandpass(x, [50 200], 1000);

  Voir aussi BANDSTOP, LOWPASS, HIGHPASS, ELLIP, FILTFILT.
```

## `bandpower`

```
BANDPOWER Puissance moyenne d'un signal, éventuellement dans une bande.
  P = BANDPOWER(X) rend la puissance moyenne, soit la moyenne des
  carrés. P = BANDPOWER(X,FS,[F1 F2]) la restreint à une bande, par
  intégration du périodogramme.

  Exemple :
     bandpower([1 -1 1 -1])   % 1

  Voir aussi PERIODOGRAM, PWELCH, MEANFREQ.
```

## `bandstop`

```
BANDSTOP Filtre coupe-bande appliqué à un signal.
  Y = BANDSTOP(X,[W1 W2]) retire ce qui se trouve entre W1 et W2,
  fréquences normalisées entre 0 et 1.
  Y = BANDSTOP(X,[F1 F2],FS) donne les fréquences en hertz.

  Les options sont celles de LOWPASS.

  [Y,B,A] = BANDSTOP(...) rend aussi les coefficients du filtre.

  Exemple :
     t = (0:999)' / 1000;
     x = sin(2*pi*10*t) + sin(2*pi*100*t);
     y = bandstop(x, [50 200], 1000);

  Voir aussi BANDPASS, LOWPASS, HIGHPASS, ELLIP, FILTFILT.
```

## `barthannwin`

```
BARTHANNWIN Fenêtre de Bartlett-Hann.
  W = BARTHANNWIN(N) rend la fenêtre de N points, en colonne.

  Elle mêle une triangulaire de Bartlett et une cosinusoïde de Hann :
  0,62 - 0,48*|k-1/2| + 0,38*cos(2*pi*(k-1/2)) avec k de 0 à 1. La
  partie triangulaire abaisse le premier lobe secondaire, la partie
  cosinusoïdale accélère la décroissance des suivants. Le résultat tient
  le milieu entre les deux : premier lobe secondaire vers -35 dB, contre
  -31 dB pour Bartlett et -13 dB pour la fenêtre rectangulaire.

  Comme toute fenêtre non rectangulaire, elle échange de la résolution
  contre de la dynamique : le lobe principal s'élargit, donc deux raies
  proches se confondent plus tôt, mais une raie faible cesse d'être
  noyée dans les lobes d'une raie forte.

  Exemple :
     w = barthannwin(64);
     max(w)

  Voir aussi BARTLETT, HANN, BOHMANWIN, PARZENWIN.
```

## `besselap`

```
BESSELAP Prototype analogique de Bessel.
  [Z,P,K] = BESSELAP(N) rend les zéros, les pôles et le gain du
  passe-bas analogique de Bessel d'ordre N, normalisé pour un retard
  de groupe de 1 seconde en continu.

  Il n'a aucun zéro fini ; ses pôles sont les racines du polynôme de
  Bessel inverse, et le gain vaut 1 en continu.

  Exemple :
     [z, p, k] = besselap(3);

  Voir aussi BESSELF, BUTTAP, CHEB1AP.
```

## `besself`

```
BESSELF Filtre analogique de Bessel.
  [B,A] = BESSELF(N,WO) rend les coefficients du filtre passe-bas
  analogique d'ordre N dont le temps de propagation de groupe reste
  plat jusqu'à WO radians par seconde. Contrairement aux autres
  familles, BESSELF ne conçoit pas de filtre numérique : la
  transformation bilinéaire détruirait la platitude du retard.

  Le dénominateur est le polynôme de Bessel inverse

     theta_n(s) = somme des a_k s^k,  a_k = (2n-k)! / (2^(n-k) k! (n-k)!)

  dont le retard de groupe vaut exactement 1 en zéro.

  Exemple :
     [b, a] = besself(2, 1);   % a = [1 3 3], b = 3

  Voir aussi BUTTER, CHEBY1, ELLIP.
```

## `bilinear`

```
BILINEAR Transformation bilinéaire d'un filtre analogique.
  [ZD,PD,KD] = BILINEAR(Z,P,K,FS) transporte les zéros, les pôles et le
  gain d'un filtre analogique dans le plan des z par la substitution

     s = 2*FS*(z-1)/(z+1),

  qui envoie le demi-plan gauche dans le disque unité : un filtre
  analogique stable donne un filtre numérique stable.

  [BD,AD] = BILINEAR(B,A,FS) fait de même sur les coefficients de la
  fonction de transfert.

  [...] = BILINEAR(...,FP) prédistord la fréquence : la réponse
  numérique à FP hertz est alors exactement celle de l'analogique à FP,
  ce qui compense la compression de l'axe des fréquences.

  Exemple :
     [z, p, k] = buttap(4);
     [zd, pd, kd] = bilinear(z, p, k, 1, 0.2);

  Voir aussi IMPINVAR, BUTTER, BUTTAP, ZP2TF, FREQZ.
```

## `bitrevorder`

```
BITREVORDER Range un vecteur en ordre de bits inversés.
  Y = BITREVORDER(X) permute X de sorte que l'élément d'indice K se
  retrouve à l'indice obtenu en lisant les bits de K-1 à l'envers.
  C'est l'ordre dans lequel une transformée de Fourier rapide en
  entrelacement temporel lit ses données.

  [Y,I] = BITREVORDER(X) rend en outre la permutation, telle que
  Y = X(I).

  La longueur de X doit être une puissance de deux.

  Exemple :
     bitrevorder(0:7)     % [0 4 2 6 1 5 3 7]

  Voir aussi FFT, DIGITREVORDER, FFTSHIFT.
```

## `blackmanharris`

```
BLACKMANHARRIS Fenêtre de Blackman-Harris à quatre termes.
  Coefficients : 0,35875 ; 0,48829 ; 0,14128 ; 0,01168.

  Exemple :
     w = blackmanharris(64);
     max(w)                      % 1 : la fenetre est normalisee a son sommet

  Voir aussi NUTTALLWIN, FLATTOPWIN, WINDOW.
```

## `bohmanwin`

```
BOHMANWIN Fenêtre de Bohman.
  W = BOHMANWIN(N) rend la fenêtre de N points, en colonne.

  C'est la convolution de deux demi-cosinusoïdes, ce qui lui donne une
  propriété que les fenêtres polynomiales n'ont pas : la fenêtre et sa
  dérivée s'annulent aux deux bords. Le raccord avec le silence se fait
  sans rupture de pente, et les lobes secondaires décroissent d'autant
  plus vite — en 1/f^4, soit 24 dB par octave, contre 6 dB pour une
  fenêtre rectangulaire dont le raccord est brutal.

  Premier lobe secondaire à -46 dB environ, pour un lobe principal deux
  fois plus large que celui de Hann. Elle sert quand il faut voir une
  composante très faible loin d'une composante forte.

  Exemple :
     w = bohmanwin(64);
     [w(1) w(end)]

  Voir aussi PARZENWIN, BARTHANNWIN, BLACKMAN, HANN.
```

## `buffer`

```
BUFFER Découpe un signal en colonnes de longueur fixe.
  Y = BUFFER(X,N) range X en colonnes de N points, la dernière complétée
  par des zéros. BUFFER(X,N,P) fait se recouvrir les colonnes de P
  points (P négatif saute P points entre deux colonnes).

  Exemple :
     buffer(1:6, 3)   % [1 4; 2 5; 3 6]

  Voir aussi SPECTROGRAM, SEQPERIOD.
```

## `buttap`

```
BUTTAP Prototype analogique de Butterworth.
  [Z,P,K] = BUTTAP(N) rend les zéros, les pôles et le gain du filtre
  passe-bas analogique de Butterworth d'ordre N, normalisé : sa
  fréquence de coupure à −3 dB vaut 1 radian par seconde.

  Il n'a aucun zéro fini ; ses N pôles sont régulièrement répartis sur
  le demi-cercle unité gauche, et le gain vaut 1 en continu.

  Exemple :
     [z, p, k] = buttap(4);
     abs(prod(-p))       % 1 : le gain en continu

  Voir aussi BUTTER, CHEB1AP, CHEB2AP, ELLIPAP, BESSELAP, ZP2TF.
```

## `butter`

```
BUTTER Filtre numérique de Butterworth.
  [B,A] = BUTTER(N,WN) conçoit un passe-bas d'ordre N de fréquence de
  coupure normalisée WN (0 < WN < 1, 1 = Nyquist).
  [Z,P,K] = BUTTER(...) rend la forme zéros-pôles-gain, dont la
  conception est numériquement plus stable que celle des coefficients :
  au-delà de l'ordre huit environ, les coefficients d'un polynôme
  perdent leurs chiffres significatifs, pas les racines.
  [B,A] = BUTTER(N,WN,'high') conçoit un passe-haut.
  [B,A] = BUTTER(N,[W1 W2]) conçoit un passe-bande d'ordre 2N, et
  BUTTER(N,[W1 W2],'stop') un coupe-bande.

  Le filtre de Butterworth est le seul dont le module est monotone dans
  les deux bandes : il n'ondule nulle part, au prix d'une transition
  plus douce qu'un Chebyshev de même ordre.

  [B,A] = BUTTER(N,WN,'s') conçoit un filtre analogique : WN est alors
  en radians par seconde et n'est plus borné à un. 'high' et 'stop' se
  combinent avec 's' — BUTTER(N,WN,'high','s').

  Le prototype analogique est transposé par transformation bilinéaire
  avec pré-distorsion de la fréquence, comme le fait la fonction de
  référence. En analogique il n'y a rien à pré-distordre : seule la
  transformation de bande s'applique.

  Exemples :
     [b, a] = butter(4, 0.3);
     [b, a] = butter(2, [0.2 0.5]);      % passe-bande d'ordre 4
     [z, p, k] = butter(4, 0.3);         % zeros, poles et gain
     [b, a] = butter(4, 100, 's');       % analogique, 100 rad/s

  Voir aussi BUTTAP, BUTTORD, CHEBY1, CHEBY2, ELLIP, FILTFILT.
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

  Voir aussi BUTTER, CHEB1ORD, CHEB2ORD, ELLIPORD.
```

## `cceps`

```
CCEPS Cepstre complexe.
  [XHAT,ND] = CCEPS(X) rend le cepstre complexe et le nombre
  d'échantillons de retard retirés avant le déroulement de la phase.
  Le cepstre complexe garde la phase, à la différence de RCEPS.

  Exemple :
     xhat = cceps([1 0 0 0 0.5 0 0 0]);

  Voir aussi ICCEPS, RCEPS, HILBERT.
```

## `cconv`

```
CCONV Convolution circulaire.
  C = CCONV(A,B,N) rend la convolution circulaire de longueur N. Sans N,
  la longueur vaut numel(A)+numel(B)-1, et le résultat coïncide alors
  avec la convolution ordinaire.

  Exemple :
     cconv([1 2], [1 1], 2)   % [3 3]

  Voir aussi CONVOLUTIONCIRCULAIRE.
```

## `cheb1ap`

```
CHEB1AP Prototype analogique de Chebyshev de type I.
  [Z,P,K] = CHEB1AP(N,RP) rend les zéros, les pôles et le gain du
  passe-bas analogique d'ordre N qui ondule de RP décibels dans sa
  bande passante ; le bord de bande est en 1 radian par seconde.

  Il n'a aucun zéro fini : ses pôles sont sur une ellipse.

  Exemple :
     [z, p, k] = cheb1ap(4, 1);

  Voir aussi CHEBY1, BUTTAP, CHEB2AP, ELLIPAP.
```

## `cheb1ord`

```
CHEB1ORD Ordre minimal d'un filtre de Chebyshev de type I.
  [N,WN] = CHEB1ORD(WP,WS,RP,RS). WN vaut WP : la bande passante est
  fixée par l'ondulation.

  Exemple :
     [n, Wn] = cheb1ord(0.2, 0.3, 1, 40);
     n                           % l'ordre minimal qui tient le gabarit

  Voir aussi CHEBY1, BUTTORD, CHEB2ORD, ELLIPORD.
```

## `cheb2ap`

```
CHEB2AP Prototype analogique de Chebyshev de type II.
  [Z,P,K] = CHEB2AP(N,RS) rend les zéros, les pôles et le gain du
  passe-bas analogique d'ordre N dont la bande atténuée descend à RS
  décibels ; le bord de bande atténuée est en 1 radian par seconde.

  Contrairement au type I, il porte des zéros sur l'axe imaginaire :
  c'est ce qui creuse sa bande coupée.

  Exemple :
     [z, p, k] = cheb2ap(4, 40);

  Voir aussi CHEBY2, BUTTAP, CHEB1AP, ELLIPAP.
```

## `cheb2ord`

```
CHEB2ORD Ordre minimal d'un filtre de Chebyshev de type II.
  WN vaut WS : c'est la bande atténuée qui est fixée.

  Exemple :
     [n, Wn] = cheb2ord(0.2, 0.3, 1, 40);
     n

  Voir aussi CHEBY2, CHEB1ORD, BUTTORD, ELLIPORD.
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

  Voir aussi TAYLORWIN, KAISER, WINDOW.
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

  [B,A] = CHEBY1(...,'s') conçoit un filtre analogique : WN est alors
  en radians par seconde, et aucune pré-distorsion n'a lieu.

  Exemple :
     [b, a] = cheby1(2, 1, 0.3);

  Voir aussi BUTTER, CHEBY2, FIR1.
```

## `cheby2`

```
CHEBY2 Filtre de Chebyshev de type II, ondulation en bande atténuée.
  [B,A] = CHEBY2(N,RS,WN) conçoit un passe-bas d'ordre N de fréquence de
  coupure normalisée WN (0 < WN < 1, 1 = Nyquist). RS est l'atténuation
  minimale en décibels dans la bande coupée.
  [Z,P,K] = CHEBY2(...) rend la forme zéros-pôles-gain.
  [B,A] = CHEBY2(N,RS,WN,'high') conçoit un passe-haut, et
  CHEBY2(N,RS,[W1 W2]) un passe-bande d'ordre 2N, 'stop' un coupe-bande.
  [B,A] = CHEBY2(...,'s') conçoit un filtre analogique : WN est alors en
  radians par seconde, et aucune pré-distorsion n'a lieu.

  Le type II est l'inverse du type I : il ondule dans la bande coupée et
  reste monotone dans la bande passante. C'est ce qui le fait préférer
  quand la bande utile doit être plate — l'ondulation est reléguée là où
  le signal ne passe pas.

  Il l'obtient en plaçant des zéros sur l'axe imaginaire : la réponse
  s'annule exactement à ces fréquences, et remonte entre elles jusqu'à
  RS. Un ordre impair laisse un zéro à l'infini, si bien que le filtre
  tend vers zéro au lieu d'osciller indéfiniment.

  WN désigne ici le début de la bande coupée, non la coupure à -3 dB :
  c'est la fréquence où l'atténuation atteint RS. Un Chebyshev de type I
  et un de type II de mêmes ordre et WN n'ont donc pas la même bande
  passante.

  Exemples :
     [b, a] = cheby2(4, 40, 0.3);
     [b, a] = cheby2(6, 60, [0.2 0.5]);     % passe-bande d'ordre 12
     [b, a] = cheby2(4, 40, 100, 's');      % analogique, 100 rad/s

  Voir aussi CHEBY1, CHEB2AP, CHEB2ORD, BUTTER, ELLIP, FILTFILT.
```

## `chirp`

```
CHIRP Sinusoïde à fréquence instantanée variable.
  Y = CHIRP(T,F0,T1,F1) balaie linéairement de F0 (à t=0) à F1 (à t=T1).
  Y = CHIRP(T,F0,T1,F1,'quadratic') fait un balayage quadratique.

  Exemple :
     t = (0:1023)' / 1024;
     y = chirp(t, 0, 1, 100);
     numel(y)                    % 1024 : un point par instant

  Voir aussi GAUSPULS, SAWTOOTH, SQUARE, VCO.
```

## `concevoirBande`

```
CONCEVOIRBANDE Filtre d'ordre minimal pour lowpass et ses voisines.
  La bande de transition est déduite de la raideur : à raideur S, elle
  occupe la fraction 1-S de ce qui sépare le bord de bande du bord du
  spectre. C'est la même idée que dans MATLAB, où S vaut 0,85 par
  défaut.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [w, o] = lireOptionsBande(0.3);
     [b, a] = concevoirBande(w, 'low', o);
     abs(abs(polyval(b, 1) / polyval(a, 1)) - 1) < 0.2   % le continu passe

  Voir aussi LOWPASS, HIGHPASS, BANDPASS, APPLIQUERBANDE.
```

## `convmtx`

```
CONVMTX Matrice de convolution.
  A = CONVMTX(H,N) rend la matrice qui transforme une convolution en
  produit matriciel : pour un vecteur X de N éléments, CONVMTX(H,N)*X
  vaut CONV(H,X) — en colonne si H est une colonne, en ligne si H est
  une ligne, auquel cas c'est X*CONVMTX(H,N) qu'il faut écrire.

  Exemple :
     h = [1 2 3];
     % H en ligne : la matrice est n x (m+n-1), et l'on multiplie a gauche.
     isequal((1:4) * convmtx(h, 4), conv(1:4, h))       % vrai
     % H en colonne : la matrice est (m+n-1) x n, et l'on multiplie a droite.
     isequal(convmtx(h', 4) * (1:4)', conv(1:4, h)')    % vrai

  Voir aussi CONV, CORRMTX, TOEPLITZ, FILTER.
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

  Voir aussi PMUSIC, PEIG.
```

## `cpsd`

```
CPSD Densité interspectrale de puissance, par la méthode de Welch.
  [PXY,F] = CPSD(X,Y,...) : même découpage que PWELCH, mais le produit
  croisé X conjugué par Y.

  Exemple :
     rng(1);
     x = randn(1024, 1);
     [p, f] = cpsd(x, filter(1, [1 -0.8], x), [], [], 256, 1);
     numel(p) == numel(f)        % 1

  Voir aussi PWELCH, MSCOHERE, TFESTIMATE.
```

## `czt`

```
CZT Transformée en Z sur une spirale (algorithme de Bluestein).
  G = CZT(X,M,W,A) évalue la transformée en Z de X en M points pris sur
  la spirale A*W^(-k). Avec M = N, W = exp(-2i*pi/N) et A = 1, c'est la
  transformée de Fourier discrète.

  Exemple :
     n = 8; norm(czt(1:n) - fft((1:n)')) < 1e-10

  Voir aussi DFTMTX, GOERTZEL.
```

## `db2mag`

```
DB2MAG Décibels en amplitude.
  Y = DB2MAG(X) rend 10^(X/20).

  Exemple :
     db2mag(20)      % 10

  Voir aussi MAG2DB, DB2POW, POW2DB.
```

## `db2pow`

```
DB2POW Décibels en puissance.
  Y = DB2POW(X) rend 10^(X/10).

  Exemple :
     db2pow(20)      % 100

  Voir aussi POW2DB, MAG2DB, DB2MAG.
```

## `dct`

```
DCT Transformée en cosinus discrète de type II, normalisée.
  Y = DCT(X) applique la transformée utilisée par MATLAB :
     y(k) = w(k) * sum_{m=1}^{N} x(m) cos(pi (2m-1)(k-1) / (2N))
  avec w(1) = 1/sqrt(N) et w(k) = sqrt(2/N) sinon.

  L'orientation est conservée, comme le fait FFT : une ligne rend une
  ligne, une colonne rend une colonne. Sans cela, le résultat ne se
  recombinait pas avec le signal d'origine sans transposition.

  Exemple :
     x = [1 2 3 4 5]';
     max(abs(idct(dct(x)) - x)) < 1e-12     % 1 : la transformee est orthonormee
     isrow(dct([1 2 3 4]))                  % 1 : une ligne reste une ligne

  Voir aussi IDCT, DST, FFT.
```

## `decimate`

```
DECIMATE Réduit la fréquence d'échantillonnage d'un facteur entier.
  Y = DECIMATE(X,R) filtre X passe-bas puis garde un échantillon sur R.
  Le filtre est un RIF d'ordre 30 par défaut, appliqué en phase nulle
  pour ne pas décaler le signal ; DECIMATE(X,R,N) choisit l'ordre.

  Exemple :
     numel(decimate(1:100, 4))   % 25

  Voir aussi INTERP, RESAMPLE.
```

## `demod`

```
DEMOD Démodulation, réciproque de MODULATE.
  X = DEMOD(Y,FC,FS,METHODE). La démodulation d'amplitude multiplie par
  la porteuse puis filtre passe-bas ; celle de phase et de fréquence
  passe par la transformée de Hilbert.

  Exemple :
     t = (0:999)' / 1000;
     porteuse = cos(2 * pi * 100 * t) .* (1 + 0.5 * cos(2 * pi * 5 * t));
     x = demod(porteuse, 100, 1000, 'am');
     numel(x)                    % 1000

  Voir aussi MODULATE, HILBERT, ENVELOPE.
```

## `detrend`

```
DETREND Retire la tendance d'un signal.
  Y = DETREND(X) retire la droite des moindres carrés.
  Y = DETREND(X,'constant') ou DETREND(X,0) ne retire que la moyenne.
  Y = DETREND(X,'linear') ou DETREND(X,1) retire la droite.
  Y = DETREND(X,N) retire le polynôme de degré N.
  Y = DETREND(X,1,POINTS) ajuste une droite par morceaux, les ruptures
  étant aux indices POINTS : la tendance retirée est continue.

  Une matrice est traitée colonne par colonne.

  Exemple :
     t = (0:99)';
     y = detrend(3 + 0.5 * t + sin(t));   % il ne reste que le sinus

  Voir aussi POLYFIT, FILTER, MOVMEAN.
```

## `dftmtx`

```
DFTMTX Matrice de la transformée de Fourier discrète.
  M = DFTMTX(N) : M*X vaut FFT(X). La matrice coûte N^2 : elle sert à
  raisonner, pas à calculer.

  Exemple :
     F = dftmtx(4);
     max(abs(F * [1 0 0 0]' - ones(4, 1))) < 1e-12   % 1 : l'impulsion donne du plat

  Voir aussi CZT, FWHT.
```

## `diric`

```
DIRIC Fonction de Dirichlet, ou sinus cardinal périodique.
  Y = DIRIC(X,N) vaut sin(N X/2)/(N sin(X/2)), prolongée par
  (-1)^(k(N-1)) aux multiples de 2 pi.

  C'est la transformée de Fourier de la fenêtre rectangulaire de N
  points, normalisée.

  Exemple :
     diric(0, 5)   % 1

  Voir aussi SQUARE, CHIRP.
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

  Voir aussi PMTM, WINDOW, PERIODOGRAM.
```

## `dst`

```
DST Transformée en sinus discrète, première espèce.
  Y(k) = somme des X(n) sin(pi n k/(N+1)), k = 1..N.

  Exemple :
     dst([1 0 0])   % [sin(pi/4) sin(pi/2) sin(3pi/4)]

  Voir aussi IDST, DCT.
```

## `dutycycle`

```
DUTYCYCLE Rapport cyclique des impulsions.
  D = DUTYCYCLE(X,FS) rend, pour chaque période, la largeur de
  l'impulsion divisée par la période.

  Exemple :
     dutycycle([0 1 1 0 0 1 1 0 0 1], 1)   % environ 0.5

  Voir aussi PULSEWIDTH, PULSEPERIOD, PULSESEP.
```

## `ellip`

```
ELLIP Filtre elliptique, ou filtre de Cauer.
  [B,A] = ELLIP(N,RP,RS,WN) conçoit un passe-bas d'ordre N dont
  l'ondulation en bande passante vaut RP décibels et l'atténuation en
  bande coupée RS décibels ; WN est la fréquence de coupure
  normalisée, 1 valant la moitié de la fréquence d'échantillonnage.
  ELLIP(N,RP,RS,WN,'high') donne un passe-haut.

  À ordre égal, l'elliptique est le filtre dont la transition est la
  plus raide : il ondule dans les deux bandes, là où Chebyshev n'ondule
  que dans l'une et Butterworth dans aucune.

  [B,A] = ELLIP(...,'s') conçoit un filtre analogique : WN est alors
  en radians par seconde, et aucune pré-distorsion n'a lieu.

  Exemples :
     [b, a] = ellip(4, 1, 40, 0.3);

     [b, a] = ellip(4, 1, 40, 100, 's');    % analogique, 100 rad/s

  Voir aussi ELLIPORD, BUTTER, CHEBY1, CHEBY2, BESSELF.
```

## `ellipap`

```
ELLIPAP Prototype analogique elliptique, ou de Cauer.
  [Z,P,K] = ELLIPAP(N,RP,RS) rend les zéros, les pôles et le gain du
  passe-bas analogique d'ordre N qui ondule de RP décibels en bande
  passante et descend à RS décibels en bande atténuée ; le bord de
  bande passante est en 1 radian par seconde.

  À ordre égal, c'est la transition la plus raide qu'on puisse obtenir.

  Exemple :
     [z, p, k] = ellipap(4, 1, 40);

  Voir aussi ELLIP, BUTTAP, CHEB1AP, CHEB2AP.
```

## `ellipord`

```
ELLIPORD Ordre minimal d'un filtre elliptique.
  [N,WN] = ELLIPORD(WP,WS,RP,RS) rend le plus petit ordre qui laisse
  passer la bande WP avec au plus RP décibels d'ondulation et atténue
  la bande WS d'au moins RS décibels. Les fréquences sont normalisées,
  1 valant la moitié de la fréquence d'échantillonnage.

  ELLIPORD(...,'s') travaille en radians par seconde, sans
  pré-distorsion.

  L'ordre vient de l'équation du degré des fonctions elliptiques :

     N = ceil( K(k) K'(k1) / (K'(k) K(k1)) )

  avec k le rapport des fréquences et k1 celui des ondulations.

  Exemple :
     [n, Wn] = ellipord(0.2, 0.3, 1, 40)   % n = 5

  Voir aussi ELLIP, BUTTORD, CHEB1ORD.
```

## `enbw`

```
ENBW Largeur de bande de bruit équivalente d'une fenêtre.
  B = ENBW(W) rend N*sum(w.^2)/sum(w)^2, en bacs de la transformée.
  ENBW(W,FS) la donne en hertz.

  Exemple :
     enbw(rectwin(10))   % 1

  Voir aussi WINDOW, PERIODOGRAM, BANDPOWER.
```

## `envelope`

```
ENVELOPE Enveloppes supérieure et inférieure d'un signal.
  [H,B] = ENVELOPE(X) rend les deux enveloppes, calculées comme le
  module du signal analytique de part et d'autre de la valeur moyenne.

  L'enveloppe encadre le signal : H le majore, B le minore, partout sauf
  aux tout premiers et derniers échantillons, où l'effet de bord de la
  transformée de Hilbert la fait dévier. C'est une propriété du calcul
  en fréquence, non un défaut de mise en œuvre — la transformée suppose
  le signal périodique.

  Le retrait de la moyenne avant le calcul permet de traiter un signal
  qui porte une composante continue : sans lui, l'enveloppe d'un signal
  décalé serait fausse des deux côtés.

  L'orientation est conservée : une ligne rend deux lignes.

  Exemple :
     t = (0:999) / 1000;
     x = sin(2*pi*50*t) .* (1 + 0.5 * sin(2*pi*2*t));
     [h, b] = envelope(x);
     all(h(20:end-20) >= x(20:end-20))    % true : elle majore

  Voir aussi HILBERT, RMS, FINDPEAKS.
```

## `eqtflength`

```
EQTFLENGTH Met deux polynômes de transfert à la même longueur.
  [B,A] = EQTFLENGTH(NUM,DEN) complète le plus court par des zéros en
  queue, de sorte que B et A aient le même nombre de coefficients :
  c'est ce qu'attendent les fonctions qui travaillent sur B et A pris
  ensemble. Les zéros de queue en trop, communs aux deux, sont retirés.

  [B,A,NB,NA] = EQTFLENGTH(...) rend en outre les degrés effectifs.

  Exemple :
     [b, a] = eqtflength([1 2], [1 2 3 0]);
     % b = [1 2 0], a = [1 2 3]

  Voir aussi TF2ZP, FILTER, IMPZ.
```

## `falltime`

```
FALLTIME Temps de descente d'un signal à deux états.
  Symétrique de RISETIME : de 90 % à 10 % sur chaque front descendant.

  Exemple :
     t = (0:0.001:0.1)';
     [d, debut, fin] = falltime(double(t < 0.05), 1000);
     d > 0                       % 1 : la descente prend un temps fini

  Voir aussi RISETIME, SLEWRATE, SETTLINGTIME.
```

## `filtic`

```
FILTIC Conditions initiales d'un filtre, d'après son passé.
  Z = FILTIC(B,A,Y,X) rend le vecteur d'état que FILTER attend pour
  reprendre un filtrage déjà commencé : Y porte les sorties passées,
  Y(1) valant y(-1), Y(2) valant y(-2), et X les entrées passées de la
  même façon. Les vecteurs trop courts sont complétés par des zéros.

  Z = FILTIC(B,A,Y) suppose les entrées passées nulles.

  L'état est celui de la forme directe II transposée, celle qu'emploie
  FILTER :

     Z(m) = somme_{i>m} [ B(i) X(i-m) - A(i) Y(i-m) ].

  Exemple :
     [b, a] = butter(3, 0.4);
     x = randn(1, 100);
     [y, zf] = filter(b, a, x);
     z = filtic(b, a, y(end:-1:end-2), x(end:-1:end-2));
     % z reproduit zf

  Voir aussi FILTER, FILTFILT, IMPZ.
```

## `finddelay`

```
FINDDELAY Retard entre deux signaux, par corrélation croisée.
  D = FINDDELAY(X,Y) : Y est en retard de D échantillons sur X quand D
  est positif.

  Exemple :
     x = [1 2 3 0 0]; y = [0 0 1 2 3]; finddelay(x, y)   % 2

  Voir aussi ALIGNSIGNALS.
```

## `findpeaks`

```
FINDPEAKS Maxima locaux d'un signal.
  PICS = FINDPEAKS(X) rend les valeurs des maxima locaux.
  [PICS,POS] = FINDPEAKS(X) rend aussi leurs indices.
  Options par paires : 'MinPeakHeight', 'MinPeakDistance'.

  Exemple :
     [pics, positions] = findpeaks([0 1 0 3 0 2 0]);
     positions                   % 2 4 6

  Voir aussi SIGNALSOMMET.
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

  B = FIR1(...,FENETRE) emploie la fenêtre donnée au lieu de celle de
  Hamming, et B = FIR1(...,'noscale') laisse le gain tel que le
  fenêtrage le donne, sans le ramener à l'unité dans la bande passante.

  La fenêtre de Hamming est appliquée par défaut, comme dans la
  documentation MathWorks.

  Exemples :
     b = fir1(20, 0.3);
     b = fir1(20, [0.2 0.4], kaiser(21, 5), 'noscale');

  Voir aussi FIR2, FIRLS, FIRPM, KAISERORD, FREQZ, FILTER.
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

  Voir aussi FIR1, FIRLS, FIRPM.
```

## `firpm`

```
FIRPM Filtre RIF équiondulant, par l'échange de Remez.
  B = FIRPM(N,F,A) conçoit le filtre à phase linéaire d'ordre N — donc
  N+1 coefficients — dont l'écart maximal au gabarit est le plus petit
  possible. F donne les bords de bande par paires, normalisés entre 0
  et 1 où 1 est la moitié de la fréquence d'échantillonnage ; A donne
  l'amplitude visée à chacun de ces bords.

  B = FIRPM(N,F,A,W) pondère les bandes : une bande de poids double
  verra son ondulation deux fois plus faible que les autres.

  B = FIRPM(N,F,A,'hilbert') ou 'differentiator' conçoit un filtre
  antisymétrique.

  [B,ERR,RES] = FIRPM(...) rend aussi l'ondulation obtenue et une
  structure décrivant la convergence.

  Le principe est celui de Parks et McClellan : le meilleur
  approximant au sens de Tchebychev est celui dont l'erreur pondérée
  atteint son maximum, en alternant de signe, en au moins L+2 points.
  On part d'un jeu de fréquences, on résout exactement l'erreur
  d'alternance, on cherche les nouveaux extrema, et on recommence.

  Exemple :
     b = firpm(20, [0 0.3 0.5 1], [1 1 0 0]);

  Voir aussi FIR1, FIR2, FIRLS.
```

## `firtype`

```
FIRTYPE Type d'un filtre RIF à phase linéaire, de 1 à 4.
  Type 1 : symétrique, longueur impaire.  Type 2 : symétrique, paire.
  Type 3 : antisymétrique, impaire.       Type 4 : antisymétrique, paire.

  Exemple :
     firtype([1 2 3 2 1])        % 1 : symetrique, longueur impaire
     firtype([1 2 2 1])          % 2 : symetrique, longueur paire

  Voir aussi FIR1, ISLINPHASE, GRPDELAY.
```

## `flattopwin`

```
FLATTOPWIN Fenêtre à sommet plat, pour la mesure d'amplitude.
  Coefficients de MathWorks : 0,21557895 ; 0,41663158 ; 0,277263158 ;
  0,083578947 ; 0,006947368.

  Exemple :
     w = flattopwin(64);
     max(w)                      % 1 : elle sert a mesurer une amplitude

  Voir aussi BLACKMANHARRIS, NUTTALLWIN, WINDOW.
```

## `freqs`

```
FREQS Réponse en fréquence d'un filtre analogique.
  H = FREQS(B,A,W) évalue B(s)/A(s) en s = j*W. Sans W, deux cents
  points logarithmiques couvrant les pôles et les zéros.

  Exemple :
     abs(freqs(1, [1 1], 1))   % 1/sqrt(2), le passe-bas RC

  Voir aussi BODE, LP2LP.
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

  Voir aussi IFWHT, PAPILLONHADAMARD.
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

  Voir aussi CHIRP, TRIPULS, RECTPULS.
```

## `gausswin`

```
GAUSSWIN Fenêtre gaussienne.
  W = GAUSSWIN(N,ALPHA) où ALPHA est l'inverse de l'écart-type, en
  demi-largeurs. ALPHA vaut 2,5 par défaut.

  W(k) = exp(-0.5 * (ALPHA * (2k/(N-1) - 1))^2).

  Exemple :
     w = gausswin(64);
     abs(w(32) - max(w)) < 0.01  % le sommet est au milieu

  Voir aussi KAISER, CHEBWIN, WINDOW.
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

  Voir aussi CZT, DFTMTX.
```

## `grpdelay`

```
GRPDELAY Temps de propagation de groupe d'un filtre numérique.
  [GD,W] = GRPDELAY(B,A,N) rend le retard de groupe, en échantillons,
  sur N points entre 0 et pi.

  Le retard est -d(arg H)/dw ; il se calcule ici par la formule exacte
  Re{ (B'(w)/B(w)) - (A'(w)/A(w)) }, où les dérivées viennent de la
  pondération des coefficients par leur indice.

  Exemple :
     [b, a] = butter(4, 0.3);
     [gd, w] = grpdelay(b, a, 128);
     all(gd > 0)                 % 1 : un filtre causal retarde

  Voir aussi PHASEZ, PHASEDELAY.
```

## `highpass`

```
HIGHPASS Filtre passe-haut appliqué à un signal.
  Y = HIGHPASS(X,WPASS) filtre X par un passe-haut dont la bande
  passante commence à WPASS, fréquence normalisée entre 0 et 1.
  Y = HIGHPASS(X,FPASS,FS) donne la fréquence en hertz.

  Les options sont celles de LOWPASS : 'Steepness',
  'StopbandAttenuation' et 'ImpulseResponse'.

  [Y,B,A] = HIGHPASS(...) rend aussi les coefficients du filtre.

  Exemple :
     t = (0:999)' / 1000;
     x = sin(2*pi*10*t) + sin(2*pi*300*t);
     y = highpass(x, 100, 1000);

  Voir aussi LOWPASS, BANDPASS, BANDSTOP, ELLIP, FILTFILT.
```

## `hilbert`

```
HILBERT Signal analytique par transformée de Hilbert.
  Y = HILBERT(X) rend un signal complexe dont la partie réelle est X et
  la partie imaginaire sa transformée de Hilbert.
  Y = HILBERT(X,N) emploie N points : X est tronqué ou complété de zéros.

  Le calcul se fait en fréquence : annuler les fréquences négatives et
  doubler les positives. C'est la définition même du signal analytique,
  et cela explique ses effets de bord — la transformée de Fourier
  suppose le signal périodique, si bien que le début et la fin
  s'influencent.

  Le module du signal analytique est l'enveloppe du signal, et la
  dérivée de sa phase la fréquence instantanée. C'est à cela qu'il sert.

  L'orientation est conservée : une ligne rend une ligne, une colonne
  une colonne. Une matrice est traitée colonne par colonne, comme dans
  MATLAB.

  Exemple :
     x = sin(2 * pi * 50 * (0:999) / 1000);
     a = hilbert(x);
     max(abs(real(a) - x))           % 0 : la partie reelle est x
     abs(a(100:900))                 % 1 : l'enveloppe d'un sinus

  Voir aussi ENVELOPE, FFT, ANGLE, UNWRAP.
```

## `icceps`

```
ICCEPS Cepstre complexe inverse.
  X = ICCEPS(XHAT,ND) reconstitue le signal à partir de son cepstre
  complexe et du retard ND rendu par CCEPS.

  Exemple :
     x = [1 0.5 0.25 0.125]';
     max(abs(icceps(cceps(x), 0) - x)) < 1e-6

  Voir aussi CCEPS, RCEPS.
```

## `idct`

```
IDCT Transformée en cosinus discrète inverse.
  X = IDCT(Y) rend la transformée en cosinus discrète inverse de Y :
  IDCT(DCT(X)) restitue X. La transformée est orthonormée, donc
  l'inverse est la transposée, et l'énergie se conserve.

  X = IDCT(Y,N) tronque ou complète Y par des zéros à N points avant de
  transformer. Annuler les derniers coefficients est exactement ce que
  fait une compression : les coefficients de rang élevé portent les
  variations rapides, et les supprimer lisse le signal sans le déplacer.

  C'est cette concentration de l'énergie dans les premiers coefficients,
  pour un signal corrélé, qui explique l'emploi de la DCT en JPEG et en
  MP3 plutôt que celui de la transformée de Fourier.

  L'orientation est conservée, comme le fait IFFT : une ligne rend une
  ligne, une colonne rend une colonne.

  Exemple :
     x = [1 2 3 4 5]';
     max(abs(idct(dct(x)) - x)) < 1e-12
     isrow(idct([1 2 3 4]))          % 1 : une ligne reste une ligne

  Voir aussi DCT, FFT, IFFT.
```

## `idst`

```
IDST Transformée en sinus discrète inverse.
  La matrice de la DST-I est symétrique et son carré vaut (N+1)/2 fois
  l'identité : l'inverse n'est donc qu'un facteur d'échelle.

  Exemple :
     x = [1 2 3 4]';
     max(abs(idst(dst(x)) - x)) < 1e-12

  Voir aussi DST, IDCT.
```

## `ifwht`

```
IFWHT Transformée de Walsh-Hadamard inverse.
  La transformée directe porte le facteur 1/N ; l'inverse n'en a pas.

  Exemple :
     ifwht(fwht([1 2 3 4]))   % [1 2 3 4]

  Voir aussi FWHT, PAPILLONHADAMARD.
```

## `impinvar`

```
IMPINVAR Transformation par invariance impulsionnelle.
  [BZ,AZ] = IMPINVAR(B,A,FS) rend le filtre numérique dont la réponse
  impulsionnelle est celle du filtre analogique B(s)/A(s) échantillonnée
  à FS hertz : hz(n) = h(n/FS)/FS.

  Contrairement à la transformation bilinéaire, elle ne déforme pas
  l'axe des fréquences — mais elle replie tout ce que le filtre
  analogique laisse passer au-delà de FS/2. Elle demande donc un filtre
  analogique déjà bien atténué à la moitié de la fréquence
  d'échantillonnage, et refuse un filtre qui n'est pas strictement
  propre.

  FS vaut 1 par défaut.

  Exemple :
     [b, a] = butter(4, 2 * pi * 2, 's');     % analogique, coupure 2 Hz
     [bz, az] = impinvar(b, a, 10);           % echantillonne a 10 Hz
     % Les reponses impulsionnelles coincident aux instants d'echantillonnage.
     numel(az) - 1                            % 4 : l'ordre est conserve

  Voir aussi BILINEAR, RESIDUE, IMPZ.
```

## `impz`

```
IMPZ Réponse impulsionnelle d'un filtre numérique.
  [H,T] = IMPZ(B,A,N) rend les N premiers points de la réponse à une
  impulsion unité. Sans N, la longueur est choisie assez grande pour que
  la réponse soit retombée.

  Exemple :
     impz(1, [1 -0.5], 4)'   % [1 0.5 0.25 0.125]

  Voir aussi STEPZ.
```

## `interp`

```
INTERP Augmente la fréquence d'échantillonnage d'un facteur entier.
  Y = INTERP(X,R) insère R-1 zéros entre les échantillons puis filtre
  passe-bas ; le résultat a R fois plus de points, et le gain est
  compensé pour que l'amplitude soit conservée.

  Exemple :
     x = sin(2 * pi * 0.05 * (0:63)');
     y = interp(x, 4);
     numel(y)                    % 256 : quatre fois plus de points

  Voir aussi DECIMATE, RESAMPLE.
```

## `intfilt`

```
INTFILT Filtre d'interpolation.
  B = INTFILT(L,P,ALPHA) conçoit le filtre à phase linéaire qui
  interpole idéalement une séquence intercalée de L-1 zéros, en
  s'appuyant sur les 2*P échantillons non nuls les plus proches. ALPHA
  est la largeur de bande du signal d'origine, en fraction de la
  fréquence de Nyquist : ALPHA = 1 suppose le signal occupant toute la
  bande, une valeur plus petite laisse de la marge et donne un filtre
  plus doux.

  B = INTFILT(L,N,'Lagrange') interpole par un polynôme de degré N au
  lieu d'une bande limitée.

  Le filtre est long de 2*P*L-1 coefficients et laisse passer les
  échantillons d'origine sans les changer : B(L:L:end) est une
  impulsion.

  Exemple :
     b = intfilt(4, 3, 0.8);
     x = sin(2*pi*0.05*(0:99));
     y = filter(b, 1, upsample(x, 4));

  Voir aussi INTERP, RESAMPLE, UPFIRDN, DECIMATE, SINC.
```

## `invfreqs`

```
INVFREQS Filtre analogique ajusté sur une réponse en fréquence complexe.
  [B,A] = INVFREQS(H,W,NB,NA) cherche le numérateur d'ordre NB et le
  dénominateur d'ordre NA, en puissances décroissantes de s, dont la
  réponse aux pulsations W approche au mieux H au sens des moindres
  carrés.

  [B,A] = INVFREQS(H,W,NB,NA,WT) pondère chaque point.
  [B,A] = INVFREQS(H,W,NB,NA,WT,ITER,TOL) demande ITER itérations de
  Steiglitz et McBride, arrêtées quand les coefficients bougent de
  moins de TOL.

  C'est le pendant analogique d'INVFREQZ : le premier passage minimise
  l'erreur d'équation |B - H A|, linéaire en les coefficients ; les
  itérations suivantes divisent par |A| trouvé au tour précédent, ce
  qui converge vers l'erreur de sortie |B/A - H|.

  Exemple :
     [bt, at] = besself(3, 1);
     w = logspace(-1, 1, 100);
     h = freqs(bt, at, w);
     [b, a] = invfreqs(h, w, 0, 3);   % retrouve bt et at

  Voir aussi INVFREQZ, FREQS, PRONY, STMCB.
```

## `invfreqz`

```
INVFREQZ Filtre numérique ajusté sur une réponse en fréquence complexe.
  [B,A] = INVFREQZ(H,W,NB,NA) cherche le numérateur d'ordre NB et le
  dénominateur d'ordre NA dont la réponse aux pulsations W approche au
  mieux H, au sens des moindres carrés.

  [B,A] = INVFREQZ(H,W,NB,NA,WT) pondère chaque point.
  [B,A] = INVFREQZ(H,W,NB,NA,WT,ITER,TOL) demande ITER itérations de
  Steiglitz et McBride, arrêtées quand les coefficients bougent de
  moins de TOL.

  Le premier passage minimise l'erreur d'équation |B - H A|, qui est
  linéaire en les coefficients mais pondère mal les fréquences où A est
  petit. Les itérations suivantes divisent par |A| trouvé au tour
  précédent : on converge alors vers l'erreur de sortie |B/A - H|,
  celle qui compte.

  Exemple :
     [bt, at] = butter(4, 0.3);
     [h, w] = freqz(bt, at, 256);
     [b, a] = invfreqz(h, w, 4, 4);   % retrouve bt et at

  Voir aussi PRONY, INVFREQS.
```

## `islinphase`

```
ISLINPHASE Le filtre est-il à phase linéaire ?
  Un RIF est à phase linéaire si ses coefficients sont symétriques ou
  antisymétriques. Un RII ne l'est qu'avec un dénominateur trivial.

  Exemple :
     islinphase([1 2 3 2 1], 1)  % 1 : un RIF symetrique est a phase lineaire
     islinphase([1 2 3], 1)      % 0

  Voir aussi FIRTYPE, ISMINPHASE, ISMAXPHASE.
```

## `ismaxphase`

```
ISMAXPHASE Le filtre est-il à phase maximale ?
  Tous les zéros sont hors du cercle unité, les pôles dedans.

  Exemple :
     ismaxphase([1 -2], 1)       % 1 : le zero est hors du cercle unite

  Voir aussi ISMINPHASE, ISLINPHASE, ISSTABLE.
```

## `isminphase`

```
ISMINPHASE Le filtre est-il à phase minimale ?
  Tous les zéros et tous les pôles doivent être dans le cercle unité.

  Exemple :
     isminphase([1 -0.5], 1)     % 1 : le zero est dans le cercle unite

  Voir aussi ISMAXPHASE, ISLINPHASE, ISSTABLE.
```

## `isstable`

```
ISSTABLE Le filtre est-il stable ?
  Un filtre numérique est stable si tous ses pôles sont strictement à
  l'intérieur du cercle unité.

  ISSTABLE(SOS) accepte aussi une matrice de sections du second ordre.

  ISSTABLE(SYS) accepte un modèle linéaire : la stabilité s'y lit sur
  les pôles, strictement à gauche de l'axe imaginaire pour un modèle
  continu, strictement dans le cercle unité pour un modèle discret.

  Exemple :
     isstable(1, [1 -0.5])       % 1 : le pole est dans le cercle unite
     isstable(1, [1 -1.5])       % 0

  Voir aussi ISMINPHASE, ZPLANE.
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

  Voir aussi KAISER, FIR1.
```

## `latc2tf`

```
LATC2TF Treillis -> fonction de transfert.
  [B,A] = LATC2TF(K,V) rend le filtre que réalise le treillis-échelle
  de coefficients de réflexion K et d'échelle V.
  B = LATC2TF(K,'fir') rend le filtre à réponse finie du treillis K.
  [B,A] = LATC2TF(K,'allpole') rend le filtre tout-pôle 1/A(z).
  Sans second argument, le treillis est pris pour un tout-pôle.

  Exemple :
     [b, a] = butter(3, 0.4);
     [k, v] = tf2latc(b, a);
     max(abs(latc2tf(k, v) - b))     % nul aux arrondis près

  Voir aussi TF2LATC, LATCFILT, RC2POLY.
```

## `latcfilt`

```
LATCFILT Filtrage par une structure en treillis.
  [F,G] = LATCFILT(K,X) filtre X par le treillis à réponse finie de
  coefficients de réflexion K : F porte la sortie directe, G la sortie
  rétrograde.

  [F,G] = LATCFILT(K,V,X) emploie le treillis-échelle de coefficients
  K et V : F est alors la sortie du filtre récursif.

  Exemple :
     % Le treillis demande un polynome a phase minimale : les zeros de
     % BUTTER sont sur le cercle unite, ceux-ci sont a l'interieur.
     b = poly([0.5 -0.3 0.2]);
     k = tf2latc(b);
     rng(1);
     x = randn(1, 100);
     max(abs(latcfilt(k, x) - filter(b, 1, x))) < 1e-10   % 1

  Voir aussi TF2LATC, LATC2TF, FILTER.
```

## `lireOptionsBande`

```
LIREOPTIONSBANDE Arguments communs à lowpass, highpass, bandpass, bandstop.
  Rend les fréquences normalisées et une structure d'options :
  Steepness, StopbandAttenuation et ImpulseResponse.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [w, o] = lireOptionsBande(200, 1000, 'Steepness', 0.9);
     w                           % 0.4 : 200 Hz a 1 kHz

  Voir aussi LOWPASS, HIGHPASS, CONCEVOIRBANDE.
```

## `lireOptionsSousEspace`

```
LIREOPTIONSSOUSESPACE Analyse les arguments communs aux méthodes sous-espace.
  Reconnaît une fréquence d'échantillonnage et le mot-clé 'corr'.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [fs, corr] = lireOptionsSousEspace({1000, 'corr'});
     [fs corr]                   % 1000 et vrai

  Voir aussi PMUSIC, PEIG, ROOTMUSIC.
```

## `lowpass`

```
LOWPASS Filtre passe-bas appliqué à un signal.
  Y = LOWPASS(X,WPASS) filtre X par un passe-bas dont la bande passante
  va jusqu'à WPASS, fréquence normalisée entre 0 et 1, 1 valant la
  moitié de la fréquence d'échantillonnage.

  Y = LOWPASS(X,FPASS,FS) donne la fréquence en hertz, FS étant la
  fréquence d'échantillonnage.

  Y = LOWPASS(...,'Steepness',S) règle la raideur de la transition, S
  entre 0,5 et 1 (0,85 par défaut) : plus S est proche de 1, plus la
  transition est courte et l'ordre du filtre élevé.
  Y = LOWPASS(...,'StopbandAttenuation',A) impose A décibels
  d'atténuation en bande coupée (60 par défaut).
  Y = LOWPASS(...,'ImpulseResponse','fir') emploie un filtre à réponse
  impulsionnelle finie au lieu du filtre récursif.

  [Y,B,A] = LOWPASS(...) rend aussi les coefficients du filtre. MATLAB
  rend un objet digitalFilter ; MatLibre n'en a pas, et rend le couple
  qui le décrit.

  Le filtrage est à phase nulle — FILTFILT —, comme dans MATLAB : la
  forme des transitoires du signal est préservée.

  Exemple :
     t = (0:999)' / 1000;
     x = sin(2*pi*10*t) + sin(2*pi*300*t);
     y = lowpass(x, 100, 1000);

  Voir aussi HIGHPASS, BANDPASS, BANDSTOP, ELLIP, FILTFILT, DESIGNFILT.
```

## `lp2bp`

```
LP2BP Passe-bas analogique vers passe-bande.
  [NT,DT] = LP2BP(NUM,DEN,WO,BW) transforme le passe-bas analogique de
  coupure unité NUM(s)/DEN(s) en un passe-bande centré sur WO et de
  largeur BW, tous deux en radians par seconde. WO et BW valent un par
  défaut.

  La transformation est s -> (s^2 + WO^2)/(BW*s). Elle double l'ordre :
  chaque pôle du prototype en engendre deux, l'un au-dessus et l'autre
  au-dessous de la fréquence centrale. C'est pourquoi BUTTER(N,[W1 W2])
  rend un filtre d'ordre 2N.

  Le centre est la moyenne géométrique des deux bords, non leur moyenne
  arithmétique : la réponse est symétrique en échelle logarithmique.

  Exemple :
     [z, p, k] = buttap(2);
     [num, den] = zp2tf(z, p, k);
     [nt, dt] = lp2bp(num, den, 100, 20);
     numel(dt) - 1                                    % 4 : l'ordre double
     abs(abs(polyval(nt, 100i) / polyval(dt, 100i)) - 1) < 1e-10

  Voir aussi LP2LP, LP2HP, LP2BS, BUTTAP, BILINEAR.
```

## `lp2bs`

```
LP2BS Passe-bas analogique vers coupe-bande.
  [NT,DT] = LP2BS(NUM,DEN,WO,BW) transforme le passe-bas analogique de
  coupure unité NUM(s)/DEN(s) en un coupe-bande centré sur WO et de
  largeur BW, tous deux en radians par seconde. WO et BW valent un par
  défaut.

  La transformation est s -> BW*s/(s^2 + WO^2) : c'est l'inverse de
  celle du passe-bande, et elle double l'ordre de la même façon. Le
  continu et l'infini se retrouvent tous deux dans la bande passante, la
  fréquence centrale dans la bande rejetée.

  Elle place des zéros exactement en +/- j*WO : le rejet y est total,
  ce qui en fait le filtre du réjecteur de secteur.

  Exemple :
     [z, p, k] = buttap(2);
     [num, den] = zp2tf(z, p, k);
     [nt, dt] = lp2bs(num, den, 100, 20);
     abs(polyval(nt, 100i) / polyval(dt, 100i)) < 1e-10   % rejet total
     abs(abs(polyval(nt, 0) / polyval(dt, 0)) - 1) < 1e-12

  Voir aussi LP2LP, LP2HP, LP2BP, BUTTAP, BILINEAR.
```

## `lp2hp`

```
LP2HP Passe-bas analogique vers passe-haut.
  [NT,DT] = LP2HP(NUM,DEN,WO) transforme le passe-bas analogique de
  coupure unité NUM(s)/DEN(s) en un passe-haut de coupure WO en radians
  par seconde. WO vaut un par défaut.

  La transformation est s -> WO/s : elle retourne l'axe des fréquences,
  le continu allant à l'infini et réciproquement. Ce qui était la bande
  passante devient la bande atténuée, et le filtre obtenu a le même
  ordre que le prototype.

  Elle place autant de zéros à l'origine que le prototype avait de
  pôles : un passe-haut doit annuler le continu, et c'est cette
  transformation qui le lui donne.

  Exemple :
     [z, p, k] = buttap(4);
     [num, den] = zp2tf(z, p, k);
     [nt, dt] = lp2hp(num, den, 100);
     abs(polyval(nt, 0) / polyval(dt, 0)) < 1e-12     % rien ne passe au continu

  Voir aussi LP2LP, LP2BP, LP2BS, BUTTAP, BILINEAR.
```

## `lp2lp`

```
LP2LP Change la fréquence de coupure d'un passe-bas analogique.
  [NT,DT] = LP2LP(NUM,DEN,WO) transforme le passe-bas analogique
  NUM(s)/DEN(s), de coupure unité, en un passe-bas de coupure WO en
  radians par seconde. WO vaut un par défaut.

  La transformation est s -> s/WO : elle dilate l'axe des fréquences
  sans rien changer à la forme de la réponse. Le gain au continu est
  donc conservé, et l'ordre aussi.

  C'est la première des quatre transformations de bande. Toutes partent
  du même prototype de coupure unité — celui que rendent BUTTAP,
  CHEB1AP, CHEB2AP et ELLIPAP — ce qui évite d'avoir à concevoir un
  filtre différent pour chaque bande.

  Exemple :
     [z, p, k] = buttap(4);
     [num, den] = zp2tf(z, p, k);
     [nt, dt] = lp2lp(num, den, 100);
     abs(polyval(nt, 0) / polyval(dt, 0) - 1) < 1e-12    % gain au continu

  Voir aussi LP2HP, LP2BP, LP2BS, BUTTAP, BILINEAR, IMPINVAR.
```

## `lsf2poly`

```
LSF2POLY Polynôme de prédiction à partir des fréquences de raies.
  Inverse de POLY2LSF : les racines de rangs pairs reconstituent Q,
  celles de rangs impairs P, et A = (P + Q)/2.

  Exemple :
     a = poly([0.5 -0.3]);
     max(abs(lsf2poly(poly2lsf(a)) - a)) < 1e-10

  Voir aussi POLY2LSF, LPC, AC2POLY.
```

## `mag2db`

```
MAG2DB Amplitude en décibels.
  Y = MAG2DB(X) rend 20*log10(X) : c'est la conversion d'une amplitude,
  non d'une puissance.

  Exemple :
     mag2db(10)      % 20

  Voir aussi DB2MAG, POW2DB, DB2POW.
```

## `matlibre_genre_filtre`

```
MATLIBRE_GENRE_FILTRE Démêle le type de bande et le mot-clé « s ».
  [GENRE,ANALOGIQUE] = MATLIBRE_GENRE_FILTRE(ARGS) lit, dans les
  arguments de queue de BUTTER, CHEBY1, CHEBY2 et ELLIP, le type de
  bande — 'low', 'high', 'bandpass', 'stop' — et le mot-clé 's' qui
  demande un filtre analogique. L'ordre des deux est indifférent, comme
  dans MATLAB.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_lp_substituer`

```
MATLIBRE_LP_SUBSTITUER Remplace s par P(s)/Q(s) dans une fonction de transfert.
  [N,D] = MATLIBRE_LP_SUBSTITUER(NUM,DEN,P,Q) rend la fonction de
  transfert obtenue en substituant la fraction rationnelle P/Q à la
  variable s dans NUM(s)/DEN(s).

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Le calcul suit la définition. Un polynôme A de degré n s'écrit
  somme a_i s^(n-i) ; y substituer P/Q donne

     A(P/Q) = (1/Q^n) * somme a_i P^(n-i) Q^i

  Numérateur et dénominateur sont d'abord complétés à la même longueur,
  si bien que le facteur 1/Q^n est le même pour les deux et disparaît du
  quotient. C'est ce qui rend la substitution exacte : aucune division
  de polynômes, seulement des produits.
```

## `matlibre_prototype_analogique`

```
MATLIBRE_PROTOTYPE_ANALOGIQUE Prototype passe-bas vers filtre analogique.
  [B,A,Z,P,K] = MATLIBRE_PROTOTYPE_ANALOGIQUE(POLES,ZEROS,GAIN,WN,GENRE)
  applique au prototype de coupure unité la transformation de bande
  voulue, et rend le filtre analogique correspondant. WN est en radians
  par seconde ; deux valeurs décrivent une bande. GAINREFERENCE est le
  module attendu à la fréquence de référence — le continu pour un
  passe-bas, l'infini pour un passe-haut, le centre pour un
  passe-bande ; il vaut 1 par défaut, mais un Chebyshev de type I ou un
  elliptique d'ordre pair descend à 10^(-RP/20).

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  C'est le pendant analogique de PROTOTYPEVERSNUMERIQUE : même
  prototype, mêmes transformations de bande, mais sans transformation
  bilinéaire ni pré-distorsion — l'axe des fréquences n'étant pas
  replié, il n'y a rien à corriger.
```

## `maxflat`

```
MAXFLAT Filtre passe-bas à réponse la plus plate possible.
  [B,A] = MAXFLAT(N,M,WN) rend un filtre de Butterworth généralisé de
  degré N au numérateur et M au dénominateur, de fréquence de coupure
  WN normalisée entre 0 et 1, 1 valant Nyquist. Le gain y vaut
  1/racine de deux.

  B = MAXFLAT(N,'sym',WN) rend un filtre à réponse impulsionnelle finie
  et symétrique, d'ordre N pair. WN n'est alors atteignable que dans un
  sous-intervalle de [0,1] : les degrés de platitude sont entiers, donc
  les coupures possibles sont en nombre fini.

  [B,A,B1,B2] = MAXFLAT(...) sépare le numérateur en ses deux facteurs :
  B1 porte les N zéros en z = -1, B2 le reste.

  MAXFLAT(...,'design') affiche ce que le filtre obtenu vérifie.

  « Le plus plat possible » a un sens précis. En posant
  x = sin(w/2)^2, le module au carré s'écrit

     |H|^2 = (1-x)^N / D(x),   D de degré M, D(0) = 1

  La forme (1-x)^N impose N zéros en x = 1, c'est-à-dire à Nyquist :
  la bande coupée est aussi plate que le degré le permet. Restent M
  coefficients libres dans D. On en dépense M-1 à annuler les M-1
  premières dérivées de |H|^2 en x = 0, ce qui donne

     D(x) = somme_{k<M} C(N,k) (-1)^k x^k + beta x^M

  et le dernier, beta, à placer la coupure là où on la veut. C'est tout
  le filtre : rien n'est optimisé, tout est imposé.

  Pour N = M on retrouve exactement le filtre de Butterworth ordinaire,
  dont BUTTER donne les mêmes coefficients.

  Exemple :
     [b, a] = maxflat(10, 2, 0.2);
     [b, a] = maxflat(4, 4, 0.3);        % identique à butter(4, 0.3)
     b = maxflat(8, 'sym', 0.5);

  Voir aussi BUTTER, FIRLS, FIRPM, FREQZ.
```

## `meanfreq`

```
MEANFREQ Fréquence moyenne, pondérée par la puissance spectrale.
  F = MEANFREQ(X,FS) rend le barycentre du spectre.

  Exemple :
     t = (0:1023)' / 1000;
     abs(meanfreq(sin(2*pi*50*t), 1000) - 50) < 10

  Voir aussi MEDFREQ, BANDPOWER.
```

## `medfilt1`

```
MEDFILT1 Filtre médian glissant d'ordre N.
  Y = MEDFILT1(X,N) remplace chaque échantillon par la médiane de la
  fenêtre de N points centrée dessus. N vaut 3 par défaut.

  Y = MEDFILT1(X,N,[],DIM) filtre suivant la dimension DIM.
  Y = MEDFILT1(...,'zeropad') complète la fenêtre par des zéros aux
  bords, ce qui est le comportement par défaut ; Y =
  MEDFILT1(...,'truncate') la raccourcit au lieu de la compléter.

  Les deux traitements des bords donnent des résultats différents, et
  il faut choisir : compléter par des zéros tire le signal vers zéro
  aux extrémités, raccourcir prend la médiane d'un échantillon plus
  petit, donc plus bruité. MATLAB complète par défaut, et c'est aussi
  ce qui rend le filtre invariant par décalage.

  La médiane, contrairement à la moyenne, n'est pas déplacée par une
  valeur aberrante : c'est tout l'intérêt de ce filtre, et ce qui le
  distingue d'un lissage.

  Exemple :
     medfilt1([1 100 2 3], 3)    % la valeur aberrante disparait
     medfilt1([1 100 1], 3)      % [1 1 1] : les bords sont completes

  Voir aussi SGOLAYFILT, MEDFILT2, MOVMEDIAN.
```

## `medfreq`

```
MEDFREQ Fréquence médiane : celle qui coupe la puissance en deux.
  F = MEDFREQ(X) rend la fréquence qui partage en deux parts égales la
  puissance du signal, avec une fréquence d'échantillonnage de 1.
  F = MEDFREQ(X,FS) donne FS en hertz et rend F en hertz.

  La densité spectrale est estimée par périodogramme, puis intégrée ;
  la fréquence médiane est celle où l'intégrale atteint la moitié de sa
  valeur finale, obtenue par interpolation linéaire entre les deux
  points qui l'encadrent.

  Comme toute médiane, elle résiste à ce qui se passe dans les queues :
  une raie parasite loin de la bande utile la déplace à peine, là où la
  fréquence moyenne MEANFREQ, qui pondère par la fréquence, s'en trouve
  tirée. C'est pourquoi le suivi de fatigue musculaire en
  électromyographie, où le spectre glisse vers le bas, se fait sur elle.

  Exemple :
     t = (0:1023)' / 1000;
     f = medfreq(sin(2*pi*50*t), 1000);

  Voir aussi MEANFREQ, BANDPOWER, PERIODOGRAM, OBW.
```

## `midcross`

```
MIDCROSS Instants de traversée du niveau médian.
  [C,NIVEAU] = MIDCROSS(X,FS) rend les instants où le signal coupe le
  niveau à mi-chemin entre ses deux états, et ce niveau.

  Exemple :
     midcross([0 0 1 1], 1)   % 1.5 : la moitié est franchie là

  Voir aussi STATELEVELS, RISETIME, FALLTIME.
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

  Voir aussi DEMOD, VCO, HILBERT.
```

## `mscohere`

```
MSCOHERE Cohérence quadratique moyenne entre deux signaux.
  C = MSCOHERE(X,Y,...) vaut |Pxy|^2 / (Pxx*Pyy) : entre 0 et 1, elle
  dit quelle part de Y s'explique linéairement par X, fréquence par
  fréquence.

  Exemple :
     rng(1);
     x = randn(1024, 1);
     [c, f] = mscohere(x, filter(1, [1 -0.8], x), [], [], 256, 1);
     all(c >= -1e-12 & c <= 1 + 1e-12)     % 1 : c'est une coherence

  Voir aussi CPSD, TFESTIMATE, PWELCH.
```

## `nuttallwin`

```
NUTTALLWIN Fenêtre de Blackman-Nuttall à quatre termes.
  Coefficients : 0,3635819 ; 0,4891775 ; 0,1365995 ; 0,0106411.

  Exemple :
     w = nuttallwin(64);
     max(w)                      % 1

  Voir aussi BLACKMANHARRIS, FLATTOPWIN, WINDOW.
```

## `overshoot`

```
OVERSHOOT Dépassement après chaque transition, en pourcentage.
  Le dépassement est mesuré entre le niveau d'état atteint et
  l'extremum observé après la transition, rapporté à l'écart entre les
  deux états. Il vaut zéro si le signal ne dépasse pas.

  Exemple :
     overshoot([0 0 1.2 1 1 1], 1)   % 20 %

  Voir aussi UNDERSHOOT, SETTLINGTIME, RISETIME.
```

## `papillonHadamard`

```
PAPILLONHADAMARD Transformée de Hadamard rapide, ordre naturel.
  Chaque étage remplace un couple (a,b) par (a+b, a-b) : c'est la
  construction de Sylvester appliquée en place, en N log2 N additions.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     x = (1:8)';
     y = papillonHadamard(x);
     abs(y(1) - sum(x)) < 1e-12  % le premier coefficient est la somme
     max(abs(papillonHadamard(y) / 8 - x)) < 1e-12   % involutive au facteur N

  Voir aussi FWHT, IFWHT, RANGERWALSH.
```

## `parzen`

```
PARZEN Fenêtre de Parzen.
  W = PARZEN(N) rend la fenêtre de Parzen de N points, aussi appelée
  fenêtre de de La Vallée Poussin : c'est la convolution de deux
  fenêtres triangulaires, donc un B-spline cubique. Son spectre décroît
  en 1/f^4, plus vite que celui de toute autre fenêtre polynomiale de
  même largeur, au prix d'un lobe principal plus large.

  C'est la même fenêtre que rend PARZENWIN.

  Exemple :
     w = parzen(64);
     sum(w) / 64          % environ 0,375

  Voir aussi PARZENWIN, BARTHANNWIN, TRIANG, WINDOW.
```

## `parzenwin`

```
PARZENWIN Fenêtre de Parzen, ou de de la Vallée Poussin.
  W = PARZENWIN(N) rend la fenêtre de N points, en colonne.

  C'est la B-spline cubique : la convolution de quatre fenêtres
  rectangulaires, d'où deux morceaux de polynômes de degré trois
  raccordés à mi-pente. Chaque convolution multiplie le spectre par un
  sinus cardinal, donc quatre convolutions font décroître les lobes
  secondaires en 1/f^4, et la fenêtre est partout positive — son spectre
  ne change jamais de signe, ce qu'aucune fenêtre de la famille cosinus
  ne garantit.

  Une densité spectrale estimée avec elle est donc toujours positive.
  Le prix est le lobe principal, le plus large des fenêtres usuelles ;
  ses lobes secondaires descendent en contrepartie à -53 dB.

  Exemple :
     w = parzenwin(64);
     all(w >= 0)

  Voir aussi BOHMANWIN, BARTLETT, BLACKMAN, HANN.
```

## `pburg`

```
PBURG Densité spectrale par la méthode de Burg.
  Même principe que PYULEAR, avec un modèle estimé par ARBURG : plus
  sûr sur les séries courtes.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [pxx, f] = pburg(x, 4, 128, 1);
     numel(pxx) == numel(f)      % 1

  Voir aussi PYULEAR, PCOV, PMCOV, ARBURG.
```

## `pcov`

```
PCOV Densité spectrale par la méthode de la covariance.
  PXX = PCOV(X,P) estime la densité spectrale de X par un modèle
  autorégressif d'ordre P ajusté par la méthode de la covariance, puis
  évalue le spectre de ce modèle.
  [PXX,F] = PCOV(X,P,NFFT,FS) donne le nombre de points de la grille
  (256 par défaut) et la fréquence d'échantillonnage, et rend l'axe des
  fréquences.

  La méthode de la covariance minimise l'erreur de prédiction avant sur
  les seuls échantillons où elle est calculable, sans supposer le signal
  nul en dehors de la fenêtre observée. Elle ne fenêtre donc pas les
  données — c'est ce qui la sépare de la méthode de Yule-Walker, dont
  l'hypothèse implicite d'extension par des zéros élargit les raies sur
  un enregistrement court.

  La contrepartie est qu'elle ne garantit pas un modèle stable : un pôle
  peut sortir du cercle unité. Le spectre reste lisible, mais le modèle
  ne s'utilise pas tel quel pour synthétiser.

  Exemple :
     x = filter(1, [1 -0.9], randn(256, 1));
     [pxx, f] = pcov(x, 4, 128, 1);

  Voir aussi PMCOV, PYULEAR, PBURG, ARCOV.
```

## `peak2peak`

```
PEAK2PEAK Écart entre le maximum et le minimum.
  Exemple :
     peak2peak([1 5 2])   % 4

  Voir aussi PEAK2RMS, RMS, RSSQ.
```

## `peak2rms`

```
PEAK2RMS Rapport entre la valeur crête et la valeur efficace.
  Exemple :
     peak2rms([1 -1 1 -1])   % 1

  Voir aussi PEAK2PEAK, RMS, RSSQ.
```

## `peig`

```
PEIG Pseudospectre par la méthode des vecteurs propres.
  Comme PMUSIC, avec chaque vecteur du sous-espace bruit pondéré par
  l'inverse de sa valeur propre.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [S, f] = peig(x, 2, 256, 1);
     [~, k] = max(S);
     abs(f(k) - 0.1) < 0.02      % la raie est retrouvee

  Voir aussi PMUSIC, ROOTEIG, ROOTMUSIC.
```

## `periodogram`

```
PERIODOGRAM Densité spectrale de puissance par périodogramme.
  [PXX,F] = PERIODOGRAM(X) estime la densité spectrale de X.
  [PXX,F] = PERIODOGRAM(X,FENETRE,NFFT,FS) précise la fenêtre, la taille
  de la transformée et la fréquence d'échantillonnage.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [pxx, f] = periodogram(x, [], 512, 1);
     [~, k] = max(pxx);
     abs(f(k) - 0.1) < 0.02

  Voir aussi PWELCH, PMTM, BANDPOWER.
```

## `permutationWalsh`

```
PERMUTATIONWALSH Rangement des fonctions de Walsh.
  Rend le vecteur d'indices qui fait passer de l'ordre naturel de
  Sylvester à l'ordre demandé : 'hadamard' (identité), 'dyadic'
  (renversement des bits, ordre de Paley) ou 'sequency' (renversement
  puis code de Gray, rangement par nombre de changements de signe).

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     p = permutationWalsh(8, 'sequency');
     isequal(sort(p(:)'), 1:8)   % 1 : c'est une permutation

  Voir aussi FWHT, RANGERWALSH, RANGERWALSHINVERSE.
```

## `phasedelay`

```
PHASEDELAY Retard de phase d'un filtre numérique.
  Le retard de phase vaut -phi(w)/w. Pour un filtre à phase linéaire
  d'ordre N il vaut N/2 échantillons, constant.

  Exemple :
     [b, a] = butter(4, 0.3);
     [pd, w] = phasedelay(b, a, 128);
     numel(pd) == numel(w)       % 1

  Voir aussi PHASEZ, GRPDELAY.
```

## `phasez`

```
PHASEZ Réponse en phase déroulée d'un filtre numérique.
  [PHI,W] = PHASEZ(B,A,N) rend la phase continue sur N points entre 0
  et pi, comme FREQZ pour le module.

  Exemple :
     [b, a] = butter(4, 0.3);
     [phi, w] = phasez(b, a, 128);
     abs(phi(1)) < 1e-12         % la phase est nulle au continu

  Voir aussi PHASEDELAY, GRPDELAY, ZEROPHASE.
```

## `pmcov`

```
PMCOV Densité spectrale par la méthode de la covariance modifiée.
  PXX = PMCOV(X,P) estime la densité spectrale de X par un modèle
  autorégressif d'ordre P ajusté par la méthode de la covariance
  modifiée, puis évalue le spectre de ce modèle.
  [PXX,F] = PMCOV(X,P,NFFT,FS) donne le nombre de points de la grille
  (256 par défaut) et la fréquence d'échantillonnage.

  « Modifiée » veut dire que l'ajustement minimise à la fois l'erreur de
  prédiction avant et l'erreur arrière. Un signal stationnaire ayant les
  mêmes statistiques lu à l'endroit et à l'envers, exiger les deux double
  les équations sans ajouter d'inconnue : l'estimation est plus stable
  sur un enregistrement court, et la résolution en fréquence meilleure.

  C'est la méthode qui sépare le mieux deux sinusoïdes proches noyées
  dans du bruit, quand on connaît l'ordre du modèle. Elle reste sensible
  au choix de P : trop bas, les raies fusionnent ; trop haut, le bruit
  engendre de fausses raies.

  Exemple :
     x = filter(1, [1 -0.9], randn(256, 1));
     [pxx, f] = pmcov(x, 4, 128, 1);

  Voir aussi PCOV, PBURG, PYULEAR, ARMCOV.
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
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [pxx, f] = pmtm(x, 4, 512, 1000);
     [~, k] = max(pxx);
     abs(f(k) - 100) < 5      % 1 : la raie est a 0,1 fois 1000 Hz

  Voir aussi PERIODOGRAM, PWELCH, DPSS.
```

## `pmusic`

```
PMUSIC Pseudospectre par la méthode MUSIC.
  [S,F] = PMUSIC(X,P,NFFT,FS) rend l'inverse de la projection du
  vecteur directeur sur le sous-espace bruit : le pseudospectre monte
  très haut aux fréquences présentes, mais ses valeurs ne sont pas des
  puissances.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [S, f] = pmusic(x, 4, 1024, 1000);
     [~, k] = max(S);
     abs(f(k) - 100) < 5      % 1 : le sous-espace signal trouve la raie

  Voir aussi PEIG, ROOTMUSIC, PBURG.
```

## `poly2ac`

```
POLY2AC Autocorrélation d'un polynôme de prédiction.
  R = POLY2AC(A,EFINAL) rend la suite d'autocorrélation dont A est le
  filtre de prédiction et EFINAL l'erreur résiduelle.

  Exemple :
     a = [1 -0.5 0.2];
     r = poly2ac(a, 1);
     max(abs(ac2poly(r) - a)) < 1e-10       % l'aller-retour

  Voir aussi AC2POLY, POLY2RC, LEVINSON.
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

  Voir aussi LSF2POLY, POLY2RC, LPC.
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

  Voir aussi RC2POLY, POLY2AC, AC2RC, SCHURRC.
```

## `polyscale`

```
POLYSCALE Déplace les racines d'un polynôme vers l'origine.
  B = POLYSCALE(A,ALPHA) rend le polynôme dont les racines sont celles
  de A multipliées par ALPHA. C'est le changement de variable z -> z/ALPHA :
  B(k) = A(k) * ALPHA^(n-k+1).

  Avec 0 < ALPHA < 1, les racines rentrent vers l'origine — c'est ainsi
  qu'on stabilise un filtre dont un pôle a débordé du cercle unité, ou
  qu'on élargit les formants d'un modèle de parole.

  Exemple :
     a = poly([0.9, -0.95]);
     max(abs(roots(polyscale(a, 0.5))))     % 0.475

  Voir aussi POLYSTAB, ROOTS, POLY, LPC.
```

## `polystab`

```
POLYSTAB Stabilise un polynôme en repliant ses racines dans le disque.
  B = POLYSTAB(A) remplace chaque racine de module supérieur à 1 par son
  inverse conjugué : le module de la réponse est conservé, mais le
  polynôme devient à phase minimale.

  Exemple :
     b = polystab([1 -1.5]);
     all(abs(roots(b)) <= 1 + 1e-12)        % 1 : les racines rentrent

  Voir aussi ISMINPHASE.
```

## `pow2db`

```
POW2DB Puissance en décibels.
  Y = POW2DB(X) rend 10*log10(X). Une puissance nulle donne −Inf, une
  puissance négative n'a pas de sens et donne NaN.

  Exemple :
     pow2db(100)     % 20

  Voir aussi DB2POW, MAG2DB, DB2MAG, BANDPOWER.
```

## `prony`

```
PRONY Modèle rationnel d'une réponse impulsionnelle.
  [B,A] = PRONY(H,NB,NA) rend le filtre d'ordre NB au numérateur et NA
  au dénominateur dont la réponse impulsionnelle commence par H : les
  NB+1 premiers échantillons sont reproduits exactement, et les
  suivants au sens des moindres carrés.

  La méthode de Prony sépare le problème en deux : les équations qui ne
  font intervenir que le dénominateur se résolvent d'abord, le
  numérateur s'en déduit par convolution.

  Exemple :
     [b, a] = butter(3, 0.4);
     h = impz(b, a, 30);
     [bb, aa] = prony(h, 3, 3);      % retrouve b et a

  Voir aussi STMCB, LEVINSON, LPC, IMPZ.
```

## `prototypeElliptique`

```
PROTOTYPEELLIPTIQUE Pôles et zéros du prototype passe-bas de Cauer.
  Le bord de bande passante est en oméga = 1, le bord de bande
  atténuée en 1/k où k est la sélectivité tirée de l'équation du degré

     N K'(k)/K(k) = K'(k1)/K(k1),    k1 = eps_p / eps_s.

  Les zéros et les pôles s'écrivent alors avec les fonctions
  elliptiques de Jacobi :

     zeta_i = cd(u_i K, k),   z_i = j/(k zeta_i)
     p_i    = j cd((u_i - j v0) K, k),   u_i = (2i-1)/N

  et, pour un ordre impair, un pôle réel supplémentaire.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  Référence : les formules classiques de la conception elliptique,
  telles qu'on les trouve dans la littérature ouverte sur les filtres
  de Cauer.

  Exemple :
     [z, p, k] = prototypeElliptique(4, 1, 40);
     all(real(p) < 0)            % 1 : un prototype stable a ses poles a gauche

  Voir aussi ELLIP, ELLIPAP, ELLIPKE.
```

## `prototypeVersNumerique`

```
PROTOTYPEVERSNUMERIQUE Prototype analogique -> filtre numérique.
  Applique la transformation de bande — passe-bas, passe-haut,
  passe-bande ou coupe-bande — puis la transformation bilinéaire, avec
  prédistorsion de la fréquence : omega = 2*tan(pi*Wn/2), comme le veut
  la conception de MATLAB.

  WN scalaire donne un passe-bas ou un passe-haut ; WN à deux éléments
  donne un passe-bande, ou un coupe-bande si GENRE vaut 'stop'. Dans
  les deux derniers cas l'ordre du filtre obtenu est le double de celui
  du prototype, comme dans MATLAB.

  GAINREFERENCE est le module attendu à la fréquence de référence — le
  continu pour un passe-bas, Nyquist pour un passe-haut, le centre de
  la bande pour un passe-bande ; il vaut 1 par défaut, mais un
  Chebyshev de type I d'ordre pair descend à 10^(-RP/20).

  Exemple :
     [z0, p0, k0] = buttap(4);
     [b, a] = prototypeVersNumerique(p0, z0, k0, 0.3, 'low');
     numel(a) - 1                % 4 : l'ordre est conserve en passe-bas

  Voir aussi BUTTER, BILINEAR, BUTTAP.
```

## `puissancesSousEspace`

```
PUISSANCESSOUSESPACE Puissance de chaque composante sinusoïdale.
  La matrice de corrélation vaut A P A' + sigma^2 I ; sigma^2 est la
  moyenne des plus petites valeurs propres, et P se lit par moindres
  carrés une fois les fréquences connues.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [R, m] = signalMatriceCorrelation(x, 2, false);
     pow = puissancesSousEspace(R, 2 * pi * 0.1, eig(R), 2);
     all(isfinite(pow))

  Voir aussi PMUSIC, PEIG, ROOTMUSIC.
```

## `pulseperiod`

```
PULSEPERIOD Période des impulsions.
  P = PULSEPERIOD(X,FS) rend l'écart entre deux fronts montants
  consécutifs, mesuré au niveau médian.

  Exemple :
     t = (0:0.001:0.5)';
     p = pulseperiod(double(sin(2*pi*10*t) > 0), 1000);
     abs(mean(p) - 0.1) < 0.01   % dix hertz : une periode de 0,1 s

  Voir aussi PULSEWIDTH, PULSESEP, DUTYCYCLE.
```

## `pulsesep`

```
PULSESEP Séparation entre impulsions.
  S = PULSESEP(X,FS) rend l'écart entre la fin d'une impulsion et le
  début de la suivante, mesuré au niveau médian.

  Exemple :
     t = (0:0.001:0.5)';
     s = pulsesep(double(sin(2*pi*10*t) > 0), 1000);
     all(s > 0)                  % 1

  Voir aussi PULSEPERIOD, PULSEWIDTH, DUTYCYCLE.
```

## `pulsewidth`

```
PULSEWIDTH Largeur des impulsions à mi-hauteur.
  W = PULSEWIDTH(X,FS) rend la durée entre le front montant et le front
  descendant qui le suit, mesurée au niveau médian.

  PULSEWIDTH(...,'Polarity','negative') mesure les creux.

  Exemple :
     t = (0:0.001:0.5)';
     l = pulsewidth(double(sin(2*pi*10*t) > 0), 1000);
     abs(mean(l) - 0.05) < 0.01  % un rapport cyclique de moitie

  Voir aussi PULSEPERIOD, PULSESEP, DUTYCYCLE.
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

  Voir aussi RECTPULS, TRIPULS, GAUSPULS.
```

## `pwelch`

```
PWELCH Densité spectrale par la méthode de Welch.
  [PXX,F] = PWELCH(X,FENETRE,RECOUVREMENT,NFFT,FS) découpe X en
  segments qui se recouvrent, fenêtre chacun, et moyenne les
  périodogrammes.

  FENETRE vaut soit une longueur de segment — la fenêtre est alors une
  Hamming de cette longueur — soit directement le vecteur de la
  fenêtre à employer. Vide, la longueur est le huitième du signal.

  Un périodogramme seul a une variance qui ne décroît pas avec la
  longueur du signal : allonger l'enregistrement affine la grille de
  fréquences sans rien calmer. Moyenner plusieurs périodogrammes, eux,
  divise la variance par leur nombre — c'est tout l'objet de la
  méthode, et le recouvrement sert à en obtenir davantage.

  Exemple :
     [p, f] = pwelch(randn(1024, 1), hamming(256), 128, 512, 1000);

  Voir aussi PERIODOGRAM, SPECTROGRAM, FFT, HAMMING.
```

## `pyulear`

```
PYULEAR Densité spectrale par un modèle autorégressif de Yule-Walker.
  [PXX,F] = PYULEAR(X,P,NFFT,FS). Le spectre paramétrique n'a pas de
  lobes de fuite : il est lisse, et sa résolution ne dépend pas de la
  longueur de l'enregistrement mais de l'ordre choisi.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [pxx, f] = pyulear(x, 8, 512, 1000);
     [~, k] = max(pxx);
     abs(f(k) - 100) < 10

  Voir aussi PBURG, PCOV, ARYULE.
```

## `rangerWalsh`

```
RANGERWALSH Passe de l'ordre naturel à l'ordre demandé.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     y = rangerWalsh((1:8)', 'sequency');
     numel(y)                    % 8

  Voir aussi RANGERWALSHINVERSE, PERMUTATIONWALSH, FWHT.
```

## `rangerWalshInverse`

```
RANGERWALSHINVERSE Revient de l'ordre demandé à l'ordre naturel.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     x = (1:8)';
     max(abs(rangerWalshInverse(rangerWalsh(x, 'sequency'), 'sequency') - x)) < 1e-12

  Voir aussi RANGERWALSH, PERMUTATIONWALSH, IFWHT.
```

## `rc2ac`

```
RC2AC Autocorrélation à partir des coefficients de réflexion.
  R = RC2AC(K,R0) remonte la récurrence de Levinson : à chaque ordre,
  le nouveau terme d'autocorrélation se déduit du polynôme courant.

  Exemple :
     k = [0.5 0.2];
     r = rc2ac(k, 1);
     max(abs(ac2rc(r) - k(:))) < 1e-10      % l'aller-retour

  Voir aussi AC2RC, RC2POLY, LEVINSON.
```

## `rc2poly`

```
RC2POLY Polynôme de prédiction à partir des coefficients de réflexion.
  A = RC2POLY(K) applique la récurrence de Levinson dans le sens
  direct. C'est l'inverse de POLY2RC.

  [A,E] = RC2POLY(K,R0) rend aussi l'erreur de prédiction finale, à
  partir de la puissance R0 du signal.

  Exemple :
     [a, e] = rc2poly([0.5 0.2], 1);
     all(abs(roots(a)) < 1)      % 1 : |k| < 1 donne un modele stable

  Voir aussi POLY2RC, RC2AC, LATC2TF.
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

  Voir aussi CCEPS, ICCEPS.
```

## `rectpuls`

```
RECTPULS Impulsion rectangulaire de largeur W centrée en zéro.
  L'impulsion vaut 1 sur [-W/2, W/2[ et 0 ailleurs ; W vaut 1 par défaut.

  Exemple :
     rectpuls([-1 -0.4 0 0.4 1])   % [0 1 1 1 0]

  Voir aussi TRIPULS, GAUSPULS, PULSTRAN.
```

## `resample`

```
RESAMPLE Rééchantillonnage d'un facteur rationnel P/Q.
  Y = RESAMPLE(X,P,Q) rend le signal rééchantillonné à P/Q fois sa
  cadence, par interpolation sur la nouvelle grille temporelle.
  [Y,T] = RESAMPLE(...) rend aussi les instants correspondants, en
  échantillons de la grille d'origine.

  Le nombre d'échantillons rendus est floor(N P / Q) : monter la cadence
  en produit plus, la descendre moins.

  L'orientation est conservée : une ligne rend une ligne.

  L'interpolation est linéaire, non par filtre polyphasé : c'est plus
  simple et suffisant quand le signal est déjà bien suréchantillonné,
  mais cela ne protège pas du repliement quand on décime. Filtrer avant
  de descendre en cadence reste nécessaire — UPFIRDN le fait d'un coup.

  Exemple :
     x = sin(2 * pi * 0.01 * (0:99));
     numel(resample(x, 3, 2))        % 149
     isrow(resample(x, 3, 2))        % true

  Voir aussi UPFIRDN, DECIMATE, INTERP, INTERP1.
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

  Voir aussi RESIDUE, TF2ZP, IMPZ.
```

## `risetime`

```
RISETIME Temps de montée d'un signal à deux états.
  R = RISETIME(X,FS) rend, pour chaque front montant, la durée entre le
  passage à 10 % et le passage à 90 % de l'écart entre les deux états.

  RISETIME(...,'PercentReferenceLevels',[BAS HAUT]) change les seuils.

  Exemple :
     risetime([0 0 0.5 1 1], 1)   % 0.8 : de 10 % à 90 %

  Voir aussi FALLTIME, SLEWRATE, OVERSHOOT.
```

## `rlevinson`

```
RLEVINSON Levinson-Durbin à l'envers.
  R = RLEVINSON(A,EFINAL) rend l'autocorrélation dont LEVINSON aurait
  tiré le polynôme de prédiction A et l'erreur finale EFINAL. C'est le
  chemin inverse de LEVINSON : il rend au modèle son autocorrélation.

  [R,U,KR,E] = RLEVINSON(A,EFINAL) rend en outre la matrice U des
  polynômes de prédiction de tous les ordres, les coefficients de
  réflexion KR et les erreurs de prédiction E de chaque ordre.

  Exemple :
     r = [5 4 3 2]';
     [a, e] = levinson(r, 3);
     max(abs(rlevinson(a, e) - r))     % nul aux arrondis près

  Voir aussi LEVINSON, POLY2RC, RC2POLY, POLY2AC, AC2POLY.
```

## `rms`

```
RMS Valeur efficace (racine de la moyenne des carrés).
  R = RMS(X) rend la racine de la moyenne des carrés de tous les
  éléments de X. R = RMS(X,DIM) opère le long de la dimension DIM.

  C'est la valeur d'un continu qui dissiperait la même puissance : le
  carré de la valeur efficace est la puissance moyenne, et c'est à ce
  titre qu'elle mesure un signal quelconque. Pour une sinusoïde
  d'amplitude A elle vaut A/sqrt(2), pour un carré d'amplitude A elle
  vaut A — deux signaux de même crête n'ont pas la même valeur efficace.

  Elle ne se confond pas avec l'écart type : celui-ci retranche d'abord
  la moyenne. Les deux coïncident sur un signal centré, et diffèrent dès
  qu'une composante continue s'ajoute.

  Exemple :
     rms(sin(2*pi*(0:999)/1000))

  Voir aussi STD, PEAK2RMS, BANDPOWER, MEAN.
```

## `rooteig`

```
ROOTEIG Fréquences par la méthode des vecteurs propres.
  Comme ROOTMUSIC, mais chaque vecteur propre du sous-espace bruit est
  pondéré par l'inverse de sa valeur propre : les directions les moins
  bruitées pèsent davantage.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     w = rooteig(x, 2);
     abs(min(abs(w)) / (2 * pi) - 0.1) < 0.02

  Voir aussi ROOTMUSIC, PEIG, PMUSIC.
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

  Voir aussi ROOTEIG, PMUSIC, PEIG.
```

## `rssq`

```
RSSQ Racine de la somme des carrés.
  Exemple :
     rssq([3 4])   % 5

  Voir aussi RMS, PEAK2RMS, BANDPOWER.
```

## `sawtooth`

```
SAWTOOTH Signal en dents de scie de période 2*pi.
  Y = SAWTOOTH(T) monte de -1 à +1 sur chaque période.
  Y = SAWTOOTH(T,LARGEUR) place le sommet à LARGEUR*2*pi.

  Exemple :
     y = sawtooth(linspace(0, 4 * pi, 100));
     [min(y) max(y)]             % -1 et 1

  Voir aussi SQUARE, CHIRP.
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

  Voir aussi POLY2RC, LEVINSON, AC2RC.
```

## `seqperiod`

```
SEQPERIOD Période la plus courte qui explique une séquence.
  P = SEQPERIOD(X) cherche le plus petit P tel que X(k+P) = X(k) pour
  tout k possible. Sans période exacte, rend celle qui minimise l'écart.

  Exemple :
     seqperiod([1 2 1 2 1 2])   % 2

  Voir aussi BUFFER, FINDPEAKS.
```

## `settlingtime`

```
SETTLINGTIME Temps d'établissement après chaque transition.
  S = SETTLINGTIME(X,FS,D) rend la durée entre la traversée médiane et
  l'instant à partir duquel le signal reste dans une bande de D pour
  cent de l'écart entre états autour du niveau atteint. D vaut 2 par
  défaut.

  Exemple :
     t = (0:0.001:1)';
     d = settlingtime(1 - exp(-20 * t), 1000);
     d > 0                       % 1

  Voir aussi RISETIME, OVERSHOOT, UNDERSHOOT.
```

## `sfdr`

```
SFDR Plage dynamique libre de parasites, en décibels.
  R = SFDR(X) compare la puissance du fondamental à celle du plus fort
  parasite, harmonique ou non.

  Exemple :
     t = (0:999)'/1000;
     sfdr(cos(2*pi*50*t) + 0.01*cos(2*pi*130*t))   % environ 40 dB

  Voir aussi SNR, SINAD, THD.
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

  Voir aussi SGOLAYFILT.
```

## `sgolayfilt`

```
SGOLAYFILT Lissage polynomial de Savitzky-Golay.
  Y = SGOLAYFILT(X,ORDRE,LONGUEUR) ajuste, sur chaque fenêtre de
  LONGUEUR points, un polynôme de degré ORDRE au sens des moindres
  carrés, et garde la valeur ajustée au centre.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.01 * (1:200)') + 0.1 * randn(200, 1);
     y = sgolayfilt(x, 3, 21);
     std(diff(y, 2)) < std(diff(x, 2))       % 1 : le lissage reduit la courbure

  Voir aussi SGOLAY, MEDFILT1.
```

## `signalLobe`

```
SIGNALLOBE Puissance d'un lobe spectral autour de la raie K.
  On somme de part et d'autre du sommet tant que le spectre décroît :
  la fuite de la fenêtre est ainsi ramassée avec la raie.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     S = [1 3 2 0.5 4 1];
     [p, plage] = signalLobe(S, 2);
     p > 0                       % 1

  Voir aussi SIGNALSOMMET, FINDPEAKS, SFDR.
```

## `signalMatriceCorrelation`

```
SIGNALMATRICECORRELATION Matrice d'autocorrélation pour les méthodes sous-espace.
  Si le premier argument est déjà une matrice de corrélation carrée, on
  la prend telle quelle. Sinon on l'estime par la méthode de la
  covariance modifiée, avant et arrière, sur une fenêtre d'ordre
  suffisant pour laisser un sous-espace bruit non vide.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [R, m] = signalMatriceCorrelation(x, 2, false);
     max(max(abs(R - R'))) < 1e-8           % 1 : elle est symetrique

  Voir aussi CORRMTX, PMUSIC, PEIG.
```

## `signalNiveaux`

```
SIGNALNIVEAUX Niveaux d'état et seuils de référence d'un signal.
  Traduit des pourcentages de l'écart entre les deux états en valeurs
  absolues, comme le font toutes les mesures de transition de MATLAB.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     t = (0:0.001:0.1)';
     [bas, haut, seuils] = signalNiveaux(double(t >= 0.05), [10 90 50]);
     seuils(1) < seuils(3) && seuils(3) < seuils(2)     % 1

  Voir aussi STATELEVELS, SIGNALTRAVERSES, SIGNALTRANSITIONS.
```

## `signalSommet`

```
SIGNALSOMMET Indice du maximum local le plus proche de AUTOUR.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     S = exp(-((1:100) - 40) .^ 2 / 50);
     signalSommet(S, 42, 10)     % 40 : le sommet le plus proche

  Voir aussi FINDPEAKS, SIGNALLOBE.
```

## `signalSpectrePuissance`

```
SIGNALSPECTREPUISSANCE Spectre de puissance unilatéral, fenêtre de Kaiser.
  Normalisé pour que la somme sur le lobe d'une sinusoïde d'amplitude A
  rende A^2/2, sa puissance. La fenêtre de Kaiser à beta = 38 est celle
  que MATLAB emploie pour ses mesures de distorsion : ses lobes
  secondaires à -180 dB laissent voir des harmoniques très faibles.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     rng(1);
     x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
     [S, f] = signalSpectrePuissance(x, 1);
     numel(S) == numel(f)        % 1

  Voir aussi PERIODOGRAM, SNR, THD.
```

## `signalTransitions`

```
SIGNALTRANSITIONS Découpe le signal en transitions et les mesure.
  Rend une matrice à cinq colonnes : instant de la traversée basse,
  instant de la traversée haute, instant de la traversée médiane,
  polarité (+1 montante, -1 descendante) et indice de l'échantillon de
  la traversée médiane.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     t = (0:0.001:0.1)';
     tr = signalTransitions(double(t >= 0.05), t, 10, 90);
     size(tr, 2)                 % 5 colonnes
     tr(1, 4)                    % 1 : la transition est montante

  Voir aussi SIGNALTRAVERSES, SIGNALNIVEAUX, RISETIME.
```

## `signalTraverses`

```
SIGNALTRAVERSES Instants de traversée d'un seuil, par interpolation.
  Rend les instants où X coupe SEUIL et, pour chacun, un booléen vrai
  si la traversée est montante.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     t = (0:0.001:0.1)';
     [instants, montantes] = signalTraverses(double(t >= 0.05), t, 0.5);
     abs(instants(1) - 0.05) < 2e-3

  Voir aussi SIGNALNIVEAUX, SIGNALTRANSITIONS, MIDCROSS.
```

## `sinad`

```
SINAD Rapport signal sur bruit et distorsion, en décibels.
  R = SINAD(X) compare la puissance du fondamental à celle de tout le
  reste, harmoniques et bruit confondus, la composante continue exclue.

  Exemple :
     t = (0:999)'/1000;
     sinad(cos(2*pi*50*t) + 0.1*cos(2*pi*100*t))   % environ 20 dB

  Voir aussi SNR, THD, SFDR.
```

## `slewrate`

```
SLEWRATE Vitesse de balayage d'un signal à deux états.
  S = SLEWRATE(X,FS) rend, pour chaque transition, la pente moyenne
  entre les seuils bas et haut : l'écart d'amplitude divisé par la
  durée. La pente est négative sur un front descendant.

  Exemple :
     slewrate([0 0 1 1], 1)   % 0.8/0.8 = 1 par seconde

  Voir aussi RISETIME, FALLTIME, MIDCROSS.
```

## `snr`

```
SNR Rapport signal sur bruit, en décibels.
  R = SNR(SIGNAL,BRUIT) rend 10*log10(puissance signal / puissance bruit).

  Exemple :
     rng(1);
     signal = sin(2 * pi * 0.05 * (0:999)');
     abs(snr(signal, 0.1 * randn(1000, 1)) - 20 * log10(rms(signal) / 0.1)) < 1

  Voir aussi SINAD, THD, SFDR, TOI.
```

## `sos2ss`

```
SOS2SS Représentation d'état d'un enchaînement de sections du second ordre.
  [A,B,C,D] = SOS2SS(SOS) rend une représentation d'état équivalente à
  l'enchaînement des sections du second ordre décrites par les lignes de
  SOS, chacune de la forme [b0 b1 b2 a0 a1 a2].
  [A,B,C,D] = SOS2SS(SOS,G) applique en plus le gain global G.

  Le passage se fait par la fonction de transfert développée, donc par
  la forme compagne. Cette forme est celle qui souffre le plus des
  erreurs d'arrondi sur les coefficients : c'est précisément pour
  l'éviter qu'on garde un filtre en sections du second ordre. Convertir
  n'a donc d'intérêt que pour raisonner sur l'état, pas pour filtrer.

  Exemple :
     [b, a] = butter(4, 0.3);
     [sos, g] = tf2sos(b, a);
     [A, B, C, D] = sos2ss(sos, g);

  Voir aussi SS2SOS, SOS2TF, TF2SS, TF2SOS.
```

## `sos2tf`

```
SOS2TF Sections du second ordre vers fonction de transfert.
  [B,A] = SOS2TF(SOS) développe l'enchaînement des sections du second
  ordre en une seule fonction de transfert B(z)/A(z), en convoluant les
  numérateurs entre eux et les dénominateurs entre eux.
  [B,A] = SOS2TF(SOS,G) multiplie le numérateur par le gain global G.

  Chaque ligne de SOS vaut [b0 b1 b2 a0 a1 a2]. Les zéros de tête du
  résultat sont retirés : un coefficient de tête nul ne décrit pas un
  degré, seulement un retard.

  Le développement est exact en arithmétique réelle et fragile en
  virgule flottante : sur un filtre d'ordre élevé, les coefficients
  développés s'étendent sur plusieurs ordres de grandeur et de petites
  erreurs relatives déplacent beaucoup les racines. C'est pour cela
  qu'on filtre en sections plutôt qu'avec B et A.

  Exemple :
     [b, a] = butter(4, 0.3);
     [sos, g] = tf2sos(b, a);
     [b2, a2] = sos2tf(sos, g);
     max(abs(b2 - b)) < 1e-10

  Voir aussi TF2SOS, SOS2ZP, SOS2SS, ZP2SOS.
```

## `sos2zp`

```
SOS2ZP Zéros, pôles et gain d'un enchaînement de sections du second ordre.
  [Z,P,K] = SOS2ZP(SOS,G) où SOS a une section par ligne, sous la forme
  [b0 b1 b2 a0 a1 a2].

  Exemple :
     [b, a] = butter(4, 0.3);
     [sos, g] = tf2sos(b, a);
     [z, p, k] = sos2zp(sos, g);
     all(abs(p) < 1)             % 1 : le filtre est stable

  Voir aussi ZP2SOS, SOS2TF, TF2SOS.
```

## `sosfilt`

```
SOSFILT Filtre par sections du second ordre, en cascade.
  Y = SOSFILT(SOS,X) applique chaque ligne de SOS l'une après l'autre.
  C'est la forme numériquement stable pour les filtres d'ordre élevé.

  Exemple :
     [b, a] = butter(4, 0.3);
     [sos, g] = tf2sos(b, a);
     rng(1);
     x = randn(100, 1);
     max(abs(sosfilt(sos, x, g) - filter(b, a, x))) < 1e-10

  Voir aussi TF2SOS.
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

  Voir aussi PWELCH, PERIODOGRAM.
```

## `square`

```
SQUARE Signal carré de période 2*pi.
  Y = SQUARE(T) vaut +1 sur la première moitié de la période, -1 sur la
  seconde. Y = SQUARE(T,RAPPORT) fixe le rapport cyclique en pour cent.

  Exemple :
     y = square(linspace(0, 4 * pi, 100));
     unique(y)                   % -1 et 1

  Voir aussi SAWTOOTH, CHIRP, PULSTRAN.
```

## `ss2sos`

```
SS2SOS Sections du second ordre d'une représentation d'état.
  [SOS,G] = SS2SOS(A,B,C,D) rend les sections du second ordre
  équivalentes à la représentation d'état donnée, et le gain global G.
  [SOS,G] = SS2SOS(A,B,C,D,IU) choisit l'entrée numéro IU quand le
  système en a plusieurs ; par défaut la première.

  Le chemin passe par la fonction de transfert, puis par le groupement
  des pôles et zéros conjugués en sections du second ordre. Un filtre
  d'ordre impair donne une section du premier ordre, complétée par des
  coefficients nuls.

  L'intérêt de la forme d'arrivée est numérique : chaque section n'a que
  deux pôles, dont la position ne dépend que de deux coefficients, si
  bien qu'un arrondi de quantification ne déplace jamais un pôle plus
  loin que dans sa propre section.

  Exemple :
     [b, a] = butter(4, 0.3);
     [A, B, C, D] = tf2ss(b, a);
     [sos, g] = ss2sos(A, B, C, D);

  Voir aussi SOS2SS, TF2SOS, ZP2SOS, SS2TF.
```

## `ss2zp`

```
SS2ZP Zéros, pôles et gain d'une représentation d'état.
  Les pôles sont les valeurs propres de A ; les zéros sont les racines
  du numérateur de la fonction de transfert.

  Exemple :
     [b, a] = butter(4, 0.3);
     [A, B, C, D] = tf2ss(b, a);
     [z, p, k] = ss2zp(A, B, C, D);
     all(abs(p) < 1)             % 1

  Voir aussi ZP2SS, SS2SOS, TF2ZP.
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

  Voir aussi MIDCROSS, RISETIME, SIGNALNIVEAUX.
```

## `stepz`

```
STEPZ Réponse indicielle d'un filtre numérique.
  [H,T] = STEPZ(B,A,N) : la réponse à un échelon unité.

  Exemple :
     [b, a] = butter(4, 0.3);
     [h, t] = stepz(b, a, 100);
     abs(h(end) - 1) < 0.01      % la reponse indicielle tend vers le gain continu

  Voir aussi IMPZ.
```

## `stmcb`

```
STMCB Modèle rationnel par la méthode de Steiglitz-McBride.
  [B,A] = STMCB(H,NB,NA) rend le filtre d'ordre NB au numérateur et NA
  au dénominateur dont la réponse impulsionnelle approche H au sens des
  moindres carrés. Contrairement à PRONY, l'erreur minimisée est celle
  de la sortie, non celle de l'équation : le modèle obtenu est en
  général meilleur.

  [B,A] = STMCB(Y,X,NB,NA) modélise le filtre qui transforme l'entrée X
  en la sortie Y.
  [B,A] = STMCB(...,NITER) fait NITER itérations (5 par défaut).
  [B,A] = STMCB(...,NITER,AI) part du dénominateur AI.

  Exemple :
     [b, a] = butter(4, 0.3);
     h = impz(b, a, 60);
     [bb, aa] = stmcb(h, 4, 4);
     max(abs(impz(bb, aa, 60) - h))     % très petit

  Voir aussi PRONY, LEVINSON, LPC, INVFREQZ.
```

## `strips`

```
STRIPS Trace un signal en bandes superposées.
  STRIPS(X) découpe X en bandes de 250 points et les trace les unes
  sous les autres : c'est la façon de voir d'un coup d'œil un signal
  long, dont la période saute alors aux yeux.

  STRIPS(X,N) met N points par bande.
  STRIPS(X,SD,FS) met SD secondes par bande, FS étant la fréquence
  d'échantillonnage.
  STRIPS(X,SD,FS,ECHELLE) multiplie l'amplitude par ECHELLE avant le
  tracé.

  Exemple :
     strips(sin(2*pi*(0:999)/50));

  Voir aussi PLOT, SPECTROGRAM, BUFFER.
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

  Voir aussi CHEBWIN, KAISER, WINDOW.
```

## `tf2latc`

```
TF2LATC Transfert -> structure en treillis.
  K = TF2LATC(B) rend les coefficients de réflexion du treillis qui
  réalise le filtre à réponse finie B. B est normalisé par son premier
  coefficient.

  K = TF2LATC(1,A) rend le treillis tout-pôle du filtre 1/A(z).
  [K,V] = TF2LATC(B,A) rend en outre les coefficients de l'échelle, qui
  ajoutent les zéros : c'est la structure treillis-échelle.

  Un treillis se prête mieux qu'une forme directe à l'arithmétique en
  virgule fixe : la stabilité s'y lit sur les coefficients, tous de
  module inférieur à 1, et un arrondi ne la détruit pas.

  Exemple :
     [b, a] = butter(3, 0.4);
     [k, v] = tf2latc(b, a);
     all(abs(k) < 1)      % le filtre est stable

  Voir aussi LATC2TF, LATCFILT, POLY2RC, RC2POLY, TF2SOS.
```

## `tf2sos`

```
TF2SOS Fonction de transfert vers sections du second ordre.
  [SOS,G] = TF2SOS(B,A) rend une matrice Lx6, chaque ligne étant
  [b0 b1 b2 1 a1 a2], et le gain global G. Les pôles complexes sont
  appariés à leur conjugué, ce qui garde des coefficients réels.

  Exemple :
     [b, a] = butter(4, 0.3);
     [sos, g] = tf2sos(b, a);
     size(sos, 1)                % 2 sections pour un ordre 4

  Voir aussi SOS2TF, ZP2SOS, SOS2ZP, TF2ZP.
```

## `tf2zp`

```
TF2ZP Fonction de transfert vers zéros, pôles et gain.
  [Z,P,K] = TF2ZP(B,A). Les coefficients sont donnés par puissances
  décroissantes ; K est b(1)/a(1).

  Exemple :
     [z, p, k] = tf2zp([1 -1], [1 -0.5]);   % z = 1, p = 0.5, k = 1

  Voir aussi ZP2TF, TF2SOS, SS2ZP.
```

## `tf2zpk`

```
TF2ZPK Transfert numérique -> zéros, pôles et gain.
  [Z,P,K] = TF2ZPK(B,A) rend les zéros, les pôles et le gain du filtre
  numérique de fonction de transfert B(z)/A(z), les polynômes étant
  écrits en puissances décroissantes de z.

  C'est le pendant de TF2ZP pour les filtres numériques : les zéros de
  tête de B, qui ne sont que des retards, sont écartés au lieu de
  devenir des zéros à l'infini.

  Exemple :
     [b, a] = butter(3, 0.4);
     [z, p, k] = tf2zpk(b, a);
     all(abs(p) < 1)        % le filtre est stable

  Voir aussi TF2ZP, ZP2TF, ZPLANE, TF2SOS.
```

## `tfestimate`

```
TFESTIMATE Estimation de la fonction de transfert entre deux signaux.
  H = TFESTIMATE(X,Y,...) vaut Pxy/Pxx : la réponse du système qui mène
  de X à Y, au sens des moindres carrés.

  Exemple :
     rng(1);
     x = randn(4096, 1);
     [h, f] = tfestimate(x, filter(1, [1 -0.8], x), [], [], 256, 1);
     abs(abs(h(1)) - 5) < 1      % 1/(1-0.8) = 5 au continu

  Voir aussi CPSD, MSCOHERE, PWELCH.
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

  Voir aussi SNR, SINAD, SFDR.
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

  Voir aussi SNR, SINAD, SFDR.
```

## `triang`

```
TRIANG Fenêtre triangulaire.
  W = TRIANG(N). Contrairement à BARTLETT, les extrémités ne sont pas
  nulles : c'est la différence que documente MathWorks entre les deux.

  Exemple :
     triang(4)'   % [0.25 0.75 0.75 0.25]

  Voir aussi WINDOW, PARZENWIN.
```

## `tripuls`

```
TRIPULS Impulsion triangulaire de largeur W et d'asymétrie S.
  S vaut 0 pour un triangle symétrique, -1 pour une rampe descendante,
  +1 pour une rampe montante. W vaut 1 et S vaut 0 par défaut.

  Exemple :
     tripuls([-0.5 -0.25 0 0.25 0.5])   % [0 0.5 1 0.5 0]

  Voir aussi RECTPULS, GAUSPULS, PULSTRAN.
```

## `tukeywin`

```
TUKEYWIN Fenêtre de Tukey, cosinus surélevé à rapport réglable.
  W = TUKEYWIN(N,R) : R = 0 donne la fenêtre rectangulaire, R = 1 la
  fenêtre de Hann. R vaut 0,5 par défaut.

  Exemple :
     isequal(tukeywin(8, 0), rectwin(8))   % vrai

  Voir aussi WINDOW.
```

## `udecode`

```
UDECODE Reconstruit un signal à partir de ses codes entiers.
  Y = UDECODE(U,N) est l'inverse d'UENCODE : il ramène les codes sur N
  bits dans l'intervalle [-1, 1[.
  Y = UDECODE(U,N,V) ramène dans [-V, V[.
  Y = UDECODE(U,N,V,'wrap') fait boucler les codes hors bornes au lieu
  de les saturer.

  Exemple :
     codes = uencode(-1:0.5:1, 3);
     udecode(codes, 3)

  Voir aussi UENCODE, QUANTIZ, CAST.
```

## `uencode`

```
UENCODE Quantification uniforme d'un signal.
  Y = UENCODE(U,N) quantifie U sur 2^N niveaux entre -1 et 1 et rend
  les codes entiers non signés, de 0 à 2^N-1. Ce qui déborde est écrêté.

  Y = UENCODE(U,N,V) quantifie entre -V et V.
  Y = UENCODE(U,N,V,'signed') rend des codes signés, de -2^(N-1) à
  2^(N-1)-1.

  La classe du résultat est le plus petit entier qui contient les
  codes : uint8, uint16 ou uint32, signés le cas échéant.

  Exemple :
     uencode(-1:0.5:1, 3)     % [0 2 4 6 7]

  Voir aussi UDECODE, QUANTIZ, ROUND, CAST.
```

## `undershoot`

```
UNDERSHOOT Creux avant chaque transition, en pourcentage.
  Symétrique d'OVERSHOOT : l'extremum est cherché avant la transition,
  du côté opposé au niveau de départ.

  Exemple :
     t = (0:0.001:0.2)';
     [p, v, instant] = undershoot(exp(-30*t) .* sin(2*pi*30*t) + double(t > 0), 1000);
     p >= 0                      % 1

  Voir aussi OVERSHOOT, SETTLINGTIME, FALLTIME.
```

## `vco`

```
VCO Oscillateur commandé en tension.
  Y = VCO(X,FC,FS) rend un cosinus dont la fréquence instantanée suit
  X : X = -1 donne 0 hertz, X = 0 donne FC, X = +1 donne 2*FC.

  Y = VCO(X,[FMIN FMAX],FS) fixe les fréquences des extrêmes -1 et +1.

  Exemple :
     fs = 1e4;  t = (0:fs-1)'/fs;  y = vco(sin(2*pi*t), 1e3, fs);

  Voir aussi CHIRP, MODULATE, DEMOD.
```

## `window`

```
WINDOW Fabrique une fenêtre par son nom ou sa poignée.
  W = WINDOW(@hamming, N) équivaut à HAMMING(N).
  W = WINDOW(@chebwin, N, R) passe les arguments supplémentaires.

  Exemple :
     w = window(@kaiser, 64, 5);

  Voir aussi KAISER.
```

## `xcov`

```
XCOV Covariance croisée : la corrélation des signaux centrés.
  [C,LAGS] = XCOV(X,Y) retranche la moyenne avant de corréler.
  XCOV(X) donne l'autocovariance.

  Exemple :
     c = xcov([1 2 3 4], 'coeff');   % c(4) == 1

  Voir aussi CORRMTX.
```

## `yulewalk`

```
YULEWALK Filtre récursif ajusté sur un gabarit de module.
  [B,A] = YULEWALK(N,F,M) conçoit un filtre d'ordre N dont le module
  suit la courbe donnée par les points (F,M). F va de 0 à 1, 1 valant
  la moitié de la fréquence d'échantillonnage, et doit croître ; M
  donne le module visé. Contrairement à FIRPM, la phase n'est pas
  imposée : seul le module compte.

  La méthode est celle de Friedlander et Porat : le dénominateur sort
  des équations de Yule-Walker modifiées, écrites sur l'autocorrélation
  déduite du gabarit ; le numérateur vient ensuite d'une factorisation
  spectrale à phase minimale du spectre résiduel.

  Exemple :
     [b, a] = yulewalk(8, [0 0.6 0.6 1], [1 1 0 0]);

  Voir aussi FIRPM, FIR2, BUTTER.
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

  Voir aussi PHASEZ, ZPLANE.
```

## `zp2sos`

```
ZP2SOS Zéros et pôles vers sections du second ordre.
  Les racines complexes sont appariées avec leur conjuguée ; les racines
  réelles sont groupées deux par deux. Le résultat est réel.

  Exemple :
     [z, p, k] = butter(4, 0.3);
     [sos, g] = zp2sos(z, p, k);
     size(sos, 2)                % 6 colonnes par section

  Voir aussi SOS2ZP, TF2SOS, ZP2TF.
```

## `zp2ss`

```
ZP2SS Représentation d'état à partir des zéros, pôles et gain.
  [A,B,C,D] = ZP2SS(Z,P,K) rend une représentation d'état ayant les
  zéros Z, les pôles P et le gain K.

  Les valeurs propres de A sont les pôles : la conversion place la
  dynamique dans la matrice d'état, et les zéros dans le couplage C et
  D. Un système strictement propre — plus de pôles que de zéros — a D
  nul, et un zéro autant de pôles qu'il en faut pour que D ne le soit
  pas.

  Le passage emprunte la fonction de transfert développée, donc la forme
  compagne : sur un ordre élevé, mieux vaut convertir en sections du
  second ordre par ZP2SOS que raisonner sur cette forme d'état.

  Exemple :
     [A, B, C, D] = zp2ss([], [-1 -2], 1);
     sort(eig(A))'

  Voir aussi ZP2TF, ZP2SOS, SS2ZP, TF2SS.
```

## `zp2tf`

```
ZP2TF Zéros, pôles et gain vers fonction de transfert.
  [B,A] = ZP2TF(Z,P,K) rend les coefficients par puissances décroissantes.

  Exemple :
     [b, a] = zp2tf([], [-1 -2], 1);
     a                           % 1 3 2 : (s+1)(s+2)

  Voir aussi TF2ZP, ZP2SOS, ZP2SS.
```

## `zplane`

```
ZPLANE Trace les zéros et les pôles dans le plan complexe.
  ZPLANE(B,A) à partir des coefficients, ZPLANE(Z,P) à partir des zéros
  et des pôles. Le cercle unité sert de repère.

  Exemple :
     [b, a] = butter(4, 0.3);
     zplane(b, a);
     close all;

  Voir aussi TF2ZP, ISSTABLE.
```

