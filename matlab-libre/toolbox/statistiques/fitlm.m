function mdl = fitlm(varargin)
%FITLM Régression linéaire.
%   MDL = FITLM(X,Y) ajuste Y = b0 + b1*x1 + ... + bp*xp par moindres
%   carrés et rend un objet LINEARMODEL : MDL.Coefficients est une table
%   (Estimate, SE, tStat, pValue), MDL.Rsquared.Ordinary le R², MDL.RMSE
%   l'écart type résiduel, et PREDICT, COEFCI, COEFTEST, ANOVA s'y
%   appliquent.
%
%   MDL = FITLM(TBL) prend la dernière variable de la table pour réponse
%   et les autres pour prédicteurs ; FITLM(TBL,FORMULE) suit une formule
%   de Wilkinson :
%      'y ~ x1 + x2'       termes additifs (la constante est implicite)
%      'y ~ x1*x2'         x1 + x2 + x1:x2
%      'y ~ x1:x2'         l'interaction seule
%      'y ~ x1^2'          x1 + x1^2
%      'y ~ x1 + x2 - 1'   sans constante
%   MDL = FITLM(X,Y,MODELE) : 'constant', 'linear' (défaut),
%   'interactions', 'purequadratic', 'quadratic', 'polyIJK' (degré I pour
%   x1, J pour x2...), ou une matrice de termes (une ligne par terme, une
%   colonne par variable, la puissance de chacune).
%
%   Options, par paires nom-valeur :
%      'Intercept'        faux : pas de constante
%      'Weights'          poids des observations (moindres carrés pondérés)
%      'Exclude'          observations écartées (indices ou logiques)
%      'VarNames'         noms des colonnes de X puis de Y
%      'PredictorVars', 'ResponseVar'   variables d'une table à employer
%      'CategoricalVars'  variables numériques à traiter en catégories
%   Les variables catégorielles, logiques ou de texte entrent par des
%   indicatrices, la première catégorie servant de référence : un
%   coefficient 'Sexe_M' mesure l'écart de M à la référence.
%
%   Les termes liés entre eux (matrice de conception de rang déficient)
%   sont détectés par une factorisation QR pivotée : leurs coefficients
%   valent zéro, sans écart type, et NumEstimatedCoefficients le dit.
%
%   Exemple :
%      % Le ciment de Hald (Draper et Smith) : chaleur dégagée selon
%      % quatre composants.
%      X = [7 26 6 60; 1 29 15 52; 11 56 8 20; 11 31 8 47; 7 52 6 33;
%           11 55 9 22; 3 71 17 6; 1 31 22 44; 2 54 18 22; 21 47 4 26;
%           1 40 23 34; 11 66 9 12; 10 68 8 12];
%      y = [78.5 74.3 104.3 87.6 95.9 109.2 102.7 72.5 93.1 115.9 ...
%           83.8 113.3 109.4]';
%      mdl = fitlm(X, y);
%      mdl.Coefficients.Estimate'   % 62.4054 1.5511 0.5102 0.1019 -0.1441
%      mdl.Rsquared.Ordinary        % 0.9824
%      mdl.RMSE                     % 2.4460
%
%   Voir aussi LINEARMODEL, REGRESS, FITGLM, STEPWISEFIT, ROBUSTFIT.
    mdl = LinearModel.fit(varargin{:});
end
