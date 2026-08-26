function [X, Y, Z] = peaks(n)
%PEAKS Surface d'essai à trois bosses et trois creux.
%   Z = PEAKS(N) évalue la fonction sur une grille N x N de [-3,3]^2.
%   [X,Y,Z] = PEAKS(N) rend aussi la grille.
%
%   La formule est celle de la documentation :
%      z = 3(1-x)^2 e^{-x^2-(y+1)^2} - 10(x/5 - x^3 - y^5) e^{-x^2-y^2}
%          - 1/3 e^{-(x+1)^2 - y^2}
    if nargin < 1
        n = 49;
    end
    t = linspace(-3, 3, n);
    [x, y] = meshgrid(t, t);
    z = 3 * (1 - x).^2 .* exp(-x.^2 - (y + 1).^2) ...
        - 10 * (x/5 - x.^3 - y.^5) .* exp(-x.^2 - y.^2) ...
        - 1/3 * exp(-(x + 1).^2 - y.^2);
    if nargout <= 1
        X = z;
    else
        X = x;
        Y = y;
        Z = z;
    end
end
