% Computer Vision Toolbox — vision par ordinateur.
%
% Points d'intérêt et descripteurs
%   detectHarrisFeatures   - Coins de Harris
%   detectMinEigenFeatures - Coins de Shi et Tomasi
%   detectFASTFeatures     - Coins FAST
%   extractFeatures        - Descripteurs de voisinage
%   extractHOGFeatures     - Histogrammes de gradients orientés
%   extractLBPFeatures     - Motifs binaires locaux
%   matchFeatures          - Appariement de descripteurs
%   selectStrongest        - Les N points les mieux notés
%   selectUniform          - Points répartis sur toute l'image
%
% Images intégrales
%   integralImage          - Table de sommes cumulées
%   integralFilter         - Filtrage par boîtes pondérées
%
% Géométrie
%   estimateGeometricTransform   - Transformation affine par moindres carrés
%   estimateGeometricTransform2D - Similitude, affine ou projective
%   estimateFundamentalMatrix    - Matrice fondamentale, huit points ou MSAC
%   epipolarLine                 - Droites épipolaires
%   triangulate                  - Reconstruction par intersection de rayons
%   rotationVectorToMatrix       - Formule de Rodrigues
%   rotationMatrixToVector       - Axe et angle d'une rotation
%   generateCheckerboardPoints   - Coins d'un damier d'étalonnage
%   houghLines                   - Droites par transformée de Hough
%
% Stéréo et mouvement
%   stereoAnaglyph         - Anaglyphe rouge-cyan
%   disparityBM            - Disparité par appariement de blocs
%   opticalFlowLK          - Flot optique de Lucas et Kanade
%   opticalFlowHS          - Flot optique de Horn et Schunck
%   assignDetectionsToTracks - Appariement optimal, algorithme hongrois
%
% Boîtes englobantes
%   bbox2points             - Coins d'une boîte
%   bboxresize              - Redimensionnement
%   bboxOverlapRatio        - Recouvrement de deux boîtes
%   bboxOverlapRatioMatrix  - Recouvrement de toutes les paires
%   bboxPrecisionRecall     - Précision et rappel d'une détection
%   selectStrongestBbox     - Suppression des non-maxima
%
% Affichage
%   insertShape             - Dessin de formes dans une image
%   insertMarker            - Marqueurs sur une image
