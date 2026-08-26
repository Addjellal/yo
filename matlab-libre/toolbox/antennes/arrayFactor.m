function AF = arrayFactor(n, d, theta, phase)
%ARRAYFACTOR Facteur d'un réseau linéaire uniforme.
%   AF = ARRAYFACTOR(N,D,THETA,PHASE) pour N éléments espacés de D
%   longueurs d'onde, THETA en radians, PHASE le déphasage progressif.
    if nargin < 4
        phase = 0;
    end
    psi = 2 * pi * d * cos(theta) + phase;
    AF = zeros(size(theta));
    for k = 1:numel(psi)
        if abs(sin(psi(k) / 2)) < 1e-12
            AF(k) = n;
        else
            AF(k) = abs(sin(n * psi(k) / 2) / sin(psi(k) / 2));
        end
    end
end
