function [k, aire] = boundary(x, y, s)
%BOUNDARY Contour d'un nuage de points, plus ou moins serré.
%   K = BOUNDARY(X,Y) rend les indices des points du contour, le premier
%   répété à la fin. K = BOUNDARY(X,Y,S) règle le serrage : S = 0 donne
%   l'enveloppe convexe, S = 1 le contour le plus serré qui enferme encore
%   tous les points. Par défaut S vaut 0,5.
%   K = BOUNDARY(P,...) où P a deux colonnes fait la même chose.
%
%   [K,A] = BOUNDARY(...) rend aussi l'aire enfermée.
%
%   Le contour est celui d'une forme alpha : on triangule les points,
%   puis on retire les triangles trop étirés — ceux dont le cercle
%   circonscrit est plus grand qu'un seuil —, et le bord de ce qui reste
%   est le contour. Le seuil vient de S : à S = 0 il est infini, donc
%   aucun triangle ne part et le bord est l'enveloppe convexe ; plus S
%   monte, plus le contour épouse le nuage et peut y creuser des baies.
%
%   Exemple :
%      t = linspace(0, 2*pi, 41)'; t(end) = [];
%      x = cos(t); y = sin(t);
%      k = boundary(x, y, 0);
%      isequal(unique(k), unique(convhull(x, y)))   % a zero, c'est l'enveloppe
%      [~, a] = boundary(x, y, 0);
%      abs(a - polyarea(x, y)) < 1e-12
%
%   Voir aussi ALPHASHAPE, CONVHULL, DELAUNAY, POLYAREA.
    if nargin < 2 || (nargin >= 2 && ~isscalar(y) && numel(y) ~= numel(x))
        error('MATLAB:boundary:Arguments', 'BOUNDARY attend X et Y.');
    end
    if nargin >= 2 && isscalar(y) && size(x, 2) == 2
        s = y;
        y = x(:, 2);
        x = x(:, 1);
    elseif nargin == 1 || (nargin >= 1 && size(x, 2) == 2 && nargin < 2)
        y = x(:, 2);
        x = x(:, 1);
    end
    if nargin < 3, s = 0.5; end
    x = double(x(:));
    y = double(y(:));
    s = max(0, min(1, double(s)));

    k = matlibre_forme_alpha(x, y, matlibre_seuil_alpha(x, y, s));
    if nargout > 1
        if numel(k) < 4
            aire = 0;
        else
            sommets = k(1:end-1);
            aire = abs(sum(x(sommets) .* y(sommets([2:end 1])) - ...
                           x(sommets([2:end 1])) .* y(sommets)) / 2);
        end
    end
end
