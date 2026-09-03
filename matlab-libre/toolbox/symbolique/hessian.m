function H = hessian(f, variables)
%HESSIAN Matrice hessienne d'une expression symbolique.
%   H = HESSIAN(F,V) rend les dérivées secondes : H{i,j} est la dérivée
%   de F par rapport à V{i} puis V{j}.
%   H = HESSIAN(F) prend les variables de F, par ordre alphabétique.
%
%   La hessienne est symétrique dès que les dérivées secondes croisées
%   sont continues — c'est le théorème de Schwarz —, et le calcul le
%   montre.
%
%   Exemple :
%      syms x y
%      H = hessian(x ^ 2 * y, {x, y});
%      char(H{1, 1})                  % '2 * y'
%      char(H{1, 2})                  % '2 * x'
%
%   Voir aussi JACOBIAN, GRADIENT, DIFF.
    if nargin < 2 || isempty(variables)
        noms = unique(matlibre_sym_noms(matlibre_sym_arbre(f)));
        variables = cell(1, numel(noms));
        for k = 1:numel(noms)
            variables{k} = sym(noms{k});
        end
    elseif ~iscell(variables)
        variables = {variables};
    end
    n = numel(variables);
    H = cell(n, n);
    for i = 1:n
        premiere = diff(sym(matlibre_sym_arbre(f)), variables{i});
        for j = 1:n
            H{i, j} = diff(premiere, variables{j});
        end
    end
end
