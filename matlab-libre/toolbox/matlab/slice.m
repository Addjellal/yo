function H = slice(varargin)
%SLICE Coupes d'un volume.
%   SLICE(V,SX,SY,SZ) montre, dans MATLAB, le volume V coupé par les
%   plans d'abscisses SX, d'ordonnées SY et de cotes SZ.
%
%   SLICE(X,Y,Z,V,SX,SY,SZ) place le volume sur la grille donnée.
%
%   H = SLICE(...) rend les poignées.
%
%   Le rendu de MatLibre est plan : il ne montre pas un volume en
%   perspective. SLICE dessine donc les coupes les unes à côté des
%   autres, chacune comme une image — ce qui donne la même information,
%   sans le relief.
%
%   Exemples :
%      [X, Y, Z] = meshgrid(-2:0.2:2);
%      V = X .* exp(-X.^2 - Y.^2 - Z.^2);
%      slice(V, [], [], [5 11 17]);      % trois coupes en z
%
%   Voir aussi IMAGESC, CONTOURSLICE, ISOSURFACE, SURF, MESHGRID.
    entrees = varargin;
    if numel(entrees) >= 7
        V = entrees{4};
        sx = entrees{5};
        sy = entrees{6};
        sz = entrees{7};
    elseif numel(entrees) >= 4
        V = entrees{1};
        sx = entrees{2};
        sy = entrees{3};
        sz = entrees{4};
    else
        error('MATLAB:slice:NotEnoughInputs', 'Not enough input arguments.');
    end
    coupes = {};
    titres = {};
    d = size(V);
    if numel(d) < 3
        d(3) = 1;
    end
    for k = 1:numel(sz)
        indice = max(1, min(d(3), round(sz(k))));
        coupes{end + 1} = V(:, :, indice);            %#ok<AGROW>
        titres{end + 1} = sprintf('z = %d', indice);  %#ok<AGROW>
    end
    for k = 1:numel(sy)
        indice = max(1, min(d(1), round(sy(k))));
        coupes{end + 1} = reshape(V(indice, :, :), d(2), d(3));   %#ok<AGROW>
        titres{end + 1} = sprintf('y = %d', indice);              %#ok<AGROW>
    end
    for k = 1:numel(sx)
        indice = max(1, min(d(2), round(sx(k))));
        coupes{end + 1} = reshape(V(:, indice, :), d(1), d(3));   %#ok<AGROW>
        titres{end + 1} = sprintf('x = %d', indice);              %#ok<AGROW>
    end
    if isempty(coupes)
        error('MATLAB:slice:NoSlice', 'SLICE needs at least one slice position.');
    end
    clf;
    colonnes = ceil(sqrt(numel(coupes)));
    lignes = ceil(numel(coupes) / colonnes);
    H = [];
    for k = 1:numel(coupes)
        subplot(lignes, colonnes, k);
        H(end + 1) = imagesc(coupes{k});      %#ok<AGROW>
        title(titres{k});
    end
    if nargout == 0
        clear H;
    end
end
