function sysc = d2c(sys, methode)
%D2C Retour au continu d'un modèle échantillonné.
%   SYSC = D2C(SYSD) rend le modèle continu dont la discrétisation par
%   bloqueur d'ordre zéro redonne SYSD. C'est l'opération inverse de C2D,
%   au bruit numérique près.
%
%   SYSC = D2C(SYSD,'tustin') emploie la transformation bilinéaire.
%
%   Exemples :
%      d = c2d(tf(1, [1 1]), 0.05);
%      c = d2c(d);
%      abs(dcgain(c) - 1) < 1e-6            % le gain statique est rendu
%
%   Voir aussi C2D, D2D, SS, TF.
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
