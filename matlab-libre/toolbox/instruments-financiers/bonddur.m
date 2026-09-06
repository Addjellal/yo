function [macaulay, modifiee] = bonddur(taux, coupon, echeance, nominal, frequence)
%BONDDUR Durations de Macaulay et modifiée.
%   [MACAULAY,MODIFIEE] = BONDDUR(TAUX,COUPON,ECHEANCE,NOMINAL,FREQUENCE)
%   rend la duration de Macaulay, en années, et la duration modifiée.
%   NOMINAL vaut 100 et FREQUENCE 1 par défaut.
%
%   La duration de Macaulay est la date moyenne des flux, pondérée par
%   leur valeur actuelle : le centre de gravité de l'échéancier. Une
%   obligation sans coupon a une duration égale à sa maturité ; les
%   coupons, qui rendent de l'argent plus tôt, la raccourcissent.
%
%   La duration modifiée en est la conséquence pratique : elle vaut
%   Macaulay/(1+TAUX/FREQUENCE) et donne directement la sensibilité
%   relative du prix — une hausse d'un point de taux fait perdre environ
%   MODIFIEE pour cent. C'est l'unité de mesure du risque de taux, et
%   celle dans laquelle se couvre un portefeuille obligataire.
%
%   L'approximation n'est que du premier ordre : pour de fortes variations
%   de taux, il faut y ajouter le terme de convexité.
%
%   Exemple :
%      [m, mo] = bonddur(0.05, 0.06, 10);
%
%   Voir aussi BONDCONVEXITY, BONDPRICE, BONDYIELD.
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
