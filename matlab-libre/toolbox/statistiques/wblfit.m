function phat = wblfit(x)
%WBLFIT Estimation des paramètres d'une loi de Weibull.
%   Le maximum de vraisemblance annule
%      sum(x^b log x)/sum(x^b) - 1/b - moyenne(log x),
%   équation en la seule forme B, résolue par Newton ; l'échelle A suit
%   par (sum(x^b)/n)^(1/b).
%
%   PHAT vaut [A B] : échelle et forme.
    x = double(x(:));
    if any(x <= 0)
        error('stats:wblfit:BadData', 'Les données doivent être strictement positives.');
    end
    n = numel(x);
    l = log(x);
    moyenneLog = sum(l) / n;
    % Départ : l'estimateur des moments d'ordre 1 et 2 sur les logarithmes.
    b = pi / (sqrt(6) * std(l));
    if ~isfinite(b) || b <= 0, b = 1; end
    for iteration = 1:200
        xb = x .^ b;
        s0 = sum(xb);
        s1 = sum(xb .* l);
        s2 = sum(xb .* l .^ 2);
        f = s1 / s0 - 1 / b - moyenneLog;
        df = (s2 * s0 - s1 ^ 2) / s0 ^ 2 + 1 / b ^ 2;
        pas = f / df;
        nouveau = b - pas;
        if nouveau <= 0, nouveau = b / 2; end
        if abs(nouveau - b) <= 1e-14 * b
            b = nouveau;
            break
        end
        b = nouveau;
    end
    a = (sum(x .^ b) / n) ^ (1 / b);
    phat = [a, b];
end
