function M = normaliserLignes(M)
%NORMALISERLIGNES Chaque ligne d'une matrice de probabilités somme à un.
%   Une ligne entièrement nulle reste nulle : c'est un état dont on ne
%   sort pas, et le signaler vaut mieux que d'inventer une loi uniforme.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    sommes = sum(M, 2);
    for k = 1:numel(sommes)
        if sommes(k) > 0
            M(k, :) = M(k, :) / sommes(k);
        end
    end
end
