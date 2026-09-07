function [entree, indice] = trouverVariable(fis, nom)
%TROUVERVARIABLE Repère une variable par son nom, entrée ou sortie.
%   Le nom peut aussi être le rang, auquel cas on cherche d'abord parmi
%   les entrées puis parmi les sorties, comme le fait MATLAB.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      fis = mamfis('Name', 'pilote');
%      fis = addInput(fis, [0 10], 'Name', 'erreur');
%      fis = addMF(fis, 'erreur', 'trimf', [0 0 5], 'Name', 'petite');
%      fis = addMF(fis, 'erreur', 'trimf', [5 10 10], 'Name', 'grande');
%      fis = addOutput(fis, [0 1], 'Name', 'commande');
%      fis = addMF(fis, 'commande', 'trimf', [0 0 0.5], 'Name', 'faible');
%      fis = addMF(fis, 'commande', 'trimf', [0.5 1 1], 'Name', 'forte');
%      [entree, indice] = trouverVariable(fis, 'erreur');
%      [entree indice]             % 1 1
%
%   Voir aussi RANGDANSGENRE, VARIABLESDE, GETFIS.
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
