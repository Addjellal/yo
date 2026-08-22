function assignation = trackAssign(pistes, mesures, seuil)
%TRACKASSIGN Association mesures / pistes par plus proche voisin global.
    if nargin < 3
        seuil = inf;
    end
    assignation = zeros(size(pistes, 1), 1);
    disponibles = true(size(mesures, 1), 1);
    for k = 1:size(pistes, 1)
        meilleure = 0;
        meilleureDistance = seuil;
        for m = 1:size(mesures, 1)
            if ~disponibles(m)
                continue;
            end
            d = norm(pistes(k, :) - mesures(m, :));
            if d < meilleureDistance
                meilleureDistance = d;
                meilleure = m;
            end
        end
        if meilleure > 0
            assignation(k) = meilleure;
            disponibles(meilleure) = false;
        end
    end
end
