function Z = s2z(S, z0)
%S2Z Paramètres S vers paramètres Z : Z = z0 (I + S)(I - S)^-1.
%   Z = S2Z(S) convertit les paramètres S, N x N ou N x N x K (K
%   fréquences), en paramètres Z, pour une impédance de référence de
%   50 ohms ; S2Z(S,Z0) la choisit. Comme MATLAB (Pozar, Microwave
%   Engineering, tableau 4.2).
%
%   Exemple :
%      S = [0 0.7079; 0.7079 0];     % atténuateur adapté de 3 dB
%      Z = s2z(S)                    % réseau en T : 150.3, 141.9, 150.3
%
%   Voir aussi Z2S, S2Y, S2ABCD, Z2GAMMA.
    if nargin < 2, z0 = 50; end
    Z = matlibre_rf_matrices(S, @(s) z0 * ((eye(size(s, 1)) + s) / (eye(size(s, 1)) - s)));
end
