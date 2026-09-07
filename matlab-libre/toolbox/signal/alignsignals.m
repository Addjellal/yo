function [xa, ya, d] = alignsignals(x, y, maxDecalage)
%ALIGNSIGNALS Aligne deux signaux en compensant leur retard.
%   [XA,YA,D] = ALIGNSIGNALS(X,Y) ajoute des zéros en tête du signal en
%   avance, de sorte que les deux se superposent.
%
%   Exemple :
%      x = [0 0 1 2 3 0];
%      [xa, ya, d] = alignsignals(x, [1 2 3 0 0 0]);
%      d                           % le decalage retrouve
    if nargin < 3, maxDecalage = []; end
    d = finddelay(x, y, maxDecalage);
    x = x(:);
    y = y(:);
    if d > 0
        xa = [zeros(d, 1); x];
        ya = y;
    elseif d < 0
        xa = x;
        ya = [zeros(-d, 1); y];
    else
        xa = x;
        ya = y;
    end
    n = max(numel(xa), numel(ya));
    xa(end+1:n) = 0;
    ya(end+1:n) = 0;
end
