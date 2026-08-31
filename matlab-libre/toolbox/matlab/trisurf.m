function H = trisurf(triangles, x, y, z, varargin)
%TRISURF Surface définie par une triangulation.
%   TRISURF(T,X,Y,Z) trace la surface dont les sommets sont (X,Y,Z) et
%   les faces les triangles de T : chaque ligne de T donne les trois
%   indices des sommets d'une face.
%
%   TRISURF(T,X,Y) trace la triangulation à plat.
%
%   TRISURF(...,'FaceColor',C) fixe la couleur des faces.
%
%   H = TRISURF(...) rend les poignées des faces.
%
%   Le rendu de MatLibre est plan : les triangles sont dessinés dans le
%   plan des X et des Y, remplis d'une couleur unie.
%
%   Exemples :
%      x = rand(30, 1); y = rand(30, 1);
%      T = delaunay(x, y);
%      trisurf(T, x, y, x.^2 + y.^2);
%
%   Voir aussi TRIMESH, DELAUNAY, PATCH, FILL, VORONOI.
    if nargin < 4
        z = [];
    end
    couleur = [0.6 0.8 1];
    k = 1;
    while k + 1 <= numel(varargin)
        if strcmpi(char(varargin{k}), 'facecolor')
            couleur = varargin{k + 1};
        end
        k = k + 2;
    end
    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    H = [];
    for f = 1:size(triangles, 1)
        indices = triangles(f, :);
        H(end + 1) = fill(x(indices), y(indices), 'FaceColor', couleur);  %#ok<AGROW>
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
