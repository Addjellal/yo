function g = gammaout(S, z0, zs)
%GAMMAOUT Coefficient de réflexion à la sortie d'un quadripôle.
%   G = GAMMAOUT(S,Z0,ZS) : Gout = S22 + S12 S21 GS / (1 - S11 GS), avec
%   GS = (ZS - Z0)/(ZS + Z0) (Pozar, équation 11.4).
%
%   Exemple :
%      gammaout([0 1; 1 0], 50, 25)  % -1/3
%
%   Voir aussi GAMMAIN, Z2GAMMA.
    gs = z2gamma(zs, z0);
    g = squeeze(S(2, 2, :) + S(1, 2, :) .* S(2, 1, :) .* gs ./ (1 - S(1, 1, :) .* gs));
end
