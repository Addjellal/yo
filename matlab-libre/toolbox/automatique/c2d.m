function sysd = c2d(sys, Ts, methode)
%C2D Discrétisation d'un modèle continu.
%   SYSD = C2D(SYS,TS) utilise le bloqueur d'ordre zéro.
%   SYSD = C2D(SYS,TS,'tustin') utilise la transformation bilinéaire.
    if nargin < 3
        methode = 'zoh';
    end
    s = ss(sys);
    n = size(s.A, 1);
    switch lower(char(methode))
        case 'tustin'
            I = eye(n);
            M = I - s.A * Ts / 2;
            Ad = M \ (I + s.A * Ts / 2);
            Bd = M \ (s.B * Ts);
            Cd = s.C / M;
            Dd = s.D + s.C * (M \ (s.B * Ts / 2));
        otherwise
            Ad = expm(s.A * Ts);
            if rank(s.A) == n
                Bd = s.A \ (Ad - eye(n)) * s.B;
            else
                Bd = s.B * Ts;
            end
            Cd = s.C;
            Dd = s.D;
    end
    sysd = ss(Ad, Bd, Cd, Dd, Ts);
end
