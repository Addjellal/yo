% Wavelet Toolbox — analyse en ondelettes.
%
% Bancs de filtres
%   wfilters          - Filtres d'analyse et de synthèse (dbN, symN, haar,
%                       biorNr.Nd, rbioNd.Nr)
%   orthfilt          - Banc orthogonal à partir du filtre d'échelle
%   biorfilt          - Banc biorthogonal à partir des deux filtres
%   daubechiesFiltre  - Filtre de Daubechies par factorisation spectrale
%   qmf               - Miroir en quadrature d'un filtre
%   wavefun           - Fonctions d'échelle et d'ondelette (cascade)
%   wavenames         - Liste des ondelettes disponibles
%   waveinfo          - Renseignements sur une famille d'ondelettes
%   centfrq           - Fréquence centrale d'une ondelette
%   scal2frq          - Conversion échelle vers fréquence
%
% Familles d'ondelettes
%   dbaux, dbwavf     - Filtre d'échelle de Daubechies, par ordre ou par nom
%   symaux, symwavf   - Filtre d'échelle d'un symlet
%   biorwavf          - Couple biorthogonal spline
%   rbiowavf          - Le même, analyse et synthèse échangées
%   meyer, meyeraux   - Ondelette de Meyer et sa fonction de transition
%   mexihat           - Chapeau mexicain
%   morlet            - Ondelette de Morlet réelle
%   gauswavf          - Dérivées de la gaussienne, ordres 1 à 8
%   cgauwavf          - Les mêmes, modulées : gaussiennes complexes
%   cmorwavf          - Morlet complexe
%   shanwavf          - Ondelette de Shannon
%   fbspwavf          - Spline en fréquence
%
% Transformée discrète, une dimension
%   dwt, idwt         - Transformée à un niveau et son inverse
%   wavedec, waverec  - Décomposition et reconstruction multiniveaux
%   wmaxlev           - Niveau maximal utile
%   appcoef, detcoef  - Extraction des coefficients d'un niveau
%   wrcoef            - Reconstruction d'un seul niveau
%   upcoef            - Reconstruction directe d'un vecteur de coefficients
%   upwlev            - Remontée d'un niveau dans la décomposition
%   wenergy           - Répartition de l'énergie par niveau
%
% Transformée discrète, deux dimensions
%   dwt2, idwt2       - Transformée à un niveau et son inverse
%   wavedec2, waverec2 - Décomposition et reconstruction multiniveaux
%   appcoef2, detcoef2 - Extraction des coefficients d'un niveau
%   wrcoef2           - Reconstruction d'un seul niveau
%   wcodemat          - Mise à l'échelle pour l'affichage
%
% Transformées redondantes
%   swt, iswt         - Transformée stationnaire (à trous)
%   modwt, imodwt     - Transformée à chevauchement maximal
%   modwtmra          - Analyse multirésolution associée
%   cwt               - Transformée continue (mexh, morl, gausP, dbN)
%
% Débruitage et compression
%   wthresh           - Seuillage dur ou doux
%   wthcoef           - Seuillage des coefficients d'une décomposition
%   thselect          - Choix du seuil (rigrsure, heursure, sqtwolog, minimaxi)
%   wnoisest          - Estimation robuste de l'écart type du bruit
%   ddencmp           - Réglages par défaut du débruitage
%   wdencmp           - Débruitage ou compression par seuillage
%   wdenoise          - Débruitage par seuillage universel
%   wnoise            - Signaux d'essai de Donoho et Johnstone
%
% Outils sur les signaux
%   wextend           - Prolongement aux bords (9 modes)
%   wkeep             - Extraction centrée
%   wrev              - Renversement
%   dyadup, dyaddown  - Sur- et sous-échantillonnage dyadique
%   wconv1, wconv2    - Convolution en une et deux dimensions
