function b = repelem(a, varargin)
%REPELEM Répétition élément par élément.
%   B = REPELEM(V,N) répète chaque élément du vecteur V. N est un
%   scalaire, ou un vecteur donnant le nombre de copies de chaque
%   élément.
%
%   B = REPELEM(A,M,N) répète chaque élément de la matrice A en un bloc
%   de M lignes et N colonnes ; M et N peuvent être des vecteurs donnant
%   la hauteur de chaque ligne et la largeur de chaque colonne.
%
%   Exemples :
%      repelem([1 2 3], 2)        % [1 1 2 2 3 3]
%      repelem([1 2 3], [1 2 3])  % [1 2 2 3 3 3]
%      repelem([1 2; 3 4], 2, 3)
%
%   Voir aussi REPMAT, KRON, RESHAPE.
    if isempty(varargin)
        error('repelem:Arguments', 'repelem exige au moins deux arguments.');
    end
    if numel(varargin) == 1
        n = varargin{1};
        if ~isvector(a) && ~isempty(a)
            error('repelem:Vecteur', ...
                  'Avec un seul compte, repelem attend un vecteur.');
        end
        compte = etaler(n, numel(a), 'repelem');
        indices = repeter(compte);
        b = a(indices);
        if size(a, 1) > 1
            b = b(:);
        else
            b = b(:)';
        end
        return;
    end
    m = etaler(varargin{1}, size(a, 1), 'repelem');
    n = etaler(varargin{2}, size(a, 2), 'repelem');
    lignes = repeter(m);
    colonnes = repeter(n);
    b = a(lignes, colonnes);
    for k = 3:numel(varargin)
        if any(varargin{k} ~= 1)
            error('repelem:Dimensions', ...
                  'repelem ne répète que suivant deux dimensions.');
        end
    end
end

function c = etaler(n, attendu, nom)
% Un compte scalaire vaut pour tous les éléments ; un vecteur doit en
% donner un par élément.
    n = double(n(:))';
    if any(n < 0) || any(n ~= fix(n))
        error([nom ':Compte'], 'Les comptes doivent être des entiers positifs.');
    end
    if isscalar(n)
        c = repmat(n, 1, attendu);
    elseif numel(n) == attendu
        c = n;
    else
        error([nom ':Compte'], ...
              'Il faut un compte par élément (%d attendus, %d donnés).', ...
              attendu, numel(n));
    end
end

function indices = repeter(compte)
% La liste des positions, chacune répétée autant de fois qu'annoncé.
    indices = zeros(1, sum(compte));
    p = 0;
    for k = 1:numel(compte)
        if compte(k) > 0
            indices(p + (1:compte(k))) = k;
            p = p + compte(k);
        end
    end
end
