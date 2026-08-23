function [y, t] = modulate(x, fc, fs, methode, opt)
%MODULATE Modulation d'un signal en bande de base.
%   Y = MODULATE(X,FC,FS,METHODE) où METHODE vaut 'am' (double bande à
%   porteuse supprimée, par défaut), 'amdsb-tc' (porteuse transmise),
%   'fm', 'pm' ou 'qam'.
%
%   Exemple :
%      fs = 1e4;  x = sin(2*pi*10*(0:999)'/fs);
%      y = modulate(x, 1e3, fs, 'am');
    if nargin < 3 || isempty(fs), fs = 1; end
    if nargin < 4 || isempty(methode), methode = 'am'; end
    x = double(x);
    colonne = iscolumn(x);
    x = x(:);
    t = (0:numel(x) - 1)' / fs;
    switch lower(char(methode))
        case {'am', 'amdsb-sc'}
            y = x .* cos(2 * pi * fc * t);
        case 'amdsb-tc'
            if nargin < 5 || isempty(opt), opt = -min(x); end
            y = (x + opt) .* cos(2 * pi * fc * t);
        case 'amssb'
            % Bande latérale unique par la transformée de Hilbert.
            y = x .* cos(2 * pi * fc * t) - imag(hilbert(x)) .* sin(2 * pi * fc * t);
        case 'fm'
            if nargin < 5 || isempty(opt), opt = (fc / fs) * 2 * pi; end
            y = cos(2 * pi * fc * t + opt * cumsum(x));
        case 'pm'
            if nargin < 5 || isempty(opt), opt = (fc / fs) * 2 * pi; end
            y = cos(2 * pi * fc * t + opt * x);
        case 'qam'
            if nargin < 5 || isempty(opt)
                error('signal:modulate:MissingQuadrature', ...
                      'La modulation en quadrature demande un second signal.');
            end
            q = double(opt(:));
            y = x .* cos(2 * pi * fc * t) + q .* sin(2 * pi * fc * t);
        otherwise
            error('signal:modulate:UnknownMethod', 'Méthode inconnue : %s.', char(methode));
    end
    if ~colonne, y = y.'; t = t.'; end
end
