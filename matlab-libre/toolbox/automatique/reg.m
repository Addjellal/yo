function rsys = reg(sys, K, L)
%REG Régulateur par retour d'état estimé.
%   RSYS = REG(SYS,K,L) assemble l'observateur de gain L et le retour
%   d'état u = -K xe en un seul correcteur, qui prend la mesure y et rend
%   la commande u :
%
%      dxe/dt = (A - BK - LC + LDK) xe + L y
%      u      = -K xe
%
%   Le signe moins du retour est déjà dans le correcteur : la boucle se
%   referme donc en contre-réaction positive, FEEDBACK(SERIES(C,G),1,+1).
%
%   Les pôles du correcteur ne sont ni ceux de A-BK ni ceux de A-LC :
%   c'est la boucle fermée complète, d'ordre 2n, qui a pour pôles la
%   réunion des deux, en vertu du principe de séparation.
%
%   Exemple :
%      g = ss([0 1; -2 -3], [0; 1], [1 0], 0);
%      k = place(g.A, g.B, [-3 -4]);
%      l = place(g.A', g.C', [-10 -12])';
%      c = reg(g, k, l);
%      sort(pole(feedback(series(c, g), 1, +1)))   % -12 -10 -4 -3
%
%   Voir aussi ESTIM, PLACE, LQR, KALMAN.
    s = ss(sys);
    Ac = s.A - s.B * K - L * s.C + L * s.D * K;
    rsys = ss(Ac, L, -K, zeros(size(K, 1), size(L, 2)), s.Ts);
end
