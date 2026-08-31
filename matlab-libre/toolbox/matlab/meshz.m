function H = meshz(varargin)
%MESHZ Maillage d'une surface, avec un rideau sur les bords.
%   MESHZ(X,Y,Z) trace le maillage et y ajoute, sur tout le pourtour, un
%   rideau vertical qui descend jusqu'au plan du bas. C'est ce qui fait
%   qu'une surface ne paraît pas flotter.
%
%   MESHZ(Z) prend une grille entière.
%
%   H = MESHZ(...) rend la poignée.
%
%   Le rendu de MatLibre est plan : le rideau ne se voit pas, et MESHZ
%   donne la même image que MESH.
%
%   Exemples :
%      meshz(peaks(30));
%
%   Voir aussi MESH, MESHC, SURF, WATERFALL.
    H = surf(varargin{:});
    if nargout == 0
        clear H;
    end
end
