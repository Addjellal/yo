function reduits = voxelDownsample(points, taille)
%VOXELDOWNSAMPLE Un point par cellule de la grille, au barycentre.
    cles = floor(points / taille);
    vus = [];
    reduits = [];
    for k = 1:size(points, 1)
        c = cles(k, :);
        trouve = false;
        for j = 1:size(vus, 1)
            if all(vus(j, :) == c)
                trouve = true;
                break;
            end
        end
        if ~trouve
            vus(end+1, :) = c;
            membres = true(size(points, 1), 1);
            for d = 1:size(points, 2)
                membres = membres & (cles(:, d) == c(d));
            end
            reduits(end+1, :) = mean(points(membres, :), 1);
        end
    end
end
