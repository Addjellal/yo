function v = npv(taux, flux)
%NPV Valeur actuelle nette : le premier flux est à la date zéro.
%   V = NPV(TAUX,FLUX) rend la valeur actuelle nette : FLUX(1) compte pour
%   sa valeur nominale — il est daté de zéro — et FLUX(k) est divisé par
%   (1+TAUX)^(k-1).
%
%   C'est le critère de décision d'un investissement : positive, la valeur
%   actuelle nette dit que le projet rapporte plus que le placement au
%   taux retenu ; négative, qu'il rapporte moins. Contrairement au taux de
%   rendement interne elle existe toujours, elle est unique, et elle
%   s'additionne d'un projet à l'autre.
%
%   Tout dépend du taux choisi, qui est le coût du capital et non une
%   donnée du projet : un flux lointain est écrasé par l'actualisation, si
%   bien qu'un même projet est bon à 3 % et mauvais à 10 %. C'est là que
%   se joue la décision, plus que dans le calcul.
%
%   Exemple :
%      npv(0.1, [-100 50 60])
%
%   Voir aussi PV, IRR, FV.
    v = flux(1);
    for k = 2:numel(flux)
        v = v + flux(k) / (1 + taux) ^ (k - 1);
    end
end
