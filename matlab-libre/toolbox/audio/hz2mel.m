function mel = hz2mel(hz)
%HZ2MEL Fréquences en hertz vers l'échelle de Mel.
%   MEL = HZ2MEL(HZ) = 2595 log10(1 + HZ/700), la formule
%   d'O'Shaughnessy (1987) qu'emploie MATLAB. Par construction, 1000 Hz
%   valent 1000 mels.
%
%   Exemple :
%      hz2mel([0 1000 4000])      % 0, 1000, 2146.1
%
%   Voir aussi MEL2HZ, HZ2BARK, HZ2ERB, MELFILTERBANK.
    mel = 2595 * log10(1 + hz / 700);
end
