function H = fill3(x, y, z, couleur, varargin)
%FILL3 Polygones remplis dans l'espace.
%   FILL3(X,Y,Z,C) trace le polygone dont les sommets sont (X,Y,Z),
%   rempli de la couleur C. Si X, Y et Z sont des matrices, chaque
%   colonne donne un polygone.
%
%   FILL3(...,'Name',valeur) accepte les mêmes propriétés que FILL.
%
%   H = FILL3(...) rend les poignées.
%
%   Le rendu de MatLibre est plan : Z est laissé de côté, et le polygone
%   est dessiné dans le plan des X et des Y, comme le fait PLOT3.
%
%   Exemples :
%      fill3([0 1 1 0], [0 0 1 1], [0 0 1 1], 'c');
%      fill3([0 1 0.5], [0 0 1], [0 0 1], [0.9 0.7 0.2]);
%
%   Voir aussi FILL, PATCH, PLOT3, SURF, AREA.
    H = fill(x, y, 'FaceColor', couleur, varargin{:});
    if nargout == 0
        clear H;
    end
end
