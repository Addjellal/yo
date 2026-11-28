function H = ribbon(varargin)
%RIBBON Colonnes dessinées en rubans côte à côte.
%   RIBBON(Y) trace une bande par colonne de Y : la bande K est posée en
%   X = K, large de 0,75, et suit les valeurs de sa colonne le long de
%   l'axe des Y, à la hauteur Z qu'elles donnent ; chaque bande prend sa
%   couleur dans la palette. RIBBON(X,Y) place les points en X.
%   RIBBON(X,Y,LARGEUR) donne aux bandes la largeur voulue.
%
%   H = RIBBON(...) rend la poignée de la première bande.
%
%   Exemples :
%      ribbon(peaks(20));
%
%      t = linspace(0, 2*pi, 100)';
%      ribbon([sin(t), sin(2*t), sin(3*t)]);
%
%   Voir aussi WATERFALL, AREA, MESH, SURF, PLOT3.
    largeur = 0.75;
    if numel(varargin) >= 2 && isnumeric(varargin{2}) && ~isscalar(varargin{2})
        x = varargin{1}(:);
        Y = varargin{2};
        if numel(varargin) >= 3
            largeur = varargin{3};
        end
    else
        Y = varargin{1};
        if isvector(Y)
            Y = Y(:);
        end
        x = (1:size(Y, 1))';
        if numel(varargin) >= 2
            largeur = varargin{2};
        end
    end
    if isvector(Y)
        Y = Y(:);
    end
    colonnes = size(Y, 2);
    tenu = ishold();
    H = [];
    for k = 1:colonnes
        Xg = [(k - largeur / 2) * ones(size(x)), (k + largeur / 2) * ones(size(x))];
        Yg = [x, x];
        Zg = [Y(:, k), Y(:, k)];
        h = surf(Xg, Yg, Zg, k * ones(size(Zg)));
        if isempty(H)
            H = h;
        end
        hold('on');
    end
    if ~tenu
        hold('off');
    end
    if colonnes > 1
        clim([1 colonnes]);
    end
    if nargout == 0
        clear H;
    end
end
