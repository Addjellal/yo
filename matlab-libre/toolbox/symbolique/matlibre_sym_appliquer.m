function r = matlibre_sym_appliquer(nom, a)
%MATLIBRE_SYM_APPLIQUER Applique une fonction élémentaire à une expression.
%   Un tableau de SYM, ou de nombres, est traité élément par élément.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if numel(a) == 1
        r = sym(symsimplify(symfun(nom, matlibre_sym_arbre(a))));
        return
    end
    r = repmat(sym(0), size(a));
    for k = 1:numel(a)
        r(k) = sym(symsimplify(symfun(nom, matlibre_sym_arbre(a(k)))));
    end
end
