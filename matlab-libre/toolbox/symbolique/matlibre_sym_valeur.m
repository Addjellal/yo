function v = matlibre_sym_valeur(x)
%MATLIBRE_SYM_VALEUR La valeur numérique d'un SYM, d'un nombre ou d'un
%   arbre constant.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isnumeric(x)
        v = double(x);
        return
    end
    v = symeval(matlibre_sym_arbre(x));
end
