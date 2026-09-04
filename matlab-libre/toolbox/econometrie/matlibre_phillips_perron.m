function [statistique, coefficients] = matlibre_phillips_perron(serie, retards, modele, forme, deterministe)
%MATLIBRE_PHILLIPS_PERRON Régression de racine unitaire, corrigée.
%   Même régression que Dickey-Fuller mais sans différences retardées :
%   l'autocorrélation des résidus est traitée après coup, en remplaçant
%   la variance instantanée par une variance de long terme.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    serie = double(serie(:));
    y = serie(2:end);
    niveau = serie(1:end-1);
    T = numel(y);
    if nargin >= 5
        colonnes = deterministe(2:end, :);
    else
        switch lower(modele)
            case 'ar',  colonnes = zeros(T, 0);
            case 'ard', colonnes = ones(T, 1);
            case 'ts',  colonnes = [ones(T, 1), (2:(T + 1)).'];
            otherwise
                error('econ:pp:Modele', ...
                      'Le modèle doit être ''AR'', ''ARD'' ou ''TS''.');
        end
    end
    X = [niveau, colonnes];
    coefficients = X \ (y - niveau);        % régression sur la différence
    residus = (y - niveau) - X * coefficients;
    variance = sum(residus .^ 2) / max(T - size(X, 2), 1);
    covariance = variance * inv(X.' * X);   %#ok<MINV>
    ecartType = sqrt(covariance(1, 1));
    if retards < 1
        retards = max(1, floor(4 * (T / 100) ^ 0.25));
    end
    sigmaCourt = sum(residus .^ 2) / T;
    sigmaLong = matlibre_newey_west(residus, retards);
    switch lower(forme)
        case 't1'
            tBrut = coefficients(1) / ecartType;
            statistique = sqrt(sigmaCourt / sigmaLong) * tBrut - ...
                (sigmaLong - sigmaCourt) * T * ecartType / ...
                (2 * sigmaLong * sqrt(sigmaCourt));
        case 't2'
            statistique = T * coefficients(1) - ...
                (sigmaLong - sigmaCourt) * T ^ 2 * ecartType ^ 2 / (2 * variance);
        otherwise
            error('econ:pp:Forme', ...
                  'La forme du test vaut ''t1'' ou ''t2'', pas ''%s''.', forme);
    end
end
