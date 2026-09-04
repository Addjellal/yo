function prix = prdisc(reglement, echeance, escompte, valeurFaciale, base)
%PRDISC Prix d'un titre vendu à escompte.
%   P = PRDISC(REGLEMENT,ECHEANCE,ESCOMPTE,FACE) rend le prix d'un titre
%   qui ne verse pas d'intérêt et se rembourse à FACE : il s'achète en
%   dessous du pair, et l'écart est l'intérêt.
%
%   Le taux d'escompte se compte sur la valeur de remboursement, non sur
%   le prix payé : c'est ce qui le distingue d'un rendement, et le rend
%   toujours plus petit que lui.
%
%   Exemple :
%      prdisc('01-Feb-2024', '01-Aug-2024', 0.05, 100, 2)
%
%   Voir aussi YLDDISC, DISCRATE, FVDISC, ACRUDISC, PRTBILL.
    if nargin < 4 || isempty(valeurFaciale), valeurFaciale = 100; end
    if nargin < 5 || isempty(base),          base = 0;            end
    fraction = yearfrac(reglement, echeance, base);
    prix = valeurFaciale .* (1 - escompte .* fraction);
end
