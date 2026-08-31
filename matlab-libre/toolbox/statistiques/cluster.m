function T = cluster(Z, critere, valeur)
%CLUSTER Coupe un arbre de regroupement en groupes.
%   T = CLUSTER(Z,'maxclust',K) coupe l'arbre Z — celui que rend
%   LINKAGE — de façon à obtenir au plus K groupes, et rend un vecteur
%   qui donne, pour chaque observation, le numéro de son groupe. La
%   coupure se fait à la plus petite hauteur qui laisse K groupes : on
%   défait simplement les K-1 dernières fusions.
%
%   T = CLUSTER(Z,'cutoff',C) coupe à la hauteur C : deux observations
%   sont dans le même groupe si elles ont été réunies en dessous de C.
%
%   T = CLUSTER(Z,'cutoff',C,'criterion','distance') est la même chose,
%   écrite comme dans MATLAB.
%
%   Les groupes sont numérotés dans l'ordre où leur première observation
%   apparaît, de sorte que T(1) vaut toujours 1.
%
%   Exemples :
%      X = [1 1; 1.2 1; 5 5; 5.1 5.2];
%      Z = linkage(X);
%      cluster(Z, 'maxclust', 2)     % [1;1;2;2]
%      cluster(Z, 'cutoff', 1)       % la meme coupure, par la hauteur
%
%   Voir aussi LINKAGE, CLUSTERDATA, DENDROGRAM, COPHENET, KMEANS.
    critere = lower(char(critere));
    n = size(Z, 1) + 1;
    if strcmp(critere, 'maxclust')
        k = valeur;
        if k < 1
            error('stats:cluster:BadMaxclust', 'MAXCLUST must be at least 1.');
        end
        k = min(k, n);
        fusions = n - k;
    elseif strcmp(critere, 'cutoff') || strcmp(critere, 'distance')
        fusions = sum(Z(:, 3) <= valeur);
    else
        error('stats:cluster:BadCriterion', ...
              'The criterion must be ''maxclust'' or ''cutoff''.');
    end

    % On refait les fusions retenues, en suivant qui appartient à qui.
    membres = cell(n + fusions, 1);
    for i = 1:n
        membres{i} = i;
    end
    vivant = true(n + fusions, 1);
    for m = 1:fusions
        a = Z(m, 1);
        b = Z(m, 2);
        membres{n + m} = [membres{a}, membres{b}];
        vivant(a) = false;
        vivant(b) = false;
        vivant(n + m) = true;
    end
    T = zeros(n, 1);
    numero = 0;
    for i = 1:n
        if T(i) ~= 0
            continue;
        end
        numero = numero + 1;
        for g = 1:n + fusions
            if vivant(g) && any(membres{g} == i)
                T(membres{g}) = numero;
                break;
            end
        end
    end
end
