function x = fskdemod(y, M, ecart, nEchantillons, fs)
%FSKDEMOD Démodulation par déplacement de fréquence, par corrélation.
    if nargin < 5, fs = 1; end
    y = y(:);
    n = floor(numel(y) / nEchantillons);
    x = zeros(n, 1);
    t = (0:nEchantillons-1)' / fs;
    for k = 1:n
        bloc = y((k-1)*nEchantillons + (1:nEchantillons));
        meilleur = -inf;
        for m = 0:M-1
            f = (2 * m - (M - 1)) * ecart / 2;
            correlation = abs(sum(bloc .* conj(exp(1i * 2 * pi * f * t))));
            if correlation > meilleur
                meilleur = correlation;
                x(k) = m;
            end
        end
    end
end
