function [tauxPair, datesCourbe] = zero2pyld(tauxZero, datesCourbe, reglement, composition, base)
%ZERO2PYLD Taux au pair déduits d'une courbe zéro-coupon.
%   [P,D] = ZERO2PYLD(Z,DATES,REGLEMENT) rend, pour chaque échéance, le
%   taux de coupon qui ferait coter l'obligation exactement au pair.
%
%   Les dates de la courbe servent de dates de coupon : la courbe doit
%   donc être donnée au pas de la composition.
%
%   Exemple :
%      [p, d] = zero2pyld([0.02 0.025 0.03], ...
%          {'01-Aug-2024','01-Feb-2025','01-Aug-2025'}, '01-Feb-2024')
%
%   Voir aussi PYLD2ZERO, ZERO2DISC, ZBTYIELD, BNDPRICE.
    if nargin < 4 || isempty(composition), composition = 2; end
    if nargin < 5 || isempty(base),        base = 0;        end
    facteurs = zero2disc(tauxZero, datesCourbe, reglement, composition, base);
    datesCourbe = matlibre_dates(datesCourbe);
    datesCourbe = datesCourbe(:);
    cumul = cumsum(facteurs);
    tauxPair = composition * (1 - facteurs) ./ cumul;
end
