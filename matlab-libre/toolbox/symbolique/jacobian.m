function J = jacobian(f, variables)
%JACOBIAN Matrice jacobienne d'expressions symboliques.
%   J = JACOBIAN(F,V) où F est une cellule d'expressions et V une cellule
%   de variables : J{i,j} est la dérivée de F{i} par rapport à V{j}.
%   Une seule expression donne une ligne, la jacobienne d'une fonction
%   scalaire étant son gradient transposé.
%
%   J = JACOBIAN(F) prend pour variables celles qui apparaissent dans F,
%   par ordre alphabétique.
%
%   Exemple :
%      syms x y
%      J = jacobian({x * y, x + y}, {x, y});
%      char(J{1, 1})                  % 'y'
%
%   Voir aussi DIFF, GRADIENT, HESSIAN, SYMVAR.
    if ~iscell(f)
        f = {f};
    end
    if nargin < 2 || isempty(variables)
        noms = {};
        for k = 1:numel(f)
            noms = [noms, matlibre_sym_noms(matlibre_sym_arbre(f{k}))];   %#ok<AGROW>
        end
        noms = unique(noms);
        variables = cell(1, numel(noms));
        for k = 1:numel(noms)
            variables{k} = sym(noms{k});
        end
    elseif ~iscell(variables)
        variables = {variables};
    end
    J = cell(numel(f), numel(variables));
    for i = 1:numel(f)
        for j = 1:numel(variables)
            J{i, j} = diff(sym(matlibre_sym_arbre(f{i})), variables{j});
        end
    end
end
