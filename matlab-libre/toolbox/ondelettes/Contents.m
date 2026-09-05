% Wavelet Toolbox — analyse en ondelettes.
%
% Bancs de filtres
%   wfilters          - Filtres d'analyse et de synthèse (dbN, symN, coifN,
%                       haar, biorNr.Nd, rbioNd.Nr)
%   orthfilt          - Banc orthogonal à partir du filtre d'échelle
%   biorfilt          - Banc biorthogonal à partir des deux filtres
%   daubechiesFiltre  - Filtre de Daubechies par factorisation spectrale
%   qmf               - Miroir en quadrature d'un filtre
%   wavefun           - Fonctions d'échelle et d'ondelette (cascade)
%   wavenames         - Liste des ondelettes disponibles
%   wavemngr          - Gestion des familles : lire, ajouter, retirer
%   dwtfilterbank     - Banc discret : réponses, repère, facteur de qualité
%   dwtmode           - Mode de prolongement des bords
%   waveinfo          - Renseignements sur une famille d'ondelettes
%   centfrq           - Fréquence centrale d'une ondelette
%   scal2frq          - Conversion échelle vers fréquence
%
% Familles d'ondelettes
%   dbaux, dbwavf     - Filtre d'échelle de Daubechies, par ordre ou par nom
%   symaux, symwavf   - Filtre d'échelle d'un symlet
%   coifwavf          - Filtre d'échelle d'une coiflette
%   coifletFiltre     - La coiflette par ses conditions, sans table
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
% Transformée stationnaire et à chevauchement maximal
%   swt, iswt         - Transformée stationnaire d'un signal
%   swt2, iswt2       - La même, pour une image
%   modwt, imodwt     - Transformée à chevauchement maximal
%   modwtmra          - Analyse multirésolution correspondante
%   modwtvar          - Variance par échelle
%   modwtcorr         - Corrélation par échelle entre deux signaux
%   modwtxcorr        - Corrélation croisée par échelle
%
% Transformée continue
%   cwt, icwt            - Transformée continue et son inverse
%   cwtfilterbank        - Banc continu : coefficients, fréquences, cône
%   cwtfreqbounds        - Bornes de fréquence utiles pour N points
%   ondeletteAnalytique  - Morse, Morlet analytique et bosse, en fréquence
%   wsst                 - Transformée synchronisée
%   wcoherence           - Cohérence en ondelettes de deux signaux
%
% Arbre double, ondelettes complexes
%   dualtree, idualtree  - Transformée par arbre double et son inverse
%   dtfilters            - Filtres des deux arbres
%   qshiftFiltre         - Filtre de quart de retard, par ses conditions
%
% Transformée discrète, deux dimensions
%   dwt2, idwt2       - Transformée à un niveau et son inverse
%   wavedec2, waverec2 - Décomposition et reconstruction multiniveaux
%   appcoef2, detcoef2 - Extraction des coefficients d'un niveau
%   wrcoef2           - Reconstruction d'un seul niveau
%   upcoef2           - Reconstruction directe d'un bloc de coefficients
%   upwlev2           - Remontée d'un niveau dans la décomposition
%   wenergy2          - Répartition de l'énergie par niveau
%   wthcoef2          - Seuillage ou atténuation par bloc
%   wavefun2          - Les quatre fonctions de la base bidimensionnelle
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
%   wdenoise2         - Le même, pour une image
%   wden              - Débruitage automatique, interface d'origine
%   wnoise            - Signaux d'essai de Donoho et Johnstone
%   measerr           - Mesures de qualité : PSNR, erreur, énergie gardée
%
% Paquets d'ondelettes
%   wpdec, wprec      - Décomposition et reconstruction d'un signal
%   wpdec2, wprec2    - Les mêmes, pour une image
%   wpcoef, wprcoef   - Coefficients d'un nœud, composante d'un nœud
%   wpsplt, wpjoin    - Scinder une feuille, refermer une branche
%   leaves, tnodes    - Nœuds terminaux
%   ntnode, treedpth  - Nombre de feuilles, profondeur de l'arbre
%   depo2ind, ind2depo - Indice d'un nœud et son couple profondeur-place
%   wentropy          - Entropie d'un bloc de coefficients
%   besttree          - Meilleure base au sens de l'entropie
%   wpthcoef          - Seuillage des coefficients de l'arbre
%   wpdencmp          - Débruitage ou compression par paquets
%   wpfun             - Fonctions de paquets W0, W1, W2, ...
%   modwpt, imodwpt   - Paquets à chevauchement maximal, en ordre de
%                       séquence
%
% Séries longue mémoire
%   wfbm              - Mouvement brownien fractionnaire
%   wfbmesti          - Estimation du paramètre de Hurst
%   wvarchg           - Détection de ruptures de variance
%
% Outils sur les signaux
%   wextend           - Prolongement aux bords (9 modes)
%   wkeep             - Extraction centrée
%   wrev              - Renversement
%   dyadup, dyaddown  - Sur- et sous-échantillonnage dyadique
%   wconv1, wconv2    - Convolution en une et deux dimensions
