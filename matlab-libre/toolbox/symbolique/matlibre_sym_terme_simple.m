function arbre = matlibre_sym_terme_simple(residu, pole, multiplicite, nom)
%MATLIBRE_SYM_TERME_SIMPLE Un terme d'une décomposition en éléments simples.
%   Rend R / (X - P)^M, sous la forme la plus lisible : le dénominateur
%   n'est pas élevé à la puissance un, et un pôle nul ne s'écrit pas
%   « X - 0 ».
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      a = matlibre_sym_terme_simple(2, 1, 1, 'x');
%      char(sym(a))                    % 2/(x - 1)
%
%   Voir aussi PARTFRAC, RESIDUE.
    if abs(residu) < 1e-14
        arbre = [];
        return
    end
    if abs(pole) < 1e-14
        base = {'var', nom};
    elseif pole > 0
        base = symsub({'var', nom}, symnum(arrondir(pole)));
    else
        base = symadd({'var', nom}, symnum(arrondir(-pole)));
    end
    if multiplicite > 1
        base = sympow(base, symnum(multiplicite));
    end
    arbre = symdiv(symnum(arrondir(residu)), base);
end

function v = arrondir(x)
% Les residus viennent d'une resolution numerique : un 2 qui vaut
% 1,9999999999999998 s'ecrit 2, sans quoi la decomposition serait juste
% et illisible.
    if abs(x - round(x)) < 1e-9 * max(1, abs(x))
        v = round(x);
    else
        v = x;
    end
end
