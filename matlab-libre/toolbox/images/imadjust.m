function y = imadjust(x, entree, sortie, gamma)
%IMADJUST Étirement de contraste.
%   Y = IMADJUST(X,[BAS HAUT],[NBAS NHAUT],GAMMA) applique la transformation
%   affine par morceaux suivie de la correction gamma.
%
%   Exemple :
%      x = [0.2 0.5 0.8];
%      y = imadjust(x, [0.2 0.8], [0 1]);
%      [y(1) y(end)]               % 0 et 1 : les bornes s'etirent
    x = im2double(x);
    if nargin < 2 || isempty(entree)
        entree = [min(x(:)), max(x(:))];
    end
    if nargin < 3 || isempty(sortie)
        sortie = [0 1];
    end
    if nargin < 4 || isempty(gamma)
        gamma = 1;
    end
    d = max(entree(2) - entree(1), eps);
    y = (x - entree(1)) / d;
    y = max(0, min(1, y)) .^ gamma;
    y = sortie(1) + y * (sortie(2) - sortie(1));
end
