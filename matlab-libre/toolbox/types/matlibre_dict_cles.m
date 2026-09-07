function [liste, textuelles] = matlibre_dict_cles(cles)
%MATLIBRE_DICT_CLES Normalise des clés de dictionnaire en cellule.
%   Les clés arrivent sous toutes les formes du texte ou en numérique ;
%   cette fonction les ramène à une cellule et dit si elles sont
%   textuelles, ce dont le dictionnaire a besoin pour refuser un mélange.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [l, t] = matlibre_dict_cles(["a", "b"]);
%      numel(l)                        % 2
%      t                               % 1 : elles sont textuelles
%
%   Voir aussi DICTIONARY, KEYS, ISKEY.
    if isnumeric(cles) || islogical(cles)
        textuelles = false;
        liste = num2cell(double(cles(:)));
    else
        textuelles = true;
        liste = cellstr(cles);
        liste = liste(:);
    end
end
