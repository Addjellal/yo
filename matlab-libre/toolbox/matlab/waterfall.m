function H = waterfall(varargin)
%WATERFALL Surface dessinée en rideaux, un par rangée.
%   WATERFALL(X,Y,Z) trace, pour chaque ligne de Z, la courbe de ses
%   valeurs le long de X, à la profondeur Y de sa ligne, et la referme
%   jusqu'au plus bas de Z : une suite de rideaux blancs aux bords
%   colorés par leur hauteur, comme dans MATLAB. C'est la façon de montrer
%   une famille de signaux — un spectre au fil du temps — sans les
%   superposer.
%
%   WATERFALL(Z) prend une grille entière.
%
%   H = WATERFALL(...) rend la poignée.
%
%   Exemples :
%      waterfall(peaks(20));
%
%      t = linspace(0, 1, 200);
%      S = zeros(8, 200);
%      for k = 1:8, S(k, :) = sin(2*pi*k*t) / k; end
%      waterfall(S);
%
%   Voir aussi RIBBON, MESH, SURF, PLOT3, STACKEDPLOT.
    numeriques = varargin(cellfun(@isnumeric, varargin));
    if numel(numeriques) >= 3
        [X, Y, Z] = numeriques{1:3};
        if ~isvector(X)
            X = X(1, :);
        end
        if ~isvector(Y)
            Y = Y(:, 1);
        end
    else
        Z = numeriques{1};
        X = 1:size(Z, 2);
        Y = 1:size(Z, 1);
    end
    X = X(:);
    Y = Y(:);
    [m, n] = size(Z);
    bas = min(Z(:));
    % Un rideau par ligne de Z : une face par colonne de ces matrices.
    PX = [X(1); X; X(end)] * ones(1, m);
    PY = ones(n + 2, 1) * Y';
    PZ = [bas * ones(1, m); Z'; bas * ones(1, m)];
    H = fill3(PX, PY, PZ, mean(Z, 2), 'FaceColor', 'w', 'EdgeColor', 'flat');
    if nargout == 0
        clear H;
    end
end
