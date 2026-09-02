function [K, CL, mu, info] = musyn(P, nmes, ncom, options)
%MUSYN Synthèse mu.
%   [K,CL,MU] = MUSYN(P,NMES,NCOM) fait ce que fait DKSYN : il cherche le
%   correcteur qui minimise la valeur singulière structurée de la boucle.
%   C'est le nom que MATLAB donne à cette synthèse depuis R2018b ;
%   MatLibre garde les deux.
%
%   MUSYN(...,OPTIONS) accepte les mêmes options que DKSYN.
%
%   Exemples :
%      G = ss(tf(1, [1 1]));
%      P = augw(G, tf(1, [1 0.1]), 0.1, []);
%      [K, CL, mu] = musyn(P, 1, 1);
%
%   Voir aussi DKSYN, MUSSV, HINFSYN, ROBSTAB, WCGAIN.
    if nargin < 4
        options = struct();
    end
    [K, CL, mu, info] = dksyn(P, nmes, ncom, options);
end
