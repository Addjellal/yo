function [r, p, k] = residuez(b, a)
%RESIDUEZ Éléments simples d'une fraction en z^-1.
%   [R,P,K] = RESIDUEZ(B,A) décompose
%
%      B(z)     R(1)                R(n)
%      ---- = ----------- + ... + ----------- + K(1) + K(2) z^-1 + ...
%      A(z)   1-P(1)z^-1          1-P(n)z^-1
%
%   B et A sont donnés en puissances croissantes de z^-1, comme pour
%   FILTER. Le calcul passe par RESIDUE sur la variable w = z^-1 : un
%   terme R/(w-P) s'y réécrit (-R/P)/(1-w/P), d'où P -> 1/P.
%
%   Exemple :
%      [r,p] = residuez(1, [1 -0.5])   % r = 1, p = 0.5
    b = double(b(:)).';
    a = double(a(:)).';
    if isempty(a) || a(1) == 0
        error('signal:residuez:BadDenominator', ...
              'Le premier coefficient du dénominateur doit être non nul.');
    end
    [R, P, K] = residue(fliplr(b), fliplr(a));
    r = zeros(numel(R), 1);
    p = zeros(numel(P), 1);
    j = 1;
    while j <= numel(P)
        m = 1;
        while j + m <= numel(P) && abs(P(j + m) - P(j)) <= 1e-6 * max(1, abs(P(j)))
            m = m + 1;
        end
        for ordre = 1:m
            r(j + ordre - 1) = R(j + ordre - 1) * (-1 / P(j)) ^ ordre;
            p(j + ordre - 1) = 1 / P(j);
        end
        j = j + m;
    end
    k = fliplr(K(:).');
end
