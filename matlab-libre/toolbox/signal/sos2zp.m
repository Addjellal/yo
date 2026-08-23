function [z, p, k] = sos2zp(sos, g)
%SOS2ZP Zéros, pôles et gain d'un enchaînement de sections du second ordre.
%   [Z,P,K] = SOS2ZP(SOS,G) où SOS a une section par ligne, sous la forme
%   [b0 b1 b2 a0 a1 a2].
    if nargin < 2, g = 1; end
    z = [];
    p = [];
    k = g;
    for section = 1:size(sos, 1)
        b = sos(section, 1:3);
        a = sos(section, 4:6);
        k = k * b(1) / a(1);
        z = [z; racinesUtiles(b)];      %#ok<AGROW>
        p = [p; racinesUtiles(a)];      %#ok<AGROW>
    end
end

function r = racinesUtiles(c)
    while numel(c) > 1 && c(1) == 0
        c(1) = [];
    end
    if numel(c) <= 1
        r = zeros(0, 1);
    else
        r = roots(c);
        r = r(:);
    end
end
