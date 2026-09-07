function [U, S, V] = pagesvd(a, mode)
%PAGESVD Décomposition en valeurs singulières de chaque page.
%   S = PAGESVD(A) rend, pour chaque page, ses valeurs singulières en
%   colonne.
%   [U,S,V] = PAGESVD(A) rend la décomposition complète : chaque page
%   vérifie A(:,:,k) = U(:,:,k)*S(:,:,k)*V(:,:,k)'.
%   [...] = PAGESVD(A,'econ') rend la forme économique.
%
%   Comme toutes les fonctions PAGE..., elle traite les pages
%   séparément : il n'y a pas de décomposition commune, et une page n'a
%   aucune influence sur une autre.
%
%   Exemple :
%      A = cat(3, diag([3 1]), diag([2 5]));
%      s = pagesvd(A);
%      s(:, :, 1)'                         % 3 1
%      [U, S, V] = pagesvd(A);
%      max(max(max(abs(pagemtimes(pagemtimes(U, S), pagetranspose(V)) - A)))) < 1e-12
%
%   Voir aussi SVD, PAGEMTIMES, PAGEINV, PAGETRANSPOSE, SVDS.
    if nargin < 2, mode = ''; end
    a = double(a);
    formes = size(a);
    if numel(formes) < 3
        if nargout <= 1
            U = svd(a);
        elseif isempty(mode)
            [U, S, V] = svd(a);
        else
            [U, S, V] = svd(a, mode);
        end
        return
    end
    pages = prod(formes(3:end));
    if nargout <= 1
        premier = svd(a(:, :, 1));
        U = zeros([numel(premier), 1, formes(3:end)]);
        U(:, 1, 1) = premier;
        for k = 2:pages
            U(:, 1, k) = svd(a(:, :, k));
        end
        return
    end
    if isempty(mode)
        [u1, s1, v1] = svd(a(:, :, 1));
    else
        [u1, s1, v1] = svd(a(:, :, 1), mode);
    end
    U = zeros([size(u1), formes(3:end)]);
    S = zeros([size(s1), formes(3:end)]);
    V = zeros([size(v1), formes(3:end)]);
    U(:, :, 1) = u1; S(:, :, 1) = s1; V(:, :, 1) = v1;
    for k = 2:pages
        if isempty(mode)
            [uk, sk, vk] = svd(a(:, :, k));
        else
            [uk, sk, vk] = svd(a(:, :, k), mode);
        end
        U(:, :, k) = uk; S(:, :, k) = sk; V(:, :, k) = vk;
    end
end
