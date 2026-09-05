function r = matlibre_id_correlation(a, b, decalage)
%MATLIBRE_ID_CORRELATION Corrélation normalisée, décalage par décalage.
%   R = MATLIBRE_ID_CORRELATION(A,B,DECALAGE) rend les corrélations de
%   moins DECALAGE à plus DECALAGE, normalisées par les écarts types :
%   elles valent alors entre moins un et un, et le seuil de confiance
%   s'écrit sans référence à l'échelle des signaux.
%
%   Exemple :
%      r = matlibre_id_correlation(randn(100, 1), randn(100, 1), 5);
%      numel(r)      % 11
%
%   Voir aussi RESID.
    a = a(:) - mean(a(:));
    b = b(:) - mean(b(:));
    n = numel(a);
    echelle = sqrt(sum(a .^ 2) * sum(b .^ 2));
    if echelle == 0
        echelle = 1;
    end
    r = zeros(2 * decalage + 1, 1);
    for k = -decalage:decalage
        if k >= 0
            produit = sum(a((k + 1):n) .* b(1:(n - k)));
        else
            produit = sum(a(1:(n + k)) .* b((1 - k):n));
        end
        r(k + decalage + 1) = produit / echelle;
    end
end
