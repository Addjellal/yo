function [u, x, t] = heat1D(u0, alpha, longueur, tFinal, nx, nt)
%HEAT1D Équation de la chaleur, schéma de Crank-Nicolson.
%   [U,X,T] = HEAT1D(U0,ALPHA,L,TFINAL,NX,NT) avec U0 une poignée @(x)
%   et des bords maintenus à zéro. NX est le nombre de points intérieurs,
%   NT le nombre de pas de temps.
%
%   Crank-Nicolson est la moyenne du schéma explicite et de l'implicite :
%   il est d'ordre deux en temps comme en espace, et inconditionnellement
%   stable — aucune condition ne lie le pas de temps au pas d'espace, là
%   où le schéma explicite exigerait dt < dx^2 / (2 alpha).
%
%   La chaleur diffuse : la solution s'aplatit, son maximum décroît, et
%   son intégrale décroît aussi puisque les bords évacuent. Un mode propre
%   sin(n pi x / L) décroît exactement en exp(-alpha (n pi / L)^2 t), sans
%   changer de forme : c'est la vérification la plus sûre.
%
%   Exemple :
%      [u, x, t] = heat1D(@(x) sin(pi * x), 0.1, 1, 0.5, 50, 200);
%      u(:, end) ./ u(:, 1)            % exp(-0.1 pi^2 * 0.5), partout
%
%   Voir aussi WAVE1D, POISSON2D, FEM1D.
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
