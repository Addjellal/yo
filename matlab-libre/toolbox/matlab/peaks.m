function [X, Y, Z] = peaks(a, b)
%PEAKS Surface d'essai à trois bosses et trois creux.
%   Z = PEAKS rend la surface sur une grille 49 x 49 de [-3,3]^2.
%   Z = PEAKS(N) évalue la fonction sur une grille N x N de [-3,3]^2.
%   Z = PEAKS(V) utilise la grille MESHGRID(V,V), V étant un vecteur.
%   Z = PEAKS(X,Y) évalue la fonction aux points donnés ; X et Y doivent
%   avoir la même taille.
%   [X,Y,Z] = PEAKS(...) rend aussi la grille.
%
%   La formule est celle de la documentation :
%      z = 3(1-x)^2 e^{-x^2-(y+1)^2} - 10(x/5 - x^3 - y^5) e^{-x^2-y^2}
%          - 1/3 e^{-(x+1)^2 - y^2}
    if nargin == 0
        a = 49;
    end
    if nargin < 2
        % PEAKS(N) sur un scalaire, PEAKS(V) sur un vecteur : dans les
        % deux cas on fabrique la grille, comme le fait MATLAB.
        if isscalar(a)
            t = linspace(-3, 3, a);
        else
            t = a;
        end
        [x, y] = meshgrid(t, t);
    else
        x = a;
        y = b;
        if ~isequal(size(x), size(y))
            error('MATLAB:peaks:sizeMismatch', ...
                  'X and Y must be the same size.');
        end
    end
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
