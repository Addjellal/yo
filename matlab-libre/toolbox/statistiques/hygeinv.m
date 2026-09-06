function x = hygeinv(y, m, k, n)
%HYGEINV Quantile de la loi hypergéométrique.
%   X = HYGEINV(P,M,K,N) rend le plus petit entier dont la fonction de
%   répartition hypergéométrique atteint P : on tire N objets sans remise
%   dans une population de M dont K possèdent le caractère cherché, et X
%   est le quantile du nombre d'objets marqués obtenus.
%
%   Sans remise : c'est tout ce qui la sépare de la binomiale. Chaque
%   tirage modifie la composition de l'urne, si bien que les tirages sont
%   négativement corrélés et la variance plus faible que celle de la
%   binomiale, dans le rapport (M-N)/(M-1) — le facteur de population
%   finie. Quand M devient grand devant N, ce facteur tend vers un et les
%   deux lois se confondent.
%
%   La loi étant discrète, la fonction de répartition est en escalier :
%   X est le plus petit entier tel que HYGECDF(X,M,K,N) >= P, cherché par
%   dichotomie entre 0 et min(K,N). Un P hors de [0,1] rend NaN.
%
%   Exemple :
%      hygeinv(0.5, 50, 10, 5)
%
%   Voir aussi HYGECDF, HYGEPDF, HYGERND, BINOINV.
    [y, m, k, n] = statAjuster(y, m, k, n);
    x = zeros(size(y));
    for indice = 1:numel(y)
        if ~(y(indice) >= 0 && y(indice) <= 1)
            x(indice) = NaN;
            continue
        end
        mm = m(indice); kk = k(indice); nn = n(indice);
        haut = min(kk, nn);
        x(indice) = statQuantileDiscret(@(t) hygecdf(t, mm, kk, nn), ...
                                        y(indice), 0, haut);
    end
end
