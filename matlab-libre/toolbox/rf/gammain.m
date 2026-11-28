function g = gammain(S, z0, zl)
%GAMMAIN Coefficient de réflexion à l'entrée d'un quadripôle chargé.
%   G = GAMMAIN(S,Z0,ZL) : Gin = S11 + S12 S21 GL / (1 - S22 GL), avec
%   GL = (ZL - Z0)/(ZL + Z0) (Pozar, équation 11.3). S est 2 x 2 ou
%   2 x 2 x K.
%
%   Exemple :
%      gammain([0 1; 1 0], 50, 100)  % une ligne adaptée transmet GL : 1/3
%
%   Voir aussi GAMMAOUT, Z2GAMMA.
    gl = z2gamma(zl, z0);
    g = squeeze(S(1, 1, :) + S(1, 2, :) .* S(2, 1, :) .* gl ./ (1 - S(2, 2, :) .* gl));
end
