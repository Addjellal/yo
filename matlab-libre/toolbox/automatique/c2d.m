function sysd = c2d(sys, Ts, methode)
%C2D Discrétisation d'un modèle continu.
%   SYSD = C2D(SYS,TS) échantillonne le modèle à la période TS par
%   bloqueur d'ordre zéro : l'entrée est supposée constante entre deux
%   instants, ce qui est le cas derrière un convertisseur numérique.
%
%   SYSD = C2D(SYS,TS,'tustin') emploie la transformation bilinéaire, qui
%   conserve mieux la réponse fréquentielle près de la fréquence de
%   Nyquist, au prix d'une légère distorsion.
%
%   Exemples :
%      d = c2d(tf(1, [1 1]), 0.1);
%      d.Ts                             % 0.1
%      abs(dcgain(d) - dcgain(tf(1, [1 1]))) < 1e-9    % le gain statique tient
%
%   Voir aussi D2C, D2D, TUSTIN, SS, TF.
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
