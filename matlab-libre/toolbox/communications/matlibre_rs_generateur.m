function generateur = matlibre_rs_generateur(n, k, m, prim, b)
%MATLIBRE_RS_GENERATEUR Générateur d'un code de Reed-Solomon.
%   Produit des (x - alpha^(b+i)) pour i de zéro à n-k-1, rendu par
%   puissances décroissantes.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    [~, exponentielle] = matlibre_gf_journal(m, prim);
    ordre = 2 ^ m - 1;
    % Coefficients par puissances croissantes pendant le calcul.
    generateur = 1;
    for i = 0:(n - k - 1)
        racine = exponentielle(mod(b + i, ordre) + 1);
        suivant = zeros(1, numel(generateur) + 1);
        for j = 1:numel(generateur)
            suivant(j + 1) = bitxor(suivant(j + 1), generateur(j));
            suivant(j) = bitxor(suivant(j), ...
                matlibre_gf_mul(generateur(j), racine, m, prim));
        end
        generateur = suivant;
    end
    generateur = fliplr(generateur);
end
