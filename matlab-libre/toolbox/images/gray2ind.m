function [indices, carte] = gray2ind(image, n)
%GRAY2IND Image en niveaux de gris vers image indexée.
%   [X,MAP] = GRAY2IND(I,N) quantifie I sur N niveaux ; N vaut 64 par
%   défaut. Les indices commencent à zéro, comme dans MATLAB pour les
%   entiers non signés.
%
%   Exemple :
%      [x, map] = gray2ind([0 0.5 1], 4);   % x = [0 1 3]
    if nargin < 2 || isempty(n), n = 64; end
    image = im2double(image);
    indices = round(image * (n - 1));
    indices = max(0, min(n - 1, indices));
    carte = gray(n);
end
