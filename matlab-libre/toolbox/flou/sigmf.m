function y = sigmf(x, p)
%SIGMF Fonction d'appartenance sigmoïde de paramètres [pente centre].
%   Y = SIGMF(X,[PENTE CENTRE]) rend 1/(1+exp(-PENTE*(X-CENTRE))) : une
%   courbe en S allant de zéro à un, valant un demi au centre.
%
%   Contrairement à la gaussienne et à la cloche, elle est monotone : elle
%   ne décrit pas « autour de », mais « au-delà de ». C'est la forme qui
%   convient aux ensembles ouverts d'un côté — « grand », « chaud » — dont
%   l'appartenance ne redescend pas quand on s'éloigne encore.
%
%   Une pente négative retourne la courbe et décrit « en deçà de ». Plus
%   la pente est grande en valeur absolue, plus la transition est courte ;
%   à la limite on retrouve le seuil net, et avec lui la discontinuité de
%   commande que la logique floue est faite d'éviter.
%
%   Exemple :
%      sigmf([20 30 40], [0.5 30])
%
%   Voir aussi GAUSSMF, GBELLMF, TRIMF, TRAPMF.
    y = 1 ./ (1 + exp(-p(1) * (x - p(2))));
end
