function interets = acrubond(emission, reglement, premierCoupon, valeurFaciale, tauxCoupon, periode, base)
%ACRUBOND Intérêts courus d'une obligation à coupons.
%   I = ACRUBOND(EMISSION,REGLEMENT,PREMIERCOUPON,FACE,TAUX) rend les
%   intérêts courus depuis le dernier coupon jusqu'à la date de
%   règlement.
%
%   Une obligation vendue entre deux coupons se paie au prix coté plus
%   les intérêts courus : le vendeur a droit à la part du coupon qui
%   correspond au temps où il détenait le titre, et c'est l'acheteur qui
%   touchera le coupon entier.
%
%   Exemple :
%      acrubond('01-Jan-2024', '15-Mar-2024', '01-Jul-2024', 100, 0.05, 2, 0)
%
%   Voir aussi ACRUDISC, BNDPRICE, CFAMOUNTS.
    if nargin < 6 || isempty(periode), periode = 2; end
    if nargin < 7 || isempty(base),    base = 0;    end
    emission = matlibre_dates(emission);
    reglement = matlibre_dates(reglement);
    premierCoupon = matlibre_dates(premierCoupon);
    % Dernière date de coupon avant le règlement : on recule depuis le
    % premier coupon, de mois en mois selon la fréquence.
    moisParPeriode = round(12 / periode);
    precedent = premierCoupon;
    while precedent > reglement
        candidat = datemnth(precedent, -moisParPeriode);
        if candidat < emission
            precedent = emission;
            break
        end
        precedent = candidat;
    end
    if precedent < emission
        precedent = emission;
    end
    suivant = datemnth(precedent, moisParPeriode);
    if suivant <= precedent
        suivant = premierCoupon;
    end
    ecoule = yearfrac(precedent, reglement, base);
    complet = yearfrac(precedent, suivant, base);
    if complet <= 0
        interets = 0;
    else
        interets = valeurFaciale .* tauxCoupon ./ periode .* (ecoule ./ complet);
    end
end
