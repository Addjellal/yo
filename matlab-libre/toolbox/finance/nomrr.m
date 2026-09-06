function r = nomrr(effectif, periodes)
%NOMRR Taux nominal à partir du taux effectif.
%   R = NOMRR(EFFECTIF,PERIODES) rend le taux nominal annuel qui, composé
%   PERIODES fois par an, produit le taux effectif annuel EFFECTIF :
%   PERIODES*((1+EFFECTIF)^(1/PERIODES) - 1).
%
%   C'est l'inverse exact de EFFRR : NOMRR(EFFRR(X,P),P) rend X. Le sens
%   pratique est celui de la mensualité — connaissant le coût annuel réel
%   d'un crédit, retrouver le taux périodique à appliquer à chaque
%   échéance.
%
%   Le nominal est toujours inférieur à l'effectif dès que PERIODES
%   dépasse un, l'écart mesurant ce qu'apporte la capitalisation des
%   intérêts en cours d'année.
%
%   Exemple :
%      nomrr(0.1268, 12)
%
%   Voir aussi EFFRR, FV, PV.
    r = periodes * ((1 + effectif) ^ (1 / periodes) - 1);
end
