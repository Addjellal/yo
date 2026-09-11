function p = ancestor(h, genre, varargin)
%ANCESTOR Ancêtre d'un objet graphique, d'un type donné.
%   P = ANCESTOR(H,TYPE) rend la poignée de l'ancêtre de H dont le type
%   est TYPE — 'axes' ou 'figure'. Si H est déjà de ce type, c'est H qui
%   est rendu. S'il n'y a pas d'ancêtre de ce type, P est vide.
%
%   TYPE peut être une cellule : le premier type rencontré en remontant
%   l'emporte.
%
%   Remonter l'arbre est ce qui permet d'agir sur la figure d'une courbe
%   sans l'avoir gardée : « set(ancestor(h,'figure'),'Name','x') ».
%
%   Exemple :
%      figure; courbe = plot(1:3);
%      strcmp(get(ancestor(courbe, 'axes'), 'Type'), 'axes')     % 1
%      strcmp(get(ancestor(courbe, 'figure'), 'Type'), 'figure') % 1
%
%   Voir aussi GCA, GCF, FINDOBJ, GET.
    p = [];
    if nargin < 2
        error('MATLAB:minrhs', 'ANCESTOR attend un objet et un type.');
    end
    genres = cellstr(string(genre));
    courant = h;
    for tour = 1:4
        if isempty(courant) || ~isobject(courant)
            return;
        end
        typeCourant = get(courant, 'Type');
        if any(strcmpi(typeCourant, genres))
            p = courant;
            return;
        end
        courant = matlibre_parent_graphique(courant);
    end
end
