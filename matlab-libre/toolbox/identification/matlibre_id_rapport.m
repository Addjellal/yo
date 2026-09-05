function modele = matlibre_id_rapport(modele, donnees, methode, echantillons, parametres)
%MATLIBRE_ID_RAPPORT Renseigne le compte rendu d'une estimation.
%   MODELE = MATLIBRE_ID_RAPPORT(MODELE,DONNEES,METHODE,N,P) remplit le
%   champ Report : la méthode employée, l'ajustement en pour cent, l'erreur
%   quadratique, le critère d'erreur finale de prédiction et le critère
%   d'Akaike.
%
%   Ces deux critères pénalisent le nombre de paramètres : sans eux, un
%   modèle plus riche paraîtrait toujours meilleur, puisqu'il peut
%   toujours coller de plus près aux données dont il est tiré.
%
%   Exemple :
%      m = arx(z, [2 2 1]);
%      m.Report.Fit.FPE
%
%   Voir aussi ARX, POLYEST, FPE, AIC.
    jeu = matlibre_id_experience(iddata(donnees), 1);
    prediction = matlibre_id_predire(modele, jeu, 1);
    ajustement = compareFit(jeu.OutputData, prediction.OutputData);
    erreur = mean((jeu.OutputData - prediction.OutputData) .^ 2);
    critereFpe = erreur * (1 + parametres / echantillons) / ...
                 max(1 - parametres / echantillons, eps);
    critereAic = echantillons * log(max(erreur, realmin)) + 2 * parametres;
    modele.Report = struct('Method', methode, 'OrderInfo', modele.Ordres, ...
                           'Fit', struct('FitPercent', ajustement, 'MSE', erreur, ...
                                         'FPE', critereFpe, 'AIC', critereAic, ...
                                         'nobs', echantillons, 'nparams', parametres));
end
