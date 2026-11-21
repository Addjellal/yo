function H = trimesh(triangles, x, y, z, varargin)
%TRIMESH Maillage défini par une triangulation.
%   TRIMESH(T,X,Y,Z) trace les arêtes des triangles de T — chaque ligne
%   donne les trois indices des sommets d'une face —, colorées par la
%   moyenne des Z de leur face, sur des faces blanches, comme MESH.
%   TRIMESH(T,X,Y) trace la triangulation à plat.
%   TRIMESH(...,'EdgeColor',C,...) ou TRIMESH(...,'Color',C) règle la
%   couleur des arêtes.
%
%   H = TRIMESH(...) rend la poignée du maillage.
%
%   Exemples :
%      [x, y] = meshgrid(1:4);
%      T = delaunay(x(:), y(:));
%      trimesh(T, x(:), y(:), sin(x(:)) .* cos(y(:)));
%
%   Voir aussi TRISURF, DELAUNAY, PATCH, MESH.
    plan = nargin < 4 || ischar(z) || isstring(z);
    if plan
        if nargin >= 4
            varargin = [{z}, varargin];
        end
        z = zeros(size(x));
    end
    reglages = {};
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'color')
            reglages(end + 1:end + 2) = {'EdgeColor', varargin{k + 1}};
        else
            reglages(end + 1:end + 2) = varargin(k:k + 1);
        end
    end
    F = triangles';
    if plan
        H = fill3(x(F), y(F), z(F), z(F), 'FaceColor', 'w', 'EdgeColor', [0 0.447 0.741], ...
                  reglages{:});
        view(2);
    else
        H = fill3(x(F), y(F), z(F), z(F), 'FaceColor', 'w', 'EdgeColor', 'flat', reglages{:});
    end
    if nargout == 0
        clear H;
    end
end
