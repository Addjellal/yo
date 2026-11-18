function ABCD = s2abcd(S, z0)
%S2ABCD Paramètres S d'un quadripôle vers paramètres ABCD (chaîne).
%   ABCD = S2ABCD(S) pour 50 ohms, S2ABCD(S,Z0) sinon ; S est 2 x 2 ou
%   2 x 2 x K. Les formules de Pozar (tableau 4.2) :
%      A = ((1+S11)(1-S22) + S12 S21) / (2 S21)
%      B = z0 ((1+S11)(1+S22) - S12 S21) / (2 S21)
%      C = ((1-S11)(1-S22) - S12 S21) / (2 S21 z0)
%      D = ((1-S11)(1+S22) + S12 S21) / (2 S21)
%   Les matrices ABCD de quadripôles en cascade se multiplient.
%
%   Exemple :
%      s2abcd([0 1; 1 0])            % une ligne adaptée sans retard : eye(2)
%
%   Voir aussi ABCD2S, S2Z.
    if nargin < 2, z0 = 50; end
    if size(S, 1) ~= 2
        error('rf:s2abcd:Taille', 'Les paramètres ABCD sont ceux d''un quadripôle (2 x 2).');
    end
    ABCD = matlibre_rf_matrices(S, @(s) [ ...
        ((1 + s(1,1)) * (1 - s(2,2)) + s(1,2) * s(2,1)) / (2 * s(2,1)), ...
        z0 * ((1 + s(1,1)) * (1 + s(2,2)) - s(1,2) * s(2,1)) / (2 * s(2,1)); ...
        ((1 - s(1,1)) * (1 - s(2,2)) - s(1,2) * s(2,1)) / (2 * s(2,1) * z0), ...
        ((1 - s(1,1)) * (1 + s(2,2)) + s(1,2) * s(2,1)) / (2 * s(2,1))]);
end
