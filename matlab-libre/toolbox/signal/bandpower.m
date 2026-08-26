function p = bandpower(x, fs, bande)
%BANDPOWER Puissance moyenne d'un signal, éventuellement dans une bande.
%   P = BANDPOWER(X) rend la puissance moyenne, soit la moyenne des
%   carrés. P = BANDPOWER(X,FS,[F1 F2]) la restreint à une bande, par
%   intégration du périodogramme.
%
%   Exemple :
%      bandpower([1 -1 1 -1])   % 1
    if nargin < 2
        p = sum(abs(x(:)).^2) / numel(x);
        return
    end
    x = x(:);
    n = numel(x);
    [pxx, f] = periodogram(x, [], n, fs);
    if nargin < 3 || isempty(bande)
        p = trapz(f, pxx);
        return
    end
    dedans = f >= bande(1) & f <= bande(2);
    if sum(dedans) < 2
        p = 0;
    else
        p = trapz(f(dedans), pxx(dedans));
    end
end
