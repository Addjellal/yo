function [x, q] = demod(y, fc, fs, methode, opt)
%DEMOD Démodulation, réciproque de MODULATE.
%   X = DEMOD(Y,FC,FS,METHODE). La démodulation d'amplitude multiplie par
%   la porteuse puis filtre passe-bas ; celle de phase et de fréquence
%   passe par la transformée de Hilbert.
    if nargin < 3 || isempty(fs), fs = 1; end
    if nargin < 4 || isempty(methode), methode = 'am'; end
    y = double(y);
    colonne = iscolumn(y);
    y = y(:);
    t = (0:numel(y) - 1)' / fs;
    q = [];
    switch lower(char(methode))
        case {'am', 'amdsb-sc', 'amdsb-tc', 'amssb'}
            x = 2 * y .* cos(2 * pi * fc * t);
            % Passe-bas de Butterworth d'ordre 5, coupure à fc/2.
            coupure = min(0.9, fc / (fs / 2));
            [b, a] = butter(5, coupure);
            x = filtfilt(b, a, x);
        case 'pm'
            if nargin < 5 || isempty(opt), opt = (fc / fs) * 2 * pi; end
            x = unwrap(angle(hilbert(y))) - 2 * pi * fc * t;
            x = x / opt;
        case 'fm'
            if nargin < 5 || isempty(opt), opt = (fc / fs) * 2 * pi; end
            phase = unwrap(angle(hilbert(y))) - 2 * pi * fc * t;
            x = [0; diff(phase)] / opt;
        case 'qam'
            x = 2 * y .* cos(2 * pi * fc * t);
            q = 2 * y .* sin(2 * pi * fc * t);
            coupure = min(0.9, fc / (fs / 2));
            [b, a] = butter(5, coupure);
            x = filtfilt(b, a, x);
            q = filtfilt(b, a, q);
        otherwise
            error('signal:demod:UnknownMethod', 'Méthode inconnue : %s.', char(methode));
    end
    if ~colonne
        x = x.';
        if ~isempty(q), q = q.'; end
    end
end
