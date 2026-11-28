function [statistique, coefficients] = matlibre_dickey_fuller(serie, retards, modele, forme, deterministe)
%MATLIBRE_DICKEY_FULLER Régression de Dickey-Fuller augmentée.
%   Régresse la différence de SERIE sur son niveau retardé, sur RETARDS
%   différences retardées et sur les termes déterministes du MODELE.
%   FORME vaut 't1' pour le rapport de Student du coefficient du niveau,
%   't2' pour le coefficient normalisé T*a/(1-somme des gamma).
%
%   DETERMINISTE, facultatif, remplace les termes du modèle par des
%   colonnes données : c'est ce dont EGCITEST a besoin, les résidus d'une
%   régression de cointégration n'ayant plus de constante à estimer.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    serie = double(serie(:));
    differences = diff(serie);
    n = numel(differences);
    lignes = (retards + 1):n;
    T = numel(lignes);
    if T <= retards + 3
        error('econ:dickey:Observations', ...
              'The series is too short for %d lags.', retards);
    end
    y = differences(lignes);
    niveau = serie(lignes);                % y_{t-1}, car differences(k) = y(k+1)-y(k)
    if nargin >= 5
        colonnes = deterministe(lignes, :);
    else
        switch lower(modele)
            case 'ar',  colonnes = zeros(T, 0);
            case 'ard', colonnes = ones(T, 1);
            case 'ts',  colonnes = [ones(T, 1), (lignes(:) + 1)];
            otherwise
                error('econ:dickey:Modele', ...
                      'Model must be ''AR'', ''ARD'', or ''TS''.');
        end
    end
    X = [niveau, colonnes];
    for j = 1:retards
        X = [X, differences(lignes - j)];   %#ok<AGROW>
    end
    coefficients = X \ y;
    residus = y - X * coefficients;
    liberte = T - size(X, 2);
    variance = sum(residus .^ 2) / max(liberte, 1);
    covariance = variance * inv(X.' * X);   %#ok<MINV>
    switch lower(forme)
        case 't1'
            statistique = coefficients(1) / sqrt(covariance(1, 1));
        case 't2'
            somme = sum(coefficients((end - retards + 1):end));
            if retards == 0
                somme = 0;
            end
            statistique = T * coefficients(1) / (1 - somme);
        otherwise
            error('econ:dickey:Forme', ...
                  'Test must be ''t1'' or ''t2'', not ''%s''.', forme);
    end
end
