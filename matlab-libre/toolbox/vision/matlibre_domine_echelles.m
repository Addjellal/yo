function domine = matlibre_domine_echelles(scores, couches, k, ligne, colonne, valeur)
%MATLIBRE_DOMINE_ECHELLES Un point est-il le plus fort de son échelle ?
%   D = MATLIBRE_DOMINE_ECHELLES(SCORES,COUCHES,K,LIGNE,COLONNE,VALEUR)
%   compare VALEUR au plus grand score du voisinage de trois sur trois qui
%   lui correspond dans les couches voisines, la position étant transposée
%   d'une échelle à l'autre. C'est cette comparaison qui n'attribue à un
%   coin qu'une seule échelle, la sienne.
%
%   À score égal, le point est gardé dans la couche la plus fine.
%
%   Exemple :
%      s = {ones(4), zeros(2)};
%      matlibre_domine_echelles(s, [1 2], 1, 2, 2, 1)     % vrai
%
%   Voir aussi DETECTBRISKFEATURES.
    domine = true;
    for voisine = [k - 1, k + 1]
        if voisine < 1 || voisine > numel(couches)
            continue
        end
        % À score égal, c'est la couche la plus fine qui garde le point :
        % la comparaison est stricte vers le bas, large vers le haut.
        strict = voisine > k;
        rapport = couches(k) / couches(voisine);
        i = round((ligne - 0.5) * rapport + 0.5);
        j = round((colonne - 0.5) * rapport + 0.5);
        autre = scores{voisine};
        [h, l] = size(autre);
        lignes = max(1, i - 1):min(h, i + 1);
        colonnes = max(1, j - 1):min(l, j + 1);
        if isempty(lignes) || isempty(colonnes)
            continue
        end
        bloc = autre(lignes, colonnes);
        if (strict && max(bloc(:)) > valeur) || (~strict && max(bloc(:)) >= valeur)
            domine = false;
            return
        end
    end
end
