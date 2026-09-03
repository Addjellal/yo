function r = matlibre_gf_pow(a, n, m, prim)
%MATLIBRE_GF_POW Puissance terme à terme dans GF(2^M).
%   Un exposant négatif prend l'inverse, ce qui a un sens dans un corps
%   tant que la base n'est pas nulle. Zéro puissance zéro vaut un, comme
%   partout dans MATLAB.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    [journal, exponentielle] = matlibre_gf_journal(m, prim);
    ordre = 2 ^ m - 1;
    r = zeros(size(a));
    for k = 1:numel(a)
        if a(k) == 0
            if n(k) == 0
                r(k) = 1;
            elseif n(k) < 0
                error('comm:gf:Puissance', ...
                      'Zéro n''a pas de puissance négative.');
            else
                r(k) = 0;
            end
            continue
        end
        exposant = mod(journal(a(k) + 1) * n(k), ordre);
        r(k) = exponentielle(exposant + 1);
    end
end
