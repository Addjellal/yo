function [y, b, a] = lowpass(x, wpass, varargin)
%LOWPASS Filtre passe-bas appliqué à un signal.
%   Y = LOWPASS(X,WPASS) filtre X par un passe-bas dont la bande passante
%   va jusqu'à WPASS, fréquence normalisée entre 0 et 1, 1 valant la
%   moitié de la fréquence d'échantillonnage.
%
%   Y = LOWPASS(X,FPASS,FS) donne la fréquence en hertz, FS étant la
%   fréquence d'échantillonnage.
%
%   Y = LOWPASS(...,'Steepness',S) règle la raideur de la transition, S
%   entre 0,5 et 1 (0,85 par défaut) : plus S est proche de 1, plus la
%   transition est courte et l'ordre du filtre élevé.
%   Y = LOWPASS(...,'StopbandAttenuation',A) impose A décibels
%   d'atténuation en bande coupée (60 par défaut).
%   Y = LOWPASS(...,'ImpulseResponse','fir') emploie un filtre à réponse
%   impulsionnelle finie au lieu du filtre récursif.
%
%   [Y,B,A] = LOWPASS(...) rend aussi les coefficients du filtre. MATLAB
%   rend un objet digitalFilter ; MatLibre n'en a pas, et rend le couple
%   qui le décrit.
%
%   Le filtrage est à phase nulle — FILTFILT —, comme dans MATLAB : la
%   forme des transitoires du signal est préservée.
%
%   Exemple :
%      t = (0:999)' / 1000;
%      x = sin(2*pi*10*t) + sin(2*pi*300*t);
%      y = lowpass(x, 100, 1000);
%
%   Voir aussi HIGHPASS, BANDPASS, BANDSTOP, ELLIP, FILTFILT, DESIGNFILT.
    [wpass, options] = lireOptionsBande(wpass, varargin{:});
    [b, a] = concevoirBande(wpass, 'low', options);
    y = appliquerBande(x, b, a);
end
