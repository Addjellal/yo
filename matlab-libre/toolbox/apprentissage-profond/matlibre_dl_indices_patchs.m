function [indices, tailleSortie] = matlibre_dl_indices_patchs(tailleEtendue, noyau, pas, dilatation)
%MATLIBRE_DL_INDICES_PATCHS Positions lues par un filtre glissant.
%   [I,T] = MATLIBRE_DL_INDICES_PATCHS(TAILLE,NOYAU,PAS,DILATATION) rend
%   la matrice des numéros linéaires que le filtre lit : une ligne par
%   coefficient du filtre — canal compris —, une colonne par position de
%   sortie. T donne la taille spatiale de la sortie.
%
%   Écrire la convolution comme un produit de matrices à partir de ces
%   numéros a deux vertus : le calcul se ramène à une seule multiplication,
%   et sa dérivée s'obtient en renvoyant les contributions à ces mêmes
%   numéros, ce qui traite d'un coup le pas, le remplissage et la
%   dilatation.
%
%   Exemple :
%      [i, t] = matlibre_dl_indices_patchs([3 3 1], [2 2], [1 1], [1 1]);
%      size(i)     % 4 4
%
%   Voir aussi DLCONV, MATLIBRE_DL_CONVOLUER.
    hauteur = tailleEtendue(1);
    largeur = tailleEtendue(2);
    canaux = tailleEtendue(3);
    hauteurSortie = floor((hauteur - (noyau(1) - 1) * dilatation(1) - 1) / pas(1)) + 1;
    largeurSortie = floor((largeur - (noyau(2) - 1) * dilatation(2) - 1) / pas(2)) + 1;
    if hauteurSortie < 1 || largeurSortie < 1
        error('nnet:dlconv:Taille', ...
              'Le filtre est plus grand que l''entrée, remplissage compris.');
    end
    tailleSortie = [hauteurSortie, largeurSortie];
    [decalageLigne, decalageColonne] = ndgrid(0:(noyau(1) - 1), 0:(noyau(2) - 1));
    decalageLigne = decalageLigne(:) * dilatation(1);
    decalageColonne = decalageColonne(:) * dilatation(2);
    [departLigne, departColonne] = ndgrid(0:(hauteurSortie - 1), 0:(largeurSortie - 1));
    departLigne = departLigne(:).' * pas(1);
    departColonne = departColonne(:).' * pas(2);
    coefficients = noyau(1) * noyau(2);
    indices = zeros(coefficients * canaux, hauteurSortie * largeurSortie);
    for c = 1:canaux
        base = (c - 1) * hauteur * largeur;
        for m = 1:coefficients
            indices((c - 1) * coefficients + m, :) = ...
                1 + base + (decalageLigne(m) + departLigne) + ...
                (decalageColonne(m) + departColonne) * hauteur;
        end
    end
end
