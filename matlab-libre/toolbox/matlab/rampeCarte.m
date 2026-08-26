function g = rampeCarte(m)
%RAMPECARTE Rampe de 0 à 1 sur M points, colonne.
%   Pour M = 1 la rampe vaut zéro, comme dans MATLAB.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    m = round(m);
    if m <= 1
        g = zeros(max(m, 0), 1);
        return
    end
    g = (0:m-1)' / (m - 1);
end
