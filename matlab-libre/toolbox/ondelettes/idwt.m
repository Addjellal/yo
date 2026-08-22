function x = idwt(approximation, detail, nom)
%IDWT Reconstruction à partir de l'approximation et du détail.
    if nargin < 3
        nom = 'haar';
    end
    % DWT applique ici une corrélation (pas de retournement du filtre) :
    % son adjoint, donc son inverse pour un banc orthogonal, se calcule
    % avec les mêmes filtres d'analyse.
    [Lo_D, Hi_D] = wfilters(nom);
    m = numel(approximation);
    n = 2 * m;
    f = numel(Lo_D);
    x = zeros(1, n);
    for k = 1:m
        for j = 1:f
            indice = mod(2 * k - 2 + j - 1, n) + 1;
            x(indice) = x(indice) + Lo_D(j) * approximation(k) + Hi_D(j) * detail(k);
        end
    end
end
