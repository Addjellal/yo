function [Nx, Ny, Nz] = surfnorm(X, Y, Z)
%SURFNORM Normales d'une surface.
%   [NX,NY,NZ] = SURFNORM(X,Y,Z) rend les trois composantes de la normale
%   unitaire en chaque point de la surface. La normale est le produit
%   vectoriel des deux dérivées partielles, normalisé.
%
%   [NX,NY,NZ] = SURFNORM(Z) prend une grille entière pour X et Y.
%
%   SURFNORM(...) sans sortie trace la surface et ses normales.
%
%   Les dérivées sont obtenues par GRADIENT, donc par différences
%   centrées à l'intérieur et décentrées aux bords.
%
%   Exemples :
%      [X, Y] = meshgrid(-2:0.5:2);
%      Z = X .* exp(-X.^2 - Y.^2);
%      [nx, ny, nz] = surfnorm(X, Y, Z);
%      max(max(abs(nx.^2 + ny.^2 + nz.^2 - 1)))     % 1 : elles sont unitaires
%
%      surfnorm(X, Y, Z);
%
%   Voir aussi GRADIENT, SURF, QUIVER3, MESH.
    if nargin == 1
        Z = X;
        [X, Y] = meshgrid(1:size(Z, 2), 1:size(Z, 1));
    end
    % Les deux tangentes : d/dx = (1, 0, dz/dx), d/dy = (0, 1, dz/dy).
    [dzdx, dzdy] = gradient(Z, X(1, 2) - X(1, 1), Y(2, 1) - Y(1, 1));
    % Leur produit vectoriel : (-dz/dx, -dz/dy, 1).
    Nx = -dzdx;
    Ny = -dzdy;
    Nz = ones(size(Z));
    norme = sqrt(Nx .^ 2 + Ny .^ 2 + Nz .^ 2);
    norme(norme == 0) = 1;
    Nx = Nx ./ norme;
    Ny = Ny ./ norme;
    Nz = Nz ./ norme;
    if nargout == 0
        surf(X, Y, Z);
        hold('on');
        quiver(X, Y, Nx, Ny);
        hold('off');
        clear Nx;
    end
end
