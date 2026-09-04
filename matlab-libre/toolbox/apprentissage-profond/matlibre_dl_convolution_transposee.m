function y = matlibre_dl_convolution_transposee(x, poids, biais, pas, rognage)
%MATLIBRE_DL_CONVOLUTION_TRANSPOSEE Convolution qui agrandit l'image.
%   Y = MATLIBRE_DL_CONVOLUTION_TRANSPOSEE(X,POIDS,BIAIS,PAS,ROGNAGE) fait
%   le chemin inverse d'une convolution : chaque point d'entrée est étalé
%   sur un voisinage de la sortie, et les étalements se recouvrent.
%
%   Le calcul est celui-là même que dit la définition : on écarte les
%   points d'entrée en intercalant des zéros — un de moins que le pas —,
%   puis on convolue. L'opération obtenue est exactement l'adjointe de la
%   convolution de mêmes poids et de même pas, ce qui est la propriété
%   qu'on attend d'elle.
%
%   Les poids sont rangés comme dans MATLAB : hauteur, largeur, filtres,
%   canaux d'entrée.
%
%   Exemple :
%      y = matlibre_dl_convolution_transposee(dlarray(ones(2,2,1,1), 'SSCB'), ...
%                                             ones(3,3,1,1), 0, [2 2], 0);
%      size(extractdata(y))      % 5 5 1 1
%
%   Voir aussi TRANSPOSEDCONV2DLAYER, DLCONV.
    taille = size(matlibre_dl_valeur(x));
    taille = [taille, ones(1, 4 - numel(taille))];
    noyau = [size(poids, 1), size(poids, 2)];
    hauteur = (taille(1) - 1) * pas(1) + 1;
    largeur = (taille(2) - 1) * pas(2) + 1;
    ecartee = dlarray(zeros(hauteur, largeur, taille(3), taille(4)), 'SSCB');
    ecartee(1:pas(1):hauteur, 1:pas(2):largeur, :, :) = x;
    % DLCONV retourne le filtre ; l'adjointe d'une convolution est une
    % correlation, on lui donne donc le filtre deja retourne pour que les
    % deux retournements s'annulent.
    noyauConv = permute(poids, [1 2 4 3]);
    noyauConv = noyauConv(end:-1:1, end:-1:1, :, :);
    y = dlconv(ecartee, noyauConv, biais, 'Stride', 1, ...
               'Padding', [noyau(1) - 1, noyau(2) - 1], 'DataFormat', 'SSCB');
    grande = [hauteur + noyau(1) - 1, largeur + noyau(2) - 1];
    bords = matlibre_couche_rognage(rognage, grande, taille(1:2), pas);
    if any(bords > 0)
        y = y((1 + bords(1)):(grande(1) - bords(2)), ...
              (1 + bords(3)):(grande(2) - bords(4)), :, :);
    end
end
