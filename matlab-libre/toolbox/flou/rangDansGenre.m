function indice = rangDansGenre(fis, variable, entree)
%RANGDANSGENRE Rang d'une variable parmi les entrées ou parmi les sorties.
%   Le nom est cherché dans le genre demandé seulement : retirer une
%   entrée ne doit pas atteindre une sortie du même nom.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    variables = variablesDe(fis, entree);
    if isnumeric(variable)
        indice = round(variable);
        if indice < 1 || indice > numel(variables)
            error('fuzzy:rangDansGenre:Rang', 'Variable %d inexistante.', indice);
        end
        return
    end
    nom = char(variable);
    for k = 1:numel(variables)
        if strcmp(variables{k}.nom, nom)
            indice = k;
            return
        end
    end
    if entree
        genre = 'entrée';
    else
        genre = 'sortie';
    end
    error('fuzzy:rangDansGenre:Absente', ...
          'Aucune %s ne s''appelle ''%s''.', genre, nom);
end
