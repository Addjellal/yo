function [u, x, t] = wave1D(u0, c, longueur, tFinal, nx, nt)
%WAVE1D Équation des ondes en 1-D, différences centrées.
%   [U,X,T] = WAVE1D(U0,C,LONGUEUR,TFINAL,NX,NT) résout u_tt = c^2 u_xx
%   avec U0 une poignée @(x), une vitesse initiale nulle et des bords
%   fixés à zéro.
%
%   Contrairement à la chaleur, l'onde ne diffuse pas : elle transporte.
%   L'énergie se conserve, la forme revient, et le schéma doit respecter
%   la condition de Courant — c dt / dx au plus un — sans quoi il diverge.
%   Ce n'est pas une question de précision mais de stabilité : au-delà,
%   l'information numérique se propage moins vite que l'onde physique.
%
%   Une corde pincée sur son mode fondamental revient à sa forme initiale
%   au bout d'une période 2L/c : c'est la vérification à faire.
%
%   Exemple :
%      [u, x, t] = wave1D(@(x) sin(pi * x), 1, 1, 2, 100, 400);
%      max(abs(u(:, end) - u(:, 1)))   % petit : une periode ecoulee
%
%   Voir aussi HEAT1D, POISSON2D.
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
