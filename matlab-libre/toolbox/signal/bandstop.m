function [y, b, a] = bandstop(x, wstop, varargin)
%BANDSTOP Filtre coupe-bande appliqué à un signal.
%   Y = BANDSTOP(X,[W1 W2]) retire ce qui se trouve entre W1 et W2,
%   fréquences normalisées entre 0 et 1.
%   Y = BANDSTOP(X,[F1 F2],FS) donne les fréquences en hertz.
%
%   Les options sont celles de LOWPASS.
%
%   [Y,B,A] = BANDSTOP(...) rend aussi les coefficients du filtre.
%
%   Exemple :
%      t = (0:999)' / 1000;
%      x = sin(2*pi*10*t) + sin(2*pi*100*t);
%      y = bandstop(x, [50 200], 1000);
%
%   Voir aussi BANDPASS, LOWPASS, HIGHPASS, ELLIP, FILTFILT.
    [wstop, options] = lireOptionsBande(wstop, varargin{:});
    [b, a] = concevoirBande(wstop, 'stop', options);
    y = appliquerBande(x, b, a);
end
