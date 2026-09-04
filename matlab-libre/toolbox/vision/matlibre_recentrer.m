function [x, y, couleur] = matlibre_recentrer(C, L, K, x, y, couleur)
%MATLIBRE_RECENTRER Recalcule le centre de chaque région.
%   [X,Y,COULEUR] = MATLIBRE_RECENTRER(C,L,K,X,Y,COULEUR) remplace chaque
%   centre par la moyenne des pixels qui lui sont rattachés — position et
%   couleur. Une région vide garde son centre précédent.
%
%   Exemple :
%      C = zeros(2, 2);
%      [x, y] = matlibre_recentrer(C, ones(2), 1, 1, 1, 0);   % 1.5 1.5
%
%   Voir aussi SUPERPIXELS.
    [h, l, plans] = size(C);
    etiquettes = L(:);
    valides = etiquettes > 0;
    effectifs = accumarray(etiquettes(valides), 1, [K 1]);
    [X, Y] = meshgrid(1:l, 1:h);
    sommeX = accumarray(etiquettes(valides), X(valides), [K 1]);
    sommeY = accumarray(etiquettes(valides), Y(valides), [K 1]);
    peuplees = effectifs > 0;
    x(peuplees) = sommeX(peuplees) ./ effectifs(peuplees);
    y(peuplees) = sommeY(peuplees) ./ effectifs(peuplees);
    for p = 1:plans
        plan = C(:, :, p);
        somme = accumarray(etiquettes(valides), plan(valides), [K 1]);
        couleur(peuplees, p) = somme(peuplees) ./ effectifs(peuplees);
    end
end
