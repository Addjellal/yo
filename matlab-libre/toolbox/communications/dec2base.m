function s = dec2base(d, base, longueur)
%DEC2BASE Entier vers chaîne dans une base quelconque.
    chiffres = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    s = '';
    v = round(d);
    while v > 0
        s = [chiffres(mod(v, base) + 1), s];
        v = floor(v / base);
    end
    if isempty(s)
        s = '0';
    end
    if nargin > 2
        while numel(s) < longueur
            s = ['0', s];
        end
    end
end
