function r = irr(flux)
%IRR Taux de rendement interne : le taux qui annule la valeur nette.
%   R = IRR(FLUX) rend le taux qui annule la valeur actuelle nette de la
%   suite de flux, le premier étant daté de zéro et donc non actualisé.
%   Le zéro est cherché entre -99,99 % et 1000 %.
%
%   Le taux de rendement interne est le taux d'actualisation auquel le
%   projet est tout juste équilibré ; on le compare au coût du capital,
%   et on retient le projet si le premier dépasse le second. Son intérêt
%   est de ne dépendre d'aucun taux extérieur, sa faiblesse d'en supposer
%   un implicitement : il fait comme si les flux intermédiaires étaient
%   replacés à ce même taux, ce qui est rarement le cas.
%
%   Il n'existe et n'est unique que si la suite change de signe une seule
%   fois — la règle de Descartes. Un projet qui exige une remise en état
%   finale change deux fois de signe et peut avoir deux taux également
%   valables, ou aucun : la valeur actuelle nette, elle, tranche toujours.
%
%   Exemple :
%      irr([-100 30 40 50])
%
%   Voir aussi NPV, PV, FV.
    f = @(t) npv(t, flux);
    r = fzero(f, [-0.9999, 10]);
end
