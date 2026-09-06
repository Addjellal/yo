function s = silhouette(X, etiquettes)
%SILHOUETTE Indice de silhouette de chaque observation.
%   S = SILHOUETTE(X,ETIQUETTES) rend, pour chaque observation, l'indice
%   (b-a)/max(a,b) où a est sa distance moyenne aux membres de sa propre
%   classe et b sa distance moyenne aux membres de la classe étrangère la
%   plus proche.
%
%   L'indice vit dans [-1,1]. Proche de un, l'observation est bien plus
%   près des siens que de tout autre groupe ; proche de zéro, elle est
%   à la frontière ; négatif, elle est plus près d'un autre groupe que du
%   sien — elle est mal classée. Une observation seule dans sa classe rend
%   zéro, faute de a définissable.
%
%   La moyenne des indices sert à choisir le nombre de groupes : on relance
%   la classification pour plusieurs valeurs de K et on retient celle qui
%   la maximise. C'est un critère purement géométrique, qui ne dit rien de
%   la pertinence des groupes trouvés ; il favorise les groupes compacts et
%   sphériques, ce qui le rend injuste envers un groupe allongé.
%
%   Exemple :
%      X = [randn(20, 2); randn(20, 2) + 5];
%      s = silhouette(X, [ones(20, 1); 2 * ones(20, 1)]);
%      mean(s)
%
%   Voir aussi KMEANS, PDIST, LINKAGE, EVALCLUSTERS.
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
