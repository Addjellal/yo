function taux = bondyield(prix, coupon, echeance, nominal, frequence)
%BONDYIELD Taux actuariel d'une obligation, par dichotomie.
    if nargin < 4, nominal = 100; end
    if nargin < 5, frequence = 1; end
    f = @(t) bondprice(t, coupon, echeance, nominal, frequence) - prix;
    taux = fzero(f, [-0.99, 10]);
end
