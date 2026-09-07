function y = humps(x)
%HUMPS Fonction d'essai à deux pics, utilisée par les démonstrations.
%   Y = HUMPS(X) évalue 1/((x-0.3)^2+0.01) + 1/((x-0.9)^2+0.04) - 6.
%
%   Exemple :
%      humps(0.3)                  % environ 96 : le sommet de la courbe
%      fzero(@humps, [1 2]) > 1        % elle change de signe entre 1 et 2
%
%   Voir aussi PEAKS.
    if nargin < 1
        x = linspace(0, 1, 101);
    end
    y = 1 ./ ((x - 0.3).^2 + 0.01) + 1 ./ ((x - 0.9).^2 + 0.04) - 6;
end
