function H = meshc(varargin)
%MESHC Maillage d'une surface, avec ses lignes de niveau en dessous.
%   MESHC(X,Y,Z) trace le maillage de la surface et, dans le plan du bas,
%   ses lignes de niveau. MESHC(Z) prend une grille entière.
%
%   H = MESHC(...) rend les poignées.
%
%   Le rendu de MatLibre est plan : la surface est montrée en couleurs,
%   et les lignes de niveau par-dessus, ce qui met exactement la même
%   information sous les yeux.
%
%   Exemples :
%      meshc(peaks(30));
%      [X, Y] = meshgrid(-2:0.2:2);
%      meshc(X, Y, X .* exp(-X.^2 - Y.^2));
%
%   Voir aussi MESH, SURFC, CONTOUR, MESHZ, PEAKS.
    H = surf(varargin{:});
    hold('on');
    contour(varargin{:});
    hold('off');
    if nargout == 0
        clear H;
    end
end
