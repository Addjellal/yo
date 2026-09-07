function r = poly2ac(a, efinal)
%POLY2AC Autocorrélation d'un polynôme de prédiction.
%   R = POLY2AC(A,EFINAL) rend la suite d'autocorrélation dont A est le
%   filtre de prédiction et EFINAL l'erreur résiduelle.
%
%   Exemple :
%      a = [1 -0.5 0.2];
%      r = poly2ac(a, 1);
%      max(abs(ac2poly(r) - a)) < 1e-10       % l'aller-retour
    [k, e] = poly2rc(a, efinal);
    if isempty(k)
        r = efinal;
        return
    end
    r0 = e(1) / (1 - abs(k(1)) ^ 2);
    r = rc2ac(k, r0);
end
