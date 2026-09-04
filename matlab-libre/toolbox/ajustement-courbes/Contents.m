% Curve Fitting Toolbox — ajustement de courbes et de surfaces.
%
% Ajuster
%   fit                 - Ajuste un modèle à des données
%   fittype             - Modèle, nommé ou écrit à la main
%   fitoptions          - Réglages de l'ajustement
%   setoptions          - Attache des réglages à un modèle
%   cfit                - Courbe ajustée, qu'on évalue comme une fonction
%   sfit                - Surface ajustée
%
% Ce qu'on demande à un ajustement
%   feval               - L'évaluer
%   coeffvalues         - La valeur des coefficients
%   confint             - Leur intervalle de confiance
%   predint             - L'intervalle de la courbe, ou d'une observation
%   differentiate       - Ses dérivées
%   integrate           - Sa primitive
%   plot                - Son tracé
%   formula, coeffnames, probnames, probvalues
%   indepnames, dependnames, argnames, numargs, numcoeffs
%   islinear, type
%
% Préparer les données
%   prepareCurveData    - Colonnes, sans point non fini
%   prepareSurfaceData  - De même, en dépliant une grille
%   excludedata         - Masque des points à écarter
%   smooth              - Lissage : moyenne mobile, régression locale,
%                         Savitzky et Golay, variantes robustes
%
% Splines
%   csaps               - Spline de lissage, compromis réglé
%   spaps               - Spline la plus lisse dans une tolérance
%   csape               - Interpolation à conditions de bord choisies
%   spap2               - Spline des moindres carrés, à nœuds donnés
%   augknt              - Répétition des nœuds extrêmes
%   fnval               - Évaluation
%   fnder, fnint        - Dérivée et primitive
%   fnbrk               - Extraction d'une partie
%   fnplt               - Tracé
%
% Anciennes commodités de MatLibre
%   fitCurve            - Ajustement par un modèle nommé
%   fitSurface          - Ajustement polynomial d'une surface
%   goodnessOfFit       - R2, RMSE, SSE
%   smoothSpline        - Lissage par spline pénalisée
