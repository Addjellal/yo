function H = trisurf(triangles, x, y, z, varargin)
%TRISURF Surface définie par une triangulation.
%   TRISURF(T,X,Y,Z) trace la surface dont les sommets sont (X,Y,Z) et
%   les faces les triangles de T : chaque ligne de T donne les trois
%   indices des sommets d'une face. Chaque face prend la couleur de la
%   moyenne des Z de ses sommets, par la palette ; les arêtes sont noires.
%   TRISURF(T,X,Y,Z,C) colore les sommets par C.
%   TRISURF(...,'FaceColor',C,'EdgeColor',C2,...) règle les couleurs.
%
%   H = TRISURF(...) rend la poignée de la surface.
%
%   Exemples :
%      x = rand(30, 1); y = rand(30, 1);
%      T = delaunay(x, y);
%      trisurf(T, x, y, x.^2 + y.^2);
%
%   Voir aussi TRIMESH, DELAUNAY, PATCH, FILL3, SURF.
    if nargin < 4 || ischar(z) || isstring(z)
        if nargin >= 4
            varargin = [{z}, varargin];
        end
        z = zeros(size(x));
    end
    couleurs = z;
    if ~isempty(varargin) && isnumeric(varargin{1})
        couleurs = varargin{1};
        varargin = varargin(2:end);
    end
    F = triangles';
    H = fill3(x(F), y(F), z(F), couleurs(F), varargin{:});
    if nargout == 0
        clear H;
    end
end
