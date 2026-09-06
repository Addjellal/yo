function [u, x, y] = poisson2D(f, nx, ny, largeur, hauteur)
%POISSON2D Résout -laplacien(u) = f sur un rectangle, u nul au bord.
%   [U,X,Y] = POISSON2D(F,NX,NY,LARGEUR,HAUTEUR) où F est une poignée
%   @(x,y) et où le rectangle vaut un sur un par défaut. NX et NY comptent
%   les points intérieurs.
%
%   C'est Laplace avec un terme source : la même équation, un second
%   membre non nul. Le potentiel électrostatique d'une densité de charge,
%   la flèche d'une membrane chargée, la température d'une plaque
%   chauffée s'y ramènent tous.
%
%   Le système est symétrique défini positif, donc la solution existe et
%   elle est unique. Une source positive partout donne une solution
%   positive partout : c'est le principe du maximum, en présence de
%   source.
%
%   Un mode propre est solution exacte : pour f = 2 pi^2 sin(pi x)
%   sin(pi y) sur le carré unité, la solution est sin(pi x) sin(pi y).
%
%   Exemple :
%      f = @(x, y) 2 * pi^2 * sin(pi * x) .* sin(pi * y);
%      [u, x, y] = poisson2D(f, 40, 40);
%      max(u(:))                       % proche de 1
%
%   Voir aussi LAPLACE2D, FEM1D, HEAT1D.
    if nargin < 4, largeur = 1; end
    if nargin < 5, hauteur = 1; end
    hx = largeur / (nx + 1);
    hy = hauteur / (ny + 1);
    x = (1:nx) * hx;
    y = (1:ny) * hy;
    n = nx * ny;
    A = zeros(n, n);
    b = zeros(n, 1);
    for j = 1:ny
        for i = 1:nx
            k = (j - 1) * nx + i;
            A(k, k) = 2 / hx^2 + 2 / hy^2;
            if i > 1,  A(k, k - 1) = -1 / hx^2; end
            if i < nx, A(k, k + 1) = -1 / hx^2; end
            if j > 1,  A(k, k - nx) = -1 / hy^2; end
            if j < ny, A(k, k + nx) = -1 / hy^2; end
            b(k) = f(x(i), y(j));
        end
    end
    solution = A \ b;
    u = reshape(solution, nx, ny).';
end
