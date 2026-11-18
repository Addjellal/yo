function S = y2s(Y, z0)
%Y2S Paramètres Y vers paramètres S : S = (I - z0 Y)(I + z0 Y)^-1.
%   S = Y2S(Y) pour 50 ohms, Y2S(Y,Z0) pour une autre référence.
%
%   Exemple :
%      S = y2s([1 -1; -1 1] / 100)   % une impédance série de 100 ohms
%
%   Voir aussi S2Y, Z2S.
    if nargin < 2, z0 = 50; end
    S = matlibre_rf_matrices(Y, @(y) (eye(size(y, 1)) - z0 * y) / (eye(size(y, 1)) + z0 * y));
end
