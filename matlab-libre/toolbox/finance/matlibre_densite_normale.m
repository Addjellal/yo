function y = matlibre_densite_normale(x)
%MATLIBRE_DENSITE_NORMALE Densité de la loi normale centrée réduite.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    y = exp(-x .^ 2 / 2) / sqrt(2 * pi);
end
