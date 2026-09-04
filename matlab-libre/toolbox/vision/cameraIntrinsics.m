function parametres = cameraIntrinsics(focale, pointPrincipal, tailleImage, varargin)
%CAMERAINTRINSICS Paramètres internes d'une caméra.
%   C = CAMERAINTRINSICS([FX FY],[CX CY],[H L]) décrit la géométrie d'une
%   caméra : distances focales en pixels, point principal, taille de
%   l'image.
%
%   La matrice rendue suit la convention de MATLAB, transposée de la
%   convention usuelle : le point est un vecteur ligne et la matrice le
%   multiplie à droite. C'est la même géométrie, écrite dans l'autre sens.
%
%   CAMERAINTRINSICS(...,'RadialDistortion',K,'TangentialDistortion',P,
%   'Skew',S) ajoute la distorsion de l'objectif et l'obliquité des
%   pixels.
%
%   Exemple :
%      c = cameraIntrinsics([800 800], [320 240], [480 640]);
%      c.K
%
%   Voir aussi CAMERAPARAMETERS, CAMERAMATRIX, WORLDTOIMAGE, POINTSTOWORLD.
    focale = double(focale(:)).';
    if isscalar(focale)
        focale = [focale focale];
    end
    pointPrincipal = double(pointPrincipal(:)).';
    if nargin < 3 || isempty(tailleImage)
        tailleImage = [];
    else
        tailleImage = double(tailleImage(:)).';
    end
    radiale = [0 0];
    tangentielle = [0 0];
    obliquite = 0;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'radialdistortion',     radiale = double(varargin{k+1}(:)).';
            case 'tangentialdistortion', tangentielle = double(varargin{k+1}(:)).';
            case 'skew',                 obliquite = varargin{k+1};
            otherwise
                error('vision:cameraIntrinsics:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    K = [focale(1), 0, 0; obliquite, focale(2), 0; ...
         pointPrincipal(1), pointPrincipal(2), 1];
    parametres = struct('FinObj', 'cameraIntrinsics', ...
                        'FocalLength', focale, 'PrincipalPoint', pointPrincipal, ...
                        'ImageSize', tailleImage, 'RadialDistortion', radiale, ...
                        'TangentialDistortion', tangentielle, 'Skew', obliquite, ...
                        'IntrinsicMatrix', K, 'K', K.');
end
