function [y, b, a] = bandpass(x, wpass, varargin)
%BANDPASS Filtre passe-bande appliqué à un signal.
%   Y = BANDPASS(X,[W1 W2]) ne laisse passer que ce qui se trouve entre
%   W1 et W2, fréquences normalisées entre 0 et 1.
%   Y = BANDPASS(X,[F1 F2],FS) donne les fréquences en hertz.
%
%   Les options sont celles de LOWPASS.
%
%   [Y,B,A] = BANDPASS(...) rend aussi les coefficients du filtre.
%
%   Exemple :
%      t = (0:999)' / 1000;
%      x = sin(2*pi*10*t) + sin(2*pi*100*t) + sin(2*pi*400*t);
%      y = bandpass(x, [50 200], 1000);
%
%   Voir aussi BANDSTOP, LOWPASS, HIGHPASS, ELLIP, FILTFILT.
    [wpass, options] = lireOptionsBande(wpass, varargin{:});
    [b, a] = concevoirBande(wpass, 'bandpass', options);
    y = appliquerBande(x, b, a);
end
