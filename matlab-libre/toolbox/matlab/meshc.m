function H = meshc(varargin)
%MESHC Maillage d'une surface, avec ses lignes de niveau en dessous.
%   MESHC(X,Y,Z) trace le maillage de la surface (MESH) et, dans le plan
%   du bas de l'axe, ses lignes de niveau, chacune de la couleur de son
%   niveau. MESHC(Z) prend une grille entière.
%
%   H = MESHC(...) rend la poignée du maillage.
%
%   Exemples :
%      meshc(peaks(30));
%      [X, Y] = meshgrid(-2:0.2:2);
%      meshc(X, Y, X .* exp(-X.^2 - Y.^2));
%
%   Voir aussi MESH, SURFC, CONTOUR, MESHZ, PEAKS.
    H = mesh(varargin{:});
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
