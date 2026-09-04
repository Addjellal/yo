function somme = matlibre_carres_residuels(y, X)
%MATLIBRE_CARRES_RESIDUELS Somme des carrés des résidus d'une régression.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isempty(X)
        somme = sum(y .^ 2);
    else
        somme = sum((y - X * (X \ y)) .^ 2);
    end
end
