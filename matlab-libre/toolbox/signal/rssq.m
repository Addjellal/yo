function r = rssq(x, dim)
%RSSQ Racine de la somme des carrés.
%   Exemple :  rssq([3 4])   % 5
    if nargin < 2
        if isvector(x), r = sqrt(sum(abs(x(:)).^2)); return, end
        dim = 1;
    end
    r = sqrt(sum(abs(x).^2, dim));
end
