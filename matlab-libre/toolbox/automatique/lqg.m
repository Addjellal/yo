function [reg, info] = lqg(sys, QXU, QWV)
%LQG Régulateur linéaire quadratique gaussien.
%   REG = LQG(SYS,QXU,QWV) assemble d'un coup le régulateur optimal d'un
%   procédé bruité : QXU pondère l'état et la commande dans le critère,
%   QWV décrit les covariances du bruit d'état et du bruit de mesure.
%
%   Les deux matrices sont bloc-diagonales par morceaux :
%      QXU = [Q  Nc ; Nc' R]  le coût, x'Qx + 2x'Nc*u + u'Ru
%      QWV = [Qn Nf ; Nf' Rn] les bruits, d'état puis de mesure
%
%   [REG,INFO] = LQG(...) rend en plus le gain de retour d'état, le gain
%   de l'estimateur et les deux solutions de Riccati.
%
%   C'est LQR et KALMAN réunis par LQGREG : le principe de séparation dit
%   que le régulateur ainsi obtenu est optimal.
%
%   Exemples :
%      G = ss(-1, 1, 1, 0);
%      C = lqg(G, eye(2), eye(2));
%      max(real(pole(feedback(G, -C)))) < 0     % la boucle est stable
%
%   Voir aussi LQR, KALMAN, LQGREG, CARE, H2SYN.
    sys = ss(sys);
    n = size(sys.A, 1);
    nu = size(sys.B, 2);
    ny = size(sys.C, 1);
    if nargin < 2 || isempty(QXU)
        QXU = eye(n + nu);
    end
    if nargin < 3 || isempty(QWV)
        QWV = eye(n + ny);
    end
    Q = QXU(1:n, 1:n);
    R = QXU(n+1:end, n+1:end);
    Nc = QXU(1:n, n+1:end);
    Qn = QWV(1:n, 1:n);
    Rn = QWV(n+1:end, n+1:end);
    [K, S] = lqr(sys.A, sys.B, Q, R, Nc);
    [L, P] = lqe(sys.A, eye(n), sys.C, Qn, Rn);
    reg = ss(sys.A - sys.B * K - L * sys.C, L, -K, zeros(nu, ny), sys.Ts);
    info = struct('Kx', K, 'L', L, 'S', S, 'P', P);
end
