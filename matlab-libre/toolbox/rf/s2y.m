function Y = s2y(S, z0)
%S2Y Paramètres S vers paramètres Y : Y = (1/z0) (I - S)(I + S)^-1.
%   Y = S2Y(S) pour 50 ohms, S2Y(S,Z0) pour une autre référence ; S est
%   N x N ou N x N x K.
%
%   Exemple :
%      Y = s2y([0 1; 1 0])           % une ligne adaptée sans pertes
%
%   Voir aussi Y2S, S2Z.
    if nargin < 2, z0 = 50; end
    Y = matlibre_rf_matrices(S, @(s) ((eye(size(s, 1)) - s) / (eye(size(s, 1)) + s)) / z0);
end
