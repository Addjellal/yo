function [pValeur, valeurCritique] = matlibre_dickey_table(statistique, modele, alpha, forme)
%MATLIBRE_DICKEY_TABLE Quantiles de la loi de Dickey-Fuller.
%   La statistique ne suit pas une loi de Student : sous racine
%   unitaire, sa loi limite est celle d'une fonctionnelle du mouvement
%   brownien, décalée vers la gauche. Les quantiles rangés ici ont été
%   obtenus en simulant huit mille marches aléatoires de quatre cents
%   pas et en passant chacune par la même régression que le test ; ils
%   s'accordent aux quantiles publiés par Dickey et Fuller à quelques
%   centièmes près.
%
%   FORME vaut 't1', le rapport de Student, ou 't2', le coefficient
%   normalisé. Le test est unilatéral à gauche.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 4 || isempty(forme)
        forme = 't1';
    end
    niveaux = [0.01 0.025 0.05 0.10 0.20 0.50 0.90 0.99];
    switch lower(forme)
        case 't1'
            quantiles = [ ...
                   -2.540    -2.210    -1.929    -1.615    -1.244    -0.504     0.890     1.990; ...
                   -3.442    -3.130    -2.882    -2.572    -2.220    -1.568    -0.467     0.579; ...
                   -4.045    -3.697    -3.434    -3.135    -2.812    -2.185    -1.232    -0.359 ...
                ];
        case 't2'
            quantiles = [ ...
                  -14.061   -10.429    -8.128    -5.737    -3.442    -0.847     0.932     1.991; ...
                  -19.703   -16.194   -13.487   -11.025    -8.271    -4.352    -0.854     1.042; ...
                  -28.585   -24.396   -21.353   -18.003   -14.386    -9.052    -3.723    -0.871 ...
                ];
        otherwise
            error('econ:dickeyTable:Forme', ...
                  'La forme du test vaut ''t1'' ou ''t2'', pas ''%s''.', forme);
    end
    switch lower(modele)
        case 'ar',  ligne = quantiles(1, :);
        case 'ard', ligne = quantiles(2, :);
        case 'ts',  ligne = quantiles(3, :);
        otherwise,  ligne = quantiles(2, :);
    end
    [pValeur, valeurCritique] = matlibre_quantiles_gauche(statistique, niveaux, ligne, alpha);
end
