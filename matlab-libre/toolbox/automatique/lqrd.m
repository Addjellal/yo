function [K, S, poles] = lqrd(A, B, Q, R, Ts, N)
%LQRD Commande discrète d'un procédé continu.
%   [K,S,P] = LQRD(A,B,Q,R,TS) rend le gain du retour d'état discret qui
%   minimise le coût continu
%
%      integrale de x'Qx + u'Ru
%
%   lorsque la commande est maintenue constante entre deux instants
%   d'échantillonnage. Ce n'est pas la même chose que discrétiser le
%   procédé puis appliquer DLQR au coût discret naïf : il faut intégrer le
%   coût sur chaque intervalle, ce qui fait apparaître un terme croisé.
%
%   L'intégration est exacte. En augmentant l'état de la commande, qui
%   est constante par morceaux, le problème se ramène à une seule
%   exponentielle de matrice (méthode de Van Loan) :
%
%      expm([-Aa'  Qa ; 0  Aa] * TS)
%
%   dont les blocs donnent d'un coup Ad, Bd, Qd, Nd et Rd.
%
%   Exemple :
%      k = lqrd(0, 1, 1, 1, 0.01);   % voisin de lqr(0,1,1,1) = 1
%
%   Voir aussi DLQR, LQR, C2D.
    n = size(A, 1);
    m = size(B, 2);
    if nargin < 6 || isempty(N), N = zeros(n, m); end
    % État augmenté [x; u], la commande étant constante sur l'intervalle.
    Aa = [A, B; zeros(m, n + m)];
    Qa = [Q, N; N', R];
    Qa = (Qa + Qa') / 2;
    M = expm([-Aa', Qa; zeros(n + m), Aa] * Ts);
    Phi = M(n + m + 1:end, n + m + 1:end);
    Qd = Phi' * M(1:n + m, n + m + 1:end);
    Qd = (Qd + Qd') / 2;
    Ad = Phi(1:n, 1:n);
    Bd = Phi(1:n, n + 1:end);
    Qdx = Qd(1:n, 1:n);
    Ndx = Qd(1:n, n + 1:end);
    Rdx = Qd(n + 1:end, n + 1:end);
    [K, S, poles] = dlqr(Ad, Bd, Qdx, Rdx, Ndx);
end
