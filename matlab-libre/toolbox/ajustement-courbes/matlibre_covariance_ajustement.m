function [covariance, ecartType] = matlibre_covariance_ajustement(ajustement)
%MATLIBRE_COVARIANCE_AJUSTEMENT Covariance des coefficients ajustés.
%   [C,S] = MATLIBRE_COVARIANCE_AJUSTEMENT(FO) rend la matrice de
%   covariance des coefficients et l'écart type résiduel.
%
%   La covariance est l'inverse de la matrice normale, multipliée par la
%   variance résiduelle : c'est l'approximation linéaire de l'incertitude
%   au point trouvé, valable tant que le modèle est peu courbé à
%   l'échelle de cette incertitude.
%
%   Exemple :
%      fo = fit((1:10)', (1:10)', 'poly1');
%      matlibre_covariance_ajustement(fo)
%
%   Voir aussi CONFINT, PREDINT.
    J = ajustement.Jacobienne;
    residus = ajustement.Residus;
    poids = ajustement.Poids;
    if isempty(J) || ajustement.DDL <= 0
        covariance = [];
        ecartType = 0;
        return
    end
    if isempty(poids)
        poids = ones(size(residus));
    end
    variance = sum(poids(:) .* residus(:) .^ 2) / ajustement.DDL;
    normale = J.' * (J .* poids(:));
    covariance = pinv(normale) * variance;
    ecartType = sqrt(variance);
end
