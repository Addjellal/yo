function etiquettes = watershed(relief, connexite)
%WATERSHED Ligne de partage des eaux.
%   L = WATERSHED(A) inonde le relief A depuis ses minima régionaux : les
%   pixels reçoivent le numéro du bassin qui les a atteints, et ceux où
%   deux bassins se rejoignent restent à zéro — c'est la ligne de
%   partage.
%
%   L'inondation suit l'algorithme de Meyer : on traite les pixels par
%   altitude croissante, en propageant l'étiquette du voisin déjà
%   inondé, et l'on marque la crête quand deux étiquettes se disputent
%   le même pixel.
%
%   Exemple :
%      relief = [1 2 3 2 1];
%      watershed(relief)   % deux bassins séparés par le sommet
    if nargin < 2 || isempty(connexite), connexite = 8; end
    relief = double(relief);
    [h, l] = size(relief);
    decalages = voisinageConnexite(connexite);
    [minima, nombre] = bwlabeln(imregionalmin(relief, connexite), connexite);
    etiquettes = minima;
    % File par altitude : on trie tous les pixels une fois pour toutes.
    [~, ordre] = sort(relief(:));
    aTraiter = ordre(etiquettes(ordre) == 0);
    encore = true;
    while encore
        encore = false;
        restants = [];
        for indice = aTraiter(:)'
            i = mod(indice - 1, h) + 1;
            j = floor((indice - 1) / h) + 1;
            vues = [];
            for k = 1:size(decalages, 1)
                ii = i + decalages(k, 1);
                jj = j + decalages(k, 2);
                if ii >= 1 && ii <= h && jj >= 1 && jj <= l
                    e = etiquettes(ii, jj);
                    if e > 0
                        vues(end + 1) = e;             %#ok<AGROW>
                    end
                end
            end
            vues = unique(vues);
            if isempty(vues)
                restants(end + 1) = indice;            %#ok<AGROW>
            elseif numel(vues) == 1
                etiquettes(i, j) = vues;
                encore = true;
            else
                etiquettes(i, j) = -1;                 % crête
                encore = true;
            end
        end
        if numel(restants) == numel(aTraiter)
            break
        end
        aTraiter = restants;
    end
    etiquettes(etiquettes < 0) = 0;
end
