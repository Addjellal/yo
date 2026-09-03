function coefficients = matlibre_gf_minimal(classe, m, prim, journal, exponentielle)
%MATLIBRE_GF_MINIMAL Polynôme minimal d'une classe cyclotomique.
%   Le produit des (x - alpha^k) sur toute la classe est à coefficients
%   dans GF(2) : c'est le polynôme minimal, rendu par puissances
%   croissantes.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 4
        [journal, exponentielle] = matlibre_gf_journal(m, prim);
    end
    n = 2 ^ m - 1;
    % Le polynôme est à coefficients dans le corps : un entier par degré.
    coefficients = 1;
    for k = 1:numel(classe)
        racine = exponentielle(mod(classe(k), n) + 1);
        suivant = zeros(1, numel(coefficients) + 1);
        for j = 1:numel(coefficients)
            suivant(j + 1) = bitxor(suivant(j + 1), coefficients(j));
            produit = matlibre_gf_mul(coefficients(j), racine, m, prim);
            suivant(j) = bitxor(suivant(j), produit);
        end
        coefficients = suivant;
    end
    if any(coefficients > 1)
        error('comm:bch:NonBinaire', ...
              'Le polynôme minimal n''est pas à coefficients binaires.');
    end
    journal = journal;   %#ok<ASGSL,NASGU>
end
