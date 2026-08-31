function H = trimesh(triangles, x, y, z, varargin)
%TRIMESH Maillage d'une triangulation.
%   TRIMESH(T,X,Y,Z) trace les arêtes des triangles de T, dont les
%   sommets sont (X,Y,Z). C'est TRISURF sans le remplissage : on voit à
%   travers.
%
%   TRIMESH(T,X,Y) trace la triangulation à plat.
%
%   TRIMESH(...,'Color',C) fixe la couleur des arêtes.
%
%   H = TRIMESH(...) rend les poignées.
%
%   Le rendu de MatLibre est plan, comme pour TRISURF.
%
%   Exemples :
%      x = rand(30, 1); y = rand(30, 1);
%      T = delaunay(x, y);
%      trimesh(T, x, y);
%
%   Voir aussi TRISURF, DELAUNAY, VORONOI, PATCH, PLOT.
    if nargin < 4
        z = [];
    end
    couleur = 'b';
    k = 1;
    while k + 1 <= numel(varargin)
        if strcmpi(char(varargin{k}), 'color')
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
        indices = [triangles(f, :), triangles(f, 1)];
        H(end + 1) = plot(x(indices), y(indices), 'Color', couleur);   %#ok<AGROW>
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
