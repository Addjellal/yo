function resultat = ols(y, X, avecConstante)
%OLS Moindres carrés ordinaires, avec diagnostics.
%   R = OLS(Y,X) ajuste par moindres carrés ordinaires Y sur X, une
%   constante étant ajoutée d'office. R = OLS(Y,X,false) ne l'ajoute pas.
%
%   La structure rendue contient les coefficients BETA, leurs écarts types
%   SE, les statistiques de Student T, les RESIDUS, le coefficient de
%   détermination R2 et sa version ajustée R2AJUSTE, et la variance
%   résiduelle SIGMA2.
%
%   Les coefficients viennent de la décomposition QR par l'opérateur
%   d'antislash, non de l'inversion de X'X : le conditionnement du
%   problème est ainsi la racine de celui du système normal, ce qui compte
%   dès que deux régresseurs sont fortement corrélés.
%
%   La variance résiduelle divise par n-k et non par n : c'est ce qui la
%   rend sans biais, k degrés de liberté ayant été consommés par
%   l'ajustement. De même le R2 ajusté pénalise l'ajout de régresseurs,
%   là où le R2 brut ne peut que croître quand on en ajoute un, fût-il du
%   bruit pur — c'est pourquoi le R2 brut ne sert jamais à choisir un
%   modèle.
%
%   Les écarts types supposent des erreurs homoscédastiques et non
%   corrélées ; sous hétéroscédasticité, les coefficients restent sans
%   biais mais les statistiques de Student sont fausses.
%
%   Exemple :
%      rng(1);
%      x = (1:50)';
%      r = ols(2 + 3 * x + randn(50, 1), x);
%      r.beta'
%
%   Voir aussi REGRESS, FITLM, LAGMATRIX, ROBUSTFIT.
    if nargin < 3
        avecConstante = true;
    end
    y = y(:);
    if avecConstante
        X = [ones(size(X, 1), 1), X];
    end
    b = X \ y;
    residus = y - X * b;
    n = numel(y);
    k = size(X, 2);
    sigma2 = sum(residus .^ 2) / max(n - k, 1);
    covariance = sigma2 * inv(X.' * X);
    ecarts = sqrt(diag(covariance));
    sct = sum((y - mean(y)) .^ 2);
    resultat = struct();
    resultat.beta = b;
    resultat.se = ecarts;
    resultat.t = b ./ ecarts;
    resultat.residus = residus;
    resultat.R2 = 1 - sum(residus .^ 2) / sct;
    resultat.R2ajuste = 1 - (1 - resultat.R2) * (n - 1) / max(n - k, 1);
    resultat.sigma2 = sigma2;
end
