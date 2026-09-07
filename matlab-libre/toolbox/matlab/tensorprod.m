function c = tensorprod(a, b, dimA, dimB)
%TENSORPROD Produit tensoriel avec contraction de dimensions.
%   C = TENSORPROD(A,B) rend le produit extérieur : C a pour dimensions
%   celles de A suivies de celles de B, et C(i,...,j,...) = A(i,...)*B(j,...).
%   C = TENSORPROD(A,B,DIMA,DIMB) contracte les dimensions DIMA de A avec
%   les dimensions DIMB de B, qui doivent être de mêmes tailles : on
%   somme sur ces indices, et ils disparaissent du résultat.
%   C = TENSORPROD(A,B,'all') contracte toutes les dimensions et rend un
%   scalaire, à condition que A et B aient la même taille.
%
%   C'est la généralisation du produit matriciel : contracter la deuxième
%   dimension de A avec la première de B redonne A*B. Le produit scalaire,
%   la trace d'un produit, le produit extérieur en sont d'autres cas
%   particuliers — ce qui les distingue n'est que le choix des indices
%   sommés.
%
%   Exemple :
%      A = [1 2; 3 4];
%      B = [5 6; 7 8];
%      max(max(abs(tensorprod(A, B, 2, 1) - A * B))) < 1e-12
%      tensorprod([1 2 3], [4 5 6], 2, 2)      % 32 : le produit scalaire
%      size(tensorprod(ones(2, 3), ones(4, 5)))   % 2 3 4 5
%
%   Voir aussi PAGEMTIMES, KRON, DOT, MTIMES, PERMUTE.
    a = double(a);
    b = double(b);
    if nargin == 3 && (ischar(dimA) || isstring(dimA)) && strcmpi(char(dimA), 'all')
        if ~isequal(size(a), size(b))
            error('MATLAB:tensorprod:SizeMismatch', ...
                  'Contracter toutes les dimensions demande des tailles égales.');
        end
        c = sum(a(:) .* b(:));
        return
    end
    if nargin < 3
        dimA = [];
        dimB = [];
    end
    dimA = double(dimA(:))';
    dimB = double(dimB(:))';
    if numel(dimA) ~= numel(dimB)
        error('MATLAB:tensorprod:DimMismatch', ...
              'Il faut autant de dimensions contractées de chaque côté.');
    end
    formeA = tailleEtendue(a, max([ndims(a), dimA]));
    formeB = tailleEtendue(b, max([ndims(b), dimB]));
    if ~isequal(formeA(dimA), formeB(dimB))
        error('MATLAB:tensorprod:SizeMismatch', ...
              'Les dimensions contractées doivent être de mêmes tailles.');
    end
    libresA = setdiff(1:numel(formeA), dimA);
    libresB = setdiff(1:numel(formeB), dimB);
    % On ramene la contraction a un produit matriciel : les dimensions
    % libres d'un cote, les contractees de l'autre, et un seul MTIMES.
    A = reshape(permute(a, [libresA, dimA]), ...
                max(prod(formeA(libresA)), 1), max(prod(formeA(dimA)), 1));
    B = reshape(permute(b, [dimB, libresB]), ...
                max(prod(formeB(dimB)), 1), max(prod(formeB(libresB)), 1));
    c = A * B;
    forme = [formeA(libresA), formeB(libresB)];
    if isempty(forme)
        return
    end
    if numel(forme) == 1
        forme = [forme, 1];
    end
    c = reshape(c, forme);
end

function t = tailleEtendue(x, n)
    t = size(x);
    if numel(t) < n
        t(end + 1:n) = 1;
    end
end
