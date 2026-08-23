function y = vco(x, fc, fs)
%VCO Oscillateur commandé en tension.
%   Y = VCO(X,FC,FS) rend un cosinus dont la fréquence instantanée suit
%   X : X = -1 donne 0 hertz, X = 0 donne FC, X = +1 donne 2*FC.
%
%   Y = VCO(X,[FMIN FMAX],FS) fixe les fréquences des extrêmes -1 et +1.
%
%   Exemple :
%      fs = 1e4;  t = (0:fs-1)'/fs;  y = vco(sin(2*pi*t), 1e3, fs);
    if nargin < 2 || isempty(fc), fc = 1000; end
    if nargin < 3 || isempty(fs), fs = 10000; end
    x = double(x);
    colonne = iscolumn(x);
    x = x(:);
    if numel(fc) == 2
        centre = (fc(1) + fc(2)) / 2;
        ecart = (fc(2) - fc(1)) / 2;
    else
        centre = fc;
        ecart = fc;
    end
    if max(abs(x)) > 1
        error('signal:vco:OutOfRange', 'X doit rester entre -1 et 1.');
    end
    % La phase est l'intégrale de la fréquence instantanée.
    phase = 2 * pi * cumsum(centre + ecart * x) / fs;
    y = cos(phase);
    if ~colonne, y = y.'; end
end
