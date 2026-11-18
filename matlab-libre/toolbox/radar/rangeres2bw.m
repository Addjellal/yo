function bande = rangeres2bw(resolution, c)
%RANGERES2BW Bande passante nécessaire à une résolution en distance : c/(2 dR).
%   B = RANGERES2BW(DR) rend la bande (Hz) qui donne la résolution DR (m) ;
%   RANGERES2BW(DR,C) prend la célérité C.
%
%   Exemple :
%      rangeres2bw(1)             % 149.9 MHz pour un mètre
%
%   Voir aussi BW2RANGERES.
    if nargin < 2
        c = physconst('LightSpeed');
    end
    bande = c ./ (2 * resolution);
end
