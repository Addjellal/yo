function rendement = yldtbill(reglement, echeance, valeurFaciale, prix)
%YLDTBILL Rendement d'un bon du Trésor.
%   R = YLDTBILL(REGLEMENT,ECHEANCE,FACE,PRIX) rend le gain rapporté au
%   prix payé, sur une année de trois cent soixante jours : c'est le
%   rendement du marché monétaire.
%
%   Exemple :
%      yldtbill('01-Feb-2024', '01-Aug-2024', 100, 97.5)
%
%   Voir aussi PRTBILL, BEYTBILL, YLDDISC.
    jours = daysact(reglement, echeance);
    rendement = (valeurFaciale - prix) ./ prix .* 360 ./ jours;
end
