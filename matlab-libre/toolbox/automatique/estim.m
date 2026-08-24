function est = estim(sys, L, capteurs, connues)
%ESTIM Estimateur d'état à partir d'un gain d'observation.
%   EST = ESTIM(SYS,L) construit l'observateur
%
%      dxe/dt = A xe + L (y - C xe)
%
%   dont les sorties sont [ye; xe] : la sortie reconstruite puis l'état
%   estimé. L'entrée est la mesure y.
%
%   EST = ESTIM(SYS,L,CAPTEURS) précise quelles sorties de SYS sont
%   mesurées ; EST = ESTIM(SYS,L,CAPTEURS,CONNUES) précise en plus
%   quelles entrées sont connues de l'estimateur, qui prend alors
%   [u connues; y mesurées].
%
%   Exemple :
%      e = estim(ss(-1, 1, 1, 0), 2);
%      pole(e)   % -3 : l'observateur est plus rapide que le procédé
%
%   Voir aussi REG, KALMAN, LQE, PLACE.
    s = ss(sys);
    n = size(s.A, 1);
    ny = size(s.C, 1);
    nu = size(s.B, 2);
    if nargin < 3 || isempty(capteurs), capteurs = 1:ny; end
    if nargin < 4, connues = []; end
    capteurs = capteurs(:)';
    connues = connues(:)';
    Cm = s.C(capteurs, :);
    Dm = s.D(capteurs, :);
    Ae = s.A - L * Cm;
    if isempty(connues)
        Be = L;
        De = [zeros(ny, numel(capteurs)); zeros(n, numel(capteurs))];
    else
        Be = [s.B(:, connues) - L * Dm(:, connues), L];
        De = [s.D(:, connues), zeros(ny, numel(capteurs)); ...
              zeros(n, numel(connues) + numel(capteurs))];
    end
    Ce = [s.C; eye(n)];
    est = ss(Ae, Be, Ce, De, s.Ts);
end
