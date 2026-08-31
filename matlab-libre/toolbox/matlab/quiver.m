function H = quiver(varargin)
%QUIVER Champ de vecteurs.
%   QUIVER(X,Y,U,V) trace une flèche partant de chaque point (X,Y) et
%   portant le vecteur (U,V). X, Y, U et V ont la même taille.
%
%   QUIVER(U,V) place les flèches aux nœuds d'une grille entière.
%
%   QUIVER(...,ECHELLE) multiplie la longueur des flèches par ECHELLE.
%   Par défaut, elles sont mises à l'échelle de façon à ne pas se
%   chevaucher. QUIVER(...,0) les trace à leur longueur vraie, sans
%   aucune mise à l'échelle : c'est ce qu'il faut quand la longueur a un
%   sens physique.
%
%   QUIVER(...,STYLE) prend une chaîne de style, comme PLOT.
%
%   H = QUIVER(...) rend les poignées.
%
%   Exemples :
%      [X, Y] = meshgrid(-2:0.4:2);
%      quiver(X, Y, -Y, X);                  % un champ tournant
%
%      Z = X .* exp(-X.^2 - Y.^2);
%      [DX, DY] = gradient(Z, 0.4);
%      contour(X, Y, Z); hold on; quiver(X, Y, DX, DY); hold off
%
%   Voir aussi QUIVER3, COMPASS, FEATHER, CONTOUR, GRADIENT, STREAMLINE.
    style = '';
    entrees = varargin;
    if ~isempty(entrees) && (ischar(entrees{end}) || isstring(entrees{end}))
        style = char(entrees{end});
        entrees = entrees(1:end - 1);
    end
    echelle = [];
    if numel(entrees) == 3 || numel(entrees) == 5
        echelle = entrees{end};
        entrees = entrees(1:end - 1);
    end
    if numel(entrees) == 2
        u = entrees{1};
        v = entrees{2};
        [x, y] = meshgrid(1:size(u, 2), 1:size(u, 1));
    elseif numel(entrees) == 4
        x = entrees{1};
        y = entrees{2};
        u = entrees{3};
        v = entrees{4};
    else
        error('MATLAB:quiver:NotEnoughInputs', 'Not enough input arguments.');
    end
    x = x(:); y = y(:); u = u(:); v = v(:);
    if isempty(echelle)
        % L'echelle par defaut : la plus longue fleche fait la taille
        % d'une maille, comme dans MATLAB.
        longueurs = sqrt(u .^ 2 + v .^ 2);
        maille = matlibre_pas_grille(x, y);
        maximum = max(longueurs);
        if maximum > 0
            echelle = 0.9 * maille / maximum;
        else
            echelle = 1;
        end
    elseif echelle == 0
        echelle = 1;
    end
    if isempty(style)
        style = 'b';
    end
    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    pointe = 0.3 * echelle * max(sqrt(u .^ 2 + v .^ 2));
    H = [];
    for k = 1:numel(x)
        [tx, ty] = matlibre_fleche(x(k), y(k), echelle * u(k), echelle * v(k), pointe);
        H(end + 1) = plot(tx, ty, style);      %#ok<AGROW>
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
