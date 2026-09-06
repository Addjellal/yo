function u = laplace2D(bordHaut, bordBas, bordGauche, bordDroite, nx, ny)
%LAPLACE2D Équation de Laplace avec conditions de Dirichlet constantes.
%   U = LAPLACE2D(HAUT,BAS,GAUCHE,DROITE,NX,NY) résout le laplacien nul
%   sur un rectangle dont chaque bord est maintenu à une valeur constante.
%
%   Une fonction harmonique n'a ni maximum ni minimum à l'intérieur : ses
%   extrêmes sont sur le bord. C'est le principe du maximum, et c'est la
%   vérification la plus simple d'une solution de Laplace.
%
%   Chaque point intérieur vaut la moyenne de ses quatre voisins : c'est à
%   la fois le schéma numérique et une propriété exacte de la solution.
%   Quatre bords égaux donnent donc une solution constante.
%
%   Exemple :
%      u = laplace2D(100, 0, 0, 0, 40, 40);
%      max(u(:)) <= 100 && min(u(:)) >= 0      % le principe du maximum
%      u = laplace2D(50, 50, 50, 50, 20, 20);  % constante a 50
%
%   Voir aussi POISSON2D, HEAT1D, FEM1D.
    u = zeros(ny, nx);
    u(1, :) = bordHaut;
    u(end, :) = bordBas;
    u(:, 1) = bordGauche;
    u(:, end) = bordDroite;
    for tour = 1:5000
        ecart = 0;
        for i = 2:ny-1
            for j = 2:nx-1
                nouveau = 0.25 * (u(i-1, j) + u(i+1, j) + u(i, j-1) + u(i, j+1));
                ecart = max(ecart, abs(nouveau - u(i, j)));
                u(i, j) = nouveau;
            end
        end
        if ecart < 1e-10
            break;
        end
    end
end
