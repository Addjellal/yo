function C = normxcorr2(motif, image)
%NORMXCORR2 Corrélation croisée normalisée.
%   C = NORMXCORR2(MOTIF,IMAGE) rend la corrélation du motif avec
%   l'image, normalisée en chaque position par les écarts types locaux :
%   le résultat est entre -1 et 1, et vaut 1 là où le motif se retrouve
%   exactement, à un facteur d'échelle et un décalage près.
%
%   C'est ce qui distingue la corrélation normalisée de la corrélation
%   ordinaire : celle-ci répond fort partout où l'image est claire, sans
%   égard à la forme.
%
%   C a la taille de l'image augmentée du motif moins un ; le maximum se
%   trouve au coin bas-droit de la position du motif.
%
%   Exemple :
%      I = mat2gray(peaks(60));
%      motif = I(20:30, 25:35);
%      C = normxcorr2(motif, I);
%      [~, k] = max(C(:));
%      [ligne, colonne] = ind2sub(size(C), k);   % 30 et 35
%
%   Voir aussi XCORR2, CORR2, IMFILTER, CONV2, IMREGCORR.
    motif = double(motif);
    image = double(image);
    if size(motif, 3) > 1
        motif = mean(motif, 3);
    end
    if size(image, 3) > 1
        image = mean(image, 3);
    end
    [mp, np] = size(motif);
    [mi, ni] = size(image);
    if mp > mi || np > ni
        error('images:normxcorr2:Taille', ...
              'Le motif ne doit pas dépasser l''image.');
    end
    motifCentre = motif - mean(motif(:));
    normeMotif = sqrt(sum(motifCentre(:) .^ 2));
    if normeMotif == 0
        C = zeros(mi + mp - 1, ni + np - 1);
        return;
    end
    % Sommes locales par image intégrale : la moyenne et la variance de
    % chaque fenêtre se lisent alors en quatre accès, quel que soit le
    % motif.
    etendue = zeros(mi + 2 * mp - 2, ni + 2 * np - 2);
    etendue(mp:(mp + mi - 1), np:(np + ni - 1)) = image;
    sommes = integrale(etendue);
    sommesCarres = integrale(etendue .^ 2);
    nombre = mp * np;
    lignes = mi + mp - 1;
    colonnes = ni + np - 1;
    C = zeros(lignes, colonnes);
    % La corrélation non normalisée est une convolution par le motif
    % retourné : conv2 la calcule d'un coup.
    numerateur = conv2(etendue, rot90(motifCentre, 2), 'valid');
    for i = 1:lignes
        for j = 1:colonnes
            somme = fenetre(sommes, i, j, mp, np);
            sommeCarres = fenetre(sommesCarres, i, j, mp, np);
            variance = sommeCarres - somme ^ 2 / nombre;
            if variance <= 0
                C(i, j) = 0;
            else
                C(i, j) = numerateur(i, j) / (sqrt(variance) * normeMotif);
            end
        end
    end
    C = max(min(C, 1), -1);
end

function S = integrale(A)
% Image intégrale, avec une ligne et une colonne de zéros en tête.
    S = zeros(size(A, 1) + 1, size(A, 2) + 1);
    S(2:end, 2:end) = cumsum(cumsum(A, 1), 2);
end

function s = fenetre(S, i, j, mp, np)
    s = S(i + mp, j + np) - S(i, j + np) - S(i + mp, j) + S(i, j);
end
