function f = forwardrate(taux1, t1, taux2, t2)
%FORWARDRATE Taux à terme implicite entre deux échéances.
%   F = FORWARDRATE(TAUX1,T1,TAUX2,T2) rend le taux à terme implicite
%   entre les échéances T1 et T2, déduit des deux taux zéro-coupon :
%   ((1+TAUX2)^T2/(1+TAUX1)^T1)^(1/(T2-T1)) - 1.
%
%   Ce taux n'est pas une prévision, c'est une contrainte d'arbitrage.
%   Placer à T2 directement, ou placer à T1 puis replacer au taux à terme,
%   doit rapporter la même chose ; sinon il existerait un gain sans risque
%   à emprunter d'un côté pour prêter de l'autre. C'est l'égalité des deux
%   chemins qui détermine F, quelles que soient les anticipations.
%
%   Une courbe de taux croissante donne des taux à terme supérieurs aux
%   taux comptants, et une courbe inversée des taux à terme inférieurs —
%   ce qui se lit souvent comme une anticipation de baisse, à la prime de
%   terme près.
%
%   Exemple :
%      forwardrate(0.02, 1, 0.03, 2)
%
%   Voir aussi DISCOUNTFACTOR, BONDYIELD, PV.
    f = ((1 + taux2) ^ t2 / (1 + taux1) ^ t1) ^ (1 / (t2 - t1)) - 1;
end
