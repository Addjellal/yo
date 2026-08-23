function d = finddelay(x, y, maxDecalage)
%FINDDELAY Retard entre deux signaux, par corrélation croisée.
%   D = FINDDELAY(X,Y) : Y est en retard de D échantillons sur X quand D
%   est positif.
%
%   Exemple :
%      x = [1 2 3 0 0]; y = [0 0 1 2 3]; finddelay(x, y)   % 2
    x = x(:);
    y = y(:);
    if nargin < 3 || isempty(maxDecalage)
        [c, decalages] = xcorr(y, x);
    else
        [c, decalages] = xcorr(y, x, maxDecalage);
    end
    [~, k] = max(abs(c));
    d = decalages(k);
end
