function [prix, parametres] = matlibre_options_actions(courbe, actif, reglement, echeance, typeOption, exercice)
%MATLIBRE_OPTIONS_ACTIONS Prix et paramètres d'options sur action.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if ischar(typeOption) || isstring(typeOption)
        typeOption = {char(typeOption)};
    end
    exercice = double(exercice(:));
    echeance = matlibre_dates(echeance);
    echeance = echeance(:);
    nombre = max([numel(typeOption), numel(exercice), numel(echeance)]);
    prix = zeros(nombre, 1);
    parametres = cell(nombre, 1);
    for k = 1:nombre
        genre = lower(char(typeOption{min(k, numel(typeOption))}));
        K = exercice(min(k, numel(exercice)));
        fin = echeance(min(k, numel(echeance)));
        [S, r, T, sigma, q] = matlibre_bls_parametres(courbe, actif, reglement, fin);
        [c, p] = matlibre_bls_general(S, K, r, r - q, T, sigma);
        if strcmp(genre, 'put')
            prix(k) = p;
        else
            prix(k) = c;
        end
        parametres{k} = struct('S', S, 'K', K, 'r', r, 'T', T, 'sigma', sigma, ...
                               'q', q, 'type', genre);
    end
end
