function prix = prtbill(reglement, echeance, escompte, valeurFaciale)
%PRTBILL Prix d'un bon du Trésor.
%   P = PRTBILL(REGLEMENT,ECHEANCE,ESCOMPTE,FACE) applique la convention
%   des bons du Trésor américains : le taux d'escompte se rapporte à la
%   valeur de remboursement et l'année compte trois cent soixante jours.
%
%   Exemple :
%      prtbill('01-Feb-2024', '01-Aug-2024', 0.05, 100)
%
%   Voir aussi YLDTBILL, BEYTBILL, PRDISC, TBILLVAL01.
    if nargin < 4 || isempty(valeurFaciale)
        valeurFaciale = 100;
    end
    jours = daysact(reglement, echeance);
    prix = valeurFaciale .* (1 - escompte .* jours / 360);
end
