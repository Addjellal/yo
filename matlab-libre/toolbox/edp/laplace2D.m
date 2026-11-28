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
%   U est NY x NX, bords compris : la première ligne est le bord du haut.
%   Le système des points intérieurs est résolu directement, en matrice
%   creuse — non par des balayages de Gauss-Seidel arrêtés au bout d'un
%   nombre fixé de tours, qui sur une grille fine s'arrêtent loin de la
%   solution sans le dire.
%
%   Exemple :
%      u = laplace2D(100, 0, 0, 0, 40, 40);
%      max(u(:)) <= 100 && min(u(:)) >= 0      % le principe du maximum
%      u = laplace2D(50, 50, 50, 50, 20, 20);  % constante a 50
%
%   Voir aussi POISSON2D, HEAT1D, FEM1D.
    if nx < 2 || ny < 2
        error('edp:laplace2D:Taille', 'At least two points per direction are required.');
    end
    u = zeros(ny, nx);
    u(1, :) = bordHaut;
    u(end, :) = bordBas;
    u(:, 1) = bordGauche;
    u(:, end) = bordDroite;
    mi = ny - 2;
    ni = nx - 2;
    if mi < 1 || ni < 1
        return
    end
    % Le laplacien à cinq points sur les inconnues intérieures, rangées
    % colonne par colonne : 4*u(i,j) - (voisins intérieurs) = (voisins au bord).
    n = mi * ni;
    numero = reshape(1:n, mi, ni);
    lignes = numero(:);
    colonnes = numero(:);
    valeurs = 4 * ones(n, 1);
    for decalage = [-1 0; 1 0; 0 -1; 0 1].'
        di = decalage(1);
        dj = decalage(2);
        [I, J] = ndgrid(1:mi, 1:ni);
        dedans = I + di >= 1 & I + di <= mi & J + dj >= 1 & J + dj <= ni;
        lignes = [lignes; numero(dedans)];                                %#ok<AGROW>
        colonnes = [colonnes; numero(sub2ind([mi ni], I(dedans) + di, J(dedans) + dj))]; %#ok<AGROW>
        valeurs = [valeurs; -ones(nnz(dedans), 1)];                       %#ok<AGROW>
    end
    A = sparse(lignes, colonnes, valeurs, n, n);
    b = zeros(mi, ni);
    b(1, :) = b(1, :) + u(1, 2:end-1);
    b(end, :) = b(end, :) + u(end, 2:end-1);
    b(:, 1) = b(:, 1) + u(2:end-1, 1);
    b(:, end) = b(:, end) + u(2:end-1, end);
    u(2:end-1, 2:end-1) = reshape(A \ b(:), mi, ni);
end
