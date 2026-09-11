function r = lhs(equation)
%LHS Membre de gauche d'une équation symbolique.
%   LHS(EQ) rend ce qui est à gauche du signe d'égalité. RHS rend ce qui
%   est à droite.
%
%   Exemple :
%      syms x
%      char(lhs(isolate(2*x + 3, x)))     % 'x'
%      double(rhs(isolate(2*x + 3, x)))   % -1.5
%
%   Voir aussi RHS, ISOLATE, SOLVE, CHILDREN.
    equation = sym(equation);
    if ~strcmp(equation.arbre{1}, '=')
        error('symbolic:lhs:pasUneEquation', ...
              'LHS attend une équation, avec ses deux membres.');
    end
    r = sym(equation.arbre{2});
end
