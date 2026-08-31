function [indices, noms] = grp2idx(groupe)
%GRP2IDX Numérote les modalités d'une variable de groupe.
%   [G,NOMS] = GRP2IDX(GROUPE) transforme une variable de groupe — un
%   vecteur de nombres, un tableau de cellules de chaînes, une matrice de
%   caractères — en indices entiers 1, 2, 3… G(i) donne le numéro du
%   groupe de la i-ème observation, et NOMS{G(i)} son nom d'origine.
%
%   L'ordre est celui du tri : pour des nombres, l'ordre croissant ; pour
%   des noms, l'ordre alphabétique. Deux appels sur les mêmes données
%   donnent donc toujours la même numérotation.
%
%   C'est la brique dont se servent les fonctions qui regroupent —
%   GRPSTATS, ANOVA1, BOXPLOT — pour ne pas avoir à traiter chaque forme
%   de variable de groupe séparément.
%
%   Une observation manquante — NaN, ou la chaîne vide — reçoit l'indice
%   NaN et n'ouvre pas de groupe.
%
%   Exemples :
%      [g, noms] = grp2idx({'b', 'a', 'b'})
%      % g = [2; 1; 2], noms = {'a'; 'b'}
%
%      [g, noms] = grp2idx([10 20 10 30])
%      % g = [1; 2; 1; 3], noms = {'10'; '20'; '30'}
%
%   Voir aussi GRPSTATS, ANOVA1, UNIQUE, CROSSTAB, TABULATE.
    if ischar(groupe) && ~isvector(groupe)
        % Une matrice de caractères : une ligne par observation.
        cellules = cell(size(groupe, 1), 1);
        for i = 1:size(groupe, 1)
            cellules{i} = strtrim(groupe(i, :));
        end
        groupe = cellules;
    elseif ischar(groupe)
        groupe = {groupe};
    elseif isstring(groupe)
        groupe = cellstr(groupe);
    end

    if iscell(groupe)
        groupe = groupe(:);
        n = numel(groupe);
        present = true(n, 1);
        for i = 1:n
            present(i) = ~isempty(groupe{i});
        end
        distincts = unique(groupe(present));
        distincts = distincts(:);
        indices = NaN(n, 1);
        for i = 1:n
            if present(i)
                for k = 1:numel(distincts)
                    if strcmp(groupe{i}, distincts{k})
                        indices(i) = k;
                        break;
                    end
                end
            end
        end
        noms = distincts;
        return;
    end

    groupe = groupe(:);
    n = numel(groupe);
    present = ~isnan(groupe);
    distincts = unique(groupe(present));
    distincts = distincts(:);
    indices = NaN(n, 1);
    for k = 1:numel(distincts)
        indices(groupe == distincts(k)) = k;
    end
    noms = cell(numel(distincts), 1);
    for k = 1:numel(distincts)
        noms{k} = num2str(distincts(k));
    end
end
