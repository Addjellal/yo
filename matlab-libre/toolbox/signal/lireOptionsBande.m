function [w, options] = lireOptionsBande(w, varargin)
%LIREOPTIONSBANDE Arguments communs à lowpass, highpass, bandpass, bandstop.
%   Rend les fréquences normalisées et une structure d'options :
%   Steepness, StopbandAttenuation et ImpulseResponse.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    options = struct('Steepness', 0.85, 'StopbandAttenuation', 60, ...
                     'ImpulseResponse', 'iir');
    w = double(w(:)).';
    k = 1;
    if ~isempty(varargin) && isnumeric(varargin{1}) && isscalar(varargin{1})
        fs = double(varargin{1});
        w = 2 * w / fs;
        k = 2;
    end
    while k <= numel(varargin)
        if k + 1 > numel(varargin)
            error('signal:bande:Paire', 'Option sans valeur : %s.', char(varargin{k}));
        end
        switch lower(char(varargin{k}))
            case 'steepness'
                options.Steepness = double(varargin{k+1});
            case 'stopbandattenuation'
                options.StopbandAttenuation = double(varargin{k+1});
            case 'impulseresponse'
                options.ImpulseResponse = lower(char(varargin{k+1}));
            otherwise
                error('signal:bande:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if any(w <= 0) || any(w >= 1)
        error('signal:bande:Frequence', ...
              'Les fréquences doivent être strictement entre 0 et la moitié de Fs.');
    end
    if any(options.Steepness < 0.5) || any(options.Steepness >= 1)
        error('signal:bande:Raideur', 'La raideur doit être dans [0,5 ; 1[.');
    end
end
