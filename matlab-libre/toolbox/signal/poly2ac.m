function r = poly2ac(a, efinal)
%POLY2AC Autocorrélation d'un polynôme de prédiction.
%   R = POLY2AC(A,EFINAL) rend la suite d'autocorrélation dont A est le
%   filtre de prédiction et EFINAL l'erreur résiduelle.
    [k, e] = poly2rc(a, efinal);
    if isempty(k)
        r = efinal;
        return
    end
    r0 = e(1) / (1 - abs(k(1)) ^ 2);
    r = rc2ac(k, r0);
end
