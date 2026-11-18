function [etiquettes, scores] = resubPredict(modele)
%RESUBPREDICT Prédictions d'un modèle sur ses propres données d'apprentissage.
%   LABEL = RESUBPREDICT(MDL) applique MDL aux observations qui ont servi
%   à l'ajuster.
%   [LABEL,SCORE] = RESUBPREDICT(MDL) rend aussi les scores, comme
%   PREDICT : pour une analyse discriminante, les probabilités a
%   posteriori de chaque classe.
%
%   Exemple :
%      load fisheriris
%      Md = fitcdiscr(meas, species);
%      etiquettes = resubPredict(Md);
%      confusionmat(species, etiquettes)
%
%   Voir aussi RESUBLOSS, PREDICT, LOSS.
    if ~isstruct(modele) || ~isfield(modele, 'X')
        error('stats:resubPredict:NoData', ...
              ['RESUBPREDICT a besoin des données d''apprentissage, que ce modèle ' ...
               'ne garde pas (champ X).']);
    end
    if nargout > 1
        [etiquettes, scores] = predict(modele, modele.X);
    else
        etiquettes = predict(modele, modele.X);
    end
end
