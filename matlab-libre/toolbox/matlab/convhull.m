function [k, aire] = convhull(x, y, varargin)
%CONVHULL Enveloppe convexe d'un nuage de points du plan.
%   K = CONVHULL(X,Y) rend les indices des points de l'enveloppe, dans
%   le sens des aiguilles d'une montre, le premier point étant répété à
%   la fin pour fermer le contour — la convention de MATLAB.
%
%   [K,AIRE] = CONVHULL(...) rend aussi l'aire de l'enveloppe.
%
%   L'algorithme est la chaîne monotone d'Andrew : on trie les points,
%   puis on construit la moitié basse et la moitié haute en retirant
%   chaque sommet qui ferait tourner du mauvais côté.
%
%   Exemple :
%      k = convhull([0 1 1 0 0.5], [0 0 1 1 0.5]);   % le carré
    if nargin == 1
        p = double(x);
        y = p(:, 2);
        x = p(:, 1);
    end
    x = double(x(:));
    y = double(y(:));
    n = numel(x);
    if n < 3
        k = (1:n)';
        if n > 1, k = [k; 1]; end
        aire = 0;
        return
    end
    [~, ordre] = sortrows([x y]);
    bas = zeros(0, 1);
    for indice = ordre(:)'
        while numel(bas) >= 2 && produitVectoriel(x, y, bas(end-1), bas(end), indice) <= 0
            bas(end) = [];
        end
        bas(end + 1, 1) = indice;      %#ok<AGROW>
    end
    haut = zeros(0, 1);
    for indice = flipud(ordre(:))'
        while numel(haut) >= 2 && produitVectoriel(x, y, haut(end-1), haut(end), indice) <= 0
            haut(end) = [];
        end
        haut(end + 1, 1) = indice;     %#ok<AGROW>
    end
    % Les deux chaînes partagent leurs extrémités : on les retire une fois.
    k = [bas(1:end-1); haut(1:end-1); bas(1)];
    if nargout > 1
        aire = polyaire(x(k), y(k));
    end
end

function c = produitVectoriel(x, y, a, b, c0)
%PRODUITVECTORIEL Signe du produit vectoriel des vecteurs AB et AC.
    c = (x(b) - x(a)) * (y(c0) - y(a)) - (y(b) - y(a)) * (x(c0) - x(a));
end

function a = polyaire(x, y)
%POLYAIRE Aire d'un polygone fermé, par la formule du lacet.
    a = abs(sum(x(1:end-1) .* y(2:end) - x(2:end) .* y(1:end-1))) / 2;
end
