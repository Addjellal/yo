function r = effrr(nominal, periodes)
%EFFRR Taux effectif annuel à partir du taux nominal.
%   R = EFFRR(NOMINAL,PERIODES) rend le taux effectif annuel correspondant
%   au taux nominal annuel NOMINAL composé PERIODES fois par an :
%   (1+NOMINAL/PERIODES)^PERIODES - 1.
%
%   Le taux nominal ne se compare pas d'un contrat à l'autre parce qu'il
%   ne dit rien de la fréquence de capitalisation : 12 % capitalisés
%   mensuellement rendent 12,68 % l'an, trimestriellement 12,55 %. Le taux
%   effectif ramène tout à une année et rend la comparaison possible ;
%   c'est à ce titre qu'il est réglementairement affiché.
%
%   Quand PERIODES tend vers l'infini, l'effectif tend vers exp(NOMINAL)-1,
%   la capitalisation continue — borne que le composé discret n'atteint
%   jamais.
%
%   Exemple :
%      effrr(0.12, 12)
%
%   Voir aussi NOMRR, FV, PV.
    r = (1 + nominal / periodes) ^ periodes - 1;
end
