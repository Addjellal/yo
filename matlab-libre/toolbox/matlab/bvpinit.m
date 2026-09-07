function solinit = bvpinit(x, yinit, varargin)
%BVPINIT Devinette initiale pour BVP4C.
%   SOLINIT = BVPINIT(X,YINIT) construit la structure que BVP4C attend :
%   un maillage X et une première estimation de la solution. YINIT peut
%   être un vecteur constant — la même valeur partout — ou une poignée de
%   fonction rendant la valeur en un point.
%   SOLINIT = BVPINIT(X,YINIT,PARAMETRES) ajoute des paramètres inconnus.
%
%   Un problème aux limites n'a pas toujours une solution, et peut en
%   avoir plusieurs. La devinette n'est donc pas un détail de mise en
%   route : c'est elle qui décide vers laquelle des solutions le solveur
%   converge, et si le poutre flambé se courbe d'un côté ou de l'autre.
%
%   Exemple :
%      solinit = bvpinit(linspace(0, 1, 11), [0 0]);
%      size(solinit.y)                 % 2 11
%      s2 = bvpinit(linspace(0, pi, 5), @(x) [sin(x); cos(x)]);
%
%   Voir aussi BVP4C, DEVAL, ODE45.
    x = double(x(:))';
    if isa(yinit, 'function_handle')
        premier = yinit(x(1));
        y = zeros(numel(premier), numel(x));
        for k = 1:numel(x)
            v = yinit(x(k));
            y(:, k) = v(:);
        end
    else
        yinit = double(yinit(:));
        y = repmat(yinit, 1, numel(x));
    end
    solinit = struct('x', x, 'y', y);
    if ~isempty(varargin)
        solinit.parameters = double(varargin{1}(:));
    end
end
