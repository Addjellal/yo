function L = del2(U, varargin)
%DEL2 Laplacien discret, divisé par quatre.
%   L = DEL2(U) rend le laplacien discret de U : en chaque point, la
%   moyenne des voisins moins le point lui-même. C'est la convention de
%   MATLAB, qui divise le laplacien par le nombre de directions fois deux
%   — quatre pour une matrice, deux pour un vecteur — de sorte que
%
%      L = (d2u/dx2 + d2u/dy2) / 4
%
%   L = DEL2(U,H) prend un pas H entre les points.
%   L = DEL2(U,HX,HY) prend un pas par direction ; HX et HY peuvent être
%   des vecteurs de coordonnées.
%
%   Aux bords, la valeur est extrapolée depuis l'intérieur, comme le fait
%   MATLAB : le laplacien y est moins sûr qu'ailleurs.
%
%   Une fonction harmonique — la partie réelle d'une fonction
%   holomorphe, le potentiel dans le vide — a un laplacien nul : c'est le
%   moyen de vérifier une solution d'équation de Laplace.
%
%   Exemples :
%      del2([1 4 9 16 25])              % 1 : la derivee seconde de x^2,
%                                       % divisee par deux
%      [X, Y] = meshgrid(-2:0.2:2);
%      L = del2(X.^2 - Y.^2, 0.2);
%      max(max(abs(L(2:end-1, 2:end-1))))     % nul : la fonction est
%                                             % harmonique
%
%   Voir aussi GRADIENT, DIFF, DIVERGENCE, LAPLACIAN.
    U = double(U);
    if isvector(U)
        forme = size(U);
        v = U(:);
        h = 1;
        if numel(varargin) >= 1 && ~isempty(varargin{1})
            if isscalar(varargin{1})
                h = varargin{1};
            end
        end
        n = numel(v);
        d = zeros(n, 1);
        for k = 2:n - 1
            d(k) = (v(k + 1) - 2 * v(k) + v(k - 1)) / (2 * h ^ 2);
        end
        if n > 3
            d(1) = 2 * d(2) - d(3);
            d(n) = 2 * d(n - 1) - d(n - 2);
        elseif n == 3
            d(1) = d(2);
            d(3) = d(2);
        end
        L = reshape(d, forme);
        return;
    end
    hx = 1;
    hy = 1;
    if numel(varargin) >= 1 && isscalar(varargin{1})
        hx = varargin{1};
        hy = hx;
    end
    if numel(varargin) >= 2 && isscalar(varargin{2})
        hy = varargin{2};
    end
    [lignes, colonnes] = size(U);
    L = zeros(lignes, colonnes);
    for i = 2:lignes - 1
        for j = 2:colonnes - 1
            L(i, j) = ((U(i, j + 1) - 2 * U(i, j) + U(i, j - 1)) / hx ^ 2 + ...
                       (U(i + 1, j) - 2 * U(i, j) + U(i - 1, j)) / hy ^ 2) / 4;
        end
    end
    % Les bords : extrapolation lineaire depuis l'interieur.
    if colonnes > 3
        L(:, 1) = 2 * L(:, 2) - L(:, 3);
        L(:, colonnes) = 2 * L(:, colonnes - 1) - L(:, colonnes - 2);
    end
    if lignes > 3
        L(1, :) = 2 * L(2, :) - L(3, :);
        L(lignes, :) = 2 * L(lignes - 1, :) - L(lignes - 2, :);
    end
end
