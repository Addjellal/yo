function [symboles, nomsEtats] = lireNomsHmm(varargin)
%LIRENOMSHMM Options « Symbols » et « Statenames » des fonctions HMM.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    symboles = [];
    nomsEtats = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'symbols'
                symboles = varargin{k+1};
            case 'statenames'
                nomsEtats = varargin{k+1};
            case {'maxiterations', 'tolerance', 'algorithm', 'verbose', 'pseudoemissions', ...
                  'pseudotransitions'}
                % Traitées ailleurs.
            otherwise
                error('stats:hmm:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
end
