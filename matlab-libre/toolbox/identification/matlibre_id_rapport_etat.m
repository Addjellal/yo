function modele = matlibre_id_rapport_etat(modele, donnees, methode, echantillons, parametres)
%MATLIBRE_ID_RAPPORT_ETAT Compte rendu d'estimation d'un modèle d'état.
%   MODELE = MATLIBRE_ID_RAPPORT_ETAT(MODELE,DONNEES,METHODE,N,P) remplit
%   le champ Report comme le fait son homologue polynomial.
%
%   Exemple :
%      m = n4sid(z, 2);
%      m.Report.Fit.FitPercent
%
%   Voir aussi N4SID, SSEST, MATLIBRE_ID_RAPPORT.
    jeu = matlibre_id_experience(iddata(donnees), 1);
    prediction = matlibre_id_predire_etat(modele, jeu, Inf);
    ajustement = compareFit(jeu.OutputData, prediction.OutputData);
    erreur = mean((jeu.OutputData - prediction.OutputData) .^ 2);
    critereFpe = erreur * (1 + parametres / echantillons) / ...
                 max(1 - parametres / echantillons, eps);
    critereAic = echantillons * log(max(erreur, realmin)) + 2 * parametres;
    modele.Report = struct('Method', methode, 'OrderInfo', size(modele.A, 1), ...
                           'Fit', struct('FitPercent', ajustement, 'MSE', erreur, ...
                                         'FPE', critereFpe, 'AIC', critereAic, ...
                                         'nobs', echantillons, 'nparams', parametres));
end
