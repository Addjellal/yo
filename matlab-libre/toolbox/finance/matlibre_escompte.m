function facteur = matlibre_escompte(taux, annees, composition)
%MATLIBRE_ESCOMPTE Facteur d'actualisation pour une composition donnée.
%   COMPOSITION vaut le nombre de capitalisations par an, ou -1 pour la
%   composition continue.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if composition == -1
        facteur = exp(-taux .* annees);
    elseif composition == 0
        facteur = 1 ./ (1 + taux .* annees);
    else
        facteur = (1 + taux ./ composition) .^ (-composition .* annees);
    end
end
