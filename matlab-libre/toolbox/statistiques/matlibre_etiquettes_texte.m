function texte = matlibre_etiquettes_texte(etiquettes)
%MATLIBRE_ETIQUETTES_TEXTE Étiquettes ramenées à des chaînes.
%   T = MATLIBRE_ETIQUETTES_TEXTE(E) accepte des nombres, un tableau de
%   cellules de chaînes, un tableau de caractères ou un tableau
%   catégoriel, et rend un tableau de cellules de chaînes. Comparer des
%   chaînes traite tous les cas d'un coup.
%
%   Exemple :
%      matlibre_etiquettes_texte([1 2])      % {'1', '2'}
%
%   Voir aussi CONFUSIONMAT.
    if iscategorical(etiquettes)
        texte = cellstr(etiquettes);
    elseif iscell(etiquettes)
        texte = etiquettes;
    elseif ischar(etiquettes)
        texte = cellstr(etiquettes);
    else
        valeurs = double(etiquettes(:));
        texte = cell(numel(valeurs), 1);
        for k = 1:numel(valeurs)
            texte{k} = sprintf('%.17g', valeurs(k));
        end
    end
    texte = texte(:);
end
