function [serie, memoire] = matlibre_arima_differencier(y, D, saison)
%MATLIBRE_ARIMA_DIFFERENCIER Applique les différences ordinaire et saisonnière.
%   MEMOIRE garde les valeurs qu'il faut pour revenir aux niveaux.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    y = y(:);
    memoire = struct('D', D, 'saison', saison, 'etapes', {{}});
    serie = y;
    if saison > 0
        if numel(serie) <= saison
            error('econ:arima:Saison', ...
                  'La série est trop courte pour une différence saisonnière.');
        end
        memoire.etapes{end+1} = struct('type', 'saison', 'periode', saison, ...
                                       'debut', serie(1:saison));
        serie = serie((saison + 1):end) - serie(1:(end - saison));
    end
    for k = 1:D
        memoire.etapes{end+1} = struct('type', 'simple', 'periode', 1, ...
                                       'debut', serie(1));
        serie = diff(serie);
    end
end
