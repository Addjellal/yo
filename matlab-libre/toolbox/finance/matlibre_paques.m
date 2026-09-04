function jour = matlibre_paques(annee)
%MATLIBRE_PAQUES Dimanche de Pâques grégorien.
%   Pâques est le premier dimanche après la première pleine lune
%   ecclésiastique qui suit l'équinoxe de printemps. L'algorithme est
%   celui, sans conditions, publié anonymement dans Nature en 1876 :
%   il traduit directement les règles du comput.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    a = mod(annee, 19);
    b = floor(annee / 100);
    c = mod(annee, 100);
    d = floor(b / 4);
    e = mod(b, 4);
    f = floor((b + 8) / 25);
    g = floor((b - f + 1) / 3);
    h = mod(19 * a + b - d - g + 15, 30);
    i = floor(c / 4);
    k = mod(c, 4);
    l = mod(32 + 2 * e + 2 * i - h - k, 7);
    m = floor((a + 11 * h + 22 * l) / 451);
    mois = floor((h + l - 7 * m + 114) / 31);
    date = mod(h + l - 7 * m + 114, 31) + 1;
    jour = datenum(annee, mois, date);
end
