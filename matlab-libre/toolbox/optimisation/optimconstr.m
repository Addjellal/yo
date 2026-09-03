classdef optimconstr
%OPTIMCONSTR Contrainte d'un problème d'optimisation.
%   Une contrainte naît d'une comparaison entre expressions : x + y <= 4
%   en est une. Elle garde l'expression ramenée à zéro et le sens de la
%   comparaison.
%
%   On ne l'écrit pas à la main : les opérateurs <=, >= et == la
%   fabriquent.
%
%   Exemple :
%      x = optimvar('x', 2);
%      c = sum(x) <= 4;
%
%   Voir aussi OPTIMVAR, OPTIMPROBLEM, SOLVE.
    properties
        Expression = []
        Sens = '<='
    end
    methods
        function c = optimconstr(expression, sens)
            if nargin == 0
                return
            end
            c.Expression = expression;
            c.Sens = sens;
        end
    end
end
