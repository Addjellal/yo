function c = matlibre_gf_convolution(a, b, m, prim)
%MATLIBRE_GF_CONVOLUTION Produit de deux polynômes de GF(2^M).
%   Coefficients par puissances croissantes ; l'addition étant le ou
%   exclusif, il n'y a pas de retenue.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    a = double(a(:)).';
    b = double(b(:)).';
    c = zeros(1, numel(a) + numel(b) - 1);
    for i = 1:numel(a)
        if a(i) == 0
            continue
        end
        produits = matlibre_gf_mul(repmat(a(i), 1, numel(b)), b, m, prim);
        plage = i:(i + numel(b) - 1);
        c(plage) = bitxor(c(plage), produits);
    end
end
