function d = hausdorffDist(A, B)
%HAUSDORFFDIST Distance de Hausdorff entre deux ensembles de points.
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
