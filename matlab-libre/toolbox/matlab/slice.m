function H = slice(varargin)
%SLICE Coupes d'un volume, dans l'espace.
%   SLICE(V,SX,SY,SZ) coupe le volume V par les plans d'abscisses SX,
%   d'ordonnées SY et de cotes SZ, et montre chaque coupe en perspective,
%   à sa place dans le volume, colorée par les valeurs de V (CLIM). Comme
%   pour MESHGRID, la colonne J, la ligne I et la page K de V sont au
%   point (J, I, K).
%
%   SLICE(X,Y,Z,V,SX,SY,SZ) place le volume sur la grille donnée par
%   MESHGRID.
%
%   Une coupe tombe sur le plan de grille le plus proche de la position
%   demandée ; MATLAB interpole entre deux plans.
%
%   H = SLICE(...) rend une poignée par coupe.
%
%   Exemples :
%      [X, Y, Z] = meshgrid(-2:0.2:2);
%      V = X .* exp(-X.^2 - Y.^2 - Z.^2);
%      slice(X, Y, Z, V, [-1.2 0.8 2], 2, [-2 -0.2]);
%      slice(V, [], [], [5 11 17]);      % trois coupes en z
%
%   Voir aussi SURF, CONTOURSLICE, ISOSURFACE, MESHGRID, VIEW.
    entrees = varargin;
    if numel(entrees) >= 7
        [X, Y, Z, V, sx, sy, sz] = entrees{1:7};
        x = X(1, :, 1);
        y = Y(:, 1, 1)';
        z = reshape(Z(1, 1, :), 1, []);
    elseif numel(entrees) >= 4
        [V, sx, sy, sz] = entrees{1:4};
        x = 1:size(V, 2);
        y = 1:size(V, 1);
        z = 1:size(V, 3);
    else
        error('MATLAB:slice:NotEnoughInputs', 'Not enough input arguments.');
    end
    if isempty(sx) && isempty(sy) && isempty(sz)
        error('MATLAB:slice:NoSlice', 'SLICE needs at least one slice position.');
    end
    proche = @(grille, v) find(abs(grille - v) == min(abs(grille - v)), 1);
    tenu = ishold();
    H = [];
    for v = sx(:)'
        j = proche(x, v);
        [Yc, Zc] = meshgrid(y, z);
        C = reshape(V(:, j, :), numel(y), numel(z))';
        H(end + 1) = surf(x(j) * ones(size(Yc)), Yc, Zc, C); %#ok<AGROW>
        hold('on');
    end
    for v = sy(:)'
        i = proche(y, v);
        [Xc, Zc] = meshgrid(x, z);
        C = reshape(V(i, :, :), numel(x), numel(z))';
        H(end + 1) = surf(Xc, y(i) * ones(size(Xc)), Zc, C); %#ok<AGROW>
        hold('on');
    end
    for v = sz(:)'
        k = proche(z, v);
        [Xc, Yc] = meshgrid(x, y);
        H(end + 1) = surf(Xc, Yc, z(k) * ones(size(Xc)), V(:, :, k)); %#ok<AGROW>
        hold('on');
    end
    if ~tenu
        hold('off');
    end
    zlim([min(z), max(z)]);
    if nargout == 0
        clear H;
    end
end
