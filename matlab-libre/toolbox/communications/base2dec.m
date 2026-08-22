function d = base2dec(chaine, base)
%BASE2DEC Chaîne dans une base quelconque vers entier.
    chaine = upper(strtrim(char(chaine)));
    d = 0;
    for k = 1:numel(chaine)
        c = chaine(k);
        if c >= '0' && c <= '9'
            v = double(c) - double('0');
        else
            v = double(c) - double('A') + 10;
        end
        d = d * base + v;
    end
end
