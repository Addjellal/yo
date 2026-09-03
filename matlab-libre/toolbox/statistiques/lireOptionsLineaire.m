function options = lireOptionsLineaire(n, varargin)
%LIREOPTIONSLINEAIRE Options de FITCLINEAR et FITRLINEAR.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    options = struct('Learner', 'svm', 'Regularization', 'ridge', ...
                     'Lambda', 1 / max(n, 1), 'PassLimit', 200, ...
                     'FitBias', true, 'Epsilon', 0.1, 'Pas', 0.1);
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'learner',        options.Learner = lower(char(varargin{k+1}));
            case 'regularization', options.Regularization = lower(char(varargin{k+1}));
            case 'lambda',         options.Lambda = double(varargin{k+1});
            case 'passlimit',      options.PassLimit = round(varargin{k+1});
            case 'fitbias',        options.FitBias = logical(varargin{k+1});
            case 'epsilon',        options.Epsilon = double(varargin{k+1});
            case {'solver', 'verbose', 'betatolerance', 'gradienttolerance'}
                % Acceptées et sans effet.
            otherwise
                error('stats:fitclinear:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
end
