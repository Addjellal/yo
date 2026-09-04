function [valeur, contexte] = matlibre_dl_agreger(x, genre, fenetre, pas, bords)
%MATLIBRE_DL_AGREGER Agrégation par le maximum ou la moyenne.
%   [Y,C] = MATLIBRE_DL_AGREGER(X,GENRE,FENETRE,PAS,BORDS) parcourt X par
%   fenêtres et n'en garde que le maximum ou la moyenne. C retient de quoi
%   dériver.
%
%   L'agrégation se fait canal par canal : les canaux sont donc traités
%   comme autant d'observations supplémentaires, ce qui permet de
%   réemployer la mise à plat des voisinages écrite pour la convolution.
%
%   Le remplissage vaut moins l'infini pour le maximum — une case ajoutée
%   ne peut pas gagner — et zéro pour la moyenne, qui divise par la
%   fenêtre entière.
%
%   Exemple :
%      y = matlibre_dl_agreger(reshape(1:16, 4, 4), 'max', [2 2], [2 2], [0 0 0 0]);
%      y(1, 1)     % 6
%
%   Voir aussi MAXPOOL, AVGPOOL, MAXPOOLING2DLAYER.
    tailleX = size(x);
    tailleX = [tailleX, ones(1, 4 - numel(tailleX))];
    plans = tailleX(3) * tailleX(4);
    if strcmp(genre, 'max')
        neutre = -Inf;
    else
        neutre = 0;
    end
    etendue = neutre * ones(tailleX(1) + bords(1) + bords(2), ...
                            tailleX(2) + bords(3) + bords(4), plans);
    etendue((1:tailleX(1)) + bords(1), (1:tailleX(2)) + bords(3), :) = ...
        reshape(x, tailleX(1), tailleX(2), plans);
    tailleEtendue = [size(etendue, 1), size(etendue, 2), 1];
    [indices, tailleSortie] = matlibre_dl_indices_patchs(tailleEtendue, fenetre, pas, [1 1]);
    positions = size(indices, 2);
    parPlan = tailleEtendue(1) * tailleEtendue(2);
    decalages = reshape((0:(plans - 1)) * parPlan, 1, 1, plans);
    indicesTous = reshape(indices + decalages, size(indices, 1), positions * plans);
    patchs = etendue(indicesTous);
    coefficients = size(patchs, 1);
    if strcmp(genre, 'max')
        [lignes, rangs] = max(patchs, [], 1);
        contexte.choix = rangs + (0:(size(patchs, 2) - 1)) * coefficients;
    else
        lignes = mean(patchs, 1);
        contexte.choix = [];
    end
    valeur = reshape(lignes, tailleSortie(1), tailleSortie(2), tailleX(3), tailleX(4));
    contexte.genre = genre;
    contexte.tailleX = tailleX;
    contexte.bords = bords;
    contexte.indices = indicesTous;
    contexte.tailleEtendue = [tailleEtendue(1), tailleEtendue(2), plans];
    contexte.coefficients = coefficients;
    contexte.tailleSortie = [tailleSortie, tailleX(3), tailleX(4)];
end
