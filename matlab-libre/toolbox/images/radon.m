function [R, xp] = radon(I, theta)
%RADON Transformée de Radon : les projections d'une image.
%   R = RADON(I,THETA) rend, pour chaque angle THETA (en degrés, 0:179 par
%   défaut), la projection de l'image I : la somme de ses valeurs le long
%   des droites perpendiculaires à la direction THETA, comptée dans le sens
%   trigonométrique depuis l'axe des x. R a une colonne par angle.
%   [R,XP] = RADON(...) rend aussi les abscisses radiales, en pixels,
%   comptées depuis le pixel central floor((size(I)+1)/2).
%
%   Comme MATLAB, chaque pixel est partagé en quatre sous-pixels, et chacun
%   répartit sa valeur entre les deux casiers les plus proches de sa
%   projection, au prorata de la distance. Ce partage évite le crénelage
%   d'un simple arrondi, qui fait osciller les projections d'un casier à
%   l'autre aux angles obliques. La somme de chaque projection vaut celle
%   de l'image.
%
%   Exemple :
%      P = phantom(64);
%      [R, xp] = radon(P, 0:179);
%      max(abs(sum(R) - sum(P(:))))    % ~0 : chaque projection garde la masse
%
%   Voir aussi IRADON, PHANTOM, FANBEAM.
    if nargin < 2
        theta = 0:179;
    end
    if ndims(I) > 2 %#ok<ISMAT>
        error('images:radon:invalidImage', 'L''image est une matrice à deux dimensions.');
    end
    I = double(I);
    [m, n] = size(I);
    centre = floor(([m n] + 1) / 2);
    rDernier = ceil(sqrt(sum(([m n] - centre) .^ 2))) + 1;
    rPremier = -rDernier;
    xp = (rPremier:rDernier).';
    nb = numel(xp);
    [colonnes, lignes] = meshgrid(1:n, 1:m);
    nonNuls = I ~= 0;
    v = I(nonNuls) / 4;
    x = colonnes(nonNuls) - centre(2);
    y = centre(1) - lignes(nonNuls);
    R = zeros(nb, numel(theta));
    decalages = [-0.25 -0.25; -0.25 0.25; 0.25 -0.25; 0.25 0.25];
    for k = 1:numel(theta)
        t = theta(k) * pi / 180;
        c = cos(t);
        s = sin(t);
        cumul = zeros(nb, 1);
        for d = 1:4
            r = (x + decalages(d, 1)) * c + (y + decalages(d, 2)) * s - rPremier + 1;
            casier = floor(r);
            w = r - casier;
            cumul = cumul + accumarray(casier, v .* (1 - w), [nb 1]) + ...
                    accumarray(casier + 1, v .* w, [nb 1]);
        end
        R(:, k) = cumul;
    end
end
