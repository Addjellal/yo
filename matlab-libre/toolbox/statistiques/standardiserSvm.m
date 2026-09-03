function [X, centre, echelle] = standardiserSvm(X, actif)
%STANDARDISERSVM Centrage et réduction optionnels des colonnes.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if ~actif
        centre = zeros(1, size(X, 2));
        echelle = ones(1, size(X, 2));
        return;
    end
    centre = mean(X, 1);
    echelle = std(X, 0, 1);
    echelle(echelle == 0) = 1;
    X = (X - repmat(centre, size(X, 1), 1)) ./ repmat(echelle, size(X, 1), 1);
end
