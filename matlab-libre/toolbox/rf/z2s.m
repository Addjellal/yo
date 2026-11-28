function S = z2s(Z, z0)
%Z2S Paramètres Z vers paramètres S : S = (Z - z0 I)(Z + z0 I)^-1.
%   S = Z2S(Z) convertit des paramètres Z, N x N ou N x N x K, en
%   paramètres S pour 50 ohms ; Z2S(Z,Z0) choisit la référence.
%
%   Exemple :
%      % Pozar, l'atténuateur de 3 dB en T.
%      K = 10 ^ (3 / 20);
%      R1 = 50 * (K - 1) / (K + 1);  R3 = 100 * K / (K ^ 2 - 1);
%      S = z2s([R1 + R3, R3; R3, R1 + R3])   % S11 = 0, S21 = 0.7079
%
%   Voir aussi S2Z, Y2S, ABCD2S.
    if nargin < 2, z0 = 50; end
    S = matlibre_rf_matrices(Z, @(z) (z - z0 * eye(size(z, 1))) / (z + z0 * eye(size(z, 1))));
end
