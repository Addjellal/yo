function code = convenc(message, generateurs, contrainte)
%CONVENC Codeur convolutif systématique en octal.
%   CODE = CONVENC(MESSAGE,GENERATEURS,CONTRAINTE) où GENERATEURS est un
%   vecteur de polynômes en octal, par exemple [7 5] pour le code de
%   rendement 1/2 et de longueur de contrainte 3.
    if nargin < 3
        contrainte = 3;
    end
    n = numel(generateurs);
    registres = zeros(1, contrainte);
    code = zeros(1, numel(message) * n);
    masques = zeros(n, contrainte);
    for g = 1:n
        bits = de2bi(base2dec(dec2base(generateurs(g), 8), 8), contrainte);
        masques(g, :) = bits(end:-1:1);
    end
    indice = 1;
    for k = 1:numel(message)
        registres = [message(k), registres(1:end-1)];
        for g = 1:n
            code(indice) = mod(sum(registres .* masques(g, :)), 2);
            indice = indice + 1;
        end
    end
end
