function lignes = matlibre_textes_cellules(texte, nombre)
%MATLIBRE_TEXTES_CELLULES Normalise l'argument texte des annotations.
%   L = MATLIBRE_TEXTES_CELLULES(TEXTE,N) rend un tableau de cellules de N
%   chaînes. TEXTE peut être une chaîne — répétée —, un tableau de
%   cellules, un vecteur de nombres, ou un tableau de caractères dont
%   chaque ligne est une étiquette.
%
%   Exemple :
%      matlibre_textes_cellules([1 2], 2)   % {'1', '2'}
%
%   Voir aussi INSERTTEXT, INSERTOBJECTANNOTATION.
    if iscell(texte)
        lignes = cell(1, numel(texte));
        for k = 1:numel(texte)
            lignes{k} = char(texte{k});
        end
    elseif ischar(texte)
        if size(texte, 1) > 1
            lignes = cell(1, size(texte, 1));
            for k = 1:size(texte, 1)
                lignes{k} = deblank(texte(k, :));
            end
        else
            lignes = {texte};
        end
    else
        valeurs = double(texte(:));
        lignes = cell(1, numel(valeurs));
        for k = 1:numel(valeurs)
            if valeurs(k) == round(valeurs(k))
                lignes{k} = sprintf('%d', valeurs(k));
            else
                lignes{k} = sprintf('%.4g', valeurs(k));
            end
        end
    end
    if numel(lignes) == 1 && nombre > 1
        lignes = repmat(lignes, 1, nombre);
    end
end
