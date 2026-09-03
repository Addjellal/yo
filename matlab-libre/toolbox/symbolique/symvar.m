function variables = symvar(expression, nombre)
%SYMVAR Variables d'une expression symbolique.
%   V = SYMVAR(F) rend, dans un tableau de SYM, les variables qui
%   apparaissent dans F, rangées par ordre alphabétique.
%   V = SYMVAR(F,N) n'en rend que N, choisies au plus près de « x » :
%   c'est la règle de MATLAB pour deviner la variable d'une dérivation
%   ou d'une résolution quand on ne la nomme pas.
%
%   Exemple :
%      syms a x
%      symvar(a * x ^ 2)              % [a, x]
%      char(symvar(a * x ^ 2, 1))     % 'x' : la plus proche de x
%
%   Voir aussi SYM, SYMS, DIFF, SOLVE.
    noms = matlibre_sym_noms(matlibre_sym_arbre(expression));
    noms = unique(noms);
    if nargin >= 2 && ~isempty(nombre)
        noms = matlibre_sym_proches(noms, round(nombre));
    end
    variables = cell(1, numel(noms));
    for k = 1:numel(noms)
        variables{k} = sym(noms{k});
    end
    if numel(variables) == 1
        variables = variables{1};
    end
end
