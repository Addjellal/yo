function [b, g] = sgolay(ordre, longueur, poids)
%SGOLAY Matrice de lissage de Savitzky-Golay.
%   B = SGOLAY(K,F) rend la matrice F x F de projection sur les polynômes
%   de degré K : la ligne centrale de B est le filtre à appliquer au
%   milieu du signal, les autres lignes traitent les bords.
%
%   [B,G] = SGOLAY(K,F) rend aussi la matrice des différentiateurs : la
%   colonne j+1 de G donne le filtre de la dérivée j-ième, au facteur
%   j! près.
%
%   Exemple :
%      b = sgolay(2, 5);   % lissage quadratique sur cinq points
    if mod(longueur, 2) ~= 1
        error('signal:sgolay:EvenFrameLength', 'La longueur doit être impaire.');
    end
    if ordre >= longueur
        error('signal:sgolay:OrderTooLarge', ...
              'Le degré doit être strictement inférieur à la longueur.');
    end
    m = (longueur - 1) / 2;
    s = (-m:m)';
    % Matrice de Vandermonde des monômes s^0 .. s^K.
    V = zeros(longueur, ordre + 1);
    for j = 0:ordre
        V(:, j + 1) = s .^ j;
    end
    if nargin >= 3 && ~isempty(poids)
        W = diag(double(poids(:)));
        g = (V' * W * V) \ (V' * W);
    else
        g = (V' * V) \ V';
    end
    g = g';
    b = V * g';
end
