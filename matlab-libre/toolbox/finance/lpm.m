function moment = lpm(donnees, seuil, ordre)
%LPM Moment partiel inférieur d'une série de rendements.
%   M = LPM(DONNEES,SEUIL,ORDRE) rend la moyenne des écarts au seuil,
%   élevés à la puissance ORDRE, en ne comptant que les observations
%   situées sous le seuil.
%
%   L'écart type punit également les hausses et les baisses ; le moment
%   partiel inférieur ne regarde que ce qui déçoit. L'ordre 0 donne la
%   fréquence des pertes, l'ordre 1 leur ampleur moyenne, l'ordre 2 une
%   semi-variance.
%
%   Exemple :
%      lpm(rendements, 0, 2)      % semi-variance sous zero
%
%   Voir aussi ELPM, MAXDRAWDOWN, SHARPE, INFORATIO.
    if nargin < 2 || isempty(seuil), seuil = 0; end
    if nargin < 3 || isempty(ordre), ordre = 0; end
    donnees = double(donnees);
    if size(donnees, 1) == 1, donnees = donnees.'; end
    manques = max(seuil - donnees, 0);
    if ordre == 0
        moment = mean(donnees < seuil, 1);
    else
        moment = mean(manques .^ ordre, 1);
    end
end
