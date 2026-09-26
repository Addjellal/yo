function [temps, valeurs] = matlibre_sl_serie(ts)
%MATLIBRE_SL_SERIE Les instants et les valeurs d'une timeseries, en lignes.
%   [T,V] = MATLIBRE_SL_SERIE(TS) rend les instants de la TIMESERIES TS en
%   colonne, et ses valeurs une ligne par instant : un échantillon
%   matriciel m-par-n s'y déplie en m*n colonnes. C'est la forme que lisent
%   le bloc From Workspace et les entrées externes de SIM.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [t, v] = matlibre_sl_serie(timeseries([1 2; 3 4], [0 1]))  % v = [1 2; 3 4]
%
%   Voir aussi TIMESERIES, SIM.
    temps = double(ts.Time(:));
    valeurs = double(ts.Data);
    n = numel(temps);
    if ts.IsTimeFirst
        if isvector(valeurs) && numel(valeurs) == n
            valeurs = valeurs(:);
        end
        valeurs = reshape(valeurs, n, []);
    else
        valeurs = reshape(valeurs, [], n).';
    end
end
