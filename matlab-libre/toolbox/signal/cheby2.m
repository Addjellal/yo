function [b, a, k] = cheby2(n, rs, Wn, genre)
%CHEBY2 Filtre de Chebyshev de type II, ondulation en bande atténuée.
%   [B,A] = CHEBY2(N,RS,WN) : RS est l'atténuation minimale en décibels
%   dans la bande coupée.
    if nargin < 4, genre = 'low'; end
    epsilon = 1 / sqrt(10^(rs / 10) - 1);
    mu = asinh(1 / epsilon) / n;
    k = 1:n;
    theta = pi * (2 * k - 1) / (2 * n);
    polesType1 = -sinh(mu) * sin(theta) + 1i * cosh(mu) * cos(theta);
    poles = 1 ./ polesType1;
    if mod(n, 2) == 0
        zeros_ = 1i ./ cos(theta);
    else
        milieu = (n + 1) / 2;
        garde = true(1, n);
        garde(milieu) = false;
        zeros_ = 1i ./ cos(theta(garde));
    end
    gain = real(prod(-poles) / prod(-zeros_));
    [b, a, zNum, pNum, kNum] = prototypeVersNumerique(poles, zeros_, gain, Wn, genre);
    % Trois sorties : MATLAB rend alors la forme zéros-pôles-gain, dont la
    % conception numérique est plus stable que celle des coefficients.
    if nargout > 2
        b = zNum;
        a = pNum;
        k = kNum;
    end
end
