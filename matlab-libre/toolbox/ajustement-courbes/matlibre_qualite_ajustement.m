function qualite = matlibre_qualite_ajustement(y, residus, poids, nombreParametres)
%MATLIBRE_QUALITE_AJUSTEMENT Mesures de la qualité d'un ajustement.
%   Q = MATLIBRE_QUALITE_AJUSTEMENT(Y,RESIDUS,POIDS,NOMBREPARAMETRES) rend
%   la somme des carrés des écarts, le R carré, le R carré ajusté, l'écart
%   quadratique moyen et les degrés de liberté.
%
%   Le R carré ajusté pénalise le nombre de paramètres : sans lui, ajouter
%   un terme améliore toujours l'ajustement, et l'on choisirait toujours le
%   modèle le plus riche.
%
%   Exemple :
%      matlibre_qualite_ajustement([1;2;3], [0;0;0], [1;1;1], 2).rsquare   % 1
%
%   Voir aussi FIT, GOODNESSOFFIT.
    y = y(:);
    residus = residus(:);
    poids = poids(:);
    sse = sum(poids .* residus .^ 2);
    moyenne = sum(poids .* y) / sum(poids);
    sst = sum(poids .* (y - moyenne) .^ 2);
    n = numel(y);
    ddl = n - nombreParametres;
    if sst > 0
        rcarre = 1 - sse / sst;
    else
        rcarre = 1;
    end
    if ddl > 0 && n > 1
        ajuste = 1 - (1 - rcarre) * (n - 1) / ddl;
        rmse = sqrt(sse / ddl);
    else
        ajuste = rcarre;
        rmse = 0;
    end
    qualite = struct('sse', sse, 'rsquare', rcarre, 'dfe', ddl, ...
                     'adjrsquare', ajuste, 'rmse', rmse);
end
