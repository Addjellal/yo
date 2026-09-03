function I = mat2gray(A, bornes)
%MAT2GRAY Ramène une matrice dans l'intervalle [0,1].
%   I = MAT2GRAY(A) rend une image d'intensité : le minimum de A devient
%   0, le maximum 1, et le reste s'échelonne linéairement entre les deux.
%   C'est ce qu'il faut pour montrer une matrice quelconque comme une
%   image.
%
%   I = MAT2GRAY(A,[BAS HAUT]) fixe les deux bornes : ce qui est en
%   dessous de BAS devient 0, ce qui est au-dessus de HAUT devient 1.
%
%   Exemple :
%      I = mat2gray(magic(4));
%      [min(I(:)) max(I(:))]     % [0 1]
%
%   Voir aussi IMADJUST, IM2DOUBLE, IMSHOW, RESCALE, STRETCHLIM.
    A = double(A);
    if nargin < 2 || isempty(bornes)
        bas = min(A(:));
        haut = max(A(:));
    else
        bas = double(bornes(1));
        haut = double(bornes(2));
    end
    if isempty(bas) || bas == haut
        % Une image constante : MATLAB la rend telle quelle, bornée.
        I = double(A ~= 0);
        I = min(max(I, 0), 1);
        return;
    end
    I = (A - bas) / (haut - bas);
    I = min(max(I, 0), 1);
end
