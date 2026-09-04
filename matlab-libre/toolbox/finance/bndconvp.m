function [convexiteAnnees, convexitePeriodes] = bndconvp(prix, tauxCoupon, reglement, echeance, periode, base, regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale)
%BNDCONVP Convexité d'une obligation, à partir de son prix.
%   Même chose que BNDCONVY, le rendement étant d'abord déduit du prix.
%
%   Voir aussi BNDCONVY, BNDDURP, BNDYIELD.
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
    [convexiteAnnees, convexitePeriodes] = bndconvy(rendement, tauxCoupon, reglement, ...
        echeance, periode, base, regleFinMois, emission, premierCoupon, dernierCoupon, ...
        debut, valeurFaciale);
end
