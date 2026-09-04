function rendement = bndyield(prix, tauxCoupon, reglement, echeance, periode, base, regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale)
%BNDYIELD Rendement à l'échéance d'une obligation.
%   R = BNDYIELD(PRIX,TAUX,REGLEMENT,ECHEANCE) rend le taux qui, appliqué
%   à tous les flux, redonne le prix observé. C'est l'inverse de
%   BNDPRICE.
%
%   Le prix décroît strictement avec le rendement : la solution est donc
%   unique, et se trouve par recherche de zéro.
%
%   Exemple :
%      p = bndprice(0.06, 0.05, '01-Feb-2024', '01-Feb-2034');
%      bndyield(p, 0.05, '01-Feb-2024', '01-Feb-2034')     % 0.06
%
%   Voir aussi BNDPRICE, BNDDURP, CFYIELD, IRR.
    if nargin < 5,  periode = [];       end
    if nargin < 6,  base = [];          end
    if nargin < 7,  regleFinMois = [];  end
    if nargin < 8,  emission = [];      end
    if nargin < 9,  premierCoupon = []; end
    if nargin < 10, dernierCoupon = []; end
    if nargin < 11, debut = [];         end
    if nargin < 12, valeurFaciale = []; end
    ecart = @(y) bndprice(y, tauxCoupon, reglement, echeance, periode, base, ...
        regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale) - prix;
    bas = -0.99;
    haut = 1;
    while ecart(haut) > 0 && haut < 1e4
        haut = haut * 2;
    end
    rendement = fzero(ecart, [bas, haut]);
end
