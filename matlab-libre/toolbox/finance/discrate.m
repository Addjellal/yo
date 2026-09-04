function escompte = discrate(reglement, echeance, valeurFaciale, prix, base)
%DISCRATE Taux d'escompte d'un titre.
%   E = DISCRATE(REGLEMENT,ECHEANCE,FACE,PRIX) rend le gain rapporté à la
%   valeur de remboursement, ramené à l'année. C'est la convention des
%   bons du Trésor.
%
%   Exemple :
%      discrate('01-Feb-2024', '01-Aug-2024', 100, 97.5, 2)
%
%   Voir aussi PRDISC, YLDDISC, FVDISC, PRTBILL.
    if nargin < 5 || isempty(base)
        base = 0;
    end
    fraction = yearfrac(reglement, echeance, base);
    escompte = (valeurFaciale - prix) ./ (valeurFaciale .* fraction);
end
