function covariance = corr2cov(ecarts, correlations)
%CORR2COV Covariance construite à partir d'écarts types et de corrélations.
%   C = CORR2COV(S,R) rend C(i,j) = S(i)*R(i,j)*S(j). Sans R, les
%   variables sont supposées non corrélées.
%
%   Exemple :
%      corr2cov([2 3], [1 1/6; 1/6 1])    % [4 1; 1 9]
%
%   Voir aussi COV2CORR, COV, CORRCOEF.
    ecarts = double(ecarts(:));
    n = numel(ecarts);
    if nargin < 2 || isempty(correlations)
        correlations = eye(n);
    end
    covariance = (ecarts * ecarts.') .* double(correlations);
end
