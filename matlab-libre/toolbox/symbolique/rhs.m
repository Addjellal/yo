function r = rhs(equation)
%RHS Membre de droite d'une équation symbolique.
%   RHS(EQ) rend ce qui est à droite du signe d'égalité. LHS rend ce qui
%   est à gauche.
%
%   Une équation n'est pas une expression : elle a deux membres, et
%   beaucoup de ce qu'on veut en faire — évaluer la solution, la
%   substituer ailleurs — porte sur un seul des deux. Sans RHS il faudrait
%   descendre dans l'arbre à la main.
%
%   Exemple :
%      syms x
%      double(rhs(isolate(2*x + 3, x)))   % -1.5
%      char(lhs(isolate(2*x + 3, x)))     % 'x'
%
%   Voir aussi LHS, ISOLATE, SOLVE, CHILDREN.
    equation = sym(equation);
    if ~strcmp(equation.arbre{1}, '=')
        error('symbolic:rhs:pasUneEquation', ...
              'RHS attend une équation, avec ses deux membres.');
    end
    r = sym(equation.arbre{3});
end
