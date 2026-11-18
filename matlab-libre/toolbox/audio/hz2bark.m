function bark = hz2bark(hz)
%HZ2BARK Fréquences en hertz vers l'échelle de Bark (Traunmüller, 1990).
%   BARK = HZ2BARK(HZ) = 26.81 HZ / (1960 + HZ) - 0.53, corrigé aux deux
%   bouts comme dans MATLAB : sous 2 Bark, b + 0.15 (2 - b) ; au-dessus de
%   20.1 Bark, b + 0.22 (b - 20.1). L'échelle de Bark compte les bandes
%   critiques de l'oreille (Zwicker) : 1000 Hz tombent vers 8.5 Bark.
%
%   Exemple :
%      hz2bark(1000)              % 8.527
%
%   Voir aussi BARK2HZ, HZ2MEL, HZ2ERB.
    bark = 26.81 * hz ./ (1960 + hz) - 0.53;
    bas = bark < 2;
    bark(bas) = bark(bas) + 0.15 * (2 - bark(bas));
    haut = bark > 20.1;
    bark(haut) = bark(haut) + 0.22 * (bark(haut) - 20.1);
end
