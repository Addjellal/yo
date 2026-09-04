function valeur = matlibre_arima_logl(obj, libres, parametres, variance, serie)
%MATLIBRE_ARIMA_LOGL Log-vraisemblance conditionnelle, variance comprise.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if variance <= 0
        valeur = -1e12;
        return
    end
    modele = matlibre_arima_poser(obj, libres, parametres);
    [phi, theta] = matlibre_arima_polynomes(modele);
    innovations = matlibre_arima_residus(serie, modele.Constant, phi, theta);
    T = numel(serie);
    valeur = -0.5 * T * log(2 * pi * variance) - ...
              sum(innovations .^ 2) / (2 * variance);
    if ~isfinite(valeur)
        valeur = -1e12;
    end
end
