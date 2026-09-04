function [prix, interetsCourus] = bndprice(rendement, tauxCoupon, reglement, echeance, periode, base, regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale)
%BNDPRICE Prix d'une obligation à coupons, à partir de son rendement.
%   [P,I] = BNDPRICE(RENDEMENT,TAUX,REGLEMENT,ECHEANCE) rend le prix
%   coté, pour cent de nominal, et les intérêts courus. Le prix payé est
%   la somme des deux.
%
%   PERIODE vaut 2 par défaut, BASE 0. Le rendement est composé PERIODE
%   fois par an, comme le veut la convention obligataire.
%
%   Le prix est la valeur actuelle des flux à venir. Quand le rendement
%   égale le taux de coupon, elle vaut exactement le nominal : c'est la
%   définition du pair. Au-dessus, le titre cote en dessous du pair,
%   puisqu'il faut un gain en capital pour compenser un coupon trop
%   faible.
%
%   Exemple :
%      bndprice(0.06, 0.05, '01-Feb-2024', '01-Feb-2034')
%
%   Voir aussi BNDYIELD, BNDDURP, BNDDURY, BNDCONVP, CFAMOUNTS.
    if nargin < 5,  periode = [];       end
    if nargin < 6,  base = [];          end
    if nargin < 7,  regleFinMois = [];  end
    if nargin < 8,  emission = [];      end
    if nargin < 9,  premierCoupon = []; end
    if nargin < 10, dernierCoupon = []; end
    if nargin < 11, debut = [];         end
    if nargin < 12, valeurFaciale = []; end
    if isempty(periode), periode = 2; end
    [montants, ~, facteurs] = cfamounts(tauxCoupon, reglement, echeance, periode, ...
        base, regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale);
    interetsCourus = -montants(1);
    escompte = (1 + rendement / periode) .^ (-facteurs(2:end));
    prix = sum(montants(2:end) .* escompte) - interetsCourus;
end
