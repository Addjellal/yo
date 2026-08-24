function d = bi2de(b, varargin)
%BI2DE Vecteurs de chiffres vers entiers.
%   D = BI2DE(B) lit chaque ligne de B comme un nombre binaire, poids
%   faible en tête. D = BI2DE(B,BASE) change de base.
%   D = BI2DE(B,BASE,'left-msb') lit le poids fort en tête.
%
%   Exemple :
%      bi2de([0 1 1 0])                 % 6
%      bi2de([1 0 0 0], 2, 'left-msb')  % 8
%
%   Voir aussi DE2BI, BIN2DEC.
    [base, sens] = optionsChiffres(varargin);
    b = double(b);
    if size(b, 2) == 1 && size(b, 1) > 1
        b = b(:)';
    end
    if strcmp(sens, 'left-msb')
        b = b(:, end:-1:1);
    end
    d = zeros(size(b, 1), 1);
    for k = 1:size(b, 1)
        v = 0;
        for j = size(b, 2):-1:1
            v = v * base + b(k, j);
        end
        d(k) = v;
    end
end
