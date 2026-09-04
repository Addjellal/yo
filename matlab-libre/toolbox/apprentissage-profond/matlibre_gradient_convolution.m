function contributions = matlibre_gradient_convolution(g, donnees)
%MATLIBRE_GRADIENT_CONVOLUTION Dérivées d'une convolution.
%   C = MATLIBRE_GRADIENT_CONVOLUTION(G,DONNEES) rend les dérivées par
%   rapport à l'entrée, aux poids et au biais.
%
%   La convolution ayant été écrite comme un produit de matrices, ses
%   dérivées sont celles d'un produit : la dérivée des poids est le
%   produit de la dérivée de sortie par les voisinages lus, et celle de
%   l'entrée se redistribue aux positions d'où les voisinages venaient —
%   chaque pixel recevant la somme de ce que toutes les positions qui
%   l'ont lu lui rendent.
%
%   Exemple :
%      % appelée par la rétropropagation, jamais directement
%
%   Voir aussi DLCONV, MATLIBRE_DL_CONVOLUER, DLGRADIENT.
    contexte = donnees{1};
    tailleSortie = contexte.tailleSortie;
    filtres = tailleSortie(3);
    unidimensionnel = isfield(contexte, 'unidimensionnel') && contexte.unidimensionnel;
    if unidimensionnel
        % La sortie a été repliée en trois dimensions ; la dérivée arrive
        % sous cette forme et doit reprendre la quatrième pour être
        % traitée comme les autres.
        g = reshape(g, tailleSortie);
    end
    gradientMatrice = reshape(permute(g, [3 1 2 4]), filtres, []);
    versPoidsMatrice = contexte.patchs * gradientMatrice.';
    versPoids = reshape(versPoidsMatrice, contexte.taillePoids);
    versPoids = versPoids(end:-1:1, end:-1:1, :, :);
    versPatchs = contexte.poidsMatrice * gradientMatrice;
    versEtendue = accumarray(contexte.indices(:), versPatchs(:), ...
                             [prod(contexte.tailleEtendue) 1]);
    versEtendue = reshape(versEtendue, contexte.tailleEtendue);
    bords = contexte.bords;
    tailleX = contexte.tailleX;
    versX = versEtendue((1:tailleX(1)) + bords(1), (1:tailleX(2)) + bords(3), :, :);
    versBiais = reshape(sum(gradientMatrice, 2), [], 1);
    if unidimensionnel
        versX = reshape(versX, tailleX(1), tailleX(3), tailleX(4));
        versPoids = reshape(versPoids, contexte.taillePoids(1), ...
                            contexte.taillePoids(3), contexte.taillePoids(4));
    end
    contributions = {versX, versPoids, versBiais};
end
