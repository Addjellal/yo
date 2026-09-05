function r = matlibre_id_covariance(a, b, M)
%MATLIBRE_ID_COVARIANCE Covariance croisée, décalage par décalage.
%   R = MATLIBRE_ID_COVARIANCE(A,B,M) rend les covariances des décalages
%   de moins M à plus M, divisées par le nombre de points — l'estimateur
%   biaisé, dont la transformée est toujours un spectre positif, ce que
%   l'estimateur non biaisé ne garantit pas.
%
%   Exemple :
%      r = matlibre_id_covariance(randn(100,1), randn(100,1), 5);
%      numel(r)      % 11
%
%   Voir aussi SPA, RESID.
    a = a(:) - mean(a(:));
    b = b(:) - mean(b(:));
    n = numel(a);
    r = zeros(2 * M + 1, 1);
    for k = -M:M
        if k >= 0
            produit = sum(a((k + 1):n) .* b(1:(n - k)));
        else
            produit = sum(a(1:(n + k)) .* b((1 - k):n));
        end
        r(k + M + 1) = produit / n;
    end
end
