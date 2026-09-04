function [Y, E] = matlibre_arima_filtrer(obj, Z, varargin)
%MATLIBRE_ARIMA_FILTRER Passe des innovations réduites dans le modèle.
%   Z porte des innovations d'écart type un : elles sont multipliées par
%   la racine de la variance du modèle avant d'entrer dans la récurrence.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    modele = matlibre_arima_verifier(obj);
    Z = double(Z);
    if size(Z, 1) == 1
        Z = Z.';
    end
    [Y, E] = matlibre_arima_simuler(modele, size(Z, 1), 'Z', ...
                                    sqrt(modele.Variance) * Z, varargin{:});
end
