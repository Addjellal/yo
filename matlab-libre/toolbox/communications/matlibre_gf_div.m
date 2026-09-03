function r = matlibre_gf_div(a, b, m, prim)
%MATLIBRE_GF_DIV Quotient terme à terme dans GF(2^M).
%   La division par zéro n'a pas de sens dans un corps : elle est
%   refusée, non rendue comme l'infini.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if any(b(:) == 0)
        error('comm:gf:DivisionParZero', ...
              'La division par zéro n''a pas de sens dans un corps.');
    end
    [journal, exponentielle] = matlibre_gf_journal(m, prim);
    n = 2 ^ m - 1;
    r = zeros(size(a));
    nonNul = a ~= 0;
    if any(nonNul(:))
        exposants = mod(journal(a(nonNul) + 1) - journal(b(nonNul) + 1), n);
        r(nonNul) = exponentielle(exposants + 1);
    end
end
