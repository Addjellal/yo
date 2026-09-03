function modele = discardSupportVectors(modele)
%DISCARDSUPPORTVECTORS Allège une SVM linéaire de ses points.
%   M = DISCARDSUPPORTVECTORS(M) retire d'un modèle à noyau linéaire les
%   vecteurs de support et leurs multiplicateurs : la frontière ne tient
%   qu'au vecteur de poids et au biais, que le modèle garde. C'est ce qui
%   permet d'embarquer un classifieur sans emporter les données
%   d'apprentissage.
%
%   Un modèle à noyau non linéaire refuse : ses points sont sa frontière.
%
%   Exemple :
%      m = fitcsvm(X, y);
%      m = discardSupportVectors(m);
%      isempty(m.SupportVectors)     % vrai
%
%   Voir aussi FITCSVM, PREDICT.
    if ~isstruct(modele) || ~isfield(modele, 'type') || ~strcmp(modele.type, 'svm')
        error('stats:discardSupportVectors:Modele', ...
              'Le modèle doit venir de FITCSVM ou de FITRSVM.');
    end
    if ~strcmp(modele.Options.KernelFunction, 'linear')
        error('stats:discardSupportVectors:Noyau', ...
              'Seul un modèle à noyau linéaire peut se passer de ses points.');
    end
    modele.SupportVectors = zeros(0, numel(modele.Beta));
    modele.Alpha = zeros(0, 1);
    modele.Cible = zeros(0, 1);
end
