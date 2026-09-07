function liste = matlibre_dict_valeurs(valeurs)
%MATLIBRE_DICT_VALEURS Normalise des valeurs de dictionnaire en cellule.
%   Une valeur peut être n'importe quoi ; ce qui compte est de savoir si
%   l'appelant en donne une ou plusieurs. Un tableau numérique en donne
%   autant qu'il a d'éléments, une cellule autant qu'elle a de cases, et
%   tout le reste compte pour une seule.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      numel(matlibre_dict_valeurs([1 2 3]))     % 3
%      numel(matlibre_dict_valeurs({[1 2]}))     % 1
%
%   Voir aussi DICTIONARY, VALUES, INSERT.
    if iscell(valeurs)
        liste = valeurs(:);
    elseif isnumeric(valeurs) || islogical(valeurs)
        liste = num2cell(valeurs(:));
    elseif isstring(valeurs)
        liste = cellstr(valeurs(:));
    else
        liste = {valeurs};
    end
end
