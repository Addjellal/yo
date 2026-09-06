function d = hausdorffDist(A, B)
%HAUSDORFFDIST Distance de Hausdorff entre deux ensembles de points.
%   D = HAUSDORFFDIST(A,B) rend la plus grande des distances qu'un point
%   de l'un doit parcourir pour atteindre le plus proche de l'autre. A et
%   B ont une ligne par point et une colonne par coordonnée.
%
%   La distance est symétrique parce qu'elle prend le maximum des deux
%   sens : sans cela, un contour entièrement contenu dans un autre
%   paraîtrait à distance nulle de lui.
%
%   Là où le Dice mesure un recouvrement global, celle-ci mesure le pire
%   écart local. Deux segmentations peuvent avoir un excellent Dice et une
%   mauvaise distance de Hausdorff : il suffit d'une petite excroissance
%   loin du reste. C'est pourquoi on rapporte les deux.
%
%   Exemple :
%      a = [0 0; 1 0; 0 1];
%      hausdorffDist(a, a)             % 0
%      hausdorffDist(a, a + 0.5)       % le decalage impose
%      hausdorffDist([0 0], [3 4])     % 5
%
%   Voir aussi DICEINDEX, PDIST2.
    d = max(distanceDirigee(A, B), distanceDirigee(B, A));
end

function d = distanceDirigee(A, B)
    d = 0;
    for i = 1:size(A, 1)
        meilleure = inf;
        for j = 1:size(B, 1)
            meilleure = min(meilleure, norm(A(i, :) - B(j, :)));
        end
        d = max(d, meilleure);
    end
end
