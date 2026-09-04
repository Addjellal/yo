function valeur = fvdisc(reglement, echeance, prix, escompte, base)
%FVDISC Valeur future d'un titre vendu à escompte.
%   V = FVDISC(REGLEMENT,ECHEANCE,PRIX,ESCOMPTE) rend la valeur de
%   remboursement d'un titre acheté à PRIX au taux d'escompte donné.
%
%   Exemple :
%      fvdisc('01-Feb-2024', '01-Aug-2024', 97.5, 0.05, 2)
%
%   Voir aussi PRDISC, DISCRATE, YLDDISC.
    if nargin < 5 || isempty(base)
        base = 0;
    end
    fraction = yearfrac(reglement, echeance, base);
    valeur = prix ./ (1 - escompte .* fraction);
end
