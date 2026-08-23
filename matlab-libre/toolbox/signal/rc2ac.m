function r = rc2ac(k, r0)
%RC2AC Autocorrélation à partir des coefficients de réflexion.
%   R = RC2AC(K,R0) remonte la récurrence de Levinson : à chaque ordre,
%   le nouveau terme d'autocorrélation se déduit du polynôme courant.
    k = double(k(:));
    r = r0;
    a = 1;
    e = r0;
    for m = 1:numel(k)
        % Le terme suivant est celui qui fait de K(m) le coefficient de
        % réflexion d'ordre m.
        acc = 0;
        for i = 1:m-1
            acc = acc + a(i + 1) * r(m - i + 1);
        end
        r(m + 1, 1) = -k(m) * e - acc;
        a = [a 0] + k(m) * [0 conj(fliplr(a))];
        e = e * (1 - abs(k(m)) ^ 2);
    end
end
