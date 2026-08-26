function P = creditTransition(notations)
%CREDITTRANSITION Matrice de transition estimée sur des trajectoires.
%   P = CREDITTRANSITION(N) où N est une matrice dont chaque ligne est la
%   trajectoire de notation d'un émetteur.
    etats = unique(notations(:));
    k = numel(etats);
    compte = zeros(k, k);
    for i = 1:size(notations, 1)
        for t = 1:size(notations, 2) - 1
            a = find(etats == notations(i, t));
            b = find(etats == notations(i, t + 1));
            compte(a, b) = compte(a, b) + 1;
        end
    end
    P = zeros(k, k);
    for i = 1:k
        total = sum(compte(i, :));
        if total > 0
            P(i, :) = compte(i, :) / total;
        end
    end
end
