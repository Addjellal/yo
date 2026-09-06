function v = pv(taux, flux)
%PV Valeur actuelle d'une suite de flux, le premier à la période 1.
%   V = PV(TAUX,FLUX) rend la valeur actuelle d'une suite de flux dont le
%   premier tombe à la fin de la période 1 : chaque FLUX(k) est divisé par
%   (1+TAUX)^k.
%
%   La différence avec NPV tient à cette seule convention de date, et elle
%   change le résultat d'un facteur (1+TAUX) : NPV sert quand un
%   décaissement a lieu aujourd'hui, PV quand tous les flux sont à venir —
%   le prix d'une rente, celui d'une obligation.
%
%   Une suite infinie de flux constants converge vers FLUX/TAUX : c'est
%   la rente perpétuelle, et la raison pour laquelle un actif de rendement
%   fixe vaut d'autant moins que les taux montent.
%
%   Exemple :
%      pv(0.05, [100 100 100])
%
%   Voir aussi NPV, FV, IRR.
    v = 0;
    for k = 1:numel(flux)
        v = v + flux(k) / (1 + taux) ^ k;
    end
end
