function [y, t, x] = lsim(sys, u, t, x0)
%LSIM Réponse à une entrée quelconque.
%   [Y,T,X] = LSIM(SYS,U,T) simule la réponse du modèle à l'entrée U
%   échantillonnée aux instants T. L'entrée est interpolée linéairement
%   entre deux instants ; le pas doit être assez fin devant les
%   constantes de temps du modèle.
%
%   [Y,T,X] = LSIM(SYS,U,T,X0) part d'une condition initiale.
%
%   Exemples :
%      t = linspace(0, 5, 200)';
%      y = lsim(tf(1, [1 1]), ones(size(t)), t);
%      abs(y(end) - 1) < 0.02               % la reponse indicielle converge vers 1
%      y2 = lsim(tf(1, [1 1]), sin(t), t);
%      max(abs(y2)) < 1                     % un premier ordre attenue
%
%   Voir aussi STEP, IMPULSE, INITIAL, GENSIG.
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
