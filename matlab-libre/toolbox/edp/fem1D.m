function [u, x] = fem1D(f, longueur, n)
%FEM1D Éléments finis P1 pour -u'' = f, u(0) = u(L) = 0.
%   [U,X] = FEM1D(F,LONGUEUR,N) résout le problème sur N éléments, F étant
%   une poignée @(x). U et X portent les N+1 nœuds, bords compris.
%
%   Les éléments P1 sont des fonctions chapeau : la solution est affine
%   par morceaux, continue, et nulle aux bords. La matrice de rigidité qui
%   en résulte est tridiagonale, symétrique et définie positive — c'est ce
%   qui rend la résolution stable et rapide.
%
%   L'erreur décroît comme le carré du pas : diviser le pas par deux
%   divise l'erreur par quatre. C'est la vérification à faire sur un cas
%   dont on connaît la solution exacte.
%
%   Exemple :
%      % -u'' = 1 sur [0,1] a pour solution x(1-x)/2.
%      [u, x] = fem1D(@(x) ones(size(x)), 1, 32);
%      max(abs(u - x .* (1 - x) / 2))
%
%   Voir aussi POISSON2D, LAPLACE2D, HEAT1D.
    h = longueur / n;
    x = (0:n).' * h;
    K = zeros(n - 1, n - 1);
    F = zeros(n - 1, 1);
    for k = 1:n-1
        K(k, k) = 2 / h;
        if k > 1
            K(k, k-1) = -1 / h;
        end
        if k < n-1
            K(k, k+1) = -1 / h;
        end
        F(k) = f(x(k + 1)) * h;
    end
    interieur = K \ F;
    u = [0; interieur; 0];
end
