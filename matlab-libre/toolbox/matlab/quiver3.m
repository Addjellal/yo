function H = quiver3(varargin)
%QUIVER3 Champ de vecteurs en trois dimensions.
%   QUIVER3(X,Y,Z,U,V,W) trace une flèche partant de chaque point
%   (X,Y,Z) et portant le vecteur (U,V,W).
%
%   QUIVER3(Z,U,V,W) place les flèches sur la surface Z.
%
%   QUIVER3(...,ECHELLE) et QUIVER3(...,STYLE) suivent la même règle que
%   QUIVER.
%
%   H = QUIVER3(...) rend les poignées.
%
%   Le rendu de MatLibre est plan : les flèches sont projetées en
%   laissant tomber la troisième coordonnée, comme le fait PLOT3.
%
%   Exemples :
%      [X, Y] = meshgrid(-2:0.5:2);
%      Z = X .* exp(-X.^2 - Y.^2);
%      [U, V, W] = surfnorm(X, Y, Z);
%      quiver3(X, Y, Z, U, V, W);
%
%   Voir aussi QUIVER, PLOT3, SURFNORM, CONTOUR3.
    entrees = varargin;
    style = '';
    if ~isempty(entrees) && (ischar(entrees{end}) || isstring(entrees{end}))
        style = char(entrees{end});
        entrees = entrees(1:end - 1);
    end
    echelle = [];
    if numel(entrees) == 5 || numel(entrees) == 7
        echelle = entrees{end};
        entrees = entrees(1:end - 1);
    end
    if numel(entrees) == 4
        z = entrees{1};
        [x, y] = meshgrid(1:size(z, 2), 1:size(z, 1));
        u = entrees{2};
        v = entrees{3};
    elseif numel(entrees) == 6
        x = entrees{1};
        y = entrees{2};
        u = entrees{4};
        v = entrees{5};
    else
        error('MATLAB:quiver3:NotEnoughInputs', 'Not enough input arguments.');
    end
    appel = {x, y, u, v};
    if ~isempty(echelle)
        appel{end + 1} = echelle;
    end
    if ~isempty(style)
        appel{end + 1} = style;
    end
    H = quiver(appel{:});
    if nargout == 0
        clear H;
    end
end
