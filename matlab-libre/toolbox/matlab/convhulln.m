function [K, volume] = convhulln(P, options)
%CONVHULLN Enveloppe convexe en dimension quelconque.
%   K = CONVHULLN(P) rend les facettes de l'enveloppe convexe du nuage P,
%   une ligne par facette portant les indices de ses sommets. En dimension
%   deux les facettes sont des segments, en dimension trois des triangles.
%
%   [K,V] = CONVHULLN(...) rend aussi le volume enfermé — l'aire en
%   dimension deux.
%
%   La méthode est celle du cadeau enveloppé (« gift wrapping ») : on
%   part d'une facette du bord, et l'on fait pivoter un hyperplan autour
%   de chacune de ses arêtes jusqu'à rencontrer le point le plus extérieur.
%   Elle est plus lente qu'un balayage incrémental, mais elle ne dépend
%   d'aucun ordre et ne se trompe pas sur les points alignés.
%
%   En dimension deux, CONVHULL est plus rapide et rend un contour fermé
%   plutôt que des segments.
%
%   Exemple :
%      P = [0 0; 1 0; 1 1; 0 1; 0.5 0.5];
%      K = convhulln(P);
%      size(K, 1)                      % 4 cotes : le point du milieu est dedans
%      [~, aire] = convhulln(P);
%      abs(aire - 1) < 1e-12
%
%   Voir aussi CONVHULL, DELAUNAY, DELAUNAYTRIANGULATION, INPOLYGON.
    if nargin > 1, (options); end   %#ok<VUNUS>
    P = double(P);
    [n, d] = size(P);
    if n <= d
        error('MATLAB:convhulln:Points', ...
              'Il faut au moins %d points en dimension %d.', d + 1, d);
    end
    if d == 2
        contour = convhull(P(:, 1), P(:, 2));
        contour = contour(:);
        K = [contour(1:end-1), contour(2:end)];
        if nargout > 1
            volume = abs(polyaire(P(contour(1:end-1), :)));
        end
        return
    end
    if d ~= 3
        error('MATLAB:convhulln:Dimension', ...
              'CONVHULLN traite les dimensions deux et trois.');
    end
    K = matlibre_enveloppe3d(P);
    if nargout > 1
        % Le volume est la somme des tetraedres formes par chaque facette
        % et un point de reference : ceux qui debordent se compensent.
        origine = mean(P, 1);
        volume = 0;
        for f = 1:size(K, 1)
            a = P(K(f, 1), :) - origine;
            b = P(K(f, 2), :) - origine;
            c = P(K(f, 3), :) - origine;
            volume = volume + abs(dot(a, cross(b, c))) / 6;
        end
    end
end

function a = polyaire(sommets)
% L'aire signee par la formule du lacet.
    x = sommets(:, 1); y = sommets(:, 2);
    a = sum(x .* y([2:end 1]) - x([2:end 1]) .* y) / 2;
end
