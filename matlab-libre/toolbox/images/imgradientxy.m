function [gx, gy] = imgradientxy(image, methode)
%IMGRADIENTXY Composantes horizontale et verticale du gradient.
%   [GX,GY] = IMGRADIENTXY(I,METHODE) où METHODE vaut 'sobel' (défaut),
%   'prewitt', 'central' ou 'intermediate'.
%
%   Les conventions sont celles de MATLAB : GX est positif quand
%   l'intensité croît vers la droite, GY quand elle croît vers le bas.
%   Les bords sont répliqués.
%
%   Exemple :
%      [gx, gy] = imgradientxy([1 2 3; 4 5 6; 7 8 9]);
%      gx(2, 2)   % 8, la réponse de Sobel sur une rampe horizontale
%      gy(2, 2)   % 24, la rampe verticale est trois fois plus raide
    if nargin < 2, methode = 'sobel'; end
    x = double(image);
    switch lower(char(methode))
        case 'sobel'
            noyau = [-1 0 1; -2 0 2; -1 0 1];
        case 'prewitt'
            noyau = [-1 0 1; -1 0 1; -1 0 1];
        case 'central'
            noyau = [0 0 0; -0.5 0 0.5; 0 0 0];
        case 'intermediate'
            noyau = [0 0 0; 0 -1 1; 0 0 0];
        otherwise
            error('images:imgradientxy:UnknownMethod', ...
                  'Unrecognized method ''%s''.', methode);
    end
    gx = imfilter(x, noyau, 'replicate');
    gy = imfilter(x, noyau', 'replicate');
end
