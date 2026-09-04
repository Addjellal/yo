function [puissances, noms] = matlibre_termes_surface(degreX, degreY)
%MATLIBRE_TERMES_SURFACE Termes d'un polynôme à deux variables.
%   [P,N] = MATLIBRE_TERMES_SURFACE(DEGREX,DEGREY) rend les couples
%   d'exposants et les noms des coefficients, dans l'ordre de MATLAB :
%   par degré total croissant, et à degré total égal, par puissance de x
%   décroissante.
%
%   Exemple :
%      [p, n] = matlibre_termes_surface(2, 2);
%      n      % p00 p10 p01 p20 p11 p02
%
%   Voir aussi MATLIBRE_MODELE_SURFACE.
    maximum = max(degreX, degreY);
    puissances = zeros(0, 2);
    noms = {};
    for total = 0:maximum
        for a = min(total, degreX):-1:0
            b = total - a;
            if b < 0 || b > degreY
                continue
            end
            puissances(end + 1, :) = [a, b];        %#ok<AGROW>
            noms{end + 1} = sprintf('p%d%d', a, b); %#ok<AGROW>
        end
    end
end
