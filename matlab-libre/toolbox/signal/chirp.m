function y = chirp(t, f0, t1, f1, methode)
%CHIRP Sinusoïde à fréquence instantanée variable.
%   Y = CHIRP(T,F0,T1,F1) balaie linéairement de F0 (à t=0) à F1 (à t=T1).
%   Y = CHIRP(T,F0,T1,F1,'quadratic') fait un balayage quadratique.
    if nargin < 5
        methode = 'linear';
    end
    switch lower(char(methode))
        case 'quadratic'
            beta = (f1 - f0) / (t1 ^ 2);
            phase = 2 * pi * (f0 * t + beta / 3 * t .^ 3);
        case 'logarithmic'
            beta = (f1 / f0) ^ (1 / t1);
            phase = 2 * pi * f0 * (beta .^ t - 1) / log(beta);
        otherwise
            beta = (f1 - f0) / t1;
            phase = 2 * pi * (f0 * t + beta / 2 * t .^ 2);
    end
    y = cos(phase);
end
