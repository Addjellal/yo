function m = matlibre_moyenne_exp(serie, periode)
%MATLIBRE_MOYENNE_EXP Moyenne mobile exponentielle.
%   Le poids décroît d'un facteur constant vers le passé ; le facteur est
%   celui qu'emploient les analystes, deux divisé par la période plus un,
%   choisi pour que la durée moyenne de la pondération soit la période.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    serie = double(serie(:));
    alpha = 2 / (periode + 1);
    m = zeros(size(serie));
    if isempty(serie)
        return
    end
    m(1) = serie(1);
    for k = 2:numel(serie)
        m(k) = alpha * serie(k) + (1 - alpha) * m(k - 1);
    end
end
