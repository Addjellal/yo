function sysd = d2d(sys, Ts, methode)
%D2D Rééchantillonnage d'un modèle discret.
%   SYSD = D2D(SYS,TS) change la période d'échantillonnage : le modèle
%   repasse en continu puis est rediscrétisé, ce qui préserve la réponse
%   indicielle aux nouveaux instants d'échantillonnage.
%   SYSD = D2D(SYS,TS,METHODE) choisit la méthode, 'zoh' par défaut ou
%   'tustin'.
%
%   Exemple :
%      g = c2d(tf(1, [1 1]), 0.1);
%      h = d2d(g, 0.2);
%      abs(dcgain(h) - dcgain(g)) < 1e-10   % le gain statique se conserve
%
%   Voir aussi C2D, D2C.
    if nargin < 3 || isempty(methode), methode = 'zoh'; end
    if sys.Ts == 0
        error('control:d2d:NotDiscrete', 'Le modèle doit être discret.');
    end
    if abs(sys.Ts - Ts) < eps(Ts)
        sysd = sys;
        return
    end
    sysd = c2d(d2c(sys, methode), Ts, methode);
end
