function varargout = gradient(F, varargin)
%GRADIENT Gradient numérique.
%   FX = GRADIENT(F) où F est un vecteur rend ses différences, prises au
%   centre à l'intérieur et d'un seul côté aux deux bouts. C'est la
%   dérivée approchée, avec le même nombre de points que F — au contraire
%   de DIFF, qui en rend un de moins.
%
%   [FX,FY] = GRADIENT(F) où F est une matrice rend les deux dérivées
%   partielles. FX est la dérivée dans le sens des colonnes — l'axe des
%   abscisses —, FY dans le sens des lignes.
%
%   [...] = GRADIENT(F,H) prend un pas H entre les points.
%   [...] = GRADIENT(F,HX,HY) prend un pas par direction. HX et HY
%   peuvent être des vecteurs de coordonnées plutôt que des pas
%   constants ; les différences sont alors prises sur les écarts réels.
%
%   Aux deux extrémités, la différence est décentrée sur un seul
%   intervalle : elle est d'ordre un, alors que l'intérieur est d'ordre
%   deux. C'est la règle de MATLAB.
%
%   Exemples :
%      gradient([1 4 9 16 25])         % [3 4 6 8 9], proche de 2x
%      gradient((0:0.1:1).^2, 0.1)     % proche de 2x
%
%      [X, Y] = meshgrid(-2:0.2:2);
%      Z = X .* exp(-X.^2 - Y.^2);
%      [dx, dy] = gradient(Z, 0.2);
%      contour(X, Y, Z); hold on; quiver(X, Y, dx, dy); hold off
%
%   Voir aussi DIFF, DEL2, DIVERGENCE, CURL, SURFNORM, CONTOUR.
    F = double(F);
    if isvector(F)
        forme = size(F);
        v = F(:);
        h = pasDe(varargin, 1, numel(v));
        varargout{1} = reshape(deriveeCentree(v, h), forme);
        return;
    end
    [lignes, colonnes] = size(F);
    hx = pasDe(varargin, 1, colonnes);
    if numel(varargin) >= 2
        hy = pasDe(varargin, 2, lignes);
    else
        hy = pasDe(varargin, 1, lignes);
    end
    % La derivee selon x : le long de chaque ligne.
    FX = zeros(lignes, colonnes);
    for i = 1:lignes
        FX(i, :) = deriveeCentree(F(i, :)', hx)';
    end
    varargout{1} = FX;
    if nargout >= 2
        FY = zeros(lignes, colonnes);
        for j = 1:colonnes
            FY(:, j) = deriveeCentree(F(:, j), hy);
        end
        varargout{2} = FY;
    end
    % Les dimensions au-dela de deux ne sont pas traitees : MatLibre rend
    % zero pour elles plutot que d'echouer.
    for k = 3:nargout
        varargout{k} = zeros(lignes, colonnes);
    end
end

function h = pasDe(arguments, rang, n)
%PASDE Le pas de la direction demandée, constant ou lu dans un vecteur.
    if numel(arguments) < rang || isempty(arguments{rang})
        h = (1:n)';
        return;
    end
    a = double(arguments{rang});
    if isscalar(a)
        h = (0:n - 1)' * a;
    else
        h = a(:);
        if numel(h) ~= n
            error('MATLAB:gradient:SizeMismatch', ...
                  'The coordinate vector must match the size of F.');
        end
    end
end

function d = deriveeCentree(v, x)
%DERIVEECENTREE Différences centrées à l'intérieur, décentrées aux bords.
    n = numel(v);
    d = zeros(n, 1);
    if n == 1
        return;
    end
    d(1) = (v(2) - v(1)) / (x(2) - x(1));
    d(n) = (v(n) - v(n - 1)) / (x(n) - x(n - 1));
    for k = 2:n - 1
        d(k) = (v(k + 1) - v(k - 1)) / (x(k + 1) - x(k - 1));
    end
end
