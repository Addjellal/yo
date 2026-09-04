function rendement = zeroyield(prix, reglement, echeance, periode, base)
%ZEROYIELD Rendement d'une obligation zéro-coupon.
%   R = ZEROYIELD(PRIX,REGLEMENT,ECHEANCE,PERIODE,BASE) est l'inverse de
%   ZEROPRICE.
%
%   Exemple :
%      zeroyield(78.35, '01-Jan-2024', '01-Jan-2029')
%
%   Voir aussi ZEROPRICE, BNDYIELD.
    if nargin < 4 || isempty(periode), periode = 2; end
    if nargin < 5 || isempty(base),    base = 0;    end
    annees = yearfrac(reglement, echeance, base);
    facteur = double(prix) / 100;
    rendement = matlibre_escompte_vers_taux(facteur, annees, periode);
end
