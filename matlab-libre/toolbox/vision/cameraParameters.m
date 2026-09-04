function parametres = cameraParameters(varargin)
%CAMERAPARAMETERS Paramètres complets d'une caméra, internes et externes.
%   C = CAMERAPARAMETERS('IntrinsicMatrix',K,'RadialDistortion',R,...)
%   réunit ce qui décrit une caméra : sa géométrie interne, la distorsion
%   de son objectif, et éventuellement la pose qu'elle avait pour chaque
%   image d'étalonnage.
%
%   Les propriétés : IntrinsicMatrix, FocalLength, PrincipalPoint, Skew,
%   RadialDistortion, TangentialDistortion, RotationMatrices,
%   TranslationVectors, ImageSize.
%
%   Exemple :
%      c = cameraParameters('IntrinsicMatrix', [800 0 0; 0 800 0; 320 240 1]);
%
%   Voir aussi CAMERAINTRINSICS, CAMERAMATRIX, UNDISTORTPOINTS.
    K = eye(3);
    radiale = [0 0];
    tangentielle = [0 0];
    rotations = [];
    translations = [];
    tailleImage = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'intrinsicmatrix',      K = double(varargin{k+1});
            case 'radialdistortion',     radiale = double(varargin{k+1}(:)).';
            case 'tangentialdistortion', tangentielle = double(varargin{k+1}(:)).';
            case 'rotationmatrices',     rotations = varargin{k+1};
            case 'translationvectors',   translations = double(varargin{k+1});
            case 'imagesize',            tailleImage = double(varargin{k+1}(:)).';
            case {'worldpoints', 'worldunits', 'estimateskew', ...
                  'numradialdistortioncoefficients', 'estimatetangentialdistortion'}
                % acceptés pour la compatibilité
            otherwise
                error('vision:cameraParameters:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    parametres = struct('FinObj', 'cameraParameters', 'IntrinsicMatrix', K, ...
                        'K', K.', 'FocalLength', [K(1, 1), K(2, 2)], ...
                        'PrincipalPoint', [K(3, 1), K(3, 2)], 'Skew', K(2, 1), ...
                        'RadialDistortion', radiale, ...
                        'TangentialDistortion', tangentielle, ...
                        'RotationMatrices', rotations, ...
                        'TranslationVectors', translations, ...
                        'ImageSize', tailleImage);
end
