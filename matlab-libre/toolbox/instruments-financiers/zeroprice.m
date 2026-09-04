function prix = zeroprice(rendement, reglement, echeance, periode, base)
%ZEROPRICE Prix d'une obligation zéro-coupon.
%   P = ZEROPRICE(RENDEMENT,REGLEMENT,ECHEANCE,PERIODE,BASE) rend le prix
%   pour cent de nominal. PERIODE vaut 2 par défaut : le rendement est
%   composé semestriellement, comme le veut la convention obligataire.
%
%   Une obligation sans coupon ne verse rien avant l'échéance : son prix
%   est le seul facteur d'actualisation, et sa duration est sa maturité.
%
%   Exemple :
%      zeroprice(0.05, '01-Jan-2024', '01-Jan-2029')
%
%   Voir aussi ZEROYIELD, BONDBYZERO, BNDPRICE.
    if nargin < 4 || isempty(periode), periode = 2; end
    if nargin < 5 || isempty(base),    base = 0;    end
    annees = yearfrac(reglement, echeance, base);
    prix = 100 * matlibre_escompte(rendement, annees, periode);
end
