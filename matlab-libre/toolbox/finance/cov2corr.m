function [correlations, ecarts] = cov2corr(covariance)
%COV2CORR Corrélations et écarts types tirés d'une covariance.
%   [R,S] = COV2CORR(C) sépare la matrice de covariance en une matrice de
%   corrélations et un vecteur d'écarts types : C(i,j) = S(i)*R(i,j)*S(j).
%
%   Exemple :
%      [r, s] = cov2corr([4 1; 1 9])      % s = [2 3], r(1,2) = 1/6
%
%   Voir aussi CORR2COV, COV, CORRCOEF, EWSTATS.
    covariance = double(covariance);
    ecarts = sqrt(diag(covariance)).';
    diviseur = ecarts.' * ecarts;
    correlations = covariance ./ diviseur;
    % La diagonale vaut un par construction ; on l'y remet exactement,
    % l'arrondi pouvant en écarter le dernier chiffre.
    n = size(correlations, 1);
    correlations(1:(n + 1):end) = 1;
end
