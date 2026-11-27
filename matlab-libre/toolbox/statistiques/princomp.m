function [coefficients, scores, valeurs, T2] = princomp(X, econ)
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
%   PRINCOMP(X,'econ') ne rend que les axes porteurs de variance quand
%   les observations sont moins nombreuses que les variables ; sans
%   'econ', COEFF est carré, comme le rendait PRINCOMP.
%
%   PRINCOMP est le nom que la fonction portait avant R2012b ; PCA lui a
%   succédé, avec les mêmes quatre premières sorties. MatLibre garde les
%   deux, pour que les programmes anciens tournent sans retouche.
%
%   Exemples :
%      X = randn(100, 3) * [1 0 0; 0.5 1 0; 0 0 2];
%      [coeff, score, latent, t2] = princomp(X);
%      cumsum(latent) / sum(latent)     % la part expliquee cumulee
%      max(t2)                          % l'individu le plus atypique
%
%   Voir aussi PCA, PCACOV, MAHAL, CANONCORR, COV.
    if nargin < 2
        economie = false;
    elseif (ischar(econ) || isstring(econ)) && strcmpi(char(econ), 'econ')
        economie = true;
    else
        error('stats:princomp:BadEcon', 'The second argument of PRINCOMP must be ''econ''.');
    end
    [coefficients, scores, valeurs, T2] = pca(X, 'Economy', economie);
end
