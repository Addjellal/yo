function [u, x, t] = wave1D(u0, c, longueur, tFinal, nx, nt)
%WAVE1D Équation des ondes en 1-D, différences centrées.
    dx = longueur / (nx + 1);
    dt = tFinal / nt;
    x = (1:nx).' * dx;
    t = (0:nt) * dt;
    lambda = (c * dt / dx) ^ 2;
    u = zeros(nx, nt + 1);
    u(:, 1) = u0(x);
    % Premier pas : vitesse initiale nulle.
    for i = 2:nx-1
        u(i, 2) = u(i, 1) + 0.5 * lambda * (u(i+1, 1) - 2*u(i, 1) + u(i-1, 1));
    end
    for k = 2:nt
        for i = 2:nx-1
            u(i, k+1) = 2*u(i, k) - u(i, k-1) + ...
                        lambda * (u(i+1, k) - 2*u(i, k) + u(i-1, k));
        end
    end
end
