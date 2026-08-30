function [wn, zeta, p] = damp(sys)
%DAMP Pulsations propres et amortissements.
%   [WN,ZETA] = DAMP(SYS) rend, pour chaque pôle, la pulsation propre WN
%   en radians par seconde et le coefficient d'amortissement ZETA. Un
%   ZETA sous 0.7 annonce un dépassement ; sous 0.3, des oscillations
%   marquées ; négatif, l'instabilité.
%
%   [WN,ZETA,P] = DAMP(SYS) rend aussi les pôles. Pour un modèle
%   échantillonné, ils sont d'abord ramenés au continu par log(z)/Ts.
%
%   Exemples :
%      [wn, zeta] = damp(tf(1, [1 0.4 1]));
%      wn(1)                                % 1 rad/s
%      zeta(1)                              % 0.2, peu amorti
%
%   Voir aussi POLE, PZMAP, STEPINFO, EIG.
    p = pole(sys);
    if sys.Ts > 0
        p = log(p) / sys.Ts;
    end
    wn = abs(p);
    zeta = -real(p) ./ max(wn, eps);
end
