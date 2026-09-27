function Vq = interp3(varargin)
%INTERP3 Interpolation sur une grille de l'espace.
%   VQ = INTERP3(X,Y,Z,V,XQ,YQ,ZQ) interpole les valeurs V, données sur la
%   grille de MESHGRID — X varie le long des colonnes, Y le long des
%   lignes, Z le long des pages —, aux points (XQ,YQ,ZQ). X, Y et Z sont
%   les vecteurs de la grille ou ses tableaux ; des vecteurs XQ, YQ, ZQ de
%   tailles différentes décrivent une grille, que MESHGRID déplie.
%   VQ = INTERP3(V,XQ,YQ,ZQ) prend X = 1:size(V,2), Y = 1:size(V,1),
%   Z = 1:size(V,3).
%
%   VQ = INTERP3(...,METHODE) : 'linear' (le défaut) ou 'nearest' ;
%   VQ = INTERP3(...,METHODE,EXTRAPVAL) : la valeur hors de la grille, NaN
%   par défaut.
%
%   Exemple :
%      [X, Y, Z] = meshgrid(0:2, 0:1, 0:3);
%      V = X + 10 * Y + 100 * Z;
%      interp3(X, Y, Z, V, 1.5, 0.5, 2)            % 206.5
%
%   Voir aussi INTERPN, INTERP2, MESHGRID.
    nNum = numel(varargin);
    for k = 1:numel(varargin)
        if ischar(varargin{k}) || isstring(varargin{k})
            nNum = k - 1;
            break
        end
    end
    options = varargin(nNum + 1:end);
    if nNum == 7
        [X, Y, Z, V] = varargin{1:4};
        questions = varargin(5:7);
        x = axe(X, 2);
        y = axe(Y, 1);
        z = axe(Z, 3);
    elseif nNum == 4
        V = varargin{1};
        questions = varargin(2:4);
        x = 1:size(V, 2);
        y = 1:size(V, 1);
        z = 1:size(V, 3);
    else
        error('MATLAB:interp3:NotEnoughInputs', ...
              'INTERP3(X,Y,Z,V,XQ,YQ,ZQ) ou INTERP3(V,XQ,YQ,ZQ).');
    end
    tousVecteurs = all(cellfun(@isvector, questions));
    memeTaille = all(cellfun(@(q) isequal(size(q), size(questions{1})), questions));
    if tousVecteurs && ~memeTaille
        [questions{1:3}] = meshgrid(questions{:});
    end
    % l'ordre de MESHGRID : les lignes suivent Y, les colonnes X
    Vq = interpn(y, x, z, V, questions{2}, questions{1}, questions{3}, options{:});
end

function v = axe(A, d)
    if isvector(A)
        v = double(A(:)).';
        return
    end
    indices = repmat({1}, 1, ndims(A));
    indices{d} = ':';
    v = double(A(indices{:}));
    v = v(:).';
end
