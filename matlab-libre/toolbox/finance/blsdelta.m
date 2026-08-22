function [deltaCall, deltaPut] = blsdelta(S, K, r, T, sigma, q)
%BLSDELTA Sensibilité du prix au cours du sous-jacent.
    if nargin < 6
        q = 0;
    end
    d1 = (log(S ./ K) + (r - q + sigma .^ 2 / 2) .* T) ./ (sigma .* sqrt(T));
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    deltaCall = exp(-q * T) .* N(d1);
    deltaPut = deltaCall - exp(-q * T);
end
