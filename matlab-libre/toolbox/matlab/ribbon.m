function H = ribbon(varargin)
%RIBBON Colonnes dessinées en rubans côte à côte.
%   RIBBON(Y) trace une bande par colonne de Y, les bandes étant rangées
%   côte à côte dans la profondeur. RIBBON(X,Y) place les points en X.
%   RIBBON(X,Y,LARGEUR) donne aux bandes la largeur voulue.
%
%   H = RIBBON(...) rend les poignées.
%
%   Le rendu de MatLibre est plan : chaque colonne est tracée comme une
%   aire décalée, ce qui donne la même lecture que la perspective de
%   MATLAB.
%
%   Exemples :
%      ribbon(peaks(20));
%
%      t = linspace(0, 2*pi, 100)';
%      ribbon([sin(t), sin(2*t), sin(3*t)]);
%
%   Voir aussi WATERFALL, AREA, MESH, SURF, PLOT3.
    if numel(varargin) >= 2 && isnumeric(varargin{2}) && ...
       ~isscalar(varargin{2})
        x = varargin{1}(:);
        Y = varargin{2};
    else
        Y = varargin{1};
        x = (1:size(Y, 1))';
    end
    if isvector(Y)
        Y = Y(:);
    end
    colonnes = size(Y, 2);
    etendue = max(Y(:)) - min(Y(:));
    if etendue == 0
        etendue = 1;
    end
    pas = etendue / 2;
    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    H = [];
    for k = colonnes:-1:1
        decalage = (k - 1) * pas;
        H(end + 1) = fill([x; flipud(x)], ...
                          [Y(:, k) + decalage; repmat(min(Y(:)) + decalage, numel(x), 1)], ...
                          'FaceColor', matlibre_couleur_secteur(k));    %#ok<AGROW>
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
