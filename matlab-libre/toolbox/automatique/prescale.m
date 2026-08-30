function sysp = prescale(sys, varargin)
%PRESCALE Met un modèle à l'échelle pour le calcul.
%   SYSP = PRESCALE(SYS) rend un modèle équivalent dont les états sont
%   remis à l'échelle : cela améliore le conditionnement des calculs de
%   pôles, de zéros et de réponses fréquentielles, sans changer ce que le
%   modèle représente.
%
%   La mise à l'échelle est diagonale, par puissances de deux : elle est
%   donc exacte en virgule flottante.
%
%   Exemples :
%      sys = ss([-1 1e6; 0 -2], [1; 1e6], [1 1e-6], 0);
%      p = prescale(sys);
%      max(abs(sort(pole(p)) - sort(pole(sys)))) < 1e-6      % memes poles
%      abs(dcgain(p) - dcgain(sys)) < 1e-9                   % meme gain
%
%   Voir aussi SS, BALREAL, POLE, MATLIBRE_EQUILIBRER.
    sys = ss(sys);
    n = size(sys.A, 1);
    if n == 0
        sysp = sys;
        return
    end
    [~, echelles] = matlibre_equilibrer(sys.A);
    T = diag(echelles);
    Ti = diag(1 ./ echelles);
    sysp = ss(Ti * sys.A * T, Ti * sys.B, sys.C * T, sys.D, sys.Ts);
end
