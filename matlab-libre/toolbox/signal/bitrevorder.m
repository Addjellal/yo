function [y, indices] = bitrevorder(x)
%BITREVORDER Range un vecteur en ordre de bits inversés.
%   Y = BITREVORDER(X) permute X de sorte que l'élément d'indice K se
%   retrouve à l'indice obtenu en lisant les bits de K-1 à l'envers.
%   C'est l'ordre dans lequel une transformée de Fourier rapide en
%   entrelacement temporel lit ses données.
%
%   [Y,I] = BITREVORDER(X) rend en outre la permutation, telle que
%   Y = X(I).
%
%   La longueur de X doit être une puissance de deux.
%
%   Exemple :
%      bitrevorder(0:7)     % [0 4 2 6 1 5 3 7]
%
%   Voir aussi FFT, DIGITREVORDER, FFTSHIFT.
    n = numel(x);
    if n < 1 || bitand(n, n - 1) ~= 0
        error('signal:bitrevorder:BadLength', ...
              'La longueur doit être une puissance de deux.');
    end
    bits = round(log2(n));
    indices = zeros(n, 1);
    for k = 0:(n - 1)
        renverse = 0;
        valeur = k;
        for b = 1:bits
            renverse = renverse * 2 + mod(valeur, 2);
            valeur = floor(valeur / 2);
        end
        indices(k + 1) = renverse + 1;
    end
    y = x(indices);
    if isrow(x)
        y = reshape(y, 1, []);
        indices = indices.';
    end
end
