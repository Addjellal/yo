function tf = isminphase(b, a)
%ISMINPHASE Le filtre est-il à phase minimale ?
%   Tous les zéros et tous les pôles doivent être dans le cercle unité.
    if nargin < 2, a = 1; end
    tf = isstable(1, a) && all(abs(racines(b)) < 1);
end

function r = racines(c)
    c = double(c(:)).';
    while numel(c) > 1 && c(1) == 0
        c(1) = [];
    end
    if numel(c) <= 1
        r = zeros(0, 1);
    else
        r = roots(c);
    end
end
