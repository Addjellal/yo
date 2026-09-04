function gain = opprofit(coursActif, prixExercice, cout, position, type)
%OPPROFIT Gain d'une option à l'échéance.
%   G = OPPROFIT(COURS,EXERCICE,COUT,POSITION,TYPE) rend le gain net.
%   POSITION vaut 0 pour un acheteur, 1 pour un vendeur ; TYPE vaut 0
%   pour un achat (call), 1 pour une vente (put).
%
%   À l'échéance, une option ne vaut plus que sa valeur intrinsèque : le
%   gain de l'exercice s'il est favorable, zéro sinon. Le gain net
%   retranche la prime payée — ou l'ajoute, pour le vendeur.
%
%   Exemple :
%      opprofit(110, 100, 5, 0, 0)     % 5 : achat d'un call gagnant
%      opprofit(90, 100, 5, 0, 0)      % -5 : la prime est perdue
%
%   Voir aussi BLSPRICE, BINPRICE, BLSDELTA.
    if nargin < 4 || isempty(position), position = 0; end
    if nargin < 5 || isempty(type),     type = 0;     end
    valeur = zeros(size(coursActif + prixExercice));
    achat = type == 0;
    valeur = achat .* max(coursActif - prixExercice, 0) + ...
             (~achat) .* max(prixExercice - coursActif, 0);
    gain = (position == 0) .* (valeur - cout) + (position ~= 0) .* (cout - valeur);
end
