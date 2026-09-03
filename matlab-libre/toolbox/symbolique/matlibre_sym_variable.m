function e = matlibre_sym_variable(nom)
%MATLIBRE_SYM_VARIABLE Feuille « variable » d'un arbre d'expression.
%   C'est le constructeur de bas niveau, celui qu'emploient SYMDIFF,
%   SYMINT et leurs voisines. SYM('x') fait la même chose et rend un
%   objet ; SYMVAR, lui, porte le sens de MATLAB — les variables d'une
%   expression.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    e = {'var', nom};
end
