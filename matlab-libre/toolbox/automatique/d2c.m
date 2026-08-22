function sysc = d2c(sys, methode)
%D2C Repasse un modèle discret en continu (logarithme matriciel).
    if nargin < 2
        methode = 'zoh';
    end
    s = ss(sys);
    Ts = s.Ts;
    A = logm(s.A) / Ts;
    n = size(A, 1);
    if rank(A) == n
        B = (expm(A * Ts) - eye(n)) \ A * s.B;
    else
        B = s.B / Ts;
    end
    sysc = ss(real(A), real(B), s.C, s.D, 0);
end
