function [coefficients, scores, valeurs, T2] = princomp(X)
%PRINCOMP Analyse en composantes principales (nom historique).
%   [COEFF,SCORE,LATENT] = PRINCOMP(X) fait ce que fait PCA : il centre
%   les colonnes de X, cherche les directions de plus grande variance, et
%   rend les vecteurs propres (COEFF), les coordonnées des individus dans
%   cette base (SCORE) et les variances portées (LATENT).
%
%   [COEFF,SCORE,LATENT,TSQUARED] = PRINCOMP(X) rend en outre le T carré
%   de Hotelling de chaque observation : sa distance au centre du nuage,
%   mesurée dans la métrique des composantes. C'est ce qui sert à
%   repérer les individus atypiques.
%
%   PRINCOMP est le nom que la fonction portait avant R2012b ; PCA lui a
%   succédé, avec les mêmes trois premières sorties. MatLibre garde les
%   deux, pour que les programmes anciens tournent sans retouche.
%
%   Exemples :
%      X = randn(100, 3) * [1 0 0; 0.5 1 0; 0 0 2];
%      [coeff, score, latent, t2] = princomp(X);
%      cumsum(latent) / sum(latent)     % la part expliquee cumulee
%      max(t2)                          % l'individu le plus atypique
%
%   Voir aussi PCA, PCACOV, MAHAL, CANONCORR, COV.
    [coefficients, scores, valeurs] = pca(X);
    n = size(X, 1);
    T2 = zeros(n, 1);
    positives = valeurs > max(size(X)) * eps * max([valeurs; realmin]);
    if any(positives)
        reduits = scores(:, positives) ./ ...
                  repmat(sqrt(valeurs(positives))', n, 1);
        T2 = sum(reduits .^ 2, 2);
    end
end
