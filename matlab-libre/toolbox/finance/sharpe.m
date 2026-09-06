function s = sharpe(rendements, sansRisque)
%SHARPE Ratio de Sharpe d'une série de rendements.
%   S = SHARPE(RENDEMENTS) rend la moyenne des rendements divisée par leur
%   écart type. S = SHARPE(RENDEMENTS,SANSRISQUE) retranche d'abord le
%   taux sans risque, et mesure donc l'excès de rendement par unité de
%   risque.
%
%   C'est le rendement payé pour un point de volatilité : il permet de
%   comparer deux stratégies d'échelles différentes, puisque multiplier
%   par deux la mise multiplie par deux la moyenne et l'écart type, et
%   laisse le ratio inchangé.
%
%   Le ratio rendu est celui de la période des données. Pour l'annualiser,
%   multiplier par la racine du nombre de périodes par an — sqrt(252) sur
%   des rendements quotidiens — parce que la moyenne croît comme le temps
%   et l'écart type comme sa racine.
%
%   L'écart type traite une hausse brusque comme une baisse brusque, ce
%   qui pénalise une stratégie qui ne surprend qu'à la hausse ; et il ne
%   voit rien d'un risque rare et catastrophique. Un écart type nul rend
%   zéro plutôt que l'infini.
%
%   Exemple :
%      sharpe([0.01 0.02 -0.005 0.015], 0.001)
%
%   Voir aussi PORTSTATS, MAXDRAWDOWN, TICK2RET.
    if nargin < 2
        sansRisque = 0;
    end
    exces = rendements(:) - sansRisque;
    e = std(exces);
    if e == 0
        s = 0;
    else
        s = mean(exces) / e;
    end
end
