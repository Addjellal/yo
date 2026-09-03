function r = matlibre_sym_appliquer(nom, a)
%MATLIBRE_SYM_APPLIQUER Applique une fonction élémentaire à une expression.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    r = sym(symsimplify(symfun(nom, matlibre_sym_arbre(a))));
end
