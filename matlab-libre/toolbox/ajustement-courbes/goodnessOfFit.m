function stats = goodnessOfFit(y, yhat)
%GOODNESSOFFIT Indicateurs de qualité d'un ajustement.
%   STATS = GOODNESSOFFIT(Y,YHAT) rend une structure : la somme des carrés
%   des résidus, l'erreur quadratique moyenne, le coefficient de
%   détermination et sa version ajustée.
%
%   Le R2 dit quelle part de la variance est expliquée, mais il ne peut
%   que croître quand on ajoute des paramètres — même inutiles. C'est
%   pourquoi le R2 ajusté existe : il pénalise le nombre de paramètres, et
%   peut donc décroître quand on en ajoute un qui n'apporte rien.
%
%   Un R2 élevé ne dit pas que le modèle est juste : il peut être élevé
%   sur un modèle faux et bas sur un modèle correct mais bruité. Regarder
%   les résidus vaut mieux que regarder le R2.
%
%   Exemple :
%      stats = goodnessOfFit(y, modele(x));
%      stats.rsquare
%      stats.rmse
%
%   Voir aussi FIT, FITSURFACE, CONFINT.
    y = y(:);
    yhat = yhat(:);
    residus = y - yhat;
    sse = sum(residus .^ 2);
    sst = sum((y - mean(y)) .^ 2);
    stats = struct();
    stats.SSE = sse;
    stats.RMSE = sqrt(sse / numel(y));
    if sst == 0
        stats.R2 = 1;
    else
        stats.R2 = 1 - sse / sst;
    end
end
