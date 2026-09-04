function prix = bondbyzero(courbe, tauxCoupon, reglement, echeance, periode, base, regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale)
%BONDBYZERO Prix d'une obligation, sur une courbe zéro-coupon.
%   P = BONDBYZERO(COURBE,TAUX,REGLEMENT,ECHEANCE) actualise chaque flux
%   au taux de sa propre date, au lieu de tous les actualiser au même
%   rendement à l'échéance.
%
%   C'est la valorisation juste : un rendement unique n'est qu'une façon
%   de résumer un prix par un nombre, et deux obligations de même
%   échéance mais de coupons différents n'ont pas le même rendement même
%   quand elles sont valorisées sur la même courbe.
%
%   Exemple :
%      bondbyzero(courbe, 0.05, '01-Jan-2024', '01-Jan-2029')
%
%   Voir aussi CFBYZERO, FIXEDBYZERO, SWAPBYZERO, BNDPRICE, INTENVPRICE.
    if nargin < 5,  periode = [];       end
    if nargin < 6,  base = [];          end
    if nargin < 7,  regleFinMois = [];  end
    if nargin < 8,  emission = [];      end
    if nargin < 9,  premierCoupon = []; end
    if nargin < 10, dernierCoupon = []; end
    if nargin < 11, debut = [];         end
    if nargin < 12, valeurFaciale = []; end
    if isempty(periode), periode = 2; end
    tauxCoupon = double(tauxCoupon(:));
    echeance = matlibre_dates(echeance);
    echeance = echeance(:);
    [tauxCoupon, echeance] = matlibre_diffuser_dates(tauxCoupon, echeance);
    prix = zeros(numel(tauxCoupon), 1);
    for k = 1:numel(tauxCoupon)
        [montants, dates] = cfamounts(tauxCoupon(k), reglement, echeance(k), ...
            periode, base, regleFinMois, emission, premierCoupon, dernierCoupon, ...
            debut, valeurFaciale);
        courus = -montants(1);
        facteurs = matlibre_courbe_escompte(courbe, dates(2:end));
        prix(k) = sum(montants(2:end).' .* facteurs(:)) - courus;
    end
end
