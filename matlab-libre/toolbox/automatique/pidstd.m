function sys = pidstd(Kp, Ti, Td, N, Ts)
%PIDSTD Correcteur PID sous forme standard.
%   C = PIDSTD(KP,TI,TD,N) rend
%
%      C(s) = KP * ( 1 + 1/(TI s) + TD s / ((TD/N) s + 1) )
%
%   C'est l'écriture des automaticiens : un gain global, un temps
%   d'intégration et un temps de dérivation, plutôt que trois gains
%   indépendants. N est le rapport de filtrage du terme dérivé, infini
%   par défaut, ce qui donne une dérivée pure.
%
%   C = PIDSTD(...,TS) rend un correcteur échantillonné.
%
%   La forme parallèle de PID s'en déduit par KI = KP/TI et KD = KP*TD.
%
%   Exemple :
%      c = pidstd(2, 1, 0);
%      tfdata(c)   % [2 2] / [1 0] : 2 + 2/s
%
%   Voir aussi PID, PIDTUNE.
    if nargin < 1 || isempty(Kp), Kp = 1; end
    if nargin < 2 || isempty(Ti), Ti = Inf; end
    if nargin < 3 || isempty(Td), Td = 0; end
    if nargin < 4 || isempty(N), N = Inf; end
    if nargin < 5, Ts = 0; end
    if isinf(Ti) || Ti == 0
        Ki = 0;
    else
        Ki = Kp / Ti;
    end
    Kd = Kp * Td;
    if isinf(N) || N == 0 || Td == 0
        Tf = 0;
    else
        Tf = Td / N;
    end
    sys = pid(Kp, Ki, Kd, Tf, Ts);
end
