function H = fplot(fonction, intervalle, varargin)
%FPLOT Trace une fonction donnée par une poignée.
%   FPLOT(F) trace F sur l'intervalle [-5 5]. F est une poignée qui
%   accepte un vecteur et rend un vecteur de même taille.
%
%   FPLOT(F,[A B]) trace sur l'intervalle donné.
%
%   FPLOT(FX,FY) trace la courbe paramétrée dont l'abscisse est FX(t) et
%   l'ordonnée FY(t), t parcourant [-5 5].
%   FPLOT(FX,FY,[A B]) fixe l'intervalle du paramètre.
%
%   FPLOT(...,STYLE) prend une chaîne de style, comme PLOT.
%   FPLOT(...,'MeshDensity',N) change le nombre de points, 400 par
%   défaut.
%
%   H = FPLOT(...) rend la poignée de la courbe.
%
%   MATLAB affine le pas là où la courbe tourne vite ; MatLibre emploie
%   un pas constant, assez fin pour que la différence ne se voie pas sur
%   les fonctions usuelles. Une fonction à variation très rapide demande
%   d'augmenter 'MeshDensity'.
%
%   Exemples :
%      fplot(@(x) sin(x) ./ x, [-20 20]);
%      fplot(@sin, [0 2*pi], 'r--');
%      fplot(@(t) cos(3*t), @(t) sin(2*t), [0 2*pi]);   % une Lissajous
%
%   Voir aussi PLOT, FSURF, FCONTOUR, EZPLOT, FIMPLICIT.
    parametree = false;
    fonctionY = [];
    if nargin >= 2 && strcmp(class(intervalle), 'function_handle')
        parametree = true;
        fonctionY = intervalle;
        intervalle = [];
        if numel(varargin) >= 1 && isnumeric(varargin{1}) && numel(varargin{1}) == 2
            intervalle = varargin{1};
            varargin = varargin(2:end);
        end
    end
    if nargin < 2 || isempty(intervalle)
        intervalle = [-5 5];
    end
    densite = 400;
    style = {};
    k = 1;
    while k <= numel(varargin)
        if (ischar(varargin{k}) || isstring(varargin{k})) && ...
           strcmpi(char(varargin{k}), 'meshdensity') && k + 1 <= numel(varargin)
            densite = varargin{k + 1};
            k = k + 2;
        else
            style{end + 1} = varargin{k};    %#ok<AGROW>
            k = k + 1;
        end
    end
    t = linspace(intervalle(1), intervalle(2), densite)';
    if parametree
        x = matlibre_evaluer_sur(fonction, t);
        y = matlibre_evaluer_sur(fonctionY, t);
    else
        x = t;
        y = matlibre_evaluer_sur(fonction, t);
    end
    H = plot(x, y, style{:});
    if nargout == 0
        clear H;
    end
end
