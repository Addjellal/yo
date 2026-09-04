function rendement = beytbill(reglement, echeance, escompte)
%BEYTBILL Rendement d'un bon du Trésor, équivalent obligataire.
%   R = BEYTBILL(REGLEMENT,ECHEANCE,ESCOMPTE) convertit un taux
%   d'escompte de bon du Trésor en rendement comparable à celui d'une
%   obligation : la base passe de trois cent soixante jours à trois cent
%   soixante-cinq, et le taux se rapporte au prix payé, non à la valeur
%   de remboursement.
%
%   Sans cette conversion, un bon et une obligation de même rendement
%   réel afficheraient des taux différents.
%
%   Exemple :
%      beytbill('01-Feb-2024', '01-Aug-2024', 0.05)
%
%   Voir aussi PRTBILL, YLDTBILL, YLDDISC.
    jours = daysact(reglement, echeance);
    rendement = 365 .* escompte ./ (360 - escompte .* jours);
end
