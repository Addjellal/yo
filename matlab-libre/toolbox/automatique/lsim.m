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
    % Un retard d'entree retarde ce qui arrive, un retard de sortie ce
    % qui sort. On les applique donc de part et d'autre de la simulation
    % plutot qu'en bloc : l'etat initial, lui, est deja la, et sa reponse
    % libre ne doit pas etre decalee.
    retardEntree = matlibre_retard_scalaire(decaleEntree(sys), 'LSIM');
    retardSortie = matlibre_retard_scalaire(decaleSortie(sys), 'LSIM');
    if retardEntree ~= 0
        u = interp1(t, u, t - retardEntree, 'linear', 0);
        u = u(:);
    end
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
    if retardSortie ~= 0
        y = interp1(t, y, t - retardSortie, 'linear', 0);
        y = y(:);
    end
end

% Les deux moities du retard. Le retard de couple compte comme un retard
% d'entree : pour une voie, les deux sont indiscernables.
function sys = decaleEntree(sys)
    sys.OutputDelay = 0;
end

function sys = decaleSortie(sys)
    sys.InputDelay = 0;
    sys.IODelay = 0;
end
