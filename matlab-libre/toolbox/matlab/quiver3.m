function H = quiver3(varargin)
%QUIVER3 Champ de vecteurs en trois dimensions.
%   QUIVER3(X,Y,Z,U,V,W) trace une flèche partant de chaque point
%   (X,Y,Z) et portant le vecteur (U,V,W). Les flèches sont mises à
%   l'échelle d'office pour ne pas se chevaucher, comme dans MATLAB.
%
%   QUIVER3(Z,U,V,W) place les flèches sur la surface Z, aux nœuds d'une
%   grille entière.
%
%   QUIVER3(...,ECHELLE) multiplie la mise à l'échelle automatique ;
%   ECHELLE = 0 garde les longueurs telles quelles. QUIVER3(...,STYLE)
%   prend une chaîne de style.
%
%   H = QUIVER3(...) rend la poignée des flèches.
%
%   Exemples :
%      [X, Y] = meshgrid(-2:0.5:2);
%      Z = X .* exp(-X.^2 - Y.^2);
%      [U, V, W] = surfnorm(X, Y, Z);
%      quiver3(X, Y, Z, U, V, W);
%
%   Voir aussi QUIVER, PLOT3, SURFNORM, CONTOUR3.
    entrees = varargin;
    style = '';
    if ~isempty(entrees) && (ischar(entrees{end}) || isstring(entrees{end}))
        style = char(entrees{end});
        entrees = entrees(1:end - 1);
    end
    echelle = 1;
    if numel(entrees) == 5 || numel(entrees) == 7
        echelle = entrees{end};
        entrees = entrees(1:end - 1);
    end
    if numel(entrees) == 4
        Z = entrees{1};
        [X, Y] = meshgrid(1:size(Z, 2), 1:size(Z, 1));
        [U, V, W] = entrees{2:4};
    elseif numel(entrees) == 6
        [X, Y, Z, U, V, W] = entrees{:};
    else
        error('MATLAB:quiver3:NotEnoughInputs', 'Not enough input arguments.');
    end
    x = X(:); y = Y(:); z = Z(:); u = U(:); v = V(:); w = W(:);
    n = numel(x);
    if echelle ~= 0 && n > 0
        % La mise à l'échelle de MATLAB : l'écart moyen entre deux points
        % dans chaque direction, et la plus longue flèche ramenée aux neuf
        % dixièmes de cet écart.
        if min(size(X)) == 1
            colonnesGrille = sqrt(numel(X));
            lignesGrille = colonnesGrille;
        else
            [lignesGrille, colonnesGrille] = size(X);
        end
        dx = (max(x) - min(x)) / colonnesGrille;
        dy = (max(y) - min(y)) / lignesGrille;
        dz = (max(z) - min(z)) / max(lignesGrille, colonnesGrille);
        ecart = sqrt(dx ^ 2 + dy ^ 2 + dz ^ 2);
        plusLongue = max(sqrt(u .^ 2 + v .^ 2 + w .^ 2)) / max(ecart, eps);
        if ecart > 0 && plusLongue > 0
            facteur = echelle * 0.9 / plusLongue;
            u = u * facteur; v = v * facteur; w = w * facteur;
        end
    end
    % Les tiges, puis les deux barbes de chaque pointe, séparées par des
    % NaN : une seule courbe.
    pointe = [x + u, y + v, z + w];
    longueur = sqrt(u .^ 2 + v .^ 2 + w .^ 2);
    direction = [u, v, w] ./ max(longueur, eps);
    travers = cross(direction, repmat([0 0 1], n, 1), 2);
    plat = sqrt(sum(travers .^ 2, 2)) < 1e-6;
    travers(plat, :) = cross(direction(plat, :), repmat([1 0 0], nnz(plat), 1), 2);
    travers = travers ./ max(sqrt(sum(travers .^ 2, 2)), eps);
    recul = pointe - 0.3 * longueur .* direction;
    barbe1 = recul + 0.12 * longueur .* travers;
    barbe2 = recul - 0.12 * longueur .* travers;
    blanc = nan(n, 1);
    px = [x, pointe(:, 1), blanc, barbe1(:, 1), pointe(:, 1), barbe2(:, 1), blanc]';
    py = [y, pointe(:, 2), blanc, barbe1(:, 2), pointe(:, 2), barbe2(:, 2), blanc]';
    pz = [z, pointe(:, 3), blanc, barbe1(:, 3), pointe(:, 3), barbe2(:, 3), blanc]';
    if isempty(style)
        H = plot3(px(:), py(:), pz(:));
    else
        H = plot3(px(:), py(:), pz(:), style);
    end
    if nargout == 0
        clear H;
    end
end
