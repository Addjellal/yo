function dates = cfdates(reglement, echeance, periode, base, regleFinMois)
%CFDATES Dates de coupon d'une obligation.
%   D = CFDATES(REGLEMENT,ECHEANCE) rend les dates auxquelles
%   l'obligation verse un coupon, entre le règlement et l'échéance
%   comprise. PERIODE vaut 2 par défaut : deux coupons par an.
%
%   Le calendrier se construit en reculant depuis l'échéance : c'est elle
%   qui commande, non la date de règlement. Une obligation échéant le 31
%   août verse ses coupons les 28 ou 29 février, non les 28 août.
%
%   Exemple :
%      datestr(cfdates('01-Feb-2024', '15-Aug-2026'))
%
%   Voir aussi CFAMOUNTS, BNDPRICE, ACRUBOND, DATEMNTH.
    if nargin < 3 || isempty(periode),      periode = 2;      end
    if nargin < 4 || isempty(base),         base = 0;         end   %#ok<NASGU>
    if nargin < 5 || isempty(regleFinMois), regleFinMois = 1; end
    dates = matlibre_echeancier(reglement, echeance, periode, regleFinMois).';
end
