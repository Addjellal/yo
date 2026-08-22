function x = pskdemod(y, M, phase)
%PSKDEMOD Démodulation de phase à M états, par décision du plus proche.
    if nargin < 3
        phase = 0;
    end
    a = angle(y) - phase;
    x = mod(round(a * M / (2 * pi)), M);
end
