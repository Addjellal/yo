function c = children(f)
%CHILDREN Sous-expressions immédiates d'une expression symbolique.
%   C = CHILDREN(F) rend, dans une cellule, les opérandes de l'opérateur
%   de tête de F. Une somme rend ses deux termes, un produit ses deux
%   facteurs, une fonction son argument ; un nombre ou une variable, qui
%   n'ont pas d'opérateur de tête, se rendent eux-mêmes.
%
%   C'est la façon de descendre dans une expression sans rien savoir de
%   sa forme : on regarde l'opérateur, on prend les enfants, on
%   recommence. Tout ce qui parcourt un arbre symbolique s'écrit ainsi.
%
%   Exemple :
%      syms x
%      c = children(x + 1);
%      numel(c)                        % 2
%      char(c{1})                      % x
%
%   Voir aussi SYMVAR, SUBS, EXPAND, SIMPLIFY.
    f = sym(f);
    arbre = f.arbre;
    switch arbre{1}
        case {'num', 'var'}
            c = {f};
        otherwise
            c = cell(1, numel(arbre) - 1);
            for k = 2:numel(arbre)
                c{k - 1} = sym(arbre{k});
            end
    end
end
