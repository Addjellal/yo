function L = resubLoss(modele, varargin)
%RESUBLOSS Erreur d'un classifieur sur ses propres données d'apprentissage.
%   L = RESUBLOSS(MDL) applique MDL aux observations qui ont servi à
%   l'ajuster et rend son erreur de classement, pondérée par les a priori
%   comme le fait LOSS. C'est une erreur apparente : optimiste, puisque
%   le modèle a vu ces données. Une validation croisée en donne une
%   estimation honnête.
%
%   L = RESUBLOSS(MDL,'LossFun',F) et RESUBLOSS(MDL,'Weights',W) passent
%   ces options à LOSS.
%
%   Le modèle doit garder ses données d'apprentissage (champs X et Y),
%   comme le font FITCDISCR, FITCNB, FITCSVM, FITCECOC et FITCKNN.
%
%   Exemple :
%      % Les iris de Fisher ; l'exemple de MathWorks donne 0.0200.
%      load fisheriris
%      Md = fitcdiscr(meas, species);
%      resubLoss(Md)      % 0.02
%
%   Voir aussi LOSS, RESUBPREDICT, PREDICT, CVPARTITION.
    if ~isstruct(modele) || ~isfield(modele, 'X') || ~isfield(modele, 'Y')
        error('stats:resubLoss:NoData', ...
              ['RESUBLOSS needs the training data, which this model does not ' ...
               'keep (fields X and Y).']);
    end
    L = loss(modele, modele.X, modele.Y, varargin{:});
end
