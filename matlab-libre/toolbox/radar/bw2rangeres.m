function resolution = bw2rangeres(bande, c)
%BW2RANGERES Résolution en distance d'une bande passante : c/(2B).
%   DR = BW2RANGERES(B) rend la résolution en distance (m) d'un signal de
%   bande B (Hz) ; BW2RANGERES(B,C) prend la célérité C (par défaut celle
%   de la lumière). Deux cibles plus proches que DR se confondent après
%   compression d'impulsion.
%
%   Exemple :
%      bw2rangeres(10e6)          % 14.99 m pour 10 MHz
%
%   Voir aussi RANGERES2BW, PULSECOMPRESSION.
    if nargin < 2
        c = physconst('LightSpeed');
    end
    resolution = c ./ (2 * bande);
end
