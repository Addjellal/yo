function [y, b, a] = highpass(x, wpass, varargin)
%HIGHPASS Filtre passe-haut appliqué à un signal.
%   Y = HIGHPASS(X,WPASS) filtre X par un passe-haut dont la bande
%   passante commence à WPASS, fréquence normalisée entre 0 et 1.
%   Y = HIGHPASS(X,FPASS,FS) donne la fréquence en hertz.
%
%   Les options sont celles de LOWPASS : 'Steepness',
%   'StopbandAttenuation' et 'ImpulseResponse'.
%
%   [Y,B,A] = HIGHPASS(...) rend aussi les coefficients du filtre.
%
%   Exemple :
%      t = (0:999)' / 1000;
%      x = sin(2*pi*10*t) + sin(2*pi*300*t);
%      y = highpass(x, 100, 1000);
%
%   Voir aussi LOWPASS, BANDPASS, BANDSTOP, ELLIP, FILTFILT.
    [wpass, options] = lireOptionsBande(wpass, varargin{:});
    [b, a] = concevoirBande(wpass, 'high', options);
    y = appliquerBande(x, b, a);
end
