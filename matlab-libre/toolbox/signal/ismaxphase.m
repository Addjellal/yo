function tf = ismaxphase(b, a)
%ISMAXPHASE Le filtre est-il à phase maximale ?
%   Tous les zéros sont hors du cercle unité, les pôles dedans.
    if nargin < 2, a = 1; end
    z = racinesFiltre(b);
    tf = isstable(1, a) && ~isempty(z) && all(abs(z) > 1);
end

function r = racinesFiltre(c)
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
