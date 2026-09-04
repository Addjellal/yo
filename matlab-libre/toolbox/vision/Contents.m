% Computer Vision Toolbox — vision par ordinateur.
%
% Points d'intérêt et descripteurs
%   detectHarrisFeatures   - Coins de Harris
%   detectMinEigenFeatures - Coins de Shi et Tomasi
%   detectFASTFeatures     - Coins FAST
%   detectBRISKFeatures    - Coins FAST retenus dans l'espace des échelles
%   detectORBFeatures      - Coins FAST orientés, sur une pyramide
%   detectSURFFeatures     - Taches, par la Hessienne approchée
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
%   estimateUncalibratedRectification - Rectification sans calibrage
%   epipolarLine                 - Droites épipolaires
%   triangulate                  - Reconstruction par intersection de rayons
%   rotationVectorToMatrix       - Formule de Rodrigues
%   rotationMatrixToVector       - Axe et angle d'une rotation
%   generateCheckerboardPoints   - Coins d'un damier d'étalonnage
%   houghLines                   - Droites par transformée de Hough
%
% Caméra
%   cameraIntrinsics        - Paramètres internes d'une caméra
%   cameraParameters        - Paramètres internes et distorsion
%   cameraMatrix            - Matrice de projection complète
%   worldToImage            - Projection de points du monde
%   pointsToWorld           - Relèvement sur le plan z égal zéro
%   undistortPoints         - Correction de la distorsion
%
% Stéréo et mouvement
%   stereoAnaglyph          - Anaglyphe rouge-cyan
%   disparityBM             - Disparité par appariement de blocs
%   disparitySGM            - Disparité par appariement semi-global
%   rectifyStereoImages     - Redressement d'une paire stéréo
%   reconstructScene        - Nuage de points à partir d'une disparité
%   opticalFlowLK           - Flot optique de Lucas et Kanade
%   opticalFlowHS           - Flot optique de Horn et Schunck
%   opticalFlowFarneback    - Flot optique par expansion polynomiale
%   assignDetectionsToTracks - Appariement optimal, algorithme hongrois
%
% Nuages de points
%   pointCloud              - Nuage de points, organisé ou non
%   pctransform             - Transformation rigide d'un nuage
%   pcdownsample            - Allègement au hasard ou par grille
%   pcdenoise               - Retrait des points isolés
%   pcmerge                 - Fusion de deux nuages
%   pcnormals               - Normales par plan tangent local
%   pcfitplane              - Plan dominant, par tirages aléatoires
%   pcsegdist               - Groupes de points connexes
%   pcregistericp           - Recalage par points les plus proches
%
% Régions
%   superpixels             - Découpage en régions homogènes
%   labeloverlay            - Superposition d'un étiquetage
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
%   insertText              - Texte dans une image
%   insertObjectAnnotation  - Objets entourés et nommés
