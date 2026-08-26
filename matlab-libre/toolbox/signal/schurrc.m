function [k, e] = schurrc(r)
%SCHURRC Coefficients de réflexion par l'algorithme de Schur.
%   [K,E] = SCHURRC(R) applique la récurrence de Schur sur la suite
%   d'autocorrélation : elle donne les mêmes coefficients de réflexion
%   que Levinson-Durbin sans former le polynôme de prédiction, ce qui la
%   rend plus stable numériquement et parallélisable.
%
%   Exemple :
%      k = schurrc([1 0.5 0.25]);   % [-0.5 0]
    r = double(r(:)).';
    p = numel(r) - 1;
    k = zeros(p, 1);
    if p == 0
        e = r(1);
        return
    end
    % Deux générateurs, décalés l'un par rapport à l'autre.
    u = r;
    v = r;
    e = r(1);
    for m = 1:p
        v = [0 v(1:end-1)];
        k(m) = -u(m + 1) / v(m + 1);
        nouveauU = u + k(m) * v;
        nouveauV = v + conj(k(m)) * u;
        u = nouveauU;
        v = nouveauV;
        e = e * (1 - abs(k(m)) ^ 2);
    end
end
