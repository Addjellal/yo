function [numerateur, denominateur] = numden(f)
%NUMDEN Numérateur et dénominateur d'une expression symbolique.
%   [N,D] = NUMDEN(F) rend N et D tels que F = N/D, D étant débarrassé
%   des divisions imbriquées.
%
%   La réduction se fait de bas en haut : le numérateur et le
%   dénominateur d'une somme s'obtiennent de ceux des deux termes en
%   croisant — a/b + c/d = (ad + cb)/(bd) —, ceux d'un produit en
%   multipliant, et ceux d'un quotient en échangeant. Une expression sans
%   division a pour dénominateur un.
%
%   Le dénominateur rendu n'est pas réduit : (x^2-1)/(x-1) garde son
%   dénominateur, la simplification de fraction rationnelle demandant une
%   division polynomiale que SIMPLIFY ne fait pas encore.
%
%   Exemple :
%      syms x
%      [n, d] = numden(1/x + 1/(x + 1));
%      char(n)                         % x + 1 + x
%      char(d)                         % x*(x + 1)
%
%   Voir aussi SIMPLIFY, EXPAND, COLLECT, PARTFRAC.
    f = sym(f);
    [n, d] = fraction(f.arbre);
    numerateur = sym(matlibre_sym_reduire(n));
    denominateur = sym(matlibre_sym_reduire(d));
end

function [n, d] = fraction(arbre)
% Le numerateur et le denominateur d'un arbre, obtenus des siens.
    switch arbre{1}
        case {'num', 'var'}
            n = arbre;
            d = symnum(1);
        case '/'
            [n1, d1] = fraction(arbre{2});
            [n2, d2] = fraction(arbre{3});
            % a/b divise par c/d vaut ad/bc : on echange.
            n = symmul(n1, d2);
            d = symmul(d1, n2);
        case '*'
            [n1, d1] = fraction(arbre{2});
            [n2, d2] = fraction(arbre{3});
            n = symmul(n1, n2);
            d = symmul(d1, d2);
        case {'+', '-'}
            [n1, d1] = fraction(arbre{2});
            [n2, d2] = fraction(arbre{3});
            croiseA = symmul(n1, d2);
            croiseB = symmul(n2, d1);
            if strcmp(arbre{1}, '+')
                n = symadd(croiseA, croiseB);
            else
                n = symsub(croiseA, croiseB);
            end
            d = symmul(d1, d2);
        case '^'
            [n1, d1] = fraction(arbre{2});
            exposant = arbre{3};
            if strcmp(exposant{1}, 'num') && exposant{2} < 0
                % Une puissance negative renverse la fraction.
                n = sympow(d1, symnum(-exposant{2}));
                d = sympow(n1, symnum(-exposant{2}));
            else
                n = sympow(n1, exposant);
                d = sympow(d1, exposant);
            end
        otherwise
            % Une fonction — sin, exp — ne se decompose pas : elle est
            % son propre numerateur.
            n = arbre;
            d = symnum(1);
    end
end
