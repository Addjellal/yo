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
        H = H .* exp(-x * totaldelay(sys));
        return
    end
    g = tf(sys);
    H = polyval(g.num, x) ./ polyval(g.den, x);
    % Le retard vaut e^(-x D) au point x du plan complexe : en s = jw,
    % c'est le dephasage pur, et l'evaluation ailleurs suit la meme loi.
    H = H .* exp(-x * matlibre_retard_scalaire(sys, 'EVALFR'));
end
