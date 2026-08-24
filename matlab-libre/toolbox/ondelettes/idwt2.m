function x = idwt2(ca, ch, cv, cd, nom)
%IDWT2 Reconstruction bidimensionnelle, un niveau.
%   Réciproque de DWT2 : on remonte d'abord les colonnes, puis les lignes.
%
%   Exemple :
%      [a,h,v,d] = dwt2(magic(4), 'db2');
%      max(max(abs(idwt2(a,h,v,d,'db2') - magic(4))))   % nul
    if nargin < 5 || isempty(nom), nom = 'haar'; end
    ligneA = remonterColonnes(ca, ch, nom);
    ligneD = remonterColonnes(cv, cd, nom);
    m = size(ligneA, 1);
    x = zeros(m, 2 * size(ligneA, 2));
    for i = 1:m
        x(i, :) = idwt(ligneA(i, :), ligneD(i, :), nom);
    end
end

function y = remonterColonnes(a, d, nom)
    colonnes = size(a, 2);
    for j = 1:colonnes
        v = idwt(a(:, j)', d(:, j)', nom);
        if j == 1
            y = zeros(numel(v), colonnes);
        end
        y(:, j) = v(:);
    end
end
