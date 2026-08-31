function [K, CL, norme, info] = h2syn(P, nmes, ncom)
%H2SYN Synthèse H2.
%   [K,CL,N] = H2SYN(P,NMES,NCOM) cherche le correcteur K qui minimise la
%   norme H2 du transfert entre les entrées exogènes et les sorties
%   régulées du modèle augmenté P. NMES est le nombre de mesures — les
%   dernières sorties de P —, NCOM le nombre de commandes — les dernières
%   entrées.
%
%   CL est la boucle fermée LFT(P,K) et N sa norme H2.
%
%   [K,CL,N,INFO] = H2SYN(...) rend en outre les deux solutions de
%   Riccati et les deux gains.
%
%   Là où la synthèse H-infini minimise le pire gain à la pire
%   fréquence, la synthèse H2 minimise l'énergie de la réponse
%   impulsionnelle — ce qui revient, pour une entrée en bruit blanc, à
%   minimiser la variance de la sortie. C'est le même problème que le
%   LQG, écrit sous forme de modèle augmenté.
%
%   La solution est celle de Doyle, Glover, Khargonekar et Francis : deux
%   équations de Riccati indépendantes, l'une pour la commande, l'autre
%   pour l'estimation, et le principe de séparation qui les réunit.
%
%   Les hypothèses usuelles doivent tenir : (A,B2) stabilisable, (C2,A)
%   détectable, D12 de rang plein en colonnes, D21 de rang plein en
%   lignes, et aucun zéro de transmission sur l'axe imaginaire. D11 doit
%   être nul, faute de quoi la norme H2 de la boucle est infinie.
%
%   Exemples :
%      G = ss(tf(1, [1 1]));
%      P = augw(G, tf(1, [1 0.1]), 0.1, []);
%      [K, CL, n] = h2syn(P, 1, 1);
%      n                              % la norme H2 atteinte
%      h2norm(CL) - n                 % nul : c'est bien elle
%
%   Voir aussi HINFSYN, H2HINFSYN, LQG, H2NORM, AUGW, MIXSYN, LFT.
    P = ss(P);
    [A, B1, B2, C1, C2, D11, D12, D21, D22] = matlibre_decouper_augmente(P, nmes, ncom);
    if max(max(abs(D11))) > 1e-9
        error('robust:h2syn:NonzeroD11', ...
              'H2SYN needs D11 = 0: otherwise the H2 norm is infinite.');
    end
    n = size(A, 1);
    % La commande : Riccati de la commande optimale.
    R = D12' * D12;
    if rcond(R) < eps
        error('robust:h2syn:RankD12', 'D12 must have full column rank.');
    end
    Ac = A - B2 / R * D12' * C1;
    Qc = C1' * (eye(size(C1, 1)) - D12 / R * D12') * C1;
    [X, okX] = matlibre_riccati(Ac, -(B2 / R * B2'), Qc);
    if ~okX
        error('robust:h2syn:NoSolution', ...
              'The control Riccati equation has no stabilizing solution.');
    end
    F = -(R \ (B2' * X + D12' * C1));
    % L'estimation : Riccati duale.
    S = D21 * D21';
    if rcond(S) < eps
        error('robust:h2syn:RankD21', 'D21 must have full row rank.');
    end
    Af = A - B1 * D21' / S * C2;
    Qf = B1 * (eye(size(B1, 2)) - D21' / S * D21) * B1';
    [Y, okY] = matlibre_riccati(Af', -(C2' / S * C2), Qf);
    if ~okY
        error('robust:h2syn:NoSolution', ...
              'The filter Riccati equation has no stabilizing solution.');
    end
    L = -((Y * C2' + B1 * D21') / S);
    % Le correcteur : l'estimateur, referme sur le retour d'etat.
    Ak = A + B2 * F + L * C2 + L * D22 * F;
    K = ss(Ak, -L, F, zeros(size(F, 1), size(L, 2)), P.Ts);
    CL = lft(P, K);
    norme = h2norm(CL);
    info = struct('X', X, 'Y', Y, 'F', F, 'L', L, 'gamma', norme);
end
