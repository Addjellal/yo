function u = laplace2D(bordHaut, bordBas, bordGauche, bordDroite, nx, ny)
%LAPLACE2D Équation de Laplace avec conditions de Dirichlet constantes.
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
