function c = bondconvexity(taux, coupon, echeance, nominal, frequence)
%BONDCONVEXITY Convexité d'une obligation.
    if nargin < 4, nominal = 100; end
    if nargin < 5, frequence = 1; end
    n = round(echeance * frequence);
    coup = coupon * nominal / frequence;
    r = taux / frequence;
    prix = bondprice(taux, coupon, echeance, nominal, frequence);
    somme = 0;
    for k = 1:n
        flux = coup;
        if k == n
            flux = flux + nominal;
        end
        somme = somme + k * (k + 1) * flux / (1 + r) ^ (k + 2);
    end
    c = somme / (prix * frequence ^ 2);
end
