function c = bondconvexity(taux, coupon, echeance, nominal, frequence)
%BONDCONVEXITY Convexité d'une obligation.
%   C = BONDCONVEXITY(TAUX,COUPON,ECHEANCE,NOMINAL,FREQUENCE) rend la
%   convexité d'une obligation : la dérivée seconde du prix par rapport au
%   taux, divisée par le prix. NOMINAL vaut 100 et FREQUENCE 1 par défaut.
%
%   La duration donne la pente de la courbe prix-taux, la convexité sa
%   courbure. Le développement au second ordre s'écrit
%   dP/P = -Dm*dr + C*dr^2/2 : la duration seule surestime toujours la
%   perte quand les taux montent et sous-estime le gain quand ils
%   baissent, et la convexité corrige cet écart.
%
%   Elle est positive pour une obligation ordinaire, ce qui est une bonne
%   nouvelle pour son détenteur : à duration égale, l'obligation la plus
%   convexe gagne plus et perd moins. Cet avantage se paie — les titres
%   très convexes se négocient à un taux légèrement inférieur.
%
%   Exemple :
%      bondconvexity(0.05, 0.06, 10)
%
%   Voir aussi BONDDUR, BONDPRICE, BONDYIELD.
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
