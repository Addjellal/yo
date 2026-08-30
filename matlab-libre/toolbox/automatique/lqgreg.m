function reg = lqgreg(kest, K, type)
%LQGREG Assemble le régulateur LQG à partir de l'estimateur et du gain.
%   REG = LQGREG(KEST,K) réunit l'estimateur de Kalman KEST — celui que
%   rend KALMAN — et le gain de retour d'état K — celui que rend LQR — en
%   un seul correcteur qui prend la mesure Y et rend la commande U :
%
%      xchapeau' = (A - B*K - L*C) xchapeau + L y
%      u         = -K xchapeau
%
%   C'est le principe de séparation : on estime l'état comme si l'on
%   commandait parfaitement, on le commande comme si on l'observait
%   parfaitement, et la réunion est optimale.
%
%   REG = LQGREG(KEST,K,'current') emploie l'estimateur courant en
%   discret ; MatLibre ne fait pas la différence et rend le même
%   régulateur.
%
%   Le signe est celui de MATLAB : REG rend U, et se referme sur le
%   procédé par une contre-réaction positive — feedback(G, REG, +1) — ou,
%   ce qui revient au même, par -REG en contre-réaction négative.
%
%   Exemples :
%      G = ss(-1, 1, 1, 0);
%      [kest, L] = kalman(G, 1, 1);
%      K = lqr(G.A, G.B, 1, 1);
%      C = lqgreg(kest, K);
%      max(real(pole(feedback(G, -C)))) < 0     % la boucle est stable
%
%   Voir aussi KALMAN, LQR, LQG, ESTIM, REG.
    if nargin < 3
        type = 'delayed';
    end
    A = kest.A;          % déjà A - L*C
    Be = kest.B;
    n = size(A, 1);
    % L'estimateur prend [u ; y] : la seconde moitié de B est L.
    nu = size(Be, 2) - size(kest.C, 1) + n;
    L = Be(:, end - (size(Be, 2) - nu) + 1:end);
    Bu = Be(:, 1:size(Be, 2) - size(L, 2));
    reg = ss(A - Bu * K, L, -K, zeros(size(K, 1), size(L, 2)), kest.Ts);
end
