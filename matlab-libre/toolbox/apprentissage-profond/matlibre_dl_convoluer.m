function [valeur, contexte] = matlibre_dl_convoluer(x, poids, biais, pas, bords, dilatation)
%MATLIBRE_DL_CONVOLUER Convolution par mise à plat des voisinages.
%   [Y,C] = MATLIBRE_DL_CONVOLUER(X,POIDS,BIAIS,PAS,BORDS,DILATATION)
%   calcule la convolution en rangeant chaque voisinage lu par le filtre
%   dans une colonne, ce qui ramène l'opération à un produit de matrices.
%   C retient de quoi la dériver.
%
%   Le filtre est retourné avant le produit : c'est une convolution au
%   sens propre, comme CONV2, et non une corrélation. Pour une couche dont
%   les poids sont appris, la convention ne change rien — le réseau
%   apprend le filtre retourné —, mais elle compte dès qu'on impose un
%   filtre connu.
%
%   Exemple :
%      y = matlibre_dl_convoluer(ones(3,3,1), ones(2,2,1,1), 0, [1 1], [0 0 0 0], [1 1]);
%      y(1, 1)     % 4
%
%   Voir aussi DLCONV, MATLIBRE_GRADIENT_CONVOLUTION.
    tailleX = size(x);
    tailleX = [tailleX, ones(1, 4 - numel(tailleX))];
    taillePoids = size(poids);
    taillePoids = [taillePoids, ones(1, 4 - numel(taillePoids))];
    canaux = tailleX(3);
    observations = tailleX(4);
    filtres = taillePoids(4);
    etendue = zeros(tailleX(1) + bords(1) + bords(2), ...
                    tailleX(2) + bords(3) + bords(4), canaux, observations);
    etendue((1:tailleX(1)) + bords(1), (1:tailleX(2)) + bords(3), :, :) = x;
    tailleEtendue = [size(etendue, 1), size(etendue, 2), canaux];
    [indices, tailleSortie] = matlibre_dl_indices_patchs(tailleEtendue, ...
                                                         taillePoids(1:2), pas, dilatation);
    positions = size(indices, 2);
    parObservation = prod(tailleEtendue);
    decalages = reshape((0:(observations - 1)) * parObservation, 1, 1, observations);
    indicesTous = reshape(indices + decalages, size(indices, 1), positions * observations);
    patchs = etendue(indicesTous);
    % Le retournement du filtre est ce qui distingue la convolution de la
    % corrélation ; il se fait une fois, sur les poids.
    poidsRetournes = poids(end:-1:1, end:-1:1, :, :);
    poidsMatrice = reshape(poidsRetournes, [], filtres);
    produit = poidsMatrice.' * patchs;
    produit = produit + reshape(double(biais(:)), filtres, 1);
    valeur = permute(reshape(produit, filtres, tailleSortie(1), tailleSortie(2), observations), ...
                     [2 3 1 4]);
    contexte.tailleX = tailleX;
    contexte.taillePoids = taillePoids;
    contexte.bords = bords;
    contexte.indices = indicesTous;
    contexte.tailleEtendue = [tailleEtendue, observations];
    contexte.patchs = patchs;
    contexte.poidsMatrice = poidsMatrice;
    contexte.tailleSortie = [tailleSortie, filtres, observations];
end
