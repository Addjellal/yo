function x = dpskdemod(y, M, phase)
%DPSKDEMOD Démodulation par déplacement de phase différentiel.
    if nargin < 3, phase = 0; end
    y = y(:);
    n = numel(y);
    x = zeros(n, 1);
    precedent = exp(1i * phase);
    for k = 1:n
        ecart = angle(y(k) / precedent);
        x(k) = mod(round(ecart * M / (2 * pi)), M);
        precedent = y(k);
    end
end
