function [u, x, t] = heat1D(u0, alpha, longueur, tFinal, nx, nt)
%HEAT1D Équation de la chaleur, schéma de Crank-Nicolson.
%   [U,X,T] = HEAT1D(U0,ALPHA,L,TFINAL,NX,NT) avec U0 une poignée @(x)
%   et des bords maintenus à zéro.
    dx = longueur / (nx + 1);
    dt = tFinal / nt;
    x = (1:nx).' * dx;
    t = (0:nt) * dt;
    r = alpha * dt / (2 * dx^2);
    A = zeros(nx, nx);
    B = zeros(nx, nx);
    for k = 1:nx
        A(k, k) = 1 + 2*r;
        B(k, k) = 1 - 2*r;
        if k > 1
            A(k, k-1) = -r;
            B(k, k-1) = r;
        end
        if k < nx
            A(k, k+1) = -r;
            B(k, k+1) = r;
        end
    end
    u = zeros(nx, nt + 1);
    u(:, 1) = u0(x);
    for k = 1:nt
        u(:, k+1) = A \ (B * u(:, k));
    end
end
