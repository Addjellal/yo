function [rapport, pire, info] = robuststab(sys, options)
%ROBUSTSTAB Marge de stabilité robuste (nom historique).
%   [R,V] = ROBUSTSTAB(SYS) fait ce que fait ROBSTAB. C'est le nom que la
%   fonction portait avant R2016a ; MATLAB le garde pour les programmes
%   anciens, et MatLibre aussi.
%
%   Exemples :
%      k = ureal('k', 4, 'Range', [3 5]);
%      G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
%      robuststab(G)
%
%   Voir aussi ROBSTAB, WCGAIN, ROBGAIN, MUSSV.
    if nargin < 2
        options = struct();
    end
    [rapport, pire, info] = robstab(sys, options);
end
