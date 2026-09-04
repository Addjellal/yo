function [innovations, variances, logL] = matlibre_arima_inferer(obj, y)
%MATLIBRE_ARIMA_INFERER Innovations et vraisemblance d'une série observée.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    modele = matlibre_arima_verifier(obj);
    [phi, theta] = matlibre_arima_polynomes(modele);
    y = double(y);
    if size(y, 1) == 1
        y = y.';
    end
    chemins = size(y, 2);
    innovations = [];
    for c = 1:chemins
        serie = matlibre_arima_differencier(y(:, c), modele.D, modele.Seasonality);
        colonne = matlibre_arima_residus(serie, modele.Constant, phi, theta);
        if isempty(innovations)
            innovations = zeros(numel(colonne), chemins);
        end
        innovations(:, c) = colonne;   %#ok<AGROW>
    end
    variances = modele.Variance * ones(size(innovations));
    T = size(innovations, 1);
    logL = -0.5 * T * log(2 * pi * modele.Variance) * ones(1, chemins) - ...
            sum(innovations .^ 2, 1) / (2 * modele.Variance);
    if chemins == 1
        logL = logL(1);
    end
end
