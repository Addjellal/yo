function [H, w] = freqresp(sys, w)
%FREQRESP Réponse fréquentielle complexe.
%   H = FREQRESP(SYS,W) évalue la transmittance à chaque pulsation de W :
%   H(jW) en continu, H(exp(jW*TS)) en discret.
%
%   Pour un modèle monovariable, H est un vecteur de la taille de W ; pour
%   un modèle d'état à plusieurs entrées ou sorties, c'est un tableau
%   NY x NU x NUMEL(W).
%
%   [H,W] = FREQRESP(SYS) choisit lui-même la grille de pulsations.
%
%   Exemple :
%      abs(freqresp(tf(1, [1 1]), 1))   % 1/sqrt(2)
%
%   Voir aussi BODE, EVALFR, SIGMA, NICHOLS.
    if nargin < 2 || isempty(w)
        [~, ~, w] = bode(sys);
    end
    w = w(:);
    if sys.Ts > 0
        points = exp(1i * w * sys.Ts);
    else
        points = 1i * w;
    end
    if strcmp(sys.type, 'ss') && ~issiso(sys)
        ny = size(sys.C, 1);
        nu = size(sys.B, 2);
        n = size(sys.A, 1);
        H = zeros(ny, nu, numel(w));
        for k = 1:numel(w)
            H(:, :, k) = sys.C * ((points(k) * eye(n) - sys.A) \ sys.B) + sys.D;
        end
    else
        g = tf(sys);
        H = polyval(g.num, points) ./ polyval(g.den, points);
    end
end
