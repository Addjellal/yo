function valeur = matlibre_gf_evaluer(poly, exposant, m, prim, journal, exponentielle)
%MATLIBRE_GF_EVALUER Valeur d'un polynôme en alpha^exposant.
%   Le polynôme est donné par puissances croissantes, à coefficients dans
%   GF(2^M).
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 5
        [journal, exponentielle] = matlibre_gf_journal(m, prim);
    end
    ordre = 2 ^ m - 1;
    valeur = 0;
    for j = 1:numel(poly)
        if poly(j) == 0
            continue
        end
        e = mod(journal(poly(j) + 1) + (j - 1) * exposant, ordre);
        valeur = bitxor(valeur, exponentielle(e + 1));
    end
end
