function [y, t, x] = lsim(sys, u, t, x0)
%LSIM Réponse d'un modèle à une entrée quelconque.
%   [Y,T] = LSIM(SYS,U,T) simule la réponse à l'entrée U aux instants T.
%   La discrétisation se fait par bloqueur d'ordre zéro sur le pas moyen.
    s = ss(sys);
    n = size(s.A, 1);
    if nargin < 4 || isempty(x0)
        x0 = zeros(n, 1);
    end
    t = t(:);
    u = u(:);
    N = numel(t);
    if N < 2
        error('control:lsim:TooFewSamples', 'T must contain at least two instants.');
    end
    dt = t(2) - t(1);
    if s.Ts > 0
        Ad = s.A;
        Bd = s.B;
    else
        Ad = expm(s.A * dt);
        if rank(s.A) == n
            Bd = s.A \ (Ad - eye(n)) * s.B;
        else
            Bd = s.B * dt;
        end
    end
    x = zeros(N, n);
    y = zeros(N, 1);
    etat = x0(:);
    for k = 1:N
        x(k, :) = etat.';
        y(k) = s.C * etat + s.D * u(k);
        etat = Ad * etat + Bd * u(k);
    end
end
