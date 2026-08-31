function H = fcontour(fonction, intervalle, varargin)
%FCONTOUR Lignes de niveau d'une fonction donnée par une poignée.
%   FCONTOUR(F) trace les lignes de niveau de F sur [-5 5] x [-5 5].
%
%   FCONTOUR(F,[A B]) emploie le carré [A B] x [A B].
%   FCONTOUR(F,[A B C D]) emploie le rectangle donné.
%
%   FCONTOUR(...,'LevelList',L) impose les niveaux.
%   FCONTOUR(...,'MeshDensity',N) change la finesse de la grille, 80 par
%   défaut. Une grille trop grossière donne des lignes anguleuses.
%
%   H = FCONTOUR(...) rend la poignée.
%
%   Exemples :
%      fcontour(@(x, y) x.^2 + y.^2, [-2 2]);
%      fcontour(@(x, y) sin(x) + cos(y), [-pi pi], 'LevelList', -1:0.5:1);
%
%   Voir aussi CONTOUR, FSURF, FMESH, FPLOT, EZCONTOUR.
    if nargin < 2 || isempty(intervalle)
        intervalle = [-5 5 -5 5];
    end
    if numel(intervalle) == 2
        intervalle = [intervalle, intervalle];
    end
    densite = 80;
    niveaux = [];
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'meshdensity')
            densite = varargin{k + 1};
        elseif strcmp(nom, 'levellist')
            niveaux = varargin{k + 1};
        end
        k = k + 2;
    end
    [X, Y] = meshgrid(linspace(intervalle(1), intervalle(2), densite), ...
                      linspace(intervalle(3), intervalle(4), densite));
    Z = matlibre_evaluer_grille(fonction, X, Y);
    if isempty(niveaux)
        [~, H] = contour(X, Y, Z);
    else
        [~, H] = contour(X, Y, Z, niveaux);
    end
    if nargout == 0
        clear H;
    end
end
