function H = surfc(varargin)
%SURFC Surface, avec ses lignes de niveau en dessous.
%   SURFC(X,Y,Z) trace la surface (SURF) et, dans le plan du bas de l'axe,
%   ses lignes de niveau, chacune de la couleur de son niveau. SURFC(Z)
%   prend une grille entière.
%
%   H = SURFC(...) rend la poignée de la surface.
%
%   Exemples :
%      surfc(peaks(30));
%      [X, Y] = meshgrid(-2:0.2:2);
%      surfc(X, Y, X.^2 - Y.^2);
%
%   Voir aussi SURF, MESHC, CONTOUR, SURFL, PEAKS.
    H = surf(varargin{:});
    tenu = ishold();
    hold('on');
    matlibre_courbes_dessous(varargin);
    if ~tenu
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
