function nom = matlibre_sym_nom(variable)
%MATLIBRE_SYM_NOM Le nom d'une variable donnée comme SYM, texte ou arbre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    arbre = matlibre_sym_arbre(variable);
    if ~strcmp(arbre{1}, 'var')
        error('symbolic:sym:Variable', ...
              'Il faut nommer une variable, non une expression.');
    end
    nom = arbre{2};
end
