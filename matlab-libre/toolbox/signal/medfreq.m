function f = medfreq(x, fs)
%MEDFREQ Fréquence médiane : celle qui coupe la puissance en deux.
    if nargin < 2, fs = 1; end
    x = x(:);
    [pxx, freq] = periodogram(x, [], numel(x), fs);
    cumule = cumtrapz(freq, pxx);
    if cumule(end) <= 0
        f = 0;
        return
    end
    cible = cumule(end) / 2;
    k = find(cumule >= cible, 1);
    if isempty(k) || k == 1
        f = freq(1);
    else
        % Interpolation linéaire entre les deux points qui encadrent.
        f = freq(k-1) + (cible - cumule(k-1)) * (freq(k) - freq(k-1)) / ...
            (cumule(k) - cumule(k-1));
    end
end
