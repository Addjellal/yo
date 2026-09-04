function indice = matlibre_indice_volume(cloture, volume, depart, sens)
%MATLIBRE_INDICE_VOLUME Indice qui ne suit le cours que certains jours.
%   SENS vaut 1 pour les séances où le volume monte, -1 pour celles où il
%   baisse.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = numel(cloture);
    indice = zeros(n, 1);
    indice(1) = depart;
    for k = 2:n
        variationVolume = volume(k) - volume(k - 1);
        if sens * variationVolume > 0 && cloture(k - 1) ~= 0
            indice(k) = indice(k - 1) * cloture(k) / cloture(k - 1);
        else
            indice(k) = indice(k - 1);
        end
    end
end
