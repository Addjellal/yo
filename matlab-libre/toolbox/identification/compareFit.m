function pourcentage = compareFit(y, yhat)
%COMPAREFIT Qualité d'ajustement, en pour cent (critère de MathWorks).
%   FIT = 100 (1 - ||y - yhat|| / ||y - moyenne(y)||)
%
%   Exemple :
%      y = (1:10)';
%      compareFit(y, y)            % 100 : un ajustement parfait
%      compareFit(y, mean(y) * ones(10, 1)) < 1e-10     % predire la moyenne fait zero
%
%   Voir aussi ARX, AIC.
    y = y(:);
    yhat = yhat(:);
    pourcentage = 100 * (1 - norm(y - yhat) / max(norm(y - mean(y)), eps));
end
