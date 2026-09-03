function variable = matlibre_sym_defaut(f)
%MATLIBRE_SYM_DEFAUT La variable qu'on sous-entend dans une expression.
%   C'est la plus proche de « x », comme dans MATLAB. Une expression sans
%   variable est dérivée par rapport à x, ce qui donne zéro.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    noms = unique(matlibre_sym_noms(matlibre_sym_arbre(f)));
    if isempty(noms)
        variable = sym('x');
        return
    end
    choisis = matlibre_sym_proches(noms, 1);
    variable = sym(choisis{1});
end
