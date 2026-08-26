function [z, p, k] = ss2zp(A, B, C, D, iu)
%SS2ZP Zéros, pôles et gain d'une représentation d'état.
%   Les pôles sont les valeurs propres de A ; les zéros sont les racines
%   du numérateur de la fonction de transfert.
    if nargin < 5, iu = 1; end
    [num, den] = ss2tf(A, B, C, D, iu);
    p = eig(A);
    p = p(:);
    num = num(:).';
    while numel(num) > 1 && abs(num(1)) < eps * max(abs(num))
        num(1) = [];
    end
    if numel(num) <= 1
        z = zeros(0, 1);
        k = num(end);
    else
        z = roots(num);
        z = z(:);
        k = num(1);
    end
    if nargin >= 4 && ~isempty(den)
        % Le gain se lit après normalisation du dénominateur.
        k = k / den(1);
    end
end
