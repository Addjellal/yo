function fraction = yearfrac(depart, arrivee, base)
%YEARFRAC Fraction d'année entre deux dates, selon une convention de calcul.
%   F = YEARFRAC(D1,D2,BASE) rend la part d'année écoulée entre D1 et D2.
%   BASE choisit la convention :
%      0  réel/réel (défaut)          7  réel/365 japonais
%      1  30/360 américaine           8  réel/réel ISMA
%      2  réel/360                    9  réel/360 ISMA
%      3  réel/365                   10  réel/365 ISMA
%      4  30/360 PSA                 11  30/360E ISMA
%      5  30/360 ISDA                12  réel/365 ISDA
%      6  30E/360 européenne         13  jours ouvrés sur 252
%
%   Une convention n'est pas une approximation de l'autre : elles
%   répondent à des contrats différents. Un prêt à taux annuel sur base
%   réel/360 rapporte plus qu'un prêt sur base réel/365, au même taux
%   affiché, parce qu'il compte plus de fractions d'année dans l'année.
%
%   Exemple :
%      yearfrac('01-Jan-2000', '01-Jan-2001', 0)   % 1 exactement
%      yearfrac('01-Jan-2000', '01-Jan-2001', 2)   % 366/360
%
%   Voir aussi DAYS360, DAYS365, DAYSACT, DAYSDIF.
    if nargin < 3 || isempty(base)
        base = 0;
    end
    [debut, fin] = matlibre_diffuser_dates(matlibre_dates(depart), matlibre_dates(arrivee));
    [debut, base] = matlibre_diffuser_dates(debut, matlibre_dates(base));
    [fin, base] = matlibre_diffuser_dates(fin, base);
    fraction = zeros(size(debut));
    for k = 1:numel(debut)
        fraction(k) = une(debut(k), fin(k), round(base(k)));
    end
end

function f = une(d1, d2, base)
    switch base
        case {0, 8}
            f = matlibre_reel_sur_reel(d1, d2);
        case 1
            f = days360(d1, d2) / 360;
        case {2, 9}
            f = daysact(d1, d2) / 360;
        case {3, 10}
            f = daysact(d1, d2) / 365;
        case 4
            f = days360psa(d1, d2) / 360;
        case 5
            f = days360isda(d1, d2) / 360;
        case {6, 11}
            f = days360e(d1, d2) / 360;
        case 7
            f = days365(d1, d2) / 365;
        case 12
            f = matlibre_reel_sur_reel(d1, d2);
        case 13
            f = numel(matlibre_jours_ouvres(d1, d2)) / 252;
        otherwise
            error('finance:yearfrac:Base', ...
                  'La base doit être un entier de zéro à treize.');
    end
end
