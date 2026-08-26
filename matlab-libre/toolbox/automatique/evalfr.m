function H = evalfr(sys, x)
%EVALFR Valeur de la transmittance en un point du plan complexe.
%   H = EVALFR(SYS,X) rend H(X). C'est la fonction de transfert évaluée
%   telle quelle : à la différence de FREQRESP, X n'est pas interprété
%   comme une pulsation, mais comme la variable de Laplace ou de la
%   transformée en Z.
%
%   Exemple :
%      evalfr(tf(1, [1 1]), 0)    % 1 : le gain statique
%      evalfr(tf(1, [1 1]), 1i)   % 0.5 - 0.5i
%
%   Voir aussi FREQRESP, DCGAIN.
    if strcmp(sys.type, 'ss') && ~issiso(sys)
        n = size(sys.A, 1);
        H = sys.C * ((x * eye(n) - sys.A) \ sys.B) + sys.D;
        return
    end
    g = tf(sys);
    H = polyval(g.num, x) ./ polyval(g.den, x);
end
