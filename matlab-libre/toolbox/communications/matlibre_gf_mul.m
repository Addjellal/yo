function r = matlibre_gf_mul(a, b, m, prim)
%MATLIBRE_GF_MUL Produit terme à terme dans GF(2^M).
%   Le produit passe par les logarithmes discrets : leur somme modulo
%   2^M-1 donne l'exposant du résultat. Un facteur nul donne zéro.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    [journal, exponentielle] = matlibre_gf_journal(m, prim);
    n = 2 ^ m - 1;
    r = zeros(size(a));
    nonNul = a ~= 0 & b ~= 0;
    if any(nonNul(:))
        exposants = mod(journal(a(nonNul) + 1) + journal(b(nonNul) + 1), n);
        r(nonNul) = exponentielle(exposants + 1);
    end
end
