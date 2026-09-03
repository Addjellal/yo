function [entree, indice] = trouverVariable(fis, nom)
%TROUVERVARIABLE Repère une variable par son nom, entrée ou sortie.
%   Le nom peut aussi être le rang, auquel cas on cherche d'abord parmi
%   les entrées puis parmi les sorties, comme le fait MATLAB.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isnumeric(nom)
        indice = round(nom);
        if indice <= numel(fis.entrees)
            entree = true;
        else
            entree = false;
            indice = indice - numel(fis.entrees);
        end
        return
    end
    nom = char(nom);
    for k = 1:numel(fis.entrees)
        if strcmp(fis.entrees{k}.nom, nom)
            entree = true;
            indice = k;
            return
        end
    end
    for k = 1:numel(fis.sorties)
        if strcmp(fis.sorties{k}.nom, nom)
            entree = false;
            indice = k;
            return
        end
    end
    error('fuzzy:trouverVariable:Absente', ...
          'Aucune variable ne s''appelle ''%s''.', nom);
end
