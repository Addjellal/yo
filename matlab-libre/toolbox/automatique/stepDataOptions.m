function options = stepDataOptions(varargin)
%STEPDATAOPTIONS Options d'une réponse indicielle.
%   O = STEPDATAOPTIONS rend une structure d'options que STEP accepte :
%   elle sert surtout à donner les niveaux de l'échelon.
%
%   O = STEPDATAOPTIONS('InputOffset',U0,'StepAmplitude',A) part du
%   niveau U0 et monte de A : la réponse rendue est alors celle du saut
%   de U0 à U0+A, et non celle du saut unité.
%
%   Exemple :
%      o = stepDataOptions('StepAmplitude', 5);
%      y = step(tf(1, [1 1]), 0:0.1:5, o);
%
%   Voir aussi STEP, STEPINFO, BODEOPTIONS, GENSIG.
    options = struct('InputOffset', 0, 'StepAmplitude', 1);
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'inputoffset',   options.InputOffset = double(varargin{k+1});
            case 'stepamplitude', options.StepAmplitude = double(varargin{k+1});
            otherwise
                error('control:stepDataOptions:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
end
