function rendement = ylddisc(reglement, echeance, valeurFaciale, prix, base)
%YLDDISC Rendement d'un titre vendu à escompte.
%   R = YLDDISC(REGLEMENT,ECHEANCE,FACE,PRIX) rend le gain rapporté au
%   prix payé, ramené à l'année.
%
%   Exemple :
%      ylddisc('01-Feb-2024', '01-Aug-2024', 100, 97.5, 2)
%
%   Voir aussi PRDISC, DISCRATE, FVDISC, YLDTBILL.
    if nargin < 5 || isempty(base)
        base = 0;
    end
    fraction = yearfrac(reglement, echeance, base);
    rendement = (valeurFaciale - prix) ./ (prix .* fraction);
end
