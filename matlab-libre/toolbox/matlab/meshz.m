function H = meshz(varargin)
%MESHZ Maillage d'une surface, avec un rideau sur les bords.
%   MESHZ(X,Y,Z) trace le maillage et y ajoute, sur tout le pourtour, un
%   rideau vertical qui descend jusqu'au plus bas de la surface. C'est ce
%   qui fait qu'une surface ne paraît pas flotter. Comme dans MATLAB, le
%   rideau est fait en bordant la grille d'une rangée de sommets au plus
%   bas.
%
%   MESHZ(Z) prend une grille entière.
%
%   H = MESHZ(...) rend la poignée.
%
%   Exemples :
%      meshz(peaks(30));
%
%   Voir aussi MESH, MESHC, SURF, WATERFALL.
    numeriques = varargin(cellfun(@isnumeric, varargin));
    reste = varargin(numel(numeriques) + 1:end);
    if numel(numeriques) >= 3
        [X, Y, Z] = numeriques{1:3};
        if isvector(X) && isvector(Y)
            [X, Y] = meshgrid(X, Y);
        end
    else
        Z = numeriques{1};
        [X, Y] = meshgrid(1:size(Z, 2), 1:size(Z, 1));
    end
    bas = min(Z(:));
    [m, n] = size(Z);
    % La grille bordée : une rangée de sommets au plus bas, sur le pourtour.
    X2 = [X(1, 1), X(1, :), X(1, end); X(:, 1), X, X(:, end); X(end, 1), X(end, :), X(end, end)];
    Y2 = [Y(1, 1), Y(1, :), Y(1, end); Y(:, 1), Y, Y(:, end); Y(end, 1), Y(end, :), Y(end, end)];
    Z2 = [bas * ones(1, n + 2); bas * ones(m, 1), Z, bas * ones(m, 1); bas * ones(1, n + 2)];
    H = mesh(X2, Y2, Z2, reste{:});
    if nargout == 0
        clear H;
    end
end
