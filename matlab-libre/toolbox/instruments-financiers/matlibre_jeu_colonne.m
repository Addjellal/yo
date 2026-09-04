function [colonne, classe] = matlibre_jeu_colonne(jeu, nom, indices)
%MATLIBRE_JEU_COLONNE Valeurs d'un champ, pour des instruments donnés.
%   Un instrument dont le type ne porte pas le champ reçoit NaN, ou une
%   chaîne vide s'il s'agit d'un champ de texte.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    classe = 'dble';
    largeur = 1;
    for j = 1:numel(jeu.Type)
        rang = find(strcmpi(jeu.FieldName{j}, nom), 1);
        if isempty(rang)
            continue
        end
        classe = jeu.FieldClass{j}{rang};
        if ~strcmp(classe, 'char')
            largeur = max(largeur, size(jeu.FieldData{j}{rang}, 2));
        end
    end
    n = numel(indices);
    if strcmp(classe, 'char')
        colonne = repmat({''}, n, 1);
    else
        colonne = nan(n, largeur);
    end
    for k = 1:n
        [type, rangLocal] = matlibre_jeu_situer(jeu, indices(k));
        if isempty(type)
            continue
        end
        rang = find(strcmpi(jeu.FieldName{type}, nom), 1);
        if isempty(rang)
            continue
        end
        valeur = jeu.FieldData{type}{rang};
        if iscell(valeur)
            colonne{k} = valeur{rangLocal};
        else
            ligne = valeur(rangLocal, :);
            colonne(k, 1:numel(ligne)) = ligne;
        end
    end
end
