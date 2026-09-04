function L = matlibre_rattacher_orphelins(L, orphelins, centresX, centresY)
%MATLIBRE_RATTACHER_ORPHELINS Donne une région aux pixels laissés de côté.
%   L = MATLIBRE_RATTACHER_ORPHELINS(L,ORPHELINS,X,Y) attribue à chaque
%   pixel non étiqueté le centre spatialement le plus proche. Cela arrive
%   quand aucune fenêtre de recherche ne l'a couvert.
%
%   Exemple :
%      L = matlibre_rattacher_orphelins(zeros(2), true(2), 1, 1);
%
%   Voir aussi SUPERPIXELS.
    indices = find(orphelins);
    if isempty(indices)
        return
    end
    [lignes, colonnes] = ind2sub(size(L), indices);
    for k = 1:numel(indices)
        distances = (centresX - colonnes(k)) .^ 2 + (centresY - lignes(k)) .^ 2;
        [~, meilleur] = min(distances);
        L(indices(k)) = meilleur;
    end
end
