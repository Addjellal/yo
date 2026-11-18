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
    courant = c * dt / dx;
    if courant > 1
        warning('edp:wave1D:Courant', ...
                ['Nombre de Courant c*dt/dx = %.3g > 1 : le schéma est instable ', ...
                 'et la solution va diverger. Augmentez NT ou diminuez NX.'], courant);
    end
    lambda = courant ^ 2;
    u = zeros(nx, nt + 1);
    u(:, 1) = reshape(u0(x), [], 1);
    % Le laplacien discret sur tous les points intérieurs, les bords valant
    % zéro : le premier et le dernier point intérieurs ont un voisin au bord,
    % et doivent bouger comme les autres.
    laplacien = @(v) [v(2:end); 0] - 2 * v + [0; v(1:end-1)];
    % Premier pas, vitesse initiale nulle : le développement de Taylor
    % u(dt) = u0 + dt^2/2 * c^2 * u0'' garde l'ordre deux du schéma.
    u(:, 2) = u(:, 1) + 0.5 * lambda * laplacien(u(:, 1));
    for k = 2:nt
        u(:, k + 1) = 2 * u(:, k) - u(:, k - 1) + lambda * laplacien(u(:, k));
    end
end
