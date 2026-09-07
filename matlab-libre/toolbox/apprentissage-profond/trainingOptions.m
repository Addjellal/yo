function options = trainingOptions(solveur, varargin)
%TRAININGOPTIONS Réglages de l'apprentissage.
%   OPT = TRAININGOPTIONS('sgdm','MaxEpochs',N,'InitialLearnRate',R, ...
%                         'MiniBatchSize',B,'Momentum',M,'Verbose',V)
%
%   Exemple :
%      o = trainingOptions('sgdm', 'MaxEpochs', 50, 'InitialLearnRate', 0.02);
%      o.MaxEpochs                 % 50
%
%   Voir aussi TRAINNETWORK, ADAMUPDATE, SGDMUPDATE.
    options = struct('solveur', lower(char(solveur)), 'MaxEpochs', 100, ...
                     'InitialLearnRate', 0.01, 'MiniBatchSize', 16, ...
                     'Momentum', 0.9, 'Verbose', 0, 'Loss', 'auto');
    for k = 1:2:numel(varargin)-1
        nom = char(varargin{k});
        options.(nom) = varargin{k+1};
    end
end
