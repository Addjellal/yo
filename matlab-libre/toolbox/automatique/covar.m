function [P, Q] = covar(sys, W)
%COVAR Covariance de la réponse à un bruit blanc.
%   [P,Q] = COVAR(SYS,W) rend la covariance P de la sortie et la
%   covariance Q de l'état, en régime permanent, lorsque l'entrée est un
%   bruit blanc d'intensité W.
%
%   En continu, Q résout l'équation de Lyapunov A Q + Q A' + B W B' = 0 et
%   P vaut C Q C'. Un modèle continu dont la transmission directe D n'est
%   pas nulle donne une sortie de variance infinie : P vaut alors Inf,
%   puisque le bruit blanc continu n'a pas de variance finie.
%
%   En discret, Q = A Q A' + B W B' et P = C Q C' + D W D', toutes deux
%   finies.
%
%   Exemple :
%      covar(ss(-1, 1, 1, 0), 1)   % 0.5
%
%   Voir aussi GRAM, LYAP, DLYAP.
    s = ss(sys);
    if nargin < 2 || isempty(W), W = eye(size(s.B, 2)); end
    if isempty(s.A)
        Q = zeros(0, 0);
    elseif s.Ts == 0
        Q = lyap(s.A, s.B * W * s.B');
    else
        Q = dlyap(s.A, s.B * W * s.B');
    end
    if isempty(Q)
        P = s.D * W * s.D';
    else
        P = s.C * Q * s.C';
    end
    if s.Ts == 0
        if any(any(abs(s.D) > 0))
            P = Inf(size(P));
        end
    else
        P = P + s.D * W * s.D';
    end
end
