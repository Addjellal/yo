function expression = poly2sym(coefficients, variable)
%POLY2SYM Expression symbolique d'un polynôme donné par ses coefficients.
%   F = POLY2SYM(P) où P porte les coefficients par puissances
%   décroissantes, comme POLYVAL les attend ; la variable est x.
%   F = POLY2SYM(P,X) nomme la variable.
%
%   C'est l'inverse de SYM2POLY : ensemble, elles font passer d'une
%   écriture à l'autre.
%
%   Exemple :
%      f = poly2sym([1 0 -4]);
%      char(f)                        % '((x ^ 2) - 4)'
%      sym2poly(f)                    % [1 0 -4]
%
%   Voir aussi SYM2POLY, SYM, ROOTS, POLYVAL.
    if nargin < 2 || isempty(variable)
        nom = 'x';
    else
        nom = matlibre_sym_nom(variable);
    end
    expression = sym(matlibre_sym_polynome(double(coefficients), nom));
end
