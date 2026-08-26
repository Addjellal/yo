function [rho, retards] = autocorr(y, nRetards)
%AUTOCORR Fonction d'autocorrélation empirique.
    y = y(:);
    n = numel(y);
    if nargin < 2
        nRetards = min(20, n - 1);
    end
    m = mean(y);
    denominateur = sum((y - m) .^ 2);
    rho = zeros(nRetards + 1, 1);
    for k = 0:nRetards
        rho(k + 1) = sum((y(1:n-k) - m) .* (y(1+k:n) - m)) / denominateur;
    end
    retards = (0:nRetards).';
end
