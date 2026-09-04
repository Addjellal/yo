function [libres, noms] = matlibre_garch_parametres(obj)
%MATLIBRE_GARCH_PARAMETRES Liste les paramètres restés à estimer.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    libres = {};
    noms = {};
    if isnan(obj.Constant)
        libres{end+1} = struct('champ', 'Constant', 'indice', 0);
        noms{end+1} = 'Constant';
    end
    listes = {'GARCH', 'ARCH'};
    retards = {obj.GARCHLags, obj.ARCHLags};
    for k = 1:numel(listes)
        coefficients = obj.(listes{k});
        for j = 1:numel(coefficients)
            if isnan(coefficients{j})
                libres{end+1} = struct('champ', listes{k}, 'indice', j);    %#ok<AGROW>
                noms{end+1} = sprintf('%s{%d}', listes{k}, retards{k}(j));  %#ok<AGROW>
            end
        end
    end
end
