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
%   maxflat     - (absent) filtre à module maximalement plat
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
