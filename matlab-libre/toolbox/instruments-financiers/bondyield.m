function taux = bondyield(prix, coupon, echeance, nominal, frequence)
%BONDYIELD Taux actuariel d'une obligation, par dichotomie.
%   TAUX = BONDYIELD(PRIX,COUPON,ECHEANCE,NOMINAL,FREQUENCE) rend le taux
%   actuariel : celui qui, appliqué à tous les flux, redonne exactement
%   PRIX. NOMINAL vaut 100 et FREQUENCE 1 par défaut. Le zéro est cherché
%   entre -99 % et 1000 %.
%
%   Le prix est une fonction strictement décroissante du taux, ce qui rend
%   le taux actuariel unique et le calcul par dichotomie sûr — à la
%   différence du taux de rendement interne d'un projet quelconque, dont
%   les flux changent plusieurs fois de signe.
%
%   C'est le taux de rendement effectif si l'obligation est portée jusqu'à
%   l'échéance et si les coupons sont replacés à ce même taux. Cette
%   seconde hypothèse est rarement vérifiée, et l'écart entre le rendement
%   annoncé et le rendement réalisé vient d'elle. Une obligation cotée
%   au-dessus du pair a un taux actuariel inférieur à son coupon, et
%   inversement.
%
%   Exemple :
%      bondyield(bondprice(0.05, 0.06, 10), 0.06, 10)
%
%   Voir aussi BONDPRICE, BONDDUR, BONDCONVEXITY.
    if nargin < 4, nominal = 100; end
    if nargin < 5, frequence = 1; end
    f = @(t) bondprice(t, coupon, echeance, nominal, frequence) - prix;
    taux = fzero(f, [-0.99, 10]);
end
