function [macaulay, modifiee] = bonddur(taux, coupon, echeance, nominal, frequence)
%BONDDUR Durations de Macaulay et modifiée.
    if nargin < 4, nominal = 100; end
    if nargin < 5, frequence = 1; end
    n = round(echeance * frequence);
    c = coupon * nominal / frequence;
    r = taux / frequence;
    prix = bondprice(taux, coupon, echeance, nominal, frequence);
    somme = 0;
    for k = 1:n
        flux = c;
        if k == n
            flux = flux + nominal;
        end
        somme = somme + (k / frequence) * flux / (1 + r) ^ k;
    end
    macaulay = somme / prix;
    modifiee = macaulay / (1 + r);
end
