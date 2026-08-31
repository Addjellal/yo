function H = rectangle(varargin)
%RECTANGLE Rectangle, éventuellement arrondi ou elliptique.
%   RECTANGLE('Position',[X Y L H]) trace un rectangle dont le coin
%   inférieur gauche est en (X,Y), de largeur L et de hauteur H.
%
%   RECTANGLE(...,'Curvature',C) arrondit les coins. C va de 0 — des
%   coins droits — à 1 — l'ellipse inscrite. C peut être un couple
%   [horizontal, vertical] pour arrondir différemment les deux
%   directions.
%
%   RECTANGLE(...,'FaceColor',C) remplit ; sans elle, seul le contour est
%   tracé. 'EdgeColor' et 'LineWidth' règlent le contour.
%
%   RECTANGLE sans argument trace le carré unité.
%
%   H = RECTANGLE(...) rend la poignée.
%
%   C'est ainsi qu'on dessine un cercle dans MATLAB : un rectangle carré
%   de courbure un.
%
%   Exemples :
%      rectangle('Position', [0 0 2 1]);
%      rectangle('Position', [0 0 2 2], 'Curvature', 1);    % un cercle
%      rectangle('Position', [1 1 3 2], 'Curvature', 0.3, ...
%                'FaceColor', [0.9 0.9 0.5]);
%      axis('equal');
%
%   Voir aussi PATCH, FILL, LINE, PLOT, AXIS.
    position = [0 0 1 1];
    courbure = [0 0];
    couleurFace = [];
    couleurBord = 'k';
    epaisseur = 1;
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'position'
                position = varargin{k + 1};
            case 'curvature'
                courbure = varargin{k + 1};
                if isscalar(courbure)
                    courbure = [courbure courbure];
                end
            case 'facecolor'
                couleurFace = varargin{k + 1};
            case 'edgecolor'
                couleurBord = varargin{k + 1};
            case 'linewidth'
                epaisseur = varargin{k + 1};
            case {'linestyle', 'tag', 'parent'}
                % acceptes et sans effet
            otherwise
                error('MATLAB:rectangle:BadOption', 'Unknown property ''%s''.', nom);
        end
        k = k + 2;
    end
    x = position(1);
    y = position(2);
    largeur = position(3);
    hauteur = position(4);
    [px, py] = contourArrondi(x, y, largeur, hauteur, courbure);

    aEffacer = ishold();
    hold('on');
    H = [];
    if ~isempty(couleurFace) && ~(ischar(couleurFace) && strcmpi(couleurFace, 'none'))
        H(end + 1) = fill(px, py, 'FaceColor', couleurFace);
    end
    if ~(ischar(couleurBord) && strcmpi(couleurBord, 'none'))
        H(end + 1) = plot(px, py, 'Color', couleurBord, 'LineWidth', epaisseur);
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end

function [px, py] = contourArrondi(x, y, largeur, hauteur, courbure)
%CONTOURARRONDI Le contour du rectangle, coins arrondis compris.
    cx = max(0, min(1, courbure(1))) * largeur / 2;
    cy = max(0, min(1, courbure(2))) * hauteur / 2;
    if cx == 0 && cy == 0
        px = [x, x + largeur, x + largeur, x, x];
        py = [y, y, y + hauteur, y + hauteur, y];
        return;
    end
    t = linspace(0, pi / 2, 20);
    % Les quatre quarts d'ellipse, dans le sens direct.
    px = [x + largeur - cx + cx * cos(t), ...
          x + cx - cx * sin(t), ...
          x + cx - cx * cos(t), ...
          x + largeur - cx + cx * sin(t)];
    py = [y + hauteur - cy + cy * sin(t), ...
          y + hauteur - cy + cy * cos(t), ...
          y + cy - cy * sin(t), ...
          y + cy - cy * cos(t)];
    px = [px, px(1)];
    py = [py, py(1)];
end
