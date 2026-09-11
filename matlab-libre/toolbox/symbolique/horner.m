function r = horner(f, variable)
%HORNER Forme emboîtée d'un polynôme symbolique.
%   HORNER(F) réécrit F sous la forme de Horner : les puissances
%   s'emboîtent au lieu de s'additionner.
%
%      a x^3 + b x^2 + c x + d  devient  ((a x + b) x + c) x + d
%
%   HORNER(F,X) nomme la variable.
%
%   L'intérêt n'est pas l'apparence : la forme emboîtée s'évalue en n
%   multiplications au lieu de n(n+1)/2, et chaque étape ne combine que
%   deux nombres, ce qui la rend plus stable. C'est celle que POLYVAL
%   emploie, et celle que produit MATLABFUNCTION quand on lui donne un
%   polynôme.
%
%   Exemple :
%      syms x
%      h = horner(x^3 + 2*x^2 + 3*x + 4);
%      double(subs(h, x, 2)) == double(subs(x^3 + 2*x^2 + 3*x + 4, x, 2))
%
%   Voir aussi POLYVAL, COLLECT, EXPAND, SIMPLIFY, MATLABFUNCTION.
    f = sym(f);
    if nargin < 2 || isempty(variable)
        variable = matlibre_sym_defaut(f);
    end
    nom = matlibre_sym_nom(variable);
    coefficients = matlibre_sym_coefficients(matlibre_sym_developper(f.arbre), nom);
    r = sym(matlibre_sym_horner(coefficients, nom));
end
