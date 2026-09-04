function taux = matlibre_taux_variation(serie, periode)
%MATLIBRE_TAUX_VARIATION Variation relative sur un nombre de pas donné.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    serie = double(serie(:));
    taux = zeros(size(serie));
    for k = (periode + 1):numel(serie)
        precedent = serie(k - periode);
        if precedent ~= 0
            taux(k) = 100 * (serie(k) - precedent) / precedent;
        end
    end
end
