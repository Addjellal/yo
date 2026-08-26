function [u, x, y] = poisson2D(f, nx, ny, largeur, hauteur)
%POISSON2D Résout -laplacien(u) = f sur un rectangle, u nul au bord.
%   [U,X,Y] = POISSON2D(F,NX,NY) où F est une poignée @(x,y).
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
