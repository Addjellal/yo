function y = matlibre_arima_cumuler(serie, D, saison)
%MATLIBRE_ARIMA_CUMULER Intègre une série simulée, en partant de zéro.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    y = serie(:);
    for k = 1:D
        y = cumsum(y);
    end
    if saison > 0
        n = numel(y);
        cumule = zeros(n, 1);
        for t = 1:n
            if t <= saison
                cumule(t) = y(t);
            else
                cumule(t) = cumule(t - saison) + y(t);
            end
        end
        y = cumule;
    end
end
