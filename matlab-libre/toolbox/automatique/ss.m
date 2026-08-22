function sys = ss(A, B, C, D, Ts)
%SS Modèle d'état.
%   SYS = SS(A,B,C,D) crée un modèle continu dx/dt = Ax + Bu, y = Cx + Du.
%   SYS = SS(A,B,C,D,TS) crée un modèle échantillonné.
%   SYS = SS(SYSTF) convertit une fonction de transfert en modèle d'état.
    if nargin == 1 && isstruct(A)
        if strcmp(A.type, 'ss')
            sys = A;
            return;
        end
        [a, b, c, d] = tf2ss(A.num, A.den);
        sys = ss(a, b, c, d, A.Ts);
        return;
    end
    if nargin < 5
        Ts = 0;
    end
    sys = struct('type', 'ss', 'num', [], 'den', [], 'Ts', Ts, ...
                 'A', A, 'B', B, 'C', C, 'D', D);
end
