function sysT = ss2ss(sys, T)
%SS2SS Changement de base d'un modèle d'état.
%   SYST = SS2SS(SYS,T) applique le changement de variable xbar = T*x :
%
%      Abar = T A T^-1,  Bbar = T B,  Cbar = C T^-1,  Dbar = D
%
%   La fonction de transfert ne change pas ; seule la réalisation change.
%
%   Exemple :
%      s = ss([0 1; -2 -3], [0; 1], [1 0], 0);
%      t = ss2ss(s, [1 0; 1 1]);
%      max(abs(pole(t) - pole(s)))   % nul
%
%   Voir aussi CANON, BALREAL, CTRBF, OBSVF.
    s = ss(sys);
    if size(T, 1) ~= size(T, 2) || size(T, 1) ~= size(s.A, 1)
        error('control:ss2ss:BadSize', ...
              'T doit être carrée, de la taille de A.');
    end
    sysT = ss(T * s.A / T, T * s.B, s.C / T, s.D, s.Ts);
end
