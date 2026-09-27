function Vq = interp2(varargin)
%INTERP2 Interpolation sur une grille du plan.
%   VQ = INTERP2(X,Y,V,XQ,YQ) interpole les valeurs V, données sur la
%   grille de MESHGRID — X varie le long des colonnes, Y le long des
%   lignes —, aux points (XQ,YQ). X et Y sont les vecteurs de la grille ou
%   ses tableaux ; un vecteur ligne XQ et un vecteur colonne YQ décrivent
%   une grille, que MESHGRID déplie.
%   VQ = INTERP2(V,XQ,YQ) prend X = 1:size(V,2) et Y = 1:size(V,1).
%   VQ = INTERP2(V,K) raffine la grille de V K fois, en insérant à chaque
%   fois un point au milieu de chaque intervalle ; VQ = INTERP2(V) le fait
%   une fois.
%
%   VQ = INTERP2(...,METHODE) : 'linear' (le défaut, bilinéaire),
%   'nearest', 'cubic', 'makima' ou 'spline'. VQ = INTERP2(...,METHODE,
%   EXTRAPVAL) : la valeur hors de la grille, NaN par défaut.
%
%   Exemple :
%      [X, Y] = meshgrid(0:2, 0:1);
%      V = X + 10 * Y;
%      interp2(X, Y, V, 1.5, 0.5)                  % 6.5
%      interp2(X, Y, V, 3, 0)                      % NaN : hors de la grille
%
%   Voir aussi INTERP1, INTERP3, INTERPN, MESHGRID, GRIDDEDINTERPOLANT.
    nNum = numel(varargin);
    for k = 1:numel(varargin)
        if ischar(varargin{k}) || isstring(varargin{k})
            nNum = k - 1;
            methode = lower(char(varargin{k}));
            if ~any(strcmp(methode, {'linear', 'nearest', 'cubic', 'makima', 'spline'}))
                error('MATLAB:interp2:InvalidMethod', ...
                      ['INTERP2 : la methode est ''linear'', ''nearest'', ''cubic'', ' ...
                       '''makima'' ou ''spline'' ; pas ''%s''.'], char(varargin{k}));
            end
            break
        end
    end
    options = varargin(nNum + 1:end);
    switch nNum
        case 5
            [X, Y, V, Xq, Yq] = varargin{1:5};
            x = axe(X, 2);
            y = axe(Y, 1);
        case 3
            [V, Xq, Yq] = varargin{1:3};
            x = 1:size(V, 2);
            y = 1:size(V, 1);
        case {1, 2}
            V = varargin{1};
            fois = 1;
            if nNum == 2
                fois = double(varargin{2});
            end
            x = 1:size(V, 2);
            y = 1:size(V, 1);
            pas = 1 / 2^fois;
            Xq = 1:pas:size(V, 2);
            Yq = (1:pas:size(V, 1)).';
        otherwise
            error('MATLAB:interp2:nargin', ...
                  'INTERP2(X,Y,V,XQ,YQ), INTERP2(V,XQ,YQ) ou INTERP2(V,K).');
    end
    if ~ismatrix(V)
        error('MATLAB:interp2:VNot2D', 'INTERP2 interpole un tableau V a deux dimensions.');
    end
    if isvector(Xq) && isvector(Yq) && ~isequal(size(Xq), size(Yq))
        [Xq, Yq] = meshgrid(Xq, Yq);
    end
    % l'ordre de MESHGRID : les lignes suivent Y, les colonnes X
    Vq = interpn(y, x, V, Yq, Xq, options{:});
end

function v = axe(A, d)
    if isvector(A)
        v = double(A(:)).';
        return
    end
    if d == 1
        v = double(A(:, 1)).';
    else
        v = double(A(1, :));
    end
end
