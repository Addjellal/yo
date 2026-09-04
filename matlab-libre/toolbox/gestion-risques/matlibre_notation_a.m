function vues = matlibre_notation_a(instants, dates, notations)
%MATLIBRE_NOTATION_A Notation en vigueur à des instants donnés.
%   La notation est celle de la dernière observation antérieure ou égale ;
%   NaN avant la première.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    vues = nan(1, numel(instants));
    for k = 1:numel(instants)
        garde = find(dates <= instants(k), 1, 'last');
        if ~isempty(garde)
            vues(k) = notations(garde);
        end
    end
end
