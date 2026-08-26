function [sysb, g, T, Ti] = balreal(sys)
%BALREAL Réalisation équilibrée.
%   [SYSB,G,T,TI] = BALREAL(SYS) change de base pour que les deux
%   grammiens deviennent égaux et diagonaux :
%
%      Wc = Wo = diag(G)
%
%   G porte les valeurs singulières de Hankel, décroissantes. Dans cette
%   base, chaque état est aussi facile à atteindre qu'à observer, ce qui
%   donne un critère net pour décider lesquels supprimer.
%
%   La construction passe par les facteurs de Cholesky Wc = Lc Lc' et
%   Wo = Lo Lo' : si Lo' Lc = U S V', alors T = S^{-1/2} U' Lo' équilibre,
%   et son inverse vaut TI = Lc V S^{-1/2}.
%
%   Exemple :
%      [sb, g] = balreal(ss([-1 0; 0 -2], [1; 1], [1 1], 0));
%      max(abs(gram(sb, 'c') - gram(sb, 'o')))   % nul
%
%   Voir aussi HSVD, MODRED, BALRED, GRAM.
    s = ss(sys);
    n = size(s.A, 1);
    if n == 0
        sysb = s; g = zeros(0, 1); T = []; Ti = []; return
    end
    if ~isstable(s)
        error('control:balreal:Unstable', ...
              'Les grammiens ne convergent que pour un modèle stable.');
    end
    Wc = gram(s, 'c');
    Wo = gram(s, 'o');
    Lc = cholFactorise(Wc);
    Lo = cholFactorise(Wo);
    [U, S, V] = svd(Lo' * Lc);
    valeurs = diag(S);
    racine = sqrt(max(valeurs, eps));
    T = diag(1 ./ racine) * U' * Lo';
    Ti = Lc * V * diag(1 ./ racine);
    sysb = ss(T * s.A * Ti, T * s.B, s.C * Ti, s.D, s.Ts);
    g = valeurs(:);
end

function L = cholFactorise(W)
%CHOLFACTORISE Facteur bas de W, tolérant à une définie positive de peu.
    W = (W + W') / 2;
    [V, D] = eig(W);
    d = max(real(diag(D)), 0);
    L = V * diag(sqrt(d));
end
