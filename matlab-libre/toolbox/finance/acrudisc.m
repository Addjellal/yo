function interets = acrudisc(reglement, echeance, valeurFaciale, escompte, periode, base)
%ACRUDISC Intérêts courus d'un titre vendu à escompte.
%   I = ACRUDISC(REGLEMENT,ECHEANCE,FACE,ESCOMPTE) rend l'écart entre la
%   valeur de remboursement et le prix : c'est ce que le titre a couru
%   d'intérêt à la date de règlement.
%
%   Exemple :
%      acrudisc('01-Feb-2024', '01-Aug-2024', 100, 0.05, 2, 2)
%
%   Voir aussi ACRUBOND, PRDISC, DISCRATE.
    if nargin < 5 || isempty(periode), periode = 2; end   %#ok<NASGU>
    if nargin < 6 || isempty(base),    base = 0;    end
    interets = valeurFaciale - prdisc(reglement, echeance, escompte, valeurFaciale, base);
end
