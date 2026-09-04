function [dureeModifiee, dureeAnnees, dureePeriodes] = bnddurp(prix, tauxCoupon, reglement, echeance, periode, base, regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale)
%BNDDURP Sensibilité d'une obligation, à partir de son prix.
%   Même chose que BNDDURY, le rendement étant d'abord déduit du prix.
%
%   Exemple :
%      bnddurp(92.5, 0.05, '01-Feb-2024', '01-Feb-2034')
%
%   Voir aussi BNDDURY, BNDCONVP, BNDYIELD.
    if nargin < 5,  periode = [];       end
    if nargin < 6,  base = [];          end
    if nargin < 7,  regleFinMois = [];  end
    if nargin < 8,  emission = [];      end
    if nargin < 9,  premierCoupon = []; end
    if nargin < 10, dernierCoupon = []; end
    if nargin < 11, debut = [];         end
    if nargin < 12, valeurFaciale = []; end
    rendement = bndyield(prix, tauxCoupon, reglement, echeance, periode, base, ...
        regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale);
    [dureeModifiee, dureeAnnees, dureePeriodes] = bnddury(rendement, tauxCoupon, ...
        reglement, echeance, periode, base, regleFinMois, emission, premierCoupon, ...
        dernierCoupon, debut, valeurFaciale);
end
