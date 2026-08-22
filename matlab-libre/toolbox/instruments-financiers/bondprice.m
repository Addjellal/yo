function prix = bondprice(taux, coupon, echeance, nominal, frequence)
%BONDPRICE Prix d'une obligation à coupons constants.
%   PRIX = BONDPRICE(TAUX,COUPON,ECHEANCE,NOMINAL,FREQUENCE)
    if nargin < 4, nominal = 100; end
    if nargin < 5, frequence = 1; end
    n = round(echeance * frequence);
    c = coupon * nominal / frequence;
    r = taux / frequence;
    prix = 0;
    for k = 1:n
        prix = prix + c / (1 + r) ^ k;
    end
    prix = prix + nominal / (1 + r) ^ n;
end
