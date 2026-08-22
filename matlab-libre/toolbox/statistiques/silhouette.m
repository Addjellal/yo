function s = silhouette(X, etiquettes)
%SILHOUETTE Indice de silhouette de chaque observation.
    n = size(X, 1);
    s = zeros(n, 1);
    classes = unique(etiquettes);
    for i = 1:n
        memeClasse = etiquettes == etiquettes(i);
        memeClasse(i) = false;
        if sum(memeClasse) == 0
            s(i) = 0;
            continue;
        end
        a = moyenneDistance(X, i, memeClasse);
        b = inf;
        for c = 1:numel(classes)
            if classes(c) == etiquettes(i)
                continue;
            end
            autre = etiquettes == classes(c);
            b = min(b, moyenneDistance(X, i, autre));
        end
        s(i) = (b - a) / max(a, b);
    end
end

function d = moyenneDistance(X, i, masque)
    indices = find(masque);
    total = 0;
    for k = 1:numel(indices)
        total = total + sqrt(sum((X(i, :) - X(indices(k), :)) .^ 2));
    end
    d = total / max(numel(indices), 1);
end
