function [stable, instable] = stabsep(sys)
%STABSEP Sépare la partie stable de la partie instable d'un modèle.
%   [GS,GNS] = STABSEP(SYS) découpe le modèle en deux : GS ne garde que
%   les modes stables, GNS que les autres, et leur somme redonne SYS.
%
%   C'est ce qu'il faut avant une réduction de modèle — on ne réduit que
%   ce qui est stable — et pour mesurer une norme H2 ou H-infini d'un
%   modèle qui ne l'est pas tout entier.
%
%   Le découpage passe par la forme diagonale : chaque mode va d'un côté
%   ou de l'autre selon le signe de sa partie réelle, ou son module en
%   discret.
%
%   Exemples :
%      [gs, gns] = stabsep(ss([-1 0; 0 2], [1; 1], [1 1], 0));
%      order(gs)                        % 1 : le mode en -1
%      order(gns)                       % 1 : le mode en +2
%      abs(dcgain(gs) + dcgain(gns) - dcgain(ss([-1 0; 0 2], [1;1], [1 1], 0))) < 1e-9
%
%   Voir aussi BALRED, MODRED, POLE, HSVD, EIG.
    sys = ss(sys);
    A = sys.A;
    n = size(A, 1);
    if n == 0
        stable = sys;
        instable = ss(zeros(0, 0), zeros(0, size(sys.D, 2)), ...
                      zeros(size(sys.D, 1), 0), zeros(size(sys.D)), sys.Ts);
        return
    end
    [V, D] = eig(A);
    valeurs = diag(D);
    if sys.Ts > 0
        estStable = abs(valeurs) < 1;
    else
        estStable = real(valeurs) < 0;
    end
    W = inv(V);
    Bt = W * sys.B;
    Ct = sys.C * V;
    garde = find(estStable);
    autre = find(~estStable);
    stable = ss(real(diag(valeurs(garde))), real(Bt(garde, :)), real(Ct(:, garde)), ...
                sys.D, sys.Ts);
    instable = ss(real(diag(valeurs(autre))), real(Bt(autre, :)), real(Ct(:, autre)), ...
                  zeros(size(sys.D)), sys.Ts);
end
