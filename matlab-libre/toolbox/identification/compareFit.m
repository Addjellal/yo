function pourcentage = compareFit(y, yhat)
%COMPAREFIT Qualité d'ajustement, en pour cent (critère de MathWorks).
%   FIT = 100 (1 - ||y - yhat|| / ||y - moyenne(y)||)
    y = y(:);
    yhat = yhat(:);
    pourcentage = 100 * (1 - norm(y - yhat) / max(norm(y - mean(y)), eps));
end
