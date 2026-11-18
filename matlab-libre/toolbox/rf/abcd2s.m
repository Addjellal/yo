function S = abcd2s(ABCD, z0)
%ABCD2S Paramètres ABCD d'un quadripôle vers paramètres S.
%   S = ABCD2S(ABCD) pour 50 ohms, ABCD2S(ABCD,Z0) sinon (Pozar, tableau
%   4.2) : avec Q = A + B/z0 + C z0 + D,
%      S11 = (A + B/z0 - C z0 - D)/Q    S12 = 2 (AD - BC)/Q
%      S21 = 2/Q                        S22 = (-A + B/z0 - C z0 + D)/Q
%
%   Exemple :
%      abcd2s([1 100; 0 1])          % impédance série de 100 ohms : S11 = 0.5
%
%   Voir aussi S2ABCD.
    if nargin < 2, z0 = 50; end
    if size(ABCD, 1) ~= 2
        error('rf:abcd2s:Taille', 'Les paramètres ABCD sont ceux d''un quadripôle (2 x 2).');
    end
    S = matlibre_rf_matrices(ABCD, @(m) unQuadripole(m, z0));
end

function s = unQuadripole(m, z0)
    A = m(1, 1); B = m(1, 2); C = m(2, 1); D = m(2, 2);
    Q = A + B / z0 + C * z0 + D;
    s = [(A + B / z0 - C * z0 - D) / Q, 2 * (A * D - B * C) / Q; ...
         2 / Q, (-A + B / z0 - C * z0 + D) / Q];
end
