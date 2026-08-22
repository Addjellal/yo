function [nombre, taux] = biterr(a, b, bits)
%BITERR Nombre et taux d'erreurs binaires entre deux suites d'entiers.
    if nargin < 3
        bits = max(1, ceil(log2(max([a(:); b(:)]) + 1)));
    end
    A = de2bi(a(:), bits);
    B = de2bi(b(:), bits);
    nombre = sum(sum(A ~= B));
    taux = nombre / numel(A);
end
