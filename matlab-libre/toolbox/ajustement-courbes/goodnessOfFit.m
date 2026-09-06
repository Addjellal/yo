function stats = goodnessOfFit(y, yhat, nParametres)
%GOODNESSOFFIT Indicateurs de qualité d'un ajustement.
%   STATS = GOODNESSOFFIT(Y,YHAT) rend une structure portant la somme des
%   carrés des résidus, l'erreur quadratique moyenne et le coefficient de
%   détermination. Chaque grandeur y figure sous deux noms : celui de la
%   structure GOF de MATLAB — sse, rmse, rsquare — et sa forme en
%   majuscules, SSE, RMSE, R2. Les deux désignent la même valeur ; les
%   premiers permettent de reprendre un programme écrit pour MATLAB sans
%   le retoucher.
%
%   STATS = GOODNESSOFFIT(Y,YHAT,NPARAMETRES) ajoute les degrés de liberté
%   résiduels dfe = N - NPARAMETRES et le coefficient ajusté adjrsquare.
%   Il faut donner ce nombre : les résidus seuls ne disent pas combien de
%   paramètres ont été ajustés pour les obtenir.
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
%      rng(1);
%      x = linspace(0, 1, 40)';
%      y = 2 * x + 1 + 0.05 * randn(40, 1);
%      stats = goodnessOfFit(y, polyval(polyfit(x, y, 1), x));
%      stats.rsquare
%      stats.rmse
%      goodnessOfFit(y, polyval(polyfit(x, y, 1), x), 2).adjrsquare
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
    % Les noms de la structure GOF de MATLAB, pour la meme valeur.
    stats.sse = stats.SSE;
    stats.rmse = stats.RMSE;
    stats.rsquare = stats.R2;
    if nargin >= 3 && ~isempty(nParametres)
        stats.dfe = numel(y) - nParametres;
        if stats.dfe > 0 && sst > 0
            stats.adjrsquare = 1 - (1 - stats.R2) * (numel(y) - 1) / stats.dfe;
        else
            stats.adjrsquare = NaN;
        end
    end
end
