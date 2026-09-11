function r = collect(f, variable)
%COLLECT Regroupe les termes d'une expression par puissances.
%   COLLECT(F) regroupe les termes de F selon sa variable ; COLLECT(F,X)
%   selon X.
%
%   Regrouper n'est pas simplifier : on développe d'abord, puis on
%   rassemble tout ce qui porte la même puissance. Le résultat est la
%   forme canonique d'un polynôme — deux expressions égales y deviennent
%   identiques —, ce qui est précisément ce qui permet de les comparer.
%
%   Exemple :
%      syms x
%      collect((x + 1)^2)              % x^2 + 2*x + 1
%      collect(x*(x + 2) - x^2)        % 2*x
%
%   Voir aussi EXPAND, SIMPLIFY, HORNER, SYM2POLY.
    f = sym(f);
    if nargin < 2 || isempty(variable)
        variable = matlibre_sym_defaut(f);
    end
    nom = matlibre_sym_nom(variable);
    developpe = matlibre_sym_developper(f.arbre);
    coefficients = matlibre_sym_coefficients(developpe, nom);
    r = sym(matlibre_sym_polynome(coefficients, nom));
end
