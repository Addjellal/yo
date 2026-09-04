function [libres, noms, modele] = matlibre_arima_parametres(obj)
%MATLIBRE_ARIMA_PARAMETRES Liste les paramètres restés à estimer.
%   Un paramètre vaut NaN tant qu'il n'est pas fixé : ce sont ceux-là qui
%   entrent dans l'optimisation. Les autres sont tenus pour connus.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    libres = {};
    noms = {};
    modele = obj;
    if isnan(obj.Constant)
        libres{end+1} = struct('champ', 'Constant', 'indice', 0);
        noms{end+1} = 'Constant';
    end
    listes = {'AR', 'SAR', 'MA', 'SMA'};
    retards = {obj.ARLags, obj.SARLags, obj.MALags, obj.SMALags};
    for k = 1:numel(listes)
        coefficients = obj.(listes{k});
        for j = 1:numel(coefficients)
            if isnan(coefficients{j})
                libres{end+1} = struct('champ', listes{k}, 'indice', j);   %#ok<AGROW>
                noms{end+1} = sprintf('%s{%d}', listes{k}, retards{k}(j)); %#ok<AGROW>
            end
        end
    end
end
