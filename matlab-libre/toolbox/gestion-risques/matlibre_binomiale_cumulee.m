function probabilite = matlibre_binomiale_cumulee(x, N, p)
%MATLIBRE_BINOMIALE_CUMULEE Répartition binomiale, calculée en logarithmes.
%   Les coefficients binomiaux dépassent vite les nombres représentables ;
%   passer par les logarithmes de factorielles les garde finis.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    probabilite = 0;
    for k = 0:x
        logTerme = gammaln(N + 1) - gammaln(k + 1) - gammaln(N - k + 1) + ...
                   k * log(p) + (N - k) * log(1 - p);
        probabilite = probabilite + exp(logTerme);
    end
    probabilite = min(probabilite, 1);
end
