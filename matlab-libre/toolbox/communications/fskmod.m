function y = fskmod(x, M, ecart, nEchantillons, fs)
%FSKMOD Modulation par déplacement de fréquence.
%   Y = FSKMOD(X,M,ECART,NECH,FS) : chaque symbole devient NECH
%   échantillons d'une sinusoïde dont la fréquence dépend du symbole.
%
%   Exemple :
%      y = fskmod([0 1], 2, 100, 8, 1000);   % 16 échantillons
    if nargin < 5, fs = 1; end
    x = x(:);
    n = numel(x);
    y = zeros(n * nEchantillons, 1);
    t = (0:nEchantillons-1)' / fs;
    for k = 1:n
        f = (2 * x(k) - (M - 1)) * ecart / 2;
        y((k-1)*nEchantillons + (1:nEchantillons)) = exp(1i * 2 * pi * f * t);
    end
end
