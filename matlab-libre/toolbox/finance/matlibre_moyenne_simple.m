function m = matlibre_moyenne_simple(serie, periode)
%MATLIBRE_MOYENNE_SIMPLE Moyenne mobile arithmétique.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    serie = double(serie(:));
    m = zeros(size(serie));
    for k = 1:numel(serie)
        m(k) = mean(serie(max(1, k - periode + 1):k));
    end
end
