function J = integralImage(I)
%INTEGRALIMAGE Image intégrale (sommes cumulées en deux dimensions).
%   J(i+1,j+1) est la somme des pixels du rectangle allant du coin
%   supérieur gauche à (i,j).
    I = double(I);
    [h, l] = size(I);
    J = zeros(h + 1, l + 1);
    for i = 1:h
        for j = 1:l
            J(i+1, j+1) = I(i, j) + J(i, j+1) + J(i+1, j) - J(i, j);
        end
    end
end
