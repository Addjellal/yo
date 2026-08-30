function sys = drss(n, ny, nu)
%DRSS Modèle d'état discret stable, tiré au hasard.
%   SYS = DRSS(N) rend un modèle discret d'ordre N dont tous les pôles
%   sont dans le cercle unité, à la période d'échantillonnage 1.
%
%   SYS = DRSS(N,NY) et SYS = DRSS(N,NY,NU) donnent plusieurs voies.
%
%   Exemples :
%      sys = drss(3);
%      max(abs(pole(sys))) < 1      % vrai : les poles sont dans le cercle
%      drss(2).Ts                   % 1
%
%   Voir aussi RSS, SS, C2D, POLE.
    if nargin < 1 || isempty(n), n = 1; end
    if nargin < 2 || isempty(ny), ny = 1; end
    if nargin < 3 || isempty(nu), nu = 1; end
    A = randn(n, n);
    if n > 0
        rayon = max(abs(eig(A)));
        if rayon > 0
            A = A * (0.5 + 0.4 * rand()) / rayon;
        end
    end
    sys = ss(A, randn(n, nu), randn(ny, n), zeros(ny, nu), 1);
end
