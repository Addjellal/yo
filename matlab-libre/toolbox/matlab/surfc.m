function H = surfc(varargin)
%SURFC Surface, avec ses lignes de niveau en dessous.
%   SURFC(X,Y,Z) trace la surface et, dans le plan du bas, ses lignes de
%   niveau. SURFC(Z) prend une grille entière.
%
%   H = SURFC(...) rend les poignées.
%
%   Le rendu de MatLibre est plan : la surface est montrée en couleurs,
%   et les lignes de niveau par-dessus.
%
%   Exemples :
%      surfc(peaks(30));
%      [X, Y] = meshgrid(-2:0.2:2);
%      surfc(X, Y, X.^2 - Y.^2);
%
%   Voir aussi SURF, MESHC, CONTOUR, SURFL, PEAKS.
    H = meshc(varargin{:});
    if nargout == 0
        clear H;
    end
end
