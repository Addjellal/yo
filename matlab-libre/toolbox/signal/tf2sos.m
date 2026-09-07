function [sos, g] = tf2sos(b, a)
%TF2SOS Fonction de transfert vers sections du second ordre.
%   [SOS,G] = TF2SOS(B,A) rend une matrice Lx6, chaque ligne étant
%   [b0 b1 b2 1 a1 a2], et le gain global G. Les pôles complexes sont
%   appariés à leur conjugué, ce qui garde des coefficients réels.
%
%   Exemple :
%      [b, a] = butter(4, 0.3);
%      [sos, g] = tf2sos(b, a);
%      size(sos, 1)                % 2 sections pour un ordre 4
%
%   Voir aussi SOS2TF, ZP2SOS, SOS2ZP, TF2ZP.
    [z, p, k] = tf2zp(b, a);
    [sos, g] = zp2sos(z, p, k);
end
