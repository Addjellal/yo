function options = anfisOptions(varargin)
%ANFISOPTIONS Options d'apprentissage d'ANFIS.
%   O = ANFISOPTIONS rend les réglages par défaut :
%     InitialFIS              système de départ, ou nombre de modalités
%                             par entrée si l'on donne un nombre
%     EpochNumber             nombre d'époques, 10
%     InitialStepSize         pas initial, 0,01
%     StepSizeDecreaseRate    facteur de réduction du pas, 0,9
%     StepSizeIncreaseRate    facteur d'augmentation, 1,1
%     ErrorGoal               erreur en deçà de laquelle on s'arrête, 0
%     DisplayANFISInformation, DisplayErrorValues, DisplayStepSize,
%     DisplayFinalResults     affichages, tous à 1 dans MATLAB
%
%   Exemple :
%      o = anfisOptions('EpochNumber', 40, 'InitialStepSize', 0.05);
%      fis = anfis([x, y], o);
%
%   Voir aussi ANFIS, GENFISOPTIONS, TUNEFISOPTIONS.
    options = struct('InitialFIS', 2, 'EpochNumber', 10, ...
                     'InitialStepSize', 0.01, ...
                     'StepSizeDecreaseRate', 0.9, ...
                     'StepSizeIncreaseRate', 1.1, ...
                     'ErrorGoal', 0, ...
                     'DisplayANFISInformation', 1, ...
                     'DisplayErrorValues', 1, ...
                     'DisplayStepSize', 1, ...
                     'DisplayFinalResults', 1, ...
                     'ValidationData', []);
    options = poserOptions(options, 'anfisOptions', varargin{:});
end
