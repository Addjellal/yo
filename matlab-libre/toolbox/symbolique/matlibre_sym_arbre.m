function arbre = matlibre_sym_arbre(valeur)
%MATLIBRE_SYM_ARBRE L'arbre d'expression d'une valeur quelconque.
%   Un objet SYM rend son arbre, un nombre devient une constante, un nom
%   une variable, et un arbre se rend tel quel.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isa(valeur, 'sym')
        arbre = valeur.arbre;
    elseif iscell(valeur)
        arbre = valeur;
    elseif ischar(valeur) || isstring(valeur)
        arbre = {'var', char(valeur)};
    elseif isnumeric(valeur) && isscalar(valeur)
        arbre = {'num', double(valeur)};
    else
        error('symbolic:sym:Conversion', ...
              'Cette valeur ne se convertit pas en expression symbolique.');
    end
end
