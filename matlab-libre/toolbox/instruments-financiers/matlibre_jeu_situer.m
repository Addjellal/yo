function [type, rang] = matlibre_jeu_situer(jeu, indice)
%MATLIBRE_JEU_SITUER Type et rang local d'un instrument, d'après son numéro.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    type = [];
    rang = [];
    for j = 1:numel(jeu.Type)
        position = find(jeu.Index{j} == indice, 1);
        if ~isempty(position)
            type = j;
            rang = position;
            return
        end
    end
end
