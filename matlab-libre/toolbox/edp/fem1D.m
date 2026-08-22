function [u, x] = fem1D(f, longueur, n)
%FEM1D Éléments finis P1 pour -u'' = f, u(0) = u(L) = 0.
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
